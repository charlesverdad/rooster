import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import String, Boolean, ForeignKey, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.organisation import OrganisationMember
    from app.models.team import TeamMember
    from app.models.roster import Assignment
    from app.models.availability import Unavailability
    from app.models.notification import Notification
    from app.models.push_subscription import PushSubscription


class User(Base, UUIDMixin, TimestampMixin):
    """User model for authentication and profile.

    Supports placeholder users (name only, no email/password) that can be
    invited later to create a full account.
    """

    __tablename__ = "users"

    # Email and password are nullable for placeholder users
    email: Mapped[Optional[str]] = mapped_column(
        String(255), unique=True, index=True, nullable=True
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    password_hash: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    # Placeholder user fields
    is_placeholder: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    invited_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    invited_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Relationships
    organisation_memberships: Mapped[list["OrganisationMember"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    team_memberships: Mapped[list["TeamMember"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    assignments: Mapped[list["Assignment"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    unavailabilities: Mapped[list["Unavailability"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    notifications: Mapped[list["Notification"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    push_subscriptions: Mapped[list["PushSubscription"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )

    # Self-referential relationship for invited_by
    invited_by: Mapped[Optional["User"]] = relationship(
        "User", remote_side="User.id", foreign_keys=[invited_by_id]
    )
