from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, HTTPException, Query, status

from backend_api.app.core.config import settings
from backend_api.app.models.schemas import (
    ONDCCropListing,
    ONDCSearchRequest,
    ONDCSelectRequest,
    ONDCResponse,
    ONDCAck,
    ONDCContext
)
from backend_api.app.services.database import db_manager
from backend_api.app.services.ml_runner import ml_runner

logger = logging.getLogger("mandisync.ondc")
router = APIRouter(prefix="/ondc", tags=["ONDC Protocol Webhooks"])


# ===========================================================================
# 1. POST /ondc/search: Catalog Discovery Webhook
# ===========================================================================

@router.post(
    "/search",
    response_model=ONDCResponse,
    status_code=status.HTTP_200_OK,
    summary="ONDC Beckn Protocol: Search Webhook",
    description="Receives catalog discovery inquiries from ONDC Buyer Apps (BAP) and returns standardized Beckn ACK."
)
async def ondc_search(request: ONDCSearchRequest):
    logger.info(
        f"Received ONDC /search webhook from BAP '{request.context.bap_id}' "
        f"[Txn ID: {request.context.transaction_id}, Action: {request.context.action}]"
    )
    # Validate Beckn domain
    if request.context.domain != settings.ONDC_DOMAIN:
        logger.warning(f"Domain mismatch: expected {settings.ONDC_DOMAIN}, received {request.context.domain}")

    if request.message and request.message.intent:
        intent = request.message.intent
        crop_query = intent.item.descriptor.name if intent.item and intent.item.descriptor else "All"
        logger.info(f"Buyer search intent for commodity: '{crop_query}' in city: '{request.context.city}'")

    return ONDCResponse(
        message={"ack": {"status": "ACK"}},
        error=None
    )


# ===========================================================================
# 2. POST /ondc/select: Item Selection / Quote Request Webhook
# ===========================================================================

@router.post(
    "/select",
    response_model=ONDCResponse,
    status_code=status.HTTP_200_OK,
    summary="ONDC Beckn Protocol: Select Webhook",
    description="Receives item selection / quote request from ONDC Buyer Apps (BAP) and returns standardized Beckn ACK."
)
async def ondc_select(request: ONDCSelectRequest):
    logger.info(
        f"Received ONDC /select webhook from BAP '{request.context.bap_id}' "
        f"[Txn ID: {request.context.transaction_id}, Action: {request.context.action}]"
    )
    provider_id = request.message.order.provider.id
    selected_items = [
        {"item_id": item.id, "quantity": item.quantity.count or 1}
        for item in request.message.order.items
    ]
    logger.info(f"Selected items from provider '{provider_id}': {selected_items}")

    return ONDCResponse(
        message={"ack": {"status": "ACK"}},
        error=None
    )


# ===========================================================================
# 3. ONDC Catalog Management
# ===========================================================================

@router.post(
    "/crop_listing",
    response_model=ONDCCropListing,
    status_code=status.HTTP_201_CREATED,
    summary="Create & Publish ONDC Crop Listing with AI Price Guidance",
    description=(
        "Registers a farmer's crop harvest onto the decentralized ONDC seller node. "
        "Automatically queries the loaded XGBoost model to enrich the listing with real-time "
        "mandi peak price forecasts and fair MSP floor guidelines."
    )
)
async def create_ondc_crop_listing(listing: ONDCCropListing):
    # Enrich with AI price prediction if not manually pinned
    if ml_runner.is_ready:
        try:
            pred = ml_runner.predict(
                commodity=listing.descriptor.name.split()[0],  # Extract primary commodity
                market=listing.mandi_info.market_name.split()[0],
                modal_price_lag1=listing.price.value,
                variety=listing.variety
            )
            listing.ai_predicted_max_price = pred.predicted_max_price
            listing.ai_recommended_msp = pred.recommended_listing_price
            listing.tags["ai_model_version"] = pred.model_version
            listing.tags["confidence_range"] = f"{pred.confidence_interval_low}-{pred.confidence_interval_high}"
        except Exception as exc:
            logger.warning(f"AI enrichment warning: {exc}")

    # Persist in MongoDB
    collection = db_manager.get_collection("ondc_crop_listings")
    doc = listing.model_dump(mode="json")
    await collection.insert_one(doc)

    logger.info(f"Published ONDC Crop Listing '{listing.id}' (AI Max Price: Rs. {listing.ai_predicted_max_price})")
    return listing


@router.get(
    "/crop_listings",
    response_model=List[ONDCCropListing],
    summary="Retrieve Active ONDC Crop Listings",
    description="Query agricultural produce catalog listings across mandis and commodities."
)
async def list_ondc_crop_listings(
    commodity: Optional[str] = Query(None, description="Filter by crop name e.g. Onion"),
    mandi: Optional[str] = Query(None, description="Filter by mandi name e.g. Lasalgaon"),
    limit: int = Query(20, ge=1, le=100)
):
    collection = db_manager.get_collection("ondc_crop_listings")
    query: Dict[str, Any] = {}
    
    docs = await collection.find(query).to_list(length=limit)
    
    # If no listings exist yet, seed high-value initial listings
    if not docs:
        initial_listing = ONDCCropListing(
            id="ITEM-ONION-LASALGAON-001",
            descriptor={
                "name": "Lasalgaon Red Onion - Grade A",
                "short_desc": "High pungency, sun-cured Nashik red onions directly sourced from APMC Lasalgaon.",
                "images": ["https://assets.mandisync.ai/crops/onion_a.jpg"]
            },
            category="VEGETABLE",
            price={"currency": "INR", "value": 2650.0, "estimated_mrp": 3100.0},
            quantity={"unit": "QUINTAL", "available_quantity": 450.0, "min_order_quantity": 5.0},
            mandi_info={
                "mandi_id": "MH-LAS-01",
                "market_name": "Lasalgaon APMC",
                "district": "Nashik",
                "state": "Maharashtra",
                "pincode": "422306"
            },
            variety="Garva Red",
            grade="GRADE_A",
            ai_predicted_max_price=2840.50,
            ai_recommended_msp=2550.00
        )
        await collection.insert_one(initial_listing.model_dump(mode="json"))
        docs = [initial_listing.model_dump(mode="json")]

    # Clean Mongo _id
    for d in docs:
        d.pop("_id", None)
    return docs


@router.get(
    "/crop_listings/{item_id}",
    response_model=ONDCCropListing,
    summary="Get Specific ONDC Crop Listing",
    description="Fetch single crop listing by unique Beckn Item ID."
)
async def get_ondc_crop_listing(item_id: str):
    collection = db_manager.get_collection("ondc_crop_listings")
    doc = await collection.find_one({"id": item_id})
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"ONDC Crop listing with ID '{item_id}' not found."
        )
    doc.pop("_id", None)
    return doc
