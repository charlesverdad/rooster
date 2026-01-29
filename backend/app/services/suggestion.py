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
        parts = []

        if self.days_since_last is None:
            parts.append("Never assigned before")
        else:
            if self.days_since_last == 0:
                parts.append("Last served today")
            elif self.days_since_last == 1:
                parts.append("Last served yesterday")
            else:
                parts.append(f"Last served {self.days_since_last} days ago")

        if self.total_assignments == 0:
            parts.append("no previous assignments")
        elif self.total_assignments == 1:
            parts.append("1 previous assignment")
        else:
            parts.append(f"{self.total_assignments} previous assignments")

        return " • ".join(parts)

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
