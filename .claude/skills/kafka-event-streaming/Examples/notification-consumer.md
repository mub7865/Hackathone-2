# Notification Consumer Example

This example shows how to consume events and send notifications.

## Overview

The notification service listens to reminder and notification events from Kafka and sends notifications to users via email, push, or SMS.

## Implementation

### 1. Notification Consumer Service

```python
# services/notification_service.py
from kafka import KafkaConsumer
import json
import logging
import os
from datetime import datetime
from typing import Dict, Any

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class NotificationService:
    """
    Service that consumes notification events and sends notifications.
    """

    def __init__(self):
        self.consumer = KafkaConsumer(
            'reminders',
            'notifications',
            bootstrap_servers=os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092').split(','),
            group_id='notification-service',
            auto_offset_reset='earliest',
            enable_auto_commit=True,
            value_deserializer=lambda m: json.loads(m.decode('utf-8'))
        )
        logger.info("Notification service started")

    def start(self):
        """Start consuming and processing events."""
        try:
            for message in self.consumer:
                try:
                    event = message.value
                    logger.info(f"Received event from {message.topic}: {event.get('event_type')}")

                    if message.topic == 'reminders':
                        self.handle_reminder(event)
                    elif message.topic == 'notifications':
                        self.handle_notification(event)

                except Exception as e:
                    logger.error(f"Error processing event: {e}")
                    continue

        except KeyboardInterrupt:
            logger.info("Shutting down notification service")
        finally:
            self.consumer.close()

    def handle_reminder(self, event: Dict[str, Any]):
        """
        Handle reminder events.

        Event structure:
        {
            "event_type": "reminder",
            "task_id": 123,
            "user_id": "user_456",
            "title": "Complete project report",
            "due_at": "2026-01-15T10:00:00",
            "remind_at": "2026-01-15T09:00:00",
            "notification_type": "email"
        }
        """
        task_id = event.get('task_id')
        user_id = event.get('user_id')
        title = event.get('title')
        due_at = event.get('due_at')
        notification_type = event.get('notification_type', 'email')

        logger.info(f"Processing reminder for task {task_id}")

        # Get user details (from database or cache)
        user = self.get_user(user_id)
        if not user:
            logger.error(f"User {user_id} not found")
            return

        # Format message
        message = f"Reminder: Your task '{title}' is due at {due_at}"

        # Send notification
        if notification_type == 'email':
            self.send_email(user['email'], "Task Reminder", message)
        elif notification_type == 'push':
            self.send_push_notification(user_id, message)
        elif notification_type == 'sms':
            self.send_sms(user['phone'], message)

        logger.info(f"Reminder sent to user {user_id} via {notification_type}")

    def handle_notification(self, event: Dict[str, Any]):
        """
        Handle generic notification events.

        Event structure:
        {
            "event_type": "notification",
            "user_id": "user_456",
            "notification_type": "email",
            "subject": "Task Reminder",
            "message": "Your task is due soon",
            "metadata": {}
        }
        """
        user_id = event.get('user_id')
        notification_type = event.get('notification_type')
        subject = event.get('subject')
        message = event.get('message')

        logger.info(f"Processing notification for user {user_id}")

        # Get user details
        user = self.get_user(user_id)
        if not user:
            logger.error(f"User {user_id} not found")
            return

        # Send notification
        if notification_type == 'email':
            self.send_email(user['email'], subject, message)
        elif notification_type == 'push':
            self.send_push_notification(user_id, message)
        elif notification_type == 'sms':
            self.send_sms(user['phone'], message)

        logger.info(f"Notification sent to user {user_id} via {notification_type}")

    def get_user(self, user_id: str) -> Dict[str, Any]:
        """
        Get user details from database.

        In production, this would query your database.
        For demo, returning mock data.
        """
        # TODO: Implement actual database query
        return {
            'id': user_id,
            'email': f'{user_id}@example.com',
            'phone': '+1234567890'
        }

    def send_email(self, to: str, subject: str, message: str):
        """
        Send email notification.

        In production, use services like:
        - SendGrid
        - AWS SES
        - Mailgun
        """
        logger.info(f"Sending email to {to}")
        logger.info(f"Subject: {subject}")
        logger.info(f"Message: {message}")

        # TODO: Implement actual email sending
        # Example with SendGrid:
        # from sendgrid import SendGridAPIClient
        # from sendgrid.helpers.mail import Mail
        #
        # message = Mail(
        #     from_email='noreply@example.com',
        #     to_emails=to,
        #     subject=subject,
        #     html_content=message
        # )
        # sg = SendGridAPIClient(os.environ.get('SENDGRID_API_KEY'))
        # response = sg.send(message)

    def send_push_notification(self, user_id: str, message: str):
        """
        Send push notification.

        In production, use services like:
        - Firebase Cloud Messaging (FCM)
        - Apple Push Notification Service (APNS)
        - OneSignal
        """
        logger.info(f"Sending push notification to user {user_id}")
        logger.info(f"Message: {message}")

        # TODO: Implement actual push notification
        # Example with FCM:
        # from firebase_admin import messaging
        #
        # message = messaging.Message(
        #     notification=messaging.Notification(
        #         title='Task Reminder',
        #         body=message,
        #     ),
        #     token=user_device_token,
        # )
        # response = messaging.send(message)

    def send_sms(self, phone: str, message: str):
        """
        Send SMS notification.

        In production, use services like:
        - Twilio
        - AWS SNS
        - Vonage
        """
        logger.info(f"Sending SMS to {phone}")
        logger.info(f"Message: {message}")

        # TODO: Implement actual SMS sending
        # Example with Twilio:
        # from twilio.rest import Client
        #
        # client = Client(account_sid, auth_token)
        # message = client.messages.create(
        #     body=message,
        #     from_='+1234567890',
        #     to=phone
        # )


if __name__ == "__main__":
    service = NotificationService()
    service.start()
```

### 2. Docker Deployment

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY services/notification_service.py .

CMD ["python", "notification_service.py"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  notification-service:
    build: .
    environment:
      - KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
      - SENDGRID_API_KEY=${SENDGRID_API_KEY}
    depends_on:
      - redpanda
    restart: unless-stopped

  redpanda:
    image: docker.redpanda.com/redpandadata/redpanda:latest
    command:
      - redpanda start
      - --smp 1
      - --overprovisioned
      - --kafka-addr PLAINTEXT://0.0.0.0:29092,OUTSIDE://0.0.0.0:9092
      - --advertise-kafka-addr PLAINTEXT://redpanda:29092,OUTSIDE://localhost:9092
    ports:
      - "9092:9092"
```

### 3. Kubernetes Deployment

```yaml
# k8s/notification-service-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notification-service
  namespace: todo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: notification-service
  template:
    metadata:
      labels:
        app: notification-service
    spec:
      containers:
      - name: notification-service
        image: your-registry/notification-service:latest
        env:
        - name: KAFKA_BOOTSTRAP_SERVERS
          value: "redpanda-service:9092"
        - name: SENDGRID_API_KEY
          valueFrom:
            secretKeyRef:
              name: notification-secrets
              key: sendgrid-api-key
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
```

### 4. Testing

```python
# test_notification_service.py
import pytest
from unittest.mock import Mock, patch
from notification_service import NotificationService

def test_handle_reminder():
    """Test reminder event handling."""
    service = NotificationService()

    # Mock methods
    service.get_user = Mock(return_value={
        'id': 'user_123',
        'email': 'test@example.com',
        'phone': '+1234567890'
    })
    service.send_email = Mock()

    # Test event
    event = {
        'event_type': 'reminder',
        'task_id': 123,
        'user_id': 'user_123',
        'title': 'Test Task',
        'due_at': '2026-01-15T10:00:00',
        'notification_type': 'email'
    }

    # Handle event
    service.handle_reminder(event)

    # Verify email was sent
    service.send_email.assert_called_once()
    args = service.send_email.call_args[0]
    assert args[0] == 'test@example.com'
    assert 'Test Task' in args[2]

def test_handle_notification():
    """Test generic notification handling."""
    service = NotificationService()

    # Mock methods
    service.get_user = Mock(return_value={
        'id': 'user_123',
        'email': 'test@example.com'
    })
    service.send_push_notification = Mock()

    # Test event
    event = {
        'event_type': 'notification',
        'user_id': 'user_123',
        'notification_type': 'push',
        'subject': 'Test',
        'message': 'Test message'
    }

    # Handle event
    service.handle_notification(event)

    # Verify push was sent
    service.send_push_notification.assert_called_once()
```

### 5. Running the Service

```bash
# Install dependencies
pip install kafka-python

# Set environment variables
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# Run service
python services/notification_service.py

# In another terminal, publish a test event
python -c "
from kafka import KafkaProducer
import json
from datetime import datetime

producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

event = {
    'event_type': 'reminder',
    'task_id': 123,
    'user_id': 'user_456',
    'title': 'Complete project report',
    'due_at': '2026-01-15T10:00:00',
    'notification_type': 'email'
}

producer.send('reminders', value=event)
producer.flush()
print('Event published')
"
```

## Monitoring

```python
# Add metrics tracking
from prometheus_client import Counter, Histogram, start_http_server

notifications_sent = Counter(
    'notifications_sent_total',
    'Total notifications sent',
    ['type', 'status']
)

notification_duration = Histogram(
    'notification_duration_seconds',
    'Time to send notification',
    ['type']
)

# In send_email method:
with notification_duration.labels(type='email').time():
    # Send email
    pass
notifications_sent.labels(type='email', status='success').inc()

# Start metrics server
start_http_server(8000)
```

## Best Practices

1. **Idempotency**: Track sent notifications to avoid duplicates
2. **Retry Logic**: Implement exponential backoff for failed sends
3. **Rate Limiting**: Respect notification service rate limits
4. **Error Handling**: Log failures but don't crash the service
5. **Monitoring**: Track success/failure rates and latency
6. **Graceful Shutdown**: Handle SIGTERM to finish processing current events
