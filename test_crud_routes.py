import asyncio
import sys
from pathlib import Path

# Add repo root to path
REPO_ROOT = Path(__file__).resolve().parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from fastapi.testclient import TestClient
from backend_api.app.main import app

def test_all_routes():
    print("=======================================================================")
    print("          MANDISYNC AI - API & CRUD ROUTES VERIFICATION TEST           ")
    print("=======================================================================")

    with TestClient(app) as client:
        # 1. Health Check
        res = client.get("/")
        print(f"\n[+] GET / -> Status {res.status_code}")
        print(f"    Payload: {res.json()}")
        assert res.status_code == 200

        # 2. CRUD - Market Prices
        print("\n--- Testing Market Prices CRUD ---")
        new_price = {
            "state": "Maharashtra",
            "district": "Pune",
            "market": "Pune APMC",
            "commodity": "Potato",
            "variety": "Jyoti",
            "arrival_date": "2026-09-09",
            "min_price": 1400.0,
            "max_price": 1850.0,
            "modal_price": 1650.0,
            "arrival_tonnes": 500.0
        }
        create_price_res = client.post("/api/v1/market_prices", json=new_price)
        print(f" * POST /api/v1/market_prices -> Status {create_price_res.status_code}")
        assert create_price_res.status_code == 201
        created_price_doc = create_price_res.json()
        record_id = created_price_doc["id"]
        print(f"   Created Record ID: {record_id}")

        # List
        list_price_res = client.get("/api/v1/market_prices?commodity=Potato")
        print(f" * GET /api/v1/market_prices?commodity=Potato -> Status {list_price_res.status_code}, Found: {len(list_price_res.json())}")
        assert list_price_res.status_code == 200

        # Get by ID
        get_price_res = client.get(f"/api/v1/market_prices/{record_id}")
        print(f" * GET /api/v1/market_prices/{record_id} -> Status {get_price_res.status_code}")
        assert get_price_res.status_code == 200

        # Patch
        patch_price_res = client.patch(f"/api/v1/market_prices/{record_id}", json={"modal_price": 1700.0})
        print(f" * PATCH /api/v1/market_prices/{record_id} -> Status {patch_price_res.status_code}")
        assert patch_price_res.status_code == 200
        assert patch_price_res.json()["modal_price"] == 1700.0

        # Delete
        del_price_res = client.delete(f"/api/v1/market_prices/{record_id}")
        print(f" * DELETE /api/v1/market_prices/{record_id} -> Status {del_price_res.status_code}")
        assert del_price_res.status_code == 200

        # 3. CRUD - Crop Listings
        print("\n--- Testing Crop Listings CRUD ---")
        new_crop = {
            "id": "ITEM-TEST-PUNE-POTATO-99",
            "descriptor": {
                "name": "Pune Fresh Jyoti Potato",
                "short_desc": "Directly from Pune APMC market yard."
            },
            "category": "VEGETABLE",
            "price": {
                "currency": "INR",
                "value": 1650.0,
                "estimated_mrp": 2000.0
            },
            "quantity": {
                "unit": "QUINTAL",
                "available_quantity": 150.0,
                "min_order_quantity": 5.0
            },
            "mandi_info": {
                "mandi_id": "MH-PUN-01",
                "market_name": "Pune APMC",
                "district": "Pune",
                "state": "Maharashtra"
            },
            "variety": "Jyoti"
        }
        create_crop_res = client.post("/api/v1/crops", json=new_crop)
        print(f" * POST /api/v1/crops -> Status {create_crop_res.status_code}")
        assert create_crop_res.status_code == 201
        created_crop = create_crop_res.json()
        print(f"   Created Crop SKU: {created_crop['id']} (AI Forecast: {created_crop.get('ai_predicted_max_price')})")

        # List
        list_crops_res = client.get("/api/v1/crops?commodity=Potato")
        print(f" * GET /api/v1/crops?commodity=Potato -> Status {list_crops_res.status_code}, Found: {len(list_crops_res.json())}")
        assert list_crops_res.status_code == 200

        # Get by ID
        get_crop_res = client.get("/api/v1/crops/ITEM-TEST-PUNE-POTATO-99")
        print(f" * GET /api/v1/crops/ITEM-TEST-PUNE-POTATO-99 -> Status {get_crop_res.status_code}")
        assert get_crop_res.status_code == 200

        # Patch
        patch_crop_res = client.patch("/api/v1/crops/ITEM-TEST-PUNE-POTATO-99", json={"grade": "GRADE_A"})
        print(f" * PATCH /api/v1/crops/ITEM-TEST-PUNE-POTATO-99 -> Status {patch_crop_res.status_code}")
        assert patch_crop_res.status_code == 200

        # Delete
        del_crop_res = client.delete("/api/v1/crops/ITEM-TEST-PUNE-POTATO-99")
        print(f" * DELETE /api/v1/crops/ITEM-TEST-PUNE-POTATO-99 -> Status {del_crop_res.status_code}")
        assert del_crop_res.status_code == 200

        # 4. AI Prediction Endpoint
        print("\n--- Testing AI Price Prediction Endpoint ---")
        pred_res = client.get("/api/v1/predict?commodity=Onion&market=Lasalgaon&modal_price=2450&min_price=2100&arrivals=1150")
        print(f" * GET /api/v1/predict -> Status {pred_res.status_code}")
        print(f"   Prediction Output: {pred_res.json()}")
        assert pred_res.status_code == 200

    print("\n=======================================================================")
    print("            ALL CRUD ROUTES AND API ENDPOINTS VERIFIED!               ")
    print("=======================================================================")

if __name__ == "__main__":
    test_all_routes()
