import uuid
from datetime import datetime, timedelta
from typing import Optional

from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.roster import EventAssignment, RosterEvent
from app.models.swap_request import SwapRequest, SwapRequestStatus
from app.models.team import Team, TeamMember, TeamRole
from app.models.user import User
from app.schemas.swap_request import SwapRequestCreate


class SwapRequestService:
    """Service for swap request operations."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_swap_request(self, data: SwapRequestCreate) -> SwapRequest:
        """Create a new swap request.

        Args:
            data: Swap request creation data

        Returns:
            Created swap request
        """
        # Set expiration to 48 hours from now
        expires_at = datetime.now(datetime.now().astimezone().tzinfo) + timedelta(hours=48)

        swap_request = SwapRequest(
            requester_assignment_id=data.requester_assignment_id,
            target_user_id=data.target_user_id,
            status=SwapRequestStatus.PENDING,
            expires_at=expires_at,
        )
        self.db.add(swap_request)
        await self.db.flush()
        await self.db.refresh(swap_request)
        return swap_request

    async def get_swap_request(self, swap_request_id: uuid.UUID) -> SwapRequest | None:
        """Get a swap request by ID.

        Args:
            swap_request_id: Swap request ID

        Returns:
            Swap request or None if not found
        """
        result = await self.db.execute(
            select(SwapRequest)
            .options(
                selectinload(SwapRequest.requester_assignment).selectinload(EventAssignment.event),
                selectinload(SwapRequest.requester_assignment).selectinload(EventAssignment.user),
                selectinload(SwapRequest.target_user),
            )
            .where(SwapRequest.id == swap_request_id)
        )
        return result.scalar_one_or_none()

    async def get_user_swap_requests(
        self,
        user_id: uuid.UUID,
        status: Optional[SwapRequestStatus] = None,
    ) -> list[SwapRequest]:
        """Get all swap requests for a user (as requester or target).

        Args:
            user_id: User ID
            status: Optional status filter

        Returns:
            List of swap requests
        """
        # Get assignments for this user
        assignment_result = await self.db.execute(
            select(EventAssignment.id).where(EventAssignment.user_id == user_id)
        )
        assignment_ids = list(assignment_result.scalars().all())

        # Build query for requests where user is requester or target
        query = select(SwapRequest).where(
            or_(
                SwapRequest.requester_assignment_id.in_(assignment_ids),
                SwapRequest.target_user_id == user_id,
            )
        )

        if status:
            query = query.where(SwapRequest.status == status)

        query = query.order_by(SwapRequest.created_at.desc())

        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def accept_swap_request(
        self, swap_request_id: uuid.UUID, target_user_id: uuid.UUID
    ) -> SwapRequest | None:
        """Accept a swap request and swap the assignments.

        Args:
            swap_request_id: Swap request ID
            target_user_id: ID of the user accepting (must be the target user)

        Returns:
            Updated swap request or None if not found
        """
        swap_request = await self.get_swap_request(swap_request_id)
        if not swap_request:
            return None

        # Verify the user accepting is the target user
        if swap_request.target_user_id != target_user_id:
            return None

        # Verify request is still pending
        if swap_request.status != SwapRequestStatus.PENDING:
            return None

        # Get the requester's assignment
        requester_assignment = swap_request.requester_assignment
        event = requester_assignment.event

        # Check if target user already has an assignment on this event
        target_assignment_result = await self.db.execute(
            select(EventAssignment).where(
                and_(
                    EventAssignment.event_id == event.id,
                    EventAssignment.user_id == target_user_id,
                )
            )
        )
        target_assignment = target_assignment_result.scalar_one_or_none()

        # Swap the assignments
        if target_assignment:
            # Both users have assignments - swap them
            requester_assignment.user_id, target_assignment.user_id = (
                target_assignment.user_id,
                requester_assignment.user_id,
            )
        else:
            # Target doesn't have assignment - just reassign requester's to target
            requester_assignment.user_id = target_user_id

        # Update swap request status
        swap_request.status = SwapRequestStatus.ACCEPTED
        swap_request.responded_at = datetime.now(datetime.now().astimezone().tzinfo)

        await self.db.flush()
        await self.db.refresh(swap_request)
        return swap_request

    async def decline_swap_request(
        self, swap_request_id: uuid.UUID, target_user_id: uuid.UUID
    ) -> SwapRequest | None:
        """Decline a swap request.

        Args:
            swap_request_id: Swap request ID
            target_user_id: ID of the user declining (must be the target user)

        Returns:
            Updated swap request or None if not found
        """
        swap_request = await self.get_swap_request(swap_request_id)
        if not swap_request:
            return None

        # Verify the user declining is the target user
        if swap_request.target_user_id != target_user_id:
            return None

        # Verify request is still pending
        if swap_request.status != SwapRequestStatus.PENDING:
            return None

        swap_request.status = SwapRequestStatus.DECLINED
        swap_request.responded_at = datetime.now(datetime.now().astimezone().tzinfo)

        await self.db.flush()
        await self.db.refresh(swap_request)
        return swap_request

    async def expire_old_requests(self) -> int:
        """Mark expired swap requests as expired.

        Returns:
            Number of requests expired
        """
        now = datetime.now(datetime.now().astimezone().tzinfo)

        result = await self.db.execute(
            select(SwapRequest).where(
                and_(
                    SwapRequest.status == SwapRequestStatus.PENDING,
                    SwapRequest.expires_at <= now,
                )
            )
        )
        expired_requests = list(result.scalars().all())

        for request in expired_requests:
            request.status = SwapRequestStatus.EXPIRED

        await self.db.flush()
        return len(expired_requests)

    async def get_eligible_swap_targets(
        self, assignment_id: uuid.UUID
    ) -> list[User]:
        """Get eligible team members for swapping.

        A team member is eligible if they:
        - Are on the same team as the requester
        - Are not already assigned to the event
        - Are not the requester themselves

        Args:
            assignment_id: ID of the assignment to swap

        Returns:
            List of eligible users
        """
        # Get the assignment with its event and roster
        assignment_result = await self.db.execute(
            select(EventAssignment)
            .options(
                selectinload(EventAssignment.event).selectinload(RosterEvent.roster),
                selectinload(EventAssignment.user),
            )
            .where(EventAssignment.id == assignment_id)
        )
        assignment = assignment_result.scalar_one_or_none()
        if not assignment:
            return []

        event = assignment.event
        roster = event.roster
        team_id = roster.team_id
        requester_user_id = assignment.user_id

        # Get all users already assigned to this event
        assigned_users_result = await self.db.execute(
            select(EventAssignment.user_id).where(EventAssignment.event_id == event.id)
        )
        assigned_user_ids = list(assigned_users_result.scalars().all())

        # Get all team members for this team
        team_members_result = await self.db.execute(
            select(TeamMember)
            .options(selectinload(TeamMember.user))
            .where(TeamMember.team_id == team_id)
        )
        team_members = list(team_members_result.scalars().all())

        # Filter to eligible users
        eligible_users = []
        for member in team_members:
            user = member.user
            if user.id != requester_user_id and user.id not in assigned_user_ids:
                eligible_users.append(user)

        return eligible_users

    async def get_team_leads_for_assignment(
        self, assignment_id: uuid.UUID
    ) -> list[User]:
        """Get team leads for the team of an assignment.

        Used to notify team leads of completed swaps.

        Args:
            assignment_id: ID of the assignment

        Returns:
            List of team lead users
        """
        # Get the assignment with its event and roster
        assignment_result = await self.db.execute(
            select(EventAssignment)
            .options(
                selectinload(EventAssignment.event).selectinload(RosterEvent.roster)
            )
            .where(EventAssignment.id == assignment_id)
        )
        assignment = assignment_result.scalar_one_or_none()
        if not assignment:
            return []

        team_id = assignment.event.roster.team_id

        # Get team leads
        team_leads_result = await self.db.execute(
            select(TeamMember)
            .options(selectinload(TeamMember.user))
            .where(
                and_(
                    TeamMember.team_id == team_id,
                    TeamMember.role == TeamRole.LEAD,
                )
            )
        )
        team_leads = list(team_leads_result.scalars().all())

        return [member.user for member in team_leads]
