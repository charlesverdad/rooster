import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr


class InviteCreate(BaseModel):
    """Schema for sending an invite to a placeholder user."""

    email: EmailStr


class InviteResponse(BaseModel):
    """Schema for invite response."""

    id: uuid.UUID
    team_id: uuid.UUID
    user_id: uuid.UUID
    email: str
    token: str
    accepted_at: Optional[datetime] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class InviteValidation(BaseModel):
    """Schema for validating an invite token."""

    valid: bool
    team_name: Optional[str] = None
    user_name: Optional[str] = None
    email: Optional[str] = None
    expired: bool = False
    already_accepted: bool = False


class InviteAccept(BaseModel):
    """Schema for accepting an invite."""

    password: str


class InviteAcceptResponse(BaseModel):
    """Schema for invite acceptance response."""

    success: bool
    message: str
    user_id: Optional[uuid.UUID] = None
    access_token: Optional[str] = None
