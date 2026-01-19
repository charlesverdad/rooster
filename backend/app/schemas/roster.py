import uuid
from datetime import date, datetime

from pydantic import BaseModel

from app.models.roster import AssignmentMode, AssignmentStatus, RecurrencePattern


class RosterCreate(BaseModel):
    """Schema for creating a new roster."""

    name: str
    team_id: uuid.UUID
    recurrence_pattern: RecurrencePattern = RecurrencePattern.WEEKLY
    recurrence_day: int  # 0=Monday, 6=Sunday
    slots_needed: int = 1
    assignment_mode: AssignmentMode = AssignmentMode.MANUAL


class RosterUpdate(BaseModel):
    """Schema for updating a roster."""

    name: str | None = None
    recurrence_pattern: RecurrencePattern | None = None
    recurrence_day: int | None = None
    slots_needed: int | None = None
    assignment_mode: AssignmentMode | None = None


class RosterResponse(BaseModel):
    """Schema for roster response."""

    id: uuid.UUID
    name: str
    team_id: uuid.UUID
    recurrence_pattern: RecurrencePattern
    recurrence_day: int
    slots_needed: int
    assignment_mode: AssignmentMode
    created_at: datetime

    model_config = {"from_attributes": True}


class AssignmentCreate(BaseModel):
    """Schema for creating an assignment."""

    roster_id: uuid.UUID
    user_id: uuid.UUID
    date: date


class AssignmentUpdate(BaseModel):
    """Schema for updating an assignment."""

    status: AssignmentStatus | None = None


class AssignmentResponse(BaseModel):
    """Schema for assignment response."""

    id: uuid.UUID
    roster_id: uuid.UUID
    user_id: uuid.UUID
    date: date
    status: AssignmentStatus
    created_at: datetime
    user_name: str | None = None
    user_email: str | None = None
    roster_name: str | None = None

    model_config = {"from_attributes": True}
