"""
Unified Notification Service

This module provides a unified interface for sending notifications across multiple channels.
"""

import logging
from typing import Optional, Dict, Any, List
from enum import Enum
from datetime import datetime
from sqlmodel import Session, select

from email_sender import EmailSender, EmailMessage, create_email_sender, EmailProvider
from sms_sender import SMSSender, SMSMessage, create_sms_sender, SMSProvider
from push_sender import PushSender, PushMessage, create_push_sender, PushProvider
from notification_model import Notification, NotificationStatus, NotificationChannel
from notification_templates import TemplateManager
from notification_preferences import PreferenceManager

logger = logging.getLogger(__name__)


class NotificationService:
    """Unified notification service for all channels."""

    def __init__(
        self,
        session_factory,
        email_sender: Optional[EmailSender] = None,
        sms_sender: Optional[SMSSender] = None,
        push_sender: Optional[PushSender] = None,
        template_manager: Optional[TemplateManager] = None,
        preference_manager: Optional[PreferenceManager] = None
    ):
        self.session_factory = session_factory
        self.email_sender = email_sender
        self.sms_sender = sms_sender
        self.push_sender = push_sender
        self.template_manager = template_manager or TemplateManager()
        self.preference_manager = preference_manager or PreferenceManager(session_factory)

    def send(
        self,
        user_id: str,
        channel: NotificationChannel,
        template_name: str,
        data: Dict[str, Any],
        priority: str = "normal",
        scheduled_for: Optional[datetime] = None
    ) -> Notification:
        """Send notification via specified channel."""
        with self.session_factory() as session:
            # Check user preferences
            if not self.preference_manager.can_send(user_id, channel):
                logger.info(f"User {user_id} has disabled {channel} notifications")
                return None

            # Create notification record
            notification = Notification(
                user_id=user_id,
                channel=channel,
                template_name=template_name,
                data=data,
                priority=priority,
                status=NotificationStatus.QUEUED,
                scheduled_for=scheduled_for or datetime.utcnow()
            )

            session.add(notification)
            session.commit()
            session.refresh(notification)

            # Send immediately if not scheduled
            if scheduled_for is None or scheduled_for <= datetime.utcnow():
                self._send_notification(notification, session)

            return notification

    def _send_notification(self, notification: Notification, session: Session):
        """Internal method to send notification."""
        try:
            # Update status
            notification.status = NotificationStatus.SENDING
            notification.sent_at = datetime.utcnow()
            session.commit()

            # Get user contact info
            user = self._get_user(notification.user_id, session)

            # Render template
            content = self.template_manager.render(
                notification.template_name,
                notification.channel,
                notification.data
            )

            # Send via appropriate channel
            if notification.channel == NotificationChannel.EMAIL:
                self._send_email(user, content, notification)
            elif notification.channel == NotificationChannel.SMS:
                self._send_sms(user, content, notification)
            elif notification.channel == NotificationChannel.PUSH:
                self._send_push(user, content, notification)
            elif notification.channel == NotificationChannel.IN_APP:
                self._send_in_app(user, content, notification)

            # Update status
            notification.status = NotificationStatus.SENT
            session.commit()

            logger.info(f"Notification {notification.id} sent successfully")

        except Exception as e:
            logger.error(f"Failed to send notification {notification.id}: {e}")
            notification.status = NotificationStatus.FAILED
            notification.error_message = str(e)
            notification.retry_count += 1
            session.commit()

            # Schedule retry if not exceeded max retries
            if notification.retry_count < 3:
                self._schedule_retry(notification)

    def _send_email(self, user: Any, content: Dict[str, str], notification: Notification):
        """Send email notification."""
        if not self.email_sender:
            raise Exception("Email sender not configured")

        if not user.email:
            raise Exception(f"User {user.id} has no email address")

        message = EmailMessage(
            to_email=user.email,
            subject=content['subject'],
            html_content=content['html'],
            text_content=content.get('text')
        )

        result = self.email_sender.send(message)
        notification.provider_message_id = result.get('message_id')

    def _send_sms(self, user: Any, content: Dict[str, str], notification: Notification):
        """Send SMS notification."""
        if not self.sms_sender:
            raise Exception("SMS sender not configured")

        if not user.phone:
            raise Exception(f"User {user.id} has no phone number")

        message = SMSMessage(
            to_phone=user.phone,
            message=content['text']
        )

        result = self.sms_sender.send(message)
        notification.provider_message_id = result.get('message_id')

    def _send_push(self, user: Any, content: Dict[str, str], notification: Notification):
        """Send push notification."""
        if not self.push_sender:
            raise Exception("Push sender not configured")

        if not user.push_token:
            raise Exception(f"User {user.id} has no push token")

        message = PushMessage(
            device_token=user.push_token,
            title=content['title'],
            body=content['body'],
            data=notification.data,
            click_action=content.get('click_action')
        )

        result = self.push_sender.send(message)
        notification.provider_message_id = result.get('message_id')

    def _send_in_app(self, user: Any, content: Dict[str, str], notification: Notification):
        """Send in-app notification."""
        # In-app notifications are just stored in database
        # Frontend will poll or use WebSocket to retrieve them
        notification.in_app_content = content
        logger.info(f"In-app notification created for user {user.id}")

    def send_multi_channel(
        self,
        user_id: str,
        channels: List[NotificationChannel],
        template_name: str,
        data: Dict[str, Any],
        fallback: bool = True
    ) -> List[Notification]:
        """Send notification via multiple channels."""
        notifications = []

        for channel in channels:
            try:
                notification = self.send(
                    user_id=user_id,
                    channel=channel,
                    template_name=template_name,
                    data=data
                )
                notifications.append(notification)

                # If fallback is False, stop after first success
                if not fallback and notification.status == NotificationStatus.SENT:
                    break

            except Exception as e:
                logger.error(f"Failed to send via {channel}: {e}")
                if not fallback:
                    raise

        return notifications

    def send_batch(
        self,
        user_ids: List[str],
        channel: NotificationChannel,
        template_name: str,
        data: Dict[str, Any]
    ) -> List[Notification]:
        """Send notification to multiple users."""
        notifications = []

        for user_id in user_ids:
            try:
                notification = self.send(
                    user_id=user_id,
                    channel=channel,
                    template_name=template_name,
                    data=data
                )
                notifications.append(notification)
            except Exception as e:
                logger.error(f"Failed to send to user {user_id}: {e}")

        return notifications

    def retry_failed(self, notification_id: int) -> bool:
        """Retry failed notification."""
        with self.session_factory() as session:
            notification = session.get(Notification, notification_id)

            if not notification:
                raise ValueError(f"Notification {notification_id} not found")

            if notification.status != NotificationStatus.FAILED:
                raise ValueError(f"Notification {notification_id} is not in failed state")

            self._send_notification(notification, session)
            return notification.status == NotificationStatus.SENT

    def get_notification_status(self, notification_id: int) -> Dict[str, Any]:
        """Get notification status."""
        with self.session_factory() as session:
            notification = session.get(Notification, notification_id)

            if not notification:
                raise ValueError(f"Notification {notification_id} not found")

            return {
                "id": notification.id,
                "status": notification.status,
                "channel": notification.channel,
                "sent_at": notification.sent_at,
                "delivered_at": notification.delivered_at,
                "error_message": notification.error_message,
                "retry_count": notification.retry_count
            }

    def get_user_notifications(
        self,
        user_id: str,
        channel: Optional[NotificationChannel] = None,
        unread_only: bool = False,
        limit: int = 50
    ) -> List[Notification]:
        """Get user's notifications."""
        with self.session_factory() as session:
            query = select(Notification).where(Notification.user_id == user_id)

            if channel:
                query = query.where(Notification.channel == channel)

            if unread_only:
                query = query.where(Notification.read_at == None)

            query = query.order_by(Notification.created_at.desc()).limit(limit)

            notifications = session.exec(query).all()
            return notifications

    def mark_as_read(self, notification_id: int) -> bool:
        """Mark notification as read."""
        with self.session_factory() as session:
            notification = session.get(Notification, notification_id)

            if not notification:
                return False

            notification.read_at = datetime.utcnow()
            session.commit()
            return True

    def mark_all_as_read(self, user_id: str) -> int:
        """Mark all user notifications as read."""
        with self.session_factory() as session:
            notifications = session.exec(
                select(Notification)
                .where(Notification.user_id == user_id)
                .where(Notification.read_at == None)
            ).all()

            count = 0
            for notification in notifications:
                notification.read_at = datetime.utcnow()
                count += 1

            session.commit()
            return count

    def delete_notification(self, notification_id: int) -> bool:
        """Delete notification."""
        with self.session_factory() as session:
            notification = session.get(Notification, notification_id)

            if not notification:
                return False

            session.delete(notification)
            session.commit()
            return True

    def _get_user(self, user_id: str, session: Session) -> Any:
        """Get user from database."""
        # This should be replaced with actual user model
        from models import User
        user = session.get(User, user_id)
        if not user:
            raise ValueError(f"User {user_id} not found")
        return user

    def _schedule_retry(self, notification: Notification):
        """Schedule notification retry."""
        # This should be implemented with a task queue (Celery)
        # For now, just log
        logger.info(f"Scheduling retry for notification {notification.id}")


# Rate limiter
class RateLimiter:
    """Rate limiter for notifications."""

    def __init__(self, session_factory):
        self.session_factory = session_factory

    def can_send(
        self,
        user_id: str,
        channel: NotificationChannel,
        window_minutes: int = 60,
        max_count: int = 10
    ) -> bool:
        """Check if user can receive notification."""
        with self.session_factory() as session:
            cutoff = datetime.utcnow() - timedelta(minutes=window_minutes)

            count = session.exec(
                select(Notification)
                .where(Notification.user_id == user_id)
                .where(Notification.channel == channel)
                .where(Notification.created_at >= cutoff)
            ).count()

            return count < max_count


# Example usage
if __name__ == "__main__":
    from sqlmodel import create_engine, Session

    # Create engine
    engine = create_engine("sqlite:///notifications.db")

    # Create notification service
    email_sender = create_email_sender(
        provider=EmailProvider.SMTP,
        from_email="noreply@example.com",
        smtp_host="smtp.gmail.com",
        smtp_port=587,
        smtp_username=os.getenv("SMTP_USERNAME"),
        smtp_password=os.getenv("SMTP_PASSWORD")
    )

    notification_service = NotificationService(
        session_factory=lambda: Session(engine),
        email_sender=email_sender
    )

    # Send notification
    notification = notification_service.send(
        user_id="user_123",
        channel=NotificationChannel.EMAIL,
        template_name="task_reminder",
        data={
            "task_title": "Complete project",
            "due_date": "2024-01-10"
        }
    )

    print(f"Notification sent: {notification.id}")
