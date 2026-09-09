import sys
from pathlib import Path

# Add project root to sys.path
REPO_ROOT = Path(__file__).resolve().parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from fastapi.testclient import TestClient
from backend_api.app.main import app

def test_requested_endpoints():
    print("=================================================================")
    print("    TESTING NEW CROPS AND MARKET-PRICES ENDPOINTS & HELPERS      ")
    print("=================================================================")

    with TestClient(app) as client:
        # 1. Test POST /crops with farmer crop listing
        print("\n[1] Testing POST /api/v1/crops (Farmer Crop Listing)...")
        farmer_crop_payload = {
            "crop_name": "Fresh Nashik Onion",
            "variety": "Garva Red",
            "category": "VEGETABLE",
            "quantity": 120.0,
            "unit": "QUINTAL",
            "price": 2450.0,
            "location": "Lasalgaon",
            "district": "Nashik",
            "state": "Maharashtra",
            "farmer_name": "Dinkar Rao",
            "status": "active"
        }
        res_post = client.post("/api/v1/crops", json=farmer_crop_payload)
        print(f" -> Status: {res_post.status_code}")
        assert res_post.status_code == 201, f"Expected 201, got {res_post.status_code}: {res_post.text}"
        created_data = res_post.json()
        print(f" -> Created Crop ID: {created_data.get('id')}")
        print(f" -> AI Forecast Price: {created_data.get('ai_predicted_max_price')}")
        print(f" -> AI Recommended Floor: {created_data.get('ai_recommended_msp')}")
        assert created_data.get("status") == "active"
        assert "_id" in created_data or "id" in created_data

        # 2. Test GET /crops (retrieving active listings)
        print("\n[2] Testing GET /api/v1/crops...")
        res_get_crops = client.get("/api/v1/crops?status=active")
        print(f" -> Status: {res_get_crops.status_code}")
        assert res_get_crops.status_code == 200
        crops_list = res_get_crops.json()
        print(f" -> Active Crop Listings retrieved: {len(crops_list)}")
        assert len(crops_list) > 0

        # Filter by crop_name
        res_filter = client.get("/api/v1/crops?crop_name=Onion")
        assert res_filter.status_code == 200
        print(f" -> Filtered by crop_name=Onion: {len(res_filter.json())} listings")

        # 3. Test GET /market-prices with query parameters for crop name and location
        print("\n[3] Testing GET /api/v1/market-prices...")
        res_market_all = client.get("/api/v1/market-prices")
        print(f" -> GET /api/v1/market-prices status: {res_market_all.status_code}")
        assert res_market_all.status_code == 200
        records = res_market_all.json()
        print(f" -> Total Market Price records: {len(records)}")

        # Query with crop_name and location
        print("\n[4] Testing GET /api/v1/market-prices?crop_name=Potato&location=Pune...")
        res_market_filtered = client.get("/api/v1/market-prices?crop_name=Potato&location=Pune")
        print(f" -> Status: {res_market_filtered.status_code}")
        assert res_market_filtered.status_code == 200
        filtered_records = res_market_filtered.json()
        print(f" -> Matching records found: {len(filtered_records)}")

        # Clean up test crop if needed
        crop_id_to_del = created_data.get("id")
        if crop_id_to_del:
            client.delete(f"/api/v1/crops/{crop_id_to_del}")
            print(f"\n[5] Cleaned up test crop {crop_id_to_del}")

    print("\n=================================================================")
    print("            ALL NEW ENDPOINTS VERIFIED SUCCESSFULLY!             ")
    print("=================================================================")

if __name__ == "__main__":
    test_requested_endpoints()
