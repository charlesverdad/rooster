import uuid
from datetime import date

from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import CurrentUser, DbSession
from app.schemas.roster import (
    AssignmentCreate,
    AssignmentResponse,
    AssignmentUpdate,
    RosterCreate,
    RosterResponse,
    RosterUpdate,
)
from app.services.organisation import OrganisationService
from app.services.roster import RosterService
from app.services.team import TeamService

router = APIRouter(prefix="/rosters", tags=["rosters"])


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

@router.post("/assignments", response_model=AssignmentResponse, status_code=status.HTTP_201_CREATED)
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

    raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No update provided")


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
