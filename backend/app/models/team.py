import enum
import uuid
from typing import TYPE_CHECKING

from sqlalchemy import Enum, ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.core.permissions import TeamPermission
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.user import User
    from app.models.organisation import Organisation
    from app.models.roster import Roster
    from app.models.invite import Invite


class TeamRole(str, enum.Enum):
    """Role of a user within a team."""

    LEAD = "lead"
    MEMBER = "member"


class Team(Base, UUIDMixin, TimestampMixin):
    """Team model (e.g., Media Team, Praise & Worship)."""

    __tablename__ = "teams"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    organisation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("organisations.id", ondelete="CASCADE"), nullable=False
    )

    # Relationships
    organisation: Mapped["Organisation"] = relationship(back_populates="teams")
    members: Mapped[list["TeamMember"]] = relationship(
        back_populates="team", cascade="all, delete-orphan"
    )
    rosters: Mapped[list["Roster"]] = relationship(
        back_populates="team", cascade="all, delete-orphan"
    )
    invites: Mapped[list["Invite"]] = relationship(
        back_populates="team", cascade="all, delete-orphan"
    )


class TeamMember(Base, TimestampMixin):
    """Association table for users belonging to teams with roles."""

    __tablename__ = "team_members"
    __table_args__ = (UniqueConstraint("user_id", "team_id", name="uq_user_team"),)

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    team_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("teams.id", ondelete="CASCADE"), primary_key=True
    )
    role: Mapped[TeamRole] = mapped_column(
        Enum(TeamRole), default=TeamRole.MEMBER, nullable=False
    )
    permissions: Mapped[list[str]] = mapped_column(
        ARRAY(String), default=list, server_default="{}", nullable=False
    )

    # Relationships
    user: Mapped["User"] = relationship(back_populates="team_memberships")
    team: Mapped["Team"] = relationship(back_populates="members")

    def has_permission(self, permission: str) -> bool:
        """Check if the member has a specific permission."""
        return permission in self.permissions

    def has_any_permission(self, *permissions: str) -> bool:
        """Check if the member has any of the specified permissions."""
        return any(p in self.permissions for p in permissions)

    def has_all_permissions(self, *permissions: str) -> bool:
        """Check if the member has all of the specified permissions."""
        return all(p in self.permissions for p in permissions)

    @property
    def is_team_lead(self) -> bool:
        """Check if member has team lead-level permissions (backward compat)."""
        return self.has_permission(TeamPermission.MANAGE_TEAM)
