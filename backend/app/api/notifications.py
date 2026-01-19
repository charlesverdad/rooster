import uuid

from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import CurrentUser, DbSession
from app.schemas.notification import NotificationResponse
from app.services.notification import NotificationService

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("", response_model=list[NotificationResponse])
async def list_notifications(
    current_user: CurrentUser,
    db: DbSession,
    unread_only: bool = Query(False),
) -> list[NotificationResponse]:
    """List all notifications for the current user."""
    service = NotificationService(db)
    notifications = await service.get_user_notifications(
        current_user.id, unread_only=unread_only
    )
    return [NotificationResponse.model_validate(n) for n in notifications]


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
async def mark_as_read(
    notification_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> NotificationResponse:
    """Mark a notification as read. User can only mark their own."""
    service = NotificationService(db)
    
    # First check if the notification belongs to the user
    notifications = await service.get_user_notifications(current_user.id)
    if not any(n.id == notification_id for n in notifications):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found or not authorized",
        )
    
    notification = await service.mark_as_read(notification_id)
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )
    
    return NotificationResponse.model_validate(notification)


@router.patch("/read-all", status_code=status.HTTP_200_OK)
async def mark_all_as_read(
    current_user: CurrentUser,
    db: DbSession,
) -> dict[str, int]:
    """Mark all notifications as read for the current user."""
    service = NotificationService(db)
    count = await service.mark_all_as_read(current_user.id)
    return {"marked_read": count}


@router.delete("/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_notification(
    notification_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> None:
    """Delete a notification. User can only delete their own."""
    service = NotificationService(db)
    
    # First check if the notification belongs to the user
    notifications = await service.get_user_notifications(current_user.id)
    if not any(n.id == notification_id for n in notifications):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found or not authorized",
        )
    
    await service.delete_notification(notification_id)
