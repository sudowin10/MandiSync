"""
Logistics Provider API Routes — MandiSync SIH26
================================================
Endpoints for managing transport providers (truck drivers / fleet operators)
and computing efficient delivery quotes with automatic backhaul matching.

Backhaul Matching Logic
-----------------------
A "backhaul" occurs when a driver who has just completed a delivery (status=RETURNING_EMPTY)
happens to be near the pickup point for another shipment that is heading back towards the
driver's home base. By incentivising the farmer with a discounted quote and the driver with
guaranteed revenue for the return trip, we ensure:
  - Zero empty miles whenever a suitable backhaul exists
  - Lower transport costs for farmers
  - Higher revenue-per-km for drivers

The matching algorithm:
  1. Find all providers with status=RETURNING_EMPTY.
  2. Filter those whose `next_available_location` (or `current_location`) matches
     the requested pickup origin (case-insensitive substring).
  3. Among matches, pick the provider whose home_base best aligns with the
     requested destination (i.e., they are already heading that way).
  4. Apply a discount of 20–40% on the calculated quote and mark `is_backhaul_discount=True`.
"""

from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional
from uuid import uuid4

from bson import ObjectId
from fastapi import APIRouter, HTTPException, Query, status

from backend_api.app.models.schemas import (
    LogisticsProviderCreate,
    LogisticsProviderUpdate,
    DeliveryQuoteRequest,
    DeliveryQuoteResponse,
    BackhaulMatch,
    ServiceStatus,
)
from backend_api.app.services.database import db_manager, insert_document, query_documents

logger = logging.getLogger("mandisync.logistics")
router = APIRouter(prefix="/logistics", tags=["Logistics (Fleet & Backhaul)"])

# ---------------------------------------------------------------------------
# Internal Helpers
# ---------------------------------------------------------------------------

COLLECTION = "logistics_providers"
CROPS_COLLECTION = "crops"

# Average road speed used for transit time estimates (km/h)
_AVG_SPEED_KMH = 60.0
# Default km assumed per trip when the client does not supply distance_km
_DEFAULT_KM_PER_TRIP = 150.0
# Backhaul discount band (min %, max %)
_BACKHAUL_DISCOUNT_RANGE = (20, 40)


def _clean_doc(doc: Dict[str, Any]) -> Dict[str, Any]:
    """Stringify ObjectId _id so it is JSON-serialisable."""
    if "_id" in doc:
        doc["_id"] = str(doc["_id"])
    return doc


def _build_id_query(provider_id: str) -> Dict[str, Any]:
    """Support lookup by both string `id` field and MongoDB ObjectId."""
    conditions = [{"id": provider_id}, {"_id": provider_id}]
    if ObjectId.is_valid(provider_id):
        conditions.append({"_id": ObjectId(provider_id)})
    return {"$or": conditions}


def _calc_quote(
    provider_doc: Dict[str, Any],
    distance_km: float,
    weight_kg: float,
    backhaul: bool = False,
) -> Dict[str, Any]:
    """
    Compute the cost components for a delivery quote given a provider document.
    Returns a dict of cost fields ready to be merged into DeliveryQuoteResponse.
    """
    base_fee: float = float(provider_doc.get("base_fee_inr", 1500.0))
    per_km: float = float(provider_doc.get("per_km_rate_inr", 18.0))
    variable = per_km * distance_km

    # Overweight surcharge: 10% extra per 20% over capacity
    max_cap: float = float(
        provider_doc.get("vehicle", {}).get("max_capacity_kg", 3000.0)
        if isinstance(provider_doc.get("vehicle"), dict)
        else 3000.0
    )
    raw_total = base_fee + variable
    if weight_kg > max_cap:
        overload_pct = (weight_kg - max_cap) / max_cap
        surcharge = raw_total * (overload_pct * 0.5)
        raw_total += surcharge

    discount_pct = 0.0
    if backhaul:
        # Scale discount based on how "full" the return trip is
        utilisation = min(weight_kg / max_cap, 1.0)
        # discount between BACKHAUL_DISCOUNT_RANGE[0] and [1]
        lo, hi = _BACKHAUL_DISCOUNT_RANGE
        discount_pct = lo + (hi - lo) * utilisation
        raw_total *= 1.0 - (discount_pct / 100.0)

    transit_days = round(distance_km / (_AVG_SPEED_KMH * 8), 2)  # 8 driving hours/day

    return {
        "base_cost_inr": round(base_fee, 2),
        "variable_cost_inr": round(variable, 2),
        "estimated_cost_inr": round(raw_total, 2),
        "is_backhaul_discount": backhaul,
        "backhaul_discount_pct": round(discount_pct, 1),
        "estimated_transit_days": max(transit_days, 0.5),
    }


# ---------------------------------------------------------------------------
# CRUD: Logistics Providers
# ---------------------------------------------------------------------------

@router.post(
    "/providers",
    response_model=Dict[str, Any],
    status_code=status.HTTP_201_CREATED,
    summary="Register Logistics Provider",
    description="Register a new truck driver or fleet operator as a logistics provider.",
)
async def create_provider(provider: LogisticsProviderCreate):
    collection = db_manager.get_collection(COLLECTION)

    # Prevent duplicate registrations based on phone number
    existing = await collection.find_one({"phone": provider.phone})
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"A provider with phone '{provider.phone}' is already registered.",
        )

    provider_id = f"PROV-{uuid4().hex[:10].upper()}"
    doc = provider.model_dump(mode="json")
    doc["id"] = provider_id
    doc["current_location"] = provider.home_base
    doc["current_load_kg"] = 0.0
    doc["next_available_location"] = provider.home_base
    doc["created_at"] = datetime.now(timezone.utc).isoformat()
    doc["updated_at"] = datetime.now(timezone.utc).isoformat()

    inserted_id = await insert_document(COLLECTION, doc)
    doc["_id"] = inserted_id
    logger.info(f"Registered logistics provider '{provider_id}' — {provider.provider_name}.")
    return _clean_doc(doc)


@router.get(
    "/providers",
    response_model=List[Dict[str, Any]],
    summary="List Logistics Providers",
    description="List available logistics providers with optional filters.",
)
async def list_providers(
    location: Optional[str] = Query(None, description="Filter by current or home base location"),
    status_filter: Optional[ServiceStatus] = Query(None, alias="status", description="Filter by service status"),
    vehicle_type: Optional[str] = Query(None, description="Filter by vehicle type"),
    min_capacity_kg: Optional[float] = Query(None, ge=0, description="Minimum vehicle capacity in kg"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
):
    query: Dict[str, Any] = {}
    and_clauses = []

    if status_filter:
        query["status"] = status_filter.value

    if location:
        and_clauses.append({
            "$or": [
                {"home_base": {"$regex": location, "$options": "i"}},
                {"current_location": {"$regex": location, "$options": "i"}},
                {"next_available_location": {"$regex": location, "$options": "i"}},
            ]
        })

    if vehicle_type:
        and_clauses.append({"vehicle.vehicle_type": vehicle_type.upper()})

    if min_capacity_kg is not None:
        and_clauses.append({"vehicle.max_capacity_kg": {"$gte": min_capacity_kg}})

    if and_clauses:
        query["$and"] = and_clauses

    docs = await query_documents(COLLECTION, filter_query=query, limit=limit, skip=skip, sort=[("_id", -1)])
    return docs


@router.get(
    "/providers/{provider_id}",
    response_model=Dict[str, Any],
    summary="Get Provider by ID",
)
async def get_provider(provider_id: str):
    collection = db_manager.get_collection(COLLECTION)
    doc = await collection.find_one(_build_id_query(provider_id))
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Logistics provider '{provider_id}' not found.",
        )
    return _clean_doc(doc)


@router.put(
    "/providers/{provider_id}",
    response_model=Dict[str, Any],
    summary="Replace Provider Details",
    description="Fully replace a logistics provider's registration details.",
)
async def replace_provider(provider_id: str, provider: LogisticsProviderCreate):
    collection = db_manager.get_collection(COLLECTION)

    id_query = _build_id_query(provider_id)
    existing = await collection.find_one(id_query)
    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Logistics provider '{provider_id}' not found.",
        )

    doc = provider.model_dump(mode="json")
    doc["id"] = provider_id
    doc["current_location"] = provider.home_base
    doc["current_load_kg"] = 0.0
    doc["next_available_location"] = provider.home_base
    doc["created_at"] = existing.get("created_at", datetime.now(timezone.utc).isoformat())
    doc["updated_at"] = datetime.now(timezone.utc).isoformat()

    if "_id" in existing:
        doc["_id"] = existing["_id"]

    await collection.replace_one(id_query, doc)
    logger.info(f"Replaced logistics provider '{provider_id}'.")
    return _clean_doc(doc)


@router.patch(
    "/providers/{provider_id}",
    response_model=Dict[str, Any],
    summary="Update Provider (Partial)",
    description=(
        "Partially update a provider's fields. "
        "Commonly used by the driver app to update status, current_location, or current_load_kg."
    ),
)
async def update_provider(provider_id: str, patch: LogisticsProviderUpdate):
    collection = db_manager.get_collection(COLLECTION)

    raw = patch.model_dump(mode="json", exclude_unset=True)
    update_data = {k: v for k, v in raw.items() if v is not None}
    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid fields provided for update.",
        )

    # Flatten vehicle sub-document fields
    if "vehicle" in update_data and isinstance(update_data["vehicle"], dict):
        for vk, vv in update_data.pop("vehicle").items():
            update_data[f"vehicle.{vk}"] = vv

    update_data["updated_at"] = datetime.now(timezone.utc).isoformat()

    id_query = _build_id_query(provider_id)
    res = await collection.find_one_and_update(
        id_query, {"$set": update_data}, return_document=True
    )
    if not res:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Logistics provider '{provider_id}' not found.",
        )
    logger.info(f"Updated logistics provider '{provider_id}': {list(update_data.keys())}.")
    return _clean_doc(res)


@router.delete(
    "/providers/{provider_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete Provider",
)
async def delete_provider(provider_id: str):
    collection = db_manager.get_collection(COLLECTION)
    res = await collection.delete_one(_build_id_query(provider_id))
    if res.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Logistics provider '{provider_id}' not found.",
        )
    logger.info(f"Deleted logistics provider '{provider_id}'.")
    return {"status": "success", "message": f"Provider '{provider_id}' deleted."}


# ---------------------------------------------------------------------------
# Quote Generation — with Backhaul Matching
# ---------------------------------------------------------------------------

@router.post(
    "/quotes",
    response_model=DeliveryQuoteResponse,
    summary="Request Delivery Quote",
    description=(
        "Calculate a delivery cost estimate between origin and destination. "
        "Automatically checks for RETURNING_EMPTY drivers near the origin "
        "to offer backhaul-discounted rates (20–40% off)."
    ),
)
async def request_delivery_quote(req: DeliveryQuoteRequest):
    distance_km = req.distance_km or _DEFAULT_KM_PER_TRIP
    collection = db_manager.get_collection(COLLECTION)

    # --- Step 1: Try to find a RETURNING_EMPTY provider near the origin ----
    backhaul_query: Dict[str, Any] = {
        "$and": [
            {"status": ServiceStatus.RETURNING_EMPTY.value},
            {
                "$or": [
                    {"next_available_location": {"$regex": req.origin, "$options": "i"}},
                    {"current_location": {"$regex": req.origin, "$options": "i"}},
                ]
            },
        ]
    }
    backhaul_candidates = await query_documents(COLLECTION, filter_query=backhaul_query, limit=20)

    # Score candidates: prefer those whose home_base is closest to the destination
    best_backhaul: Optional[Dict[str, Any]] = None
    for candidate in backhaul_candidates:
        home = (candidate.get("home_base") or "").lower()
        dest = req.destination.lower()
        if home in dest or dest in home:
            best_backhaul = candidate
            break
    # If no perfect home-base match, take any RETURNING_EMPTY near origin
    if best_backhaul is None and backhaul_candidates:
        best_backhaul = backhaul_candidates[0]

    # --- Step 2: Fall back to any AVAILABLE provider if no backhaul found ---
    if best_backhaul:
        provider_doc = best_backhaul
        is_backhaul = True
    else:
        avail_query: Dict[str, Any] = {"status": ServiceStatus.AVAILABLE.value}
        if req.preferred_vehicle_type:
            avail_query["vehicle.vehicle_type"] = req.preferred_vehicle_type.value
        available = await query_documents(COLLECTION, filter_query=avail_query, limit=1)
        provider_doc = available[0] if available else {}
        is_backhaul = False

    # --- Step 3: Compute the quote ---
    if not provider_doc:
        # No provider found — use platform defaults for estimation
        provider_doc = {"base_fee_inr": 1500.0, "per_km_rate_inr": 18.0, "vehicle": {"max_capacity_kg": 3000.0}}

    cost_fields = _calc_quote(provider_doc, distance_km, req.weight_kg, backhaul=is_backhaul)

    notes: Optional[str] = None
    max_cap = float(
        provider_doc.get("vehicle", {}).get("max_capacity_kg", 3000.0)
        if isinstance(provider_doc.get("vehicle"), dict)
        else 3000.0
    )
    if req.weight_kg > max_cap:
        notes = (
            f"Warning: requested weight ({req.weight_kg} kg) exceeds matched vehicle capacity "
            f"({max_cap} kg). A larger vehicle or split shipment is recommended."
        )

    return DeliveryQuoteResponse(
        origin=req.origin,
        destination=req.destination,
        weight_kg=req.weight_kg,
        distance_km=distance_km,
        matched_provider_id=provider_doc.get("id"),
        matched_provider_name=provider_doc.get("provider_name"),
        notes=notes,
        **cost_fields,
    )


# ---------------------------------------------------------------------------
# Backhaul Match Finder — for the Driver App
# ---------------------------------------------------------------------------

@router.get(
    "/match-backhauls/{provider_id}",
    response_model=List[BackhaulMatch],
    summary="Find Backhaul Loads for a Driver",
    description=(
        "Given a driver's ID, find active crop listings in their current location "
        "that need transport towards their home base — eliminating empty return trips."
    ),
)
async def match_backhauls(
    provider_id: str,
    limit: int = Query(10, ge=1, le=50, description="Max backhaul opportunities to return"),
):
    # Fetch the provider record
    collection = db_manager.get_collection(COLLECTION)
    provider = await collection.find_one(_build_id_query(provider_id))
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Logistics provider '{provider_id}' not found.",
        )

    # The driver is heading back from their current delivery destination towards home
    driver_location = (
        provider.get("next_available_location")
        or provider.get("current_location")
        or provider.get("home_base", "")
    )
    home_base = provider.get("home_base", "")

    # Find active crop listings near the driver's current location
    crop_query: Dict[str, Any] = {
        "$and": [
            {"status": "active"},
            {
                "$or": [
                    {"location": {"$regex": driver_location, "$options": "i"}},
                    {"mandi_info.market_name": {"$regex": driver_location, "$options": "i"}},
                    {"mandi_info.district": {"$regex": driver_location, "$options": "i"}},
                ]
            },
        ]
    }
    crop_docs = await query_documents(CROPS_COLLECTION, filter_query=crop_query, limit=limit * 3)

    backhauls: List[BackhaulMatch] = []
    for crop in crop_docs:
        crop_loc = (
            crop.get("location")
            or crop.get("mandi_info", {}).get("market_name", "")
            if isinstance(crop.get("mandi_info"), dict)
            else ""
        )
        # Compute a simple alignment score: full score if heading towards home base district/state
        crop_state = (
            crop.get("mandi_info", {}).get("state", "")
            if isinstance(crop.get("mandi_info"), dict)
            else ""
        )
        home_state = provider.get("home_base_state", "")
        alignment = 0.8 if (home_state and crop_state and home_state.lower() == crop_state.lower()) else 0.5

        # Estimate weight from available_quantity (default QUINTAL → kg)
        qty = float((
            crop.get("quantity", {}).get("available_quantity", 0)
            if isinstance(crop.get("quantity"), dict)
            else crop.get("quantity", 0)
        ) or 0)
        unit = (
            crop.get("quantity", {}).get("unit", "QUINTAL")
            if isinstance(crop.get("quantity"), dict)
            else "QUINTAL"
        )
        weight_kg = qty * 100.0 if "QUINTAL" in str(unit).upper() else qty

        # Revenue estimation based on provider's per_km rate
        per_km = float(provider.get("per_km_rate_inr", 18.0))
        est_revenue = per_km * _DEFAULT_KM_PER_TRIP * (1.0 - 0.30)  # backhaul rate = 30% off

        crop_name = (
            crop.get("descriptor", {}).get("name", crop.get("crop_name", "Unknown"))
            if isinstance(crop.get("descriptor"), dict)
            else crop.get("crop_name", "Unknown")
        )

        backhauls.append(
            BackhaulMatch(
                crop_listing_id=crop.get("id") or crop.get("_id", ""),
                crop_name=crop_name,
                pickup_location=crop_loc or driver_location,
                dropoff_location=home_base,
                weight_kg=weight_kg,
                farmer_contact=crop.get("farmer_id"),
                estimated_revenue_inr=round(est_revenue, 2),
                alignment_score=alignment,
            )
        )
        if len(backhauls) >= limit:
            break

    # Sort by best alignment score first
    backhauls.sort(key=lambda b: b.alignment_score, reverse=True)
    return backhauls
