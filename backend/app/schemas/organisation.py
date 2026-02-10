import uuid
from datetime import datetime

from pydantic import BaseModel

from app.models.organisation import OrganisationRole


class OrganisationCreate(BaseModel):
    """Schema for creating a new organisation."""

    name: str


class OrganisationUpdate(BaseModel):
    """Schema for updating an organisation."""

    name: str | None = None


class OrganisationResponse(BaseModel):
    """Schema for organisation response."""

    id: uuid.UUID
    name: str
    is_personal: bool = False
    created_at: datetime

    model_config = {"from_attributes": True}


class OrganisationMemberResponse(BaseModel):
    """Schema for organisation member response."""

    user_id: uuid.UUID
    organisation_id: uuid.UUID
    role: OrganisationRole
    user_email: str | None = None
    user_name: str

    model_config = {"from_attributes": True}


class OrganisationWithRole(BaseModel):
    """Schema for organisation with the user's role."""

    id: uuid.UUID
    name: str
    role: OrganisationRole
    is_personal: bool = False
    created_at: datetime

    model_config = {"from_attributes": True}


class AddMemberRequest(BaseModel):
    """Schema for adding a member to an organisation."""

    user_id: uuid.UUID
    role: OrganisationRole = OrganisationRole.MEMBER


class UpdateMemberRoleRequest(BaseModel):
    """Schema for updating a member's role."""

    role: OrganisationRole
