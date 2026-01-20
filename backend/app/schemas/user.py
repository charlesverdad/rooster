import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    """Schema for creating a new user."""

    email: EmailStr
    name: str
    password: str


class PlaceholderUserCreate(BaseModel):
    """Schema for creating a placeholder user (name only)."""

    name: str


class UserLogin(BaseModel):
    """Schema for user login."""

    email: EmailStr
    password: str


class UserResponse(BaseModel):
    """Schema for user response (excludes password)."""

    id: uuid.UUID
    email: Optional[str] = None
    name: str
    is_placeholder: bool = False
    roles: list[str] = []
    created_at: datetime

    model_config = {"from_attributes": True}


class UserBriefResponse(BaseModel):
    """Brief user info for nested responses."""

    id: uuid.UUID
    name: str
    email: Optional[str] = None
    is_placeholder: bool = False

    model_config = {"from_attributes": True}


class Token(BaseModel):
    """Schema for JWT token response."""

    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """Schema for decoded token data."""

    user_id: uuid.UUID | None = None
