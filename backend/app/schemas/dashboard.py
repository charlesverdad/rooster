import uuid
from datetime import date, datetime

from pydantic import BaseModel

from app.models.roster import AssignmentStatus


class UpcomingAssignment(BaseModel):
    """Schema for upcoming assignment with context."""

    id: uuid.UUID
    date: date
    status: AssignmentStatus
    roster_name: str
    team_name: str
    organisation_name: str
    created_at: datetime


class CalendarDay(BaseModel):
    """Schema for a day in the calendar view."""

    date: date
    assignments: list[UpcomingAssignment]


class TeamMemberAvailability(BaseModel):
    """Schema for team member availability."""

    user_id: uuid.UUID
    user_name: str
    user_email: str
    is_available: bool
    unavailability_reason: str | None
