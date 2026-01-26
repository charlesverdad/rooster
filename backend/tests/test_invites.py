import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, get_password_hash
from app.models.invite import Invite
from app.models.organisation import Organisation
from app.models.team import Team, TeamMember, TeamRole
from app.models.user import User


@pytest.mark.asyncio
async def test_accept_invite_creates_team_notification(
    test_client: AsyncClient, db_session: AsyncSession
):
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
