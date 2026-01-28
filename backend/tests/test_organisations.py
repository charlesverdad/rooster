"""
Unit tests for the organisation service and API endpoints.
"""

import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.organisation import Organisation, OrganisationMember, OrganisationRole
from app.models.user import User
from app.core.security import get_password_hash, create_access_token
from app.services.organisation import OrganisationService


@pytest.fixture
async def test_user_for_org(db_session: AsyncSession):
    """Create a test user for organisation tests."""
    user = User(
        email="orguser@example.com",
        name="Org Test User",
        password_hash=get_password_hash("password"),
    )
    db_session.add(user)
    await db_session.commit()
    return user


@pytest.mark.asyncio
async def test_create_organisation_service(db_session: AsyncSession, test_user_for_org):
    """Test creating an organisation through the service."""
    user = test_user_for_org

    from app.schemas.organisation import OrganisationCreate

    service = OrganisationService(db_session)
    org_data = OrganisationCreate(name="New Church")
    org = await service.create_organisation(org_data, user.id)

    assert org.name == "New Church"

    # Creator should be an admin
    membership = await service.get_membership(user.id, org.id)
    assert membership is not None
    assert membership.role == OrganisationRole.ADMIN


@pytest.mark.asyncio
async def test_get_organisation(db_session: AsyncSession):
    """Test getting an organisation by ID."""
    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.commit()

    service = OrganisationService(db_session)
    result = await service.get_organisation(org.id)

    assert result is not None
    assert result.name == "Test Church"


@pytest.mark.asyncio
async def test_get_organisation_not_found(db_session: AsyncSession):
    """Test getting a non-existent organisation."""
    service = OrganisationService(db_session)
    result = await service.get_organisation(uuid.uuid4())

    assert result is None


@pytest.mark.asyncio
async def test_get_user_organisations(db_session: AsyncSession, test_user_for_org):
    """Test getting all organisations a user belongs to."""
    user = test_user_for_org

    org1 = Organisation(name="Church 1")
    org2 = Organisation(name="Church 2")
    db_session.add_all([org1, org2])
    await db_session.flush()

    member1 = OrganisationMember(
        user_id=user.id,
        organisation_id=org1.id,
        role=OrganisationRole.ADMIN,
    )
    member2 = OrganisationMember(
        user_id=user.id,
        organisation_id=org2.id,
        role=OrganisationRole.MEMBER,
    )
    db_session.add_all([member1, member2])
    await db_session.commit()

    service = OrganisationService(db_session)
    orgs = await service.get_user_organisations(user.id)

    assert len(orgs) == 2
    org_names = {o[0].name for o in orgs}
    assert "Church 1" in org_names
    assert "Church 2" in org_names


@pytest.mark.asyncio
async def test_update_organisation(db_session: AsyncSession):
    """Test updating an organisation."""
    org = Organisation(name="Old Name")
    db_session.add(org)
    await db_session.commit()

    from app.schemas.organisation import OrganisationUpdate

    service = OrganisationService(db_session)
    updated = await service.update_organisation(
        org.id, OrganisationUpdate(name="New Name")
    )

    assert updated is not None
    assert updated.name == "New Name"


@pytest.mark.asyncio
async def test_delete_organisation(db_session: AsyncSession):
    """Test deleting an organisation."""
    org = Organisation(name="To Delete")
    db_session.add(org)
    await db_session.commit()

    service = OrganisationService(db_session)
    result = await service.delete_organisation(org.id)
    await db_session.commit()

    assert result is True
    assert await service.get_organisation(org.id) is None


@pytest.mark.asyncio
async def test_delete_organisation_not_found(db_session: AsyncSession):
    """Test deleting a non-existent organisation."""
    service = OrganisationService(db_session)
    result = await service.delete_organisation(uuid.uuid4())

    assert result is False


@pytest.mark.asyncio
async def test_is_admin(db_session: AsyncSession, test_user_for_org):
    """Test checking if user is an admin."""
    user = test_user_for_org

    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    admin_member = OrganisationMember(
        user_id=user.id,
        organisation_id=org.id,
        role=OrganisationRole.ADMIN,
    )
    db_session.add(admin_member)

    regular_user = User(
        email="regular@example.com",
        name="Regular User",
        password_hash=get_password_hash("password"),
    )
    db_session.add(regular_user)
    await db_session.flush()

    regular_member = OrganisationMember(
        user_id=regular_user.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db_session.add(regular_member)
    await db_session.commit()

    service = OrganisationService(db_session)

    assert await service.is_admin(user.id, org.id) is True
    assert await service.is_admin(regular_user.id, org.id) is False


@pytest.mark.asyncio
async def test_add_member_to_organisation(db_session: AsyncSession, test_user_for_org):
    """Test adding a member to an organisation."""
    org = Organisation(name="Test Church")
    db_session.add(org)

    new_user = User(
        email="newmember@example.com",
        name="New Member",
        password_hash=get_password_hash("password"),
    )
    db_session.add(new_user)
    await db_session.commit()

    service = OrganisationService(db_session)
    membership = await service.add_member(org.id, new_user.id, OrganisationRole.MEMBER)

    assert membership is not None
    assert membership.role == OrganisationRole.MEMBER


@pytest.mark.asyncio
async def test_add_member_already_exists(db_session: AsyncSession, test_user_for_org):
    """Test adding a member who is already in the organisation."""
    user = test_user_for_org

    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    existing_member = OrganisationMember(
        user_id=user.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db_session.add(existing_member)
    await db_session.commit()

    service = OrganisationService(db_session)
    result = await service.add_member(org.id, user.id, OrganisationRole.ADMIN)

    # Should return existing membership
    assert result is not None
    assert result.role == OrganisationRole.MEMBER  # Role should not change


@pytest.mark.asyncio
async def test_add_member_user_not_found(db_session: AsyncSession):
    """Test adding a non-existent user to an organisation."""
    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.commit()

    service = OrganisationService(db_session)
    result = await service.add_member(org.id, uuid.uuid4(), OrganisationRole.MEMBER)

    assert result is None


@pytest.mark.asyncio
async def test_remove_member_from_organisation(
    db_session: AsyncSession, test_user_for_org
):
    """Test removing a member from an organisation."""
    user = test_user_for_org

    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    member = OrganisationMember(
        user_id=user.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db_session.add(member)
    await db_session.commit()

    service = OrganisationService(db_session)
    result = await service.remove_member(org.id, user.id)
    await db_session.commit()

    assert result is True
    assert await service.get_membership(user.id, org.id) is None


@pytest.mark.asyncio
async def test_remove_member_not_found(db_session: AsyncSession, test_user_for_org):
    """Test removing a non-existent member from an organisation."""
    user = test_user_for_org

    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.commit()

    service = OrganisationService(db_session)
    result = await service.remove_member(org.id, user.id)

    assert result is False


@pytest.mark.asyncio
async def test_get_members(db_session: AsyncSession, test_user_for_org):
    """Test getting all members of an organisation."""
    user = test_user_for_org

    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    member1 = OrganisationMember(
        user_id=user.id,
        organisation_id=org.id,
        role=OrganisationRole.ADMIN,
    )
    db_session.add(member1)

    user2 = User(
        email="user2@example.com",
        name="User 2",
        password_hash=get_password_hash("password"),
    )
    db_session.add(user2)
    await db_session.flush()

    member2 = OrganisationMember(
        user_id=user2.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db_session.add(member2)
    await db_session.commit()

    service = OrganisationService(db_session)
    members = await service.get_members(org.id)

    assert len(members) == 2


@pytest.mark.asyncio
async def test_create_organisation_api(
    test_client: AsyncClient, db_session: AsyncSession, test_user_for_org
):
    """Test creating an organisation via API endpoint."""
    user = test_user_for_org

    token = create_access_token(subject=str(user.id))
    response = await test_client.post(
        "/api/organisations",
        json={"name": "API Created Church"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 201
    resp_data = response.json()
    assert resp_data["name"] == "API Created Church"


@pytest.mark.asyncio
async def test_list_organisations_api(
    test_client: AsyncClient, db_session: AsyncSession, test_user_for_org
):
    """Test listing organisations via API endpoint."""
    user = test_user_for_org

    org = Organisation(name="My Church")
    db_session.add(org)
    await db_session.flush()

    member = OrganisationMember(
        user_id=user.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db_session.add(member)
    await db_session.commit()

    token = create_access_token(subject=str(user.id))
    response = await test_client.get(
        "/api/organisations",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    orgs = response.json()
    assert len(orgs) >= 1
    assert any(o["name"] == "My Church" for o in orgs)


@pytest.mark.asyncio
async def test_get_organisation_api(
    test_client: AsyncClient, db_session: AsyncSession, test_user_for_org
):
    """Test getting a specific organisation via API endpoint."""
    user = test_user_for_org

    org = Organisation(name="Specific Church")
    db_session.add(org)
    await db_session.flush()

    member = OrganisationMember(
        user_id=user.id,
        organisation_id=org.id,
        role=OrganisationRole.ADMIN,
    )
    db_session.add(member)
    await db_session.commit()

    token = create_access_token(subject=str(user.id))
    response = await test_client.get(
        f"/api/organisations/{org.id}",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    resp_data = response.json()
    assert resp_data["name"] == "Specific Church"


@pytest.mark.asyncio
async def test_update_organisation_api(
    test_client: AsyncClient, db_session: AsyncSession, test_user_for_org
):
    """Test updating an organisation via API endpoint."""
    user = test_user_for_org

    org = Organisation(name="Old Church Name")
    db_session.add(org)
    await db_session.flush()

    member = OrganisationMember(
        user_id=user.id,
        organisation_id=org.id,
        role=OrganisationRole.ADMIN,
    )
    db_session.add(member)
    await db_session.commit()

    token = create_access_token(subject=str(user.id))
    response = await test_client.patch(
        f"/api/organisations/{org.id}",
        json={"name": "New Church Name"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    resp_data = response.json()
    assert resp_data["name"] == "New Church Name"
