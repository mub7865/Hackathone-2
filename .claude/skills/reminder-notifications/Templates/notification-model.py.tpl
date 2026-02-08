"""
Notification Database Models

This module defines SQLModel models for notification storage and tracking.
"""

from sqlmodel import SQLModel, Field, Relationship
from datetime import datetime
from typing import Optional, Dict, Any
from enum import Enum
import json


class NotificationChannel(str, Enum):
    """Notification delivery channels."""
    EMAIL = "email"
    SMS = "sms"
    PUSH = "push"
    IN_APP = "in_app"


class NotificationStatus(str, Enum):
    """Notification delivery status."""
    QUEUED = "queued"
    SENDING = "sending"
    SENT = "sent"
    DELIVERED = "delivered"
    FAILED = "failed"
    BOUNCED = "bounced"
    OPENED = "opened"
    CLICKED = "clicked"


class NotificationPriority(str, Enum):
    """Notification priority levels."""
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    URGENT = "urgent"


class Notification(SQLModel, table=True):
    """Notification model for tracking all notifications."""
    __tablename__ = "notifications"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: str = Field(index=True)

    # Channel and template
    channel: NotificationChannel = Field(index=True)
    template_name: str

    # Content (stored as JSON)
    data: Dict[str, Any] = Field(default_factory=dict, sa_column_kwargs={"type_": "JSON"})

    # Status tracking
    status: NotificationStatus = Field(default=NotificationStatus.QUEUED, index=True)
    priority: NotificationPriority = Field(default=NotificationPriority.NORMAL)

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)
    scheduled_for: Optional[datetime] = Field(default=None, index=True)
    sent_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    read_at: Optional[datetime] = None
    clicked_at: Optional[datetime] = None

    # Provider tracking
    provider_message_id: Optional[str] = None
    provider_name: Optional[str] = None

    # Error handling
    error_message: Optional[str] = None
    retry_count: int = Field(default=0)
    max_retries: int = Field(default=3)

    # In-app specific
    in_app_content: Optional[Dict[str, Any]] = Field(default=None, sa_column_kwargs={"type_": "JSON"})

    # Metadata
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict, sa_column_kwargs={"type_": "JSON"})

    def is_delivered(self) -> bool:
        """Check if notification was delivered."""
        return self.status in [
            NotificationStatus.DELIVERED,
            NotificationStatus.OPENED,
            NotificationStatus.CLICKED
        ]

    def is_failed(self) -> bool:
        """Check if notification failed."""
        return self.status in [NotificationStatus.FAILED, NotificationStatus.BOUNCED]

    def can_retry(self) -> bool:
        """Check if notification can be retried."""
        return self.is_failed() and self.retry_count < self.max_retries


class NotificationPreference(SQLModel, table=True):
    """User notification preferences."""
    __tablename__ = "notification_preferences"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: str = Field(index=True, unique=True)

    # Channel preferences
    email_enabled: bool = Field(default=True)
    sms_enabled: bool = Field(default=True)
    push_enabled: bool = Field(default=True)
    in_app_enabled: bool = Field(default=True)

    # Frequency preferences
    email_frequency: str = Field(default="immediate")  # immediate, daily, weekly
    digest_time: Optional[str] = Field(default="09:00")  # Time for daily digest

    # Quiet hours
    quiet_hours_enabled: bool = Field(default=False)
    quiet_hours_start: Optional[str] = Field(default="22:00")
    quiet_hours_end: Optional[str] = Field(default="08:00")
    quiet_hours_timezone: str = Field(default="UTC")

    # Category preferences (stored as JSON)
    category_preferences: Dict[str, bool] = Field(
        default_factory=lambda: {
            "task_reminders": True,
            "task_updates": True,
            "system_notifications": True,
            "marketing": False
        },
        sa_column_kwargs={"type_": "JSON"}
    )

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    def is_channel_enabled(self, channel: NotificationChannel) -> bool:
        """Check if channel is enabled."""
        if channel == NotificationChannel.EMAIL:
            return self.email_enabled
        elif channel == NotificationChannel.SMS:
            return self.sms_enabled
        elif channel == NotificationChannel.PUSH:
            return self.push_enabled
        elif channel == NotificationChannel.IN_APP:
            return self.in_app_enabled
        return False

    def is_category_enabled(self, category: str) -> bool:
        """Check if notification category is enabled."""
        return self.category_preferences.get(category, True)


class NotificationTemplate(SQLModel, table=True):
    """Notification templates."""
    __tablename__ = "notification_templates"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(index=True, unique=True)
    channel: NotificationChannel = Field(index=True)

    # Template content
    subject: Optional[str] = None  # For email
    title: Optional[str] = None  # For push
    body_text: str
    body_html: Optional[str] = None  # For email

    # Variables used in template
    variables: list[str] = Field(default_factory=list, sa_column_kwargs={"type_": "JSON"})

    # Metadata
    category: Optional[str] = None
    description: Optional[str] = None
    is_active: bool = Field(default=True)

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class NotificationLog(SQLModel, table=True):
    """Detailed notification event log."""
    __tablename__ = "notification_logs"

    id: Optional[int] = Field(default=None, primary_key=True)
    notification_id: int = Field(foreign_key="notifications.id", index=True)

    # Event details
    event_type: str = Field(index=True)  # queued, sent, delivered, opened, clicked, failed
    event_data: Optional[Dict[str, Any]] = Field(default=None, sa_column_kwargs={"type_": "JSON"})

    # Timestamp
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)


class NotificationBatch(SQLModel, table=True):
    """Batch notification tracking."""
    __tablename__ = "notification_batches"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str

    # Batch details
    channel: NotificationChannel
    template_name: str
    total_count: int = Field(default=0)
    sent_count: int = Field(default=0)
    failed_count: int = Field(default=0)

    # Status
    status: str = Field(default="pending")  # pending, processing, completed, failed

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


class NotificationWebhook(SQLModel, table=True):
    """Webhook events from notification providers."""
    __tablename__ = "notification_webhooks"

    id: Optional[int] = Field(default=None, primary_key=True)
    notification_id: Optional[int] = Field(default=None, foreign_key="notifications.id", index=True)

    # Provider details
    provider: str = Field(index=True)
    provider_message_id: Optional[str] = Field(index=True)

    # Event details
    event_type: str = Field(index=True)
    event_data: Dict[str, Any] = Field(default_factory=dict, sa_column_kwargs={"type_": "JSON"})

    # Raw webhook data
    raw_data: Dict[str, Any] = Field(default_factory=dict, sa_column_kwargs={"type_": "JSON"})

    # Processing
    processed: bool = Field(default=False, index=True)
    processed_at: Optional[datetime] = None

    # Timestamp
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)


# Pydantic models for API
class NotificationCreate(SQLModel):
    """Create notification request."""
    user_id: str
    channel: NotificationChannel
    template_name: str
    data: Dict[str, Any]
    priority: NotificationPriority = NotificationPriority.NORMAL
    scheduled_for: Optional[datetime] = None


class NotificationResponse(SQLModel):
    """Notification response."""
    id: int
    user_id: str
    channel: NotificationChannel
    template_name: str
    status: NotificationStatus
    created_at: datetime
    sent_at: Optional[datetime]
    delivered_at: Optional[datetime]
    read_at: Optional[datetime]


class NotificationPreferenceUpdate(SQLModel):
    """Update notification preferences."""
    email_enabled: Optional[bool] = None
    sms_enabled: Optional[bool] = None
    push_enabled: Optional[bool] = None
    in_app_enabled: Optional[bool] = None
    email_frequency: Optional[str] = None
    quiet_hours_enabled: Optional[bool] = None
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None
    category_preferences: Optional[Dict[str, bool]] = None


class NotificationStats(SQLModel):
    """Notification statistics."""
    total_sent: int
    total_delivered: int
    total_failed: int
    total_opened: int
    total_clicked: int
    delivery_rate: float
    open_rate: float
    click_rate: float


# Helper functions
def get_notification_stats(
    session,
    user_id: Optional[str] = None,
    channel: Optional[NotificationChannel] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None
) -> NotificationStats:
    """Get notification statistics."""
    from sqlmodel import select, func

    query = select(Notification)

    if user_id:
        query = query.where(Notification.user_id == user_id)
    if channel:
        query = query.where(Notification.channel == channel)
    if start_date:
        query = query.where(Notification.created_at >= start_date)
    if end_date:
        query = query.where(Notification.created_at <= end_date)

    notifications = session.exec(query).all()

    total_sent = sum(1 for n in notifications if n.status != NotificationStatus.QUEUED)
    total_delivered = sum(1 for n in notifications if n.is_delivered())
    total_failed = sum(1 for n in notifications if n.is_failed())
    total_opened = sum(1 for n in notifications if n.status == NotificationStatus.OPENED)
    total_clicked = sum(1 for n in notifications if n.status == NotificationStatus.CLICKED)

    delivery_rate = (total_delivered / total_sent * 100) if total_sent > 0 else 0
    open_rate = (total_opened / total_delivered * 100) if total_delivered > 0 else 0
    click_rate = (total_clicked / total_delivered * 100) if total_delivered > 0 else 0

    return NotificationStats(
        total_sent=total_sent,
        total_delivered=total_delivered,
        total_failed=total_failed,
        total_opened=total_opened,
        total_clicked=total_clicked,
        delivery_rate=round(delivery_rate, 2),
        open_rate=round(open_rate, 2),
        click_rate=round(click_rate, 2)
    )


# Example usage
if __name__ == "__main__":
    from sqlmodel import create_engine, Session, SQLModel

    # Create database
    engine = create_engine("sqlite:///notifications.db")
    SQLModel.metadata.create_all(engine)

    with Session(engine) as session:
        # Create notification
        notification = Notification(
            user_id="user_123",
            channel=NotificationChannel.EMAIL,
            template_name="task_reminder",
            data={"task_title": "Complete project", "due_date": "2024-01-10"}
        )
        session.add(notification)
        session.commit()

        print(f"Notification created: {notification.id}")

        # Create preferences
        preferences = NotificationPreference(
            user_id="user_123",
            email_enabled=True,
            sms_enabled=False
        )
        session.add(preferences)
        session.commit()

        print(f"Preferences created for user: {preferences.user_id}")
