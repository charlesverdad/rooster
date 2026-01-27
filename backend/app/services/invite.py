import uuid
from datetime import datetime, timezone

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import get_password_hash, create_access_token
from app.models.invite import Invite
from app.models.user import User
from app.models.team import Team
from app.services.notification import NotificationService


class InviteService:
    """Service for invite operations."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_invite(
        self,
        team_id: uuid.UUID,
        user_id: uuid.UUID,
        email: str,
    ) -> Invite:
        """Create a new invite for a placeholder user.

        Args:
            team_id: The team the user is being invited to
            user_id: The placeholder user being invited
            email: The email to send the invite to

        Returns:
            The created invite
        """
        # Check if there's already an active invite for this user/team
        existing = await self.get_active_invite(user_id, team_id)
        if existing:
            # Update email if different and return existing
            if existing.email != email:
                existing.email = email
                await self.db.flush()
                await self.db.refresh(existing)
            return existing

        invite = Invite(
            team_id=team_id,
            user_id=user_id,
            email=email,
        )
        self.db.add(invite)
        await self.db.flush()
        await self.db.refresh(invite)

        # Update the user's email and invited_at timestamp
        user = await self.db.get(User, user_id)
        if user:
            user.email = email
            user.invited_at = datetime.now(timezone.utc)
            await self.db.flush()

        return invite

    async def get_invite_by_token(self, token: str) -> Invite | None:
        """Get an invite by its token."""
        result = await self.db.execute(
            select(Invite)
            .options(selectinload(Invite.team), selectinload(Invite.user))
            .where(Invite.token == token)
        )
        return result.scalar_one_or_none()

    async def get_active_invite(
        self, user_id: uuid.UUID, team_id: uuid.UUID
    ) -> Invite | None:
        """Get an active (non-accepted) invite for a user in a team."""
        result = await self.db.execute(
            select(Invite).where(
                and_(
                    Invite.user_id == user_id,
                    Invite.team_id == team_id,
                    Invite.accepted_at.is_(None),
                )
            )
        )
        return result.scalar_one_or_none()

    async def get_user_invites(self, user_id: uuid.UUID) -> list[Invite]:
        """Get all invites for a user."""
        result = await self.db.execute(
            select(Invite)
            .options(selectinload(Invite.team))
            .where(Invite.user_id == user_id)
            .order_by(Invite.created_at.desc())
        )
        return list(result.scalars().all())

    async def validate_token(self, token: str) -> dict:
        """Validate an invite token and return validation info.

        Returns a dict with:
            valid: bool - whether the token is valid
            team_name: str | None - the team name
            user_name: str | None - the user name
            email: str | None - the invite email
            expired: bool - whether the invite is expired
            already_accepted: bool - whether the invite was already accepted
        """
        invite = await self.get_invite_by_token(token)

        if not invite:
            return {
                "valid": False,
                "team_name": None,
                "user_name": None,
                "email": None,
                "expired": False,
                "already_accepted": False,
            }

        if invite.is_accepted:
            return {
                "valid": False,
                "team_name": invite.team.name,
                "user_name": invite.user.name,
                "email": invite.email,
                "expired": False,
                "already_accepted": True,
            }

        if invite.is_expired:
            return {
                "valid": False,
                "team_name": invite.team.name,
                "user_name": invite.user.name,
                "email": invite.email,
                "expired": True,
                "already_accepted": False,
            }

        return {
            "valid": True,
            "team_name": invite.team.name,
            "user_name": invite.user.name,
            "email": invite.email,
            "expired": False,
            "already_accepted": False,
        }

    async def accept_invite(
        self, token: str, password: str
    ) -> tuple[bool, str, User | None, str | None, "uuid.UUID | None", str | None]:
        """Accept an invite by setting the user's password.

        Args:
            token: The invite token
            password: The password to set for the user

        Returns:
            A tuple of (success, message, user, access_token, team_id, team_name)
        """
        invite = await self.get_invite_by_token(token)

        if not invite:
            return False, "Invalid invite token", None, None, None, None

        if invite.is_accepted:
            return False, "This invite has already been accepted", None, None, None, None

        if invite.is_expired:
            return False, "This invite has expired", None, None, None, None

        # Convert placeholder to full user
        user = invite.user
        user.password_hash = get_password_hash(password)
        user.is_placeholder = False

        # Mark invite as accepted
        invite.accepted_at = datetime.now(timezone.utc)

        notification_service = NotificationService(self.db)
        await notification_service.notify_team_joined(
            user_id=user.id,
            team_id=invite.team_id,
            team_name=invite.team.name if invite.team else "your team",
        )

        await self.db.flush()
        await self.db.refresh(user)

        # Create access token for immediate login
        access_token = create_access_token(subject=str(user.id))

        team_id = invite.team_id
        team_name = invite.team.name if invite.team else None

        return True, "Account created successfully", user, access_token, team_id, team_name

    async def resend_invite(self, invite_id: uuid.UUID) -> Invite | None:
        """Resend an invite by generating a new token.

        Args:
            invite_id: The invite ID

        Returns:
            The updated invite with new token, or None if not found
        """
        result = await self.db.execute(
            select(Invite).where(Invite.id == invite_id)
        )
        invite = result.scalar_one_or_none()

        if not invite or invite.is_accepted:
            return None

        # Generate new token
        from app.models.invite import generate_invite_token
        invite.token = generate_invite_token()
        invite.created_at = datetime.now(timezone.utc)

        await self.db.flush()
        await self.db.refresh(invite)

        return invite
