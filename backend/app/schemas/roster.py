import uuid
from datetime import date, datetime
from typing import Optional

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
    location: Optional[str] = None
    notes: Optional[str] = None
    start_date: date
    end_date: Optional[date] = None
    end_after_occurrences: Optional[int] = None
    generate_events_count: int = 12  # How many events to auto-generate


class RosterUpdate(BaseModel):
    """Schema for updating a roster."""

    name: str | None = None
    recurrence_pattern: RecurrencePattern | None = None
    recurrence_day: int | None = None
    slots_needed: int | None = None
    assignment_mode: AssignmentMode | None = None
    location: Optional[str] = None
    notes: Optional[str] = None
    end_date: Optional[date] = None
    end_after_occurrences: Optional[int] = None
    is_active: Optional[bool] = None


class RosterResponse(BaseModel):
    """Schema for roster response."""

    id: uuid.UUID
    name: str
    team_id: uuid.UUID
    recurrence_pattern: RecurrencePattern
    recurrence_day: int
    slots_needed: int
    assignment_mode: AssignmentMode
    location: Optional[str] = None
    notes: Optional[str] = None
    start_date: date
    end_date: Optional[date] = None
    end_after_occurrences: Optional[int] = None
    is_active: bool = True
    created_at: datetime

    model_config = {"from_attributes": True}


# RosterEvent schemas
class RosterEventResponse(BaseModel):
    """Schema for roster event response."""

    id: uuid.UUID
    roster_id: uuid.UUID
    date: date
    notes: Optional[str] = None
    is_cancelled: bool = False
    roster_name: Optional[str] = None
    team_id: Optional[uuid.UUID] = None
    slots_needed: Optional[int] = None
    filled_slots: int = 0
    created_at: datetime

    model_config = {"from_attributes": True}


class RosterEventUpdate(BaseModel):
    """Schema for updating a roster event."""

    notes: Optional[str] = None
    is_cancelled: Optional[bool] = None


class EventAssignmentCreate(BaseModel):
    """Schema for creating an event assignment."""

    event_id: uuid.UUID
    user_id: uuid.UUID


class EventAssignmentResponse(BaseModel):
    """Schema for event assignment response."""

    id: uuid.UUID
    event_id: uuid.UUID
    user_id: uuid.UUID
    status: AssignmentStatus
    user_name: Optional[str] = None
    user_email: Optional[str] = None
    is_placeholder: bool = False
    is_invited: bool = False
    created_at: datetime

    # Additional fields for display (populated from related data)
    event_date: Optional[date] = None
    roster_name: Optional[str] = None
    team_name: Optional[str] = None

    model_config = {"from_attributes": True}


class EventAssignmentUpdate(BaseModel):
    """Schema for updating an event assignment."""

    status: AssignmentStatus


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


class CoVolunteerInfo(BaseModel):
    """Info about a co-volunteer on the same event."""

    user_id: uuid.UUID
    name: str
    status: AssignmentStatus
    is_placeholder: bool = False
    is_invited: bool = False


class TeamLeadInfo(BaseModel):
    """Info about the team lead for contact purposes."""

    user_id: uuid.UUID
    name: str
    email: Optional[str] = None


class EventAssignmentDetailResponse(BaseModel):
    """Detailed event assignment response with co-volunteers and team lead info."""

    id: uuid.UUID
    event_id: uuid.UUID
    user_id: uuid.UUID
    status: AssignmentStatus
    user_name: Optional[str] = None
    user_email: Optional[str] = None
    is_placeholder: bool = False
    is_invited: bool = False
    created_at: datetime

    # Event details
    event_date: date
    roster_id: uuid.UUID
    roster_name: str
    team_id: uuid.UUID
    team_name: str
    location: Optional[str] = None
    notes: Optional[str] = None
    slots_needed: int = 1

    # Co-volunteers
    co_volunteers: list[CoVolunteerInfo] = []

    # Team lead contact info
    team_lead: Optional[TeamLeadInfo] = None

    model_config = {"from_attributes": True}
