"""Push notification API endpoints."""

from typing import Optional

from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel

from app.api.deps import CurrentUser, DbSession
from app.core.config import get_settings
from app.services.push import PushService

router = APIRouter(prefix="/push", tags=["push"])


class PushSubscriptionRequest(BaseModel):
    """Request to subscribe to push notifications."""

    endpoint: str
    p256dh_key: str
    auth_key: str


class PushSubscriptionResponse(BaseModel):
    """Response after subscribing to push notifications."""

    success: bool
    message: str


@router.get("/vapid-public-key")
async def get_vapid_public_key() -> dict[str, str]:
    """Get the VAPID public key for push subscription.

    This endpoint is public as it's needed before authentication
    to set up push notifications.
    """
    settings = get_settings()
    if not settings.vapid_public_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Push notifications not configured",
        )
    return {"publicKey": settings.vapid_public_key}


@router.post("/subscribe", response_model=PushSubscriptionResponse)
async def subscribe_to_push(
    data: PushSubscriptionRequest,
    current_user: CurrentUser,
    db: DbSession,
    user_agent: Optional[str] = Header(None),
) -> PushSubscriptionResponse:
    """Register a push subscription for the current user.

    The subscription info comes from the browser's Push API.
    """
    push_service = PushService(db)

    if not push_service.is_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Push notifications not configured",
        )

    await push_service.subscribe(
        user_id=current_user.id,
        endpoint=data.endpoint,
        p256dh_key=data.p256dh_key,
        auth_key=data.auth_key,
        user_agent=user_agent,
    )

    return PushSubscriptionResponse(
        success=True,
        message="Subscribed to push notifications",
    )


@router.post("/unsubscribe", response_model=PushSubscriptionResponse)
async def unsubscribe_from_push(
    data: PushSubscriptionRequest,
    current_user: CurrentUser,
    db: DbSession,
) -> PushSubscriptionResponse:
    """Remove a push subscription for the current user."""
    push_service = PushService(db)

    removed = await push_service.unsubscribe(
        user_id=current_user.id,
        endpoint=data.endpoint,
    )

    if not removed:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Subscription not found",
        )

    return PushSubscriptionResponse(
        success=True,
        message="Unsubscribed from push notifications",
    )


@router.delete("/subscriptions", response_model=PushSubscriptionResponse)
async def unsubscribe_all(
    current_user: CurrentUser,
    db: DbSession,
) -> PushSubscriptionResponse:
    """Remove all push subscriptions for the current user."""
    push_service = PushService(db)
    count = await push_service.unsubscribe_all(current_user.id)

    return PushSubscriptionResponse(
        success=True,
        message=f"Removed {count} subscription(s)",
    )
