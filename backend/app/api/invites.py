import uuid

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUser, DbSession
from app.schemas.invite import (
    InviteAccept,
    InviteAcceptResponse,
    InviteCreate,
    InviteResponse,
    InviteValidation,
    PendingInviteResponse,
)
from app.services.invite import InviteService
from app.services.team import TeamService
from app.services.email import get_email_service

router = APIRouter(prefix="/invites", tags=["invites"])


@router.get("/my-pending", response_model=list[PendingInviteResponse])
async def list_my_pending_invites(
    current_user: CurrentUser,
    db: DbSession,
) -> list[PendingInviteResponse]:
    """List pending invites for the current user (by their email)."""
    if not current_user.email:
        return []

    invite_service = InviteService(db)
    pending = await invite_service.check_pending_invites_for_email(current_user.email)

    return [
        PendingInviteResponse(
            id=invite.id,
            team_id=invite.team_id,
            team_name=invite.team.name if invite.team else "Unknown team",
            email=invite.email,
            created_at=invite.created_at,
        )
        for invite in pending
    ]


@router.post(
    "/accept-team/{team_id}",
    response_model=InviteAcceptResponse,
)
async def accept_invite_by_team(
    team_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> InviteAcceptResponse:
    """Accept a pending invite for a team. For logged-in users who were invited."""
    if not current_user.email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No email associated with your account",
        )

    invite_service = InviteService(db)
    invite = await invite_service.get_pending_invite_for_email_and_team(
        email=current_user.email,
        team_id=team_id,
    )

    if not invite:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No pending invite found for this team",
        )

    from datetime import datetime, timezone

    invite.accepted_at = datetime.now(timezone.utc)

    # Ensure user has org membership
    from app.models.organisation import OrganisationMember, OrganisationRole
    from app.services.organisation import OrganisationService

    team_service = TeamService(db)
    org_service = OrganisationService(db)
    team = await team_service.get_team(team_id)

    if team:
        existing_org_membership = await org_service.get_membership(
            current_user.id, team.organisation_id
        )
        if not existing_org_membership:
            org_member = OrganisationMember(
                user_id=current_user.id,
                organisation_id=team.organisation_id,
                role=OrganisationRole.MEMBER,
            )
            db.add(org_member)

    # Send team_joined notifications
    from app.services.notification import NotificationService

    notification_service = NotificationService(db)
    team_lead_ids = await team_service.get_team_lead_ids(team_id)

    await notification_service.notify_team_joined(
        user_id=current_user.id,
        team_id=team_id,
        team_name=team.name if team else "the team",
        team_lead_ids=team_lead_ids,
        user_name=current_user.name,
    )

    await db.flush()

    return InviteAcceptResponse(
        success=True,
        message=f"Successfully joined {team.name}"
        if team
        else "Successfully joined the team",
        user_id=current_user.id,
        team_id=team_id,
        team_name=team.name if team else None,
    )


@router.post(
    "/team/{team_id}/user/{user_id}",
    response_model=InviteResponse,
    status_code=status.HTTP_201_CREATED,
)
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

    # Look up the placeholder user
    from sqlalchemy import select
    from app.models.user import User

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    # Check if the invite email belongs to an already-registered user
    registered_result = await db.execute(
        select(User).where(
            User.email == data.email,
            User.is_placeholder.is_(False),
        )
    )
    registered_user = registered_result.scalar_one_or_none()

    if registered_user and not user.is_placeholder:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is already registered and a member",
        )

    if registered_user:
        # Invite email matches an existing registered user.
        # Merge the placeholder into the registered user, send notification,
        # and auto-accept the invite.
        from datetime import datetime, timezone
        from app.models.invite import Invite as InviteModel
        from app.services.notification import NotificationService

        # Merge placeholder into registered user (transfers memberships, assignments)
        await team_service.merge_placeholder_into_user(
            placeholder_id=user_id,
            registered_user=registered_user,
        )

        # Create invite record pointing to the registered user (already merged)
        invite = InviteModel(
            team_id=team_id,
            user_id=registered_user.id,
            email=data.email,
            accepted_at=datetime.now(timezone.utc),
        )
        db.add(invite)
        await db.flush()
        await db.refresh(invite)

        # Send notification to the registered user
        notification_service = NotificationService(db)
        await notification_service.notify_team_invite(
            user_id=registered_user.id,
            team_name=team.name,
            team_id=team_id,
        )

        # Send invite email so they know
        email_service = get_email_service()
        await email_service.send_invite_email(
            to_email=data.email,
            invitee_name=registered_user.name,
            team_name=team.name,
            inviter_name=current_user.name,
            token=invite.token,
        )

        return InviteResponse.model_validate(invite)

    if not user.is_placeholder:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is not a placeholder and does not need an invite",
        )

    # Normal placeholder invite flow
    invite = await invite_service.create_invite(
        team_id=team_id,
        user_id=user_id,
        email=data.email,
    )

    # Send invite email
    email_service = get_email_service()
    await email_service.send_invite_email(
        to_email=data.email,
        invitee_name=user.name,
        team_name=team.name,
        inviter_name=current_user.name,
        token=invite.token,
    )

    # Send in-app + push notification (useful once user accepts invite)
    try:
        from app.services.notification import NotificationService

        notification_service = NotificationService(db)
        await notification_service.notify_team_invite(
            user_id=user_id,
            team_name=team.name,
            team_id=team_id,
        )
    except Exception:
        pass

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
    """Accept an invite. Password required for new users, optional for registered users."""
    invite_service = InviteService(db)
    (
        success,
        message,
        user,
        access_token,
        team_id,
        team_name,
    ) = await invite_service.accept_invite(
        token=token,
        password=data.password,
    )

    return InviteAcceptResponse(
        success=success,
        message=message,
        user_id=user.id if user else None,
        access_token=access_token,
        team_id=team_id,
        team_name=team_name,
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

    # Get user info for the email
    from app.models.user import User

    result = await db.execute(select(User).where(User.id == invite.user_id))
    user = result.scalar_one_or_none()

    # Send invite email with new token
    if user:
        email_service = get_email_service()
        await email_service.send_invite_email(
            to_email=updated_invite.email,
            invitee_name=user.name,
            team_name=team.name,
            inviter_name=current_user.name,
            token=updated_invite.token,
        )

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
