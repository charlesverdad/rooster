"""
Integration tests for roster and assignment functionality.
"""
import uuid
from datetime import date, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.permissions import TeamPermission
from app.models.organisation import Organisation, OrganisationMember, OrganisationRole
from app.core.security import create_access_token, get_password_hash
from app.models.roster import Assignment, AssignmentMode, RecurrencePattern, Roster, RosterEvent
from app.models.team import Team, TeamMember, TeamRole
from app.models.user import User


@pytest.mark.asyncio
async def test_create_roster(client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict):
    """Test creating a roster."""
    # Create org, team
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()
    
    org_member = OrganisationMember(
        user_id=test_user.id,
        organisation_id=org.id,
        role=OrganisationRole.ADMIN,
    )
    db.add(org_member)
    
    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()
    
    team_member = TeamMember(
        user_id=test_user.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    db.add(team_member)
    await db.commit()

    # Create roster
    start_date = date.today()
    response = await client.post(
        "/api/rosters",
        json={
            "name": "Sunday Service",
            "team_id": str(team.id),
            "recurrence_pattern": "weekly",
            "recurrence_day": 6,  # Sunday
            "slots_needed": 2,
            "assignment_mode": "manual",
            "start_date": start_date.isoformat(),
        },
        headers=auth_headers,
    )

    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Sunday Service"
    assert data["recurrence_pattern"] == "weekly"
    assert data["slots_needed"] == 2


@pytest.mark.asyncio
async def test_create_assignment(client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict):
    """Test creating an assignment."""
    # Setup
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()
    
    org_member = OrganisationMember(
        user_id=test_user.id,
        organisation_id=org.id,
        role=OrganisationRole.ADMIN,
    )
    db.add(org_member)
    
    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()
    
    team_member = TeamMember(
        user_id=test_user.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    db.add(team_member)

    roster = Roster(
        name="Sunday Service",
        team_id=team.id,
        recurrence_pattern=RecurrencePattern.WEEKLY,
        recurrence_day=6,
        slots_needed=2,
        assignment_mode=AssignmentMode.MANUAL,
        start_date=date.today(),
    )
    db.add(roster)
    await db.commit()

    # Create assignment
    target_date = date.today() + timedelta(days=7)
    response = await client.post(
        "/api/rosters/assignments",
        json={
            "roster_id": str(roster.id),
            "user_id": str(test_user.id),
            "date": target_date.isoformat(),
        },
        headers=auth_headers,
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["roster_id"] == str(roster.id)
    assert data["user_id"] == str(test_user.id)
    assert data["status"] == "pending"


@pytest.mark.asyncio
async def test_list_my_assignments(client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict):
    """Test listing user's assignments."""
    # Setup
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()
    
    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()
    
    roster = Roster(
        name="Sunday Service",
        team_id=team.id,
        recurrence_pattern=RecurrencePattern.WEEKLY,
        recurrence_day=6,
        slots_needed=1,
        assignment_mode=AssignmentMode.MANUAL,
        start_date=date.today(),
    )
    db.add(roster)
    await db.flush()

    # Create assignments
    assignment1 = Assignment(
        roster_id=roster.id,
        user_id=test_user.id,
        date=date.today() + timedelta(days=7),
    )
    assignment2 = Assignment(
        roster_id=roster.id,
        user_id=test_user.id,
        date=date.today() + timedelta(days=14),
    )
    db.add(assignment1)
    db.add(assignment2)
    await db.commit()
    
    # List assignments
    response = await client.get(
        "/api/rosters/assignments/my",
        headers=auth_headers,
    )
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["roster_name"] == "Sunday Service"


@pytest.mark.asyncio
async def test_member_self_assign_to_event(client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict):
    """Test that a regular team member can self-assign to a roster event."""
    # Create a second user who is the team lead
    lead_user = User(
        email="lead@example.com",
        name="Lead User",
        password_hash=get_password_hash("testpassword"),
    )
    db.add(lead_user)
    await db.flush()

    # Setup org and team
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    org_member_lead = OrganisationMember(
        user_id=lead_user.id,
        organisation_id=org.id,
        role=OrganisationRole.ADMIN,
    )
    org_member_test = OrganisationMember(
        user_id=test_user.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db.add(org_member_lead)
    db.add(org_member_test)

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    # Lead is a team lead; test_user is a regular member
    team_lead = TeamMember(
        user_id=lead_user.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    team_member = TeamMember(
        user_id=test_user.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db.add(team_lead)
    db.add(team_member)

    roster = Roster(
        name="Sunday Service",
        team_id=team.id,
        recurrence_pattern=RecurrencePattern.WEEKLY,
        recurrence_day=6,
        slots_needed=2,
        assignment_mode=AssignmentMode.MANUAL,
        start_date=date.today(),
    )
    db.add(roster)
    await db.flush()

    event = RosterEvent(
        roster_id=roster.id,
        date=date.today() + timedelta(days=7),
    )
    db.add(event)
    await db.commit()

    # Self-assign: member assigns themselves (should succeed)
    response = await client.post(
        f"/api/rosters/events/{event.id}/assignments",
        json={
            "event_id": str(event.id),
            "user_id": str(test_user.id),
        },
        headers=auth_headers,
    )

    assert response.status_code == 201
    data = response.json()
    assert data["user_id"] == str(test_user.id)
    assert data["event_id"] == str(event.id)
    assert data["status"] == "confirmed"  # Self-volunteers are auto-confirmed


@pytest.mark.asyncio
async def test_member_cannot_assign_other_user(client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict):
    """Test that a regular team member cannot assign another user to an event."""
    # Create another user
    other_user = User(
        email="other@example.com",
        name="Other User",
        password_hash=get_password_hash("testpassword"),
    )
    db.add(other_user)
    await db.flush()

    # Setup org and team
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    org_member_test = OrganisationMember(
        user_id=test_user.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    org_member_other = OrganisationMember(
        user_id=other_user.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db.add(org_member_test)
    db.add(org_member_other)

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    # Both are regular members (no lead role)
    team_member_test = TeamMember(
        user_id=test_user.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    team_member_other = TeamMember(
        user_id=other_user.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db.add(team_member_test)
    db.add(team_member_other)

    roster = Roster(
        name="Sunday Service",
        team_id=team.id,
        recurrence_pattern=RecurrencePattern.WEEKLY,
        recurrence_day=6,
        slots_needed=2,
        assignment_mode=AssignmentMode.MANUAL,
        start_date=date.today(),
    )
    db.add(roster)
    await db.flush()

    event = RosterEvent(
        roster_id=roster.id,
        date=date.today() + timedelta(days=7),
    )
    db.add(event)
    await db.commit()

    # Try to assign another user (should fail with 403)
    response = await client.post(
        f"/api/rosters/events/{event.id}/assignments",
        json={
            "event_id": str(event.id),
            "user_id": str(other_user.id),
        },
        headers=auth_headers,
    )

    assert response.status_code == 403
    assert "Not authorized" in response.json()["detail"]


@pytest.mark.asyncio
async def test_event_response_includes_assignments(client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict):
    """Test that event list responses include assignment summaries."""
    # Setup org, team, roster, event
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    org_member = OrganisationMember(
        user_id=test_user.id,
        organisation_id=org.id,
        role=OrganisationRole.ADMIN,
    )
    db.add(org_member)

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    team_member = TeamMember(
        user_id=test_user.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    db.add(team_member)

    roster = Roster(
        name="Sunday Service",
        team_id=team.id,
        recurrence_pattern=RecurrencePattern.WEEKLY,
        recurrence_day=6,
        slots_needed=2,
        assignment_mode=AssignmentMode.MANUAL,
        start_date=date.today(),
    )
    db.add(roster)
    await db.flush()

    event = RosterEvent(
        roster_id=roster.id,
        date=date.today() + timedelta(days=7),
    )
    db.add(event)
    await db.commit()

    # Assign test_user to the event
    assign_response = await client.post(
        f"/api/rosters/events/{event.id}/assignments",
        json={
            "event_id": str(event.id),
            "user_id": str(test_user.id),
        },
        headers=auth_headers,
    )
    assert assign_response.status_code == 201

    # Fetch roster events and verify assignments field
    response = await client.get(
        f"/api/rosters/{roster.id}/events",
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    # Find our event
    matching = [e for e in data if e["id"] == str(event.id)]
    assert len(matching) == 1
    event_data = matching[0]
    assert "assignments" in event_data
    assert len(event_data["assignments"]) == 1
    assert event_data["assignments"][0]["user_name"] == "Test User"
    assert event_data["assignments"][0]["status"] == "confirmed"  # Self-assign is auto-confirmed
