"""
Unit tests for the swap request service and functionality.
"""

import uuid
from datetime import date, datetime, timedelta, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, get_password_hash
from app.models.organisation import Organisation, OrganisationMember, OrganisationRole
from app.models.roster import (
    AssignmentStatus,
    EventAssignment,
    RecurrencePattern,
    Roster,
    RosterEvent,
)
from app.models.swap_request import SwapRequest, SwapRequestStatus
from app.models.team import Team, TeamMember, TeamRole
from app.models.user import User
from app.schemas.swap_request import SwapRequestCreate
from app.services.swap_request import SwapRequestService


async def _create_swap_request_fixtures(db_session: AsyncSession):
    """Helper to create org, team, users, roster, event, assignments, and swap request."""
    # Create organization
    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    # Create team
    team = Team(name="Worship Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    # Create requester user
    requester = User(
        email="requester@example.com",
        name="Requester User",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(requester)
    await db_session.flush()

    # Create target user
    target = User(
        email="target@example.com",
        name="Target User",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(target)
    await db_session.flush()

    # Create team memberships
    requester_membership = TeamMember(
        user_id=requester.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    target_membership = TeamMember(
        user_id=target.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add_all([requester_membership, target_membership])

    # Create roster
    roster = Roster(
        name="Sunday Worship",
        team_id=team.id,
        recurrence_pattern=RecurrencePattern.WEEKLY,
        recurrence_day=6,  # Sunday
        slots_needed=2,
        start_date=date.today(),
    )
    db_session.add(roster)
    await db_session.flush()

    # Create roster event
    event = RosterEvent(
        roster_id=roster.id,
        date=date.today() + timedelta(days=7),  # Next Sunday
    )
    db_session.add(event)
    await db_session.flush()

    # Create requester assignment
    requester_assignment = EventAssignment(
        event_id=event.id,
        user_id=requester.id,
        status=AssignmentStatus.CONFIRMED,
    )
    db_session.add(requester_assignment)
    await db_session.flush()

    # Create swap request
    expires_at = datetime.now(timezone.utc) + timedelta(hours=48)
    swap_request = SwapRequest(
        requester_assignment_id=requester_assignment.id,
        target_user_id=target.id,
        status=SwapRequestStatus.PENDING,
        expires_at=expires_at,
    )
    db_session.add(swap_request)
    await db_session.commit()

    return org, team, requester, target, roster, event, requester_assignment, swap_request


@pytest.mark.asyncio
async def test_create_swap_request(db_session: AsyncSession):
    """Test creating a swap request through the service."""
    org, team, requester, target, roster, event, requester_assignment, _ = (
        await _create_swap_request_fixtures(db_session)
    )

    service = SwapRequestService(db_session)
    swap_data = SwapRequestCreate(
        requester_assignment_id=requester_assignment.id,
        target_user_id=target.id,
    )

    swap_request = await service.create_swap_request(swap_data)
    await db_session.commit()

    assert swap_request.requester_assignment_id == requester_assignment.id
    assert swap_request.target_user_id == target.id
    assert swap_request.status == SwapRequestStatus.PENDING
    assert swap_request.expires_at is not None
    # Should expire in approximately 48 hours
    time_diff = swap_request.expires_at - datetime.now(timezone.utc)
    assert 47 <= time_diff.total_seconds() / 3600 <= 49


@pytest.mark.asyncio
async def test_get_swap_request(db_session: AsyncSession):
    """Test getting a swap request by ID."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    service = SwapRequestService(db_session)
    result = await service.get_swap_request(swap_request.id)

    assert result is not None
    assert result.id == swap_request.id
    assert result.status == SwapRequestStatus.PENDING
    # Check that relationships are loaded
    assert result.requester_assignment is not None
    assert result.target_user is not None


@pytest.mark.asyncio
async def test_get_swap_request_not_found(db_session: AsyncSession):
    """Test getting a non-existent swap request."""
    service = SwapRequestService(db_session)
    result = await service.get_swap_request(uuid.uuid4())

    assert result is None


@pytest.mark.asyncio
async def test_get_user_swap_requests_as_requester(db_session: AsyncSession):
    """Test getting swap requests where user is the requester."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    service = SwapRequestService(db_session)
    requests = await service.get_user_swap_requests(requester.id)

    assert len(requests) == 1
    assert requests[0].id == swap_request.id


@pytest.mark.asyncio
async def test_get_user_swap_requests_as_target(db_session: AsyncSession):
    """Test getting swap requests where user is the target."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    service = SwapRequestService(db_session)
    requests = await service.get_user_swap_requests(target.id)

    assert len(requests) == 1
    assert requests[0].id == swap_request.id


@pytest.mark.asyncio
async def test_get_user_swap_requests_with_status_filter(db_session: AsyncSession):
    """Test getting swap requests filtered by status."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    service = SwapRequestService(db_session)

    # Should find pending request
    pending_requests = await service.get_user_swap_requests(
        target.id, status=SwapRequestStatus.PENDING
    )
    assert len(pending_requests) == 1

    # Should not find accepted requests (none exist)
    accepted_requests = await service.get_user_swap_requests(
        target.id, status=SwapRequestStatus.ACCEPTED
    )
    assert len(accepted_requests) == 0


@pytest.mark.asyncio
async def test_accept_swap_request_without_target_assignment(db_session: AsyncSession):
    """Test accepting a swap request when target doesn't have an assignment."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    service = SwapRequestService(db_session)
    result = await service.accept_swap_request(swap_request.id, target.id)
    await db_session.commit()

    assert result is not None
    assert result.status == SwapRequestStatus.ACCEPTED
    assert result.responded_at is not None

    # Requester's assignment should now belong to target
    await db_session.refresh(requester_assignment)
    assert requester_assignment.user_id == target.id


@pytest.mark.asyncio
async def test_accept_swap_request_with_target_assignment(db_session: AsyncSession):
    """Test accepting a swap request when both users have assignments - should swap them."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    # Create assignment for target user
    target_assignment = EventAssignment(
        event_id=event.id,
        user_id=target.id,
        status=AssignmentStatus.CONFIRMED,
    )
    db_session.add(target_assignment)
    await db_session.commit()

    original_target_user_id = target_assignment.user_id

    service = SwapRequestService(db_session)
    result = await service.accept_swap_request(swap_request.id, target.id)
    await db_session.commit()

    assert result is not None
    assert result.status == SwapRequestStatus.ACCEPTED

    # Assignments should be swapped
    await db_session.refresh(requester_assignment)
    await db_session.refresh(target_assignment)

    assert requester_assignment.user_id == original_target_user_id
    assert target_assignment.user_id == requester.id


@pytest.mark.asyncio
async def test_accept_swap_request_wrong_user(db_session: AsyncSession):
    """Test that only the target user can accept a swap request."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    # Try to accept with requester's ID instead of target's
    service = SwapRequestService(db_session)
    result = await service.accept_swap_request(swap_request.id, requester.id)

    assert result is None


@pytest.mark.asyncio
async def test_accept_swap_request_not_found(db_session: AsyncSession):
    """Test accepting a non-existent swap request."""
    service = SwapRequestService(db_session)
    result = await service.accept_swap_request(uuid.uuid4(), uuid.uuid4())

    assert result is None


@pytest.mark.asyncio
async def test_accept_swap_request_already_accepted(db_session: AsyncSession):
    """Test accepting a swap request that has already been accepted."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    service = SwapRequestService(db_session)

    # Accept the request
    result = await service.accept_swap_request(swap_request.id, target.id)
    await db_session.commit()
    assert result is not None
    assert result.status == SwapRequestStatus.ACCEPTED

    # Try to accept again
    result2 = await service.accept_swap_request(swap_request.id, target.id)

    assert result2 is None


@pytest.mark.asyncio
async def test_decline_swap_request(db_session: AsyncSession):
    """Test declining a swap request."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    service = SwapRequestService(db_session)
    result = await service.decline_swap_request(swap_request.id, target.id)
    await db_session.commit()

    assert result is not None
    assert result.status == SwapRequestStatus.DECLINED
    assert result.responded_at is not None

    # Assignment should remain unchanged
    await db_session.refresh(requester_assignment)
    assert requester_assignment.user_id == requester.id


@pytest.mark.asyncio
async def test_decline_swap_request_wrong_user(db_session: AsyncSession):
    """Test that only the target user can decline a swap request."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    # Try to decline with requester's ID instead of target's
    service = SwapRequestService(db_session)
    result = await service.decline_swap_request(swap_request.id, requester.id)

    assert result is None


@pytest.mark.asyncio
async def test_decline_swap_request_not_found(db_session: AsyncSession):
    """Test declining a non-existent swap request."""
    service = SwapRequestService(db_session)
    result = await service.decline_swap_request(uuid.uuid4(), uuid.uuid4())

    assert result is None


@pytest.mark.asyncio
async def test_decline_swap_request_already_declined(db_session: AsyncSession):
    """Test declining a swap request that has already been declined."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    service = SwapRequestService(db_session)

    # Decline the request
    result = await service.decline_swap_request(swap_request.id, target.id)
    await db_session.commit()
    assert result is not None
    assert result.status == SwapRequestStatus.DECLINED

    # Try to decline again
    result2 = await service.decline_swap_request(swap_request.id, target.id)

    assert result2 is None


@pytest.mark.asyncio
async def test_expire_old_requests(db_session: AsyncSession):
    """Test expiring old swap requests."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    # Manually set expires_at to past time
    swap_request.expires_at = datetime.now(timezone.utc) - timedelta(hours=1)
    db_session.add(swap_request)
    await db_session.commit()

    service = SwapRequestService(db_session)
    count = await service.expire_old_requests()
    await db_session.commit()

    assert count == 1

    # Verify the request is now expired
    await db_session.refresh(swap_request)
    assert swap_request.status == SwapRequestStatus.EXPIRED


@pytest.mark.asyncio
async def test_expire_old_requests_does_not_affect_accepted(db_session: AsyncSession):
    """Test that expiration doesn't affect already accepted requests."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    # Accept the request first
    service = SwapRequestService(db_session)
    await service.accept_swap_request(swap_request.id, target.id)

    # Set expires_at to past time
    swap_request.expires_at = datetime.now(timezone.utc) - timedelta(hours=1)
    db_session.add(swap_request)
    await db_session.commit()

    # Try to expire
    count = await service.expire_old_requests()
    await db_session.commit()

    assert count == 0

    # Should still be accepted, not expired
    await db_session.refresh(swap_request)
    assert swap_request.status == SwapRequestStatus.ACCEPTED


@pytest.mark.asyncio
async def test_get_eligible_swap_targets(db_session: AsyncSession):
    """Test getting eligible swap targets for an assignment."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    # Create another team member who is eligible
    eligible_user = User(
        email="eligible@example.com",
        name="Eligible User",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(eligible_user)
    await db_session.flush()

    eligible_membership = TeamMember(
        user_id=eligible_user.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(eligible_membership)

    # Create a user already assigned to the event (not eligible)
    assigned_user = User(
        email="assigned@example.com",
        name="Already Assigned User",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(assigned_user)
    await db_session.flush()

    assigned_membership = TeamMember(
        user_id=assigned_user.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(assigned_membership)

    assigned_assignment = EventAssignment(
        event_id=event.id,
        user_id=assigned_user.id,
        status=AssignmentStatus.CONFIRMED,
    )
    db_session.add(assigned_assignment)
    await db_session.commit()

    service = SwapRequestService(db_session)
    eligible_users = await service.get_eligible_swap_targets(requester_assignment.id)

    # Should include target and eligible_user, but not requester or assigned_user
    eligible_ids = {user.id for user in eligible_users}
    assert target.id in eligible_ids
    assert eligible_user.id in eligible_ids
    assert requester.id not in eligible_ids
    assert assigned_user.id not in eligible_ids
    assert len(eligible_users) == 2


@pytest.mark.asyncio
async def test_get_eligible_swap_targets_assignment_not_found(db_session: AsyncSession):
    """Test getting eligible swap targets for non-existent assignment."""
    service = SwapRequestService(db_session)
    eligible_users = await service.get_eligible_swap_targets(uuid.uuid4())

    assert len(eligible_users) == 0


@pytest.mark.asyncio
async def test_get_team_leads_for_assignment(db_session: AsyncSession):
    """Test getting team leads for an assignment."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    # Create a team lead
    lead = User(
        email="lead@example.com",
        name="Team Lead",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(lead)
    await db_session.flush()

    lead_membership = TeamMember(
        user_id=lead.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=[],
    )
    db_session.add(lead_membership)
    await db_session.commit()

    service = SwapRequestService(db_session)
    team_leads = await service.get_team_leads_for_assignment(requester_assignment.id)

    assert len(team_leads) == 1
    assert team_leads[0].id == lead.id
    assert team_leads[0].email == "lead@example.com"


@pytest.mark.asyncio
async def test_get_team_leads_for_assignment_not_found(db_session: AsyncSession):
    """Test getting team leads for non-existent assignment."""
    service = SwapRequestService(db_session)
    team_leads = await service.get_team_leads_for_assignment(uuid.uuid4())

    assert len(team_leads) == 0


@pytest.mark.asyncio
async def test_get_team_leads_no_leads(db_session: AsyncSession):
    """Test getting team leads when team has no leads."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    service = SwapRequestService(db_session)
    team_leads = await service.get_team_leads_for_assignment(requester_assignment.id)

    # Should return empty list when no leads exist
    assert len(team_leads) == 0


@pytest.mark.asyncio
async def test_multiple_swap_requests_for_same_assignment(db_session: AsyncSession):
    """Test creating multiple swap requests for the same assignment."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    # Create another target user
    target2 = User(
        email="target2@example.com",
        name="Target User 2",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(target2)
    await db_session.flush()

    target2_membership = TeamMember(
        user_id=target2.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(target2_membership)
    await db_session.commit()

    # Create another swap request for the same assignment
    service = SwapRequestService(db_session)
    swap_data = SwapRequestCreate(
        requester_assignment_id=requester_assignment.id,
        target_user_id=target2.id,
    )
    swap_request2 = await service.create_swap_request(swap_data)
    await db_session.commit()

    # Both requests should exist
    requests = await service.get_user_swap_requests(requester.id)
    assert len(requests) == 2


@pytest.mark.asyncio
async def test_swap_request_ordering(db_session: AsyncSession):
    """Test that swap requests are ordered by created_at descending."""
    org, team, requester, target, roster, event, requester_assignment, swap_request = (
        await _create_swap_request_fixtures(db_session)
    )

    # Create another target user
    target2 = User(
        email="target2@example.com",
        name="Target User 2",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(target2)
    await db_session.flush()

    target2_membership = TeamMember(
        user_id=target2.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(target2_membership)
    await db_session.commit()

    # Create second swap request (will be newer)
    service = SwapRequestService(db_session)
    swap_data = SwapRequestCreate(
        requester_assignment_id=requester_assignment.id,
        target_user_id=target2.id,
    )
    swap_request2 = await service.create_swap_request(swap_data)
    await db_session.commit()

    # Get all requests
    requests = await service.get_user_swap_requests(requester.id)

    # Should be ordered newest first
    assert len(requests) == 2
    assert requests[0].id == swap_request2.id
    assert requests[1].id == swap_request.id
