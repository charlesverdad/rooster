import uuid
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification, NotificationType
from app.models.roster import Assignment
from app.schemas.notification import NotificationCreate


class NotificationService:
    """Service for notification operations."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_notification(self, data: NotificationCreate) -> Notification:
        """Create a new notification."""
        notification = Notification(
            user_id=data.user_id,
            type=data.type,
            title=data.title,
            message=data.message,
            reference_id=data.reference_id,
        )
        self.db.add(notification)
        await self.db.flush()
        await self.db.refresh(notification)
        return notification

    async def get_user_notifications(
        self,
        user_id: uuid.UUID,
        unread_only: bool = False,
    ) -> list[Notification]:
        """Get all notifications for a user."""
        query = select(Notification).where(Notification.user_id == user_id)
        if unread_only:
            query = query.where(Notification.read_at.is_(None))
        query = query.order_by(Notification.created_at.desc())
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def mark_as_read(self, notification_id: uuid.UUID) -> Notification | None:
        """Mark a notification as read."""
        result = await self.db.execute(
            select(Notification).where(Notification.id == notification_id)
        )
        notification = result.scalar_one_or_none()
        if not notification:
            return None
        notification.read_at = datetime.now(datetime.now().astimezone().tzinfo)
        await self.db.flush()
        await self.db.refresh(notification)
        return notification

    async def mark_all_as_read(self, user_id: uuid.UUID) -> int:
        """Mark all notifications as read for a user."""
        notifications = await self.get_user_notifications(user_id, unread_only=True)
        count = 0
        for notification in notifications:
            notification.read_at = datetime.now(datetime.now().astimezone().tzinfo)
            count += 1
        await self.db.flush()
        return count

    async def delete_notification(self, notification_id: uuid.UUID) -> bool:
        """Delete a notification."""
        result = await self.db.execute(
            select(Notification).where(Notification.id == notification_id)
        )
        notification = result.scalar_one_or_none()
        if not notification:
            return False
        await self.db.delete(notification)
        return True

    async def notify_assignment_created(self, assignment: Assignment) -> Notification:
        """Create a notification when an assignment is created."""
        from app.services.roster import RosterService

        roster_service = RosterService(self.db)
        roster = await roster_service.get_roster(assignment.roster_id)

        title = "New Assignment"
        message = f"You have been assigned to {roster.name if roster else 'a roster'} on {assignment.date.strftime('%B %d, %Y')}"

        return await self.create_notification(
            NotificationCreate(
                user_id=assignment.user_id,
                type=NotificationType.ASSIGNMENT_CREATED,
                title=title,
                message=message,
            )
        )

    async def notify_conflict_detected(
        self, user_id: uuid.UUID, date: str, roster_name: str
    ) -> Notification:
        """Create a notification when a conflict is detected."""
        title = "Schedule Conflict Detected"
        message = f"You are marked unavailable on {date} but assigned to {roster_name}"

        return await self.create_notification(
            NotificationCreate(
                user_id=user_id,
                type=NotificationType.CONFLICT_DETECTED,
                title=title,
                message=message,
            )
        )

    async def notify_team_joined(
        self, user_id: uuid.UUID, team_id: uuid.UUID, team_name: str
    ) -> Notification:
        """Create a notification when a user joins a team."""
        title = "Team Joined"
        message = f"You've joined {team_name}"

        return await self.create_notification(
            NotificationCreate(
                user_id=user_id,
                type=NotificationType.TEAM_JOINED,
                title=title,
                message=message,
                reference_id=team_id,
            )
        )
