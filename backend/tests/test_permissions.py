"""
Unit tests for the permissions system.
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.permissions import TeamPermission
from app.models.organisation import Organisation, OrganisationMember, OrganisationRole
from app.models.team import Team, TeamMember, TeamRole
from app.models.user import User
from app.core.security import get_password_hash


@pytest.fixture
async def setup_team_with_members(db_session: AsyncSession):
    """Setup a team with members having different permissions."""
    # Create org
    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    # Create team
    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    # Create users
    admin_user = User(
        email="admin@example.com",
        name="Admin User",
        password_hash=get_password_hash("password"),
    )
    roster_manager = User(
        email="roster@example.com",
        name="Roster Manager",
        password_hash=get_password_hash("password"),
    )
    regular_member = User(
        email="member@example.com",
        name="Regular Member",
        password_hash=get_password_hash("password"),
    )
    db_session.add_all([admin_user, roster_manager, regular_member])
    await db_session.flush()

    # Add org membership for all users
    for user in [admin_user, roster_manager, regular_member]:
        org_member = OrganisationMember(
            user_id=user.id,
            organisation_id=org.id,
            role=OrganisationRole.ADMIN
            if user == admin_user
            else OrganisationRole.MEMBER,
        )
        db_session.add(org_member)

    # Create team memberships with different permissions
    admin_membership = TeamMember(
        user_id=admin_user.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    roster_manager_membership = TeamMember(
        user_id=roster_manager.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[
            TeamPermission.MANAGE_ROSTERS,
            TeamPermission.ASSIGN_VOLUNTEERS,
            TeamPermission.VIEW_RESPONSES,
        ],
    )
    regular_membership = TeamMember(
        user_id=regular_member.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],  # No permissions
    )
    db_session.add_all(
        [admin_membership, roster_manager_membership, regular_membership]
    )
    await db_session.commit()

    return {
        "org": org,
        "team": team,
        "admin_user": admin_user,
        "roster_manager": roster_manager,
        "regular_member": regular_member,
        "admin_membership": admin_membership,
        "roster_manager_membership": roster_manager_membership,
        "regular_membership": regular_membership,
    }


@pytest.mark.asyncio
async def test_team_member_has_permission(setup_team_with_members):
    """Test TeamMember.has_permission method."""
    data = setup_team_with_members  # Don't await - pytest handles it
    admin_membership = data["admin_membership"]
    roster_manager_membership = data["roster_manager_membership"]
    regular_membership = data["regular_membership"]

    # Admin has all permissions
    assert admin_membership.has_permission(TeamPermission.MANAGE_TEAM)
    assert admin_membership.has_permission(TeamPermission.MANAGE_MEMBERS)
    assert admin_membership.has_permission(TeamPermission.MANAGE_ROSTERS)

    # Roster manager has specific permissions
    assert roster_manager_membership.has_permission(TeamPermission.MANAGE_ROSTERS)
    assert roster_manager_membership.has_permission(TeamPermission.ASSIGN_VOLUNTEERS)
    assert not roster_manager_membership.has_permission(TeamPermission.MANAGE_TEAM)
    assert not roster_manager_membership.has_permission(TeamPermission.MANAGE_MEMBERS)

    # Regular member has no permissions
    assert not regular_membership.has_permission(TeamPermission.MANAGE_TEAM)
    assert not regular_membership.has_permission(TeamPermission.MANAGE_ROSTERS)


@pytest.mark.asyncio
async def test_team_member_convenience_properties(setup_team_with_members):
    """Test TeamMember convenience properties like is_team_lead."""
    data = setup_team_with_members
    admin_membership = data["admin_membership"]
    roster_manager_membership = data["roster_manager_membership"]

    # Admin should be considered team lead
    assert admin_membership.is_team_lead

    # Roster manager is not a team lead (doesn't have manage_team)
    assert not roster_manager_membership.is_team_lead


@pytest.mark.asyncio
async def test_update_member_permissions(
    test_client: AsyncClient,
    setup_team_with_members,
):
    """Test updating a member's permissions via API."""
    from app.core.security import create_access_token

    data = setup_team_with_members
    team = data["team"]
    admin_user = data["admin_user"]
    regular_member = data["regular_member"]

    # Admin grants permissions to regular member
    token = create_access_token(subject=str(admin_user.id))
    response = await test_client.patch(
        f"/api/teams/{team.id}/members/{regular_member.id}/permissions",
        json={
            "permissions": [
                TeamPermission.MANAGE_ROSTERS,
                TeamPermission.VIEW_RESPONSES,
            ],
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    resp_data = response.json()
    assert TeamPermission.MANAGE_ROSTERS in resp_data["permissions"]
    assert TeamPermission.VIEW_RESPONSES in resp_data["permissions"]


@pytest.mark.asyncio
async def test_cannot_remove_last_manage_members(
    test_client: AsyncClient,
    setup_team_with_members,
):
    """Test that the last person with manage_members cannot remove that permission."""
    from app.core.security import create_access_token

    data = setup_team_with_members
    team = data["team"]
    admin_user = data["admin_user"]

    # Admin tries to remove manage_members from themselves (they're the only one with it)
    token = create_access_token(subject=str(admin_user.id))
    response = await test_client.patch(
        f"/api/teams/{team.id}/members/{admin_user.id}/permissions",
        json={
            "permissions": [TeamPermission.MANAGE_ROSTERS],  # Missing manage_members
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    # Should fail because they're the last one with manage_members
    assert response.status_code == 400
    assert "last member" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_team_list_includes_permissions(
    test_client: AsyncClient,
    setup_team_with_members,
):
    """Test that listing teams includes the user's permissions."""
    from app.core.security import create_access_token

    data = setup_team_with_members
    roster_manager = data["roster_manager"]

    token = create_access_token(subject=str(roster_manager.id))
    response = await test_client.get(
        "/api/teams",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    teams = response.json()
    assert len(teams) == 1
    assert "permissions" in teams[0]
    assert TeamPermission.MANAGE_ROSTERS in teams[0]["permissions"]
    assert TeamPermission.MANAGE_TEAM not in teams[0]["permissions"]
