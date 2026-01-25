import enum
import uuid
from datetime import date
from typing import TYPE_CHECKING, Optional

from sqlalchemy import Boolean, Date, Enum, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.team import Team
    from app.models.user import User


class RecurrencePattern(str, enum.Enum):
    """Pattern for recurring rosters."""

    WEEKLY = "weekly"
    BIWEEKLY = "biweekly"
    MONTHLY = "monthly"
    ONE_TIME = "one_time"  # For single events


class AssignmentMode(str, enum.Enum):
    """Mode for assigning volunteers to roster slots."""

    MANUAL = "manual"
    AUTO_ROTATE = "auto_rotate"
    RANDOM = "random"


class AssignmentStatus(str, enum.Enum):
    """Status of an assignment."""

    PENDING = "pending"
    CONFIRMED = "confirmed"
    DECLINED = "declined"


class Roster(Base, UUIDMixin, TimestampMixin):
    """Roster model - a recurring schedule template."""

    __tablename__ = "rosters"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    team_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("teams.id", ondelete="CASCADE"), nullable=False
    )
    recurrence_pattern: Mapped[RecurrencePattern] = mapped_column(
        Enum(RecurrencePattern), default=RecurrencePattern.WEEKLY, nullable=False
    )
    recurrence_day: Mapped[int] = mapped_column(
        Integer, nullable=False
    )  # 0=Monday, 6=Sunday
    slots_needed: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    assignment_mode: Mapped[AssignmentMode] = mapped_column(
        Enum(AssignmentMode), default=AssignmentMode.MANUAL, nullable=False
    )

    # Enhanced fields
    location: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    end_after_occurrences: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    team: Mapped["Team"] = relationship(back_populates="rosters")
    events: Mapped[list["RosterEvent"]] = relationship(
        back_populates="roster", cascade="all, delete-orphan"
    )
    # Keep direct assignments for backward compatibility
    assignments: Mapped[list["Assignment"]] = relationship(
        back_populates="roster", cascade="all, delete-orphan"
    )


class RosterEvent(Base, UUIDMixin, TimestampMixin):
    """A single occurrence of a roster.

    This represents a specific date when the roster occurs. Events are
    generated from the roster's recurrence pattern.
    """

    __tablename__ = "roster_events"

    roster_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("rosters.id", ondelete="CASCADE"), nullable=False
    )
    date: Mapped[date] = mapped_column(Date, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_cancelled: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Relationships
    roster: Mapped["Roster"] = relationship(back_populates="events")
    event_assignments: Mapped[list["EventAssignment"]] = relationship(
        back_populates="event", cascade="all, delete-orphan"
    )


class Assignment(Base, UUIDMixin, TimestampMixin):
    """Assignment model - a specific person assigned to a roster on a date.

    NOTE: This is kept for backward compatibility. New assignments should
    use EventAssignment which links to a specific RosterEvent.
    """

    __tablename__ = "assignments"

    roster_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("rosters.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    date: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[AssignmentStatus] = mapped_column(
        Enum(AssignmentStatus), default=AssignmentStatus.PENDING, nullable=False
    )

    # Relationships
    roster: Mapped["Roster"] = relationship(back_populates="assignments")
    user: Mapped["User"] = relationship(back_populates="assignments")


class EventAssignment(Base, UUIDMixin, TimestampMixin):
    """Assignment to a specific roster event."""

    __tablename__ = "event_assignments"

    event_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("roster_events.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    status: Mapped[AssignmentStatus] = mapped_column(
        Enum(AssignmentStatus), default=AssignmentStatus.PENDING, nullable=False
    )

    # Relationships
    event: Mapped["RosterEvent"] = relationship(back_populates="event_assignments")
    user: Mapped["User"] = relationship("User")
