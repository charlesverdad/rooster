import enum
import uuid
from typing import TYPE_CHECKING

from sqlalchemy import Enum, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.user import User
    from app.models.team import Team


class OrganisationRole(str, enum.Enum):
    """Role of a user within an organisation."""

    ADMIN = "admin"
    MEMBER = "member"


class Organisation(Base, UUIDMixin, TimestampMixin):
    """Organisation model (e.g., a church or campus)."""

    __tablename__ = "organisations"

    name: Mapped[str] = mapped_column(String(255), nullable=False)

    # Relationships
    members: Mapped[list["OrganisationMember"]] = relationship(
        back_populates="organisation", cascade="all, delete-orphan"
    )
    teams: Mapped[list["Team"]] = relationship(
        back_populates="organisation", cascade="all, delete-orphan"
    )


class OrganisationMember(Base, TimestampMixin):
    """Association table for users belonging to organisations with roles."""

    __tablename__ = "organisation_members"
    __table_args__ = (
        UniqueConstraint("user_id", "organisation_id", name="uq_user_organisation"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    organisation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("organisations.id", ondelete="CASCADE"), primary_key=True
    )
    role: Mapped[OrganisationRole] = mapped_column(
        Enum(OrganisationRole), default=OrganisationRole.MEMBER, nullable=False
    )

    # Relationships
    user: Mapped["User"] = relationship(back_populates="organisation_memberships")
    organisation: Mapped["Organisation"] = relationship(back_populates="members")
