import uuid
from datetime import date

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.availability import Unavailability
from app.models.roster import Assignment, Roster
from app.schemas.availability import UnavailabilityCreate


class AvailabilityService:
    """Service for availability operations."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def mark_unavailable(
        self, user_id: uuid.UUID, data: UnavailabilityCreate
    ) -> Unavailability:
        """Mark a date as unavailable for a user."""
        unavailability = Unavailability(
            user_id=user_id,
            date=data.date,
            reason=data.reason,
        )
        self.db.add(unavailability)
        await self.db.flush()
        await self.db.refresh(unavailability)
        return unavailability

    async def get_user_unavailabilities(
        self,
        user_id: uuid.UUID,
        start_date: date | None = None,
        end_date: date | None = None,
    ) -> list[Unavailability]:
        """Get all unavailabilities for a user within a date range."""
        query = select(Unavailability).where(Unavailability.user_id == user_id)
        if start_date:
            query = query.where(Unavailability.date >= start_date)
        if end_date:
            query = query.where(Unavailability.date <= end_date)
        query = query.order_by(Unavailability.date)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def delete_unavailability(self, unavailability_id: uuid.UUID) -> bool:
        """Delete an unavailability record."""
        result = await self.db.execute(
            select(Unavailability).where(Unavailability.id == unavailability_id)
        )
        unavailability = result.scalar_one_or_none()
        if not unavailability:
            return False
        await self.db.delete(unavailability)
        return True

    async def check_user_conflicts(
        self, user_id: uuid.UUID
    ) -> list[tuple[Assignment, Unavailability]]:
        """Check for conflicts between assignments and unavailabilities for a user."""
        # Get all assignments for the user
        assignments_result = await self.db.execute(
            select(Assignment)
            .options(selectinload(Assignment.roster).selectinload(Roster.team))
            .where(Assignment.user_id == user_id)
        )
        assignments = list(assignments_result.scalars().all())

        # Get all unavailabilities for the user
        unavailabilities_result = await self.db.execute(
            select(Unavailability).where(Unavailability.user_id == user_id)
        )
        unavailabilities = list(unavailabilities_result.scalars().all())

        # Find conflicts (same date)
        conflicts = []
        for assignment in assignments:
            for unavailability in unavailabilities:
                if assignment.date == unavailability.date:
                    conflicts.append((assignment, unavailability))

        return conflicts

    async def get_team_availability(
        self, team_id: uuid.UUID, target_date: date
    ) -> dict[uuid.UUID, bool]:
        """Get availability status for all team members on a specific date."""
        from app.models.team import TeamMember

        # Get all team members
        members_result = await self.db.execute(
            select(TeamMember).where(TeamMember.team_id == team_id)
        )
        members = list(members_result.scalars().all())

        # Check unavailability for each member on the target date
        availability = {}
        for member in members:
            unavail_result = await self.db.execute(
                select(Unavailability).where(
                    and_(
                        Unavailability.user_id == member.user_id,
                        Unavailability.date == target_date,
                    )
                )
            )
            is_unavailable = unavail_result.scalar_one_or_none() is not None
            availability[member.user_id] = not is_unavailable  # True if available

        return availability
