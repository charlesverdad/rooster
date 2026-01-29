import uuid
from datetime import date

from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import CurrentUser, DbSession
from app.models.roster import AssignmentStatus
from app.schemas.roster import (
    AssignmentCreate,
    AssignmentResponse,
    AssignmentUpdate,
    CoVolunteerInfo,
    EventAssignmentCreate,
    EventAssignmentDetailResponse,
    EventAssignmentResponse,
    EventAssignmentSummary,
    EventAssignmentUpdate,
    RosterCreate,
    RosterEventResponse,
    RosterEventUpdate,
    RosterResponse,
    RosterUpdate,
    SuggestionResponse,
    SuggestionsResponse,
    TeamLeadInfo,
)
from app.services.organisation import OrganisationService
from app.services.roster import RosterService
from app.services.suggestion import SuggestionService
from app.services.team import TeamService

router = APIRouter(prefix="/rosters", tags=["rosters"])


def _build_assignment_summaries(event) -> list[EventAssignmentSummary]:
    """Build assignment summary list from an event's assignments."""
    return [
        EventAssignmentSummary(
            id=a.id,
            user_id=a.user_id,
            user_name=a.user.name if a.user else None,
            status=a.status,
            is_placeholder=a.user.is_placeholder if a.user else False,
        )
        for a in event.event_assignments
    ]


@router.post("", response_model=RosterResponse, status_code=status.HTTP_201_CREATED)
async def create_roster(
    data: RosterCreate,
    current_user: CurrentUser,
    db: DbSession,
) -> RosterResponse:
    """Create a new roster. Org admin or team lead only."""
    team_service = TeamService(db)
    roster_service = RosterService(db)

    team = await team_service.get_team(data.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    if not await team_service.can_manage_team(current_user.id, team):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create rosters for this team",
        )

    roster = await roster_service.create_roster(data)
    return RosterResponse.model_validate(roster)


@router.get("/team/{team_id}", response_model=list[RosterResponse])
async def list_team_rosters(
    team_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> list[RosterResponse]:
    """List all rosters for a team. Must be org member."""
    team_service = TeamService(db)
    org_service = OrganisationService(db)
    roster_service = RosterService(db)

    team = await team_service.get_team(team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    # Check org membership
    membership = await org_service.get_membership(current_user.id, team.organisation_id)
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a member of this organisation",
        )

    rosters = await roster_service.get_team_rosters(team_id)
    return [RosterResponse.model_validate(r) for r in rosters]


@router.get("/{roster_id}", response_model=RosterResponse)
async def get_roster(
    roster_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> RosterResponse:
    """Get a roster by ID. Must be org member."""
    roster_service = RosterService(db)
    team_service = TeamService(db)
    org_service = OrganisationService(db)

    roster = await roster_service.get_roster(roster_id)
    if not roster:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Roster not found",
        )

    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    # Check org membership
    membership = await org_service.get_membership(current_user.id, team.organisation_id)
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a member of this organisation",
        )

    return RosterResponse.model_validate(roster)


@router.patch("/{roster_id}", response_model=RosterResponse)
async def update_roster(
    roster_id: uuid.UUID,
    data: RosterUpdate,
    current_user: CurrentUser,
    db: DbSession,
) -> RosterResponse:
    """Update a roster. Org admin or team lead only."""
    roster_service = RosterService(db)
    team_service = TeamService(db)

    roster = await roster_service.get_roster(roster_id)
    if not roster:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Roster not found",
        )

    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    if not await team_service.can_manage_team(current_user.id, team):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this roster",
        )

    updated = await roster_service.update_roster(roster_id, data)
    return RosterResponse.model_validate(updated)


@router.delete("/{roster_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_roster(
    roster_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> None:
    """Delete a roster. Org admin or team lead only."""
    roster_service = RosterService(db)
    team_service = TeamService(db)

    roster = await roster_service.get_roster(roster_id)
    if not roster:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Roster not found",
        )

    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    if not await team_service.can_manage_team(current_user.id, team):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this roster",
        )

    await roster_service.delete_roster(roster_id)


# Assignments


@router.post(
    "/assignments",
    response_model=AssignmentResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_assignment(
    data: AssignmentCreate,
    current_user: CurrentUser,
    db: DbSession,
) -> AssignmentResponse:
    """Create a new assignment. Org admin or team lead only."""
    roster_service = RosterService(db)
    team_service = TeamService(db)

    roster = await roster_service.get_roster(data.roster_id)
    if not roster:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Roster not found",
        )

    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    if not await team_service.can_manage_team(current_user.id, team):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create assignments for this roster",
        )

    assignment = await roster_service.create_assignment(data)
    return AssignmentResponse(
        id=assignment.id,
        roster_id=assignment.roster_id,
        user_id=assignment.user_id,
        date=assignment.date,
        status=assignment.status,
        created_at=assignment.created_at,
    )


@router.get("/assignments/my", response_model=list[AssignmentResponse])
async def list_my_assignments(
    current_user: CurrentUser,
    db: DbSession,
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
) -> list[AssignmentResponse]:
    """List all assignments for the current user."""
    roster_service = RosterService(db)
    assignments = await roster_service.get_user_assignments(
        current_user.id, start_date, end_date
    )
    return [
        AssignmentResponse(
            id=a.id,
            roster_id=a.roster_id,
            user_id=a.user_id,
            date=a.date,
            status=a.status,
            created_at=a.created_at,
            roster_name=a.roster.name if a.roster else None,
        )
        for a in assignments
    ]


@router.get("/{roster_id}/assignments", response_model=list[AssignmentResponse])
async def list_roster_assignments(
    roster_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
) -> list[AssignmentResponse]:
    """List assignments for a roster. Must be org member."""
    roster_service = RosterService(db)
    team_service = TeamService(db)
    org_service = OrganisationService(db)

    roster = await roster_service.get_roster(roster_id)
    if not roster:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Roster not found",
        )

    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    # Check org membership
    membership = await org_service.get_membership(current_user.id, team.organisation_id)
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a member of this organisation",
        )

    assignments = await roster_service.get_roster_assignments(
        roster_id, start_date, end_date
    )
    return [
        AssignmentResponse(
            id=a.id,
            roster_id=a.roster_id,
            user_id=a.user_id,
            date=a.date,
            status=a.status,
            created_at=a.created_at,
            user_name=a.user.name if a.user else None,
            user_email=a.user.email if a.user else None,
        )
        for a in assignments
    ]


@router.patch("/assignments/{assignment_id}", response_model=AssignmentResponse)
async def update_assignment(
    assignment_id: uuid.UUID,
    data: AssignmentUpdate,
    current_user: CurrentUser,
    db: DbSession,
) -> AssignmentResponse:
    """Update an assignment status. User can update their own, leads can update any."""
    roster_service = RosterService(db)
    team_service = TeamService(db)

    assignment = await roster_service.get_assignment(assignment_id)
    if not assignment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Assignment not found",
        )

    roster = await roster_service.get_roster(assignment.roster_id)
    if not roster:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Roster not found",
        )

    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    # User can update their own assignment status, or leads can update any
    is_own = assignment.user_id == current_user.id
    can_manage = await team_service.can_manage_team(current_user.id, team)

    if not is_own and not can_manage:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this assignment",
        )

    if data.status:
        updated = await roster_service.update_assignment_status(
            assignment_id, data.status
        )
        if updated:
            return AssignmentResponse(
                id=updated.id,
                roster_id=updated.roster_id,
                user_id=updated.user_id,
                date=updated.date,
                status=updated.status,
                created_at=updated.created_at,
            )

    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST, detail="No update provided"
    )


@router.delete("/assignments/{assignment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_assignment(
    assignment_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> None:
    """Delete an assignment. Org admin or team lead only."""
    roster_service = RosterService(db)
    team_service = TeamService(db)

    assignment = await roster_service.get_assignment(assignment_id)
    if not assignment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Assignment not found",
        )

    roster = await roster_service.get_roster(assignment.roster_id)
    if not roster:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Roster not found",
        )

    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    if not await team_service.can_manage_team(current_user.id, team):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this assignment",
        )

    await roster_service.delete_assignment(assignment_id)


# Roster Events


@router.get("/{roster_id}/events", response_model=list[RosterEventResponse])
async def list_roster_events(
    roster_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
    include_cancelled: bool = Query(False),
) -> list[RosterEventResponse]:
    """List events for a roster. Must be org member."""
    roster_service = RosterService(db)
    team_service = TeamService(db)
    org_service = OrganisationService(db)

    roster = await roster_service.get_roster(roster_id)
    if not roster:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Roster not found",
        )

    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    # Check org membership
    membership = await org_service.get_membership(current_user.id, team.organisation_id)
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a member of this organisation",
        )

    events = await roster_service.get_roster_events(
        roster_id, start_date, end_date, include_cancelled
    )

    return [
        RosterEventResponse(
            id=e.id,
            roster_id=e.roster_id,
            date=e.date,
            notes=e.notes,
            is_cancelled=e.is_cancelled,
            roster_name=roster.name,
            team_id=roster.team_id,
            slots_needed=roster.slots_needed,
            filled_slots=len(
                [a for a in e.event_assignments if a.status.value == "confirmed"]
            ),
            assignments=_build_assignment_summaries(e),
            created_at=e.created_at,
        )
        for e in events
    ]


@router.get("/events/team/{team_id}", response_model=list[RosterEventResponse])
async def list_team_events(
    team_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
    include_cancelled: bool = Query(False),
) -> list[RosterEventResponse]:
    """List all events for a team. Must be org member."""
    roster_service = RosterService(db)
    team_service = TeamService(db)
    org_service = OrganisationService(db)

    team = await team_service.get_team(team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    # Check org membership
    membership = await org_service.get_membership(current_user.id, team.organisation_id)
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a member of this organisation",
        )

    events = await roster_service.get_team_events(
        team_id, start_date, end_date, include_cancelled
    )

    return [
        RosterEventResponse(
            id=e.id,
            roster_id=e.roster_id,
            date=e.date,
            notes=e.notes,
            is_cancelled=e.is_cancelled,
            roster_name=e.roster.name if e.roster else None,
            team_id=team_id,
            slots_needed=e.roster.slots_needed if e.roster else None,
            filled_slots=len(
                [a for a in e.event_assignments if a.status.value == "confirmed"]
            ),
            assignments=_build_assignment_summaries(e),
            created_at=e.created_at,
        )
        for e in events
    ]


@router.get("/events/team/{team_id}/unfilled", response_model=list[RosterEventResponse])
async def list_unfilled_events(
    team_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
) -> list[RosterEventResponse]:
    """List events that need more volunteers. Must be team lead."""
    roster_service = RosterService(db)
    team_service = TeamService(db)

    team = await team_service.get_team(team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    if not await team_service.can_manage_team(current_user.id, team):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view unfilled events",
        )

    events = await roster_service.get_unfilled_events(team_id, start_date, end_date)

    return [
        RosterEventResponse(
            id=e.id,
            roster_id=e.roster_id,
            date=e.date,
            notes=e.notes,
            is_cancelled=e.is_cancelled,
            roster_name=e.roster.name if e.roster else None,
            team_id=team_id,
            slots_needed=e.roster.slots_needed if e.roster else None,
            filled_slots=len(
                [a for a in e.event_assignments if a.status.value == "confirmed"]
            ),
            assignments=_build_assignment_summaries(e),
            created_at=e.created_at,
        )
        for e in events
    ]


@router.get("/events/{event_id}", response_model=RosterEventResponse)
async def get_roster_event(
    event_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> RosterEventResponse:
    """Get a roster event by ID. Must be org member."""
    roster_service = RosterService(db)
    team_service = TeamService(db)
    org_service = OrganisationService(db)

    event = await roster_service.get_event(event_id)
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event not found",
        )

    roster = event.roster
    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    # Check org membership
    membership = await org_service.get_membership(current_user.id, team.organisation_id)
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a member of this organisation",
        )

    return RosterEventResponse(
        id=event.id,
        roster_id=event.roster_id,
        date=event.date,
        notes=event.notes,
        is_cancelled=event.is_cancelled,
        roster_name=roster.name,
        team_id=roster.team_id,
        slots_needed=roster.slots_needed,
        filled_slots=len(
            [a for a in event.event_assignments if a.status.value == "confirmed"]
        ),
        assignments=_build_assignment_summaries(event),
        created_at=event.created_at,
    )


@router.get("/events/{event_id}/suggestions", response_model=SuggestionsResponse)
async def get_event_suggestions(
    event_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
    limit: int = Query(10, ge=1, le=50),
) -> SuggestionsResponse:
    """Get assignment suggestions for a roster event. Team lead only."""
    roster_service = RosterService(db)
    team_service = TeamService(db)
    suggestion_service = SuggestionService(db)

    event = await roster_service.get_event(event_id)
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event not found",
        )

    roster = event.roster
    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    # Only team leads can get suggestions
    if not await team_service.can_manage_team(current_user.id, team):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to get suggestions for this event",
        )

    suggestions = await suggestion_service.get_suggestions(
        event_id, roster.team_id, limit
    )

    return SuggestionsResponse(
        suggestions=[
            SuggestionResponse(
                user_id=s.user_id,
                user_name=s.user_name,
                score=s.score,
                reasoning=s.reasoning,
            )
            for s in suggestions
        ]
    )


@router.patch("/events/{event_id}", response_model=RosterEventResponse)
async def update_roster_event(
    event_id: uuid.UUID,
    data: RosterEventUpdate,
    current_user: CurrentUser,
    db: DbSession,
) -> RosterEventResponse:
    """Update a roster event. Org admin or team lead only."""
    roster_service = RosterService(db)
    team_service = TeamService(db)

    event = await roster_service.get_event(event_id)
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event not found",
        )

    roster = event.roster
    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    if not await team_service.can_manage_team(current_user.id, team):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this event",
        )

    updated = await roster_service.update_event(event_id, data.notes, data.is_cancelled)
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update event",
        )

    return RosterEventResponse(
        id=updated.id,
        roster_id=updated.roster_id,
        date=updated.date,
        notes=updated.notes,
        is_cancelled=updated.is_cancelled,
        roster_name=roster.name,
        team_id=roster.team_id,
        slots_needed=roster.slots_needed,
        filled_slots=len(
            [a for a in updated.event_assignments if a.status.value == "confirmed"]
        ),
        assignments=_build_assignment_summaries(updated),
        created_at=updated.created_at,
    )


@router.post("/{roster_id}/events/generate", response_model=list[RosterEventResponse])
async def generate_more_events(
    roster_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
    count: int = Query(12, ge=1, le=52),
) -> list[RosterEventResponse]:
    """Generate more events for a roster. Org admin or team lead only."""
    roster_service = RosterService(db)
    team_service = TeamService(db)

    roster = await roster_service.get_roster(roster_id)
    if not roster:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Roster not found",
        )

    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    if not await team_service.can_manage_team(current_user.id, team):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to generate events for this roster",
        )

    events = await roster_service.generate_more_events(roster_id, count)

    return [
        RosterEventResponse(
            id=e.id,
            roster_id=e.roster_id,
            date=e.date,
            notes=e.notes,
            is_cancelled=e.is_cancelled,
            roster_name=roster.name,
            team_id=roster.team_id,
            slots_needed=roster.slots_needed,
            filled_slots=0,
            created_at=e.created_at,
        )
        for e in events
    ]


# Event Assignments


@router.get(
    "/events/{event_id}/assignments", response_model=list[EventAssignmentResponse]
)
async def list_event_assignments(
    event_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> list[EventAssignmentResponse]:
    """List all assignments for a roster event. Must be org member."""
    roster_service = RosterService(db)
    team_service = TeamService(db)
    org_service = OrganisationService(db)

    event = await roster_service.get_event(event_id)
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event not found",
        )

    roster = event.roster
    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    # Check org membership
    membership = await org_service.get_membership(current_user.id, team.organisation_id)
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a member of this organisation",
        )

    assignment_data = await roster_service.get_event_assignment_with_invite_status(
        event_id
    )

    return [
        EventAssignmentResponse(
            id=d["assignment"].id,
            event_id=d["assignment"].event_id,
            user_id=d["assignment"].user_id,
            status=d["assignment"].status,
            user_name=d["assignment"].user.name if d["assignment"].user else None,
            user_email=d["assignment"].user.email if d["assignment"].user else None,
            is_placeholder=d["is_placeholder"],
            is_invited=d["is_invited"],
            created_at=d["assignment"].created_at,
        )
        for d in assignment_data
    ]


@router.post(
    "/events/{event_id}/assignments",
    response_model=EventAssignmentResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_event_assignment(
    event_id: uuid.UUID,
    data: EventAssignmentCreate,
    current_user: CurrentUser,
    db: DbSession,
) -> EventAssignmentResponse:
    """Assign a user to a roster event. Org admin or team lead only."""
    roster_service = RosterService(db)
    team_service = TeamService(db)

    event = await roster_service.get_event(event_id)
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event not found",
        )

    roster = event.roster
    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    is_self_assign = data.user_id == current_user.id
    if not is_self_assign:
        if not await team_service.can_manage_team(current_user.id, team):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to create assignments for this event",
            )

    # Verify the assigned user is a team member
    membership = await team_service.get_team_membership(data.user_id, team.id)
    if not membership:
        if is_self_assign:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not a member of this team",
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is not a member of this team",
        )

    initial_status = (
        AssignmentStatus.CONFIRMED if is_self_assign else AssignmentStatus.PENDING
    )
    assignment = await roster_service.create_event_assignment(
        event_id, data.user_id, status=initial_status
    )
    if not assignment:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is already assigned to this event or event not found",
        )

    # Get invite status
    user = membership.user
    is_invited = False
    if user.is_placeholder:
        is_invited = await team_service.has_active_invite(user.id, team.id)

    return EventAssignmentResponse(
        id=assignment.id,
        event_id=assignment.event_id,
        user_id=assignment.user_id,
        status=assignment.status,
        user_name=user.name,
        user_email=user.email,
        is_placeholder=user.is_placeholder,
        is_invited=is_invited,
        created_at=assignment.created_at,
    )


@router.get(
    "/event-assignments/{assignment_id}/detail",
    response_model=EventAssignmentDetailResponse,
)
async def get_event_assignment_detail(
    assignment_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> EventAssignmentDetailResponse:
    """Get detailed info for an event assignment including co-volunteers and team lead."""
    roster_service = RosterService(db)
    org_service = OrganisationService(db)

    detail = await roster_service.get_event_assignment_detail(assignment_id)
    if not detail:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Assignment not found",
        )

    assignment = detail["assignment"]
    event = detail["event"]
    roster = detail["roster"]

    # Check user can access (org member or it's their own assignment)
    is_own = assignment.user_id == current_user.id
    membership = await org_service.get_membership(current_user.id, roster.team_id)

    if not is_own and not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this assignment",
        )

    co_volunteers = [
        CoVolunteerInfo(
            user_id=cv["assignment"].user_id,
            name=cv["assignment"].user.name if cv["assignment"].user else "",
            status=cv["assignment"].status,
            is_placeholder=cv["is_placeholder"],
            is_invited=cv["is_invited"],
        )
        for cv in detail["co_volunteers"]
    ]

    team_lead = None
    if detail["team_lead"]:
        team_lead = TeamLeadInfo(
            user_id=detail["team_lead"]["user_id"],
            name=detail["team_lead"]["name"],
            email=detail["team_lead"]["email"],
        )

    return EventAssignmentDetailResponse(
        id=assignment.id,
        event_id=assignment.event_id,
        user_id=assignment.user_id,
        status=assignment.status,
        user_name=assignment.user.name if assignment.user else None,
        user_email=assignment.user.email if assignment.user else None,
        is_placeholder=detail["is_placeholder"],
        is_invited=detail["is_invited"],
        created_at=assignment.created_at,
        event_date=event.date,
        roster_id=roster.id,
        roster_name=roster.name,
        team_id=roster.team_id,
        team_name=detail["team_name"],
        location=roster.location,
        notes=event.notes or roster.notes,
        slots_needed=roster.slots_needed,
        co_volunteers=co_volunteers,
        team_lead=team_lead,
    )


@router.get("/event-assignments/my", response_model=list[EventAssignmentResponse])
async def list_my_event_assignments(
    current_user: CurrentUser,
    db: DbSession,
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
) -> list[EventAssignmentResponse]:
    """List all event assignments for the current user."""
    roster_service = RosterService(db)
    assignments = await roster_service.get_user_event_assignments(
        current_user.id, start_date, end_date
    )
    return [
        EventAssignmentResponse(
            id=a.id,
            event_id=a.event_id,
            user_id=a.user_id,
            status=a.status,
            user_name=a.user.name if a.user else None,
            user_email=a.user.email if a.user else None,
            is_placeholder=a.user.is_placeholder if a.user else False,
            is_invited=False,  # Current user is not a placeholder
            created_at=a.created_at,
            event_date=a.event.date if a.event else None,
            roster_name=a.event.roster.name if a.event and a.event.roster else None,
            team_name=a.event.roster.team.name
            if a.event and a.event.roster and a.event.roster.team
            else None,
            team_id=a.event.roster.team_id if a.event and a.event.roster else None,
        )
        for a in assignments
    ]


@router.patch(
    "/event-assignments/{assignment_id}", response_model=EventAssignmentResponse
)
async def update_event_assignment(
    assignment_id: uuid.UUID,
    data: EventAssignmentUpdate,
    current_user: CurrentUser,
    db: DbSession,
) -> EventAssignmentResponse:
    """Update an event assignment status. User can update their own, leads can update any."""
    roster_service = RosterService(db)
    team_service = TeamService(db)

    assignment = await roster_service.get_event_assignment(assignment_id)
    if not assignment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Assignment not found",
        )

    event = assignment.event
    roster = event.roster
    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    # User can update their own assignment status, or leads can update any
    is_own = assignment.user_id == current_user.id
    can_manage = await team_service.can_manage_team(current_user.id, team)

    if not is_own and not can_manage:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this assignment",
        )

    updated = await roster_service.update_event_assignment_status(
        assignment_id, data.status
    )
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update assignment",
        )

    # Get invite status
    user = updated.user
    is_invited = False
    if user and user.is_placeholder:
        is_invited = await team_service.has_active_invite(user.id, team.id)

    return EventAssignmentResponse(
        id=updated.id,
        event_id=updated.event_id,
        user_id=updated.user_id,
        status=updated.status,
        user_name=user.name if user else None,
        user_email=user.email if user else None,
        is_placeholder=user.is_placeholder if user else False,
        is_invited=is_invited,
        created_at=updated.created_at,
    )


@router.delete(
    "/event-assignments/{assignment_id}", status_code=status.HTTP_204_NO_CONTENT
)
async def delete_event_assignment(
    assignment_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> None:
    """Delete an event assignment. Org admin or team lead only."""
    roster_service = RosterService(db)
    team_service = TeamService(db)

    assignment = await roster_service.get_event_assignment(assignment_id)
    if not assignment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Assignment not found",
        )

    event = assignment.event
    roster = event.roster
    team = await team_service.get_team(roster.team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    if not await team_service.can_manage_team(current_user.id, team):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this assignment",
        )

    await roster_service.delete_event_assignment(assignment_id)
