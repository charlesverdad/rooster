import uuid

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUser, DbSession
from app.schemas.invite import (
    InviteAccept,
    InviteAcceptResponse,
    InviteCreate,
    InviteResponse,
    InviteValidation,
)
from app.services.invite import InviteService
from app.services.team import TeamService

router = APIRouter(prefix="/invites", tags=["invites"])


@router.post("/team/{team_id}/user/{user_id}", response_model=InviteResponse, status_code=status.HTTP_201_CREATED)
async def send_invite(
    team_id: uuid.UUID,
    user_id: uuid.UUID,
    data: InviteCreate,
    current_user: CurrentUser,
    db: DbSession,
) -> InviteResponse:
    """Send an invite to a placeholder user. Must be team lead or org admin."""
    team_service = TeamService(db)
    invite_service = InviteService(db)

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

    # Check if user is a member of the team
    membership = await team_service.get_team_membership(user_id, team_id)
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User is not a member of this team",
        )

    # Check if user is a placeholder
    from sqlalchemy import select
    from app.models.user import User
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    if not user.is_placeholder:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is not a placeholder and does not need an invite",
        )

    invite = await invite_service.create_invite(
        team_id=team_id,
        user_id=user_id,
        email=data.email,
    )

    # TODO: Send email with invite link
    # For now, just return the invite with token

    return InviteResponse.model_validate(invite)


@router.get("/validate/{token}", response_model=InviteValidation)
async def validate_invite_token(
    token: str,
    db: DbSession,
) -> InviteValidation:
    """Validate an invite token. No authentication required."""
    invite_service = InviteService(db)
    validation = await invite_service.validate_token(token)
    return InviteValidation(**validation)


@router.post("/accept/{token}", response_model=InviteAcceptResponse)
async def accept_invite(
    token: str,
    data: InviteAccept,
    db: DbSession,
) -> InviteAcceptResponse:
    """Accept an invite by setting a password. No authentication required."""
    invite_service = InviteService(db)
    success, message, user, access_token = await invite_service.accept_invite(
        token=token,
        password=data.password,
    )

    return InviteAcceptResponse(
        success=success,
        message=message,
        user_id=user.id if user else None,
        access_token=access_token,
    )


@router.post("/{invite_id}/resend", response_model=InviteResponse)
async def resend_invite(
    invite_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> InviteResponse:
    """Resend an invite with a new token. Must be team lead or org admin."""
    invite_service = InviteService(db)
    team_service = TeamService(db)

    # Get the invite first to check permissions
    from sqlalchemy import select
    from app.models.invite import Invite
    result = await db.execute(select(Invite).where(Invite.id == invite_id))
    invite = result.scalar_one_or_none()

    if not invite:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invite not found",
        )

    team = await team_service.get_team(invite.team_id)
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

    updated_invite = await invite_service.resend_invite(invite_id)
    if not updated_invite:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot resend invite - already accepted or not found",
        )

    # TODO: Send email with new invite link

    return InviteResponse.model_validate(updated_invite)


@router.get("/team/{team_id}", response_model=list[InviteResponse])
async def list_team_invites(
    team_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> list[InviteResponse]:
    """List all invites for a team. Must be team lead or org admin."""
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
            detail="Not authorized to view team invites",
        )

    # Get all invites for the team
    from sqlalchemy import select
    from sqlalchemy.orm import selectinload
    from app.models.invite import Invite
    result = await db.execute(
        select(Invite)
        .options(selectinload(Invite.team), selectinload(Invite.user))
        .where(Invite.team_id == team_id)
        .order_by(Invite.created_at.desc())
    )
    invites = result.scalars().all()

    return [InviteResponse.model_validate(i) for i in invites]
