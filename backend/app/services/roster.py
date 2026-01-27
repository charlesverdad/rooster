import uuid
from datetime import date, timedelta
from typing import Optional

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.roster import (
    Assignment,
    AssignmentStatus,
    EventAssignment,
    RecurrencePattern,
    Roster,
    RosterEvent,
)
from app.models.team import Team, TeamMember, TeamRole
from app.models.invite import Invite
from app.schemas.roster import AssignmentCreate, RosterCreate, RosterUpdate


def calculate_event_dates(
    start_date: date,
    recurrence_pattern: RecurrencePattern,
    recurrence_day: int,
    count: int,
    end_date: Optional[date] = None,
    end_after_occurrences: Optional[int] = None,
) -> list[date]:
    """Calculate the dates for roster events based on recurrence pattern.

    Args:
        start_date: The first possible date
        recurrence_pattern: Weekly, biweekly, monthly, or one_time
        recurrence_day: Day of week (0=Monday, 6=Sunday) or day of month
        count: Maximum number of events to generate
        end_date: Optional end date (no events after this date)
        end_after_occurrences: Optional max occurrences

    Returns:
        List of dates for events
    """
    if recurrence_pattern == RecurrencePattern.ONE_TIME:
        return [start_date]

    dates = []
    current = start_date

    # Find the first occurrence on or after start_date
    if recurrence_pattern in (RecurrencePattern.WEEKLY, RecurrencePattern.BIWEEKLY):
        # recurrence_day is day of week (0=Monday, 6=Sunday)
        days_until = (recurrence_day - current.weekday()) % 7
        if days_until == 0 and current >= start_date:
            pass  # Current day is correct
        else:
            current = current + timedelta(days=days_until if days_until > 0 else 7)

    elif recurrence_pattern == RecurrencePattern.MONTHLY:
        # recurrence_day is day of month
        if current.day > recurrence_day:
            # Move to next month
            if current.month == 12:
                current = date(current.year + 1, 1, recurrence_day)
            else:
                current = date(current.year, current.month + 1, recurrence_day)
        else:
            current = date(current.year, current.month, recurrence_day)

    max_events = count
    if end_after_occurrences:
        max_events = min(max_events, end_after_occurrences)

    while len(dates) < max_events:
        if end_date and current > end_date:
            break

        dates.append(current)

        # Move to next occurrence
        if recurrence_pattern == RecurrencePattern.WEEKLY:
            current = current + timedelta(weeks=1)
        elif recurrence_pattern == RecurrencePattern.BIWEEKLY:
            current = current + timedelta(weeks=2)
        elif recurrence_pattern == RecurrencePattern.MONTHLY:
            # Move to next month, same day
            if current.month == 12:
                current = date(current.year + 1, 1, recurrence_day)
            else:
                try:
                    current = date(current.year, current.month + 1, recurrence_day)
                except ValueError:
                    # Day doesn't exist in that month, skip
                    if current.month == 11:
                        current = date(current.year + 1, 1, recurrence_day)
                    else:
                        current = date(current.year, current.month + 2, recurrence_day)

    return dates


class RosterService:
    """Service for roster operations."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_roster(self, data: RosterCreate) -> Roster:
        """Create a new roster and generate initial events."""
        roster = Roster(
            name=data.name,
            team_id=data.team_id,
            recurrence_pattern=data.recurrence_pattern,
            recurrence_day=data.recurrence_day,
            slots_needed=data.slots_needed,
            assignment_mode=data.assignment_mode,
            location=data.location,
            notes=data.notes,
            start_date=data.start_date,
            end_date=data.end_date,
            end_after_occurrences=data.end_after_occurrences,
        )
        self.db.add(roster)
        await self.db.flush()

        # Generate events
        event_dates = calculate_event_dates(
            start_date=data.start_date,
            recurrence_pattern=data.recurrence_pattern,
            recurrence_day=data.recurrence_day,
            count=data.generate_events_count,
            end_date=data.end_date,
            end_after_occurrences=data.end_after_occurrences,
        )

        for event_date in event_dates:
            event = RosterEvent(
                roster_id=roster.id,
                date=event_date,
            )
            self.db.add(event)

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

    # RosterEvent methods
    async def get_event(self, event_id: uuid.UUID) -> RosterEvent | None:
        """Get a roster event by ID."""
        result = await self.db.execute(
            select(RosterEvent)
            .options(
                selectinload(RosterEvent.roster),
                selectinload(RosterEvent.event_assignments).selectinload(EventAssignment.user),
            )
            .where(RosterEvent.id == event_id)
        )
        return result.scalar_one_or_none()

    async def get_roster_events(
        self,
        roster_id: uuid.UUID,
        start_date: date | None = None,
        end_date: date | None = None,
        include_cancelled: bool = False,
    ) -> list[RosterEvent]:
        """Get events for a roster within a date range."""
        query = (
            select(RosterEvent)
            .options(
                selectinload(RosterEvent.event_assignments).selectinload(EventAssignment.user)
            )
            .where(RosterEvent.roster_id == roster_id)
        )
        if start_date:
            query = query.where(RosterEvent.date >= start_date)
        if end_date:
            query = query.where(RosterEvent.date <= end_date)
        if not include_cancelled:
            query = query.where(RosterEvent.is_cancelled == False)
        query = query.order_by(RosterEvent.date)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_team_events(
        self,
        team_id: uuid.UUID,
        start_date: date | None = None,
        end_date: date | None = None,
        include_cancelled: bool = False,
    ) -> list[RosterEvent]:
        """Get all events for a team within a date range."""
        query = (
            select(RosterEvent)
            .join(Roster)
            .options(
                selectinload(RosterEvent.roster),
                selectinload(RosterEvent.event_assignments).selectinload(EventAssignment.user),
            )
            .where(Roster.team_id == team_id)
        )
        if start_date:
            query = query.where(RosterEvent.date >= start_date)
        if end_date:
            query = query.where(RosterEvent.date <= end_date)
        if not include_cancelled:
            query = query.where(RosterEvent.is_cancelled == False)
        query = query.order_by(RosterEvent.date)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_unfilled_events(
        self,
        team_id: uuid.UUID,
        start_date: date | None = None,
        end_date: date | None = None,
    ) -> list[RosterEvent]:
        """Get events that don't have enough confirmed volunteers."""
        events = await self.get_team_events(
            team_id=team_id,
            start_date=start_date,
            end_date=end_date,
            include_cancelled=False,
        )

        unfilled = []
        for event in events:
            confirmed_count = sum(
                1 for a in event.event_assignments
                if a.status == AssignmentStatus.CONFIRMED
            )
            if confirmed_count < event.roster.slots_needed:
                unfilled.append(event)

        return unfilled

    async def update_event(
        self, event_id: uuid.UUID, notes: str | None = None, is_cancelled: bool | None = None
    ) -> RosterEvent | None:
        """Update a roster event."""
        event = await self.get_event(event_id)
        if not event:
            return None
        if notes is not None:
            event.notes = notes
        if is_cancelled is not None:
            event.is_cancelled = is_cancelled
        await self.db.flush()
        await self.db.refresh(event)
        return event

    async def generate_more_events(self, roster_id: uuid.UUID, count: int = 12) -> list[RosterEvent]:
        """Generate more events for a roster starting after the last existing event."""
        roster = await self.get_roster(roster_id)
        if not roster:
            return []

        # Find the last event date
        result = await self.db.execute(
            select(func.max(RosterEvent.date)).where(RosterEvent.roster_id == roster_id)
        )
        last_date = result.scalar_one_or_none()

        start = last_date + timedelta(days=1) if last_date else roster.start_date

        event_dates = calculate_event_dates(
            start_date=start,
            recurrence_pattern=roster.recurrence_pattern,
            recurrence_day=roster.recurrence_day,
            count=count,
            end_date=roster.end_date,
            end_after_occurrences=roster.end_after_occurrences,
        )

        new_events = []
        for event_date in event_dates:
            event = RosterEvent(
                roster_id=roster.id,
                date=event_date,
            )
            self.db.add(event)
            new_events.append(event)

        await self.db.flush()
        for event in new_events:
            await self.db.refresh(event)

        return new_events

    # EventAssignment methods
    async def create_event_assignment(
        self,
        event_id: uuid.UUID,
        user_id: uuid.UUID,
        status: AssignmentStatus = AssignmentStatus.PENDING,
    ) -> EventAssignment | None:
        """Create an assignment for a roster event."""
        # Check event exists
        event = await self.get_event(event_id)
        if not event:
            return None

        # Check if user is already assigned
        existing = await self.db.execute(
            select(EventAssignment).where(
                and_(
                    EventAssignment.event_id == event_id,
                    EventAssignment.user_id == user_id,
                )
            )
        )
        if existing.scalar_one_or_none():
            return None  # Already assigned

        assignment = EventAssignment(
            event_id=event_id,
            user_id=user_id,
            status=status,
        )
        self.db.add(assignment)
        await self.db.flush()
        await self.db.refresh(assignment)
        return assignment

    async def get_event_assignment(self, assignment_id: uuid.UUID) -> EventAssignment | None:
        """Get an event assignment by ID."""
        result = await self.db.execute(
            select(EventAssignment)
            .options(
                selectinload(EventAssignment.user),
                selectinload(EventAssignment.event).selectinload(RosterEvent.roster),
            )
            .where(EventAssignment.id == assignment_id)
        )
        return result.scalar_one_or_none()

    async def get_user_event_assignments(
        self,
        user_id: uuid.UUID,
        start_date: date | None = None,
        end_date: date | None = None,
    ) -> list[EventAssignment]:
        """Get all event assignments for a user within a date range."""
        query = (
            select(EventAssignment)
            .join(RosterEvent)
            .options(
                selectinload(EventAssignment.user),
                selectinload(EventAssignment.event).selectinload(RosterEvent.roster),
            )
            .where(EventAssignment.user_id == user_id)
        )
        if start_date:
            query = query.where(RosterEvent.date >= start_date)
        if end_date:
            query = query.where(RosterEvent.date <= end_date)
        query = query.order_by(RosterEvent.date)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def update_event_assignment_status(
        self, assignment_id: uuid.UUID, status: AssignmentStatus
    ) -> EventAssignment | None:
        """Update an event assignment's status."""
        assignment = await self.get_event_assignment(assignment_id)
        if not assignment:
            return None
        assignment.status = status
        await self.db.flush()
        await self.db.refresh(assignment)
        return assignment

    async def delete_event_assignment(self, assignment_id: uuid.UUID) -> bool:
        """Delete an event assignment."""
        assignment = await self.get_event_assignment(assignment_id)
        if not assignment:
            return False
        await self.db.delete(assignment)
        return True

    async def get_event_assignment_with_invite_status(
        self, event_id: uuid.UUID
    ) -> list[dict]:
        """Get all assignments for an event with invite status for placeholder users."""
        event = await self.get_event(event_id)
        if not event:
            return []

        # Get all user IDs that are placeholders
        placeholder_user_ids = [
            a.user_id for a in event.event_assignments
            if a.user and a.user.is_placeholder
        ]

        # Check which placeholders have active invites
        invite_status = {}
        if placeholder_user_ids:
            result = await self.db.execute(
                select(Invite.user_id).where(
                    and_(
                        Invite.team_id == event.roster.team_id,
                        Invite.user_id.in_(placeholder_user_ids),
                        Invite.accepted_at.is_(None),
                    )
                )
            )
            invited_ids = set(result.scalars().all())
            invite_status = {uid: uid in invited_ids for uid in placeholder_user_ids}

        return [
            {
                "assignment": a,
                "is_placeholder": a.user.is_placeholder if a.user else False,
                "is_invited": invite_status.get(a.user_id, False),
            }
            for a in event.event_assignments
        ]

    async def get_event_assignment_detail(
        self, assignment_id: uuid.UUID
    ) -> dict | None:
        """Get detailed info for an event assignment including co-volunteers and team lead."""
        # Need to eagerly load all relationships we'll access:
        # - assignment.user
        # - assignment.event
        # - event.roster
        # - event.event_assignments (for co-volunteers)
        # - event.event_assignments.user (for co-volunteer names)
        result = await self.db.execute(
            select(EventAssignment)
            .options(
                selectinload(EventAssignment.user),
                selectinload(EventAssignment.event)
                .selectinload(RosterEvent.roster),
                selectinload(EventAssignment.event)
                .selectinload(RosterEvent.event_assignments)
                .selectinload(EventAssignment.user),
            )
            .where(EventAssignment.id == assignment_id)
        )
        assignment = result.scalar_one_or_none()
        if not assignment:
            return None

        event = assignment.event
        roster = event.roster

        # Get all co-volunteers (other assignments for the same event)
        co_volunteers = []
        placeholder_user_ids = []

        for a in event.event_assignments:
            if a.id != assignment_id and a.user:
                if a.user.is_placeholder:
                    placeholder_user_ids.append(a.user_id)
                co_volunteers.append({
                    "assignment": a,
                    "is_placeholder": a.user.is_placeholder,
                })

        # Check invite status for placeholders
        invite_status = {}
        if placeholder_user_ids:
            result = await self.db.execute(
                select(Invite.user_id).where(
                    and_(
                        Invite.team_id == roster.team_id,
                        Invite.user_id.in_(placeholder_user_ids),
                        Invite.accepted_at.is_(None),
                    )
                )
            )
            invited_ids = set(result.scalars().all())
            invite_status = {uid: uid in invited_ids for uid in placeholder_user_ids}

        # Enrich co-volunteers with invite status
        for cv in co_volunteers:
            cv["is_invited"] = invite_status.get(cv["assignment"].user_id, False)

        # Get team lead
        result = await self.db.execute(
            select(TeamMember)
            .options(selectinload(TeamMember.user))
            .where(
                and_(
                    TeamMember.team_id == roster.team_id,
                    TeamMember.role == TeamRole.LEAD,
                )
            )
        )
        team_lead_membership = result.scalar_one_or_none()
        team_lead = None
        if team_lead_membership and team_lead_membership.user:
            team_lead = {
                "user_id": team_lead_membership.user_id,
                "name": team_lead_membership.user.name,
                "email": team_lead_membership.user.email,
            }

        # Get team name
        result = await self.db.execute(select(Team).where(Team.id == roster.team_id))
        team = result.scalar_one_or_none()
        team_name = team.name if team else ""

        # Check assignment user invite status
        is_invited = False
        if assignment.user and assignment.user.is_placeholder:
            is_invited = await self.db.execute(
                select(Invite.id).where(
                    and_(
                        Invite.team_id == roster.team_id,
                        Invite.user_id == assignment.user_id,
                        Invite.accepted_at.is_(None),
                    )
                )
            )
            is_invited = is_invited.scalar_one_or_none() is not None

        return {
            "assignment": assignment,
            "event": event,
            "roster": roster,
            "team_name": team_name,
            "co_volunteers": co_volunteers,
            "team_lead": team_lead,
            "is_placeholder": assignment.user.is_placeholder if assignment.user else False,
            "is_invited": is_invited,
        }
