import uuid
from datetime import datetime

from pydantic import BaseModel

from app.models.team import TeamRole


class TeamCreate(BaseModel):
    """Schema for creating a new team."""

    name: str
    organisation_id: uuid.UUID


class TeamUpdate(BaseModel):
    """Schema for updating a team."""

    name: str | None = None


class TeamResponse(BaseModel):
    """Schema for team response."""

    id: uuid.UUID
    name: str
    organisation_id: uuid.UUID
    created_at: datetime

    model_config = {"from_attributes": True}


class TeamMemberResponse(BaseModel):
    """Schema for team member response."""

    user_id: uuid.UUID
    team_id: uuid.UUID
    role: TeamRole
    user_email: str
    user_name: str

    model_config = {"from_attributes": True}


class TeamWithRole(BaseModel):
    """Schema for team with the user's role."""

    id: uuid.UUID
    name: str
    organisation_id: uuid.UUID
    role: TeamRole
    created_at: datetime

    model_config = {"from_attributes": True}


class AddTeamMemberRequest(BaseModel):
    """Schema for adding a member to a team."""

    user_id: uuid.UUID
    role: TeamRole = TeamRole.MEMBER
