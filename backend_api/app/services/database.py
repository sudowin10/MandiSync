import logging
from typing import Optional, Any, Dict, List, Tuple
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pymongo.errors import PyMongoError, ServerSelectionTimeoutError

from backend_api.app.core.config import settings

logger = logging.getLogger("mandisync.database")

class MongoDBManager:
    """
    Asynchronous MongoDB Connection Manager using Motor.
    Manages connection pooling, lifecycle hooks, and connectivity diagnostics.
    """
    def __init__(self):
        self.client: Optional[AsyncIOMotorClient] = None
        self.db: Optional[AsyncIOMotorDatabase] = None
        self.is_connected: bool = False
        self._fallback_storage: Dict[str, List[Dict[str, Any]]] = {}

    async def connect_to_mongo(
        self,
        uri: Optional[str] = None,
        db_name: Optional[str] = None,
        timeout_ms: Optional[int] = None
    ) -> bool:
        mongo_uri = uri or settings.MONGO_URI
        target_db = db_name or settings.MONGO_DB_NAME
        timeout = timeout_ms or settings.MONGO_TIMEOUT_MS

        logger.info(f"Connecting to MongoDB at {mongo_uri} (db: {target_db}, timeout: {timeout}ms)...")
        try:
            self.client = AsyncIOMotorClient(
                mongo_uri,
                serverSelectionTimeoutMS=timeout,
                connectTimeoutMS=timeout,
                maxPoolSize=50,
                minPoolSize=5
            )
            # Verify connectivity with an admin ping
            await self.client.admin.command("ping")
            self.db = self.client[target_db]
            self.is_connected = True
            logger.info(f"Successfully connected to MongoDB database '{target_db}'")
            return True
        except (ServerSelectionTimeoutError, PyMongoError) as exc:
            self.is_connected = False
            logger.warning(
                f"Could not establish connection to live MongoDB at {mongo_uri}: {exc}. "
                "Operating in resilient fallback mode (in-memory mock storage enabled for offline/test environments)."
            )
            return False

    async def close_mongo_connection(self):
        if self.client:
            logger.info("Closing MongoDB connection pool...")
            self.client.close()
            self.is_connected = False
            logger.info("MongoDB connection closed cleanly.")

    def get_database(self) -> Optional[AsyncIOMotorDatabase]:
        """Return the active Motor database if connected, else None."""
        if self.is_connected and self.db is not None:
            return self.db
        return None

    def get_collection(self, collection_name: str):
        """
        Return the Motor collection if connected.
        If MongoDB is offline, return a fallback collection proxy for seamless local testing.
        """
        if self.is_connected and self.db is not None:
            return self.db[collection_name]
        return FallbackCollection(collection_name, self._fallback_storage)

    async def insert_document(self, collection_name: str, document: Dict[str, Any]) -> str:
        return await insert_document(collection_name, document)

    async def query_documents(
        self,
        collection_name: str,
        filter_query: Optional[Dict[str, Any]] = None,
        limit: Optional[int] = None,
        skip: int = 0,
        sort: Optional[List[Tuple[str, int]]] = None
    ) -> List[Dict[str, Any]]:
        return await query_documents(collection_name, filter_query, limit, skip, sort)


class FallbackCollection:
    """
    Lightweight in-memory asynchronous collection fallback.
    Guarantees that test suites and API endpoints remain fully functional even
    when an external MongoDB server is not running on the development workstation.
    """
    def __init__(self, name: str, storage: Dict[str, List[Dict[str, Any]]]):
        self.name = name
        self._storage = storage
        if name not in self._storage:
            self._storage[name] = []

    async def insert_one(self, doc: Dict[str, Any]):
        doc_copy = dict(doc)
        if "_id" not in doc_copy:
            doc_copy["_id"] = str(len(self._storage[self.name]) + 1)
        self._storage[self.name].append(doc_copy)
        class InsertResult:
            inserted_id = doc_copy["_id"]
        return InsertResult()

    async def insert_many(self, docs: List[Dict[str, Any]]):
        ids = []
        for doc in docs:
            res = await self.insert_one(doc)
            ids.append(res.inserted_id)
        class InsertManyResult:
            inserted_ids = ids
        return InsertManyResult()

    def _matches_filter(self, item: Dict[str, Any], filter_query: Dict[str, Any]) -> bool:
        for k, v in filter_query.items():
            if k == "$or":
                sub_matches = any(self._matches_filter(item, cond) for cond in v)
                if not sub_matches:
                    return False
                continue
            if k == "$and":
                sub_matches = all(self._matches_filter(item, cond) for cond in v)
                if not sub_matches:
                    return False
                continue
            
            # Support nested dict lookup e.g. "descriptor.name"
            val = item
            for part in k.split("."):
                if isinstance(val, dict):
                    val = val.get(part)
                else:
                    val = None
                    break

            if isinstance(v, dict):
                if "$regex" in v:
                    pattern = str(v["$regex"]).lower()
                    if val is None or pattern not in str(val).lower():
                        return False
                elif "$exists" in v:
                    exists = val is not None
                    if exists != v["$exists"]:
                        return False
                elif "$gt" in v and (val is None or val <= v["$gt"]):
                    return False
                elif "$gte" in v and (val is None or val < v["$gte"]):
                    return False
                elif "$lt" in v and (val is None or val >= v["$lt"]):
                    return False
                elif "$lte" in v and (val is None or val > v["$lte"]):
                    return False
                elif "$ne" in v and val == v["$ne"]:
                    return False
            elif val != v and str(val) != str(v):
                return False
        return True

    def find(self, filter_query: Optional[Dict[str, Any]] = None, sort: Optional[List] = None):
        items = list(self._storage.get(self.name, []))
        if filter_query:
            items = [item for item in items if self._matches_filter(item, filter_query)]

        class AsyncCursor:
            def __init__(self, data: List[Dict[str, Any]]):
                self._data = list(data)
                self._index = 0

            def skip(self, count: int):
                self._data = self._data[count:]
                return self

            def limit(self, count: int):
                if count is not None:
                    self._data = self._data[:count]
                return self

            def __aiter__(self):
                return self

            async def __anext__(self):
                if self._index < len(self._data):
                    val = self._data[self._index]
                    self._index += 1
                    return val
                raise StopAsyncIteration

            async def to_list(self, length: Optional[int] = None):
                if length is None:
                    return list(self._data)
                return list(self._data[:length])

        return AsyncCursor(items)

    async def find_one(self, filter_query: Dict[str, Any]):
        items = self._storage.get(self.name, [])
        for item in items:
            if self._matches_filter(item, filter_query):
                return item
        return None

    async def update_one(self, filter_query: Dict[str, Any], update_doc: Dict[str, Any], upsert: bool = False):
        item = await self.find_one(filter_query)
        if item:
            if "$set" in update_doc:
                item.update(update_doc["$set"])
            class UpdateResult:
                matched_count = 1
                modified_count = 1
            return UpdateResult()
        elif upsert:
            new_item = dict(filter_query)
            if "$set" in update_doc:
                new_item.update(update_doc["$set"])
            await self.insert_one(new_item)
            class UpsertResult:
                matched_count = 0
                modified_count = 0
                upserted_id = new_item.get("_id")
            return UpsertResult()
        class NoUpdateResult:
            matched_count = 0
            modified_count = 0
        return NoUpdateResult()

    async def replace_one(self, filter_query: Dict[str, Any], replacement: Dict[str, Any]):
        for idx, item in enumerate(self._storage.get(self.name, [])):
            if self._matches_filter(item, filter_query):
                rep_copy = dict(replacement)
                rep_copy["_id"] = item.get("_id", rep_copy.get("_id"))
                self._storage[self.name][idx] = rep_copy
                class RepResult:
                    matched_count = 1
                    modified_count = 1
                return RepResult()
        class RepZero:
            matched_count = 0
            modified_count = 0
        return RepZero()

    async def find_one_and_update(self, filter_query: Dict[str, Any], update_doc: Dict[str, Any], return_document: bool = True):
        item = await self.find_one(filter_query)
        if item and "$set" in update_doc:
            item.update(update_doc["$set"])
            return dict(item)
        return item

    async def delete_one(self, filter_query: Dict[str, Any]):
        items = self._storage.get(self.name, [])
        for idx, item in enumerate(items):
            if self._matches_filter(item, filter_query):
                del items[idx]
                class DelResult:
                    deleted_count = 1
                return DelResult()
        class DelZero:
            deleted_count = 0
        return DelZero()

    async def count_documents(self, filter_query: Optional[Dict[str, Any]] = None) -> int:
        if not filter_query:
            return len(self._storage.get(self.name, []))
        items = await self.find(filter_query).to_list(None)
        return len(items)


# Global Database Manager Singleton
db_manager = MongoDBManager()

async def get_database() -> Optional[AsyncIOMotorDatabase]:
    """Dependency injector for routes requiring raw database handle."""
    return db_manager.get_database()


# ===========================================================================
# Core Asynchronous Helper Functions
# ===========================================================================

async def insert_document(collection_name: str, document: Dict[str, Any]) -> str:
    """
    Asynchronously insert a document into the specified MongoDB collection.

    Args:
        collection_name: Target collection name (e.g. 'crops', 'market_prices')
        document: Dictionary containing document fields

    Returns:
        The inserted document's unique ID as a string.
    """
    collection = db_manager.get_collection(collection_name)
    doc_copy = dict(document)
    result = await collection.insert_one(doc_copy)
    inserted_id = str(result.inserted_id)
    logger.info(f"Inserted document into '{collection_name}' with ID: {inserted_id}")
    return inserted_id


async def query_documents(
    collection_name: str,
    filter_query: Optional[Dict[str, Any]] = None,
    limit: Optional[int] = None,
    skip: int = 0,
    sort: Optional[List] = None
) -> List[Dict[str, Any]]:
    """
    Asynchronously query documents from the specified MongoDB collection matching filter_query.

    Args:
        collection_name: Target collection name
        filter_query: MongoDB query filter dictionary (default: {})
        limit: Maximum number of records to return
        skip: Offset for pagination
        sort: Sort parameters, e.g. [("_id", -1)]

    Returns:
        List of matching document dictionaries with string '_id' and 'id'.
    """
    collection = db_manager.get_collection(collection_name)
    query = filter_query or {}

    if sort is not None:
        cursor = collection.find(query, sort=sort)
    else:
        cursor = collection.find(query)

    if hasattr(cursor, "skip") and skip > 0:
        cursor = cursor.skip(skip)
    if hasattr(cursor, "limit") and limit is not None:
        cursor = cursor.limit(limit)

    raw_docs = await cursor.to_list(length=limit)
    cleaned_docs: List[Dict[str, Any]] = []
    for doc in raw_docs:
        d = dict(doc)
        if "_id" in d:
            d["_id"] = str(d["_id"])
            if "id" not in d:
                d["id"] = d["_id"]
        cleaned_docs.append(d)

    return cleaned_docs
