import uuid

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.organisation import OrganisationMember, OrganisationRole
from app.models.team import Team, TeamMember, TeamRole
from app.models.user import User
from app.models.invite import Invite
from app.schemas.team import TeamCreate, TeamUpdate


class TeamService:
    """Service for team operations."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_team(self, data: TeamCreate, creator_id: uuid.UUID) -> Team:
        """Create a new team with the creator as lead."""
        team = Team(name=data.name, organisation_id=data.organisation_id)
        self.db.add(team)
        await self.db.flush()

        # Add creator as team lead
        membership = TeamMember(
            user_id=creator_id,
            team_id=team.id,
            role=TeamRole.LEAD,
        )
        self.db.add(membership)
        await self.db.flush()
        await self.db.refresh(team)
        return team

    async def get_team(self, team_id: uuid.UUID) -> Team | None:
        """Get a team by ID."""
        result = await self.db.execute(select(Team).where(Team.id == team_id))
        return result.scalar_one_or_none()

    async def get_organisation_teams(self, org_id: uuid.UUID) -> list[Team]:
        """Get all teams in an organisation."""
        result = await self.db.execute(
            select(Team).where(Team.organisation_id == org_id)
        )
        return list(result.scalars().all())

    async def get_user_teams(
        self, user_id: uuid.UUID, org_id: uuid.UUID | None = None
    ) -> list[tuple[Team, TeamRole]]:
        """Get all teams a user belongs to with their roles."""
        query = (
            select(Team, TeamMember.role)
            .join(TeamMember)
            .where(TeamMember.user_id == user_id)
        )
        if org_id:
            query = query.where(Team.organisation_id == org_id)
        result = await self.db.execute(query)
        return list(result.all())

    async def update_team(self, team_id: uuid.UUID, data: TeamUpdate) -> Team | None:
        """Update a team."""
        team = await self.get_team(team_id)
        if not team:
            return None
        if data.name is not None:
            team.name = data.name
        await self.db.flush()
        await self.db.refresh(team)
        return team

    async def delete_team(self, team_id: uuid.UUID) -> bool:
        """Delete a team."""
        team = await self.get_team(team_id)
        if not team:
            return False
        await self.db.delete(team)
        return True

    async def get_team_membership(
        self, user_id: uuid.UUID, team_id: uuid.UUID
    ) -> TeamMember | None:
        """Get a user's membership in a team."""
        result = await self.db.execute(
            select(TeamMember).where(
                TeamMember.user_id == user_id,
                TeamMember.team_id == team_id,
            )
        )
        return result.scalar_one_or_none()

    async def is_team_lead(self, user_id: uuid.UUID, team_id: uuid.UUID) -> bool:
        """Check if a user is a lead of a team."""
        membership = await self.get_team_membership(user_id, team_id)
        return membership is not None and membership.role == TeamRole.LEAD

    async def is_org_admin(self, user_id: uuid.UUID, org_id: uuid.UUID) -> bool:
        """Check if a user is an admin of an organisation."""
        result = await self.db.execute(
            select(OrganisationMember).where(
                OrganisationMember.user_id == user_id,
                OrganisationMember.organisation_id == org_id,
            )
        )
        membership = result.scalar_one_or_none()
        return membership is not None and membership.role == OrganisationRole.ADMIN

    async def can_manage_team(self, user_id: uuid.UUID, team: Team) -> bool:
        """Check if a user can manage a team (org admin or team lead)."""
        if await self.is_org_admin(user_id, team.organisation_id):
            return True
        return await self.is_team_lead(user_id, team.id)

    async def add_member(
        self, team_id: uuid.UUID, user_id: uuid.UUID, role: TeamRole
    ) -> TeamMember | None:
        """Add a member to a team."""
        # Check if user exists
        user_result = await self.db.execute(select(User).where(User.id == user_id))
        if not user_result.scalar_one_or_none():
            return None

        # Check if already a member
        existing = await self.get_team_membership(user_id, team_id)
        if existing:
            return existing

        membership = TeamMember(
            user_id=user_id,
            team_id=team_id,
            role=role,
        )
        self.db.add(membership)
        await self.db.flush()
        await self.db.refresh(membership)
        return membership

    async def remove_member(self, team_id: uuid.UUID, user_id: uuid.UUID) -> bool:
        """Remove a member from a team."""
        membership = await self.get_team_membership(user_id, team_id)
        if not membership:
            return False
        await self.db.delete(membership)
        return True

    async def get_members(self, team_id: uuid.UUID) -> list[TeamMember]:
        """Get all members of a team."""
        result = await self.db.execute(
            select(TeamMember)
            .options(selectinload(TeamMember.user))
            .where(TeamMember.team_id == team_id)
        )
        return list(result.scalars().all())

    async def create_placeholder_member(
        self, team_id: uuid.UUID, name: str, role: TeamRole, created_by_id: uuid.UUID
    ) -> TeamMember:
        """Create a placeholder user and add them to a team."""
        # Create placeholder user
        user = User(
            name=name,
            is_placeholder=True,
            invited_by_id=created_by_id,
        )
        self.db.add(user)
        await self.db.flush()

        # Add to team
        membership = TeamMember(
            user_id=user.id,
            team_id=team_id,
            role=role,
        )
        self.db.add(membership)
        await self.db.flush()
        await self.db.refresh(membership)

        # Load user relationship
        result = await self.db.execute(
            select(TeamMember)
            .options(selectinload(TeamMember.user))
            .where(
                TeamMember.user_id == user.id,
                TeamMember.team_id == team_id,
            )
        )
        return result.scalar_one()

    async def has_active_invite(self, user_id: uuid.UUID, team_id: uuid.UUID) -> bool:
        """Check if a user has an active (non-accepted) invite for a team."""
        result = await self.db.execute(
            select(Invite).where(
                and_(
                    Invite.user_id == user_id,
                    Invite.team_id == team_id,
                    Invite.accepted_at.is_(None),
                )
            )
        )
        return result.scalar_one_or_none() is not None

    async def get_member_invite_status(
        self, members: list[TeamMember], team_id: uuid.UUID
    ) -> dict[uuid.UUID, bool]:
        """Get invite status for a list of members.

        Returns a dict mapping user_id -> is_invited (True if has active invite).
        """
        user_ids = [m.user_id for m in members]
        if not user_ids:
            return {}

        result = await self.db.execute(
            select(Invite.user_id).where(
                and_(
                    Invite.team_id == team_id,
                    Invite.user_id.in_(user_ids),
                    Invite.accepted_at.is_(None),
                )
            )
        )
        invited_user_ids = set(result.scalars().all())
        return {uid: uid in invited_user_ids for uid in user_ids}
