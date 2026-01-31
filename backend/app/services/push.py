"""Push notification service for Web Push notifications."""

import json
import logging
import uuid
from typing import Optional

from pywebpush import webpush, WebPushException
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.models.push_subscription import PushSubscription

logger = logging.getLogger(__name__)


class PushService:
    """Service for Web Push notification operations."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.settings = get_settings()

    @property
    def is_configured(self) -> bool:
        """Check if VAPID keys are configured."""
        return bool(self.settings.vapid_public_key and self.settings.vapid_private_key)

    async def subscribe(
        self,
        user_id: uuid.UUID,
        endpoint: str,
        p256dh_key: str,
        auth_key: str,
        user_agent: Optional[str] = None,
    ) -> PushSubscription:
        """Register a push subscription for a user.

        If the endpoint already exists, update the keys. This handles
        subscription renewal gracefully.

        Args:
            user_id: The user to subscribe
            endpoint: The push service endpoint URL
            p256dh_key: The p256dh encryption key
            auth_key: The auth secret
            user_agent: Optional user agent string

        Returns:
            The created or updated subscription
        """
        # Check for existing subscription with this endpoint
        result = await self.db.execute(
            select(PushSubscription).where(PushSubscription.endpoint == endpoint)
        )
        existing = result.scalar_one_or_none()

        if existing:
            # Update existing subscription
            existing.user_id = user_id
            existing.p256dh_key = p256dh_key
            existing.auth_key = auth_key
            existing.user_agent = user_agent
            await self.db.flush()
            await self.db.refresh(existing)
            return existing

        # Create new subscription
        subscription = PushSubscription(
            user_id=user_id,
            endpoint=endpoint,
            p256dh_key=p256dh_key,
            auth_key=auth_key,
            user_agent=user_agent,
        )
        self.db.add(subscription)
        await self.db.flush()
        await self.db.refresh(subscription)
        return subscription

    async def unsubscribe(self, user_id: uuid.UUID, endpoint: str) -> bool:
        """Remove a push subscription.

        Args:
            user_id: The user to unsubscribe
            endpoint: The push service endpoint URL to remove

        Returns:
            True if a subscription was removed, False otherwise
        """
        result = await self.db.execute(
            delete(PushSubscription).where(
                PushSubscription.user_id == user_id,
                PushSubscription.endpoint == endpoint,
            )
        )
        return result.rowcount > 0

    async def unsubscribe_all(self, user_id: uuid.UUID) -> int:
        """Remove all push subscriptions for a user.

        Args:
            user_id: The user to unsubscribe

        Returns:
            Number of subscriptions removed
        """
        result = await self.db.execute(
            delete(PushSubscription).where(PushSubscription.user_id == user_id)
        )
        return result.rowcount

    async def get_user_subscriptions(
        self, user_id: uuid.UUID
    ) -> list[PushSubscription]:
        """Get all push subscriptions for a user.

        Args:
            user_id: The user to get subscriptions for

        Returns:
            List of subscriptions
        """
        result = await self.db.execute(
            select(PushSubscription).where(PushSubscription.user_id == user_id)
        )
        return list(result.scalars().all())

    async def send_to_user(
        self,
        user_id: uuid.UUID,
        title: str,
        body: str,
        url: Optional[str] = None,
        icon: Optional[str] = None,
    ) -> int:
        """Send a push notification to all of a user's subscriptions.

        Args:
            user_id: The user to notify
            title: Notification title
            body: Notification body text
            url: URL to open when notification is clicked
            icon: URL to notification icon

        Returns:
            Number of notifications successfully sent
        """
        if not self.is_configured:
            logger.warning("Push notifications not configured - VAPID keys missing")
            return 0

        subscriptions = await self.get_user_subscriptions(user_id)
        if not subscriptions:
            return 0

        payload = {
            "title": title,
            "body": body,
        }
        if url:
            payload["url"] = url
        if icon:
            payload["icon"] = icon

        sent = 0
        for subscription in subscriptions:
            success = await self._send_notification(subscription, payload)
            if success:
                sent += 1

        return sent

    async def _send_notification(
        self, subscription: PushSubscription, payload: dict
    ) -> bool:
        """Send a notification to a single subscription.

        Args:
            subscription: The push subscription
            payload: The notification payload

        Returns:
            True if sent successfully, False otherwise
        """
        subscription_info = {
            "endpoint": subscription.endpoint,
            "keys": {
                "p256dh": subscription.p256dh_key,
                "auth": subscription.auth_key,
            },
        }

        vapid_claims = {
            "sub": self.settings.vapid_subject,
        }

        try:
            webpush(
                subscription_info=subscription_info,
                data=json.dumps(payload),
                vapid_private_key=self.settings.vapid_private_key,
                vapid_claims=vapid_claims,
            )
            logger.info(f"Push notification sent to {subscription.endpoint[:50]}...")
            return True
        except WebPushException as e:
            logger.error(f"Push notification failed: {e}")
            # If subscription is invalid (410 Gone or 404), remove it
            if e.response and e.response.status_code in (404, 410):
                logger.info(
                    f"Removing invalid subscription: {subscription.endpoint[:50]}..."
                )
                await self.db.delete(subscription)
            return False
        except Exception as e:
            logger.error(f"Unexpected error sending push notification: {e}")
            return False
