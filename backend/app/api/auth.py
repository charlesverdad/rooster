from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm

from app.api.deps import CurrentUser, DbSession
from app.schemas.user import UserCreate, UserResponse, Token
from app.services.auth import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserCreate, db: DbSession) -> UserResponse:
    """Register a new user."""
    auth_service = AuthService(db)

    existing_user = await auth_service.get_user_by_email(user_data.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    user = await auth_service.create_user(user_data)
    roles = await auth_service.get_user_roles(user.id)
    user_response = UserResponse.model_validate(user)
    user_response.roles = roles
    return user_response


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
    roles = await auth_service.get_user_roles(current_user.id)
    user_response = UserResponse.model_validate(current_user)
    user_response.roles = roles
    return user_response
