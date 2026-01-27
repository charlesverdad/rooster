import uuid
from datetime import date

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUser, DbSession
from app.core.permissions import TeamPermission
from app.schemas.team import (
    AddPlaceholderMemberRequest,
    AddTeamMemberRequest,
    TeamCreate,
    TeamMemberResponse,
    TeamResponse,
    TeamUpdate,
    TeamWithRole,
    UpdateMemberPermissionsRequest,
)
from app.schemas.roster import EventAssignmentResponse
from app.services.organisation import OrganisationService
from app.services.roster import RosterService
from app.services.team import TeamService

router = APIRouter(prefix="/teams", tags=["teams"])


@router.post("", response_model=TeamResponse, status_code=status.HTTP_201_CREATED)
async def create_team(
    data: TeamCreate,
    current_user: CurrentUser,
    db: DbSession,
) -> TeamResponse:
    """Create a new team.

    Any authenticated user can create a team. If no organisation_id is provided,
    the user's default organisation is used (created automatically if needed).
    The creator becomes the team lead with all permissions.
    """
    org_service = OrganisationService(db)
    team_service = TeamService(db)

    # Get or create the organisation
    if data.organisation_id:
        # If org specified, check that user is a member (not necessarily admin for MVP)
        org = await org_service.get_organisation(data.organisation_id)
        if not org:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organisation not found",
            )
        membership = await org_service.get_membership(
            current_user.id, data.organisation_id
        )
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You must be a member of the organisation to create teams",
            )
        org_id = data.organisation_id
    else:
        # Use or create the user's default organisation
        org = await org_service.get_or_create_default(current_user.id)
        org_id = org.id

    # Create the team with the resolved org_id
    team_data = TeamCreate(name=data.name, organisation_id=org_id)
    team = await team_service.create_team(team_data, current_user.id)
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
            permissions=permissions or [],
            created_at=team.created_at,
        )
        for team, role, permissions in teams
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


@router.get("/{team_id}", response_model=TeamWithRole)
async def get_team(
    team_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> TeamWithRole:
    """Get a team by ID with the current user's role and permissions."""
    team_service = TeamService(db)
    org_service = OrganisationService(db)

    team = await team_service.get_team(team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    # Check org membership
    org_membership = await org_service.get_membership(
        current_user.id, team.organisation_id
    )
    if not org_membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a member of this organisation",
        )

    # Get user's team membership for role and permissions
    team_membership = await team_service.get_team_membership(current_user.id, team_id)

    return TeamWithRole(
        id=team.id,
        name=team.name,
        organisation_id=team.organisation_id,
        role=team_membership.role if team_membership else None,
        permissions=team_membership.permissions if team_membership else [],
        created_at=team.created_at,
    )


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
    invite_status = await team_service.get_member_invite_status(members, team_id)

    return [
        TeamMemberResponse(
            user_id=m.user_id,
            team_id=m.team_id,
            role=m.role,
            permissions=m.permissions or [],
            user_email=m.user.email,
            user_name=m.user.name,
            is_placeholder=m.user.is_placeholder,
            is_invited=invite_status.get(m.user_id, False),
        )
        for m in members
    ]


@router.get(
    "/{team_id}/members/{user_id}/assignments",
    response_model=list[EventAssignmentResponse],
)
async def list_member_assignments(
    team_id: uuid.UUID,
    user_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
    start_date: date | None = None,
    end_date: date | None = None,
) -> list[EventAssignmentResponse]:
    """List event assignments for a specific team member. Requires view_responses permission."""
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

    await team_service.require_permission(
        current_user.id, team_id, TeamPermission.VIEW_RESPONSES
    )

    member = await team_service.get_team_membership(user_id, team_id)
    if not member:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Member not found",
        )

    assignments = await roster_service.get_user_event_assignments(
        user_id, start_date, end_date
    )

    responses: list[EventAssignmentResponse] = []
    for assignment in assignments:
        event = assignment.event
        roster = event.roster if event else None
        if not roster or roster.team_id != team_id:
            continue

        user = assignment.user
        is_invited = False
        if user and user.is_placeholder:
            is_invited = await team_service.has_active_invite(user.id, team_id)

        responses.append(
            EventAssignmentResponse(
                id=assignment.id,
                event_id=assignment.event_id,
                user_id=assignment.user_id,
                status=assignment.status,
                user_name=user.name if user else None,
                user_email=user.email if user else None,
                is_placeholder=user.is_placeholder if user else False,
                is_invited=is_invited,
                created_at=assignment.created_at,
                event_date=event.date if event else None,
                roster_name=roster.name if roster else None,
                team_name=team.name,
            )
        )

    return responses


@router.post(
    "/{team_id}/members",
    response_model=TeamMemberResponse,
    status_code=status.HTTP_201_CREATED,
)
async def add_member(
    team_id: uuid.UUID,
    data: AddTeamMemberRequest,
    current_user: CurrentUser,
    db: DbSession,
) -> TeamMemberResponse:
    """Add an existing user to a team. Org admin or team lead only."""
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

    membership = await team_service.add_member(
        team_id, data.user_id, data.role, data.permissions
    )
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    # Reload with user info
    members = await team_service.get_members(team_id)
    invite_status = await team_service.get_member_invite_status(members, team_id)
    for m in members:
        if m.user_id == data.user_id:
            return TeamMemberResponse(
                user_id=m.user_id,
                team_id=m.team_id,
                role=m.role,
                permissions=m.permissions or [],
                user_email=m.user.email,
                user_name=m.user.name,
                is_placeholder=m.user.is_placeholder,
                is_invited=invite_status.get(m.user_id, False),
            )

    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)


@router.post(
    "/{team_id}/members/placeholder",
    response_model=TeamMemberResponse,
    status_code=status.HTTP_201_CREATED,
)
async def add_placeholder_member(
    team_id: uuid.UUID,
    data: AddPlaceholderMemberRequest,
    current_user: CurrentUser,
    db: DbSession,
) -> TeamMemberResponse:
    """Add a placeholder member to a team (name only). Org admin or team lead only."""
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

    membership = await team_service.create_placeholder_member(
        team_id=team_id,
        name=data.name,
        role=data.role,
        created_by_id=current_user.id,
    )

    return TeamMemberResponse(
        user_id=membership.user_id,
        team_id=membership.team_id,
        role=membership.role,
        permissions=membership.permissions or [],
        user_email=membership.user.email,
        user_name=membership.user.name,
        is_placeholder=membership.user.is_placeholder,
        is_invited=False,  # New placeholder, no invite yet
    )


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


@router.patch(
    "/{team_id}/members/{user_id}/permissions", response_model=TeamMemberResponse
)
async def update_member_permissions(
    team_id: uuid.UUID,
    user_id: uuid.UUID,
    data: UpdateMemberPermissionsRequest,
    current_user: CurrentUser,
    db: DbSession,
) -> TeamMemberResponse:
    """Update a team member's permissions. Requires manage_members permission."""
    team_service = TeamService(db)

    team = await team_service.get_team(team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found",
        )

    # Check if current user has permission to manage members
    await team_service.require_permission(
        current_user.id, team_id, TeamPermission.MANAGE_MEMBERS
    )

    # Prevent removing the last manage_members permission
    if TeamPermission.MANAGE_MEMBERS not in data.permissions:
        count = await team_service.count_members_with_permission(
            team_id, TeamPermission.MANAGE_MEMBERS
        )
        target_membership = await team_service.get_team_membership(user_id, team_id)
        if (
            target_membership
            and target_membership.has_permission(TeamPermission.MANAGE_MEMBERS)
            and count <= 1
        ):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot remove the last member with manage_members permission",
            )

    membership = await team_service.update_member_permissions(
        team_id, user_id, data.permissions
    )
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Member not found",
        )

    # Reload with user info
    members = await team_service.get_members(team_id)
    invite_status = await team_service.get_member_invite_status(members, team_id)
    for m in members:
        if m.user_id == user_id:
            return TeamMemberResponse(
                user_id=m.user_id,
                team_id=m.team_id,
                role=m.role,
                permissions=m.permissions or [],
                user_email=m.user.email,
                user_name=m.user.name,
                is_placeholder=m.user.is_placeholder,
                is_invited=invite_status.get(m.user_id, False),
            )

    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)
