from fastapi import status
from httpx import AsyncClient

from app.schemas.user import UserResponse


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
