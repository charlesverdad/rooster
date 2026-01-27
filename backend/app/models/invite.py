import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional
import secrets

from sqlalchemy import String, ForeignKey, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.user import User
    from app.models.team import Team


def generate_invite_token() -> str:
    """Generate a secure random invite token."""
    return secrets.token_urlsafe(32)


class Invite(Base, UUIDMixin, TimestampMixin):
    """Invite model for inviting placeholder users to create accounts.

    When a team lead invites a placeholder user, an invite record is created
    with a unique token. The placeholder user receives an email with a link
    containing this token. When they click the link and set their password,
    the invite is marked as accepted and the user is converted to a full user.
    """

    __tablename__ = "invites"

    # The team the user is being invited to
    team_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("teams.id", ondelete="CASCADE"), nullable=False
    )

    # The placeholder user being invited
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    # The email to send the invite to
    email: Mapped[str] = mapped_column(String(255), nullable=False)

    # Unique token for the invite link
    token: Mapped[str] = mapped_column(
        String(64),
        unique=True,
        index=True,
        nullable=False,
        default=generate_invite_token,
    )

    # When the invite was accepted (null if not yet accepted)
    accepted_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Relationships
    team: Mapped["Team"] = relationship("Team", back_populates="invites")
    user: Mapped["User"] = relationship("User")

    @property
    def is_accepted(self) -> bool:
        """Check if the invite has been accepted."""
        return self.accepted_at is not None

    @property
    def is_expired(self) -> bool:
        """Check if the invite has expired (7 days)."""
        if self.accepted_at is not None:
            return True
        age = datetime.utcnow() - self.created_at.replace(tzinfo=None)
        return age.days > 7
