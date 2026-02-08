"""
Push Notification Sender

This module provides push notification functionality for mobile and web platforms.
"""

import os
import logging
from typing import Optional, Dict, Any, List
from enum import Enum
from dataclasses import dataclass

logger = logging.getLogger(__name__)


class PushProvider(str, Enum):
    """Supported push notification providers."""
    FIREBASE = "firebase"
    ONESIGNAL = "onesignal"
    AWS_SNS = "aws_sns"
    APNS = "apns"
    WEB_PUSH = "web_push"


@dataclass
class PushMessage:
    """Push notification message data."""
    device_token: str
    title: str
    body: str
    data: Optional[Dict[str, Any]] = None
    image_url: Optional[str] = None
    click_action: Optional[str] = None
    badge: Optional[int] = None
    sound: Optional[str] = None
    priority: str = "high"  # high or normal
    ttl: Optional[int] = None  # Time to live in seconds


class PushSender:
    """Base push notification sender class."""

    def __init__(self, provider: PushProvider, **kwargs):
        self.provider = provider
        self.config = kwargs

    def send(self, message: PushMessage) -> Dict[str, Any]:
        """Send push notification."""
        raise NotImplementedError("Subclass must implement send()")

    def send_batch(self, messages: List[PushMessage]) -> List[Dict[str, Any]]:
        """Send multiple push notifications."""
        results = []
        for message in messages:
            try:
                result = self.send(message)
                results.append(result)
            except Exception as e:
                logger.error(f"Failed to send push to {message.device_token}: {e}")
                results.append({"success": False, "error": str(e)})
        return results

    def send_to_topic(self, topic: str, message: PushMessage) -> Dict[str, Any]:
        """Send push notification to a topic."""
        raise NotImplementedError("Topic sending not supported by this provider")


class FirebasePushSender(PushSender):
    """Firebase Cloud Messaging (FCM) push sender."""

    def __init__(self, credentials_path: Optional[str] = None, **kwargs):
        super().__init__(PushProvider.FIREBASE, **kwargs)

        try:
            import firebase_admin
            from firebase_admin import credentials, messaging

            # Initialize Firebase Admin SDK
            if not firebase_admin._apps:
                if credentials_path:
                    cred = credentials.Certificate(credentials_path)
                else:
                    cred = credentials.ApplicationDefault()
                firebase_admin.initialize_app(cred)

            self.messaging = messaging
        except ImportError:
            raise ImportError("firebase-admin package not installed. Install with: pip install firebase-admin")

    def send(self, message: PushMessage) -> Dict[str, Any]:
        """Send push notification via Firebase."""
        try:
            # Build notification
            notification = self.messaging.Notification(
                title=message.title,
                body=message.body,
                image=message.image_url
            )

            # Build Android config
            android_config = self.messaging.AndroidConfig(
                priority=message.priority,
                ttl=message.ttl,
                notification=self.messaging.AndroidNotification(
                    sound=message.sound or 'default',
                    click_action=message.click_action
                )
            )

            # Build APNS config
            apns_config = self.messaging.APNSConfig(
                payload=self.messaging.APNSPayload(
                    aps=self.messaging.Aps(
                        badge=message.badge,
                        sound=message.sound or 'default',
                        category=message.click_action
                    )
                )
            )

            # Build message
            fcm_message = self.messaging.Message(
                notification=notification,
                data=message.data or {},
                token=message.device_token,
                android=android_config,
                apns=apns_config
            )

            # Send
            response = self.messaging.send(fcm_message)

            logger.info(f"Push notification sent via Firebase to {message.device_token}")
            return {
                "success": True,
                "message_id": response
            }

        except Exception as e:
            logger.error(f"Failed to send push via Firebase: {e}")
            raise

    def send_to_topic(self, topic: str, message: PushMessage) -> Dict[str, Any]:
        """Send push notification to a topic."""
        try:
            notification = self.messaging.Notification(
                title=message.title,
                body=message.body,
                image=message.image_url
            )

            fcm_message = self.messaging.Message(
                notification=notification,
                data=message.data or {},
                topic=topic
            )

            response = self.messaging.send(fcm_message)

            logger.info(f"Push notification sent to topic {topic}")
            return {
                "success": True,
                "message_id": response
            }

        except Exception as e:
            logger.error(f"Failed to send push to topic: {e}")
            raise

    def send_multicast(self, tokens: List[str], message: PushMessage) -> Dict[str, Any]:
        """Send push notification to multiple devices."""
        try:
            notification = self.messaging.Notification(
                title=message.title,
                body=message.body,
                image=message.image_url
            )

            multicast_message = self.messaging.MulticastMessage(
                notification=notification,
                data=message.data or {},
                tokens=tokens
            )

            response = self.messaging.send_multicast(multicast_message)

            logger.info(f"Multicast push sent to {len(tokens)} devices")
            return {
                "success": True,
                "success_count": response.success_count,
                "failure_count": response.failure_count,
                "responses": response.responses
            }

        except Exception as e:
            logger.error(f"Failed to send multicast push: {e}")
            raise


class OneSignalPushSender(PushSender):
    """OneSignal push notification sender."""

    def __init__(self, app_id: str, api_key: str, **kwargs):
        super().__init__(PushProvider.ONESIGNAL, **kwargs)
        self.app_id = app_id
        self.api_key = api_key
        self.base_url = "https://onesignal.com/api/v1"

    def send(self, message: PushMessage) -> Dict[str, Any]:
        """Send push notification via OneSignal."""
        try:
            import requests

            headers = {
                "Content-Type": "application/json; charset=utf-8",
                "Authorization": f"Basic {self.api_key}"
            }

            payload = {
                "app_id": self.app_id,
                "include_player_ids": [message.device_token],
                "headings": {"en": message.title},
                "contents": {"en": message.body},
                "data": message.data or {}
            }

            if message.image_url:
                payload["big_picture"] = message.image_url
                payload["ios_attachments"] = {"id": message.image_url}

            if message.click_action:
                payload["url"] = message.click_action

            if message.badge:
                payload["ios_badgeType"] = "SetTo"
                payload["ios_badgeCount"] = message.badge

            if message.sound:
                payload["ios_sound"] = message.sound
                payload["android_sound"] = message.sound

            response = requests.post(
                f"{self.base_url}/notifications",
                headers=headers,
                json=payload
            )

            response.raise_for_status()
            result = response.json()

            logger.info(f"Push notification sent via OneSignal to {message.device_token}")
            return {
                "success": True,
                "message_id": result.get("id"),
                "recipients": result.get("recipients")
            }

        except Exception as e:
            logger.error(f"Failed to send push via OneSignal: {e}")
            raise

    def send_to_segment(self, segment: str, message: PushMessage) -> Dict[str, Any]:
        """Send push notification to a segment."""
        try:
            import requests

            headers = {
                "Content-Type": "application/json; charset=utf-8",
                "Authorization": f"Basic {self.api_key}"
            }

            payload = {
                "app_id": self.app_id,
                "included_segments": [segment],
                "headings": {"en": message.title},
                "contents": {"en": message.body},
                "data": message.data or {}
            }

            response = requests.post(
                f"{self.base_url}/notifications",
                headers=headers,
                json=payload
            )

            response.raise_for_status()
            result = response.json()

            logger.info(f"Push notification sent to segment {segment}")
            return {
                "success": True,
                "message_id": result.get("id"),
                "recipients": result.get("recipients")
            }

        except Exception as e:
            logger.error(f"Failed to send push to segment: {e}")
            raise


class WebPushSender(PushSender):
    """Web Push notification sender."""

    def __init__(
        self,
        vapid_private_key: str,
        vapid_public_key: str,
        vapid_claims: Dict[str, str],
        **kwargs
    ):
        super().__init__(PushProvider.WEB_PUSH, **kwargs)
        self.vapid_private_key = vapid_private_key
        self.vapid_public_key = vapid_public_key
        self.vapid_claims = vapid_claims

        try:
            from pywebpush import webpush
            self.webpush = webpush
        except ImportError:
            raise ImportError("pywebpush package not installed. Install with: pip install pywebpush")

    def send(self, message: PushMessage) -> Dict[str, Any]:
        """Send web push notification."""
        try:
            import json

            # Parse subscription info from device_token
            # Expected format: JSON string with endpoint, keys
            subscription_info = json.loads(message.device_token)

            # Build notification payload
            payload = {
                "title": message.title,
                "body": message.body,
                "data": message.data or {}
            }

            if message.image_url:
                payload["image"] = message.image_url

            if message.click_action:
                payload["url"] = message.click_action

            if message.badge:
                payload["badge"] = message.badge

            # Send
            response = self.webpush(
                subscription_info=subscription_info,
                data=json.dumps(payload),
                vapid_private_key=self.vapid_private_key,
                vapid_claims=self.vapid_claims
            )

            logger.info(f"Web push notification sent")
            return {
                "success": response.status_code in [200, 201],
                "status_code": response.status_code
            }

        except Exception as e:
            logger.error(f"Failed to send web push: {e}")
            raise


class APNSPushSender(PushSender):
    """Apple Push Notification Service (APNs) sender."""

    def __init__(
        self,
        key_id: str,
        team_id: str,
        bundle_id: str,
        key_path: str,
        use_sandbox: bool = False,
        **kwargs
    ):
        super().__init__(PushProvider.APNS, **kwargs)
        self.key_id = key_id
        self.team_id = team_id
        self.bundle_id = bundle_id
        self.key_path = key_path
        self.use_sandbox = use_sandbox

        try:
            from apns2.client import APNsClient
            from apns2.credentials import TokenCredentials

            credentials = TokenCredentials(
                auth_key_path=key_path,
                auth_key_id=key_id,
                team_id=team_id
            )

            self.client = APNsClient(
                credentials=credentials,
                use_sandbox=use_sandbox
            )
        except ImportError:
            raise ImportError("apns2 package not installed. Install with: pip install apns2")

    def send(self, message: PushMessage) -> Dict[str, Any]:
        """Send push notification via APNs."""
        try:
            from apns2.payload import Payload

            # Build payload
            payload = Payload(
                alert={
                    "title": message.title,
                    "body": message.body
                },
                badge=message.badge,
                sound=message.sound or 'default',
                custom=message.data or {}
            )

            # Send
            self.client.send_notification(
                token_hex=message.device_token,
                notification=payload,
                topic=self.bundle_id
            )

            logger.info(f"Push notification sent via APNs to {message.device_token}")
            return {
                "success": True
            }

        except Exception as e:
            logger.error(f"Failed to send push via APNs: {e}")
            raise


def create_push_sender(
    provider: PushProvider,
    **kwargs
) -> PushSender:
    """Factory function to create push sender."""
    if provider == PushProvider.FIREBASE:
        return FirebasePushSender(**kwargs)
    elif provider == PushProvider.ONESIGNAL:
        return OneSignalPushSender(**kwargs)
    elif provider == PushProvider.WEB_PUSH:
        return WebPushSender(**kwargs)
    elif provider == PushProvider.APNS:
        return APNSPushSender(**kwargs)
    else:
        raise ValueError(f"Unsupported push provider: {provider}")


# Example usage
if __name__ == "__main__":
    # Firebase example
    firebase_sender = create_push_sender(
        provider=PushProvider.FIREBASE,
        credentials_path=os.getenv("FIREBASE_CREDENTIALS_PATH")
    )

    message = PushMessage(
        device_token="device_token_here",
        title="New Task Reminder",
        body="Your task 'Complete project' is due in 1 hour",
        data={
            "task_id": "123",
            "type": "reminder"
        },
        click_action="/tasks/123"
    )

    result = firebase_sender.send(message)
    print(f"Push notification sent: {result}")

    # Send to topic
    topic_result = firebase_sender.send_to_topic("all_users", message)
    print(f"Topic notification sent: {topic_result}")
