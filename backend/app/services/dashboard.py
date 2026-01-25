import uuid
from datetime import date, timedelta
from collections import defaultdict

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.availability import Unavailability
from app.models.roster import Assignment
from app.models.team import TeamMember
from app.schemas.dashboard import CalendarDay, UpcomingAssignment


class DashboardService:
    """Service for dashboard operations."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_upcoming_assignments(
        self, user_id: uuid.UUID, days: int = 30
    ) -> list[UpcomingAssignment]:
        """Get user's upcoming assignments for the next N days."""
        today = date.today()
        end_date = today + timedelta(days=days)

        result = await self.db.execute(
            select(Assignment)
            .options(
                selectinload(Assignment.roster)
                .selectinload(lambda r: r.team)  # type: ignore
                .selectinload(lambda t: t.organisation)  # type: ignore
            )
            .where(
                and_(
                    Assignment.user_id == user_id,
                    Assignment.date >= today,
                    Assignment.date <= end_date,
                )
            )
            .order_by(Assignment.date)
        )
        assignments = list(result.scalars().all())

        return [
            UpcomingAssignment(
                id=a.id,
                date=a.date,
                status=a.status,
                roster_name=a.roster.name if a.roster else "Unknown",
                team_name=a.roster.team.name if a.roster and a.roster.team else "Unknown",
                organisation_name=(
                    a.roster.team.organisation.name
                    if a.roster and a.roster.team and a.roster.team.organisation
                    else "Unknown"
                ),
                created_at=a.created_at,
            )
            for a in assignments
        ]

    async def get_calendar_view(
        self, user_id: uuid.UUID, start_date: date, end_date: date
    ) -> list[CalendarDay]:
        """Get calendar view with assignments grouped by date."""
        result = await self.db.execute(
            select(Assignment)
            .options(
                selectinload(Assignment.roster)
                .selectinload(lambda r: r.team)  # type: ignore
                .selectinload(lambda t: t.organisation)  # type: ignore
            )
            .where(
                and_(
                    Assignment.user_id == user_id,
                    Assignment.date >= start_date,
                    Assignment.date <= end_date,
                )
            )
            .order_by(Assignment.date)
        )
        assignments = list(result.scalars().all())

        # Group assignments by date
        assignments_by_date: dict[date, list[UpcomingAssignment]] = defaultdict(list)
        for a in assignments:
            assignments_by_date[a.date].append(
                UpcomingAssignment(
                    id=a.id,
                    date=a.date,
                    status=a.status,
                    roster_name=a.roster.name if a.roster else "Unknown",
                    team_name=a.roster.team.name if a.roster and a.roster.team else "Unknown",
                    organisation_name=(
                        a.roster.team.organisation.name
                        if a.roster and a.roster.team and a.roster.team.organisation
                        else "Unknown"
                    ),
                    created_at=a.created_at,
                )
            )

        # Create calendar days for all dates in range
        calendar_days = []
        current_date = start_date
        while current_date <= end_date:
            calendar_days.append(
                CalendarDay(
                    date=current_date,
                    assignments=assignments_by_date.get(current_date, []),
                )
            )
            current_date += timedelta(days=1)

        return calendar_days

    async def get_team_availability_overview(
        self, team_id: uuid.UUID, target_date: date
    ) -> list[dict]:
        """Get availability overview for all team members on a specific date."""
        # Get all team members
        members_result = await self.db.execute(
            select(TeamMember)
            .options(selectinload(TeamMember.user))
            .where(TeamMember.team_id == team_id)
        )
        members = list(members_result.scalars().all())

        # Check unavailability for each member
        availability_overview = []
        for member in members:
            unavail_result = await self.db.execute(
                select(Unavailability).where(
                    and_(
                        Unavailability.user_id == member.user_id,
                        Unavailability.date == target_date,
                    )
                )
            )
            unavailability = unavail_result.scalar_one_or_none()

            availability_overview.append(
                {
                    "user_id": member.user_id,
                    "user_name": member.user.name if member.user else "Unknown",
                    "user_email": member.user.email if member.user else "Unknown",
                    "is_available": unavailability is None,
                    "unavailability_reason": (
                        unavailability.reason if unavailability else None
                    ),
                }
            )

        return availability_overview
