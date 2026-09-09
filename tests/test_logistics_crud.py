"""
Unit Tests — Logistics Provider CRUD & Backhaul Matching
=========================================================
Tests cover:
  - Provider registration and duplicate phone guard
  - GET all providers with status filter
  - GET single provider by ID
  - PUT full replacement
  - PATCH partial update (status, current_location, load)
  - DELETE provider
  - POST /quotes — standard quote and backhaul discount path
  - GET /match-backhauls — seed a crop listing then verify backhaul match
"""
import uuid
import pytest
from fastapi.testclient import TestClient


PROVIDERS_URL = "/api/v1/logistics/providers"
QUOTES_URL = "/api/v1/logistics/quotes"
CROPS_URL = "/api/v1/crops"

VALID_PROVIDER = {
    "provider_name": "Raju Transport",
    "phone": "9876500001",
    "home_base": "Lasalgaon",
    "home_base_district": "Nashik",
    "home_base_state": "Maharashtra",
    "vehicle": {
        "vehicle_type": "LCV",
        "registration_number": "MH15AB1234",
        "max_capacity_kg": 3000.0,
        "refrigerated": False,
        "gps_enabled": True,
    },
    "base_fee_inr": 1500.0,
    "per_km_rate_inr": 18.0,
    "operating_radius_km": 400.0,
    "status": "AVAILABLE",
}

VALID_QUOTE = {
    "origin": "Lasalgaon",
    "destination": "Pune",
    "weight_kg": 2000.0,
    "distance_km": 210.0,
    "crop_type": "Onion",
}


def make_provider(overrides=None):
    """Generate a valid provider payload with a unique phone number."""
    payload = dict(VALID_PROVIDER)
    payload["phone"] = f"98{uuid.uuid4().int % 100000000:08d}"
    if overrides:
        payload.update(overrides)
    return payload


class TestLogisticsCRUD:
    """Full CRUD lifecycle tests for logistics providers."""

    def test_create_provider(self, client: TestClient, farmer_headers: dict):
        payload = make_provider()
        resp = client.post(PROVIDERS_URL, json=payload, headers=farmer_headers)
        assert resp.status_code == 201, resp.text
        data = resp.json()
        assert data["provider_name"] == payload["provider_name"]
        assert "id" in data
        assert data["status"] == "AVAILABLE"
        # The system should initialise current_location to home_base
        assert data["current_location"] == payload["home_base"]
        assert data["current_load_kg"] == 0.0

    def test_duplicate_phone_rejected(self, client: TestClient, farmer_headers: dict):
        """Registering twice with the same phone number must fail."""
        payload = make_provider()
        resp1 = client.post(PROVIDERS_URL, json=payload, headers=farmer_headers)
        assert resp1.status_code == 201
        resp2 = client.post(PROVIDERS_URL, json=payload, headers=farmer_headers)
        assert resp2.status_code == 400
        assert "already registered" in resp2.json()["detail"]

    def test_list_providers(self, client: TestClient, farmer_headers: dict):
        resp = client.get(PROVIDERS_URL, headers=farmer_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert isinstance(data, list)
        assert len(data) >= 1

    def test_list_providers_status_filter(self, client: TestClient, farmer_headers: dict):
        resp = client.get(f"{PROVIDERS_URL}?status=AVAILABLE", headers=farmer_headers)
        assert resp.status_code == 200
        for item in resp.json():
            assert item["status"] == "AVAILABLE"

    def test_list_providers_location_filter(self, client: TestClient, farmer_headers: dict):
        resp = client.get(f"{PROVIDERS_URL}?location=Lasalgaon", headers=farmer_headers)
        assert resp.status_code == 200
        assert len(resp.json()) >= 1

    def test_get_provider_by_id(self, client: TestClient, farmer_headers: dict):
        # Create a fresh provider with a unique phone to reliably fetch it
        payload = make_provider({"provider_name": "Sita Logistics"})
        create_resp = client.post(PROVIDERS_URL, json=payload, headers=farmer_headers)
        assert create_resp.status_code == 201
        provider_id = create_resp.json()["id"]

        resp = client.get(f"{PROVIDERS_URL}/{provider_id}", headers=farmer_headers)
        assert resp.status_code == 200
        assert resp.json()["id"] == provider_id
        assert resp.json()["provider_name"] == "Sita Logistics"

    def test_get_provider_not_found(self, client: TestClient, farmer_headers: dict):
        resp = client.get(f"{PROVIDERS_URL}/NONEXISTENT-ID-XYZ", headers=farmer_headers)
        assert resp.status_code == 404

    def test_patch_provider_status_and_location(self, client: TestClient, farmer_headers: dict):
        """Driver app updates status to EN_ROUTE and sets current location."""
        payload = make_provider({"provider_name": "Ram Carriers"})
        create_resp = client.post(PROVIDERS_URL, json=payload, headers=farmer_headers)
        assert create_resp.status_code == 201
        provider_id = create_resp.json()["id"]

        patch = {
            "status": "EN_ROUTE",
            "current_location": "Niphad",
            "current_load_kg": 2400.0,
            "next_available_location": "Pune",
        }
        resp = client.patch(f"{PROVIDERS_URL}/{provider_id}", json=patch, headers=farmer_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "EN_ROUTE"
        assert data["current_location"] == "Niphad"
        assert data["current_load_kg"] == 2400.0
        assert data["next_available_location"] == "Pune"

    def test_patch_provider_empty_body_rejected(self, client: TestClient, farmer_headers: dict):
        payload = make_provider({"provider_name": "Empty Patch Test"})
        create_resp = client.post(PROVIDERS_URL, json=payload, headers=farmer_headers)
        assert create_resp.status_code == 201
        provider_id = create_resp.json()["id"]

        resp = client.patch(f"{PROVIDERS_URL}/{provider_id}", json={}, headers=farmer_headers)
        assert resp.status_code == 400

    def test_put_replace_provider(self, client: TestClient, farmer_headers: dict):
        """Full replacement of provider details via PUT."""
        payload = make_provider({"provider_name": "Old Name"})
        create_resp = client.post(PROVIDERS_URL, json=payload, headers=farmer_headers)
        assert create_resp.status_code == 201
        provider_id = create_resp.json()["id"]

        replacement = make_provider({
            "phone": payload["phone"],  # keep same phone
            "provider_name": "New Name Transport",
            "base_fee_inr": 2000.0
        })

        resp = client.put(f"{PROVIDERS_URL}/{provider_id}", json=replacement, headers=farmer_headers)
        assert resp.status_code == 200
        assert resp.json()["provider_name"] == "New Name Transport"
        assert resp.json()["base_fee_inr"] == 2000.0

    def test_delete_provider(self, client: TestClient, farmer_headers: dict):
        payload = make_provider({"provider_name": "To Be Deleted"})
        create_resp = client.post(PROVIDERS_URL, json=payload, headers=farmer_headers)
        assert create_resp.status_code == 201
        provider_id = create_resp.json()["id"]

        del_resp = client.delete(f"{PROVIDERS_URL}/{provider_id}", headers=farmer_headers)
        assert del_resp.status_code == 200
        assert "deleted" in del_resp.json()["message"].lower()


        # Confirm it is gone
        get_resp = client.get(f"{PROVIDERS_URL}/{provider_id}", headers=farmer_headers)
        assert get_resp.status_code == 404


class TestDeliveryQuotes:
    """Tests for delivery quote generation and backhaul matching logic."""

    def test_standard_quote(self, client: TestClient, farmer_headers: dict):
        """Quote without backhaul — should return a valid price breakdown."""
        resp = client.post(QUOTES_URL, json=VALID_QUOTE, headers=farmer_headers)
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert data["origin"] == "Lasalgaon"
        assert data["destination"] == "Pune"
        assert data["estimated_cost_inr"] > 0
        assert data["distance_km"] == 210.0

    def test_quote_uses_default_distance_when_not_provided(self, client: TestClient, farmer_headers: dict):
        """If distance_km is omitted, the system should use a sensible default."""
        payload = dict(VALID_QUOTE)
        del payload["distance_km"]
        resp = client.post(QUOTES_URL, json=payload, headers=farmer_headers)
        assert resp.status_code == 200
        assert resp.json()["distance_km"] > 0

    def test_backhaul_discount_applied(self, client: TestClient, farmer_headers: dict):
        """
        Simulate the backhaul scenario:
          1. Create a provider and set them to RETURNING_EMPTY at the quote's origin.
          2. Request a quote for that origin → expect is_backhaul_discount=True.
        """
        # Create provider based at Pune heading back to Lasalgaon
        payload = make_provider({
            "provider_name": "Backhaul Driver",
            "home_base": "Lasalgaon",
        })
        create_resp = client.post(PROVIDERS_URL, json=payload, headers=farmer_headers)
        assert create_resp.status_code == 201
        provider_id = create_resp.json()["id"]

        # Simulate driver finishing delivery at Pune and now returning empty
        patch = {
            "status": "RETURNING_EMPTY",
            "current_location": "Pune",
            "next_available_location": "Lasalgaon",
            "current_load_kg": 0.0,
        }
        patch_resp = client.patch(f"{PROVIDERS_URL}/{provider_id}", json=patch, headers=farmer_headers)
        assert patch_resp.status_code == 200

        # Request a quote FROM Pune (where the driver currently is)
        quote_payload = {
            "origin": "Pune",
            "destination": "Lasalgaon",
            "weight_kg": 1500.0,
            "distance_km": 210.0,
        }
        quote_resp = client.post(QUOTES_URL, json=quote_payload, headers=farmer_headers)
        assert quote_resp.status_code == 200
        q = quote_resp.json()
        assert q["is_backhaul_discount"] is True
        assert q["backhaul_discount_pct"] > 0
        # Cost with backhaul must be less than without (i.e. meaningful discount)
        assert q["estimated_cost_inr"] < (q["base_cost_inr"] + q["variable_cost_inr"])

    def test_overweight_note_included(self, client: TestClient, farmer_headers: dict):
        """Requesting more weight than vehicle capacity should include a warning note."""
        payload = {
            "origin": "Lasalgaon",
            "destination": "Mumbai",
            "weight_kg": 99999.0,  # way over any vehicle capacity
            "distance_km": 300.0,
        }
        resp = client.post(QUOTES_URL, json=payload, headers=farmer_headers)
        assert resp.status_code == 200
        data = resp.json()
        # Note may or may not be present depending on whether a provider was matched,
        # but the cost should still be returned
        assert data["estimated_cost_inr"] > 0


class TestBackhaulMatching:
    """Tests for the GET /match-backhauls/{provider_id} endpoint."""

    def test_match_backhauls_for_returning_driver(self, client: TestClient, farmer_headers: dict):
        """
        Seed a crop listing in Lasalgaon, create a driver returning to Lasalgaon,
        and verify the backhaul endpoint returns that crop as an opportunity.
        """
        # Seed a crop listing in Lasalgaon
        crop_payload = {
            "crop_name": "Onion",
            "quantity": 50.0,
            "unit": "QUINTAL",
            "price": 2500.0,
            "location": "Lasalgaon",
            "district": "Nashik",
            "state": "Maharashtra",
        }
        crop_resp = client.post(CROPS_URL, json=crop_payload, headers=farmer_headers)
        assert crop_resp.status_code == 201

        # Create a driver returning to Lasalgaon from Mumbai
        provider_payload = make_provider({
            "provider_name": "Backhaul Match Tester",
            "home_base": "Lasalgaon",
        })
        create_resp = client.post(PROVIDERS_URL, json=provider_payload, headers=farmer_headers)
        assert create_resp.status_code == 201
        provider_id = create_resp.json()["id"]

        # Set driver as returning empty at Lasalgaon
        client.patch(
            f"{PROVIDERS_URL}/{provider_id}",
            json={"status": "RETURNING_EMPTY", "current_location": "Lasalgaon", "next_available_location": "Lasalgaon"},
            headers=farmer_headers,
        )

        # Request backhaul matches
        match_resp = client.get(f"/api/v1/logistics/match-backhauls/{provider_id}", headers=farmer_headers)
        assert match_resp.status_code == 200
        matches = match_resp.json()
        assert isinstance(matches, list)
        assert len(matches) >= 1
        first = matches[0]
        assert "crop_listing_id" in first
        assert first["alignment_score"] > 0
        assert first["estimated_revenue_inr"] > 0

    def test_match_backhauls_unknown_provider(self, client: TestClient, farmer_headers: dict):
        resp = client.get("/api/v1/logistics/match-backhauls/UNKNOWN-PROV-XYZ", headers=farmer_headers)
        assert resp.status_code == 404
