"""Authentication router providing login endpoint for JWT token issuance.

Supports JSON-based login without requiring external multipart dependencies.
"""

from datetime import timedelta
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel

from backend_api.app.core.security import (
    ACCESS_TOKEN_EXPIRE_MINUTES,
    authenticate_user,
    create_access_token,
)

router = APIRouter()

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class LoginRequest(BaseModel):
    username: str
    password: str

@router.post("/login", response_model=Token, tags=["Authentication"])
async def login(credentials: LoginRequest):
    """Validate credentials and return a signed JWT access token."""
    user = await authenticate_user(credentials.username, credentials.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(data={"sub": user["username"]}, expires_delta=access_token_expires)
    return Token(access_token=access_token)


from backend_api.app.models.schemas import UserRegister, UserResponse
from backend_api.app.api.routes_users import register_user

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED, tags=["Authentication"])
async def auth_register(user_in: UserRegister):
    """Register a new user directly from auth endpoint."""
    return await register_user(user_in)

