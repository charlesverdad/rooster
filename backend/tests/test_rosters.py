"""
Integration tests for roster and assignment functionality.
"""
import uuid
from datetime import date, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.organisation import Organisation, OrganisationMember, OrganisationRole
from app.models.roster import Assignment, AssignmentMode, RecurrencePattern, Roster
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
    )
    db.add(team_member)
    await db.commit()
    
    # Create roster
    response = await client.post(
        "/api/rosters",
        json={
            "name": "Sunday Service",
            "team_id": str(team.id),
            "recurrence_pattern": "WEEKLY",
            "recurrence_day": 6,  # Sunday
            "slots_needed": 2,
            "assignment_mode": "MANUAL",
        },
        headers=auth_headers,
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Sunday Service"
    assert data["recurrence_pattern"] == "WEEKLY"
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
    )
    db.add(team_member)
    
    roster = Roster(
        name="Sunday Service",
        team_id=team.id,
        recurrence_pattern=RecurrencePattern.WEEKLY,
        recurrence_day=6,
        slots_needed=2,
        assignment_mode=AssignmentMode.MANUAL,
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
    assert data["status"] == "PENDING"


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
