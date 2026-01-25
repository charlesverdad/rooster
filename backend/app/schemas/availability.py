import uuid
from datetime import date, datetime

from pydantic import BaseModel


class UnavailabilityCreate(BaseModel):
    """Schema for creating an unavailability record."""

    date: date
    reason: str | None = None


class UnavailabilityResponse(BaseModel):
    """Schema for unavailability response."""

    id: uuid.UUID
    user_id: uuid.UUID
    date: date
    reason: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class ConflictResponse(BaseModel):
    """Schema for conflict response."""

    assignment_id: uuid.UUID
    unavailability_id: uuid.UUID
    date: date
    roster_name: str
    team_name: str
    reason: str | None
