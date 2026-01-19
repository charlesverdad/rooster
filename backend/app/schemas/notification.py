import uuid
from datetime import datetime

from pydantic import BaseModel

from app.models.notification import NotificationType


class NotificationCreate(BaseModel):
    """Schema for creating a notification (internal use)."""

    user_id: uuid.UUID
    type: NotificationType
    title: str
    message: str


class NotificationResponse(BaseModel):
    """Schema for notification response."""

    id: uuid.UUID
    user_id: uuid.UUID
    type: NotificationType
    title: str
    message: str
    read_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}
