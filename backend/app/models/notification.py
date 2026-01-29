import enum
import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.user import User


class NotificationType(str, enum.Enum):
    """Types of notifications."""

    ASSIGNMENT_CREATED = "assignment_created"
    ASSIGNMENT_REMINDER = "assignment_reminder"
    CONFLICT_DETECTED = "conflict_detected"
    TEAM_JOINED = "team_joined"
    SWAP_REQUESTED = "swap_requested"
    SWAP_ACCEPTED = "swap_accepted"
    SWAP_DECLINED = "swap_declined"
    SWAP_EXPIRED = "swap_expired"
    SWAP_COMPLETED = "swap_completed"


class Notification(Base, UUIDMixin, TimestampMixin):
    """Notification model - in-app notifications for users."""

    __tablename__ = "notifications"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    type: Mapped[NotificationType] = mapped_column(
        Enum(NotificationType), nullable=False
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    reference_id: Mapped[uuid.UUID | None] = mapped_column(nullable=True)
    read_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Relationships
    user: Mapped["User"] = relationship(back_populates="notifications")
