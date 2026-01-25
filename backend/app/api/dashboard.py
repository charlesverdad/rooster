import uuid
from datetime import date, timedelta

from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import CurrentUser, DbSession
from app.schemas.dashboard import CalendarDay, TeamMemberAvailability, UpcomingAssignment
from app.services.dashboard import DashboardService
from app.services.organisation import OrganisationService
from app.services.team import TeamService

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/assignments", response_model=list[UpcomingAssignment])
async def get_upcoming_assignments(
    current_user: CurrentUser,
    db: DbSession,
    days: int = Query(30, ge=1, le=365),
) -> list[UpcomingAssignment]:
    """Get upcoming assignments for the current user."""
    service = DashboardService(db)
    return await service.get_upcoming_assignments(current_user.id, days)


@router.get("/calendar", response_model=list[CalendarDay])
async def get_calendar_view(
    current_user: CurrentUser,
    db: DbSession,
    start_date: date = Query(None),
    end_date: date = Query(None),
) -> list[CalendarDay]:
    """Get calendar view with assignments grouped by date."""
    # Default to current month if no dates provided
    if not start_date:
        today = date.today()
        start_date = today.replace(day=1)
    if not end_date:
        # Get last day of month
        if start_date.month == 12:
            end_date = start_date.replace(year=start_date.year + 1, month=1, day=1) - timedelta(days=1)
        else:
            end_date = start_date.replace(month=start_date.month + 1, day=1) - timedelta(days=1)
    
    service = DashboardService(db)
    return await service.get_calendar_view(current_user.id, start_date, end_date)


@router.get("/teams/{team_id}/availability", response_model=list[TeamMemberAvailability])
async def get_team_availability(
    team_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
    target_date: date = Query(None),
) -> list[TeamMemberAvailability]:
    """Get availability overview for team members. Team lead or org admin only."""
    if not target_date:
        target_date = date.today()
    
    team_service = TeamService(db)
    org_service = OrganisationService(db)
    dashboard_service = DashboardService(db)
    
    team = await team_service.get_team(team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )
    
    # Check if user can manage team
    if not await team_service.can_manage_team(current_user.id, team):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view team availability",
        )
    
    availability = await dashboard_service.get_team_availability_overview(team_id, target_date)
    return [TeamMemberAvailability(**a) for a in availability]
