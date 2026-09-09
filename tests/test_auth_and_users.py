import uuid
import pytest


class TestAuthAndUsers:
    """Unit test suite for authentication and user profile management."""

    def test_login_success_and_failure(self, client):
        """Test login returns JWT token on valid credentials and 401 on invalid."""
        # 1. Success with built-in farmer credentials
        res = client.post("/api/v1/auth/login", json={
            "username": "farmer_user",
            "password": "password123"
        })
        assert res.status_code == 200
        token_data = res.json()
        assert "access_token" in token_data
        assert token_data["token_type"] == "bearer"

        # 2. Failure with wrong password
        res_fail = client.post("/api/v1/auth/login", json={
            "username": "farmer_user",
            "password": "wrongpassword"
        })
        assert res_fail.status_code == 401

        # 3. Failure with non-existent user
        res_nonexistent = client.post("/api/v1/auth/login", json={
            "username": "ghost_user_does_not_exist",
            "password": "any"
        })
        assert res_nonexistent.status_code == 401

    def test_register_new_user_and_duplicate_check(self, client):
        """Test user registration and duplicate prevention."""
        unique_name = f"farmer_{uuid.uuid4().hex[:6]}"
        reg_payload = {
            "username": unique_name,
            "password": "securepassword123",
            "full_name": "Balram Kisan",
            "email": f"{unique_name}@mandisync.ai",
            "role": "farmer"
        }

        # 1. Register via /api/v1/users/register
        reg_res = client.post("/api/v1/users/register", json=reg_payload)
        assert reg_res.status_code == 201
        data = reg_res.json()
        assert data["username"] == unique_name
        assert data["full_name"] == "Balram Kisan"
        assert data["role"] == "farmer"
        assert "hashed_password" not in data

        # 2. Duplicate registration returns 400
        dup_res = client.post("/api/v1/users/register", json=reg_payload)
        assert dup_res.status_code == 400

        # 3. Newly registered user can log in immediately
        login_res = client.post("/api/v1/auth/login", json={
            "username": unique_name,
            "password": "securepassword123"
        })
        assert login_res.status_code == 200
        assert "access_token" in login_res.json()

    def test_register_via_auth_alias(self, client):
        """Test registration via /api/v1/auth/register alias."""
        unique_name = f"buyer_{uuid.uuid4().hex[:6]}"
        reg_payload = {
            "username": unique_name,
            "password": "password456",
            "full_name": "Agro Buyer Ltd",
            "email": f"{unique_name}@agrobuyer.com",
            "role": "buyer"
        }
        res = client.post("/api/v1/auth/register", json=reg_payload)
        assert res.status_code == 201
        assert res.json()["username"] == unique_name

    def test_get_current_user_profile(self, client, farmer_headers):
        """Test /users/me endpoint with and without token."""
        # 1. Without token -> 401 Unauthorized
        res_no_auth = client.get("/api/v1/users/me")
        assert res_no_auth.status_code == 401

        # 2. With token -> 200 OK
        res_auth = client.get("/api/v1/users/me", headers=farmer_headers)
        assert res_auth.status_code == 200
        user_info = res_auth.json()
        assert user_info["username"] == "farmer_user"
        assert "hashed_password" not in user_info

    def test_update_and_delete_user_profile(self, client):
        """Test full user lifecycle: register, login, PUT/PATCH profile, and delete."""
        uname = f"testuser_{uuid.uuid4().hex[:6]}"
        client.post("/api/v1/users/register", json={
            "username": uname,
            "password": "testpassword123",
            "full_name": "Initial Name",
            "role": "trader"
        })

        # Login
        token = client.post("/api/v1/auth/login", json={
            "username": uname,
            "password": "testpassword123"
        }).json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 1. PUT replace profile
        put_res = client.put("/api/v1/users/me", headers=headers, json={
            "full_name": "Updated Trader Name",
            "email": "updated@trade.com",
            "role": "trader"
        })
        assert put_res.status_code == 200
        assert put_res.json()["full_name"] == "Updated Trader Name"

        # 2. PATCH partial profile
        patch_res = client.patch("/api/v1/users/me", headers=headers, json={
            "full_name": "Patched Name"
        })
        assert patch_res.status_code == 200
        assert patch_res.json()["full_name"] == "Patched Name"

        # 3. DELETE account
        del_res = client.delete("/api/v1/users/me", headers=headers)
        assert del_res.status_code == 200
        assert del_res.json()["status"] == "success"

        # 4. Subsequent login fails
        assert client.post("/api/v1/auth/login", json={
            "username": uname,
            "password": "testpassword123"
        }).status_code == 401
