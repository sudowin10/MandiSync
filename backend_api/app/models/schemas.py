from datetime import date, datetime, timezone
from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, ConfigDict

# ==========================================
# ONDC Protocol Enums & Value Specifications
# ==========================================

class CropCategory(str, Enum):
    GRAIN = "GRAIN"
    PULSE = "PULSE"
    VEGETABLE = "VEGETABLE"
    FRUIT = "FRUIT"
    OILSEED = "OILSEED"
    SPICE = "SPICE"
    CASH_CROP = "CASH_CROP"


class WeightUnit(str, Enum):
    KG = "KG"
    QUINTAL = "QUINTAL"
    TONNE = "TONNE"
    BAG = "BAG"
    CRATE = "CRATE"


class QualityGrade(str, Enum):
    GRADE_A = "GRADE_A"
    GRADE_B = "GRADE_B"
    GRADE_C = "GRADE_C"
    FAQ = "FAQ"  # Fair Average Quality


class PriceSpecification(BaseModel):
    currency: str = Field(default="INR", description="Three-letter ISO currency code")
    value: float = Field(..., gt=0, description="Base selling price per unit")
    estimated_mrp: Optional[float] = Field(None, gt=0, description="Maximum Retail Price benchmark")
    minimum_order_value: Optional[float] = Field(None, ge=0, description="Minimum order valuation required")

    model_config = ConfigDict(json_schema_extra={
        "example": {
            "currency": "INR",
            "value": 2650.0,
            "estimated_mrp": 3000.0,
            "minimum_order_value": 5000.0
        }
    })


class QuantitySpecification(BaseModel):
    unit: WeightUnit = Field(default=WeightUnit.QUINTAL, description="Unit of measurement")
    available_quantity: float = Field(..., ge=0, description="Stock available at mandi / warehouse")
    min_order_quantity: float = Field(default=1.0, gt=0, description="Minimum purchase amount")
    max_order_quantity: Optional[float] = Field(None, gt=0, description="Bulk ceiling per transaction")


class CropDescriptor(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, description="Common crop name (e.g. Nashik Red Onion)")
    code: Optional[str] = Field(None, description="HSN/Commodity barcode/code")
    short_desc: str = Field(..., max_length=255, description="Summary description")
    long_desc: Optional[str] = Field(None, description="Detailed agronomic and quality specification")
    images: List[str] = Field(default_factory=list, description="Publicly accessible image URLs")


class MandiLocation(BaseModel):
    mandi_id: str = Field(..., description="Unique Agmarknet / APMC mandi code")
    market_name: str = Field(..., description="Mandi/APMC market name")
    district: str = Field(..., description="District")
    state: str = Field(..., description="State")
    pincode: Optional[str] = Field(None, pattern=r"^\d{6}$", description="Indian 6-digit PIN code")
    gps: Optional[str] = Field(None, description="Latitude, Longitude coordinates e.g. 20.0827,74.1202")


# ==========================================
# ONDC Crop Listing Contract (Beckn Schema)
# ==========================================

class ONDCCropListing(BaseModel):
    id: str = Field(..., description="Unique SKU identifier in the decentralized network")
    descriptor: CropDescriptor
    category: CropCategory = Field(default=CropCategory.VEGETABLE)
    price: PriceSpecification
    quantity: QuantitySpecification
    mandi_info: MandiLocation
    variety: str = Field(default="Standard", description="Botanical or regional variety e.g. Garva / Desi")
    grade: QualityGrade = Field(default=QualityGrade.GRADE_A)
    harvest_date: Optional[date] = Field(None, description="Harvesting date for freshness assurance")
    shelf_life_days: Optional[int] = Field(default=30, ge=1, description="Estimated shelf life under mandi storage")
    organic_certified: bool = Field(default=False, description="Certified organic badge")
    farmer_id: Optional[str] = Field(None, description="Decentralized DID or FPO ID")
    
    # AI-Derived Pricing Attributes
    ai_predicted_max_price: Optional[float] = Field(
        None, description="Dynamic XGBoost forecast for maximum mandi price in current window"
    )
    ai_recommended_msp: Optional[float] = Field(
        None, description="Fair floor recommendation safeguarding farmer profitability"
    )
    tags: Dict[str, Any] = Field(default_factory=dict, description="Beckn protocol tag extension key-values")
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "id": "ITEM-ONION-LASALGAON-001",
                "descriptor": {
                    "name": "Lasalgaon Red Onion - Grade A",
                    "short_desc": "High pungency, sun-cured Nashik red onions directly sourced from APMC Lasalgaon.",
                    "images": ["https://assets.mandisync.ai/crops/onion_a.jpg"]
                },
                "category": "VEGETABLE",
                "price": {
                    "currency": "INR",
                    "value": 2650.0,
                    "estimated_mrp": 3100.0
                },
                "quantity": {
                    "unit": "QUINTAL",
                    "available_quantity": 450.0,
                    "min_order_quantity": 5.0
                },
                "mandi_info": {
                    "mandi_id": "MH-LAS-01",
                    "market_name": "Lasalgaon APMC",
                    "district": "Nashik",
                    "state": "Maharashtra",
                    "pincode": "422306"
                },
                "variety": "Garva Red",
                "grade": "GRADE_A",
                "ai_predicted_max_price": 2840.50,
                "ai_recommended_msp": 2550.00
            }
        }
    )


# ==========================================
# Farmer Crop Listing Contract
# ==========================================

class FarmerCropListingCreate(BaseModel):
    crop_name: str = Field(..., min_length=2, description="Crop / Commodity name e.g. Onion, Wheat, Tomato")
    variety: Optional[str] = Field("Standard", description="Botanical or local variety e.g. Garva, Desi, Hybrid")
    category: Optional[CropCategory] = Field(default=CropCategory.VEGETABLE, description="Agricultural category")
    quantity: float = Field(..., gt=0, description="Available stock quantity")
    unit: WeightUnit = Field(default=WeightUnit.QUINTAL, description="Measurement unit (KG, QUINTAL, TONNE)")
    price: float = Field(..., gt=0, description="Price per unit (INR)")
    location: str = Field(..., description="Mandi, APMC, or village location")
    district: Optional[str] = Field(None, description="District")
    state: Optional[str] = Field("Maharashtra", description="State")
    farmer_id: Optional[str] = Field(None, description="Unique Farmer ID or contact identifier")
    farmer_name: Optional[str] = Field(None, description="Name of the producer/farmer")
    grade: QualityGrade = Field(default=QualityGrade.GRADE_A, description="Quality grade")
    harvest_date: Optional[date] = Field(None, description="Harvest date")
    status: str = Field(default="active", description="Listing status: active, pending, completed")


class FarmerCropListingUpdate(BaseModel):
    crop_name: Optional[str] = Field(None, min_length=2, description="Crop / Commodity name e.g. Onion, Wheat, Tomato")
    variety: Optional[str] = Field(None, description="Botanical or local variety e.g. Garva, Desi, Hybrid")
    category: Optional[CropCategory] = Field(None, description="Agricultural category")
    quantity: Optional[float] = Field(None, gt=0, description="Available stock quantity")
    unit: Optional[WeightUnit] = Field(None, description="Measurement unit (KG, QUINTAL, TONNE)")
    price: Optional[float] = Field(None, gt=0, description="Price per unit (INR)")
    location: Optional[str] = Field(None, description="Mandi, APMC, or village location")
    district: Optional[str] = Field(None, description="District")
    state: Optional[str] = Field(None, description="State")
    farmer_id: Optional[str] = Field(None, description="Unique Farmer ID or contact identifier")
    farmer_name: Optional[str] = Field(None, description="Name of the producer/farmer")
    grade: Optional[QualityGrade] = Field(None, description="Quality grade")
    harvest_date: Optional[date] = Field(None, description="Harvest date")
    status: Optional[str] = Field(None, description="Listing status: active, pending, completed")


# ==========================================
# Agmarknet Historical Market Price Schema
# ==========================================

class AgmarknetPriceRecord(BaseModel):
    state: str = Field(..., description="Indian State e.g. Maharashtra")
    district: str = Field(..., description="District e.g. Nashik")
    market: str = Field(..., description="Mandi/Market Name e.g. Lasalgaon")
    commodity: str = Field(..., description="Commodity e.g. Onion")
    variety: str = Field(default="Other", description="Variety name")
    arrival_date: date = Field(..., description="Daily market recording date")
    min_price: float = Field(..., ge=0, description="Minimum price (INR / Quintal)")
    max_price: float = Field(..., ge=0, description="Maximum price (INR / Quintal)")
    modal_price: float = Field(..., ge=0, description="Modal transaction price (INR / Quintal)")
    arrival_tonnes: float = Field(default=0.0, ge=0, description="Daily arrival quantity in tonnes")
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "state": "Maharashtra",
                "district": "Nashik",
                "market": "Lasalgaon",
                "commodity": "Onion",
                "variety": "Red Onion",
                "arrival_date": "2026-09-08",
                "min_price": 2100.0,
                "max_price": 2750.0,
                "modal_price": 2480.0,
                "arrival_tonnes": 1250.0
            }
        }
    )


class ONDCCropListingUpdate(BaseModel):
    descriptor: Optional[CropDescriptor] = None
    category: Optional[CropCategory] = None
    price: Optional[PriceSpecification] = None
    quantity: Optional[QuantitySpecification] = None
    mandi_info: Optional[MandiLocation] = None
    variety: Optional[str] = None
    grade: Optional[QualityGrade] = None
    harvest_date: Optional[date] = None
    shelf_life_days: Optional[int] = None
    organic_certified: Optional[bool] = None
    farmer_id: Optional[str] = None
    ai_predicted_max_price: Optional[float] = None
    ai_recommended_msp: Optional[float] = None
    tags: Optional[Dict[str, Any]] = None


class AgmarknetPriceRecordUpdate(BaseModel):
    state: Optional[str] = None
    district: Optional[str] = None
    market: Optional[str] = None
    commodity: Optional[str] = None
    variety: Optional[str] = None
    arrival_date: Optional[date] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    modal_price: Optional[float] = None
    arrival_tonnes: Optional[float] = None


# ==========================================
# Machine Learning Prediction Contracts
# ==========================================

class PredictionRequest(BaseModel):
    commodity: str = Field(..., description="Crop/Commodity name (e.g. Onion, Tomato, Potato, Wheat)")
    market: str = Field(..., description="Mandi name (e.g. Lasalgaon, Azadpur, Pimpalgaon, Indore)")
    target_date: Optional[date] = Field(default_factory=date.today, description="Forecast target date")
    modal_price_lag1: Optional[float] = Field(None, gt=0, description="Previous day's modal price in INR/quintal")
    min_price_lag1: Optional[float] = Field(None, gt=0, description="Previous day's minimum price in INR/quintal")
    arrival_tonnes: Optional[float] = Field(None, ge=0, description="Estimated daily mandi arrival volume")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "commodity": "Onion",
                "market": "Lasalgaon",
                "target_date": "2026-09-10",
                "modal_price_lag1": 2450.0,
                "min_price_lag1": 2100.0,
                "arrival_tonnes": 1150.0
            }
        }
    )


class PredictionResponse(BaseModel):
    status: str = Field(default="success")
    commodity: str
    market: str
    target_date: str
    predicted_max_price: float = Field(..., description="XGBoost regression forecast for peak mandi price (INR/Quintal)")
    confidence_interval_low: float = Field(..., description="Estimated lower bound 90% confidence")
    confidence_interval_high: float = Field(..., description="Estimated upper bound 90% confidence")
    recommended_listing_price: float = Field(..., description="AI suggested seller floor rate")
    model_version: str = Field(default="price_predictor_v1.pkl")
    inference_latency_ms: float = Field(..., description="Inference execution latency in milliseconds")
    features_used: Dict[str, Any] = Field(default_factory=dict)
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


# ==========================================
# ONDC Beckn Protocol Webhook Contracts
# ==========================================

class ONDCAction(str, Enum):
    SEARCH = "search"
    SELECT = "select"
    INIT = "init"
    CONFIRM = "confirm"
    STATUS = "status"
    TRACK = "track"
    CANCEL = "cancel"
    UPDATE = "update"
    RATING = "rating"
    SUPPORT = "support"
    ON_SEARCH = "on_search"
    ON_SELECT = "on_select"
    ON_INIT = "on_init"
    ON_CONFIRM = "on_confirm"


class ONDCContext(BaseModel):
    domain: str = Field(..., description="ONDC network domain code e.g. nic2004:52110 or ONDC:RET10")
    country: str = Field(default="IND", description="Three-letter ISO country code")
    city: str = Field(..., description="STD code or city identifier e.g. std:0253 or *")
    action: str = Field(..., description="Beckn action name e.g. search, select")
    core_version: str = Field(default="1.2.0", description="Beckn core protocol version")
    bap_id: str = Field(..., description="Buyer App subscriber ID")
    bap_uri: str = Field(..., description="Buyer App callback endpoint URI")
    bpp_id: Optional[str] = Field(None, description="Seller App subscriber ID (optional on search, required on select)")
    bpp_uri: Optional[str] = Field(None, description="Seller App endpoint URI")
    transaction_id: str = Field(..., description="Unique end-to-end transaction UUID")
    message_id: str = Field(..., description="Unique message UUID for idempotency")
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc), description="Timestamp in RFC3339 format")
    ttl: Optional[str] = Field(default="PT30S", description="Time-to-live for request e.g. PT30S")
    key: Optional[str] = Field(None, description="Encryption / signing key")

    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "domain": "nic2004:52110",
                "country": "IND",
                "city": "std:0253",
                "action": "search",
                "core_version": "1.2.0",
                "bap_id": "buyer.ondc.buyerapp.com",
                "bap_uri": "https://buyer.ondc.buyerapp.com/protocol/v1",
                "bpp_id": "seller.mandisync.ai",
                "bpp_uri": "https://seller.mandisync.ai/ondc",
                "transaction_id": "txn_mandisync_001",
                "message_id": "msg_mandisync_001",
                "timestamp": "2026-09-09T17:30:00.000Z",
                "ttl": "PT30S"
            }
        }
    )


# ------------------------------------------
# Beckn Common Primitives
# ------------------------------------------

class ONDCTag(BaseModel):
    code: str = Field(..., description="Tag code/key")
    list: Optional[List[Dict[str, str]]] = Field(default_factory=list, description="Tag key-value parameters")


class ONDCAddress(BaseModel):
    door: Optional[str] = None
    name: Optional[str] = None
    building: Optional[str] = None
    street: Optional[str] = None
    locality: Optional[str] = None
    ward: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = "IND"
    area_code: Optional[str] = Field(None, description="Pincode / Postal area code e.g. 422306")


class ONDCLocation(BaseModel):
    id: Optional[str] = None
    gps: Optional[str] = Field(None, description="Latitude, Longitude coordinates e.g. '20.0827,74.1202'")
    address: Optional[ONDCAddress] = None


class ONDCEndLocation(BaseModel):
    location: Optional[ONDCLocation] = None
    contact: Optional[Dict[str, str]] = None


# ------------------------------------------
# ONDC /search Payload Schemas
# ------------------------------------------

class ONDCItemIntent(BaseModel):
    id: Optional[str] = Field(None, description="Specific SKU / Item ID")
    descriptor: Optional[CropDescriptor] = Field(None, description="Item name or query descriptor")
    category_id: Optional[str] = None
    fulfillment_id: Optional[str] = None
    tags: Optional[List[ONDCTag]] = Field(default_factory=list)


class ONDCCategoryIntent(BaseModel):
    id: Optional[str] = None
    descriptor: Optional[CropDescriptor] = None


class ONDCProviderIntent(BaseModel):
    id: Optional[str] = None
    descriptor: Optional[CropDescriptor] = None
    locations: Optional[List[ONDCLocation]] = Field(default_factory=list)


class ONDCFulfillmentIntent(BaseModel):
    id: Optional[str] = None
    type: Optional[str] = Field("Delivery", description="Fulfillment mode: Delivery, Pickup, etc.")
    end: Optional[ONDCEndLocation] = None
    tracking: Optional[bool] = False


class ONDCPaymentIntent(BaseModel):
    collected_by: Optional[str] = None
    finder_fee_type: Optional[str] = Field(None, alias="@ondc/org/buyer_app_finder_fee_type")
    finder_fee_amount: Optional[str] = Field(None, alias="@ondc/org/buyer_app_finder_fee_amount")

    model_config = ConfigDict(populate_by_name=True)


class ONDCSearchIntent(BaseModel):
    item: Optional[ONDCItemIntent] = None
    category: Optional[ONDCCategoryIntent] = None
    provider: Optional[ONDCProviderIntent] = None
    fulfillment: Optional[ONDCFulfillmentIntent] = None
    payment: Optional[ONDCPaymentIntent] = None
    tags: Optional[List[ONDCTag]] = Field(default_factory=list)


class ONDCSearchMessage(BaseModel):
    intent: Optional[ONDCSearchIntent] = Field(default_factory=ONDCSearchIntent, description="Buyer search intent parameters")


class ONDCSearchRequest(BaseModel):
    context: ONDCContext
    message: ONDCSearchMessage


# ------------------------------------------
# ONDC /select Payload Schemas
# ------------------------------------------

class ONDCItemQuantity(BaseModel):
    count: Optional[int] = Field(1, ge=1, description="Quantity count")
    measure: Optional[Dict[str, Any]] = Field(None, description="Weight or volume measurement e.g. {value: 10, unit: 'QUINTAL'}")


class ONDCSelectedItem(BaseModel):
    id: str = Field(..., description="Unique SKU Item ID selected from seller catalog")
    location_id: Optional[str] = Field(None, description="Location ID of provider fulfillment origin")
    quantity: ONDCItemQuantity = Field(default_factory=ONDCItemQuantity, description="Selected item quantity")
    parent_item_id: Optional[str] = None
    tags: Optional[List[ONDCTag]] = Field(default_factory=list)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "id": "ITEM-ONION-LASALGAON-001",
                "location_id": "MH-LAS-01",
                "quantity": {
                    "count": 5,
                    "measure": {"unit": "QUINTAL", "value": 5}
                }
            }
        }
    )


class ONDCProviderLocation(BaseModel):
    id: str = Field(..., description="Provider location identifier")


class ONDCSelectedProvider(BaseModel):
    id: str = Field(..., description="Selected seller / mandi / FPO provider ID")
    locations: Optional[List[ONDCProviderLocation]] = Field(default_factory=list, description="Provider dispatch locations")


class ONDCSelectedFulfillment(BaseModel):
    id: Optional[str] = Field(None, description="Fulfillment identifier")
    type: Optional[str] = Field("Delivery", description="Fulfillment type: Delivery or Self-Pickup")
    end: Optional[ONDCEndLocation] = Field(None, description="Buyer delivery dropoff location & address")


class ONDCSelectOrder(BaseModel):
    provider: ONDCSelectedProvider = Field(..., description="Selected seller/mandi provider")
    items: List[ONDCSelectedItem] = Field(..., min_length=1, description="List of items selected for quote generation")
    fulfillments: Optional[List[ONDCSelectedFulfillment]] = Field(default_factory=list, description="Requested fulfillment terms")


class ONDCSelectMessage(BaseModel):
    order: ONDCSelectOrder = Field(..., description="Draft order containing selected items and provider")


class ONDCSelectRequest(BaseModel):
    context: ONDCContext
    message: ONDCSelectMessage


# ------------------------------------------
# Beckn Standard ACK/NACK Response Models
# ------------------------------------------

class ONDCAck(BaseModel):
    status: str = Field(default="ACK", description="Status code: ACK or NACK")


class ONDCError(BaseModel):
    type: Optional[str] = Field(None, description="Error type: CONTEXT-ERROR, CORE-ERROR, DOMAIN-ERROR, POLICY-ERROR")
    code: str = Field(..., description="Standard Beckn / ONDC error code e.g. 10000, 30000")
    path: Optional[str] = Field(None, description="JSON path where error originated")
    message: str = Field(..., description="Human-readable error description")


class ONDCResponse(BaseModel):
    message: Dict[str, Any] = Field(default_factory=lambda: {"ack": {"status": "ACK"}})
    error: Optional[ONDCError] = None


# ==========================================
# User & Authentication Schemas
# ==========================================

class UserRegister(BaseModel):
    username: str = Field(..., min_length=3, max_length=50, description="Unique username")
    password: str = Field(..., min_length=6, description="Plaintext password")
    email: Optional[str] = Field(None, description="Email address")
    full_name: Optional[str] = Field(None, description="Full name of user")
    role: str = Field(default="farmer", description="User role (farmer, mandi_admin, buyer, trader)")


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    password: Optional[str] = Field(None, min_length=6)
    role: Optional[str] = None


class UserResponse(BaseModel):
    username: str
    full_name: Optional[str] = None
    email: Optional[str] = None
    role: str = "farmer"
    disabled: bool = False


# ==========================================
# Logistics Domain Schemas
# ==========================================

class VehicleType(str, Enum):
    TRUCK = "TRUCK"                      # Standard heavy goods truck (>7.5T)
    LCV = "LCV"                          # Light Commercial Vehicle (1-7.5T)
    TRACTOR_TRAILER = "TRACTOR_TRAILER"  # Agricultural tractor with trailer
    MINI_TRUCK = "MINI_TRUCK"            # Mini trucks e.g. Tata Ace
    AUTO_RICKSHAW = "AUTO_RICKSHAW"      # For small intra-city loads


class ServiceStatus(str, Enum):
    AVAILABLE = "AVAILABLE"              # Free, at home base or origin
    EN_ROUTE = "EN_ROUTE"               # Currently carrying a load
    RETURNING_EMPTY = "RETURNING_EMPTY" # Completed delivery, heading back (backhaul opportunity!)
    OFFLINE = "OFFLINE"                  # Not taking bookings


class VehicleSpecification(BaseModel):
    vehicle_type: VehicleType = Field(default=VehicleType.LCV, description="Type of vehicle")
    registration_number: str = Field(..., description="Vehicle registration plate e.g. MH15AB1234")
    max_capacity_kg: float = Field(..., gt=0, description="Maximum carrying capacity in kilograms")
    refrigerated: bool = Field(default=False, description="Whether the vehicle has a refrigerated container")
    gps_enabled: bool = Field(default=True, description="Whether the vehicle has GPS tracking")


class LogisticsProviderCreate(BaseModel):
    """Schema for registering a new logistics provider / truck driver."""
    provider_name: str = Field(..., min_length=2, max_length=100, description="Driver or fleet operator name")
    phone: str = Field(..., description="Contact phone number")
    home_base: str = Field(..., description="Driver's home city/town (used for backhaul matching)")
    home_base_district: Optional[str] = Field(None, description="Home base district")
    home_base_state: Optional[str] = Field(default="Maharashtra", description="Home base state")
    vehicle: VehicleSpecification = Field(..., description="Vehicle details")
    base_fee_inr: float = Field(..., gt=0, description="Fixed base charge per trip in INR")
    per_km_rate_inr: float = Field(..., gt=0, description="Variable rate per kilometre in INR")
    operating_radius_km: float = Field(default=500.0, gt=0, description="Maximum operating distance from home base in km")
    status: ServiceStatus = Field(default=ServiceStatus.AVAILABLE, description="Current operational status")

    model_config = ConfigDict(json_schema_extra={
        "example": {
            "provider_name": "Raju Transport",
            "phone": "9876543210",
            "home_base": "Lasalgaon",
            "home_base_district": "Nashik",
            "home_base_state": "Maharashtra",
            "vehicle": {
                "vehicle_type": "LCV",
                "registration_number": "MH15AB1234",
                "max_capacity_kg": 3000.0,
                "refrigerated": False,
                "gps_enabled": True
            },
            "base_fee_inr": 1500.0,
            "per_km_rate_inr": 18.0,
            "operating_radius_km": 400.0,
            "status": "AVAILABLE"
        }
    })


class LogisticsProviderUpdate(BaseModel):
    """Partial update schema for logistics provider — all fields optional."""
    provider_name: Optional[str] = Field(None, min_length=2, max_length=100)
    phone: Optional[str] = None
    home_base: Optional[str] = None
    home_base_district: Optional[str] = None
    home_base_state: Optional[str] = None
    vehicle: Optional[VehicleSpecification] = None
    base_fee_inr: Optional[float] = Field(None, gt=0)
    per_km_rate_inr: Optional[float] = Field(None, gt=0)
    operating_radius_km: Optional[float] = Field(None, gt=0)
    status: Optional[ServiceStatus] = None
    # Real-time operational state (updated by driver app or dispatch system)
    current_location: Optional[str] = Field(None, description="Current city/town of the vehicle")
    current_load_kg: Optional[float] = Field(None, ge=0, description="Current cargo load in kg (0 = empty)")
    next_available_location: Optional[str] = Field(
        None,
        description="Location where vehicle will become available after completing current trip"
    )


class DeliveryQuoteRequest(BaseModel):
    """
    Input for calculating a delivery cost estimate.
    The system will search for RETURNING_EMPTY drivers near the origin
    to offer backhaul discounts automatically.
    """
    origin: str = Field(..., description="Pickup location city/town")
    destination: str = Field(..., description="Drop-off location city/town")
    weight_kg: float = Field(..., gt=0, description="Cargo weight in kilograms")
    distance_km: Optional[float] = Field(
        None, gt=0,
        description="Road distance in km (if not provided, a flat estimate is used)"
    )
    crop_type: Optional[str] = Field(None, description="Type of crop for refrigeration matching")
    preferred_vehicle_type: Optional[VehicleType] = Field(None, description="Optional vehicle preference")

    model_config = ConfigDict(json_schema_extra={
        "example": {
            "origin": "Lasalgaon",
            "destination": "Pune",
            "weight_kg": 2000.0,
            "distance_km": 210.0,
            "crop_type": "Onion",
            "preferred_vehicle_type": "LCV"
        }
    })


class DeliveryQuoteResponse(BaseModel):
    """
    Delivery cost estimate returned to the user.
    Includes a discount flag if a backhaul (empty return trip) driver was matched.
    """
    origin: str
    destination: str
    weight_kg: float
    distance_km: float
    estimated_cost_inr: float = Field(..., description="Total estimated delivery cost in INR")
    base_cost_inr: float = Field(..., description="Fixed base fee component")
    variable_cost_inr: float = Field(..., description="Distance-based variable charge")
    is_backhaul_discount: bool = Field(
        default=False,
        description="True if a returning-empty driver was matched, giving a discounted rate"
    )
    backhaul_discount_pct: float = Field(
        default=0.0,
        description="Percentage discount applied due to backhaul matching (0–40%)"
    )
    matched_provider_id: Optional[str] = Field(None, description="ID of the matched logistics provider")
    matched_provider_name: Optional[str] = Field(None, description="Name of the matched logistics provider")
    estimated_transit_days: float = Field(..., description="Estimated delivery time in days")
    notes: Optional[str] = Field(None, description="Any advisory notes (e.g. capacity mismatch)")


class BackhaulMatch(BaseModel):
    """
    Represents a backhaul opportunity — a pending crop shipment that can fill a
    vehicle currently heading back towards its home base (avoiding an empty return trip).
    """
    crop_listing_id: str = Field(..., description="ID of the crop listing needing transport")
    crop_name: str = Field(..., description="Crop commodity name")
    pickup_location: str = Field(..., description="Where the crop needs to be picked up")
    dropoff_location: str = Field(..., description="Where the crop needs to be delivered")
    weight_kg: float = Field(..., description="Estimated cargo weight in kg")
    farmer_contact: Optional[str] = Field(None, description="Farmer phone/ID for coordination")
    estimated_revenue_inr: float = Field(..., description="Estimated revenue for this backhaul load")
    alignment_score: float = Field(
        ..., ge=0.0, le=1.0,
        description="How well this backhaul aligns with the driver's return route (1.0 = perfect)"
    )

