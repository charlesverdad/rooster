import uuid
from datetime import date

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.roster import Assignment, AssignmentStatus, Roster
from app.models.team import Team
from app.schemas.roster import AssignmentCreate, RosterCreate, RosterUpdate


class RosterService:
    """Service for roster operations."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_roster(self, data: RosterCreate) -> Roster:
        """Create a new roster."""
        roster = Roster(
            name=data.name,
            team_id=data.team_id,
            recurrence_pattern=data.recurrence_pattern,
            recurrence_day=data.recurrence_day,
            slots_needed=data.slots_needed,
            assignment_mode=data.assignment_mode,
        )
        self.db.add(roster)
        await self.db.flush()
        await self.db.refresh(roster)
        return roster

    async def get_roster(self, roster_id: uuid.UUID) -> Roster | None:
        """Get a roster by ID."""
        result = await self.db.execute(
            select(Roster)
            .options(selectinload(Roster.team))
            .where(Roster.id == roster_id)
        )
        return result.scalar_one_or_none()

    async def get_team_rosters(self, team_id: uuid.UUID) -> list[Roster]:
        """Get all rosters for a team."""
        result = await self.db.execute(
            select(Roster).where(Roster.team_id == team_id)
        )
        return list(result.scalars().all())

    async def update_roster(
        self, roster_id: uuid.UUID, data: RosterUpdate
    ) -> Roster | None:
        """Update a roster."""
        roster = await self.get_roster(roster_id)
        if not roster:
            return None

        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(roster, field, value)

        await self.db.flush()
        await self.db.refresh(roster)
        return roster

    async def delete_roster(self, roster_id: uuid.UUID) -> bool:
        """Delete a roster."""
        roster = await self.get_roster(roster_id)
        if not roster:
            return False
        await self.db.delete(roster)
        return True

    async def create_assignment(self, data: AssignmentCreate) -> Assignment:
        """Create a new assignment."""
        assignment = Assignment(
            roster_id=data.roster_id,
            user_id=data.user_id,
            date=data.date,
            status=AssignmentStatus.PENDING,
        )
        self.db.add(assignment)
        await self.db.flush()
        await self.db.refresh(assignment)
        return assignment

    async def get_assignment(self, assignment_id: uuid.UUID) -> Assignment | None:
        """Get an assignment by ID."""
        result = await self.db.execute(
            select(Assignment)
            .options(selectinload(Assignment.user), selectinload(Assignment.roster))
            .where(Assignment.id == assignment_id)
        )
        return result.scalar_one_or_none()

    async def get_roster_assignments(
        self,
        roster_id: uuid.UUID,
        start_date: date | None = None,
        end_date: date | None = None,
    ) -> list[Assignment]:
        """Get assignments for a roster within a date range."""
        query = (
            select(Assignment)
            .options(selectinload(Assignment.user))
            .where(Assignment.roster_id == roster_id)
        )
        if start_date:
            query = query.where(Assignment.date >= start_date)
        if end_date:
            query = query.where(Assignment.date <= end_date)
        query = query.order_by(Assignment.date)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_user_assignments(
        self,
        user_id: uuid.UUID,
        start_date: date | None = None,
        end_date: date | None = None,
    ) -> list[Assignment]:
        """Get all assignments for a user within a date range."""
        query = (
            select(Assignment)
            .options(selectinload(Assignment.roster), selectinload(Assignment.user))
            .where(Assignment.user_id == user_id)
        )
        if start_date:
            query = query.where(Assignment.date >= start_date)
        if end_date:
            query = query.where(Assignment.date <= end_date)
        query = query.order_by(Assignment.date)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def update_assignment_status(
        self, assignment_id: uuid.UUID, status: AssignmentStatus
    ) -> Assignment | None:
        """Update an assignment's status."""
        assignment = await self.get_assignment(assignment_id)
        if not assignment:
            return None
        assignment.status = status
        await self.db.flush()
        await self.db.refresh(assignment)
        return assignment

    async def delete_assignment(self, assignment_id: uuid.UUID) -> bool:
        """Delete an assignment."""
        assignment = await self.get_assignment(assignment_id)
        if not assignment:
            return False
        await self.db.delete(assignment)
        return True
