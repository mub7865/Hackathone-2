"""NotificationPreferences model for user notification settings.

This module defines the NotificationPreferences entity for managing
user-specific notification settings including channels, quiet hours, and frequency.
"""

from datetime import datetime, time
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4

from sqlalchemy import Column, DateTime, Index, String, Time, func
from sqlmodel import Field, SQLModel


class NotificationChannel(str, Enum):
    """Valid notification channels.

    Attributes:
        EMAIL: Email notifications.
        IN_APP: In-app notifications (WebSocket).
        PUSH: Push notifications (future).
        SMS: SMS notifications (future).
    """

    EMAIL = "email"
    IN_APP = "in_app"
    PUSH = "push"
    SMS = "sms"


class NotificationFrequency(str, Enum):
    """Notification frequency settings.

    Attributes:
        IMMEDIATE: Send notifications immediately.
        HOURLY: Batch notifications hourly.
        DAILY: Batch notifications daily.
        WEEKLY: Batch notifications weekly.
    """

    IMMEDIATE = "immediate"
    HOURLY = "hourly"
    DAILY = "daily"
    WEEKLY = "weekly"


class NotificationPreferences(SQLModel, table=True):
    """Represents user notification preferences.

    Invariants:
        - Each user has exactly one preferences record (user_id is unique)
        - Quiet hours start and end times are valid time values
        - At least one notification channel must be enabled
        - Timezone is a valid IANA timezone string

    Attributes:
        id: Unique preferences identifier (UUID, auto-generated).
        user_id: User who owns these preferences (UUID string, max 36 chars, unique).
        email_enabled: Whether email notifications are enabled.
        in_app_enabled: Whether in-app notifications are enabled.
        push_enabled: Whether push notifications are enabled (future).
        sms_enabled: Whether SMS notifications are enabled (future).
        reminder_frequency: How often to send reminder notifications.
        task_updates_enabled: Whether to receive task update notifications.
        recurring_task_enabled: Whether to receive recurring task notifications.
        quiet_hours_enabled: Whether quiet hours are enabled.
        quiet_hours_start: Start time for quiet hours (no notifications).
        quiet_hours_end: End time for quiet hours.
        timezone: User's timezone (IANA timezone string, e.g., "America/New_York").
        created_at: Timestamp when preferences were created.
        updated_at: Timestamp when preferences were last updated.
    """

    __tablename__ = "notification_preferences"
    __table_args__ = (
        Index("ix_notification_preferences_user_id", "user_id", unique=True),
    )

    # Primary key
    id: UUID = Field(
        default_factory=uuid4,
        primary_key=True,
        nullable=False,
        description="Unique preferences identifier",
    )

    # User reference (Better Auth user ID)
    user_id: str = Field(
        ...,
        max_length=36,
        nullable=False,
        unique=True,
        index=True,
        description="User who owns these preferences (UUID string)",
    )

    # Channel preferences
    email_enabled: bool = Field(
        default=True,
        nullable=False,
        description="Whether email notifications are enabled",
    )

    in_app_enabled: bool = Field(
        default=True,
        nullable=False,
        description="Whether in-app notifications are enabled",
    )

    push_enabled: bool = Field(
        default=False,
        nullable=False,
        description="Whether push notifications are enabled (future)",
    )

    sms_enabled: bool = Field(
        default=False,
        nullable=False,
        description="Whether SMS notifications are enabled (future)",
    )

    # Frequency preferences
    reminder_frequency: NotificationFrequency = Field(
        default=NotificationFrequency.IMMEDIATE,
        sa_column=Column(String(20), nullable=False),
        description="How often to send reminder notifications",
    )

    # Notification type preferences
    task_updates_enabled: bool = Field(
        default=True,
        nullable=False,
        description="Whether to receive task update notifications",
    )

    recurring_task_enabled: bool = Field(
        default=True,
        nullable=False,
        description="Whether to receive recurring task notifications",
    )

    # Quiet hours
    quiet_hours_enabled: bool = Field(
        default=False,
        nullable=False,
        description="Whether quiet hours are enabled",
    )

    quiet_hours_start: Optional[time] = Field(
        default=None,
        sa_column=Column(Time, nullable=True),
        description="Start time for quiet hours (no notifications)",
    )

    quiet_hours_end: Optional[time] = Field(
        default=None,
        sa_column=Column(Time, nullable=True),
        description="End time for quiet hours",
    )

    # Timezone
    timezone: str = Field(
        default="UTC",
        max_length=50,
        nullable=False,
        description="User's timezone (IANA timezone string)",
    )

    # Timestamps
    created_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            server_default=func.now(),
            nullable=False,
        ),
        description="Timestamp when preferences were created",
    )

    updated_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            server_default=func.now(),
            onupdate=func.now(),
            nullable=False,
        ),
        description="Timestamp when preferences were last updated",
    )

    def is_in_quiet_hours(self, current_time: time) -> bool:
        """Check if current time is within quiet hours.

        Args:
            current_time: The time to check

        Returns:
            True if in quiet hours, False otherwise
        """
        if not self.quiet_hours_enabled or not self.quiet_hours_start or not self.quiet_hours_end:
            return False

        # Handle quiet hours that span midnight
        if self.quiet_hours_start <= self.quiet_hours_end:
            # Normal case: 22:00 - 08:00 (same day)
            return self.quiet_hours_start <= current_time <= self.quiet_hours_end
        else:
            # Spans midnight: 22:00 - 08:00 (next day)
            return current_time >= self.quiet_hours_start or current_time <= self.quiet_hours_end

    def has_any_channel_enabled(self) -> bool:
        """Check if at least one notification channel is enabled.

        Returns:
            True if any channel is enabled, False otherwise
        """
        return (
            self.email_enabled
            or self.in_app_enabled
            or self.push_enabled
            or self.sms_enabled
        )
