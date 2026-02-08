"""Notification preferences service for managing user notification settings.

This module provides functionality for creating, retrieving, and updating
user notification preferences.
"""

import logging
from datetime import datetime, time
from typing import Any, Dict, Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
import pytz

from app.models.notification_preferences import (
    NotificationPreferences,
    NotificationChannel,
    NotificationFrequency,
)

logger = logging.getLogger(__name__)


class NotificationPreferencesService:
    """Service for managing notification preferences."""

    def __init__(self, session: AsyncSession):
        """Initialize the notification preferences service.

        Args:
            session: Async database session
        """
        self.session = session

    async def get_or_create_preferences(
        self, user_id: str
    ) -> NotificationPreferences:
        """Get user preferences or create default preferences if not exists.

        Args:
            user_id: User ID to get preferences for

        Returns:
            NotificationPreferences for the user
        """
        # Try to get existing preferences
        query = select(NotificationPreferences).where(
            NotificationPreferences.user_id == user_id
        )
        result = await self.session.execute(query)
        preferences = result.scalar_one_or_none()

        if preferences is None:
            # Create default preferences
            preferences = NotificationPreferences(
                user_id=user_id,
                email_enabled=True,
                in_app_enabled=True,
                push_enabled=False,
                sms_enabled=False,
                reminder_frequency=NotificationFrequency.IMMEDIATE,
                task_updates_enabled=True,
                recurring_task_enabled=True,
                quiet_hours_enabled=False,
                quiet_hours_start=None,
                quiet_hours_end=None,
                timezone="UTC",
            )

            self.session.add(preferences)
            await self.session.flush()
            await self.session.refresh(preferences)

            logger.info(f"Created default notification preferences for user {user_id}")

        return preferences

    async def get_preferences(
        self, user_id: str
    ) -> Optional[NotificationPreferences]:
        """Get user notification preferences.

        Args:
            user_id: User ID to get preferences for

        Returns:
            NotificationPreferences if found, None otherwise
        """
        query = select(NotificationPreferences).where(
            NotificationPreferences.user_id == user_id
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def update_preferences(
        self,
        user_id: str,
        updates: Dict[str, Any],
    ) -> Optional[NotificationPreferences]:
        """Update user notification preferences.

        Args:
            user_id: User ID to update preferences for
            updates: Dictionary of fields to update

        Returns:
            Updated NotificationPreferences if found, None otherwise

        Raises:
            ValueError: If validation fails
        """
        # Get existing preferences
        preferences = await self.get_preferences(user_id)
        if preferences is None:
            return None

        # Validate updates
        self._validate_updates(updates, preferences)

        # Apply updates
        for field, value in updates.items():
            if hasattr(preferences, field):
                setattr(preferences, field, value)

        await self.session.flush()
        await self.session.refresh(preferences)

        logger.info(f"Updated notification preferences for user {user_id}")

        return preferences

    def _validate_updates(
        self,
        updates: Dict[str, Any],
        current_preferences: NotificationPreferences,
    ) -> None:
        """Validate preference updates.

        Args:
            updates: Dictionary of fields to update
            current_preferences: Current preferences

        Raises:
            ValueError: If validation fails
        """
        # Check if at least one channel will be enabled
        email_enabled = updates.get("email_enabled", current_preferences.email_enabled)
        in_app_enabled = updates.get("in_app_enabled", current_preferences.in_app_enabled)
        push_enabled = updates.get("push_enabled", current_preferences.push_enabled)
        sms_enabled = updates.get("sms_enabled", current_preferences.sms_enabled)

        if not (email_enabled or in_app_enabled or push_enabled or sms_enabled):
            raise ValueError("At least one notification channel must be enabled")

        # Validate quiet hours
        quiet_hours_enabled = updates.get(
            "quiet_hours_enabled", current_preferences.quiet_hours_enabled
        )
        if quiet_hours_enabled:
            quiet_hours_start = updates.get(
                "quiet_hours_start", current_preferences.quiet_hours_start
            )
            quiet_hours_end = updates.get(
                "quiet_hours_end", current_preferences.quiet_hours_end
            )

            if quiet_hours_start is None or quiet_hours_end is None:
                raise ValueError(
                    "Quiet hours start and end times must be set when quiet hours are enabled"
                )

        # Validate timezone
        if "timezone" in updates:
            timezone = updates["timezone"]
            try:
                pytz.timezone(timezone)
            except pytz.exceptions.UnknownTimeZoneError:
                raise ValueError(f"Invalid timezone: {timezone}")

    async def should_send_notification(
        self,
        user_id: str,
        channel: NotificationChannel,
        notification_type: str,
    ) -> bool:
        """Check if a notification should be sent based on user preferences.

        Args:
            user_id: User ID to check preferences for
            channel: Notification channel (email, in_app, push, sms)
            notification_type: Type of notification (task_update, reminder, recurring_task)

        Returns:
            True if notification should be sent, False otherwise
        """
        # Get user preferences
        preferences = await self.get_or_create_preferences(user_id)

        # Check if channel is enabled
        if channel == NotificationChannel.EMAIL and not preferences.email_enabled:
            return False
        elif channel == NotificationChannel.IN_APP and not preferences.in_app_enabled:
            return False
        elif channel == NotificationChannel.PUSH and not preferences.push_enabled:
            return False
        elif channel == NotificationChannel.SMS and not preferences.sms_enabled:
            return False

        # Check if notification type is enabled
        if notification_type == "task_update" and not preferences.task_updates_enabled:
            return False
        elif notification_type == "recurring_task" and not preferences.recurring_task_enabled:
            return False

        # Check quiet hours
        if preferences.quiet_hours_enabled:
            # Get current time in user's timezone
            user_tz = pytz.timezone(preferences.timezone)
            current_time = datetime.now(user_tz).time()

            if preferences.is_in_quiet_hours(current_time):
                logger.info(
                    f"Notification blocked for user {user_id}: in quiet hours"
                )
                return False

        return True

    async def get_enabled_channels(
        self, user_id: str
    ) -> list[NotificationChannel]:
        """Get list of enabled notification channels for a user.

        Args:
            user_id: User ID to get enabled channels for

        Returns:
            List of enabled NotificationChannel values
        """
        preferences = await self.get_or_create_preferences(user_id)

        channels = []
        if preferences.email_enabled:
            channels.append(NotificationChannel.EMAIL)
        if preferences.in_app_enabled:
            channels.append(NotificationChannel.IN_APP)
        if preferences.push_enabled:
            channels.append(NotificationChannel.PUSH)
        if preferences.sms_enabled:
            channels.append(NotificationChannel.SMS)

        return channels

    async def is_in_quiet_hours(self, user_id: str) -> bool:
        """Check if user is currently in quiet hours.

        Args:
            user_id: User ID to check

        Returns:
            True if in quiet hours, False otherwise
        """
        preferences = await self.get_or_create_preferences(user_id)

        if not preferences.quiet_hours_enabled:
            return False

        # Get current time in user's timezone
        user_tz = pytz.timezone(preferences.timezone)
        current_time = datetime.now(user_tz).time()

        return preferences.is_in_quiet_hours(current_time)

    async def get_user_timezone(self, user_id: str) -> str:
        """Get user's timezone.

        Args:
            user_id: User ID to get timezone for

        Returns:
            IANA timezone string (e.g., "America/New_York")
        """
        preferences = await self.get_or_create_preferences(user_id)
        return preferences.timezone

    async def get_reminder_frequency(
        self, user_id: str
    ) -> NotificationFrequency:
        """Get user's reminder notification frequency.

        Args:
            user_id: User ID to get frequency for

        Returns:
            NotificationFrequency value
        """
        preferences = await self.get_or_create_preferences(user_id)
        return preferences.reminder_frequency
