import asyncio
from typing import AsyncGenerator

import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base, get_db
from app.main import app

# Use an in-memory SQLite database for testing
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

engine = create_async_engine(TEST_DATABASE_URL, echo=True)
TestingSessionLocal = sessionmaker(
    autocommit=False, autoflush=False, bind=engine, class_=AsyncSession
)


async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
    """Override database session for tests."""
    async with TestingSessionLocal() as session:
        yield session


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for each test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
async def test_db():
    """Fixture to create and tear down the test database."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """Fixture to provide a database session for a test."""
    async with TestingSessionLocal() as session:
        yield session


@pytest.fixture
async def test_client(test_db) -> AsyncGenerator[AsyncClient, None]:
    """Fixture to provide a test client."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client


@pytest.fixture
async def test_user(db_session: AsyncSession):
    """Fixture to create a test user."""
    from app.models.user import User
    from app.core.security import get_password_hash
    
    user = User(
        email="test@example.com",
        name="Test User",
        password_hash=get_password_hash("testpassword"),
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
async def auth_headers(test_client: AsyncClient, test_user):
    """Fixture to provide authentication headers."""
    from app.core.security import create_access_token
    
    token = create_access_token({"sub": test_user.email})
    return {"Authorization": f"Bearer {token}"}


# Alias fixtures for convenience
@pytest.fixture
async def client(test_client):
    """Alias for test_client."""
    return test_client


@pytest.fixture
async def db(db_session):
    """Alias for db_session."""
    return db_session
