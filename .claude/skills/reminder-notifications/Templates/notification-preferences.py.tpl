"""
Notification Preference Manager

This module manages user notification preferences and opt-outs.
"""

import logging
from typing import Optional, Dict, Any, List
from datetime import datetime, time
from sqlmodel import Session, select
from notification_model import NotificationPreference, NotificationChannel
import pytz

logger = logging.getLogger(__name__)


class PreferenceManager:
    """Manage user notification preferences."""

    def __init__(self, session_factory):
        self.session_factory = session_factory

    def get_preferences(self, user_id: str) -> NotificationPreference:
        """Get user notification preferences."""
        with self.session_factory() as session:
            preferences = session.exec(
                select(NotificationPreference)
                .where(NotificationPreference.user_id == user_id)
            ).first()

            if not preferences:
                # Create default preferences
                preferences = self.create_default_preferences(user_id)

            return preferences

    def create_default_preferences(self, user_id: str) -> NotificationPreference:
        """Create default preferences for user."""
        with self.session_factory() as session:
            preferences = NotificationPreference(
                user_id=user_id,
                email_enabled=True,
                sms_enabled=True,
                push_enabled=True,
                in_app_enabled=True,
                email_frequency="immediate",
                quiet_hours_enabled=False
            )

            session.add(preferences)
            session.commit()
            session.refresh(preferences)

            logger.info(f"Created default preferences for user {user_id}")
            return preferences

    def update_preferences(
        self,
        user_id: str,
        **kwargs
    ) -> NotificationPreference:
        """Update user preferences."""
        with self.session_factory() as session:
            preferences = session.exec(
                select(NotificationPreference)
                .where(NotificationPreference.user_id == user_id)
            ).first()

            if not preferences:
                preferences = NotificationPreference(user_id=user_id)
                session.add(preferences)

            # Update fields
            for key, value in kwargs.items():
                if hasattr(preferences, key) and value is not None:
                    setattr(preferences, key, value)

            preferences.updated_at = datetime.utcnow()
            session.commit()
            session.refresh(preferences)

            logger.info(f"Updated preferences for user {user_id}")
            return preferences

    def can_send(
        self,
        user_id: str,
        channel: NotificationChannel,
        category: Optional[str] = None
    ) -> bool:
        """Check if notification can be sent to user."""
        preferences = self.get_preferences(user_id)

        # Check channel enabled
        if not preferences.is_channel_enabled(channel):
            logger.info(f"Channel {channel} disabled for user {user_id}")
            return False

        # Check category enabled
        if category and not preferences.is_category_enabled(category):
            logger.info(f"Category {category} disabled for user {user_id}")
            return False

        # Check quiet hours
        if preferences.quiet_hours_enabled and self._is_quiet_hours(preferences):
            logger.info(f"Quiet hours active for user {user_id}")
            return False

        return True

    def _is_quiet_hours(self, preferences: NotificationPreference) -> bool:
        """Check if current time is within quiet hours."""
        if not preferences.quiet_hours_enabled:
            return False

        try:
            # Get current time in user's timezone
            user_tz = pytz.timezone(preferences.quiet_hours_timezone)
            now = datetime.now(user_tz).time()

            # Parse quiet hours
            start = time.fromisoformat(preferences.quiet_hours_start)
            end = time.fromisoformat(preferences.quiet_hours_end)

            # Check if current time is within quiet hours
            if start < end:
                # Normal case: 22:00 - 08:00
                return start <= now <= end
            else:
                # Crosses midnight: 22:00 - 08:00
                return now >= start or now <= end

        except Exception as e:
            logger.error(f"Error checking quiet hours: {e}")
            return False

    def enable_channel(self, user_id: str, channel: NotificationChannel) -> bool:
        """Enable notification channel for user."""
        field_map = {
            NotificationChannel.EMAIL: "email_enabled",
            NotificationChannel.SMS: "sms_enabled",
            NotificationChannel.PUSH: "push_enabled",
            NotificationChannel.IN_APP: "in_app_enabled"
        }

        field = field_map.get(channel)
        if not field:
            return False

        self.update_preferences(user_id, **{field: True})
        logger.info(f"Enabled {channel} for user {user_id}")
        return True

    def disable_channel(self, user_id: str, channel: NotificationChannel) -> bool:
        """Disable notification channel for user."""
        field_map = {
            NotificationChannel.EMAIL: "email_enabled",
            NotificationChannel.SMS: "sms_enabled",
            NotificationChannel.PUSH: "push_enabled",
            NotificationChannel.IN_APP: "in_app_enabled"
        }

        field = field_map.get(channel)
        if not field:
            return False

        self.update_preferences(user_id, **{field: False})
        logger.info(f"Disabled {channel} for user {user_id}")
        return True

    def enable_category(self, user_id: str, category: str) -> bool:
        """Enable notification category for user."""
        preferences = self.get_preferences(user_id)
        preferences.category_preferences[category] = True

        with self.session_factory() as session:
            session.add(preferences)
            session.commit()

        logger.info(f"Enabled category {category} for user {user_id}")
        return True

    def disable_category(self, user_id: str, category: str) -> bool:
        """Disable notification category for user."""
        preferences = self.get_preferences(user_id)
        preferences.category_preferences[category] = False

        with self.session_factory() as session:
            session.add(preferences)
            session.commit()

        logger.info(f"Disabled category {category} for user {user_id}")
        return True

    def set_quiet_hours(
        self,
        user_id: str,
        enabled: bool,
        start: Optional[str] = None,
        end: Optional[str] = None,
        timezone: Optional[str] = None
    ) -> NotificationPreference:
        """Set quiet hours for user."""
        updates = {"quiet_hours_enabled": enabled}

        if start:
            updates["quiet_hours_start"] = start
        if end:
            updates["quiet_hours_end"] = end
        if timezone:
            updates["quiet_hours_timezone"] = timezone

        return self.update_preferences(user_id, **updates)

    def set_email_frequency(
        self,
        user_id: str,
        frequency: str
    ) -> NotificationPreference:
        """Set email notification frequency."""
        if frequency not in ["immediate", "daily", "weekly"]:
            raise ValueError(f"Invalid frequency: {frequency}")

        return self.update_preferences(user_id, email_frequency=frequency)

    def unsubscribe_all(self, user_id: str) -> NotificationPreference:
        """Unsubscribe user from all notifications."""
        return self.update_preferences(
            user_id,
            email_enabled=False,
            sms_enabled=False,
            push_enabled=False,
            in_app_enabled=False
        )

    def get_digest_users(self, frequency: str = "daily") -> List[str]:
        """Get users who should receive digest notifications."""
        with self.session_factory() as session:
            preferences = session.exec(
                select(NotificationPreference)
                .where(NotificationPreference.email_enabled == True)
                .where(NotificationPreference.email_frequency == frequency)
            ).all()

            return [p.user_id for p in preferences]


class OptOutManager:
    """Manage notification opt-outs and unsubscribes."""

    def __init__(self, session_factory):
        self.session_factory = session_factory
        self.preference_manager = PreferenceManager(session_factory)

    def opt_out(
        self,
        user_id: str,
        channel: Optional[NotificationChannel] = None,
        category: Optional[str] = None,
        reason: Optional[str] = None
    ):
        """Opt user out of notifications."""
        if channel:
            self.preference_manager.disable_channel(user_id, channel)
        elif category:
            self.preference_manager.disable_category(user_id, category)
        else:
            self.preference_manager.unsubscribe_all(user_id)

        # Log opt-out
        logger.info(f"User {user_id} opted out: channel={channel}, category={category}, reason={reason}")

    def opt_in(
        self,
        user_id: str,
        channel: Optional[NotificationChannel] = None,
        category: Optional[str] = None
    ):
        """Opt user back in to notifications."""
        if channel:
            self.preference_manager.enable_channel(user_id, channel)
        elif category:
            self.preference_manager.enable_category(user_id, category)

        logger.info(f"User {user_id} opted in: channel={channel}, category={category}")

    def generate_unsubscribe_token(self, user_id: str) -> str:
        """Generate unsubscribe token for email links."""
        import hashlib
        import secrets

        # In production, use proper token generation with expiry
        token = secrets.token_urlsafe(32)
        return token

    def verify_unsubscribe_token(self, token: str) -> Optional[str]:
        """Verify unsubscribe token and return user_id."""
        # In production, implement proper token verification
        # This is a placeholder
        return None


class NotificationThrottler:
    """Throttle notifications to prevent spam."""

    def __init__(self, session_factory):
        self.session_factory = session_factory

    def can_send(
        self,
        user_id: str,
        channel: NotificationChannel,
        window_minutes: int = 60,
        max_count: int = 10
    ) -> bool:
        """Check if user can receive notification based on rate limits."""
        from notification_model import Notification
        from datetime import timedelta

        with self.session_factory() as session:
            cutoff = datetime.utcnow() - timedelta(minutes=window_minutes)

            count = session.exec(
                select(Notification)
                .where(Notification.user_id == user_id)
                .where(Notification.channel == channel)
                .where(Notification.created_at >= cutoff)
            ).count()

            if count >= max_count:
                logger.warning(
                    f"Rate limit exceeded for user {user_id} on channel {channel}: "
                    f"{count} notifications in {window_minutes} minutes"
                )
                return False

            return True

    def get_rate_limit_info(
        self,
        user_id: str,
        channel: NotificationChannel,
        window_minutes: int = 60
    ) -> Dict[str, Any]:
        """Get rate limit information for user."""
        from notification_model import Notification
        from datetime import timedelta

        with self.session_factory() as session:
            cutoff = datetime.utcnow() - timedelta(minutes=window_minutes)

            count = session.exec(
                select(Notification)
                .where(Notification.user_id == user_id)
                .where(Notification.channel == channel)
                .where(Notification.created_at >= cutoff)
            ).count()

            return {
                "user_id": user_id,
                "channel": channel,
                "window_minutes": window_minutes,
                "current_count": count,
                "max_count": 10,
                "remaining": max(0, 10 - count)
            }


# Helper functions
def create_unsubscribe_link(user_id: str, base_url: str) -> str:
    """Create unsubscribe link for emails."""
    import hashlib

    # Generate token (in production, use proper token generation)
    token = hashlib.sha256(f"{user_id}:secret".encode()).hexdigest()

    return f"{base_url}/unsubscribe?token={token}"


def parse_unsubscribe_link(url: str) -> Optional[str]:
    """Parse unsubscribe link and return user_id."""
    # In production, implement proper token parsing and verification
    return None


# Example usage
if __name__ == "__main__":
    from sqlmodel import create_engine, Session, SQLModel

    # Create database
    engine = create_engine("sqlite:///notifications.db")
    SQLModel.metadata.create_all(engine)

    # Create preference manager
    preference_manager = PreferenceManager(lambda: Session(engine))

    # Get preferences
    preferences = preference_manager.get_preferences("user_123")
    print(f"Email enabled: {preferences.email_enabled}")
    print(f"SMS enabled: {preferences.sms_enabled}")

    # Update preferences
    preference_manager.update_preferences(
        "user_123",
        email_enabled=True,
        sms_enabled=False,
        quiet_hours_enabled=True,
        quiet_hours_start="22:00",
        quiet_hours_end="08:00"
    )

    # Check if can send
    can_send = preference_manager.can_send(
        "user_123",
        NotificationChannel.EMAIL,
        category="task_reminders"
    )
    print(f"Can send email: {can_send}")

    # Disable category
    preference_manager.disable_category("user_123", "marketing")

    # Set email frequency
    preference_manager.set_email_frequency("user_123", "daily")

    # Create throttler
    throttler = NotificationThrottler(lambda: Session(engine))

    # Check rate limit
    can_send = throttler.can_send("user_123", NotificationChannel.EMAIL)
    print(f"Within rate limit: {can_send}")

    # Get rate limit info
    info = throttler.get_rate_limit_info("user_123", NotificationChannel.EMAIL)
    print(f"Rate limit info: {info}")
