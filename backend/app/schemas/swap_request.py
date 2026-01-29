import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.models.swap_request import SwapRequestStatus


class SwapRequestCreate(BaseModel):
    """Schema for creating a swap request."""

    requester_assignment_id: uuid.UUID
    target_user_id: uuid.UUID


class SwapRequestUpdate(BaseModel):
    """Schema for updating a swap request (accept/decline)."""

    status: SwapRequestStatus


class SwapRequestResponse(BaseModel):
    """Schema for swap request response."""

    id: uuid.UUID
    requester_assignment_id: uuid.UUID
    target_user_id: uuid.UUID
    status: SwapRequestStatus
    expires_at: datetime
    responded_at: Optional[datetime] = None
    created_at: datetime

    model_config = {"from_attributes": True}
