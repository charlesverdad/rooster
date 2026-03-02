import math
import uuid
from datetime import datetime, timezone, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import get_settings
from app.models.organisation import Organisation, OrganisationMember
from app.models.push_subscription import PushSubscription
from app.models.roster import Assignment, AssignmentStatus, EventAssignment
from app.models.system_config import AuthSettings
from app.models.team import Team, TeamMember
from app.models.user import User
from app.schemas.admin import (
    AdminConfigResponse,
    AdminConfigUpdate,
    AdminOrgListResponse,
    AdminOrgResponse,
    AdminUserListResponse,
    AdminUserOrgMembership,
    AdminUserResponse,
    AdminUserTeamMembership,
    AssignmentStats,
    AuthConfigStats,
    DashboardOrgSummary,
    DashboardStatsResponse,
    OrgStats,
    PushStats,
    TeamStats,
    UserStats,
)


class AdminService:
    """Service for sys admin operations."""

    def __init__(self, db: AsyncSession):
        self.db = db

    # --- Dashboard ---

    async def get_dashboard_stats(self) -> DashboardStatsResponse:
        settings = get_settings()
        thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)

        # User stats
        total_users = (
            await self.db.execute(select(func.count()).select_from(User))
        ).scalar_one()
        placeholder_users = (
            await self.db.execute(
                select(func.count())
                .select_from(User)
                .where(User.is_placeholder == True)  # noqa: E712
            )
        ).scalar_one()
        superadmin_users = (
            await self.db.execute(
                select(func.count()).select_from(User).where(User.is_superadmin == True)  # noqa: E712
            )
        ).scalar_one()
        deactivated_users = (
            await self.db.execute(
                select(func.count())
                .select_from(User)
                .where(User.is_deactivated == True)  # noqa: E712
            )
        ).scalar_one()
        recent_users = (
            await self.db.execute(
                select(func.count())
                .select_from(User)
                .where(User.created_at >= thirty_days_ago)
            )
        ).scalar_one()
        active_users = total_users - placeholder_users - deactivated_users

        # Org stats
        total_orgs = (
            await self.db.execute(select(func.count()).select_from(Organisation))
        ).scalar_one()
        personal_orgs = (
            await self.db.execute(
                select(func.count())
                .select_from(Organisation)
                .where(Organisation.is_personal == True)  # noqa: E712
            )
        ).scalar_one()

        # Team stats
        total_teams = (
            await self.db.execute(select(func.count()).select_from(Team))
        ).scalar_one()

        # Assignment stats (both legacy and event assignments)
        total_assignments = (
            await self.db.execute(select(func.count()).select_from(Assignment))
        ).scalar_one()
        pending_assignments = (
            await self.db.execute(
                select(func.count())
                .select_from(Assignment)
                .where(Assignment.status == AssignmentStatus.PENDING)
            )
        ).scalar_one()
        confirmed_assignments = (
            await self.db.execute(
                select(func.count())
                .select_from(Assignment)
                .where(Assignment.status == AssignmentStatus.CONFIRMED)
            )
        ).scalar_one()
        declined_assignments = (
            await self.db.execute(
                select(func.count())
                .select_from(Assignment)
                .where(Assignment.status == AssignmentStatus.DECLINED)
            )
        ).scalar_one()

        # Also count event assignments
        total_ea = (
            await self.db.execute(select(func.count()).select_from(EventAssignment))
        ).scalar_one()
        pending_ea = (
            await self.db.execute(
                select(func.count())
                .select_from(EventAssignment)
                .where(EventAssignment.status == AssignmentStatus.PENDING)
            )
        ).scalar_one()
        confirmed_ea = (
            await self.db.execute(
                select(func.count())
                .select_from(EventAssignment)
                .where(EventAssignment.status == AssignmentStatus.CONFIRMED)
            )
        ).scalar_one()
        declined_ea = (
            await self.db.execute(
                select(func.count())
                .select_from(EventAssignment)
                .where(EventAssignment.status == AssignmentStatus.DECLINED)
            )
        ).scalar_one()

        # Push stats
        total_push = (
            await self.db.execute(select(func.count()).select_from(PushSubscription))
        ).scalar_one()

        # Auth config
        auth_row = (
            await self.db.execute(select(AuthSettings).where(AuthSettings.id == 1))
        ).scalar_one_or_none()
        if auth_row:
            email_enabled = auth_row.email_enabled
            google_enabled = auth_row.google_enabled
        else:
            email_enabled = settings.auth_email_enabled
            google_enabled = settings.auth_google_enabled

        if settings.auth_force_email_enabled:
            email_enabled = True

        email_configured = bool(
            (settings.email_provider == "resend" and settings.resend_api_key)
            or (
                settings.email_provider == "smtp"
                and settings.smtp_host
                and settings.smtp_user
            )
        )
        push_configured = bool(settings.vapid_public_key and settings.vapid_private_key)

        # Organisation list (non-personal orgs with member/team counts)
        org_result = await self.db.execute(
            select(Organisation)
            .where(Organisation.is_personal == False)  # noqa: E712
            .order_by(Organisation.created_at.desc())
        )
        orgs = org_result.scalars().all()
        org_ids = [o.id for o in orgs]

        member_counts: dict[uuid.UUID, int] = {}
        team_counts: dict[uuid.UUID, int] = {}
        if org_ids:
            mc_result = await self.db.execute(
                select(OrganisationMember.organisation_id, func.count())
                .where(OrganisationMember.organisation_id.in_(org_ids))
                .group_by(OrganisationMember.organisation_id)
            )
            member_counts = {row[0]: row[1] for row in mc_result.all()}

            tc_result = await self.db.execute(
                select(Team.organisation_id, func.count())
                .where(Team.organisation_id.in_(org_ids))
                .group_by(Team.organisation_id)
            )
            team_counts = {row[0]: row[1] for row in tc_result.all()}

        org_summaries = [
            DashboardOrgSummary(
                id=o.id,
                name=o.name,
                member_count=member_counts.get(o.id, 0),
                team_count=team_counts.get(o.id, 0),
                created_at=o.created_at,
            )
            for o in orgs
        ]

        return DashboardStatsResponse(
            users=UserStats(
                total=total_users,
                active=active_users,
                placeholder=placeholder_users,
                superadmin=superadmin_users,
                created_last_30_days=recent_users,
            ),
            organisations=OrgStats(
                total=total_orgs,
                personal=personal_orgs,
                named=total_orgs - personal_orgs,
            ),
            teams=TeamStats(total=total_teams),
            assignments=AssignmentStats(
                total=total_assignments + total_ea,
                pending=pending_assignments + pending_ea,
                confirmed=confirmed_assignments + confirmed_ea,
                declined=declined_assignments + declined_ea,
            ),
            push_subscriptions=PushStats(total=total_push),
            auth_config=AuthConfigStats(
                email_enabled=email_enabled,
                google_enabled=google_enabled,
                email_provider=settings.email_provider,
                email_configured=email_configured,
                push_configured=push_configured,
            ),
            organisation_list=org_summaries,
        )

    # --- Users ---

    async def get_users(
        self,
        search: str | None = None,
        user_status: str | None = None,
        page: int = 1,
        per_page: int = 20,
        sort: str = "created_at",
        order: str = "desc",
    ) -> AdminUserListResponse:
        base_query = select(User)
        count_query = select(func.count()).select_from(User)

        # Filter by status
        if user_status == "active":
            base_query = base_query.where(
                User.is_placeholder == False,  # noqa: E712
                User.is_deactivated == False,  # noqa: E712
            )
            count_query = count_query.where(
                User.is_placeholder == False,  # noqa: E712
                User.is_deactivated == False,  # noqa: E712
            )
        elif user_status == "placeholder":
            base_query = base_query.where(User.is_placeholder == True)  # noqa: E712
            count_query = count_query.where(User.is_placeholder == True)  # noqa: E712
        elif user_status == "deactivated":
            base_query = base_query.where(User.is_deactivated == True)  # noqa: E712
            count_query = count_query.where(User.is_deactivated == True)  # noqa: E712
        elif user_status == "superadmin":
            base_query = base_query.where(User.is_superadmin == True)  # noqa: E712
            count_query = count_query.where(User.is_superadmin == True)  # noqa: E712

        # Search
        if search:
            search_filter = or_(
                User.name.ilike(f"%{search}%"),
                User.email.ilike(f"%{search}%"),
            )
            base_query = base_query.where(search_filter)
            count_query = count_query.where(search_filter)

        # Total count
        total = (await self.db.execute(count_query)).scalar_one()
        pages = max(1, math.ceil(total / per_page))

        # Sorting
        sort_col = getattr(User, sort, User.created_at)
        if order == "asc":
            base_query = base_query.order_by(sort_col.asc())
        else:
            base_query = base_query.order_by(sort_col.desc())

        # Pagination
        base_query = base_query.offset((page - 1) * per_page).limit(per_page)

        # Eager load memberships
        base_query = base_query.options(
            selectinload(User.organisation_memberships).selectinload(
                OrganisationMember.organisation
            ),
            selectinload(User.team_memberships)
            .selectinload(TeamMember.team)
            .selectinload(Team.organisation),
        )

        result = await self.db.execute(base_query)
        users = result.scalars().all()

        user_responses = []
        for u in users:
            org_memberships = [
                AdminUserOrgMembership(
                    org_id=om.organisation_id,
                    org_name=om.organisation.name,
                    role=om.role.value if hasattr(om.role, "value") else str(om.role),
                )
                for om in u.organisation_memberships
            ]
            team_memberships = [
                AdminUserTeamMembership(
                    team_id=tm.team_id,
                    team_name=tm.team.name,
                    org_name=tm.team.organisation.name if tm.team.organisation else "",
                    role=tm.role.value if hasattr(tm.role, "value") else str(tm.role),
                )
                for tm in u.team_memberships
            ]
            user_responses.append(
                AdminUserResponse(
                    id=u.id,
                    email=u.email,
                    name=u.name,
                    is_placeholder=u.is_placeholder,
                    is_superadmin=u.is_superadmin,
                    is_deactivated=u.is_deactivated,
                    has_google=bool(u.google_id),
                    created_at=u.created_at,
                    organisations=org_memberships,
                    teams=team_memberships,
                )
            )

        return AdminUserListResponse(
            users=user_responses,
            total=total,
            page=page,
            per_page=per_page,
            pages=pages,
        )

    async def get_user_detail(self, user_id: uuid.UUID) -> AdminUserResponse:
        result = await self.db.execute(
            select(User)
            .where(User.id == user_id)
            .options(
                selectinload(User.organisation_memberships).selectinload(
                    OrganisationMember.organisation
                ),
                selectinload(User.team_memberships)
                .selectinload(TeamMember.team)
                .selectinload(Team.organisation),
            )
        )
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

        org_memberships = [
            AdminUserOrgMembership(
                org_id=om.organisation_id,
                org_name=om.organisation.name,
                role=om.role.value if hasattr(om.role, "value") else str(om.role),
            )
            for om in user.organisation_memberships
        ]
        team_memberships = [
            AdminUserTeamMembership(
                team_id=tm.team_id,
                team_name=tm.team.name,
                org_name=tm.team.organisation.name if tm.team.organisation else "",
                role=tm.role.value if hasattr(tm.role, "value") else str(tm.role),
            )
            for tm in user.team_memberships
        ]

        return AdminUserResponse(
            id=user.id,
            email=user.email,
            name=user.name,
            is_placeholder=user.is_placeholder,
            is_superadmin=user.is_superadmin,
            is_deactivated=user.is_deactivated,
            has_google=bool(user.google_id),
            created_at=user.created_at,
            organisations=org_memberships,
            teams=team_memberships,
        )

    async def deactivate_user(self, user_id: uuid.UUID) -> AdminUserResponse:
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )
        user.is_deactivated = True
        await self.db.flush()
        return await self.get_user_detail(user_id)

    async def reactivate_user(self, user_id: uuid.UUID) -> AdminUserResponse:
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )
        user.is_deactivated = False
        await self.db.flush()
        return await self.get_user_detail(user_id)

    async def promote_admin(self, user_id: uuid.UUID) -> AdminUserResponse:
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )
        user.is_superadmin = True
        await self.db.flush()
        return await self.get_user_detail(user_id)

    async def demote_admin(
        self, user_id: uuid.UUID, current_user_id: uuid.UUID
    ) -> AdminUserResponse:
        if user_id == current_user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot remove sys admin from yourself",
            )

        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

        # Last-admin guard
        admin_count = (
            await self.db.execute(
                select(func.count()).select_from(User).where(User.is_superadmin == True)  # noqa: E712
            )
        ).scalar_one()
        if admin_count <= 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot remove the last sys admin",
            )

        user.is_superadmin = False
        await self.db.flush()
        return await self.get_user_detail(user_id)

    # --- Auth Config ---

    async def get_auth_config(self) -> AdminConfigResponse:
        settings = get_settings()
        result = await self.db.execute(select(AuthSettings).where(AuthSettings.id == 1))
        auth = result.scalar_one_or_none()

        if auth:
            email_enabled = auth.email_enabled
            google_enabled = auth.google_enabled
            google_client_id = auth.google_client_id
        else:
            email_enabled = settings.auth_email_enabled
            google_enabled = settings.auth_google_enabled
            google_client_id = settings.google_client_id or None

        if settings.auth_force_email_enabled:
            email_enabled = True

        return AdminConfigResponse(
            email_enabled=email_enabled,
            google_enabled=google_enabled,
            google_client_id=google_client_id,
            force_email_enabled=settings.auth_force_email_enabled,
        )

    async def update_auth_config(
        self, data: AdminConfigUpdate, updated_by: uuid.UUID
    ) -> AdminConfigResponse:
        settings = get_settings()

        # Validate: cannot disable all auth methods unless force email is on
        email_val = data.email_enabled
        google_val = data.google_enabled

        # Resolve current values for fields not being updated
        result = await self.db.execute(select(AuthSettings).where(AuthSettings.id == 1))
        auth = result.scalar_one_or_none()

        if email_val is None:
            email_val = auth.email_enabled if auth else settings.auth_email_enabled
        if google_val is None:
            google_val = auth.google_enabled if auth else settings.auth_google_enabled

        if not email_val and not google_val and not settings.auth_force_email_enabled:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot disable all authentication methods",
            )

        # Validate: enabling Google requires client ID
        google_client_id = data.google_client_id
        if google_client_id is None and auth:
            google_client_id = auth.google_client_id
        if google_val and not google_client_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Google client ID is required when Google sign-in is enabled",
            )

        # Upsert
        if auth:
            if data.email_enabled is not None:
                auth.email_enabled = data.email_enabled
            if data.google_enabled is not None:
                auth.google_enabled = data.google_enabled
            if data.google_client_id is not None:
                auth.google_client_id = data.google_client_id
            auth.updated_by_id = updated_by
        else:
            auth = AuthSettings(
                id=1,
                email_enabled=email_val,
                google_enabled=google_val,
                google_client_id=google_client_id,
                updated_by_id=updated_by,
            )
            self.db.add(auth)

        await self.db.flush()
        return await self.get_auth_config()

    # --- Organisations ---

    async def get_organisations(
        self,
        search: str | None = None,
        page: int = 1,
        per_page: int = 20,
    ) -> AdminOrgListResponse:
        base_query = select(Organisation)
        count_query = select(func.count()).select_from(Organisation)

        if search:
            search_filter = Organisation.name.ilike(f"%{search}%")
            base_query = base_query.where(search_filter)
            count_query = count_query.where(search_filter)

        total = (await self.db.execute(count_query)).scalar_one()
        pages = max(1, math.ceil(total / per_page))

        base_query = base_query.order_by(Organisation.created_at.desc())
        base_query = base_query.offset((page - 1) * per_page).limit(per_page)

        result = await self.db.execute(base_query)
        orgs = result.scalars().all()

        # Get member and team counts
        org_ids = [o.id for o in orgs]
        member_counts: dict[uuid.UUID, int] = {}
        team_counts: dict[uuid.UUID, int] = {}

        if org_ids:
            mc_result = await self.db.execute(
                select(OrganisationMember.organisation_id, func.count())
                .where(OrganisationMember.organisation_id.in_(org_ids))
                .group_by(OrganisationMember.organisation_id)
            )
            member_counts = {row[0]: row[1] for row in mc_result.all()}

            tc_result = await self.db.execute(
                select(Team.organisation_id, func.count())
                .where(Team.organisation_id.in_(org_ids))
                .group_by(Team.organisation_id)
            )
            team_counts = {row[0]: row[1] for row in tc_result.all()}

        org_responses = [
            AdminOrgResponse(
                id=o.id,
                name=o.name,
                is_personal=o.is_personal,
                member_count=member_counts.get(o.id, 0),
                team_count=team_counts.get(o.id, 0),
                created_at=o.created_at,
            )
            for o in orgs
        ]

        return AdminOrgListResponse(
            organisations=org_responses,
            total=total,
            page=page,
            per_page=per_page,
            pages=pages,
        )
