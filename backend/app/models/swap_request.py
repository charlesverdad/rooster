import enum
import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import DateTime, Enum, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.roster import EventAssignment
    from app.models.user import User


class SwapRequestStatus(str, enum.Enum):
    """Status of a swap request."""

    PENDING = "pending"
    ACCEPTED = "accepted"
    DECLINED = "declined"
    EXPIRED = "expired"


class SwapRequest(Base, UUIDMixin, TimestampMixin):
    """Swap request model - allows volunteers to swap assignments with teammates.

    When a volunteer can't serve on an assigned date, they can request to swap
    with another team member. The target user can accept or decline the swap.
    Requests expire after 48 hours if not responded to.
    """

    __tablename__ = "swap_requests"

    requester_assignment_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("event_assignments.id", ondelete="CASCADE"), nullable=False
    )
    target_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    status: Mapped[SwapRequestStatus] = mapped_column(
        Enum(SwapRequestStatus), default=SwapRequestStatus.PENDING, nullable=False
    )
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    responded_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Relationships
    requester_assignment: Mapped["EventAssignment"] = relationship(
        "EventAssignment", foreign_keys=[requester_assignment_id]
    )
    target_user: Mapped["User"] = relationship("User", foreign_keys=[target_user_id])
