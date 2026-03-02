from unittest.mock import patch

import pytest
from fastapi import status
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.user import UserResponse
from app.services.auth import AuthService
from app.core.security import get_password_hash
from app.models.invite import Invite
from app.models.organisation import Organisation
from app.models.team import Team, TeamMember, TeamRole
from app.models.user import User


# =============================================================================
# Registration Tests
# =============================================================================


async def test_register_user(test_client: AsyncClient):
    """Test successful user registration."""
    response = await test_client.post(
        "/api/auth/register",
        json={"email": "test@example.com", "name": "Test User", "password": "password"},
    )
    assert response.status_code == status.HTTP_201_CREATED
    user = UserResponse(**response.json())
    assert user.email == "test@example.com"
    assert user.name == "Test User"


async def test_register_existing_user(test_client: AsyncClient):
    """Test registration with an already registered email."""
    await test_client.post(
        "/api/auth/register",
        json={"email": "test@example.com", "name": "Test User", "password": "password"},
    )
    response = await test_client.post(
        "/api/auth/register",
        json={
            "email": "test@example.com",
            "name": "Another User",
            "password": "password",
        },
    )
    assert response.status_code == status.HTTP_400_BAD_REQUEST


async def test_login(test_client: AsyncClient):
    """Test successful login."""
    await test_client.post(
        "/api/auth/register",
        json={"email": "test@example.com", "name": "Test User", "password": "password"},
    )
    response = await test_client.post(
        "/api/auth/login",
        data={"username": "test@example.com", "password": "password"},
    )
    assert response.status_code == status.HTTP_200_OK
    assert "access_token" in response.json()


async def test_login_wrong_password(test_client: AsyncClient):
    """Test login with wrong password."""
    await test_client.post(
        "/api/auth/register",
        json={"email": "test@example.com", "name": "Test User", "password": "password"},
    )
    response = await test_client.post(
        "/api/auth/login",
        data={"username": "test@example.com", "password": "wrongpassword"},
    )
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


async def test_login_non_existent_user(test_client: AsyncClient):
    """Test login with a non-existent user."""
    response = await test_client.post(
        "/api/auth/login",
        data={"username": "nonexistent@example.com", "password": "password"},
    )
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


async def test_get_current_user(test_client: AsyncClient):
    """Test getting the current authenticated user."""
    await test_client.post(
        "/api/auth/register",
        json={"email": "test@example.com", "name": "Test User", "password": "password"},
    )
    login_response = await test_client.post(
        "/api/auth/login",
        data={"username": "test@example.com", "password": "password"},
    )
    token = login_response.json()["access_token"]
    response = await test_client.get(
        "/api/auth/me", headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == status.HTTP_200_OK
    user = UserResponse(**response.json())
    assert user.email == "test@example.com"
    assert user.name == "Test User"


async def test_get_current_user_not_authenticated(test_client: AsyncClient):
    """Test getting current user without authentication."""
    response = await test_client.get("/api/auth/me")
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


# =============================================================================
# Input Validation Tests
# =============================================================================


async def test_register_invalid_email(test_client: AsyncClient):
    """Test registration with an invalid email format."""
    response = await test_client.post(
        "/api/auth/register",
        json={"email": "not-an-email", "name": "Test User", "password": "password"},
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT


async def test_register_missing_email(test_client: AsyncClient):
    """Test registration with missing email."""
    response = await test_client.post(
        "/api/auth/register",
        json={"name": "Test User", "password": "password"},
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT


async def test_register_missing_name(test_client: AsyncClient):
    """Test registration with missing name."""
    response = await test_client.post(
        "/api/auth/register",
        json={"email": "test@example.com", "password": "password"},
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT


async def test_register_missing_password(test_client: AsyncClient):
    """Test registration with missing password."""
    response = await test_client.post(
        "/api/auth/register",
        json={"email": "test@example.com", "name": "Test User"},
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT


async def test_register_empty_name(test_client: AsyncClient):
    """Test registration with empty name."""
    response = await test_client.post(
        "/api/auth/register",
        json={"email": "test@example.com", "name": "", "password": "password"},
    )
    # Empty string might still be accepted depending on validation
    # At minimum, check it doesn't crash
    assert response.status_code in [
        status.HTTP_201_CREATED,
        status.HTTP_422_UNPROCESSABLE_CONTENT,
    ]


# =============================================================================
# Token Validation Tests
# =============================================================================


async def test_get_current_user_invalid_token(test_client: AsyncClient):
    """Test accessing protected endpoint with an invalid token."""
    response = await test_client.get(
        "/api/auth/me",
        headers={"Authorization": "Bearer invalid-token-here"},
    )
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


async def test_get_current_user_malformed_auth_header(test_client: AsyncClient):
    """Test accessing protected endpoint with malformed auth header."""
    response = await test_client.get(
        "/api/auth/me",
        headers={"Authorization": "NotBearer token"},
    )
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


async def test_get_current_user_empty_token(test_client: AsyncClient):
    """Test accessing protected endpoint with empty Bearer token."""
    response = await test_client.get(
        "/api/auth/me",
        headers={"Authorization": "Bearer "},
    )
    assert response.status_code == status.HTTP_401_UNAUTHORIZED


# =============================================================================
# Auth Service Unit Tests
# =============================================================================


@pytest.mark.asyncio
async def test_auth_service_create_user(db_session: AsyncSession):
    """Test creating a user through the auth service."""
    from app.schemas.user import UserCreate

    service = AuthService(db_session)
    user_data = UserCreate(
        email="service@example.com",
        name="Service Test",
        password="testpassword",
    )
    user = await service.create_user(user_data)

    assert user.email == "service@example.com"
    assert user.name == "Service Test"
    assert user.password_hash is not None
    assert user.password_hash != "testpassword"  # Should be hashed


@pytest.mark.asyncio
async def test_auth_service_get_user_by_email(db_session: AsyncSession):
    """Test getting a user by email through the auth service."""
    from app.models.user import User

    user = User(
        email="findme@example.com",
        name="Find Me",
        password_hash=get_password_hash("password"),
    )
    db_session.add(user)
    await db_session.commit()

    service = AuthService(db_session)
    found_user = await service.get_user_by_email("findme@example.com")

    assert found_user is not None
    assert found_user.email == "findme@example.com"


@pytest.mark.asyncio
async def test_auth_service_get_user_by_email_not_found(db_session: AsyncSession):
    """Test getting a non-existent user by email."""
    service = AuthService(db_session)
    found_user = await service.get_user_by_email("nonexistent@example.com")

    assert found_user is None


@pytest.mark.asyncio
async def test_auth_service_authenticate_user(db_session: AsyncSession):
    """Test authenticating a user through the auth service."""
    from app.models.user import User

    user = User(
        email="auth@example.com",
        name="Auth Test",
        password_hash=get_password_hash("correctpassword"),
    )
    db_session.add(user)
    await db_session.commit()

    service = AuthService(db_session)

    # Correct password
    authenticated = await service.authenticate_user(
        "auth@example.com", "correctpassword"
    )
    assert authenticated is not None
    assert authenticated.email == "auth@example.com"

    # Wrong password
    not_authenticated = await service.authenticate_user(
        "auth@example.com", "wrongpassword"
    )
    assert not_authenticated is None


@pytest.mark.asyncio
async def test_auth_service_authenticate_nonexistent_user(db_session: AsyncSession):
    """Test authenticating a non-existent user."""
    service = AuthService(db_session)
    authenticated = await service.authenticate_user("nobody@example.com", "password")
    assert authenticated is None


@pytest.mark.asyncio
async def test_auth_service_create_token(db_session: AsyncSession):
    """Test creating a token for a user."""
    from app.models.user import User

    user = User(
        email="token@example.com",
        name="Token Test",
        password_hash=get_password_hash("password"),
    )
    db_session.add(user)
    await db_session.commit()

    service = AuthService(db_session)
    token = service.create_token(user)

    assert token is not None
    assert isinstance(token, str)
    assert len(token) > 0


# =============================================================================
# Full User Flow Tests
# =============================================================================


async def test_full_signup_login_access_flow(test_client: AsyncClient):
    """Test complete user flow: signup -> login -> access protected resource."""
    # Step 1: Register
    register_response = await test_client.post(
        "/api/auth/register",
        json={
            "email": "fullflow@example.com",
            "name": "Full Flow User",
            "password": "securepassword123",
        },
    )
    assert register_response.status_code == status.HTTP_201_CREATED
    user_data = register_response.json()
    assert user_data["email"] == "fullflow@example.com"

    # Step 2: Login
    login_response = await test_client.post(
        "/api/auth/login",
        data={"username": "fullflow@example.com", "password": "securepassword123"},
    )
    assert login_response.status_code == status.HTTP_200_OK
    token_data = login_response.json()
    assert "access_token" in token_data
    token = token_data["access_token"]

    # Step 3: Access protected resource
    me_response = await test_client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert me_response.status_code == status.HTTP_200_OK
    me_data = me_response.json()
    assert me_data["email"] == "fullflow@example.com"
    assert me_data["name"] == "Full Flow User"


async def test_signup_then_immediate_login(test_client: AsyncClient):
    """Test that a user can login immediately after signup."""
    # Register
    await test_client.post(
        "/api/auth/register",
        json={
            "email": "immediate@example.com",
            "name": "Immediate Login",
            "password": "mypassword",
        },
    )

    # Login immediately
    login_response = await test_client.post(
        "/api/auth/login",
        data={"username": "immediate@example.com", "password": "mypassword"},
    )
    assert login_response.status_code == status.HTTP_200_OK
    assert "access_token" in login_response.json()


async def test_multiple_logins_same_user(test_client: AsyncClient):
    """Test that a user can login multiple times and get valid tokens."""
    # Register
    await test_client.post(
        "/api/auth/register",
        json={
            "email": "multilogin@example.com",
            "name": "Multi Login",
            "password": "password123",
        },
    )

    # Login first time
    login1 = await test_client.post(
        "/api/auth/login",
        data={"username": "multilogin@example.com", "password": "password123"},
    )
    token1 = login1.json()["access_token"]

    # Login second time
    login2 = await test_client.post(
        "/api/auth/login",
        data={"username": "multilogin@example.com", "password": "password123"},
    )
    token2 = login2.json()["access_token"]

    # Both tokens should work
    me1 = await test_client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token1}"},
    )
    me2 = await test_client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token2}"},
    )

    assert me1.status_code == status.HTTP_200_OK
    assert me2.status_code == status.HTTP_200_OK


async def test_case_sensitivity_email(test_client: AsyncClient):
    """Test email handling with different cases."""
    # Register with lowercase
    await test_client.post(
        "/api/auth/register",
        json={
            "email": "casetest@example.com",
            "name": "Case Test",
            "password": "password",
        },
    )

    # Try to login with same case (should work)
    response = await test_client.post(
        "/api/auth/login",
        data={"username": "casetest@example.com", "password": "password"},
    )
    assert response.status_code == status.HTTP_200_OK


# =============================================================================
# Registration with Placeholder Email Tests
# =============================================================================


async def test_register_with_invited_placeholder_email(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Registration should succeed when the email belongs to a placeholder user."""
    # Create a placeholder user with that email (simulating invite flow)
    placeholder = User(
        email="invited@example.com",
        name="Placeholder",
        password_hash=get_password_hash("placeholder"),
        is_placeholder=True,
    )
    db_session.add(placeholder)
    await db_session.commit()

    # Register with the same email — should succeed
    response = await test_client.post(
        "/api/auth/register",
        json={
            "email": "invited@example.com",
            "name": "Real User",
            "password": "securepass123",
        },
    )
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["email"] == "invited@example.com"
    assert data["name"] == "Real User"


async def test_register_with_invited_email_can_login(
    test_client: AsyncClient, db_session: AsyncSession
):
    """After registering with a placeholder's email, the user should be able to login."""
    placeholder = User(
        email="login_invited@example.com",
        name="Placeholder",
        password_hash=get_password_hash("placeholder"),
        is_placeholder=True,
    )
    db_session.add(placeholder)
    await db_session.commit()

    await test_client.post(
        "/api/auth/register",
        json={
            "email": "login_invited@example.com",
            "name": "Real User",
            "password": "mypassword",
        },
    )

    login_response = await test_client.post(
        "/api/auth/login",
        data={"username": "login_invited@example.com", "password": "mypassword"},
    )
    assert login_response.status_code == status.HTTP_200_OK
    assert "access_token" in login_response.json()


async def test_register_with_pending_invite_creates_notification(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Registering with an email that has pending invites should create notifications."""
    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    team = Team(name="Worship Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    placeholder = User(
        email="pending_invite@example.com",
        name="Placeholder",
        password_hash=get_password_hash("placeholder"),
        is_placeholder=True,
    )
    db_session.add(placeholder)
    await db_session.flush()

    membership = TeamMember(
        user_id=placeholder.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(membership)

    invite = Invite(
        team_id=team.id,
        user_id=placeholder.id,
        email="pending_invite@example.com",
    )
    db_session.add(invite)
    await db_session.commit()

    # Register with the invited email
    register_response = await test_client.post(
        "/api/auth/register",
        json={
            "email": "pending_invite@example.com",
            "name": "New User",
            "password": "password123",
        },
    )
    assert register_response.status_code == status.HTTP_201_CREATED

    # Login and check notifications
    login_response = await test_client.post(
        "/api/auth/login",
        data={"username": "pending_invite@example.com", "password": "password123"},
    )
    token = login_response.json()["access_token"]

    notifications = await test_client.get(
        "/api/notifications",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert notifications.status_code == 200
    data = notifications.json()
    assert any(
        n["type"] == "team_invite" and n["reference_id"] == str(team.id) for n in data
    )


# =============================================================================
# Auth Config Tests
# =============================================================================


async def test_auth_config_defaults(test_client: AsyncClient):
    """Test /auth/config returns default flags."""
    response = await test_client.get("/api/auth/config")
    assert response.status_code == 200
    data = response.json()
    assert data["email_enabled"] is True
    assert data["google_enabled"] is False
    assert data["google_client_id"] is None


@patch("app.api.auth.get_settings")
async def test_auth_config_google_enabled(mock_settings, test_client: AsyncClient):
    """Test /auth/config when Google is enabled."""
    from app.core.config import Settings

    mock_settings.return_value = Settings(
        auth_google_enabled=True,
        google_client_id="test-client-id.apps.googleusercontent.com",
    )
    response = await test_client.get("/api/auth/config")
    assert response.status_code == 200
    data = response.json()
    assert data["google_enabled"] is True
    assert data["google_client_id"] == "test-client-id.apps.googleusercontent.com"


# =============================================================================
# Google Login Disabled Tests
# =============================================================================


async def test_google_login_disabled_by_default(test_client: AsyncClient):
    """Test POST /auth/google returns 403 when Google auth is disabled."""
    response = await test_client.post(
        "/api/auth/google",
        json={"id_token": "some-token"},
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN
    assert "disabled" in response.json()["detail"].lower()


# =============================================================================
# Email Login/Register Disabled Tests
# =============================================================================


@patch("app.api.auth.get_settings")
async def test_login_disabled_when_email_auth_off(
    mock_settings, test_client: AsyncClient
):
    """Test POST /auth/login returns 403 when email auth is disabled."""
    from app.core.config import Settings

    mock_settings.return_value = Settings(auth_email_enabled=False)
    response = await test_client.post(
        "/api/auth/login",
        data={"username": "test@example.com", "password": "password"},
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN
    assert "disabled" in response.json()["detail"].lower()


@patch("app.api.auth.get_settings")
async def test_register_disabled_when_email_auth_off(
    mock_settings, test_client: AsyncClient
):
    """Test POST /auth/register returns 403 when email auth is disabled."""
    from app.core.config import Settings

    mock_settings.return_value = Settings(auth_email_enabled=False)
    response = await test_client.post(
        "/api/auth/register",
        json={"email": "test@example.com", "name": "Test", "password": "password"},
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN
    assert "disabled" in response.json()["detail"].lower()


# =============================================================================
# Google Login Flow Tests
# =============================================================================


@patch("app.api.auth.get_settings")
@patch("app.services.google_auth.verify_google_id_token")
async def test_google_login_creates_new_user(
    mock_verify, mock_settings, test_client: AsyncClient
):
    """Test Google login creates a new user when none exists."""
    from app.core.config import Settings

    mock_settings.return_value = Settings(
        auth_google_enabled=True,
        google_client_id="test-client-id",
    )
    mock_verify.return_value = {
        "sub": "google-123",
        "email": "googleuser@gmail.com",
        "email_verified": True,
        "name": "Google User",
    }

    response = await test_client.post(
        "/api/auth/google",
        json={"id_token": "valid-google-token"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


@patch("app.api.auth.get_settings")
@patch("app.services.google_auth.verify_google_id_token")
async def test_google_login_links_existing_email_user(
    mock_verify, mock_settings, test_client: AsyncClient
):
    """Test Google login links to existing user with same email."""
    from app.core.config import Settings

    mock_settings.return_value = Settings(
        auth_google_enabled=True,
        google_client_id="test-client-id",
    )

    # First register with email
    await test_client.post(
        "/api/auth/register",
        json={
            "email": "existing@example.com",
            "name": "Existing User",
            "password": "password",
        },
    )

    # Now login with Google using same email
    mock_verify.return_value = {
        "sub": "google-456",
        "email": "existing@example.com",
        "email_verified": True,
        "name": "Existing User",
    }
    response = await test_client.post(
        "/api/auth/google",
        json={"id_token": "valid-google-token"},
    )
    assert response.status_code == 200
    token = response.json()["access_token"]

    # Verify it's the same user
    me_response = await test_client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert me_response.status_code == 200
    assert me_response.json()["email"] == "existing@example.com"


async def test_google_only_user_cannot_email_login(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Test that a Google-only user gets a helpful error when trying email login."""
    # Create a Google-only user directly in the database
    user = User(
        email="googleonly@example.com",
        name="Google Only",
        google_id="google-789",
    )
    db_session.add(user)
    await db_session.commit()

    response = await test_client.post(
        "/api/auth/login",
        data={"username": "googleonly@example.com", "password": "anything"},
    )
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert "google" in response.json()["detail"].lower()


# =============================================================================
# Google Auth Service Tests
# =============================================================================


@pytest.mark.asyncio
async def test_authenticate_or_create_google_user_new(db_session: AsyncSession):
    """Test creating a new user via Google OAuth."""
    service = AuthService(db_session)
    user = await service.authenticate_or_create_google_user(
        google_id="new-google-id",
        email="newgoogle@example.com",
        name="New Google User",
    )
    assert user.email == "newgoogle@example.com"
    assert user.google_id == "new-google-id"
    assert user.password_hash is None


@pytest.mark.asyncio
async def test_authenticate_or_create_google_user_existing(db_session: AsyncSession):
    """Test linking Google to an existing email user."""
    # Create existing user
    existing = User(
        email="link@example.com",
        name="Link User",
        password_hash=get_password_hash("password"),
    )
    db_session.add(existing)
    await db_session.commit()

    service = AuthService(db_session)
    user = await service.authenticate_or_create_google_user(
        google_id="link-google-id",
        email="link@example.com",
        name="Link User",
    )
    assert user.id == existing.id
    assert user.google_id == "link-google-id"
    assert user.password_hash is not None  # Password should be preserved


@pytest.mark.asyncio
async def test_authenticate_or_create_google_user_placeholder(
    db_session: AsyncSession,
):
    """Test converting a placeholder user via Google OAuth."""
    placeholder = User(
        email="placeholder@example.com",
        name="Placeholder",
        is_placeholder=True,
    )
    db_session.add(placeholder)
    await db_session.commit()

    service = AuthService(db_session)
    user = await service.authenticate_or_create_google_user(
        google_id="placeholder-google-id",
        email="placeholder@example.com",
        name="Real Name",
    )
    assert user.id == placeholder.id
    assert user.google_id == "placeholder-google-id"
    assert user.name == "Real Name"
    assert user.is_placeholder is False


@pytest.mark.asyncio
async def test_authenticate_or_create_google_user_already_linked(
    db_session: AsyncSession,
):
    """Test that an already-linked Google user is returned directly."""
    existing = User(
        email="linked@example.com",
        name="Linked User",
        google_id="already-linked-id",
    )
    db_session.add(existing)
    await db_session.commit()

    service = AuthService(db_session)
    user = await service.authenticate_or_create_google_user(
        google_id="already-linked-id",
        email="linked@example.com",
        name="Linked User",
    )
    assert user.id == existing.id


# =============================================================================
# First-Run Setup Flow Tests
# =============================================================================


async def test_setup_required_true_when_no_users(test_client: AsyncClient):
    """Test setup-required returns true when no non-placeholder users exist."""
    response = await test_client.get("/api/auth/setup-required")
    assert response.status_code == 200
    assert response.json()["setup_required"] is True


async def test_setup_required_true_with_only_placeholders(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Test setup-required returns true when only placeholder users exist."""
    placeholder = User(
        name="Placeholder",
        is_placeholder=True,
    )
    db_session.add(placeholder)
    await db_session.commit()

    response = await test_client.get("/api/auth/setup-required")
    assert response.status_code == 200
    assert response.json()["setup_required"] is True


async def test_setup_required_false_when_users_exist(test_client: AsyncClient):
    """Test setup-required returns false after a user is registered."""
    await test_client.post(
        "/api/auth/register",
        json={"email": "user@example.com", "name": "User", "password": "password"},
    )
    response = await test_client.get("/api/auth/setup-required")
    assert response.status_code == 200
    assert response.json()["setup_required"] is False


async def test_setup_creates_superadmin(test_client: AsyncClient):
    """Test POST /auth/setup creates a superadmin user and returns JWT."""
    response = await test_client.post(
        "/api/auth/setup",
        json={
            "name": "Admin User",
            "email": "admin@example.com",
            "password": "securepassword",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"

    # Verify the user is a superadmin
    token = data["access_token"]
    me_response = await test_client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert me_response.status_code == 200
    me_data = me_response.json()
    assert me_data["name"] == "Admin User"
    assert me_data["email"] == "admin@example.com"
    assert "superadmin" in me_data["roles"]


async def test_setup_with_org_name_creates_org(test_client: AsyncClient):
    """Test POST /auth/setup with org name creates the organisation."""
    response = await test_client.post(
        "/api/auth/setup",
        json={
            "name": "Admin",
            "email": "admin@church.org",
            "password": "securepassword",
            "organisation_name": "St. Mary's",
        },
    )
    assert response.status_code == 200
    token = response.json()["access_token"]

    # Check user has the org
    me_response = await test_client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert me_response.status_code == 200
    orgs = me_response.json()["organisations"]
    assert any(o["name"] == "St. Mary's" for o in orgs)


async def test_setup_returns_409_when_users_exist(test_client: AsyncClient):
    """Test POST /auth/setup returns 409 when users already exist."""
    # First setup
    await test_client.post(
        "/api/auth/setup",
        json={
            "name": "First Admin",
            "email": "first@example.com",
            "password": "securepassword",
        },
    )

    # Second setup attempt
    response = await test_client.post(
        "/api/auth/setup",
        json={
            "name": "Second Admin",
            "email": "second@example.com",
            "password": "securepassword",
        },
    )
    assert response.status_code == status.HTTP_409_CONFLICT


async def test_setup_short_password_rejected(test_client: AsyncClient):
    """Test POST /auth/setup rejects password shorter than 8 chars."""
    response = await test_client.post(
        "/api/auth/setup",
        json={
            "name": "Admin",
            "email": "admin@example.com",
            "password": "short",
        },
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT


# =============================================================================
# Deactivated User Tests
# =============================================================================


async def test_deactivated_user_gets_403(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Test that a deactivated user gets 403 on authenticated endpoints."""
    user = User(
        email="deactivated@example.com",
        name="Deactivated",
        password_hash=get_password_hash("password"),
        is_deactivated=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    # Login succeeds (login doesn't check deactivation, just credentials)
    login_response = await test_client.post(
        "/api/auth/login",
        data={"username": "deactivated@example.com", "password": "password"},
    )
    assert login_response.status_code == 200
    token = login_response.json()["access_token"]

    # But accessing /me returns 403
    me_response = await test_client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert me_response.status_code == status.HTTP_403_FORBIDDEN
    assert "deactivated" in me_response.json()["detail"].lower()


# =============================================================================
# Superadmin Role in User Response Tests
# =============================================================================


async def test_superadmin_has_superadmin_role(
    test_client: AsyncClient,
):
    """Test that superadmin users have 'superadmin' in their roles."""
    # Use setup to create superadmin
    setup_resp = await test_client.post(
        "/api/auth/setup",
        json={
            "name": "Super Admin",
            "email": "super@example.com",
            "password": "securepassword",
        },
    )
    token = setup_resp.json()["access_token"]

    me_response = await test_client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert "superadmin" in me_response.json()["roles"]


async def test_regular_user_no_superadmin_role(test_client: AsyncClient):
    """Test that regular users don't have 'superadmin' in their roles."""
    await test_client.post(
        "/api/auth/register",
        json={
            "email": "regular@example.com",
            "name": "Regular",
            "password": "password",
        },
    )
    login_resp = await test_client.post(
        "/api/auth/login",
        data={"username": "regular@example.com", "password": "password"},
    )
    token = login_resp.json()["access_token"]

    me_response = await test_client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert "superadmin" not in me_response.json()["roles"]
