import uuid

from fastapi import APIRouter, Query

from app.api.deps import DbSession, SuperAdmin
from app.schemas.admin import (
    AdminConfigResponse,
    AdminConfigUpdate,
    AdminOrgListResponse,
    AdminUserListResponse,
    AdminUserResponse,
    DashboardStatsResponse,
)
from app.services.admin import AdminService

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/stats", response_model=DashboardStatsResponse)
async def get_stats(admin: SuperAdmin, db: DbSession) -> DashboardStatsResponse:
    """Get system dashboard statistics."""
    service = AdminService(db)
    return await service.get_dashboard_stats()


@router.get("/users", response_model=AdminUserListResponse)
async def list_users(
    admin: SuperAdmin,
    db: DbSession,
    search: str | None = Query(None),
    status: str | None = Query(None, alias="status"),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    sort: str = Query("created_at"),
    order: str = Query("desc"),
) -> AdminUserListResponse:
    """List all users with pagination and filters."""
    service = AdminService(db)
    return await service.get_users(
        search=search,
        user_status=status,
        page=page,
        per_page=per_page,
        sort=sort,
        order=order,
    )


@router.get("/users/{user_id}", response_model=AdminUserResponse)
async def get_user(
    user_id: uuid.UUID, admin: SuperAdmin, db: DbSession
) -> AdminUserResponse:
    """Get user detail with memberships."""
    service = AdminService(db)
    return await service.get_user_detail(user_id)


@router.post("/users/{user_id}/deactivate", response_model=AdminUserResponse)
async def deactivate_user(
    user_id: uuid.UUID, admin: SuperAdmin, db: DbSession
) -> AdminUserResponse:
    """Deactivate a user account."""
    service = AdminService(db)
    return await service.deactivate_user(user_id)


@router.post("/users/{user_id}/reactivate", response_model=AdminUserResponse)
async def reactivate_user(
    user_id: uuid.UUID, admin: SuperAdmin, db: DbSession
) -> AdminUserResponse:
    """Reactivate a deactivated user account."""
    service = AdminService(db)
    return await service.reactivate_user(user_id)


@router.post("/users/{user_id}/promote-admin", response_model=AdminUserResponse)
async def promote_admin(
    user_id: uuid.UUID, admin: SuperAdmin, db: DbSession
) -> AdminUserResponse:
    """Promote a user to sys admin."""
    service = AdminService(db)
    return await service.promote_admin(user_id)


@router.post("/users/{user_id}/demote-admin", response_model=AdminUserResponse)
async def demote_admin(
    user_id: uuid.UUID, admin: SuperAdmin, db: DbSession
) -> AdminUserResponse:
    """Demote a user from sys admin."""
    service = AdminService(db)
    return await service.demote_admin(user_id, admin.id)


@router.get("/config", response_model=AdminConfigResponse)
async def get_config(admin: SuperAdmin, db: DbSession) -> AdminConfigResponse:
    """Get current auth configuration."""
    service = AdminService(db)
    return await service.get_auth_config()


@router.put("/config", response_model=AdminConfigResponse)
async def update_config(
    data: AdminConfigUpdate, admin: SuperAdmin, db: DbSession
) -> AdminConfigResponse:
    """Update auth configuration."""
    service = AdminService(db)
    return await service.update_auth_config(data, admin.id)


@router.get("/organisations", response_model=AdminOrgListResponse)
async def list_organisations(
    admin: SuperAdmin,
    db: DbSession,
    search: str | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
) -> AdminOrgListResponse:
    """List all organisations with member and team counts."""
    service = AdminService(db)
    return await service.get_organisations(
        search=search,
        page=page,
        per_page=per_page,
    )
