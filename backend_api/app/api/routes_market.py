import logging
from typing import Any, Dict, List, Optional
from bson import ObjectId
from fastapi import APIRouter, HTTPException, Query, status

from backend_api.app.models.schemas import (
    AgmarknetPriceRecord,
    AgmarknetPriceRecordUpdate
)
from backend_api.app.services.database import (
    db_manager,
    insert_document,
    query_documents
)

logger = logging.getLogger("mandisync.market")
router = APIRouter(tags=["Market Prices"])


def doc_to_response(doc: Dict[str, Any]) -> Dict[str, Any]:
    if "_id" in doc:
        doc["id"] = str(doc["_id"])
        doc.pop("_id", None)
    return doc


# ===========================================================================
# 1. GET /market-prices: Query Historical Market Prices
# ===========================================================================

@router.get(
    "/market-prices",
    response_model=List[Dict[str, Any]],
    summary="Get Historical Market Prices",
    description="Retrieve historical agricultural market price records with optional filtering by crop name and location."
)
@router.get(
    "/market_prices",
    response_model=List[Dict[str, Any]],
    include_in_schema=False
)
async def get_market_prices(
    crop_name: Optional[str] = Query(None, description="Filter by crop or commodity name e.g. Potato, Onion, Wheat"),
    commodity: Optional[str] = Query(None, description="Alternative alias for crop name"),
    location: Optional[str] = Query(None, description="Filter by location (market, mandi, district, or state) e.g. Pune, Lasalgaon, Nashik"),
    market: Optional[str] = Query(None, description="Alternative alias for market name"),
    state: Optional[str] = Query(None, description="Filter specifically by Indian state"),
    variety: Optional[str] = Query(None, description="Filter by crop variety"),
    skip: int = Query(0, ge=0, description="Offset for pagination"),
    limit: int = Query(50, ge=1, le=500, description="Max number of historical records to return")
):
    query: Dict[str, Any] = {}
    and_clauses: List[Dict[str, Any]] = []

    crop_target = crop_name or commodity
    if crop_target:
        and_clauses.append({
            "$or": [
                {"commodity": {"$regex": crop_target, "$options": "i"}},
                {"variety": {"$regex": crop_target, "$options": "i"}}
            ]
        })

    loc_target = location or market
    if loc_target:
        and_clauses.append({
            "$or": [
                {"market": {"$regex": loc_target, "$options": "i"}},
                {"district": {"$regex": loc_target, "$options": "i"}},
                {"state": {"$regex": loc_target, "$options": "i"}}
            ]
        })

    if state:
        and_clauses.append({"state": {"$regex": state, "$options": "i"}})
    if variety:
        and_clauses.append({"variety": {"$regex": variety, "$options": "i"}})

    if len(and_clauses) == 1:
        query = and_clauses[0]
    elif len(and_clauses) > 1:
        query["$and"] = and_clauses

    docs = await query_documents(
        "market_prices",
        filter_query=query,
        limit=limit,
        skip=skip,
        sort=[("_id", -1)]
    )

    return [doc_to_response(d) for d in docs]


# ===========================================================================
# 2. POST /market-prices: Create Market Price Record
# ===========================================================================

@router.post(
    "/market-prices",
    response_model=Dict[str, Any],
    status_code=status.HTTP_201_CREATED,
    summary="Create Market Price Record",
    description="Insert a daily Agmarknet market price record into MongoDB."
)
@router.post(
    "/market_prices",
    response_model=Dict[str, Any],
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False
)
async def create_market_price_record(record: AgmarknetPriceRecord):
    doc = record.model_dump(mode="json")
    inserted_id = await insert_document("market_prices", doc)
    doc["id"] = inserted_id
    doc.pop("_id", None)
    logger.info(f"Created market price record for '{record.commodity}' at '{record.market}' (ID: {inserted_id}).")
    return doc


def build_id_query(record_id: str) -> Dict[str, Any]:
    clauses = [{"_id": record_id}, {"id": record_id}]
    if ObjectId.is_valid(record_id):
        clauses.append({"_id": ObjectId(record_id)})
    return {"$or": clauses}


# ===========================================================================
# 3. GET /market-prices/{record_id}: Fetch Single Record by ID
# ===========================================================================

@router.get(
    "/market-prices/{record_id}",
    response_model=Dict[str, Any],
    summary="Get Market Price Record by ID",
    description="Fetch a single market price document by its ID."
)
@router.get(
    "/market_prices/{record_id}",
    response_model=Dict[str, Any],
    include_in_schema=False
)
async def get_market_price_record(record_id: str):
    collection = db_manager.get_collection("market_prices")
    doc = await collection.find_one(build_id_query(record_id))

    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Market price record with ID '{record_id}' not found."
        )

    return doc_to_response(doc)


# ===========================================================================
# 4. PUT /market-prices/{record_id}: Full Replace Record
# ===========================================================================

@router.put(
    "/market-prices/{record_id}",
    response_model=Dict[str, Any],
    summary="Replace Market Price Record",
    description="Fully replace an existing market price document."
)
@router.put(
    "/market_prices/{record_id}",
    response_model=Dict[str, Any],
    include_in_schema=False
)
async def replace_market_price_record(record_id: str, record: AgmarknetPriceRecord):
    collection = db_manager.get_collection("market_prices")
    query = build_id_query(record_id)
    existing = await collection.find_one(query)
    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Market price record with ID '{record_id}' not found to replace."
        )

    doc = record.model_dump(mode="json")
    if "_id" in existing:
        doc["_id"] = existing["_id"]

    await collection.replace_one(query, doc)

    doc["id"] = record_id
    doc.pop("_id", None)
    logger.info(f"Replaced market price record '{record_id}'.")
    return doc


# ===========================================================================
# 5. PATCH /market-prices/{record_id}: Partial Update Record
# ===========================================================================

@router.patch(
    "/market-prices/{record_id}",
    response_model=Dict[str, Any],
    summary="Update Market Price Record (Partial)",
    description="Partially update specific fields of a market price record."
)
@router.patch(
    "/market_prices/{record_id}",
    response_model=Dict[str, Any],
    include_in_schema=False
)
async def update_market_price_record(record_id: str, patch: AgmarknetPriceRecordUpdate):
    collection = db_manager.get_collection("market_prices")
    update_data = {k: v for k, v in patch.model_dump(mode="json").items() if v is not None}

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid fields provided for update."
        )

    res = await collection.find_one_and_update(
        build_id_query(record_id),
        {"$set": update_data},
        return_document=True
    )

    if not res:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Market price record with ID '{record_id}' not found to update."
        )

    logger.info(f"Updated market price record '{record_id}'.")
    return doc_to_response(res)


# ===========================================================================
# 6. DELETE /market-prices/{record_id}: Delete Record
# ===========================================================================

@router.delete(
    "/market-prices/{record_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete Market Price Record",
    description="Remove a market price record from MongoDB."
)
@router.delete(
    "/market_prices/{record_id}",
    status_code=status.HTTP_200_OK,
    include_in_schema=False
)
async def delete_market_price_record(record_id: str):
    collection = db_manager.get_collection("market_prices")
    res = await collection.delete_one(build_id_query(record_id))

    if res.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Market price record with ID '{record_id}' not found to delete."
        )

    logger.info(f"Deleted market price record '{record_id}'.")
    return {"status": "success", "message": f"Market price record '{record_id}' deleted successfully."}
