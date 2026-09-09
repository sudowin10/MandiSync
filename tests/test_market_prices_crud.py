import pytest


class TestMarketPricesCRUD:
    """Comprehensive unit test suite for /market-prices and /market_prices CRUD."""

    def test_create_market_price_record(self, client):
        """Test POST endpoint to create a market price record."""
        payload = {
            "state": "Maharashtra",
            "district": "Solapur",
            "market": "Solapur APMC",
            "commodity": "Pomegranate",
            "variety": "Bhagwa",
            "arrival_date": "2026-09-09",
            "min_price": 5000.0,
            "max_price": 9500.0,
            "modal_price": 7500.0,
            "arrival_tonnes": 120.0
        }
        res = client.post("/api/v1/market-prices", json=payload)
        assert res.status_code == 201
        data = res.json()
        assert data["commodity"] == "Pomegranate"
        assert data["market"] == "Solapur APMC"
        assert data["modal_price"] == 7500.0
        assert "id" in data

    def test_list_and_filter_market_prices(self, client):
        """Test GET /market-prices with various filtering options."""
        # 1. List without filters
        res = client.get("/api/v1/market-prices")
        assert res.status_code == 200
        assert isinstance(res.json(), list)

        # 2. Filter by commodity
        res_com = client.get("/api/v1/market-prices?commodity=Pomegranate")
        assert res_com.status_code == 200
        records = res_com.json()
        assert len(records) > 0
        for r in records:
            assert "pomegranate" in r["commodity"].lower()

        # 3. Filter by location / market
        res_loc = client.get("/api/v1/market-prices?location=Solapur")
        assert res_loc.status_code == 200
        assert len(res_loc.json()) > 0

        # 4. Alternative endpoint alias /market_prices
        res_alias = client.get("/api/v1/market_prices")
        assert res_alias.status_code == 200

    def test_get_market_price_by_id(self, client):
        """Test fetching a market price record by ID."""
        # Create record
        create_res = client.post("/api/v1/market-prices", json={
            "state": "Gujarat",
            "district": "Rajkot",
            "market": "Rajkot APMC",
            "commodity": "Groundnut",
            "variety": "GG-20",
            "arrival_date": "2026-09-09",
            "min_price": 6000.0,
            "max_price": 7200.0,
            "modal_price": 6600.0,
            "arrival_tonnes": 300.0
        })
        rec_id = create_res.json()["id"]

        # Fetch existing
        get_res = client.get(f"/api/v1/market-prices/{rec_id}")
        assert get_res.status_code == 200
        assert get_res.json()["commodity"] == "Groundnut"

        # Non-existent ID returns 404
        assert client.get("/api/v1/market-prices/000000000000000000000000").status_code == 404

    def test_put_replace_market_price(self, client):
        """Test full replacement of a market price record using PUT."""
        # 1. Create record
        create_res = client.post("/api/v1/market-prices", json={
            "state": "Madhya Pradesh",
            "district": "Indore",
            "market": "Indore APMC",
            "commodity": "Soybean",
            "variety": "Yellow",
            "arrival_date": "2026-09-08",
            "min_price": 4200.0,
            "max_price": 4800.0,
            "modal_price": 4500.0,
            "arrival_tonnes": 450.0
        })
        rec_id = create_res.json()["id"]

        # 2. Fully replace with new data
        replacement = {
            "state": "Madhya Pradesh",
            "district": "Indore",
            "market": "Indore APMC",
            "commodity": "Soybean",
            "variety": "JS-9560",
            "arrival_date": "2026-09-09",
            "min_price": 4400.0,
            "max_price": 5100.0,
            "modal_price": 4800.0,
            "arrival_tonnes": 600.0
        }
        put_res = client.put(f"/api/v1/market-prices/{rec_id}", json=replacement)
        assert put_res.status_code == 200
        replaced = put_res.json()
        assert replaced["variety"] == "JS-9560"
        assert replaced["modal_price"] == 4800.0
        assert replaced["arrival_tonnes"] == 600.0

        # 3. PUT non-existent returns 404
        assert client.put("/api/v1/market-prices/000000000000000000000000", json=replacement).status_code == 404

    def test_patch_update_market_price(self, client):
        """Test partial field update using PATCH."""
        create_res = client.post("/api/v1/market-prices", json={
            "state": "Punjab",
            "district": "Ludhiana",
            "market": "Khanna Mandi",
            "commodity": "Wheat",
            "variety": "PBW-343",
            "arrival_date": "2026-09-09",
            "min_price": 2200.0,
            "max_price": 2400.0,
            "modal_price": 2300.0,
            "arrival_tonnes": 1500.0
        })
        rec_id = create_res.json()["id"]

        # 1. Patch modal_price and max_price
        patch_res = client.patch(f"/api/v1/market-prices/{rec_id}", json={
            "modal_price": 2350.0,
            "max_price": 2450.0
        })
        assert patch_res.status_code == 200
        patched = patch_res.json()
        assert patched["modal_price"] == 2350.0
        assert patched["max_price"] == 2450.0
        # Untouched fields remain intact
        assert patched["commodity"] == "Wheat"

        # 2. Empty patch body returns 400
        assert client.patch(f"/api/v1/market-prices/{rec_id}", json={}).status_code == 400

        # 3. Patch non-existent returns 404
        assert client.patch("/api/v1/market-prices/000000000000000000000000", json={"modal_price": 2500.0}).status_code == 404

    def test_delete_market_price_record(self, client):
        """Test deleting a market price record."""
        create_res = client.post("/api/v1/market-prices", json={
            "state": "Rajasthan",
            "district": "Kota",
            "market": "Kota APMC",
            "commodity": "Mustard",
            "variety": "Standard",
            "arrival_date": "2026-09-09",
            "min_price": 5100.0,
            "max_price": 5800.0,
            "modal_price": 5500.0,
            "arrival_tonnes": 200.0
        })
        rec_id = create_res.json()["id"]

        # 1. Delete
        del_res = client.delete(f"/api/v1/market-prices/{rec_id}")
        assert del_res.status_code == 200
        assert del_res.json()["status"] == "success"

        # 2. Subsequent GET returns 404
        assert client.get(f"/api/v1/market-prices/{rec_id}").status_code == 404

        # 3. Subsequent DELETE returns 404
        assert client.delete(f"/api/v1/market-prices/{rec_id}").status_code == 404
