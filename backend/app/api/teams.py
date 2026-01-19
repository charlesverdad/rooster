import uuid

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUser, DbSession
from app.schemas.team import (
    AddTeamMemberRequest,
    TeamCreate,
    TeamMemberResponse,
    TeamResponse,
    TeamUpdate,
    TeamWithRole,
)
from app.services.organisation import OrganisationService
from app.services.team import TeamService

router = APIRouter(prefix="/teams", tags=["teams"])


@router.post("", response_model=TeamResponse, status_code=status.HTTP_201_CREATED)
async def create_team(
    data: TeamCreate,
    current_user: CurrentUser,
    db: DbSession,
) -> TeamResponse:
    """Create a new team. Must be org admin."""
    org_service = OrganisationService(db)
    team_service = TeamService(db)

    # Check org membership
    if not await org_service.is_admin(current_user.id, data.organisation_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required to create teams",
        )

    team = await team_service.create_team(data, current_user.id)
    return TeamResponse.model_validate(team)


@router.get("", response_model=list[TeamWithRole])
async def list_my_teams(
    current_user: CurrentUser,
    db: DbSession,
    organisation_id: uuid.UUID | None = None,
) -> list[TeamWithRole]:
    """List all teams the current user belongs to."""
    service = TeamService(db)
    teams = await service.get_user_teams(current_user.id, organisation_id)
    return [
        TeamWithRole(
            id=team.id,
            name=team.name,
            organisation_id=team.organisation_id,
            role=role,
            created_at=team.created_at,
        )
        for team, role in teams
    ]


@router.get("/organisation/{org_id}", response_model=list[TeamResponse])
async def list_organisation_teams(
    org_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> list[TeamResponse]:
    """List all teams in an organisation. Must be org member."""
    org_service = OrganisationService(db)
    team_service = TeamService(db)

    # Check org membership
    membership = await org_service.get_membership(current_user.id, org_id)
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a member of this organisation",
        )

    teams = await team_service.get_organisation_teams(org_id)
    return [TeamResponse.model_validate(t) for t in teams]


@router.get("/{team_id}", response_model=TeamResponse)
async def get_team(
    team_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> TeamResponse:
    """Get a team by ID. Must be org member."""
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

    return TeamResponse.model_validate(team)


@router.patch("/{team_id}", response_model=TeamResponse)
async def update_team(
    team_id: uuid.UUID,
    data: TeamUpdate,
    current_user: CurrentUser,
    db: DbSession,
) -> TeamResponse:
    """Update a team. Org admin or team lead only."""
    service = TeamService(db)

    team = await service.get_team(team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    if not await service.can_manage_team(current_user.id, team):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this team",
        )

    updated = await service.update_team(team_id, data)
    return TeamResponse.model_validate(updated)


@router.delete("/{team_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_team(
    team_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> None:
    """Delete a team. Org admin only."""
    service = TeamService(db)

    team = await service.get_team(team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    if not await service.is_org_admin(current_user.id, team.organisation_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required to delete teams",
        )

    await service.delete_team(team_id)


@router.get("/{team_id}/members", response_model=list[TeamMemberResponse])
async def list_members(
    team_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> list[TeamMemberResponse]:
    """List all members of a team. Must be org member."""
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

    members = await team_service.get_members(team_id)
    return [
        TeamMemberResponse(
            user_id=m.user_id,
            team_id=m.team_id,
            role=m.role,
            user_email=m.user.email,
            user_name=m.user.name,
        )
        for m in members
    ]


@router.post("/{team_id}/members", response_model=TeamMemberResponse, status_code=status.HTTP_201_CREATED)
async def add_member(
    team_id: uuid.UUID,
    data: AddTeamMemberRequest,
    current_user: CurrentUser,
    db: DbSession,
) -> TeamMemberResponse:
    """Add a member to a team. Org admin or team lead only."""
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
            detail="Not authorized to manage this team",
        )

    membership = await team_service.add_member(team_id, data.user_id, data.role)
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    # Reload with user info
    members = await team_service.get_members(team_id)
    for m in members:
        if m.user_id == data.user_id:
            return TeamMemberResponse(
                user_id=m.user_id,
                team_id=m.team_id,
                role=m.role,
                user_email=m.user.email,
                user_name=m.user.name,
            )

    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)


@router.delete("/{team_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_member(
    team_id: uuid.UUID,
    user_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> None:
    """Remove a member from a team. Org admin or team lead only."""
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
            detail="Not authorized to manage this team",
        )

    if not await team_service.remove_member(team_id, user_id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Member not found",
        )
