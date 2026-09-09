import asyncio
from datetime import datetime, timezone
import logging
from backend_api.app.services.database import db_manager

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mongo_verify")

async def verify_connection():
    success = await db_manager.connect_to_mongo()
    if not success:
        logger.error("Failed to connect to MongoDB")
        return
    # List collection names in the configured DB
    db = db_manager.get_database()
    if db is None:
        logger.error("Database object is None after successful connection")
        return
    collections = await db.list_collection_names()
    logger.info(f"Connected to MongoDB. Collections in '{db.name}': {collections}")
    # Insert a simple test document
    test_coll = db_manager.get_collection("test_connection")
    result = await test_coll.insert_one({"test": "ping", "timestamp": "now"})
    logger.info(f"Inserted test document ID: {result.inserted_id}")
    # Insert a sample Agmarknet market price record
    sample_price = {
        "state": "Maharashtra",
        "district": "Nashik",
        "market": "Lasalgaon",
        "commodity": "Onion",
        "variety": "Red Onion",
        "arrival_date": "2026-09-01",
        "min_price": 2100.0,
        "max_price": 2750.0,
        "modal_price": 2400.0,
        "arrival_tonnes": 1200.0,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    price_coll = db_manager.get_collection("market_prices")
    price_res = await price_coll.insert_one(sample_price)
    logger.info(f"Inserted sample market price document ID: {price_res.inserted_id}")
    # Cleanup test document only (keep sample data for further use)
    await test_coll.delete_one({"_id": result.inserted_id})
    await db_manager.close_mongo_connection()
    logger.info("MongoDB connection closed after verification.")

if __name__ == "__main__":
    asyncio.run(verify_connection())
