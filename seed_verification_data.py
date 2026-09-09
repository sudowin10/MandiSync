import asyncio
import logging
from datetime import datetime, timezone
from backend_api.app.services.database import db_manager

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("mandi_seeder")

SAMPLE_CROPS = [
    {
        "id": "ITEM-ONION-LASALGAON-001",
        "descriptor": {
            "name": "Lasalgaon Grade-A Red Onion",
            "code": "HSN-07031010",
            "short_desc": "Export-quality sun-cured Nashik red onions directly from APMC Lasalgaon yard.",
            "long_desc": "High pungency, uniform bulb diameter (55mm+), cured with less than 5% moisture loss.",
            "images": ["https://assets.mandisync.ai/crops/onion_lasalgaon_a.jpg"]
        },
        "category": "VEGETABLE",
        "price": {
            "currency": "INR",
            "value": 2650.0,
            "estimated_mrp": 3100.0,
            "minimum_order_value": 10000.0
        },
        "quantity": {
            "unit": "QUINTAL",
            "available_quantity": 350.0,
            "min_order_quantity": 5.0,
            "max_order_quantity": 100.0
        },
        "mandi_info": {
            "mandi_id": "MH-LAS-01",
            "market_name": "Lasalgaon APMC",
            "district": "Nashik",
            "state": "Maharashtra",
            "pincode": "422306",
            "gps": "20.1478,74.2268"
        },
        "variety": "Garva Red",
        "grade": "GRADE_A",
        "harvest_date": "2026-09-02",
        "shelf_life_days": 45,
        "organic_certified": False,
        "farmer_id": "FPO-MAH-NASHIK-9921",
        "ai_predicted_max_price": 2840.50,
        "ai_recommended_msp": 2550.00,
        "tags": {
            "ondc_bap_search_enabled": True,
            "quality_inspection": "Agmarknet-Certified"
        },
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat()
    },
    {
        "id": "ITEM-WHEAT-SEHORE-002",
        "descriptor": {
            "name": "Sehore Premium Sharbati Golden Wheat",
            "code": "HSN-10019910",
            "short_desc": "Finest golden grain Sharbati wheat from the black soil of Sehore, Madhya Pradesh.",
            "long_desc": "Lustrous heavy grain, high protein content (14%), moisture under 10%.",
            "images": ["https://assets.mandisync.ai/crops/wheat_sehore.jpg"]
        },
        "category": "GRAIN",
        "price": {
            "currency": "INR",
            "value": 3850.0,
            "estimated_mrp": 4400.0,
            "minimum_order_value": 15000.0
        },
        "quantity": {
            "unit": "QUINTAL",
            "available_quantity": 500.0,
            "min_order_quantity": 10.0,
            "max_order_quantity": 250.0
        },
        "mandi_info": {
            "mandi_id": "MP-SEH-01",
            "market_name": "Sehore Krishi Upaj Mandi",
            "district": "Sehore",
            "state": "Madhya Pradesh",
            "pincode": "466001",
            "gps": "23.2031,77.0844"
        },
        "variety": "Sharbati C-306",
        "grade": "GRADE_A",
        "harvest_date": "2026-08-25",
        "shelf_life_days": 180,
        "organic_certified": True,
        "farmer_id": "FPO-MP-SEHORE-4412",
        "ai_predicted_max_price": 4120.00,
        "ai_recommended_msp": 3700.00,
        "tags": {
            "ondc_bap_search_enabled": True,
            "organic_cert_no": "NPOP/NAB/0019"
        },
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat()
    },
    {
        "id": "ITEM-TOMATO-KOLAR-003",
        "descriptor": {
            "name": "Kolar Hybrid Red Firm Tomato",
            "code": "HSN-07020000",
            "short_desc": "Freshly picked firm table tomatoes from Kolar APMC vegetable terminal.",
            "long_desc": "Thick pericarp suitable for long distance transport, 80-90% red maturity, zero puncture defects.",
            "images": ["https://assets.mandisync.ai/crops/tomato_kolar.jpg"]
        },
        "category": "VEGETABLE",
        "price": {
            "currency": "INR",
            "value": 1950.0,
            "estimated_mrp": 2400.0,
            "minimum_order_value": 8000.0
        },
        "quantity": {
            "unit": "QUINTAL",
            "available_quantity": 200.0,
            "min_order_quantity": 5.0,
            "max_order_quantity": 50.0
        },
        "mandi_info": {
            "mandi_id": "KA-KOL-02",
            "market_name": "Kolar APMC Mandi",
            "district": "Kolar",
            "state": "Karnataka",
            "pincode": "563101",
            "gps": "13.1367,78.1292"
        },
        "variety": "Abhinav Hybrid",
        "grade": "GRADE_A",
        "harvest_date": "2026-09-08",
        "shelf_life_days": 12,
        "organic_certified": False,
        "farmer_id": "FPO-KA-KOLAR-7731",
        "ai_predicted_max_price": 2280.00,
        "ai_recommended_msp": 1850.00,
        "tags": {
            "ondc_bap_search_enabled": True,
            "cold_chain_compatible": True
        },
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
]

SAMPLE_PRICES = [
    {
        "state": "Maharashtra",
        "district": "Nashik",
        "market": "Lasalgaon",
        "commodity": "Onion",
        "variety": "Red Onion",
        "arrival_date": "2026-09-09",
        "min_price": 2250.0,
        "max_price": 2890.0,
        "modal_price": 2580.0,
        "arrival_tonnes": 1450.0,
        "created_at": datetime.now(timezone.utc).isoformat()
    },
    {
        "state": "Madhya Pradesh",
        "district": "Sehore",
        "market": "Sehore",
        "commodity": "Wheat",
        "variety": "Sharbati",
        "arrival_date": "2026-09-09",
        "min_price": 3600.0,
        "max_price": 4200.0,
        "modal_price": 3900.0,
        "arrival_tonnes": 820.0,
        "created_at": datetime.now(timezone.utc).isoformat()
    },
    {
        "state": "Karnataka",
        "district": "Kolar",
        "market": "Kolar",
        "commodity": "Tomato",
        "variety": "Hybrid",
        "arrival_date": "2026-09-09",
        "min_price": 1700.0,
        "max_price": 2350.0,
        "modal_price": 2050.0,
        "arrival_tonnes": 960.0,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
]

async def seed_data():
    logger.info("Initializing connection to remote MongoDB...")
    success = await db_manager.connect_to_mongo()
    if not success:
        logger.error("Failed to connect to MongoDB!")
        return

    db = db_manager.get_database()
    logger.info(f"Target Database: '{db.name}'")

    # 1. Seed ONDC Crop Listings into 'crops' collection
    crop_coll = db_manager.get_collection("crops")
    logger.info("Inserting ONDC Crop Listings into 'crops' collection...")
    crop_results = []
    for crop in SAMPLE_CROPS:
        res = await crop_coll.update_one(
            {"id": crop["id"]},
            {"$set": crop},
            upsert=True
        )
        crop_results.append(crop["id"])
    logger.info(f"Successfully upserted {len(crop_results)} crops: {crop_results}")

    # 2. Seed Agmarknet Market Prices into 'market_prices' collection
    price_coll = db_manager.get_collection("market_prices")
    logger.info("Inserting Agmarknet price records into 'market_prices' collection...")
    price_ids = []
    for price in SAMPLE_PRICES:
        res = await price_coll.insert_one(price)
        price_ids.append(str(res.inserted_id))
    logger.info(f"Successfully inserted {len(price_ids)} market price records. IDs: {price_ids}")

    # 3. Read back and verify
    print("\n" + "="*70)
    print("           DATABASE VERIFICATION REPORT (LIVE MONGODB CLUSTER)      ")
    print("="*70)

    total_crops = await crop_coll.count_documents({})
    total_prices = await price_coll.count_documents({})
    print(f"\n>> Collections in '{db.name}': {await db.list_collection_names()}")
    print(f">> Total documents in 'crops': {total_crops}")
    print(f">> Total documents in 'market_prices': {total_prices}")

    print("\n--- Current Crop Listings in 'crops' ---")
    async for c in crop_coll.find({}).limit(5):
        print(f" * SKU: {c.get('id')} | Name: {c['descriptor']['name']} | Price: Rs {c['price']['value']}/Quintal | Mandi: {c['mandi_info']['market_name']} ({c['mandi_info']['state']})")

    print("\n--- Recent Market Prices in 'market_prices' ---")
    async for p in price_coll.find({}).sort("_id", -1).limit(5):
        print(f" * Commodity: {p.get('commodity')} ({p.get('variety')}) | Market: {p.get('market')}, {p.get('state')} | Modal: Rs {p.get('modal_price')} | Max: Rs {p.get('max_price')} | Date: {p.get('arrival_date')}")

    print("="*70 + "\n")

    await db_manager.close_mongo_connection()
    logger.info("Verification finished & connection closed cleanly.")

if __name__ == "__main__":
    asyncio.run(seed_data())
