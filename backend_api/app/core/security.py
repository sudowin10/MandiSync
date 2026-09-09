"""Security utilities for FastAPI JWT authentication using standard library HMAC-SHA256.

This module provides a zero-dependency JWT implementation suitable for local development,
evaluation, and hackathon deployments without external C-extension dependencies.
"""

import base64
import hashlib
import hmac
import json
import time
from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any

from fastapi import Depends, HTTPException, status
from backend_api.app.services.database import db_manager
from fastapi.security import OAuth2PasswordBearer

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SECRET_KEY: str = "mandisync_ai_supersecret_production_key_2026"
ALGORITHM: str = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES: int = 120

# ---------------------------------------------------------------------------
# In-memory user database for development / verification
# ---------------------------------------------------------------------------
FAKE_USERS_DB: Dict[str, Dict[str, Any]] = {
    "farmer_user": {
        "username": "farmer_user",
        "full_name": "Ramesh Patil",
        "email": "ramesh@mandisync.ai",
        "role": "farmer",
        "hashed_password": "password123",
        "disabled": False,
    },
    "mandi_admin": {
        "username": "mandi_admin",
        "full_name": "Nashik APMC Secretary",
        "email": "admin@nashikapmc.gov.in",
        "role": "admin",
        "hashed_password": "adminpassword",
        "disabled": False,
    },
}

# ---------------------------------------------------------------------------
# Zero-dependency JWT helpers using standard HMAC-SHA256
# ---------------------------------------------------------------------------
def _base64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("utf-8").rstrip("=")

def _base64url_decode(data: str) -> bytes:
    padding = 4 - (len(data) % 4)
    if padding != 4:
        data += "=" * padding
    return base64.urlsafe_b64decode(data.encode("utf-8"))

def fake_hash_password(password: str) -> str:
    return hashlib.sha256(password.encode("utf-8")).hexdigest()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    # Supports both plain match for backward-compat and sha256
    return plain_password == hashed_password or fake_hash_password(plain_password) == hashed_password

def get_user(db: Dict[str, Dict[str, Any]], username: str) -> Optional[Dict[str, Any]]:
    return db.get(username)

async def get_user_from_db(username: str) -> Optional[Dict[str, Any]]:
    collection = db_manager.get_collection("users")
    return await collection.find_one({"username": username})

async def authenticate_user(username: str, password: str) -> Optional[Dict[str, Any]]:
    # Try persistent DB first
    user = await get_user_from_db(username)
    if not user:
        # Fallback to in-memory store
        user = get_user(FAKE_USERS_DB, username)
    if not user:
        return None
    if not verify_password(password, user["hashed_password"]):
        return None
    return user

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Generate an RFC 7519 standard HMAC-SHA256 JSON Web Token."""
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    header = {"alg": "HS256", "typ": "JWT"}
    payload = data.copy()
    payload.update({"exp": int(expire.timestamp()), "iat": int(now.timestamp())})
    
    header_encoded = _base64url_encode(json.dumps(header, separators=(",", ":")).encode("utf-8"))
    payload_encoded = _base64url_encode(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    
    signature_input = f"{header_encoded}.{payload_encoded}".encode("utf-8")
    signature = hmac.new(SECRET_KEY.encode("utf-8"), signature_input, hashlib.sha256).digest()
    signature_encoded = _base64url_encode(signature)
    
    return f"{header_encoded}.{payload_encoded}.{signature_encoded}"

def decode_access_token(token: str) -> Dict[str, Any]:
    """Decode and verify an RFC 7519 HMAC-SHA256 token."""
    parts = token.split(".")
    if len(parts) != 3:
        raise ValueError("Invalid JWT format")
    
    header_encoded, payload_encoded, signature_encoded = parts
    signature_input = f"{header_encoded}.{payload_encoded}".encode("utf-8")
    expected_sig = hmac.new(SECRET_KEY.encode("utf-8"), signature_input, hashlib.sha256).digest()
    actual_sig = _base64url_decode(signature_encoded)
    
    if not hmac.compare_digest(expected_sig, actual_sig):
        raise ValueError("Invalid token signature")
    
    payload = json.loads(_base64url_decode(payload_encoded).decode("utf-8"))
    
    exp = payload.get("exp")
    if exp and exp < time.time():
        raise ValueError("Token has expired")
        
    return payload

# ---------------------------------------------------------------------------
# FastAPI Dependency for JWT Authentication
# ---------------------------------------------------------------------------
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login", auto_error=False)

async def get_current_user(token: Optional[str] = Depends(oauth2_scheme)) -> Optional[Dict[str, Any]]:
    """Dependency that returns the authenticated user, or raises 401 if invalid."""
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token required",
            headers={"WWW-Authenticate": "Bearer"},
        )
    try:
        payload = decode_access_token(token)
        username: str = payload.get("sub")
        if not username:
            raise ValueError("Missing subject claim")
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Could not validate credentials: {exc}",
            headers={"WWW-Authenticate": "Bearer"},
        )
    # Try persistent DB first
    user = await get_user_from_db(username)
    if not user:
        # Fallback to in-memory store
        user = get_user(FAKE_USERS_DB, username)
    if user is None or user.get("disabled"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or disabled",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user

async def get_optional_user(token: Optional[str] = Depends(oauth2_scheme)) -> Optional[Dict[str, Any]]:
    """Optional dependency that returns user if valid token is present, else None."""
    if not token:
        return None
    try:
        payload = decode_access_token(token)
        username: str = payload.get("sub")
        return get_user(FAKE_USERS_DB, username) if username else None
    except Exception:
        return None

def get_current_active_user(current_user: Dict[str, Any] = Depends(get_current_user)) -> Dict[str, Any]:
    if current_user.get("disabled"):
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user
