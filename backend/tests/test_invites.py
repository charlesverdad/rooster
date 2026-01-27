import pytest
from datetime import datetime, timezone, timedelta
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, get_password_hash
from app.models.invite import Invite
from app.models.organisation import Organisation, OrganisationMember, OrganisationRole
from app.models.team import Team, TeamMember, TeamRole
from app.models.user import User


async def _create_invite_fixtures(db_session: AsyncSession):
    """Helper to create org, team, placeholder user, membership, and invite."""
    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    team = Team(name="Praise Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    user = User(
        email="invitee@example.com",
        name="Invitee User",
        password_hash=get_password_hash("placeholder"),
        is_placeholder=True,
    )
    db_session.add(user)
    await db_session.flush()

    membership = TeamMember(
        user_id=user.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(membership)

    invite = Invite(
        team_id=team.id,
        user_id=user.id,
        email=user.email,
    )
    db_session.add(invite)
    await db_session.commit()

    return org, team, user, invite


@pytest.mark.asyncio
async def test_accept_invite_creates_team_notification(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Accepting an invite should create a team_joined notification with reference_id."""
    org, team, user, invite = await _create_invite_fixtures(db_session)

    response = await test_client.post(
        f"/api/invites/accept/{invite.token}",
        json={"password": "newpassword123"},
    )
    assert response.status_code == 200
    token = response.json()["access_token"]

    notifications = await test_client.get(
        "/api/notifications",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert notifications.status_code == 200
    data = notifications.json()
    assert any(
        n["type"] == "team_joined" and n["reference_id"] == str(team.id)
        for n in data
    )


@pytest.mark.asyncio
async def test_accept_invite_returns_team_info(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Accept response should include team_id and team_name for post-invite navigation."""
    org, team, user, invite = await _create_invite_fixtures(db_session)

    response = await test_client.post(
        f"/api/invites/accept/{invite.token}",
        json={"password": "newpassword123"},
    )
    assert response.status_code == 200
    data = response.json()

    assert data["success"] is True
    assert data["access_token"] is not None
    assert data["user_id"] == str(user.id)
    assert data["team_id"] == str(team.id)
    assert data["team_name"] == "Praise Team"


@pytest.mark.asyncio
async def test_accept_invite_converts_placeholder_to_full_user(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Accepting an invite should convert the placeholder user to a full user."""
    org, team, user, invite = await _create_invite_fixtures(db_session)

    response = await test_client.post(
        f"/api/invites/accept/{invite.token}",
        json={"password": "newpassword123"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True

    # Verify user can log in with new password
    login_response = await test_client.post(
        "/api/auth/login",
        data={"username": "invitee@example.com", "password": "newpassword123"},
    )
    assert login_response.status_code == 200
    assert login_response.json()["access_token"] is not None


@pytest.mark.asyncio
async def test_accept_invite_invalid_token(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Accepting with an invalid token should fail."""
    response = await test_client.post(
        "/api/invites/accept/invalid-token-that-does-not-exist",
        json={"password": "newpassword123"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is False
    assert "invalid" in data["message"].lower() or "Invalid" in data["message"]
    assert data["access_token"] is None
    assert data["team_id"] is None
    assert data["team_name"] is None


@pytest.mark.asyncio
async def test_accept_invite_already_accepted(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Accepting an already-accepted invite should fail."""
    org, team, user, invite = await _create_invite_fixtures(db_session)

    # Accept the invite
    response = await test_client.post(
        f"/api/invites/accept/{invite.token}",
        json={"password": "newpassword123"},
    )
    assert response.status_code == 200
    assert response.json()["success"] is True

    # Try to accept again
    response2 = await test_client.post(
        f"/api/invites/accept/{invite.token}",
        json={"password": "anotherpassword"},
    )
    assert response2.status_code == 200
    data = response2.json()
    assert data["success"] is False
    assert "already" in data["message"].lower()


@pytest.mark.asyncio
async def test_accept_invite_expired(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Accepting an expired invite should fail."""
    org, team, user, invite = await _create_invite_fixtures(db_session)

    # Manually set created_at to 8 days ago to expire the invite
    invite.created_at = datetime.now(timezone.utc) - timedelta(days=8)
    db_session.add(invite)
    await db_session.commit()

    response = await test_client.post(
        f"/api/invites/accept/{invite.token}",
        json={"password": "newpassword123"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is False
    assert "expired" in data["message"].lower()


@pytest.mark.asyncio
async def test_validate_invite_token_valid(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Validating a valid token should return team and user info."""
    org, team, user, invite = await _create_invite_fixtures(db_session)

    response = await test_client.get(f"/api/invites/validate/{invite.token}")
    assert response.status_code == 200
    data = response.json()

    assert data["valid"] is True
    assert data["team_name"] == "Praise Team"
    assert data["user_name"] == "Invitee User"
    assert data["email"] == "invitee@example.com"
    assert data["expired"] is False
    assert data["already_accepted"] is False


@pytest.mark.asyncio
async def test_validate_invite_token_invalid(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Validating an invalid token should return valid=False."""
    response = await test_client.get("/api/invites/validate/nonexistent-token")
    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is False


@pytest.mark.asyncio
async def test_validate_invite_token_already_accepted(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Validating an already-accepted token should return already_accepted=True."""
    org, team, user, invite = await _create_invite_fixtures(db_session)

    # Accept the invite first
    await test_client.post(
        f"/api/invites/accept/{invite.token}",
        json={"password": "newpassword123"},
    )

    # Validate the now-accepted token
    response = await test_client.get(f"/api/invites/validate/{invite.token}")
    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is False
    assert data["already_accepted"] is True


@pytest.mark.asyncio
async def test_send_invite_requires_team_lead(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Sending an invite should require team lead permissions."""
    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    # Create a regular member (not a lead)
    member_user = User(
        email="member@example.com",
        name="Regular Member",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(member_user)
    await db_session.flush()

    org_member = OrganisationMember(
        user_id=member_user.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db_session.add(org_member)

    team_member = TeamMember(
        user_id=member_user.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(team_member)

    # Create a placeholder to invite
    placeholder = User(
        email="placeholder@example.com",
        name="Placeholder",
        password_hash=get_password_hash("placeholder"),
        is_placeholder=True,
    )
    db_session.add(placeholder)
    await db_session.flush()

    placeholder_member = TeamMember(
        user_id=placeholder.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(placeholder_member)
    await db_session.commit()

    token = create_access_token(subject=str(member_user.id))
    headers = {"Authorization": f"Bearer {token}"}

    response = await test_client.post(
        f"/api/invites/team/{team.id}/user/{placeholder.id}",
        json={"email": "real@example.com"},
        headers=headers,
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_send_invite_as_team_lead(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Team lead should be able to send an invite to a placeholder member."""
    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    lead_user = User(
        email="lead@example.com",
        name="Team Lead",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(lead_user)
    await db_session.flush()

    org_member = OrganisationMember(
        user_id=lead_user.id,
        organisation_id=org.id,
        role=OrganisationRole.ADMIN,
    )
    db_session.add(org_member)

    team_member = TeamMember(
        user_id=lead_user.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=["manage_team", "manage_members", "manage_rosters", "assign_volunteers", "send_invites", "view_responses"],
    )
    db_session.add(team_member)

    placeholder = User(
        name="New Volunteer",
        is_placeholder=True,
    )
    db_session.add(placeholder)
    await db_session.flush()

    placeholder_member = TeamMember(
        user_id=placeholder.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(placeholder_member)
    await db_session.commit()

    token = create_access_token(subject=str(lead_user.id))
    headers = {"Authorization": f"Bearer {token}"}

    response = await test_client.post(
        f"/api/invites/team/{team.id}/user/{placeholder.id}",
        json={"email": "volunteer@example.com"},
        headers=headers,
    )
    assert response.status_code == 201
    data = response.json()
    assert data["team_id"] == str(team.id)
    assert data["user_id"] == str(placeholder.id)
    assert data["email"] == "volunteer@example.com"
    assert data["token"] is not None
