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
        n["type"] == "team_joined" and n["reference_id"] == str(team.id) for n in data
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
        permissions=[
            "manage_team",
            "manage_members",
            "manage_rosters",
            "assign_volunteers",
            "send_invites",
            "view_responses",
        ],
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


@pytest.mark.asyncio
async def test_accept_invite_creates_org_membership(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Accepting an invite should create an org membership so the user can access team endpoints."""
    org, team, user, invite = await _create_invite_fixtures(db_session)

    # Verify placeholder has no org membership
    from app.models.organisation import OrganisationMember
    from sqlalchemy import select

    result = await db_session.execute(
        select(OrganisationMember).where(
            OrganisationMember.user_id == user.id,
            OrganisationMember.organisation_id == org.id,
        )
    )
    assert result.scalar_one_or_none() is None

    # Accept the invite
    response = await test_client.post(
        f"/api/invites/accept/{invite.token}",
        json={"password": "newpassword123"},
    )
    assert response.status_code == 200
    assert response.json()["success"] is True
    token = response.json()["access_token"]

    # Verify the user can now access the team detail endpoint (requires org membership)
    team_response = await test_client.get(
        f"/api/teams/{team.id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert team_response.status_code == 200
    assert team_response.json()["name"] == "Praise Team"


@pytest.mark.asyncio
async def test_accept_invite_user_can_view_team_members(
    test_client: AsyncClient, db_session: AsyncSession
):
    """After accepting invite, regular member should be able to view team members."""
    org, team, user, invite = await _create_invite_fixtures(db_session)

    response = await test_client.post(
        f"/api/invites/accept/{invite.token}",
        json={"password": "newpassword123"},
    )
    assert response.status_code == 200
    token = response.json()["access_token"]

    members_response = await test_client.get(
        f"/api/teams/{team.id}/members",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert members_response.status_code == 200
    members = members_response.json()
    assert len(members) >= 1
    assert any(m["user_name"] == "Invitee User" for m in members)


# =============================================================================
# Invite to Already-Registered User Tests
# =============================================================================


async def _create_registered_user_invite_fixtures(db_session: AsyncSession):
    """Helper to create fixtures with a placeholder and a separately-registered user.

    The placeholder has no email (realistic: admin creates "John Doe" placeholder,
    then invites to john@example.com which belongs to an existing user).
    """
    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    # Team lead
    lead = User(
        email="lead@example.com",
        name="Team Lead",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(lead)
    await db_session.flush()

    org_admin = OrganisationMember(
        user_id=lead.id,
        organisation_id=org.id,
        role=OrganisationRole.ADMIN,
    )
    db_session.add(org_admin)

    lead_membership = TeamMember(
        user_id=lead.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=[
            "manage_team",
            "manage_members",
            "manage_rosters",
            "assign_volunteers",
            "send_invites",
            "view_responses",
        ],
    )
    db_session.add(lead_membership)

    # Placeholder user (no email — hasn't been invited yet)
    placeholder = User(
        name="John Doe",
        is_placeholder=True,
    )
    db_session.add(placeholder)
    await db_session.flush()

    placeholder_membership = TeamMember(
        user_id=placeholder.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(placeholder_membership)

    # Already-registered user with the email we'll invite to
    registered = User(
        email="john@example.com",
        name="John Smith",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(registered)
    await db_session.flush()

    reg_org_member = OrganisationMember(
        user_id=registered.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db_session.add(reg_org_member)
    await db_session.commit()

    return org, team, lead, placeholder, registered


@pytest.mark.asyncio
async def test_send_invite_to_registered_user_merges_placeholder(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Sending invite to an email belonging to a registered user should merge the placeholder."""
    (
        org,
        team,
        lead,
        placeholder,
        registered,
    ) = await _create_registered_user_invite_fixtures(db_session)

    token = create_access_token(subject=str(lead.id))
    headers = {"Authorization": f"Bearer {token}"}

    response = await test_client.post(
        f"/api/invites/team/{team.id}/user/{placeholder.id}",
        json={"email": "john@example.com"},
        headers=headers,
    )
    assert response.status_code == 201
    data = response.json()
    # The invite should be auto-accepted
    assert data["accepted_at"] is not None


@pytest.mark.asyncio
async def test_send_invite_to_registered_user_creates_notification(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Sending invite to registered user's email should notify them."""
    (
        org,
        team,
        lead,
        placeholder,
        registered,
    ) = await _create_registered_user_invite_fixtures(db_session)

    lead_token = create_access_token(subject=str(lead.id))
    lead_headers = {"Authorization": f"Bearer {lead_token}"}

    await test_client.post(
        f"/api/invites/team/{team.id}/user/{placeholder.id}",
        json={"email": "john@example.com"},
        headers=lead_headers,
    )

    # Check notifications for the registered user
    reg_token = create_access_token(subject=str(registered.id))
    reg_headers = {"Authorization": f"Bearer {reg_token}"}

    notifications = await test_client.get(
        "/api/notifications",
        headers=reg_headers,
    )
    assert notifications.status_code == 200
    data = notifications.json()
    assert any(
        n["type"] == "team_invite" and n["reference_id"] == str(team.id) for n in data
    )


@pytest.mark.asyncio
async def test_send_invite_to_registered_user_creates_org_membership(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Inviting a registered user who has no org membership should create one so they can access team endpoints."""
    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    # Team lead (has org + team membership)
    lead = User(
        email="lead@example.com",
        name="Team Lead",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(lead)
    await db_session.flush()

    db_session.add(
        OrganisationMember(
            user_id=lead.id,
            organisation_id=org.id,
            role=OrganisationRole.ADMIN,
        )
    )
    db_session.add(
        TeamMember(
            user_id=lead.id,
            team_id=team.id,
            role=TeamRole.LEAD,
            permissions=[
                "manage_team",
                "manage_members",
                "send_invites",
                "view_responses",
            ],
        )
    )

    # Placeholder (no email, no org membership — realistic)
    placeholder = User(name="John Doe", is_placeholder=True)
    db_session.add(placeholder)
    await db_session.flush()

    db_session.add(
        TeamMember(
            user_id=placeholder.id,
            team_id=team.id,
            role=TeamRole.MEMBER,
            permissions=[],
        )
    )

    # Registered user — deliberately NO org membership
    registered = User(
        email="john@example.com",
        name="John Smith",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(registered)
    await db_session.commit()

    # Send invite as lead — this should auto-accept and create org membership
    lead_token = create_access_token(subject=str(lead.id))
    response = await test_client.post(
        f"/api/invites/team/{team.id}/user/{placeholder.id}",
        json={"email": "john@example.com"},
        headers={"Authorization": f"Bearer {lead_token}"},
    )
    assert response.status_code == 201

    # Registered user should now be able to access the team (requires org membership)
    reg_token = create_access_token(subject=str(registered.id))
    reg_headers = {"Authorization": f"Bearer {reg_token}"}

    team_response = await test_client.get(
        f"/api/teams/{team.id}",
        headers=reg_headers,
    )
    assert team_response.status_code == 200
    assert team_response.json()["name"] == "Media Team"

    members_response = await test_client.get(
        f"/api/teams/{team.id}/members",
        headers=reg_headers,
    )
    assert members_response.status_code == 200


async def _create_invite_fixtures_no_email(db_session: AsyncSession):
    """Helper to create invite fixtures where the placeholder has a different email from the invite.

    This simulates: placeholder created with no email, then invited to a specific email.
    We use a unique placeholder email to avoid unique constraint issues.
    """
    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    team = Team(name="Praise Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    # Placeholder starts with no email (realistic flow)
    user = User(
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

    # Invite targets an email — create_invite would normally set placeholder.email,
    # but we set it here to "target_invite@example.com" to simulate that step
    invite_email = "target_invite@example.com"
    user.email = invite_email
    invite = Invite(
        team_id=team.id,
        user_id=user.id,
        email=invite_email,
    )
    db_session.add(invite)
    await db_session.commit()

    return org, team, user, invite


@pytest.mark.asyncio
async def test_validate_token_returns_user_is_registered(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Validate token should return user_is_registered when a registered user has the invite email."""
    org, team, placeholder, invite = await _create_invite_fixtures_no_email(db_session)

    # Create a registered user with the same email as the invite
    registered = User(
        email="target_invite@example.com",
        name="Already Registered",
        password_hash=get_password_hash("password123"),
        is_placeholder=False,
    )
    # We need to clear the placeholder's email first to avoid unique conflict
    placeholder.email = None
    await db_session.flush()
    db_session.add(registered)
    await db_session.commit()

    # Update invite email is still target_invite@example.com
    response = await test_client.get(f"/api/invites/validate/{invite.token}")
    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is True
    assert data["user_is_registered"] is True


@pytest.mark.asyncio
async def test_validate_token_unregistered_user_is_registered_false(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Validate token should return user_is_registered=False when no registered user matches."""
    org, team, user, invite = await _create_invite_fixtures(db_session)

    response = await test_client.get(f"/api/invites/validate/{invite.token}")
    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is True
    assert data["user_is_registered"] is False


@pytest.mark.asyncio
async def test_accept_invite_without_password_for_registered_user(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Accepting an invite without password should work when email matches a registered user."""
    org, team, placeholder, invite = await _create_invite_fixtures_no_email(db_session)

    # Create a registered user with the invite email, clearing placeholder email first
    placeholder.email = None
    await db_session.flush()

    registered = User(
        email="target_invite@example.com",
        name="Already Registered",
        password_hash=get_password_hash("password123"),
        is_placeholder=False,
    )
    db_session.add(registered)
    await db_session.commit()

    response = await test_client.post(
        f"/api/invites/accept/{invite.token}",
        json={},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["access_token"] is not None
    assert data["team_id"] == str(team.id)
    assert data["team_name"] == "Praise Team"


@pytest.mark.asyncio
async def test_accept_invite_without_password_for_new_user_fails(
    test_client: AsyncClient, db_session: AsyncSession
):
    """Accepting an invite without password should fail when the user is new (no registered match)."""
    org, team, user, invite = await _create_invite_fixtures(db_session)

    response = await test_client.post(
        f"/api/invites/accept/{invite.token}",
        json={},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is False
    assert "password" in data["message"].lower()
