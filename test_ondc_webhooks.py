import sys
from pathlib import Path

# Add project root to sys.path
REPO_ROOT = Path(__file__).resolve().parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from fastapi.testclient import TestClient
from backend_api.app.main import app

def test_ondc_webhooks():
    print("=================================================================")
    print("        TESTING ONDC /search AND /select WEBHOOK ROUTES          ")
    print("=================================================================")

    with TestClient(app) as client:
        # 1. Test POST /ondc/search
        print("\n[1] Testing POST /api/v1/ondc/search with strict Beckn payload...")
        search_payload = {
            "context": {
                "domain": "nic2004:52110",
                "country": "IND",
                "city": "std:0253",
                "action": "search",
                "core_version": "1.2.0",
                "bap_id": "buyer.ondc.buyerapp.com",
                "bap_uri": "https://buyer.ondc.buyerapp.com/protocol/v1",
                "transaction_id": "txn_test_search_101",
                "message_id": "msg_test_search_101",
                "timestamp": "2026-09-09T17:40:00.000Z",
                "ttl": "PT30S"
            },
            "message": {
                "intent": {
                    "item": {
                        "descriptor": {
                            "name": "Nashik Red Onion",
                            "short_desc": "Looking for fresh grade A red onion."
                        }
                    },
                    "fulfillment": {
                        "type": "Delivery",
                        "end": {
                            "location": {
                                "gps": "20.0827,74.1202",
                                "address": {
                                    "area_code": "422306",
                                    "city": "Nashik",
                                    "state": "Maharashtra"
                                }
                            }
                        }
                    }
                }
            }
        }

        res_search = client.post("/api/v1/ondc/search", json=search_payload)
        print(f" -> Status: {res_search.status_code}")
        print(f" -> Response Body: {res_search.json()}")
        assert res_search.status_code == 200, f"Expected 200, got {res_search.status_code}: {res_search.text}"
        assert res_search.json().get("message", {}).get("ack", {}).get("status") == "ACK"

        # 2. Test POST /ondc/select
        print("\n[2] Testing POST /api/v1/ondc/select with strict Beckn payload...")
        select_payload = {
            "context": {
                "domain": "nic2004:52110",
                "country": "IND",
                "city": "std:0253",
                "action": "select",
                "core_version": "1.2.0",
                "bap_id": "buyer.ondc.buyerapp.com",
                "bap_uri": "https://buyer.ondc.buyerapp.com/protocol/v1",
                "bpp_id": "seller.mandisync.ai",
                "bpp_uri": "https://seller.mandisync.ai/ondc",
                "transaction_id": "txn_test_select_202",
                "message_id": "msg_test_select_202",
                "timestamp": "2026-09-09T17:45:00.000Z",
                "ttl": "PT30S"
            },
            "message": {
                "order": {
                    "provider": {
                        "id": "MANDI-LAS-01",
                        "locations": [
                            {"id": "LOC-LAS-01"}
                        ]
                    },
                    "items": [
                        {
                            "id": "ITEM-ONION-LASALGAON-001",
                            "location_id": "LOC-LAS-01",
                            "quantity": {
                                "count": 10,
                                "measure": {
                                    "unit": "QUINTAL",
                                    "value": 10
                                }
                            }
                        }
                    ],
                    "fulfillments": [
                        {
                            "id": "FULFILLMENT-01",
                            "type": "Delivery",
                            "end": {
                                "location": {
                                    "gps": "18.5204,73.8567",
                                    "address": {
                                        "area_code": "411001",
                                        "city": "Pune",
                                        "state": "Maharashtra"
                                    }
                                }
                            }
                        }
                    ]
                }
            }
        }

        res_select = client.post("/api/v1/ondc/select", json=select_payload)
        print(f" -> Status: {res_select.status_code}")
        print(f" -> Response Body: {res_select.json()}")
        assert res_select.status_code == 200, f"Expected 200, got {res_select.status_code}: {res_select.text}"
        assert res_select.json().get("message", {}).get("ack", {}).get("status") == "ACK"

        # 3. Test Strict Validation Failure on Malformed Payload
        print("\n[3] Testing Strict Pydantic Validation on Malformed Payload...")
        malformed_select_payload = {
            "context": {
                "domain": "nic2004:52110"
                # Missing required context fields: country, city, action, bap_id, transaction_id, etc.
            },
            "message": {
                "order": {
                    # Missing provider and items
                }
            }
        }
        res_malformed = client.post("/api/v1/ondc/select", json=malformed_select_payload)
        print(f" -> Malformed payload rejected with Status: {res_malformed.status_code}")
        assert res_malformed.status_code == 422, f"Expected 422 Unprocessable Entity, got {res_malformed.status_code}"
        print(" -> Correctly enforced strict schema validation!")

    print("\n=================================================================")
    print("      ALL ONDC /search AND /select WEBHOOKS VERIFIED (200 OK)!   ")
    print("=================================================================")

if __name__ == "__main__":
    test_ondc_webhooks()
