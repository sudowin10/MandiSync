import uuid
import pytest


class TestCropsCRUD:
    """Comprehensive unit test suite for /crops endpoints (POST, GET, PUT, PATCH, DELETE)."""

    def test_create_crop_farmer_format(self, client):
        """Test creating a crop listing using the simplified farmer format."""
        payload = {
            "crop_name": "Nashik Garlic",
            "variety": "G-282",
            "category": "SPICE",
            "quantity": 50.0,
            "unit": "QUINTAL",
            "price": 8500.0,
            "location": "Pimpalgaon",
            "district": "Nashik",
            "state": "Maharashtra",
            "farmer_name": "Anil Jadhav",
            "status": "active"
        }
        res = client.post("/api/v1/crops", json=payload)
        assert res.status_code == 201
        data = res.json()
        assert data["crop_name"] == "Nashik Garlic"
        assert "id" in data
        assert data["status"] == "active"
        assert data["price"]["value"] == 8500.0
        assert data["quantity"]["available_quantity"] == 50.0

    def test_create_crop_ondc_format(self, client):
        """Test creating a crop listing using the full ONDC Beckn format."""
        crop_id = f"ITEM-TEST-ONDC-{uuid.uuid4().hex[:6]}"
        payload = {
            "id": crop_id,
            "descriptor": {
                "name": "Organic Alphonso Mango",
                "short_desc": "GI-tagged Ratnagiri Alphonso fresh harvest.",
                "images": []
            },
            "category": "FRUIT",
            "price": {
                "currency": "INR",
                "value": 12000.0,
                "estimated_mrp": 14000.0
            },
            "quantity": {
                "unit": "CRATE",
                "available_quantity": 200.0,
                "min_order_quantity": 2.0
            },
            "mandi_info": {
                "mandi_id": "MH-RAT-01",
                "market_name": "Ratnagiri Market",
                "district": "Ratnagiri",
                "state": "Maharashtra"
            },
            "variety": "Alphonso",
            "grade": "GRADE_A",
            "status": "active"
        }
        res = client.post("/api/v1/crops", json=payload)
        assert res.status_code == 201
        data = res.json()
        assert data["id"] == crop_id
        assert data["descriptor"]["name"] == "Organic Alphonso Mango"

        # Duplicate ID should return 400 Bad Request
        res_dup = client.post("/api/v1/crops", json=payload)
        assert res_dup.status_code == 400

    def test_list_crops_with_filters(self, client):
        """Test listing active crops and applying query parameter filters."""
        # 1. List without filters
        res = client.get("/api/v1/crops")
        assert res.status_code == 200
        assert isinstance(res.json(), list)

        # 2. Filter by commodity / crop_name
        res_crop = client.get("/api/v1/crops?crop_name=Garlic")
        assert res_crop.status_code == 200
        for item in res_crop.json():
            name = (item.get("descriptor", {}).get("name", "") + item.get("crop_name", "")).lower()
            assert "garlic" in name or "g-" in item.get("variety", "").lower()

        # 3. Filter by location
        res_loc = client.get("/api/v1/crops?location=Pimpalgaon")
        assert res_loc.status_code == 200

        # 4. Filter by status
        res_status = client.get("/api/v1/crops?status=active")
        assert res_status.status_code == 200

    def test_get_crop_by_id_success_and_not_found(self, client):
        """Test fetching a crop by ID and handling 404 for invalid IDs."""
        # Create a temporary crop
        crop_id = f"ITEM-GET-{uuid.uuid4().hex[:6]}"
        payload = {
            "id": crop_id,
            "descriptor": {"name": "Test Crop", "short_desc": "Description"},
            "category": "GRAIN",
            "price": {"currency": "INR", "value": 2200.0},
            "quantity": {"unit": "QUINTAL", "available_quantity": 80.0},
            "mandi_info": {
                "mandi_id": "MH-01",
                "market_name": "Akola",
                "district": "Akola",
                "state": "Maharashtra"
            }
        }
        res_create = client.post("/api/v1/crops", json=payload)
        assert res_create.status_code == 201

        # Fetch existing
        res_get = client.get(f"/api/v1/crops/{crop_id}")
        assert res_get.status_code == 200
        assert res_get.json()["id"] == crop_id

        # Non-existent ID returns 404
        res_missing = client.get("/api/v1/crops/NON_EXISTENT_ID_9999")
        assert res_missing.status_code == 404

    def test_put_replace_crop(self, client):
        """Test full replacement of a crop listing using PUT."""
        crop_id = f"ITEM-PUT-{uuid.uuid4().hex[:6]}"
        # 1. Create original
        client.post("/api/v1/crops", json={
            "id": crop_id,
            "descriptor": {"name": "Original Crop", "short_desc": "Old Desc"},
            "category": "VEGETABLE",
            "price": {"currency": "INR", "value": 1000.0},
            "quantity": {"unit": "QUINTAL", "available_quantity": 50.0},
            "mandi_info": {
                "mandi_id": "M1",
                "market_name": "Nagpur",
                "district": "Nagpur",
                "state": "Maharashtra"
            }
        })

        # 2. PUT replacement using Farmer format
        replacement_farmer = {
            "crop_name": "Replaced Organic Cotton",
            "variety": "Bt-2",
            "category": "CASH_CROP",
            "quantity": 150.0,
            "unit": "QUINTAL",
            "price": 6800.0,
            "location": "Wardha",
            "district": "Wardha",
            "state": "Maharashtra",
            "farmer_name": "Suresh",
            "status": "active"
        }
        res_put = client.put(f"/api/v1/crops/{crop_id}", json=replacement_farmer)
        assert res_put.status_code == 200
        data = res_put.json()
        assert data["id"] == crop_id
        assert data["descriptor"]["name"] == "Replaced Organic Cotton"
        assert data["price"]["value"] == 6800.0
        assert data["quantity"]["available_quantity"] == 150.0

        # 3. PUT to non-existent ID should return 404
        res_put_404 = client.put("/api/v1/crops/NOT_FOUND_SKU_123", json=replacement_farmer)
        assert res_put_404.status_code == 404

    def test_patch_crop_partial_update(self, client):
        """Test partial update of crop listing using PATCH."""
        crop_id = f"ITEM-PATCH-{uuid.uuid4().hex[:6]}"
        # Create initial crop
        client.post("/api/v1/crops", json={
            "id": crop_id,
            "descriptor": {"name": "Soybean Harvest", "short_desc": "Yellow Soybean"},
            "category": "OILSEED",
            "price": {"currency": "INR", "value": 4500.0},
            "quantity": {"unit": "QUINTAL", "available_quantity": 100.0},
            "mandi_info": {
                "mandi_id": "M2",
                "market_name": "Latur",
                "district": "Latur",
                "state": "Maharashtra"
            }
        })

        # 1. Partial update price & quantity
        patch_res = client.patch(f"/api/v1/crops/{crop_id}", json={
            "price": 4950.0,
            "quantity": 75.0,
            "status": "in_negotiation"
        })
        assert patch_res.status_code == 200
        updated = patch_res.json()
        assert updated["price"]["value"] == 4950.0
        assert updated["quantity"]["available_quantity"] == 75.0
        assert updated["status"] == "in_negotiation"

        # 2. Empty patch body should return 400
        empty_patch = client.patch(f"/api/v1/crops/{crop_id}", json={})
        assert empty_patch.status_code == 400

        # 3. Non-existent ID should return 404
        missing_patch = client.patch("/api/v1/crops/DOES_NOT_EXIST", json={"price": 3000.0})
        assert missing_patch.status_code == 404

    def test_delete_crop(self, client):
        """Test deleting a crop listing using DELETE."""
        crop_id = f"ITEM-DEL-{uuid.uuid4().hex[:6]}"
        client.post("/api/v1/crops", json={
            "id": crop_id,
            "descriptor": {"name": "To be deleted", "short_desc": "Temporary"},
            "category": "VEGETABLE",
            "price": {"currency": "INR", "value": 500.0},
            "quantity": {"unit": "BAG", "available_quantity": 10.0},
            "mandi_info": {
                "mandi_id": "M3",
                "market_name": "Nashik",
                "district": "Nashik",
                "state": "Maharashtra"
            }
        })

        # 1. Delete existing
        res_del = client.delete(f"/api/v1/crops/{crop_id}")
        assert res_del.status_code == 200
        assert res_del.json()["status"] == "success"

        # 2. Subsequent GET should return 404
        assert client.get(f"/api/v1/crops/{crop_id}").status_code == 404

        # 3. Subsequent DELETE should return 404
        assert client.delete(f"/api/v1/crops/{crop_id}").status_code == 404
