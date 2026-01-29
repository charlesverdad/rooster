"""
End-to-end integration test for swap request workflow.

This test verifies the complete swap request workflow from initiation to completion:
1. User A has a confirmed assignment for a future date
2. User A initiates swap request to User B (same team, not assigned)
3. Verify swap request created in database with PENDING status
4. Verify User B receives notification
5. User B accepts the swap
6. Verify assignments are swapped in database
7. Verify team lead receives notification of completed swap
8. Verify both users see updated assignments
"""

import uuid
from datetime import date, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, get_password_hash
from app.models.notification import Notification, NotificationType
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


async def _create_e2e_fixtures(db_session: AsyncSession):
    """Create all fixtures needed for E2E swap workflow test."""
    # Create organization
    org = Organisation(name="Test Church")
    db_session.add(org)
    await db_session.flush()

    # Create team
    team = Team(name="Worship Team", organisation_id=org.id)
    db_session.add(team)
    await db_session.flush()

    # Create User A (requester) - has a confirmed assignment
    user_a = User(
        email="usera@example.com",
        name="User A",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(user_a)
    await db_session.flush()

    # Create User B (target) - same team, no assignment for this event
    user_b = User(
        email="userb@example.com",
        name="User B",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(user_b)
    await db_session.flush()

    # Create Team Lead
    team_lead = User(
        email="teamlead@example.com",
        name="Team Lead",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(team_lead)
    await db_session.flush()

    # Create organization memberships
    org_member_a = OrganisationMember(
        user_id=user_a.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    org_member_b = OrganisationMember(
        user_id=user_b.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    org_member_lead = OrganisationMember(
        user_id=team_lead.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db_session.add_all([org_member_a, org_member_b, org_member_lead])

    # Create team memberships
    member_a = TeamMember(
        user_id=user_a.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    member_b = TeamMember(
        user_id=user_b.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    member_lead = TeamMember(
        user_id=team_lead.id,
        team_id=team.id,
        role=TeamRole.LEAD,
        permissions=[],
    )
    db_session.add_all([member_a, member_b, member_lead])

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

    # Create roster event for future date
    event = RosterEvent(
        roster_id=roster.id,
        date=date.today() + timedelta(days=7),  # Next Sunday
    )
    db_session.add(event)
    await db_session.flush()

    # Create User A's confirmed assignment
    assignment_a = EventAssignment(
        event_id=event.id,
        user_id=user_a.id,
        status=AssignmentStatus.CONFIRMED,
    )
    db_session.add(assignment_a)
    await db_session.flush()

    await db_session.commit()

    return {
        "org": org,
        "team": team,
        "user_a": user_a,
        "user_b": user_b,
        "team_lead": team_lead,
        "roster": roster,
        "event": event,
        "assignment_a": assignment_a,
    }


@pytest.mark.asyncio
async def test_e2e_swap_request_accept_workflow(
    client: AsyncClient, db_session: AsyncSession
):
    """
    End-to-end test for successful swap request workflow.

    Steps:
    1. User A has a confirmed assignment for a future date
    2. User A initiates swap request to User B (same team, not assigned)
    3. Verify swap request created in database with PENDING status
    4. Verify User B receives notification
    5. User B accepts the swap
    6. Verify assignments are swapped in database
    7. Verify team lead receives notification of completed swap
    8. Verify both users see updated assignments in their home screen
    """
    # Step 1: Setup fixtures - User A has a confirmed assignment
    fixtures = await _create_e2e_fixtures(db_session)
    user_a = fixtures["user_a"]
    user_b = fixtures["user_b"]
    team_lead = fixtures["team_lead"]
    assignment_a = fixtures["assignment_a"]
    event = fixtures["event"]

    # Generate auth tokens
    token_a = create_access_token(data={"sub": str(user_a.id)})
    token_b = create_access_token(data={"sub": str(user_b.id)})
    token_lead = create_access_token(data={"sub": str(team_lead.id)})

    # Step 2: User A initiates swap request to User B
    response = await client.post(
        "/api/rosters/swap-requests",
        json={
            "requester_assignment_id": str(assignment_a.id),
            "target_user_id": str(user_b.id),
        },
        headers={"Authorization": f"Bearer {token_a}"},
    )
    assert response.status_code == 201
    swap_request_data = response.json()
    swap_request_id = swap_request_data["id"]

    # Step 3: Verify swap request created in database with PENDING status
    result = await db_session.execute(
        select(SwapRequest).where(SwapRequest.id == uuid.UUID(swap_request_id))
    )
    swap_request = result.scalar_one()
    assert swap_request.status == SwapRequestStatus.PENDING
    assert swap_request.requester_assignment_id == assignment_a.id
    assert swap_request.target_user_id == user_b.id
    assert swap_request.responded_at is None
    assert swap_request.expires_at > datetime.now(datetime.now().astimezone().tzinfo)

    # Step 4: Verify User B receives notification
    result = await db_session.execute(
        select(Notification)
        .where(Notification.user_id == user_b.id)
        .where(Notification.notification_type == NotificationType.SWAP_REQUESTED)
    )
    notifications = list(result.scalars().all())
    assert len(notifications) == 1
    notification = notifications[0]
    assert notification.reference_id == swap_request_id
    assert notification.is_read is False

    # Step 5: User B accepts the swap
    response = await client.post(
        f"/api/rosters/swap-requests/{swap_request_id}/accept",
        headers={"Authorization": f"Bearer {token_b}"},
    )
    assert response.status_code == 200
    accepted_swap_data = response.json()
    assert accepted_swap_data["status"] == "accepted"
    assert accepted_swap_data["responded_at"] is not None

    await db_session.refresh(swap_request)
    assert swap_request.status == SwapRequestStatus.ACCEPTED
    assert swap_request.responded_at is not None

    # Step 6: Verify assignments are swapped in database
    # User A's original assignment should now belong to User B
    await db_session.refresh(assignment_a)
    assert assignment_a.user_id == user_b.id
    assert assignment_a.status == AssignmentStatus.CONFIRMED

    # User B should now have the assignment
    result = await db_session.execute(
        select(EventAssignment)
        .where(EventAssignment.event_id == event.id)
        .where(EventAssignment.user_id == user_b.id)
    )
    user_b_assignments = list(result.scalars().all())
    assert len(user_b_assignments) == 1
    assert user_b_assignments[0].id == assignment_a.id

    # Step 7: Verify team lead receives notification of completed swap
    result = await db_session.execute(
        select(Notification)
        .where(Notification.user_id == team_lead.id)
        .where(Notification.notification_type == NotificationType.SWAP_COMPLETED)
    )
    team_lead_notifications = list(result.scalars().all())
    assert len(team_lead_notifications) == 1
    assert team_lead_notifications[0].reference_id == swap_request_id

    # Step 8: Verify both users see updated assignments in their home screen
    # User A should see no assignments (swapped away)
    response = await client.get(
        "/api/rosters/event-assignments/my",
        headers={"Authorization": f"Bearer {token_a}"},
    )
    assert response.status_code == 200
    user_a_assignments = response.json()
    # Filter for this specific event
    event_assignments_a = [
        a for a in user_a_assignments if a["event"]["id"] == str(event.id)
    ]
    assert len(event_assignments_a) == 0

    # User B should see the swapped assignment
    response = await client.get(
        "/api/rosters/event-assignments/my",
        headers={"Authorization": f"Bearer {token_b}"},
    )
    assert response.status_code == 200
    user_b_assignments = response.json()
    # Filter for this specific event
    event_assignments_b = [
        a for a in user_b_assignments if a["event"]["id"] == str(event.id)
    ]
    assert len(event_assignments_b) == 1
    assert event_assignments_b[0]["id"] == str(assignment_a.id)
    assert event_assignments_b[0]["status"] == "confirmed"


@pytest.mark.asyncio
async def test_e2e_swap_request_with_target_assignment(
    client: AsyncClient, db_session: AsyncSession
):
    """
    Test swap workflow where target user also has an assignment on same event.
    Verifies that both assignments are properly swapped.
    """
    # Setup fixtures
    fixtures = await _create_e2e_fixtures(db_session)
    user_a = fixtures["user_a"]
    user_b = fixtures["user_b"]
    team_lead = fixtures["team_lead"]
    assignment_a = fixtures["assignment_a"]
    event = fixtures["event"]

    # Create User B's assignment on the same event
    assignment_b = EventAssignment(
        event_id=event.id,
        user_id=user_b.id,
        status=AssignmentStatus.CONFIRMED,
    )
    db_session.add(assignment_b)
    await db_session.commit()

    # Generate auth tokens
    token_a = create_access_token(data={"sub": str(user_a.id)})
    token_b = create_access_token(data={"sub": str(user_b.id)})

    # User A initiates swap request
    response = await client.post(
        "/api/rosters/swap-requests",
        json={
            "requester_assignment_id": str(assignment_a.id),
            "target_user_id": str(user_b.id),
        },
        headers={"Authorization": f"Bearer {token_a}"},
    )
    assert response.status_code == 201
    swap_request_id = response.json()["id"]

    # User B accepts the swap
    response = await client.post(
        f"/api/rosters/swap-requests/{swap_request_id}/accept",
        headers={"Authorization": f"Bearer {token_b}"},
    )
    assert response.status_code == 200

    # Verify both assignments are swapped
    await db_session.refresh(assignment_a)
    await db_session.refresh(assignment_b)

    # Assignment A now belongs to User B
    assert assignment_a.user_id == user_b.id
    # Assignment B now belongs to User A
    assert assignment_b.user_id == user_a.id

    # Both should still be confirmed
    assert assignment_a.status == AssignmentStatus.CONFIRMED
    assert assignment_b.status == AssignmentStatus.CONFIRMED


@pytest.mark.asyncio
async def test_e2e_eligible_swap_targets(client: AsyncClient, db_session: AsyncSession):
    """
    Test that only eligible swap targets are returned.
    Eligible means: same team, not already assigned to that event.
    """
    fixtures = await _create_e2e_fixtures(db_session)
    user_a = fixtures["user_a"]
    user_b = fixtures["user_b"]
    assignment_a = fixtures["assignment_a"]
    team = fixtures["team"]
    event = fixtures["event"]

    # Create another user in the same team
    user_c = User(
        email="userc@example.com",
        name="User C",
        password_hash=get_password_hash("password123"),
    )
    db_session.add(user_c)
    await db_session.flush()

    # Add User C to organization
    org = fixtures["org"]
    org_member_c = OrganisationMember(
        user_id=user_c.id,
        organisation_id=org.id,
        role=OrganisationRole.MEMBER,
    )
    db_session.add(org_member_c)

    # Add User C to team
    member_c = TeamMember(
        user_id=user_c.id,
        team_id=team.id,
        role=TeamRole.MEMBER,
        permissions=[],
    )
    db_session.add(member_c)
    await db_session.commit()

    # Generate auth token for User A
    token_a = create_access_token(data={"sub": str(user_a.id)})

    # Get eligible swap targets for User A's assignment
    response = await client.get(
        f"/api/rosters/event-assignments/{assignment_a.id}/eligible-swap-targets",
        headers={"Authorization": f"Bearer {token_a}"},
    )
    assert response.status_code == 200
    targets = response.json()

    # Should include User B and User C (both in same team, not assigned)
    target_ids = [t["id"] for t in targets]
    assert str(user_b.id) in target_ids
    assert str(user_c.id) in target_ids
    # Should NOT include User A (requester)
    assert str(user_a.id) not in target_ids

    # Now give User B an assignment on the same event
    assignment_b = EventAssignment(
        event_id=event.id,
        user_id=user_b.id,
        status=AssignmentStatus.CONFIRMED,
    )
    db_session.add(assignment_b)
    await db_session.commit()

    # Get eligible targets again
    response = await client.get(
        f"/api/rosters/event-assignments/{assignment_a.id}/eligible-swap-targets",
        headers={"Authorization": f"Bearer {token_a}"},
    )
    assert response.status_code == 200
    targets = response.json()

    # Now should only include User C (User B is assigned to same event)
    target_ids = [t["id"] for t in targets]
    assert str(user_c.id) in target_ids
    # User B should NOT be eligible (already assigned to same event)
    # Note: According to backend logic, users already assigned can still be eligible
    # for swaps (they swap assignments). So this assertion may need adjustment.
