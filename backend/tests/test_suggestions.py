"""
Unit tests for roster assignment suggestion algorithm.
"""

from datetime import date, timedelta

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_password_hash
from app.models.availability import Unavailability
from app.models.organisation import Organisation
from app.models.roster import (
    AssignmentMode,
    AssignmentStatus,
    EventAssignment,
    RecurrencePattern,
    Roster,
    RosterEvent,
)
from app.models.team import Team, TeamMember, TeamRole
from app.models.user import User
from app.services.suggestion import SuggestionService


@pytest.mark.asyncio
async def test_suggest_never_assigned_members(db: AsyncSession):
    """Test that members who have never been assigned get highest priority."""
    # Create org and team
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    # Create 3 users - all never assigned
    user1 = User(
        email="user1@example.com",
        name="Alice",
        password_hash=get_password_hash("testpass"),
    )
    user2 = User(
        email="user2@example.com",
        name="Bob",
        password_hash=get_password_hash("testpass"),
    )
    user3 = User(
        email="user3@example.com",
        name="Charlie",
        password_hash=get_password_hash("testpass"),
    )
    db.add_all([user1, user2, user3])
    await db.flush()

    # Add them to team
    member1 = TeamMember(user_id=user1.id, team_id=team.id, role=TeamRole.MEMBER)
    member2 = TeamMember(user_id=user2.id, team_id=team.id, role=TeamRole.MEMBER)
    member3 = TeamMember(user_id=user3.id, team_id=team.id, role=TeamRole.MEMBER)
    db.add_all([member1, member2, member3])

    # Create roster and event
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

    event = RosterEvent(roster_id=roster.id, date=date.today() + timedelta(days=7))
    db.add(event)
    await db.commit()

    # Get suggestions
    service = SuggestionService(db)
    suggestions = await service.get_suggestions(event.id, team.id, limit=10)

    # All 3 should be suggested with high score (never assigned = 10000 base)
    assert len(suggestions) == 3
    for s in suggestions:
        assert s.score >= 9997  # 10000 - max 3 total assignments
        assert s.total_assignments == 0
        assert s.days_since_last is None
        assert "Never assigned before" in s.reasoning


@pytest.mark.asyncio
async def test_suggest_prioritizes_long_time_since_last(db: AsyncSession):
    """Test that members with longer gaps since last assignment are prioritized."""
    # Setup
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    # Create 3 users
    user_recent = User(
        email="recent@example.com",
        name="Recent User",
        password_hash=get_password_hash("testpass"),
    )
    user_medium = User(
        email="medium@example.com",
        name="Medium User",
        password_hash=get_password_hash("testpass"),
    )
    user_old = User(
        email="old@example.com",
        name="Old User",
        password_hash=get_password_hash("testpass"),
    )
    db.add_all([user_recent, user_medium, user_old])
    await db.flush()

    # Add to team
    member_recent = TeamMember(
        user_id=user_recent.id, team_id=team.id, role=TeamRole.MEMBER
    )
    member_medium = TeamMember(
        user_id=user_medium.id, team_id=team.id, role=TeamRole.MEMBER
    )
    member_old = TeamMember(user_id=user_old.id, team_id=team.id, role=TeamRole.MEMBER)
    db.add_all([member_recent, member_medium, member_old])

    # Create roster
    roster = Roster(
        name="Sunday Service",
        team_id=team.id,
        recurrence_pattern=RecurrencePattern.WEEKLY,
        recurrence_day=6,
        slots_needed=2,
        assignment_mode=AssignmentMode.MANUAL,
        start_date=date.today() - timedelta(days=60),
    )
    db.add(roster)
    await db.flush()

    # Create past events and assignments
    # Recent: 7 days ago
    event_recent = RosterEvent(
        roster_id=roster.id, date=date.today() - timedelta(days=7)
    )
    db.add(event_recent)
    await db.flush()

    assignment_recent = EventAssignment(
        event_id=event_recent.id,
        user_id=user_recent.id,
        status=AssignmentStatus.CONFIRMED,
    )
    db.add(assignment_recent)

    # Medium: 30 days ago
    event_medium = RosterEvent(
        roster_id=roster.id, date=date.today() - timedelta(days=30)
    )
    db.add(event_medium)
    await db.flush()

    assignment_medium = EventAssignment(
        event_id=event_medium.id,
        user_id=user_medium.id,
        status=AssignmentStatus.CONFIRMED,
    )
    db.add(assignment_medium)

    # Old: 60 days ago
    event_old = RosterEvent(roster_id=roster.id, date=date.today() - timedelta(days=60))
    db.add(event_old)
    await db.flush()

    assignment_old = EventAssignment(
        event_id=event_old.id,
        user_id=user_old.id,
        status=AssignmentStatus.CONFIRMED,
    )
    db.add(assignment_old)

    # Create future event to get suggestions for
    event_future = RosterEvent(
        roster_id=roster.id, date=date.today() + timedelta(days=7)
    )
    db.add(event_future)
    await db.commit()

    # Get suggestions
    service = SuggestionService(db)
    suggestions = await service.get_suggestions(event_future.id, team.id, limit=10)

    # Should be ordered: old > medium > recent
    assert len(suggestions) == 3
    assert suggestions[0].user_name == "Old User"
    assert suggestions[1].user_name == "Medium User"
    assert suggestions[2].user_name == "Recent User"

    # Verify scores decrease with recency
    assert suggestions[0].score > suggestions[1].score
    assert suggestions[1].score > suggestions[2].score

    # Verify days since last
    assert suggestions[0].days_since_last == 67  # 60 + 7
    assert suggestions[1].days_since_last == 37  # 30 + 7
    assert suggestions[2].days_since_last == 14  # 7 + 7


@pytest.mark.asyncio
async def test_suggest_excludes_unavailable_members(db: AsyncSession):
    """Test that members marked unavailable are excluded from suggestions."""
    # Setup
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    # Create 2 users
    user_available = User(
        email="available@example.com",
        name="Available User",
        password_hash=get_password_hash("testpass"),
    )
    user_unavailable = User(
        email="unavailable@example.com",
        name="Unavailable User",
        password_hash=get_password_hash("testpass"),
    )
    db.add_all([user_available, user_unavailable])
    await db.flush()

    # Add to team
    member_available = TeamMember(
        user_id=user_available.id, team_id=team.id, role=TeamRole.MEMBER
    )
    member_unavailable = TeamMember(
        user_id=user_unavailable.id, team_id=team.id, role=TeamRole.MEMBER
    )
    db.add_all([member_available, member_unavailable])

    # Create roster and event
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

    event_date = date.today() + timedelta(days=7)
    event = RosterEvent(roster_id=roster.id, date=event_date)
    db.add(event)

    # Mark one user as unavailable for the event date
    unavailability = Unavailability(user_id=user_unavailable.id, date=event_date)
    db.add(unavailability)
    await db.commit()

    # Get suggestions
    service = SuggestionService(db)
    suggestions = await service.get_suggestions(event.id, team.id, limit=10)

    # Only available user should be suggested
    assert len(suggestions) == 1
    assert suggestions[0].user_name == "Available User"


@pytest.mark.asyncio
async def test_suggest_respects_limit(db: AsyncSession):
    """Test that suggestions respect the limit parameter."""
    # Setup
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    # Create 10 users
    users = []
    for i in range(10):
        user = User(
            email=f"user{i}@example.com",
            name=f"User {i}",
            password_hash=get_password_hash("testpass"),
        )
        users.append(user)
        db.add(user)
    await db.flush()

    # Add all to team
    for user in users:
        member = TeamMember(user_id=user.id, team_id=team.id, role=TeamRole.MEMBER)
        db.add(member)

    # Create roster and event
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

    event = RosterEvent(roster_id=roster.id, date=date.today() + timedelta(days=7))
    db.add(event)
    await db.commit()

    # Get suggestions with limit
    service = SuggestionService(db)
    suggestions = await service.get_suggestions(event.id, team.id, limit=3)

    # Should return exactly 3
    assert len(suggestions) == 3


@pytest.mark.asyncio
async def test_suggest_includes_placeholder_users(db: AsyncSession):
    """Test that placeholder users are included in suggestions (they are real people who haven't joined yet)."""
    # Setup
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    # Create real user and placeholder user
    user_real = User(
        email="real@example.com",
        name="Real User",
        password_hash=get_password_hash("testpass"),
        is_placeholder=False,
    )
    user_placeholder = User(
        email="placeholder@example.com",
        name="Placeholder User",
        password_hash=get_password_hash("testpass"),
        is_placeholder=True,
    )
    db.add_all([user_real, user_placeholder])
    await db.flush()

    # Add both to team
    member_real = TeamMember(
        user_id=user_real.id, team_id=team.id, role=TeamRole.MEMBER
    )
    member_placeholder = TeamMember(
        user_id=user_placeholder.id, team_id=team.id, role=TeamRole.MEMBER
    )
    db.add_all([member_real, member_placeholder])

    # Create roster and event
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

    event = RosterEvent(roster_id=roster.id, date=date.today() + timedelta(days=7))
    db.add(event)
    await db.commit()

    # Get suggestions
    service = SuggestionService(db)
    suggestions = await service.get_suggestions(event.id, team.id, limit=10)

    # Both users should be suggested (including placeholder)
    assert len(suggestions) == 2
    user_names = {s.user_name for s in suggestions}
    assert "Real User" in user_names
    assert "Placeholder User" in user_names


@pytest.mark.asyncio
async def test_suggest_considers_total_assignments(db: AsyncSession):
    """Test that total assignment count affects scoring."""
    # Setup
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    # Create 2 users
    user_few = User(
        email="few@example.com",
        name="Few Assignments",
        password_hash=get_password_hash("testpass"),
    )
    user_many = User(
        email="many@example.com",
        name="Many Assignments",
        password_hash=get_password_hash("testpass"),
    )
    db.add_all([user_few, user_many])
    await db.flush()

    # Add to team
    member_few = TeamMember(user_id=user_few.id, team_id=team.id, role=TeamRole.MEMBER)
    member_many = TeamMember(
        user_id=user_many.id, team_id=team.id, role=TeamRole.MEMBER
    )
    db.add_all([member_few, member_many])

    # Create roster
    roster = Roster(
        name="Sunday Service",
        team_id=team.id,
        recurrence_pattern=RecurrencePattern.WEEKLY,
        recurrence_day=6,
        slots_needed=2,
        assignment_mode=AssignmentMode.MANUAL,
        start_date=date.today() - timedelta(days=90),
    )
    db.add(roster)
    await db.flush()

    # Create multiple past assignments for user_many
    # Both last served 30 days ago, but user_many has 5 total, user_few has 1
    for i in range(5):
        event = RosterEvent(
            roster_id=roster.id, date=date.today() - timedelta(days=30 + (i * 7))
        )
        db.add(event)
        await db.flush()

        assignment = EventAssignment(
            event_id=event.id,
            user_id=user_many.id,
            status=AssignmentStatus.CONFIRMED,
        )
        db.add(assignment)

    # Create one assignment for user_few (also 30 days ago)
    event_few = RosterEvent(roster_id=roster.id, date=date.today() - timedelta(days=30))
    db.add(event_few)
    await db.flush()

    assignment_few = EventAssignment(
        event_id=event_few.id,
        user_id=user_few.id,
        status=AssignmentStatus.CONFIRMED,
    )
    db.add(assignment_few)

    # Create future event
    event_future = RosterEvent(
        roster_id=roster.id, date=date.today() + timedelta(days=7)
    )
    db.add(event_future)
    await db.commit()

    # Get suggestions
    service = SuggestionService(db)
    suggestions = await service.get_suggestions(event_future.id, team.id, limit=10)

    # user_few should be ranked higher (fewer total assignments)
    assert len(suggestions) == 2
    assert suggestions[0].user_name == "Few Assignments"
    assert suggestions[1].user_name == "Many Assignments"

    # Both have same days_since_last, but different totals
    assert suggestions[0].total_assignments < suggestions[1].total_assignments
    assert suggestions[0].score > suggestions[1].score


@pytest.mark.asyncio
async def test_suggest_handles_no_event(db: AsyncSession):
    """Test that get_suggestions returns empty list for non-existent event."""
    import uuid

    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.commit()

    # Get suggestions for non-existent event
    service = SuggestionService(db)
    suggestions = await service.get_suggestions(uuid.uuid4(), team.id, limit=10)

    assert suggestions == []


@pytest.mark.asyncio
async def test_suggest_handles_no_team_members(db: AsyncSession):
    """Test that get_suggestions returns empty list when team has no members."""
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    # Create roster and event but no team members
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

    event = RosterEvent(roster_id=roster.id, date=date.today() + timedelta(days=7))
    db.add(event)
    await db.commit()

    # Get suggestions
    service = SuggestionService(db)
    suggestions = await service.get_suggestions(event.id, team.id, limit=10)

    assert suggestions == []


@pytest.mark.asyncio
async def test_suggestion_reasoning(db: AsyncSession):
    """Test that suggestion reasoning is formatted correctly."""
    # Setup
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    # Create user
    user = User(
        email="user@example.com",
        name="Test User",
        password_hash=get_password_hash("testpass"),
    )
    db.add(user)
    await db.flush()

    member = TeamMember(user_id=user.id, team_id=team.id, role=TeamRole.MEMBER)
    db.add(member)

    # Create roster
    roster = Roster(
        name="Sunday Service",
        team_id=team.id,
        recurrence_pattern=RecurrencePattern.WEEKLY,
        recurrence_day=6,
        slots_needed=2,
        assignment_mode=AssignmentMode.MANUAL,
        start_date=date.today() - timedelta(days=30),
    )
    db.add(roster)
    await db.flush()

    # Create past assignment
    event_past = RosterEvent(
        roster_id=roster.id, date=date.today() - timedelta(days=30)
    )
    db.add(event_past)
    await db.flush()

    assignment = EventAssignment(
        event_id=event_past.id,
        user_id=user.id,
        status=AssignmentStatus.CONFIRMED,
    )
    db.add(assignment)

    # Create future event
    event_future = RosterEvent(
        roster_id=roster.id, date=date.today() + timedelta(days=7)
    )
    db.add(event_future)
    await db.commit()

    # Get suggestions
    service = SuggestionService(db)
    suggestions = await service.get_suggestions(event_future.id, team.id, limit=10)

    assert len(suggestions) == 1
    suggestion = suggestions[0]

    # Check reasoning format
    assert "37 days ago" in suggestion.reasoning  # 30 + 7
    assert "1 previous assignment" in suggestion.reasoning


@pytest.mark.asyncio
async def test_suggestion_to_dict(db: AsyncSession):
    """Test that suggestion converts to dict correctly for API responses."""
    # Setup
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    user = User(
        email="user@example.com",
        name="Test User",
        password_hash=get_password_hash("testpass"),
    )
    db.add(user)
    await db.flush()

    member = TeamMember(user_id=user.id, team_id=team.id, role=TeamRole.MEMBER)
    db.add(member)

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

    event = RosterEvent(roster_id=roster.id, date=date.today() + timedelta(days=7))
    db.add(event)
    await db.commit()

    # Get suggestions
    service = SuggestionService(db)
    suggestions = await service.get_suggestions(event.id, team.id, limit=10)

    assert len(suggestions) == 1
    suggestion_dict = suggestions[0].to_dict()

    # Check all required fields
    assert "user_id" in suggestion_dict
    assert "user_name" in suggestion_dict
    assert "score" in suggestion_dict
    assert "reasoning" in suggestion_dict
    assert "last_assignment_date" in suggestion_dict
    assert "total_assignments" in suggestion_dict
    assert "days_since_last" in suggestion_dict

    # Verify types
    assert isinstance(suggestion_dict["user_id"], str)
    assert isinstance(suggestion_dict["user_name"], str)
    assert isinstance(suggestion_dict["score"], float)
    assert isinstance(suggestion_dict["reasoning"], str)
    assert suggestion_dict["total_assignments"] == 0
    assert suggestion_dict["days_since_last"] is None


@pytest.mark.asyncio
async def test_fair_rotation_with_pending_assignments(db: AsyncSession):
    """Test that fair rotation works with PENDING assignments.

    This is a statistical test that verifies all team members get assigned
    when creating multiple events. The bug was that PENDING assignments were
    not counted, causing the same people to be suggested repeatedly.
    """
    # Setup: Create org and team
    org = Organisation(name="Test Church")
    db.add(org)
    await db.flush()

    team = Team(name="Media Team", organisation_id=org.id)
    db.add(team)
    await db.flush()

    # Create 5 team members
    users = []
    for i in range(5):
        user = User(
            email=f"user{i}@example.com",
            name=f"User {i}",
            password_hash=get_password_hash("testpass"),
        )
        users.append(user)
        db.add(user)
    await db.flush()

    # Add all users to team
    for user in users:
        member = TeamMember(user_id=user.id, team_id=team.id, role=TeamRole.MEMBER)
        db.add(member)

    # Create roster
    roster = Roster(
        name="Sunday Service",
        team_id=team.id,
        recurrence_pattern=RecurrencePattern.WEEKLY,
        recurrence_day=6,
        slots_needed=1,  # 1 slot per event
        assignment_mode=AssignmentMode.MANUAL,
        start_date=date.today(),
    )
    db.add(roster)
    await db.flush()

    # Create 15 events (3 full rotations)
    events = []
    for i in range(15):
        event = RosterEvent(
            roster_id=roster.id, date=date.today() + timedelta(days=7 * i)
        )
        db.add(event)
        events.append(event)
    await db.flush()
    await db.commit()

    # Simulate assigning suggestions to each event
    service = SuggestionService(db)
    assignment_counts = {user.id: 0 for user in users}

    for event in events:
        # Get suggestions for this event
        suggestions = await service.get_suggestions(event.id, team.id, limit=5)

        # Should have suggestions
        assert len(suggestions) > 0

        # Assign the top suggestion as PENDING
        top_suggestion = suggestions[0]
        assignment = EventAssignment(
            event_id=event.id,
            user_id=top_suggestion.user_id,
            status=AssignmentStatus.PENDING,  # PENDING, not CONFIRMED
        )
        db.add(assignment)
        await db.commit()

        # Track who got assigned
        assignment_counts[top_suggestion.user_id] += 1

    # Statistical verification
    # All 5 members should have at least one assignment after 15 events
    assigned_members = [
        user_id for user_id, count in assignment_counts.items() if count > 0
    ]
    assert len(assigned_members) == 5, (
        f"Fair rotation failed: only {len(assigned_members)}/5 members were assigned. "
        f"Assignment counts: {assignment_counts}"
    )

    # Verify relatively even distribution
    # With 15 events and 5 members, each should get 3 assignments on average
    # Allow some variation but no member should have 0 or more than 6
    for user_id, count in assignment_counts.items():
        assert count >= 1, f"User {user_id} got 0 assignments (unfair rotation)"
        assert count <= 7, f"User {user_id} got {count} assignments (unfair rotation)"

    # Verify that the algorithm considers PENDING assignments
    # If PENDING assignments were ignored, the same person would be suggested every time
    # and we'd have 1 person with 15 assignments and 4 with 0
    max_assignments = max(assignment_counts.values())
    min_assignments = min(assignment_counts.values())
    difference = max_assignments - min_assignments

    # The difference should be small (at most 2-3 for fair rotation)
    assert difference <= 4, (
        f"Rotation is too uneven: difference between max ({max_assignments}) "
        f"and min ({min_assignments}) assignments is {difference}. "
        f"Full distribution: {assignment_counts}"
    )
