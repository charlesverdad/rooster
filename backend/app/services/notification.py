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

    async def has_notification(
        self,
        user_id: uuid.UUID,
        notification_type: str,
        reference_id: uuid.UUID,
    ) -> bool:
        """Check if a notification already exists for a user with given type and reference."""
        result = await self.db.execute(
            select(Notification).where(
                Notification.user_id == user_id,
                Notification.type == notification_type,
                Notification.reference_id == reference_id,
            )
        )
        return result.scalar_one_or_none() is not None

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
        self,
        user_id: uuid.UUID,
        team_id: uuid.UUID,
        team_name: str,
        team_lead_ids: list[uuid.UUID] | None = None,
        user_name: str | None = None,
    ) -> Notification:
        """Create a notification when a user joins a team.

        Also notifies team leads that a new member has joined.
        """
        from app.services.push import PushService

        title = "Team Joined"
        message = f"You've joined {team_name}"

        notification = await self.create_notification(
            NotificationCreate(
                user_id=user_id,
                type=NotificationType.TEAM_JOINED,
                title=title,
                message=message,
                reference_id=team_id,
            )
        )

        # Send push to the joining user
        try:
            push_service = PushService(self.db)
            await push_service.send_to_user(
                user_id=user_id,
                title=title,
                body=message,
                url=f"/teams/{team_id}",
            )
        except Exception:
            pass

        # Notify team leads that someone joined
        if team_lead_ids and user_name:
            lead_title = "New Team Member"
            lead_message = f"{user_name} has joined {team_name}"
            try:
                push_service = PushService(self.db)
                for lead_id in team_lead_ids:
                    if lead_id == user_id:
                        continue
                    await self.create_notification(
                        NotificationCreate(
                            user_id=lead_id,
                            type=NotificationType.TEAM_JOINED,
                            title=lead_title,
                            message=lead_message,
                            reference_id=team_id,
                        )
                    )
                    await push_service.send_to_user(
                        user_id=lead_id,
                        title=lead_title,
                        body=lead_message,
                        url=f"/teams/{team_id}",
                    )
            except Exception:
                pass

        return notification

    async def notify_assignment_created_with_email(
        self,
        assignment_id: uuid.UUID,
        user_id: uuid.UUID,
        user_name: str,
        user_email: str | None,
        roster_name: str,
        team_name: str,
        event_date: datetime,
        event_time: str | None = None,
    ) -> Notification:
        """Create notification and send email for new assignment.

        Args:
            assignment_id: The assignment ID
            user_id: The user being assigned
            user_name: The user's name
            user_email: The user's email (if available)
            roster_name: Name of the roster
            team_name: Name of the team
            event_date: Date of the event
            event_time: Time of the event (optional)

        Returns:
            The created notification
        """
        from app.services.email import get_email_service

        title = "New Assignment"
        formatted_date = event_date.strftime("%B %d, %Y")
        message = f"You've been assigned to {roster_name} on {formatted_date}"

        # Create in-app notification
        notification = await self.create_notification(
            NotificationCreate(
                user_id=user_id,
                type=NotificationType.ASSIGNMENT_CREATED,
                title=title,
                message=message,
                reference_id=assignment_id,
            )
        )

        # Send email if user has email
        if user_email:
            email_service = get_email_service()
            await email_service.send_assignment_notification(
                to_email=user_email,
                user_name=user_name,
                roster_name=roster_name,
                team_name=team_name,
                event_date=formatted_date,
                event_time=event_time,
            )

        # Send push notification with accept/decline actions
        try:
            from app.services.push import PushService

            push_service = PushService(self.db)
            await push_service.send_to_user(
                user_id=user_id,
                title=title,
                body=message,
                url=f"/assignments/{assignment_id}",
                actions=[
                    {"action": "accept", "title": "Accept"},
                    {"action": "decline", "title": "Decline"},
                ],
                tag=f"assignment-{assignment_id}",
                data={
                    "assignment_id": str(assignment_id),
                    "accept_url": f"/api/event-assignments/{assignment_id}/accept",
                    "url": f"/assignments/{assignment_id}",
                },
            )
        except ImportError:
            pass

        return notification

    async def notify_assignment_confirmed(
        self,
        user_name: str,
        roster_name: str,
        event_date: datetime,
        team_lead_ids: list[uuid.UUID],
        assignment_id: uuid.UUID,
    ) -> list[Notification]:
        """Notify team leads when an assignment is accepted."""
        from app.services.push import PushService

        title = f"{user_name} accepted"
        formatted_date = event_date.strftime("%B %d, %Y")
        message = f"Confirmed for {roster_name} on {formatted_date}"

        notifications = []
        push_service = PushService(self.db)

        for lead_id in team_lead_ids:
            notification = await self.create_notification(
                NotificationCreate(
                    user_id=lead_id,
                    type=NotificationType.ASSIGNMENT_CONFIRMED,
                    title=title,
                    message=message,
                    reference_id=assignment_id,
                )
            )
            notifications.append(notification)

            try:
                await push_service.send_to_user(
                    user_id=lead_id,
                    title=title,
                    body=message,
                    url=f"/assignments/{assignment_id}",
                )
            except Exception:
                pass

        return notifications

    async def notify_assignment_declined(
        self,
        user_name: str,
        roster_name: str,
        event_date: datetime,
        event_id: uuid.UUID,
        team_lead_ids: list[uuid.UUID],
        assignment_id: uuid.UUID,
    ) -> list[Notification]:
        """Notify team leads when an assignment is declined."""
        from app.services.push import PushService

        title = f"{user_name} declined"
        formatted_date = event_date.strftime("%B %d, %Y")
        message = f"Declined {roster_name} on {formatted_date}"

        notifications = []
        push_service = PushService(self.db)

        for lead_id in team_lead_ids:
            notification = await self.create_notification(
                NotificationCreate(
                    user_id=lead_id,
                    type=NotificationType.ASSIGNMENT_DECLINED,
                    title=title,
                    message=message,
                    reference_id=assignment_id,
                )
            )
            notifications.append(notification)

            try:
                await push_service.send_to_user(
                    user_id=lead_id,
                    title=title,
                    body=message,
                    url=f"/events/{event_id}",
                    actions=[{"action": "reassign", "title": "Reassign"}],
                    data={"url": f"/events/{event_id}"},
                )
            except Exception:
                pass

        return notifications

    async def notify_team_invite(
        self,
        user_id: uuid.UUID,
        team_name: str,
        team_id: uuid.UUID,
    ) -> Notification:
        """Notify a user when they are invited to a team."""
        from app.services.push import PushService

        title = "Team Invitation"
        message = f"You've been invited to join {team_name}"

        notification = await self.create_notification(
            NotificationCreate(
                user_id=user_id,
                type=NotificationType.TEAM_INVITE,
                title=title,
                message=message,
                reference_id=team_id,
            )
        )

        try:
            push_service = PushService(self.db)
            await push_service.send_to_user(
                user_id=user_id,
                title=title,
                body=message,
                url=f"/teams/{team_id}",
            )
        except Exception:
            pass

        return notification

    async def notify_team_removed(
        self,
        user_id: uuid.UUID,
        team_name: str,
        team_id: uuid.UUID,
    ) -> Notification:
        """Notify a user when they are removed from a team (in-app only)."""
        title = "Removed from Team"
        message = f"You've been removed from {team_name}"

        return await self.create_notification(
            NotificationCreate(
                user_id=user_id,
                type=NotificationType.TEAM_REMOVED,
                title=title,
                message=message,
                reference_id=team_id,
            )
        )
