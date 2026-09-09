"""User management routes providing registration and profile CRUD."""

from datetime import datetime, timezone
from typing import Any, Dict, Optional
from fastapi import APIRouter, Depends, HTTPException, status

from backend_api.app.core.security import (
    get_current_active_user,
    get_user_from_db,
    get_user,
    fake_hash_password,
    FAKE_USERS_DB,
)
from backend_api.app.models.schemas import UserRegister, UserUpdate, UserResponse
from backend_api.app.services.database import db_manager

router = APIRouter()


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register New User",
    description="Register a regular user (farmer, buyer, trader) with persistent MongoDB storage."
)
async def register_user(user_in: UserRegister):
    collection = db_manager.get_collection("users")

    # Check if username already exists in persistent DB or in-memory store
    existing_db = await collection.find_one({"username": user_in.username})
    existing_fake = get_user(FAKE_USERS_DB, user_in.username)
    if existing_db or existing_fake:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Username '{user_in.username}' is already registered."
        )

    user_doc: Dict[str, Any] = {
        "username": user_in.username,
        "full_name": user_in.full_name or user_in.username,
        "email": user_in.email or f"{user_in.username}@mandisync.ai",
        "role": user_in.role or "farmer",
        "hashed_password": fake_hash_password(user_in.password),
        "disabled": False,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }

    res = await collection.insert_one(dict(user_doc))
    user_doc["_id"] = str(res.inserted_id)

    # Sync into in-memory fallback for test resilience
    FAKE_USERS_DB[user_in.username] = dict(user_doc)

    return UserResponse(
        username=user_doc["username"],
        full_name=user_doc["full_name"],
        email=user_doc["email"],
        role=user_doc["role"],
        disabled=user_doc["disabled"]
    )


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get Current User Profile",
    description="Return the authenticated user's details (password hash excluded)."
)
async def read_current_user(current_user: dict = Depends(get_current_active_user)):
    return UserResponse(
        username=current_user["username"],
        full_name=current_user.get("full_name"),
        email=current_user.get("email"),
        role=current_user.get("role", "farmer"),
        disabled=current_user.get("disabled", False)
    )


@router.put(
    "/me",
    response_model=UserResponse,
    summary="Replace User Profile",
    description="Fully replace current user profile fields."
)
async def replace_current_user(
    update_data: UserUpdate,
    current_user: dict = Depends(get_current_active_user)
):
    collection = db_manager.get_collection("users")
    username = current_user["username"]

    updated_fields: Dict[str, Any] = {
        "full_name": update_data.full_name or username,
        "email": update_data.email or current_user.get("email"),
        "role": update_data.role or current_user.get("role", "farmer"),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
    if update_data.password:
        updated_fields["hashed_password"] = fake_hash_password(update_data.password)

    await collection.update_one({"username": username}, {"$set": updated_fields})
    if username in FAKE_USERS_DB:
        FAKE_USERS_DB[username].update(updated_fields)

    current_user.update(updated_fields)
    return UserResponse(
        username=username,
        full_name=current_user.get("full_name"),
        email=current_user.get("email"),
        role=current_user.get("role", "farmer"),
        disabled=current_user.get("disabled", False)
    )


@router.patch(
    "/me",
    response_model=UserResponse,
    summary="Update User Profile (Partial)",
    description="Partially update current user profile."
)
async def patch_current_user(
    patch: UserUpdate,
    current_user: dict = Depends(get_current_active_user)
):
    collection = db_manager.get_collection("users")
    username = current_user["username"]

    patch_dict = {k: v for k, v in patch.model_dump(exclude_unset=True).items() if v is not None}
    if not patch_dict:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid fields provided for update."
        )

    if "password" in patch_dict:
        patch_dict["hashed_password"] = fake_hash_password(patch_dict.pop("password"))

    patch_dict["updated_at"] = datetime.now(timezone.utc).isoformat()

    await collection.update_one({"username": username}, {"$set": patch_dict})
    if username in FAKE_USERS_DB:
        FAKE_USERS_DB[username].update(patch_dict)

    current_user.update(patch_dict)
    return UserResponse(
        username=username,
        full_name=current_user.get("full_name"),
        email=current_user.get("email"),
        role=current_user.get("role", "farmer"),
        disabled=current_user.get("disabled", False)
    )


@router.delete(
    "/me",
    status_code=status.HTTP_200_OK,
    summary="Delete User Account",
    description="Remove the authenticated user account."
)
async def delete_current_user(current_user: dict = Depends(get_current_active_user)):
    collection = db_manager.get_collection("users")
    username = current_user["username"]

    await collection.delete_one({"username": username})
    FAKE_USERS_DB.pop(username, None)

    return {"status": "success", "message": f"User account '{username}' deleted successfully."}

