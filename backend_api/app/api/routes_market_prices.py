from datetime import datetime, timezone, date
import logging
from typing import Any, Dict, List, Optional
from bson import ObjectId
from fastapi import APIRouter, HTTPException, Query, status

from backend_api.app.models.schemas import (
    AgmarknetPriceRecord,
    AgmarknetPriceRecordUpdate
)
from backend_api.app.services.database import db_manager

logger = logging.getLogger("mandisync.market_prices")
router = APIRouter(prefix="/market_prices", tags=["Market Prices (CRUD)"])


def doc_to_response(doc: Dict[str, Any]) -> Dict[str, Any]:
    if "_id" in doc:
        doc["id"] = str(doc["_id"])
        doc.pop("_id", None)
    return doc


@router.post(
    "",
    response_model=Dict[str, Any],
    status_code=status.HTTP_201_CREATED,
    summary="Create Market Price Record",
    description="Insert a daily Agmarknet market price record into MongoDB."
)
async def create_market_price_record(record: AgmarknetPriceRecord):
    collection = db_manager.get_collection("market_prices")
    doc = record.model_dump(mode="json")
    
    res = await collection.insert_one(doc)
    doc["id"] = str(res.inserted_id)
    doc.pop("_id", None)
    
    logger.info(f"Created market price record for '{record.commodity}' at '{record.market}' (ID: {res.inserted_id}).")
    return doc


@router.get(
    "",
    response_model=List[Dict[str, Any]],
    summary="List Market Price Records",
    description="Query market price records with optional filtering by commodity, market, state, or variety."
)
async def list_market_price_records(
    commodity: Optional[str] = Query(None, description="Filter by commodity name e.g. Onion, Wheat, Tomato"),
    market: Optional[str] = Query(None, description="Filter by market/mandi name e.g. Lasalgaon, Sehore, Kolar"),
    state: Optional[str] = Query(None, description="Filter by Indian state e.g. Maharashtra, Rajasthan"),
    variety: Optional[str] = Query(None, description="Filter by variety name e.g. Red Onion, Sharbati, Hybrid"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=500)
):
    collection = db_manager.get_collection("market_prices")
    query: Dict[str, Any] = {}

    if commodity:
        query["commodity"] = {"$regex": commodity, "$options": "i"}
    if market:
        query["market"] = {"$regex": market, "$options": "i"}
    if state:
        query["state"] = {"$regex": state, "$options": "i"}
    if variety:
        query["variety"] = {"$regex": variety, "$options": "i"}

    cursor = collection.find(query, sort=[("_id", -1)]).skip(skip).limit(limit)
    docs = await cursor.to_list(length=limit)

    return [doc_to_response(d) for d in docs]


@router.get(
    "/{record_id}",
    response_model=Dict[str, Any],
    summary="Get Market Price Record by ID",
    description="Fetch a single market price document by its 24-character hexadecimal ObjectId."
)
async def get_market_price_record(record_id: str):
    if not ObjectId.is_valid(record_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid ObjectId format: '{record_id}'."
        )

    collection = db_manager.get_collection("market_prices")
    doc = await collection.find_one({"_id": ObjectId(record_id)})

    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Market price record with ID '{record_id}' not found."
        )

    return doc_to_response(doc)


@router.put(
    "/{record_id}",
    response_model=Dict[str, Any],
    summary="Replace Market Price Record",
    description="Fully replace an existing market price document."
)
async def replace_market_price_record(record_id: str, record: AgmarknetPriceRecord):
    if not ObjectId.is_valid(record_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid ObjectId format: '{record_id}'."
        )

    collection = db_manager.get_collection("market_prices")
    doc = record.model_dump(mode="json")

    res = await collection.replace_one({"_id": ObjectId(record_id)}, doc)

    if res.matched_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Market price record with ID '{record_id}' not found to replace."
        )

    doc["id"] = record_id
    doc.pop("_id", None)
    logger.info(f"Replaced market price record '{record_id}'.")
    return doc


@router.patch(
    "/{record_id}",
    response_model=Dict[str, Any],
    summary="Update Market Price Record (Partial)",
    description="Partially update specific fields of a market price record."
)
async def update_market_price_record(record_id: str, patch: AgmarknetPriceRecordUpdate):
    if not ObjectId.is_valid(record_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid ObjectId format: '{record_id}'."
        )

    collection = db_manager.get_collection("market_prices")
    update_data = {k: v for k, v in patch.model_dump(mode="json").items() if v is not None}

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid fields provided for update."
        )

    res = await collection.find_one_and_update(
        {"_id": ObjectId(record_id)},
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


@router.delete(
    "/{record_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete Market Price Record",
    description="Remove a market price record from MongoDB."
)
async def delete_market_price_record(record_id: str):
    if not ObjectId.is_valid(record_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid ObjectId format: '{record_id}'."
        )

    collection = db_manager.get_collection("market_prices")
    res = await collection.delete_one({"_id": ObjectId(record_id)})

    if res.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Market price record with ID '{record_id}' not found to delete."
        )

    logger.info(f"Deleted market price record '{record_id}'.")
    return {"status": "success", "message": f"Market price record '{record_id}' deleted successfully."}
