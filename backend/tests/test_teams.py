"""
Unit tests for the team service and API endpoints.
"""
import pytest
from datetime import date
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.permissions import TeamPermission
from app.models.organisation import Organisation, OrganisationMember, OrganisationRole
from app.models.team import Team, TeamMember, TeamRole
from app.models.user import User
from app.models.roster import Roster, RosterEvent, EventAssignment, RecurrencePattern
from app.core.security import get_password_hash, create_access_token
from app.services.team import TeamService


@pytest.fixture
async def org_with_admin(db_session: AsyncSession):
    """Setup an organisation with an admin user."""
    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    admin = User(
        email="admin@example.com",
        name="Admin User",
        password_hash=get_password_hash("password"),
    )
    db_session.add(admin)
    await db_session.flush()

    org_member = OrganisationMember(
        user_id=admin.id,
        organisation_id=org.id,
        role=OrganisationRole.ADMIN,
    )
    db_session.add(org_member)
    await db_session.commit()

    return {"org": org, "admin": admin}


@pytest.mark.asyncio
async def test_create_team_service(db_session: AsyncSession, org_with_admin):
    """Test creating a team through the service."""
    data = org_with_admin
    org = data["org"]
    admin = data["admin"]

    from app.schemas.team import TeamCreate

    service = TeamService(db_session)
    team_data = TeamCreate(name="Media Team", organisation_id=org.id)
    team = await service.create_team(team_data, admin.id)

    assert team.name == "Media Team"
    assert team.organisation_id == org.id

    # Creator should be a team lead with permissions
    membership = await service.get_team_membership(admin.id, team.id)
    assert membership is not None
    assert membership.role == TeamRole.LEAD
    assert TeamPermission.MANAGE_TEAM in membership.permissions


@pytest.mark.asyncio
async def test_get_team(db_session: AsyncSession, org_with_admin):
    """Test getting a team by ID."""
    data = org_with_admin
    org = data["org"]

    team = Team(name="Sound Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.commit()

    service = TeamService(db_session)
    result = await service.get_team(team.id)

    assert result is not None
    assert result.name == "Sound Team"


@pytest.mark.asyncio
async def test_get_team_not_found(db_session: AsyncSession):
    """Test getting a non-existent team."""
    import uuid

    service = TeamService(db_session)
    result = await service.get_team(uuid.uuid4())

    assert result is None


@pytest.mark.asyncio
async def test_get_organisation_teams(db_session: AsyncSession, org_with_admin):
    """Test getting all teams in an organisation."""
    data = org_with_admin
    org = data["org"]

    team1 = Team(name="Media Team", organisation_id=org.id)
    team2 = Team(name="Sound Team", organisation_id=org.id)
    db_session.add_all([team1, team2])
    await db_session.commit()

    service = TeamService(db_session)
    teams = await service.get_organisation_teams(org.id)

    assert len(teams) == 2
    team_names = {t.name for t in teams}
    assert "Media Team" in team_names
    assert "Sound Team" in team_names


@pytest.mark.asyncio
async def test_update_team(db_session: AsyncSession, org_with_admin):
    """Test updating a team."""
    data = org_with_admin
    org = data["org"]

    team = Team(name="Old Name", organisation_id=org.id)
    db_session.add(team)
    await db_session.commit()

    from app.schemas.team import TeamUpdate

    service = TeamService(db_session)
    updated = await service.update_team(team.id, TeamUpdate(name="New Name"))

    assert updated is not None
    assert updated.name == "New Name"


@pytest.mark.asyncio
async def test_delete_team(db_session: AsyncSession, org_with_admin):
    """Test deleting a team."""
    data = org_with_admin
    org = data["org"]

    team = Team(name="To Delete", organisation_id=org.id)
    db_session.add(team)
    await db_session.commit()

    service = TeamService(db_session)
    result = await service.delete_team(team.id)
    await db_session.commit()

    assert result is True
    assert await service.get_team(team.id) is None


@pytest.mark.asyncio
async def test_add_member_to_team(db_session: AsyncSession, org_with_admin):
    """Test adding a member to a team."""
    data = org_with_admin
    org = data["org"]
    admin = data["admin"]

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)

    new_user = User(
        email="member@example.com",
        name="New Member",
        password_hash=get_password_hash("password"),
    )
    db_session.add(new_user)
    await db_session.commit()

    service = TeamService(db_session)
    membership = await service.add_member(
        team.id,
        new_user.id,
        TeamRole.MEMBER,
        permissions=[TeamPermission.VIEW_RESPONSES],
    )

    assert membership is not None
    assert membership.role == TeamRole.MEMBER
    assert TeamPermission.VIEW_RESPONSES in membership.permissions


@pytest.mark.asyncio
async def test_add_member_already_exists(db_session: AsyncSession, org_with_admin):
    """Test adding a member who is already in the team."""
    data = org_with_admin
    org = data["org"]
    admin = data["admin"]

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    membership = TeamMember(
        user_id=admin.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    db_session.add(membership)
    await db_session.commit()

    service = TeamService(db_session)
    # Note: add_member takes (team_id, user_id, role)
    result = await service.add_member(team.id, admin.id, TeamRole.MEMBER)

    # Should return existing membership, not create a new one
    assert result is not None


@pytest.mark.asyncio
async def test_remove_member_from_team(db_session: AsyncSession, org_with_admin):
    """Test removing a member from a team."""
    data = org_with_admin
    org = data["org"]
    admin = data["admin"]

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    membership = TeamMember(
        user_id=admin.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    db_session.add(membership)
    await db_session.commit()

    service = TeamService(db_session)
    result = await service.remove_member(team.id, admin.id)
    await db_session.commit()

    assert result is True
    assert await service.get_team_membership(admin.id, team.id) is None


@pytest.mark.asyncio
async def test_check_permission(db_session: AsyncSession, org_with_admin):
    """Test checking user permissions."""
    data = org_with_admin
    org = data["org"]
    admin = data["admin"]

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    membership = TeamMember(
        user_id=admin.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[TeamPermission.MANAGE_ROSTERS],
    )
    db_session.add(membership)
    await db_session.commit()

    service = TeamService(db_session)

    assert await service.check_permission(admin.id, team.id, TeamPermission.MANAGE_ROSTERS) is True
    assert await service.check_permission(admin.id, team.id, TeamPermission.MANAGE_TEAM) is False


@pytest.mark.asyncio
async def test_is_team_lead(db_session: AsyncSession, org_with_admin):
    """Test checking if user is a team lead."""
    data = org_with_admin
    org = data["org"]
    admin = data["admin"]

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    lead_membership = TeamMember(
        user_id=admin.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    db_session.add(lead_membership)

    member_user = User(
        email="member@example.com",
        name="Regular Member",
        password_hash=get_password_hash("password"),
    )
    db_session.add(member_user)
    await db_session.flush()

    member_membership = TeamMember(
        user_id=member_user.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(member_membership)
    await db_session.commit()

    service = TeamService(db_session)

    assert await service.is_team_lead(admin.id, team.id) is True
    assert await service.is_team_lead(member_user.id, team.id) is False


@pytest.mark.asyncio
async def test_get_user_teams(db_session: AsyncSession, org_with_admin):
    """Test getting all teams a user belongs to."""
    data = org_with_admin
    org = data["org"]
    admin = data["admin"]

    team1 = Team(name="Media Team", organisation_id=org.id)
    team2 = Team(name="Sound Team", organisation_id=org.id)
    db_session.add_all([team1, team2])
    await db_session.flush()

    membership1 = TeamMember(
        user_id=admin.id,
        team_id=team1.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    membership2 = TeamMember(
        user_id=admin.id,
        team_id=team2.id,
        role=TeamRole.MEMBER,
        permissions=[TeamPermission.VIEW_RESPONSES],
    )
    db_session.add_all([membership1, membership2])
    await db_session.commit()

    service = TeamService(db_session)
    teams = await service.get_user_teams(admin.id)

    assert len(teams) == 2


@pytest.mark.asyncio
async def test_update_member_permissions(db_session: AsyncSession, org_with_admin):
    """Test updating a member's permissions."""
    data = org_with_admin
    org = data["org"]
    admin = data["admin"]

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    membership = TeamMember(
        user_id=admin.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(membership)
    await db_session.commit()

    service = TeamService(db_session)
    updated = await service.update_member_permissions(
        team.id,
        admin.id,
        [TeamPermission.MANAGE_ROSTERS, TeamPermission.ASSIGN_VOLUNTEERS],
    )

    assert updated is not None
    assert TeamPermission.MANAGE_ROSTERS in updated.permissions
    assert TeamPermission.ASSIGN_VOLUNTEERS in updated.permissions


@pytest.mark.asyncio
async def test_count_members_with_permission(db_session: AsyncSession, org_with_admin):
    """Test counting members with a specific permission."""
    data = org_with_admin
    org = data["org"]
    admin = data["admin"]

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    # Admin with all permissions
    membership1 = TeamMember(
        user_id=admin.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    db_session.add(membership1)

    # Member with limited permissions
    member = User(
        email="member@example.com",
        name="Member",
        password_hash=get_password_hash("password"),
    )
    db_session.add(member)
    await db_session.flush()

    membership2 = TeamMember(
        user_id=member.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[TeamPermission.VIEW_RESPONSES],
    )
    db_session.add(membership2)
    await db_session.commit()

    service = TeamService(db_session)

    # Both should have view_responses (admin has all)
    count = await service.count_members_with_permission(team.id, TeamPermission.VIEW_RESPONSES)
    assert count == 2

    # Only admin should have manage_team
    count = await service.count_members_with_permission(team.id, TeamPermission.MANAGE_TEAM)
    assert count == 1


@pytest.mark.asyncio
async def test_create_team_api(test_client: AsyncClient, db_session: AsyncSession, org_with_admin):
    """Test creating a team via API endpoint."""
    data = org_with_admin
    org = data["org"]
    admin = data["admin"]

    token = create_access_token(subject=str(admin.id))
    response = await test_client.post(
        "/api/teams",
        json={
            "name": "New Team",
            "organisation_id": str(org.id),
        },
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 201
    resp_data = response.json()
    assert resp_data["name"] == "New Team"


@pytest.mark.asyncio
async def test_list_teams_api(test_client: AsyncClient, db_session: AsyncSession, org_with_admin):
    """Test listing teams via API endpoint."""
    data = org_with_admin
    org = data["org"]
    admin = data["admin"]

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    membership = TeamMember(
        user_id=admin.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    db_session.add(membership)
    await db_session.commit()

    token = create_access_token(subject=str(admin.id))
    response = await test_client.get(
        "/api/teams",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    teams = response.json()
    assert len(teams) >= 1
    assert any(t["name"] == "Media Team" for t in teams)


@pytest.mark.asyncio
async def test_list_member_assignments_api(
    test_client: AsyncClient, db_session: AsyncSession, org_with_admin
):
    """Test listing assignments for a specific team member with permissions."""
    data = org_with_admin
    org = data["org"]
    admin = data["admin"]

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    admin_membership = TeamMember(
        user_id=admin.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=[TeamPermission.VIEW_RESPONSES],
    )
    db_session.add(admin_membership)

    member = User(
        email="member@example.com",
        name="Member User",
        password_hash=get_password_hash("password"),
    )
    db_session.add(member)
    await db_session.flush()

    member_membership = TeamMember(
        user_id=member.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(member_membership)

    roster = Roster(
        name="Sunday Service",
        team_id=team.id,
        recurrence_pattern=RecurrencePattern.WEEKLY,
        recurrence_day=0,
        slots_needed=2,
        start_date=date(2024, 1, 1),
    )
    db_session.add(roster)
    await db_session.flush()

    event = RosterEvent(
        roster_id=roster.id,
        date=date(2024, 1, 7),
    )
    db_session.add(event)
    await db_session.flush()

    assignment = EventAssignment(
        event_id=event.id,
        user_id=member.id,
    )
    db_session.add(assignment)

    other_team = Team(name="Other Team", organisation_id=org.id)
    db_session.add(other_team)
    await db_session.flush()

    other_roster = Roster(
        name="Other Roster",
        team_id=other_team.id,
        recurrence_pattern=RecurrencePattern.WEEKLY,
        recurrence_day=1,
        slots_needed=1,
        start_date=date(2024, 1, 1),
    )
    db_session.add(other_roster)
    await db_session.flush()

    other_event = RosterEvent(
        roster_id=other_roster.id,
        date=date(2024, 1, 8),
    )
    db_session.add(other_event)
    await db_session.flush()

    other_assignment = EventAssignment(
        event_id=other_event.id,
        user_id=member.id,
    )
    db_session.add(other_assignment)
    await db_session.commit()

    token = create_access_token(subject=str(admin.id))
    response = await test_client.get(
        f"/api/teams/{team.id}/members/{member.id}/assignments",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assignments = response.json()
    assert len(assignments) == 1
    assert assignments[0]["roster_name"] == "Sunday Service"


@pytest.mark.asyncio
async def test_list_member_assignments_requires_permission(
    test_client: AsyncClient, db_session: AsyncSession, org_with_admin
):
    """Test listing assignments for a team member without view_responses permission."""
    data = org_with_admin
    org = data["org"]
    admin = data["admin"]

    team = Team(name="Media Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    membership = TeamMember(
        user_id=admin.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(membership)
    await db_session.commit()

    token = create_access_token(subject=str(admin.id))
    response = await test_client.get(
        f"/api/teams/{team.id}/members/{admin.id}/assignments",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403
