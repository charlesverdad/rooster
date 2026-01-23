import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.models.team import TeamRole


class TeamCreate(BaseModel):
    """Schema for creating a new team.

    organisation_id is optional - if not provided, the user's default
    organisation will be used (created automatically if needed).
    """

    name: str
    organisation_id: uuid.UUID | None = None


class AddPlaceholderMemberRequest(BaseModel):
    """Schema for adding a placeholder member to a team (name only)."""

    name: str
    role: TeamRole = TeamRole.MEMBER


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
    permissions: list[str] = []
    user_email: Optional[str] = None
    user_name: str
    is_placeholder: bool = False
    is_invited: bool = False

    model_config = {"from_attributes": True}


class TeamWithRole(BaseModel):
    """Schema for team with the user's role and permissions."""

    id: uuid.UUID
    name: str
    organisation_id: uuid.UUID
    role: TeamRole | None = None
    permissions: list[str] = []
    created_at: datetime

    model_config = {"from_attributes": True}


class AddTeamMemberRequest(BaseModel):
    """Schema for adding a member to a team."""

    user_id: uuid.UUID
    role: TeamRole = TeamRole.MEMBER
    permissions: list[str] = []


class UpdateMemberPermissionsRequest(BaseModel):
    """Schema for updating a member's permissions."""

    permissions: list[str]
