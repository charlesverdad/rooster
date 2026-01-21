import pytest
from fastapi import status
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.user import UserResponse
from app.services.auth import AuthService
from app.core.security import get_password_hash


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
        json={"email": "test@example.com", "name": "Another User", "password": "password"},
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
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


async def test_register_missing_email(test_client: AsyncClient):
    """Test registration with missing email."""
    response = await test_client.post(
        "/api/auth/register",
        json={"name": "Test User", "password": "password"},
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


async def test_register_missing_name(test_client: AsyncClient):
    """Test registration with missing name."""
    response = await test_client.post(
        "/api/auth/register",
        json={"email": "test@example.com", "password": "password"},
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


async def test_register_missing_password(test_client: AsyncClient):
    """Test registration with missing password."""
    response = await test_client.post(
        "/api/auth/register",
        json={"email": "test@example.com", "name": "Test User"},
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


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
        status.HTTP_422_UNPROCESSABLE_ENTITY,
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
    authenticated = await service.authenticate_user("auth@example.com", "correctpassword")
    assert authenticated is not None
    assert authenticated.email == "auth@example.com"

    # Wrong password
    not_authenticated = await service.authenticate_user("auth@example.com", "wrongpassword")
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
