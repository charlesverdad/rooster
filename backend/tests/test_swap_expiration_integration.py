"""
Integration test for swap request expiration with notifications.

This test verifies:
1. Swap requests expire after 48 hours
2. Status changes to EXPIRED
3. Requester receives notification
"""

import uuid
from datetime import date, datetime, timedelta, timezone

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_password_hash
from app.models.notification import NotificationType
from app.models.organisation import Organisation
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
from app.services.notification import NotificationService
from app.services.swap_request import SwapRequestService


async def _create_test_data(db_session: AsyncSession):
    """Helper to create test organization, team, users, and assignment."""
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

    await db_session.commit()

    return org, team, requester, target, roster, event, requester_assignment


@pytest.mark.asyncio
async def test_swap_request_expiration_with_notification(db_session: AsyncSession):
    """Test that swap requests expire and send notifications."""
    # Create test data
    org, team, requester, target, roster, event, requester_assignment = (
        await _create_test_data(db_session)
    )

    # Create swap request service and create a swap request
    swap_service = SwapRequestService(db_session)
    swap_request = await swap_service.create_swap_request(
        SwapRequestCreate(
            requester_assignment_id=requester_assignment.id,
            target_user_id=target.id,
        )
    )
    await db_session.commit()

    # Verify swap request was created with PENDING status
    assert swap_request.status == SwapRequestStatus.PENDING
    assert swap_request.expires_at is not None

    # Verify expires_at is approximately 48 hours from now
    expected_expiry = datetime.now(timezone.utc) + timedelta(hours=48)
    time_diff = abs((swap_request.expires_at - expected_expiry).total_seconds())
    assert time_diff < 60, "Expiry should be 48 hours from now (within 1 minute)"

    # Manually set expires_at to past time to simulate expiration
    swap_request.expires_at = datetime.now(timezone.utc) - timedelta(hours=1)
    db_session.add(swap_request)
    await db_session.commit()

    # Run expiration check
    expired_count = await swap_service.expire_old_requests()
    await db_session.commit()

    # Verify one request was expired
    assert expired_count == 1, "One swap request should have been expired"

    # Verify the request status is now EXPIRED
    await db_session.refresh(swap_request)
    assert swap_request.status == SwapRequestStatus.EXPIRED

    # Now send notification (this would normally be done by the expiration job)
    notification_service = NotificationService(db_session)
    notification = await notification_service.notify_swap_expired(
        requester_user_id=requester.id,
        event_date=event.date.strftime("%B %d, %Y"),
        swap_request_id=swap_request.id,
    )
    await db_session.commit()

    # Verify notification was created
    assert notification is not None
    assert notification.user_id == requester.id
    assert notification.type == NotificationType.SWAP_EXPIRED
    assert notification.title == "Swap Request Expired"
    assert event.date.strftime("%B %d, %Y") in notification.message
    assert notification.reference_id == swap_request.id

    # Verify requester can see the notification
    requester_notifications = await notification_service.get_user_notifications(
        requester.id,
        unread_only=True,
    )
    assert len(requester_notifications) == 1
    assert requester_notifications[0].type == NotificationType.SWAP_EXPIRED


@pytest.mark.asyncio
async def test_multiple_expiring_requests(db_session: AsyncSession):
    """Test that multiple expired requests are handled correctly."""
    # Create test data
    org, team, requester, target, roster, event, requester_assignment = (
        await _create_test_data(db_session)
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

    # Create swap request service
    swap_service = SwapRequestService(db_session)

    # Create two swap requests
    swap_request1 = await swap_service.create_swap_request(
        SwapRequestCreate(
            requester_assignment_id=requester_assignment.id,
            target_user_id=target.id,
        )
    )
    swap_request2 = await swap_service.create_swap_request(
        SwapRequestCreate(
            requester_assignment_id=requester_assignment.id,
            target_user_id=target2.id,
        )
    )
    await db_session.commit()

    # Manually set both to expired
    swap_request1.expires_at = datetime.now(timezone.utc) - timedelta(hours=2)
    swap_request2.expires_at = datetime.now(timezone.utc) - timedelta(hours=1)
    db_session.add_all([swap_request1, swap_request2])
    await db_session.commit()

    # Run expiration check
    expired_count = await swap_service.expire_old_requests()
    await db_session.commit()

    # Verify both were expired
    assert expired_count == 2, "Both swap requests should have been expired"

    # Verify both statuses
    await db_session.refresh(swap_request1)
    await db_session.refresh(swap_request2)
    assert swap_request1.status == SwapRequestStatus.EXPIRED
    assert swap_request2.status == SwapRequestStatus.EXPIRED


@pytest.mark.asyncio
async def test_expiration_does_not_affect_non_pending_requests(db_session: AsyncSession):
    """Test that expiration only affects PENDING requests."""
    # Create test data
    org, team, requester, target, roster, event, requester_assignment = (
        await _create_test_data(db_session)
    )

    # Create swap request service
    swap_service = SwapRequestService(db_session)

    # Create a swap request and accept it
    swap_request = await swap_service.create_swap_request(
        SwapRequestCreate(
            requester_assignment_id=requester_assignment.id,
            target_user_id=target.id,
        )
    )
    await db_session.commit()

    # Accept the request
    await swap_service.accept_swap_request(swap_request.id, target.id)
    await db_session.commit()

    # Manually set expires_at to past time
    swap_request.expires_at = datetime.now(timezone.utc) - timedelta(hours=1)
    db_session.add(swap_request)
    await db_session.commit()

    # Run expiration check
    expired_count = await swap_service.expire_old_requests()
    await db_session.commit()

    # Verify no requests were expired
    assert expired_count == 0, "Accepted request should not be expired"

    # Verify status is still ACCEPTED
    await db_session.refresh(swap_request)
    assert swap_request.status == SwapRequestStatus.ACCEPTED
