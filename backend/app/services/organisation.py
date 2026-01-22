import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.organisation import Organisation, OrganisationMember, OrganisationRole
from app.models.user import User
from app.schemas.organisation import OrganisationCreate, OrganisationUpdate


class OrganisationService:
    """Service for organisation operations."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_organisation(
        self, data: OrganisationCreate, creator_id: uuid.UUID
    ) -> Organisation:
        """Create a new organisation with the creator as admin."""
        org = Organisation(name=data.name)
        self.db.add(org)
        await self.db.flush()

        # Add creator as admin
        membership = OrganisationMember(
            user_id=creator_id,
            organisation_id=org.id,
            role=OrganisationRole.ADMIN,
        )
        self.db.add(membership)
        await self.db.flush()
        await self.db.refresh(org)
        return org

    async def get_organisation(self, org_id: uuid.UUID) -> Organisation | None:
        """Get an organisation by ID."""
        result = await self.db.execute(
            select(Organisation).where(Organisation.id == org_id)
        )
        return result.scalar_one_or_none()

    async def get_user_organisations(self, user_id: uuid.UUID) -> list[tuple[Organisation, OrganisationRole]]:
        """Get all organisations a user belongs to with their roles."""
        result = await self.db.execute(
            select(Organisation, OrganisationMember.role)
            .join(OrganisationMember)
            .where(OrganisationMember.user_id == user_id)
        )
        return list(result.all())

    async def update_organisation(
        self, org_id: uuid.UUID, data: OrganisationUpdate
    ) -> Organisation | None:
        """Update an organisation."""
        org = await self.get_organisation(org_id)
        if not org:
            return None
        if data.name is not None:
            org.name = data.name
        await self.db.flush()
        await self.db.refresh(org)
        return org

    async def delete_organisation(self, org_id: uuid.UUID) -> bool:
        """Delete an organisation."""
        org = await self.get_organisation(org_id)
        if not org:
            return False
        await self.db.delete(org)
        return True

    async def get_membership(
        self, user_id: uuid.UUID, org_id: uuid.UUID
    ) -> OrganisationMember | None:
        """Get a user's membership in an organisation."""
        result = await self.db.execute(
            select(OrganisationMember).where(
                OrganisationMember.user_id == user_id,
                OrganisationMember.organisation_id == org_id,
            )
        )
        return result.scalar_one_or_none()

    async def is_admin(self, user_id: uuid.UUID, org_id: uuid.UUID) -> bool:
        """Check if a user is an admin of an organisation."""
        membership = await self.get_membership(user_id, org_id)
        return membership is not None and membership.role == OrganisationRole.ADMIN

    async def add_member(
        self, org_id: uuid.UUID, user_id: uuid.UUID, role: OrganisationRole
    ) -> OrganisationMember | None:
        """Add a member to an organisation."""
        # Check if user exists
        user_result = await self.db.execute(select(User).where(User.id == user_id))
        if not user_result.scalar_one_or_none():
            return None

        # Check if already a member
        existing = await self.get_membership(user_id, org_id)
        if existing:
            return existing

        membership = OrganisationMember(
            user_id=user_id,
            organisation_id=org_id,
            role=role,
        )
        self.db.add(membership)
        await self.db.flush()
        await self.db.refresh(membership)
        return membership

    async def remove_member(self, org_id: uuid.UUID, user_id: uuid.UUID) -> bool:
        """Remove a member from an organisation."""
        membership = await self.get_membership(user_id, org_id)
        if not membership:
            return False
        await self.db.delete(membership)
        return True

    async def get_members(self, org_id: uuid.UUID) -> list[OrganisationMember]:
        """Get all members of an organisation."""
        result = await self.db.execute(
            select(OrganisationMember)
            .options(selectinload(OrganisationMember.user))
            .where(OrganisationMember.organisation_id == org_id)
        )
        return list(result.scalars().all())

    async def get_or_create_default(self, user_id: uuid.UUID) -> Organisation:
        """Get the user's default organisation, creating one if needed.

        For MVP, each user gets a personal organisation when they first create a team.
        This simplifies the model by not requiring explicit org creation.
        """
        # Check if user already has an organisation (take the first one as default)
        user_orgs = await self.get_user_organisations(user_id)
        if user_orgs:
            return user_orgs[0][0]  # Return the first organisation

        # Get user's name for the org name
        user_result = await self.db.execute(select(User).where(User.id == user_id))
        user = user_result.scalar_one_or_none()
        if not user:
            raise ValueError("User not found")

        # Create a personal organisation for this user
        org_name = f"{user.name}'s Organisation"
        org = Organisation(name=org_name)
        self.db.add(org)
        await self.db.flush()

        # Add user as admin
        membership = OrganisationMember(
            user_id=user_id,
            organisation_id=org.id,
            role=OrganisationRole.ADMIN,
        )
        self.db.add(membership)
        await self.db.flush()
        await self.db.refresh(org)

        return org
