"""Notification rate limiting service.

This module provides rate limiting functionality for notifications to prevent
spam and respect user preferences.
"""

import logging
from datetime import datetime, timedelta
from typing import Dict, Optional

from sqlalchemy import func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import Field, SQLModel, select

logger = logging.getLogger(__name__)


class NotificationRateLimit(SQLModel, table=True):
    """Tracks notification sends for rate limiting.

    Attributes:
        id: Unique identifier (auto-increment).
        user_id: User who received the notification.
        notification_type: Type of notification (reminder, task_update, etc.).
        channel: Notification channel (email, in_app, push, sms).
        sent_at: Timestamp when notification was sent.
    """

    __tablename__ = "notification_rate_limit"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: str = Field(..., max_length=36, nullable=False, index=True)
    notification_type: str = Field(..., max_length=50, nullable=False)
    channel: str = Field(..., max_length=20, nullable=False)
    sent_at: datetime = Field(
        default_factory=datetime.utcnow,
        nullable=False,
        index=True,
    )


class NotificationRateLimiter:
    """Service for rate limiting notifications."""

    # Rate limit configurations
    MAX_NOTIFICATIONS_PER_HOUR = 20
    MAX_NOTIFICATIONS_PER_DAY = 100
    MAX_SAME_TYPE_PER_HOUR = 5

    def __init__(self, session: AsyncSession):
        """Initialize the rate limiter.

        Args:
            session: Async database session
        """
        self.session = session

    async def check_rate_limit(
        self,
        user_id: str,
        notification_type: str,
        channel: str,
    ) -> bool:
        """Check if a notification can be sent based on rate limits.

        Args:
            user_id: User ID to check rate limit for
            notification_type: Type of notification
            channel: Notification channel

        Returns:
            True if notification can be sent, False if rate limit exceeded
        """
        now = datetime.utcnow()

        # Check hourly limit (all notifications)
        hourly_count = await self._count_notifications(
            user_id=user_id,
            since=now - timedelta(hours=1),
        )
        if hourly_count >= self.MAX_NOTIFICATIONS_PER_HOUR:
            logger.warning(
                f"Hourly rate limit exceeded for user {user_id}: {hourly_count} notifications"
            )
            return False

        # Check daily limit (all notifications)
        daily_count = await self._count_notifications(
            user_id=user_id,
            since=now - timedelta(days=1),
        )
        if daily_count >= self.MAX_NOTIFICATIONS_PER_DAY:
            logger.warning(
                f"Daily rate limit exceeded for user {user_id}: {daily_count} notifications"
            )
            return False

        # Check same type limit (prevent spam of same notification type)
        same_type_count = await self._count_notifications(
            user_id=user_id,
            notification_type=notification_type,
            since=now - timedelta(hours=1),
        )
        if same_type_count >= self.MAX_SAME_TYPE_PER_HOUR:
            logger.warning(
                f"Same type rate limit exceeded for user {user_id}: {same_type_count} {notification_type} notifications"
            )
            return False

        return True

    async def record_notification(
        self,
        user_id: str,
        notification_type: str,
        channel: str,
    ) -> None:
        """Record a sent notification for rate limiting.

        Args:
            user_id: User ID who received the notification
            notification_type: Type of notification
            channel: Notification channel
        """
        record = NotificationRateLimit(
            user_id=user_id,
            notification_type=notification_type,
            channel=channel,
        )

        self.session.add(record)
        await self.session.flush()

        logger.debug(
            f"Recorded notification: user={user_id}, type={notification_type}, channel={channel}"
        )

    async def _count_notifications(
        self,
        user_id: str,
        since: datetime,
        notification_type: Optional[str] = None,
    ) -> int:
        """Count notifications sent to a user since a given time.

        Args:
            user_id: User ID to count notifications for
            since: Count notifications since this time
            notification_type: Optional filter by notification type

        Returns:
            Count of notifications
        """
        query = select(func.count(NotificationRateLimit.id)).where(
            NotificationRateLimit.user_id == user_id,
            NotificationRateLimit.sent_at >= since,
        )

        if notification_type is not None:
            query = query.where(
                NotificationRateLimit.notification_type == notification_type
            )

        result = await self.session.execute(query)
        return result.scalar_one()

    async def get_notification_stats(
        self, user_id: str
    ) -> Dict[str, int]:
        """Get notification statistics for a user.

        Args:
            user_id: User ID to get stats for

        Returns:
            Dictionary with notification counts
        """
        now = datetime.utcnow()

        # Count notifications in different time windows
        hourly_count = await self._count_notifications(
            user_id=user_id,
            since=now - timedelta(hours=1),
        )

        daily_count = await self._count_notifications(
            user_id=user_id,
            since=now - timedelta(days=1),
        )

        weekly_count = await self._count_notifications(
            user_id=user_id,
            since=now - timedelta(days=7),
        )

        return {
            "last_hour": hourly_count,
            "last_day": daily_count,
            "last_week": weekly_count,
            "hourly_limit": self.MAX_NOTIFICATIONS_PER_HOUR,
            "daily_limit": self.MAX_NOTIFICATIONS_PER_DAY,
        }

    async def cleanup_old_records(self, days: int = 30) -> int:
        """Delete old notification rate limit records.

        Args:
            days: Delete records older than this many days (default 30)

        Returns:
            Number of records deleted
        """
        cutoff_date = datetime.utcnow() - timedelta(days=days)

        # Count records to delete
        count_query = select(func.count(NotificationRateLimit.id)).where(
            NotificationRateLimit.sent_at < cutoff_date
        )
        result = await self.session.execute(count_query)
        total_to_delete = result.scalar_one()

        if total_to_delete == 0:
            return 0

        # Delete old records
        query = select(NotificationRateLimit).where(
            NotificationRateLimit.sent_at < cutoff_date
        )
        result = await self.session.execute(query)
        records = result.scalars().all()

        for record in records:
            await self.session.delete(record)

        await self.session.flush()

        logger.info(
            f"Cleaned up {total_to_delete} notification rate limit records older than {days} days"
        )

        return total_to_delete

    async def reset_user_limits(self, user_id: str) -> None:
        """Reset rate limits for a user (admin function).

        Args:
            user_id: User ID to reset limits for
        """
        query = select(NotificationRateLimit).where(
            NotificationRateLimit.user_id == user_id
        )
        result = await self.session.execute(query)
        records = result.scalars().all()

        for record in records:
            await self.session.delete(record)

        await self.session.flush()

        logger.info(f"Reset rate limits for user {user_id}")
