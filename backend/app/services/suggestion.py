import uuid
from datetime import date
from typing import Optional

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.availability import Unavailability
from app.models.roster import EventAssignment, RosterEvent, AssignmentStatus
from app.models.team import TeamMember


class Suggestion:
    """A suggested volunteer for an assignment."""

    def __init__(
        self,
        user_id: uuid.UUID,
        user_name: str,
        score: float,
        last_assignment_date: Optional[date],
        total_assignments: int,
        days_since_last: Optional[int],
    ):
        self.user_id = user_id
        self.user_name = user_name
        self.score = score
        self.last_assignment_date = last_assignment_date
        self.total_assignments = total_assignments
        self.days_since_last = days_since_last

    @property
    def reasoning(self) -> str:
        """Generate human-readable reasoning for this suggestion."""
        if self.days_since_last is None:
            return "Never assigned before"

        # Build time-based part
        if self.days_since_last == 0:
            time_part = "Last rostered today"
        elif self.days_since_last == 1:
            time_part = "Last rostered yesterday"
        else:
            time_part = f"Last rostered {self.days_since_last} days ago"

        # Add assignment count
        if self.total_assignments == 1:
            count_part = "1 previous assignment"
        else:
            count_part = f"{self.total_assignments} previous assignments"

        return f"{time_part}, {count_part}"

    def to_dict(self) -> dict:
        """Convert to dictionary for API responses."""
        return {
            "user_id": str(self.user_id),
            "user_name": self.user_name,
            "score": self.score,
            "reasoning": self.reasoning,
            "last_assignment_date": self.last_assignment_date.isoformat()
            if self.last_assignment_date
            else None,
            "total_assignments": self.total_assignments,
            "days_since_last": self.days_since_last,
        }


class SuggestionService:
    """Service for generating assignment suggestions."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_suggestions(
        self,
        event_id: uuid.UUID,
        team_id: uuid.UUID,
        limit: int = 10,
    ) -> list[Suggestion]:
        """Get suggested volunteers for an event based on fair rotation.

        Algorithm:
        1. Get all team members (excluding placeholders)
        2. For each member:
           - Find last assignment date across all events in the team
           - Count total assignments in the team
           - Check if unavailable for the event date
        3. Calculate score: days_since_last * 10 - total_assignments
        4. Filter out unavailable members
        5. Sort by score (descending) and return top N

        Args:
            event_id: The event to suggest volunteers for
            team_id: The team to search members from
            limit: Maximum number of suggestions to return

        Returns:
            List of Suggestion objects sorted by score (highest first)
        """
        # Get the event to know the date
        event_result = await self.db.execute(
            select(RosterEvent)
            .options(selectinload(RosterEvent.roster))
            .where(RosterEvent.id == event_id)
        )
        event = event_result.scalar_one_or_none()
        if not event:
            return []

        event_date = event.date

        # Get all team members (excluding placeholders)
        members_result = await self.db.execute(
            select(TeamMember)
            .options(selectinload(TeamMember.user))
            .where(TeamMember.team_id == team_id)
        )
        members = list(members_result.scalars().all())

        # Include all members (including placeholders - they are real people who haven't joined yet)
        real_members = [m for m in members if m.user]

        # Get unavailable user IDs for this date
        unavailable_result = await self.db.execute(
            select(Unavailability.user_id).where(
                and_(
                    Unavailability.date == event_date,
                    Unavailability.user_id.in_([m.user_id for m in real_members]),
                )
            )
        )
        unavailable_user_ids = set(unavailable_result.scalars().all())

        # Get all events in this team's rosters
        roster_ids_result = await self.db.execute(
            select(RosterEvent.id)
            .join(RosterEvent.roster)
            .where(RosterEvent.roster.has(team_id=team_id))
        )
        team_event_ids = [row[0] for row in roster_ids_result.all()]

        suggestions = []

        for member in real_members:
            if member.user_id in unavailable_user_ids:
                continue  # Skip unavailable members

            # Get last assignment date for this member across all team events
            # Include both CONFIRMED and PENDING (but not DECLINED)
            # Only consider past or current events (not future events)
            last_assignment_result = await self.db.execute(
                select(RosterEvent.date)
                .join(EventAssignment)
                .where(
                    and_(
                        EventAssignment.user_id == member.user_id,
                        EventAssignment.event_id.in_(team_event_ids),
                        EventAssignment.status.in_(
                            [AssignmentStatus.CONFIRMED, AssignmentStatus.PENDING]
                        ),
                        RosterEvent.date <= event_date,  # Only past/current events
                    )
                )
                .order_by(RosterEvent.date.desc())
                .limit(1)
            )
            last_assignment_date = last_assignment_result.scalar_one_or_none()

            # Count total assignments (CONFIRMED and PENDING) for this member in this team
            # PENDING assignments are treated as actual assignments that haven't been accepted yet
            total_assignments_result = await self.db.execute(
                select(func.count(EventAssignment.id)).where(
                    and_(
                        EventAssignment.user_id == member.user_id,
                        EventAssignment.event_id.in_(team_event_ids),
                        EventAssignment.status.in_(
                            [AssignmentStatus.CONFIRMED, AssignmentStatus.PENDING]
                        ),
                    )
                )
            )
            total_assignments = total_assignments_result.scalar_one() or 0

            # Calculate days since last assignment
            days_since_last = None
            if last_assignment_date:
                days_since_last = (event_date - last_assignment_date).days

            # Calculate score
            # Higher score = better candidate
            # Priority: never assigned > long time since last > low total count
            if days_since_last is None:
                # Never assigned - highest priority
                score = 10000.0 - total_assignments
            else:
                # Recently assigned get lower scores
                # Weight days_since_last heavily (10x) vs total count
                score = (days_since_last * 10.0) - total_assignments

            suggestion = Suggestion(
                user_id=member.user_id,
                user_name=member.user.name,
                score=score,
                last_assignment_date=last_assignment_date,
                total_assignments=total_assignments,
                days_since_last=days_since_last,
            )
            suggestions.append(suggestion)

        # Sort by score (descending) and return top N
        # For ties, sort alphabetically by name for deterministic results
        suggestions.sort(key=lambda s: (-s.score, s.user_name))
        return suggestions[:limit]

    async def auto_assign_roster(
        self, roster_id: uuid.UUID, team_id: uuid.UUID
    ) -> list[dict]:
        """Auto-assign volunteers to all unfilled events in a roster using round-robin.

        This method:
        1. Gets all unfilled events in the roster (sorted by date)
        2. Gets a prioritized list of team members (never assigned first, then by recency)
        3. Uses round-robin to distribute assignments fairly across events
        4. Creates PENDING assignments in the database
        5. Respects the slots_needed for each event

        Args:
            roster_id: The roster to auto-assign
            team_id: The team to assign members from

        Returns:
            List of assignment dicts created: [{event_id, user_id, user_name, event_date}]
        """
        from app.models.roster import Roster

        # Get the roster
        roster_result = await self.db.execute(
            select(Roster).where(Roster.id == roster_id)
        )
        roster = roster_result.scalar_one_or_none()
        if not roster:
            return []

        # Get all unfilled events in this roster (not cancelled, sorted by date)
        events_result = await self.db.execute(
            select(RosterEvent)
            .options(
                selectinload(RosterEvent.event_assignments),
                selectinload(RosterEvent.roster),
            )
            .where(
                and_(
                    RosterEvent.roster_id == roster_id,
                    RosterEvent.is_cancelled == False,  # noqa: E712
                )
            )
            .order_by(RosterEvent.date)
        )
        events = list(events_result.scalars().all())

        # Filter to only events that need more volunteers
        unfilled_events = []
        for event in events:
            filled_slots = sum(
                1
                for a in event.event_assignments
                if a.status in [AssignmentStatus.CONFIRMED, AssignmentStatus.PENDING]
            )
            if filled_slots < event.roster.slots_needed:
                unfilled_events.append(
                    {
                        "event": event,
                        "filled_slots": filled_slots,
                        "slots_to_fill": event.roster.slots_needed - filled_slots,
                    }
                )

        if not unfilled_events:
            return []

        # Get all team members
        members_result = await self.db.execute(
            select(TeamMember)
            .options(selectinload(TeamMember.user))
            .where(TeamMember.team_id == team_id)
        )
        members = [m for m in members_result.scalars().all() if m.user]

        if not members:
            return []

        # Get all events in this team for scoring
        team_event_ids_result = await self.db.execute(
            select(RosterEvent.id)
            .join(RosterEvent.roster)
            .where(RosterEvent.roster.has(team_id=team_id))
        )
        team_event_ids = [row[0] for row in team_event_ids_result.all()]

        # Calculate a single prioritized list of members
        # This list will be used round-robin style for all events
        member_scores = []
        for member in members:
            # Get last assignment date (only past events)
            last_assignment_result = await self.db.execute(
                select(RosterEvent.date)
                .join(EventAssignment)
                .where(
                    and_(
                        EventAssignment.user_id == member.user_id,
                        EventAssignment.event_id.in_(team_event_ids),
                        EventAssignment.status.in_(
                            [AssignmentStatus.CONFIRMED, AssignmentStatus.PENDING]
                        ),
                        RosterEvent.date <= date.today(),  # Only past events
                    )
                )
                .order_by(RosterEvent.date.desc())
                .limit(1)
            )
            last_assignment_date = last_assignment_result.scalar_one_or_none()

            # Count total assignments
            total_assignments_result = await self.db.execute(
                select(func.count(EventAssignment.id)).where(
                    and_(
                        EventAssignment.user_id == member.user_id,
                        EventAssignment.event_id.in_(team_event_ids),
                        EventAssignment.status.in_(
                            [AssignmentStatus.CONFIRMED, AssignmentStatus.PENDING]
                        ),
                    )
                )
            )
            total_assignments = total_assignments_result.scalar_one() or 0

            # Calculate score (same algorithm as get_suggestions)
            if last_assignment_date is None:
                score = 10000.0 - total_assignments
            else:
                days_since_last = (date.today() - last_assignment_date).days
                score = (days_since_last * 10.0) - total_assignments

            member_scores.append(
                {
                    "member": member,
                    "score": score,
                }
            )

        # Sort members by score (highest first), then by name for deterministic order
        member_scores.sort(key=lambda m: (-m["score"], m["member"].user.name))
        sorted_members = [m["member"] for m in member_scores]

        # Get unavailability for all dates in the roster
        event_dates = [e["event"].date for e in unfilled_events]
        unavailability_result = await self.db.execute(
            select(Unavailability).where(
                and_(
                    Unavailability.date.in_(event_dates),
                    Unavailability.user_id.in_([m.user_id for m in sorted_members]),
                )
            )
        )
        unavailability_records = unavailability_result.scalars().all()

        # Build a set of (user_id, date) tuples for quick lookup
        unavailable_set = {(u.user_id, u.date) for u in unavailability_records}

        # Round-robin assignment
        assignments_created = []
        member_index = 0

        for event_info in unfilled_events:
            event = event_info["event"]
            slots_to_fill = event_info["slots_to_fill"]
            event_date = event.date

            # Get users already assigned to this event
            already_assigned = {
                a.user_id
                for a in event.event_assignments
                if a.status in [AssignmentStatus.CONFIRMED, AssignmentStatus.PENDING]
            }

            filled_count = 0
            attempts = 0
            max_attempts = len(sorted_members) * 2  # Avoid infinite loop

            while filled_count < slots_to_fill and attempts < max_attempts:
                member = sorted_members[member_index % len(sorted_members)]
                member_index += 1
                attempts += 1

                # Skip if already assigned to this event
                if member.user_id in already_assigned:
                    continue

                # Skip if unavailable for this date
                if (member.user_id, event_date) in unavailable_set:
                    continue

                # Create assignment
                assignment = EventAssignment(
                    event_id=event.id,
                    user_id=member.user_id,
                    status=AssignmentStatus.PENDING,
                )
                self.db.add(assignment)
                await self.db.flush()
                already_assigned.add(member.user_id)
                filled_count += 1

                assignments_created.append(
                    {
                        "assignment_id": str(assignment.id),
                        "event_id": str(event.id),
                        "user_id": str(member.user_id),
                        "user_name": member.user.name,
                        "event_date": event_date.isoformat(),
                    }
                )

        # Commit all assignments
        await self.db.commit()

        return assignments_created
