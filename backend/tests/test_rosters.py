"""
Integration tests for roster and assignment functionality.
"""

from datetime import date, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.permissions import TeamPermission
from app.models.organisation import Organisation, OrganisationMember, OrganisationRole
from app.core.security import get_password_hash
from app.models.roster import (
    Assignment,
    AssignmentMode,
    RecurrencePattern,
    Roster,
    RosterEvent,
)
from app.models.team import Team, TeamMember, TeamRole
from app.models.user import User


@pytest.mark.asyncio
async def test_create_roster(
    client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict
):
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
async def test_create_assignment(
    client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict
):
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
async def test_list_my_assignments(
    client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict
):
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
async def test_member_self_assign_to_event(
    client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict
):
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
async def test_member_cannot_assign_other_user(
    client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict
):
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
async def test_event_response_includes_assignments(
    client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict
):
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
    assert (
        event_data["assignments"][0]["status"] == "confirmed"
    )  # Self-assign is auto-confirmed


@pytest.mark.asyncio
async def test_get_suggestions(
    client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict
):
    """Test that team lead can get assignment suggestions."""
    from app.models.availability import Unavailability
    from app.models.roster import EventAssignment

    # Setup org and team
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

    # test_user is team lead
    team_lead = TeamMember(
        user_id=test_user.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    db.add(team_lead)

    # Create additional team members
    member1 = User(
        email="member1@example.com",
        name="Member One",
        password_hash=get_password_hash("testpassword"),
    )
    member2 = User(
        email="member2@example.com",
        name="Member Two",
        password_hash=get_password_hash("testpassword"),
    )
    member3 = User(
        email="member3@example.com",
        name="Member Three",
        password_hash=get_password_hash("testpassword"),
    )
    db.add(member1)
    db.add(member2)
    db.add(member3)
    await db.flush()

    org_member1 = OrganisationMember(
        user_id=member1.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    org_member2 = OrganisationMember(
        user_id=member2.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    org_member3 = OrganisationMember(
        user_id=member3.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db.add(org_member1)
    db.add(org_member2)
    db.add(org_member3)

    team_member1 = TeamMember(
        user_id=member1.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    team_member2 = TeamMember(
        user_id=member2.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    team_member3 = TeamMember(
        user_id=member3.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db.add(team_member1)
    db.add(team_member2)
    db.add(team_member3)

    # Create roster and events
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

    # Create past event with assignment for member1 (recent)
    past_event = RosterEvent(
        roster_id=roster.id,
        date=date.today() - timedelta(days=3),
    )
    db.add(past_event)
    await db.flush()

    past_assignment = EventAssignment(
        event_id=past_event.id,
        user_id=member1.id,
        status=AssignmentStatus.CONFIRMED,
    )
    db.add(past_assignment)

    # Create future event to get suggestions for
    future_event = RosterEvent(
        roster_id=roster.id,
        date=date.today() + timedelta(days=7),
    )
    db.add(future_event)
    await db.flush()

    # Mark member3 as unavailable for the future event date
    unavailability = Unavailability(
        user_id=member3.id,
        date=future_event.date,
        reason="On vacation",
    )
    db.add(unavailability)

    await db.commit()

    # Get suggestions as team lead
    response = await client.get(
        f"/api/rosters/events/{future_event.id}/suggestions",
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert "suggestions" in data
    suggestions = data["suggestions"]

    # Should get suggestions (member2, member1, test_user)
    # member3 should be excluded (unavailable)
    assert len(suggestions) >= 2

    # member2 should rank higher than member1 (member1 was recently assigned)
    suggestion_user_ids = [s["user_id"] for s in suggestions]

    # member2 should be in suggestions
    assert str(member2.id) in suggestion_user_ids

    # member3 should NOT be in suggestions (unavailable)
    assert str(member3.id) not in suggestion_user_ids

    # Each suggestion should have required fields
    for suggestion in suggestions:
        assert "user_id" in suggestion
        assert "user_name" in suggestion
        assert "score" in suggestion
        assert "reasoning" in suggestion


@pytest.mark.asyncio
async def test_get_suggestions_non_team_lead_forbidden(
    client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict
):
    """Test that non-team-lead cannot access suggestions endpoint."""
    # Setup org and team
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    org_member = OrganisationMember(
        user_id=test_user.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db.add(org_member)

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    # test_user is regular member (not lead)
    team_member = TeamMember(
        user_id=test_user.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
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

    # Try to get suggestions as regular member
    response = await client.get(
        f"/api/rosters/events/{event.id}/suggestions",
        headers=auth_headers,
    )

    assert response.status_code == 403
    assert "Not authorized" in response.json()["detail"]


@pytest.mark.asyncio
async def test_get_suggestions_respects_availability(
    client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict
):
    """Test that suggestions exclude unavailable members."""
    from app.models.availability import Unavailability

    # Setup org and team
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

    team_lead = TeamMember(
        user_id=test_user.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    db.add(team_lead)

    # Create two members
    available_member = User(
        email="available@example.com",
        name="Available Member",
        password_hash=get_password_hash("testpassword"),
    )
    unavailable_member = User(
        email="unavailable@example.com",
        name="Unavailable Member",
        password_hash=get_password_hash("testpassword"),
    )
    db.add(available_member)
    db.add(unavailable_member)
    await db.flush()

    org_member_available = OrganisationMember(
        user_id=available_member.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    org_member_unavailable = OrganisationMember(
        user_id=unavailable_member.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db.add(org_member_available)
    db.add(org_member_unavailable)

    team_member_available = TeamMember(
        user_id=available_member.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    team_member_unavailable = TeamMember(
        user_id=unavailable_member.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db.add(team_member_available)
    db.add(team_member_unavailable)

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
    await db.flush()

    # Mark unavailable_member as unavailable for the event date
    unavailability = Unavailability(
        user_id=unavailable_member.id,
        date=event.date,
        reason="On vacation",
    )
    db.add(unavailability)
    await db.commit()

    # Get suggestions
    response = await client.get(
        f"/api/rosters/events/{event.id}/suggestions",
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    suggestions = data["suggestions"]

    suggestion_user_ids = [s["user_id"] for s in suggestions]

    # Available member should be in suggestions
    assert str(available_member.id) in suggestion_user_ids

    # Unavailable member should NOT be in suggestions
    assert str(unavailable_member.id) not in suggestion_user_ids


@pytest.mark.asyncio
async def test_get_suggestions_respects_recent_assignments(
    client: AsyncClient, db: AsyncSession, test_user: User, auth_headers: dict
):
    """Test that suggestions prioritize members with older or no assignments."""
    from app.models.roster import EventAssignment

    # Setup org and team
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

    team_lead = TeamMember(
        user_id=test_user.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=TeamPermission.ALL.copy(),
    )
    db.add(team_lead)

    # Create three members
    never_assigned = User(
        email="never@example.com",
        name="Never Assigned",
        password_hash=get_password_hash("testpassword"),
    )
    recently_assigned = User(
        email="recent@example.com",
        name="Recently Assigned",
        password_hash=get_password_hash("testpassword"),
    )
    long_ago_assigned = User(
        email="longago@example.com",
        name="Long Ago Assigned",
        password_hash=get_password_hash("testpassword"),
    )
    db.add(never_assigned)
    db.add(recently_assigned)
    db.add(long_ago_assigned)
    await db.flush()

    for member in [never_assigned, recently_assigned, long_ago_assigned]:
        org_member = OrganisationMember(
            user_id=member.id,
            organisation_id=org.id,
            role=OrganisationRole.MEMBER,
        )
        db.add(org_member)
        team_member = TeamMember(
            user_id=member.id,
            team_id=team.id,
            role=TeamRole.MEMBER,
            permissions=[],
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

    # Create past events with assignments
    recent_event = RosterEvent(
        roster_id=roster.id,
        date=date.today() - timedelta(days=3),
    )
    old_event = RosterEvent(
        roster_id=roster.id,
        date=date.today() - timedelta(days=30),
    )
    db.add(recent_event)
    db.add(old_event)
    await db.flush()

    recent_assignment = EventAssignment(
        event_id=recent_event.id,
        user_id=recently_assigned.id,
        status=AssignmentStatus.CONFIRMED,
    )
    old_assignment = EventAssignment(
        event_id=old_event.id,
        user_id=long_ago_assigned.id,
        status=AssignmentStatus.CONFIRMED,
    )
    db.add(recent_assignment)
    db.add(old_assignment)

    # Create future event to get suggestions for
    future_event = RosterEvent(
        roster_id=roster.id,
        date=date.today() + timedelta(days=7),
    )
    db.add(future_event)
    await db.commit()

    # Get suggestions
    response = await client.get(
        f"/api/rosters/events/{future_event.id}/suggestions",
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    suggestions = data["suggestions"]

    # Should have at least 3 suggestions
    assert len(suggestions) >= 3

    # Find positions in the list
    positions = {}
    for idx, suggestion in enumerate(suggestions):
        user_id = suggestion["user_id"]
        if user_id == str(never_assigned.id):
            positions["never"] = idx
        elif user_id == str(recently_assigned.id):
            positions["recent"] = idx
        elif user_id == str(long_ago_assigned.id):
            positions["old"] = idx

    # never_assigned should rank higher than recently_assigned
    assert positions["never"] < positions["recent"]

    # long_ago_assigned should rank higher than recently_assigned
    assert positions["old"] < positions["recent"]
