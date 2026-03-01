import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_password_hash, verify_password, create_access_token
from app.models.user import User
from app.schemas.user import UserCreate


class AuthService:
    """Service for authentication operations."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_user_by_email(self, email: str) -> User | None:
        """Get a user by email address."""
        result = await self.db.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def create_user(self, user_data: UserCreate) -> User:
        """Create a new user."""
        user = User(
            email=user_data.email,
            name=user_data.name,
            password_hash=get_password_hash(user_data.password),
        )
        self.db.add(user)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def get_user_by_google_id(self, google_id: str) -> User | None:
        """Get a user by Google ID."""
        result = await self.db.execute(select(User).where(User.google_id == google_id))
        return result.scalar_one_or_none()

    async def authenticate_user(self, email: str, password: str) -> User | None:
        """Authenticate a user by email and password."""
        user = await self.get_user_by_email(email)
        if not user:
            return None
        if not user.password_hash:
            return None
        if not verify_password(password, user.password_hash):
            return None
        return user

    async def authenticate_or_create_google_user(
        self, google_id: str, email: str, name: str
    ) -> User:
        """Authenticate or create a user from Google OAuth.

        Cases:
        1. Already linked by google_id -> return existing
        2. Existing registered user by email, no google_id -> link and return
        3. Placeholder user by email -> convert to full user with Google
        4. No user exists -> create new (no password_hash)
        """
        # Case 1: Already linked
        user = await self.get_user_by_google_id(google_id)
        if user:
            return user

        # Check by email
        user = await self.get_user_by_email(email)
        if user:
            if user.is_placeholder:
                # Case 3: Convert placeholder
                user.google_id = google_id
                user.name = name
                user.is_placeholder = False
            else:
                # Case 2: Link existing user
                user.google_id = google_id
            await self.db.flush()
            await self.db.refresh(user)
            return user

        # Case 4: Create new user
        user = User(
            email=email,
            name=name,
            google_id=google_id,
        )
        self.db.add(user)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def get_user_roles(self, user_id: uuid.UUID) -> list[str]:
        """Get user roles based on team memberships."""
        from app.models.team import TeamMember

        roles = ["member"]  # Everyone is at least a member

        # Check if user is a team lead
        result = await self.db.execute(
            select(TeamMember).where(
                TeamMember.user_id == user_id, TeamMember.role == "lead"
            )
        )
        team_lead_memberships = result.scalars().all()

        if team_lead_memberships:
            roles.append("team_lead")

        # Check if user is an org admin
        from app.models.organisation import OrganisationMember, OrganisationRole

        org_result = await self.db.execute(
            select(OrganisationMember).where(
                OrganisationMember.user_id == user_id,
                OrganisationMember.role == OrganisationRole.ADMIN,
            )
        )
        if org_result.scalars().first():
            roles.append("admin")

        return roles

    def create_token(self, user: User) -> str:
        """Create a JWT access token for a user."""
        return create_access_token(subject=str(user.id))
