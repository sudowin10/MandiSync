import pytest
from fastapi.testclient import TestClient


class TestMockAndScaffoldRoutes:
    """Test the mock/scaffold routes created for frontend developer integration."""

    def test_mock_register(self, client: TestClient):
        resp = client.post("/api/v1/register")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "success"
        assert data["message"] == "User registered"

    def test_mock_stats(self, client: TestClient):
        resp = client.get("/api/v1/stats")
        assert resp.status_code == 200
        data = resp.json()
        assert data["total_sales"] == 15000
        assert data["active_orders"] == 4

    def test_mock_transactions_and_history(self, client: TestClient):
        resp_tx = client.get("/api/v1/transactions")
        assert resp_tx.status_code == 200
        assert resp_tx.json() == {"data": []}

        resp_hist = client.get("/api/v1/history")
        assert resp_hist.status_code == 200
        assert resp_hist.json() == {"data": []}

    def test_mock_kyc_start(self, client: TestClient):
        resp_aadhaar = client.post("/api/v1/auth/aadhaar/start")
        assert resp_aadhaar.status_code == 200
        assert resp_aadhaar.json() == {"status": "otp_sent", "reference_id": "mock_123"}

        resp_digi = client.post("/api/v1/auth/digilocker/start")
        assert resp_digi.status_code == 200
        assert resp_digi.json() == {"status": "otp_sent", "reference_id": "mock_123"}

    def test_cors_preflight(self, client: TestClient):
        headers = {
            "Origin": "http://localhost:5500",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "Content-Type",
        }
        resp = client.options("/api/v1/register", headers=headers)
        assert resp.status_code == 200
        assert resp.headers.get("access-control-allow-origin") == "http://localhost:5500"
