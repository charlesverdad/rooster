import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


# --- Dashboard Stats ---


class UserStats(BaseModel):
    total: int
    active: int
    placeholder: int
    superadmin: int
    created_last_30_days: int


class OrgStats(BaseModel):
    total: int
    personal: int
    named: int


class TeamStats(BaseModel):
    total: int


class AssignmentStats(BaseModel):
    total: int
    pending: int
    confirmed: int
    declined: int


class PushStats(BaseModel):
    total: int


class AuthConfigStats(BaseModel):
    email_enabled: bool
    google_enabled: bool
    email_provider: str
    email_configured: bool
    push_configured: bool


class DashboardOrgSummary(BaseModel):
    id: uuid.UUID
    name: str
    member_count: int
    team_count: int
    created_at: datetime

    model_config = {"from_attributes": True}


class DashboardStatsResponse(BaseModel):
    users: UserStats
    organisations: OrgStats
    teams: TeamStats
    assignments: AssignmentStats
    push_subscriptions: PushStats
    auth_config: AuthConfigStats
    organisation_list: list[DashboardOrgSummary] = []


# --- Admin User ---


class AdminUserOrgMembership(BaseModel):
    org_id: uuid.UUID
    org_name: str
    role: str

    model_config = {"from_attributes": True}


class AdminUserTeamMembership(BaseModel):
    team_id: uuid.UUID
    team_name: str
    org_name: str
    role: str

    model_config = {"from_attributes": True}


class AdminUserResponse(BaseModel):
    id: uuid.UUID
    email: Optional[str] = None
    name: str
    is_placeholder: bool
    is_superadmin: bool
    is_deactivated: bool
    has_google: bool = False
    created_at: datetime
    organisations: list[AdminUserOrgMembership] = []
    teams: list[AdminUserTeamMembership] = []

    model_config = {"from_attributes": True}


class AdminUserListResponse(BaseModel):
    users: list[AdminUserResponse]
    total: int
    page: int
    per_page: int
    pages: int


# --- Admin Config ---


class AdminConfigResponse(BaseModel):
    email_enabled: bool
    google_enabled: bool
    google_client_id: Optional[str] = None
    force_email_enabled: bool = False


class AdminConfigUpdate(BaseModel):
    email_enabled: Optional[bool] = None
    google_enabled: Optional[bool] = None
    google_client_id: Optional[str] = None


# --- Admin Organisations ---


class AdminOrgResponse(BaseModel):
    id: uuid.UUID
    name: str
    is_personal: bool
    member_count: int
    team_count: int
    created_at: datetime

    model_config = {"from_attributes": True}


class AdminOrgListResponse(BaseModel):
    organisations: list[AdminOrgResponse]
    total: int
    page: int
    per_page: int
    pages: int
