import pytest


class TestAIPrediction:
    """Unit test suite for AI Price Prediction endpoints."""

    def test_predict_via_get_query_params(self, client):
        """Test GET /api/v1/predict with commodity, market, and price parameters."""
        res = client.get("/api/v1/predict?commodity=Onion&market=Lasalgaon&modal_price=2450&min_price=2100&arrivals=1150")
        assert res.status_code == 200
        data = res.json()
        assert data["status"] == "success"
        assert data["commodity"] == "Onion"
        assert data["market"] == "Lasalgaon"
        assert "predicted_max_price" in data
        assert "recommended_listing_price" in data
        assert "confidence_interval_low" in data
        assert "confidence_interval_high" in data
        assert data["predicted_max_price"] > 0

    def test_predict_via_post_json(self, client):
        """Test POST /api/v1/predict with JSON body."""
        payload = {
            "commodity": "Potato",
            "market": "Pune",
            "modal_price_lag1": 1650.0,
            "min_price_lag1": 1400.0,
            "arrival_tonnes": 500.0
        }
        res = client.post("/api/v1/predict", json=payload)
        assert res.status_code == 200
        data = res.json()
        assert data["status"] == "success"
        assert data["commodity"] == "Potato"
        assert "predicted_max_price" in data
