#!/usr/bin/env python3
"""
Script to expire old swap requests and send notifications.

This script should be run periodically (e.g., via cron) to:
1. Find and expire swap requests that are past their expiration date
2. Send notifications to requesters about expired requests

Usage:
    uv run python scripts/expire_swap_requests.py
"""

import asyncio
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import async_engine, async_session_maker
from app.models.roster import EventAssignment
from app.models.swap_request import SwapRequest, SwapRequestStatus
from app.services.notification import NotificationService
from app.services.swap_request import SwapRequestService


async def expire_requests_with_notifications():
    """Expire old swap requests and send notifications."""
    async with async_session_maker() as session:
        swap_service = SwapRequestService(session)
        notification_service = NotificationService(session)

        # Get all pending requests that have expired
        now = datetime.now(datetime.now().astimezone().tzinfo)
        result = await session.execute(
            select(SwapRequest)
            .options(
                selectinload(SwapRequest.requester_assignment)
                .selectinload(EventAssignment.event)
                .selectinload(EventAssignment.user)
            )
            .where(
                SwapRequest.status == SwapRequestStatus.PENDING,
                SwapRequest.expires_at <= now,
            )
        )
        expired_requests = list(result.scalars().all())

        print(f"Found {len(expired_requests)} expired swap requests")

        # Expire each request and send notification
        for swap_request in expired_requests:
            # Update status to EXPIRED
            swap_request.status = SwapRequestStatus.EXPIRED
            session.add(swap_request)

            # Get requester info
            requester_assignment = swap_request.requester_assignment
            requester_user_id = requester_assignment.user_id
            event_date = requester_assignment.event.date.strftime("%B %d, %Y")

            # Send notification to requester
            try:
                notification = await notification_service.notify_swap_expired(
                    requester_user_id=requester_user_id,
                    event_date=event_date,
                    swap_request_id=swap_request.id,
                )
                print(
                    f"  ✓ Expired swap request {swap_request.id} and notified user {requester_user_id}"
                )
            except Exception as e:
                print(
                    f"  ✗ Error notifying user {requester_user_id} for swap request {swap_request.id}: {e}"
                )

        # Commit all changes
        await session.commit()
        print(f"\nSuccessfully expired {len(expired_requests)} swap requests")

        return len(expired_requests)


async def main():
    """Main entry point."""
    print("=" * 60)
    print("Swap Request Expiration Job")
    print("=" * 60)
    print()

    try:
        expired_count = await expire_requests_with_notifications()
        print()
        print("=" * 60)
        print(f"Job completed. Expired {expired_count} requests.")
        print("=" * 60)
        return 0
    except Exception as e:
        print()
        print("=" * 60)
        print(f"ERROR: {e}")
        print("=" * 60)
        import traceback

        traceback.print_exc()
        return 1
    finally:
        # Close the database engine
        await async_engine.dispose()


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    exit(exit_code)
