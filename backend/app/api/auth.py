from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm

from app.api.deps import CurrentUser, DbSession
from app.schemas.organisation import OrganisationWithRole
from app.schemas.user import UserCreate, UserResponse, Token
from app.services.auth import AuthService
from app.services.organisation import OrganisationService

router = APIRouter(prefix="/auth", tags=["auth"])


async def _build_user_response(user, db, auth_service: AuthService) -> UserResponse:
    """Build a UserResponse with roles and organisations."""
    roles = await auth_service.get_user_roles(user.id)
    user_response = UserResponse.model_validate(user)
    user_response.roles = roles

    org_service = OrganisationService(db)
    orgs = await org_service.get_user_organisations(user.id)
    user_response.organisations = [
        OrganisationWithRole(
            id=org.id,
            name=org.name,
            role=role,
            is_personal=org.is_personal,
            created_at=org.created_at,
        )
        for org, role in orgs
    ]
    return user_response


@router.post(
    "/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED
)
async def register(user_data: UserCreate, db: DbSession) -> UserResponse:
    """Register a new user."""
    auth_service = AuthService(db)

    existing_user = await auth_service.get_user_by_email(user_data.email)
    if existing_user and not existing_user.is_placeholder:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    if existing_user and existing_user.is_placeholder:
        # Convert the placeholder into a full user instead of creating a duplicate
        from app.core.security import get_password_hash

        existing_user.name = user_data.name
        existing_user.password_hash = get_password_hash(user_data.password)
        existing_user.is_placeholder = False
        await db.flush()
        await db.refresh(existing_user)
        user = existing_user
    else:
        user = await auth_service.create_user(user_data)

    # Check for pending invites matching the new user's email
    from app.services.invite import InviteService
    from app.services.notification import NotificationService

    invite_service = InviteService(db)
    pending_invites = await invite_service.check_pending_invites_for_email(
        user_data.email
    )
    if pending_invites:
        notification_service = NotificationService(db)
        for invite in pending_invites:
            try:
                # Skip if a TEAM_INVITE notification already exists for this team
                # (e.g., created when the invite was originally sent to the placeholder)
                existing = await notification_service.has_notification(
                    user_id=user.id,
                    notification_type="team_invite",
                    reference_id=invite.team_id,
                )
                if not existing:
                    await notification_service.notify_team_invite(
                        user_id=user.id,
                        team_name=invite.team.name if invite.team else "a team",
                        team_id=invite.team_id,
                    )
            except Exception:
                pass

    return await _build_user_response(user, db, auth_service)


@router.post("/login", response_model=Token)
async def login(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: DbSession,
) -> Token:
    """Login and get access token."""
    auth_service = AuthService(db)

    user = await auth_service.authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = auth_service.create_token(user)
    return Token(access_token=access_token)


@router.get("/me", response_model=UserResponse)
async def get_current_user(current_user: CurrentUser, db: DbSession) -> UserResponse:
    """Get current authenticated user."""
    auth_service = AuthService(db)
    return await _build_user_response(current_user, db, auth_service)
