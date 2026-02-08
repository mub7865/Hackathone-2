# Celery Async Notifications

This example demonstrates using Celery for asynchronous notification processing with retry logic and scheduling.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     FastAPI Application                      │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │   REST API   │────────▶│    Celery    │                 │
│  │  Endpoints   │         │    Tasks     │                 │
│  └──────────────┘         └──────────────┘                 │
│                                   │                          │
│                                   ▼                          │
│                           ┌──────────────┐                 │
│                           │    Redis/    │                 │
│                           │   RabbitMQ   │                 │
│                           └──────────────┘                 │
│                                   │                          │
│                                   ▼                          │
│                           ┌──────────────┐                 │
│                           │   Celery     │                 │
│                           │   Workers    │                 │
│                           └──────────────┘                 │
│                                   │                          │
│                                   ▼                          │
│                           ┌──────────────┐                 │
│                           │ Notification │                 │
│                           │  Providers   │                 │
│                           └──────────────┘                 │
└─────────────────────────────────────────────────────────────┘
```

## Setup

### 1. Install Dependencies

```bash
pip install celery redis flower
```

### 2. Celery Configuration (celery_config.py)

```python
from celery import Celery
from kombu import Exchange, Queue

# Create Celery app
celery_app = Celery(
    'notifications',
    broker='redis://localhost:6379/0',
    backend='redis://localhost:6379/0'
)

# Configuration
celery_app.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
    task_track_started=True,
    task_time_limit=300,  # 5 minutes
    task_soft_time_limit=240,  # 4 minutes
    worker_prefetch_multiplier=4,
    worker_max_tasks_per_child=1000,
)

# Task routing
celery_app.conf.task_routes = {
    'notifications.tasks.send_email': {'queue': 'email'},
    'notifications.tasks.send_sms': {'queue': 'sms'},
    'notifications.tasks.send_push': {'queue': 'push'},
    'notifications.tasks.send_batch': {'queue': 'batch'},
}

# Queue definitions
celery_app.conf.task_queues = (
    Queue('default', Exchange('default'), routing_key='default'),
    Queue('email', Exchange('email'), routing_key='email'),
    Queue('sms', Exchange('sms'), routing_key='sms'),
    Queue('push', Exchange('push'), routing_key='push'),
    Queue('batch', Exchange('batch'), routing_key='batch'),
)

# Retry configuration
celery_app.conf.task_default_retry_delay = 60  # 1 minute
celery_app.conf.task_max_retries = 3
```

### 3. Celery Tasks (tasks.py)

```python
from celery import Task
from celery.utils.log import get_task_logger
from sqlmodel import Session, create_engine
from datetime import datetime

from celery_config import celery_app
from notification_service import NotificationService
from notification_model import Notification, NotificationStatus
from email_sender import create_email_sender, EmailProvider
from sms_sender import create_sms_sender, SMSProvider
from push_sender import create_push_sender, PushProvider

logger = get_task_logger(__name__)

# Database
engine = create_engine("postgresql://user:pass@localhost/db")

# Initialize senders
email_sender = create_email_sender(
    provider=EmailProvider.SENDGRID,
    from_email="noreply@example.com",
    api_key="your_api_key"
)

sms_sender = create_sms_sender(
    provider=SMSProvider.TWILIO,
    from_phone="+1234567890",
    account_sid="your_sid",
    auth_token="your_token"
)

push_sender = create_push_sender(
    provider=PushProvider.FIREBASE,
    credentials_path="/path/to/credentials.json"
)

notification_service = NotificationService(
    session_factory=lambda: Session(engine),
    email_sender=email_sender,
    sms_sender=sms_sender,
    push_sender=push_sender
)


class NotificationTask(Task):
    """Base task for notifications with retry logic."""

    autoretry_for = (Exception,)
    retry_kwargs = {'max_retries': 3}
    retry_backoff = True
    retry_backoff_max = 600  # 10 minutes
    retry_jitter = True


@celery_app.task(base=NotificationTask, bind=True)
def send_notification_task(self, notification_id: int):
    """Send notification asynchronously."""
    try:
        logger.info(f"Processing notification {notification_id}")

        with Session(engine) as session:
            notification = session.get(Notification, notification_id)

            if not notification:
                logger.error(f"Notification {notification_id} not found")
                return

            # Send notification
            notification_service._send_notification(notification, session)

            logger.info(f"Notification {notification_id} sent successfully")

    except Exception as e:
        logger.error(f"Failed to send notification {notification_id}: {e}")

        # Update retry count
        with Session(engine) as session:
            notification = session.get(Notification, notification_id)
            if notification:
                notification.retry_count = self.request.retries
                session.commit()

        raise


@celery_app.task(base=NotificationTask)
def send_email_task(
    to_email: str,
    subject: str,
    html_content: str,
    text_content: str = None
):
    """Send email notification."""
    from email_sender import EmailMessage

    try:
        message = EmailMessage(
            to_email=to_email,
            subject=subject,
            html_content=html_content,
            text_content=text_content
        )

        result = email_sender.send(message)
        logger.info(f"Email sent to {to_email}")
        return result

    except Exception as e:
        logger.error(f"Failed to send email to {to_email}: {e}")
        raise


@celery_app.task(base=NotificationTask)
def send_sms_task(to_phone: str, message: str):
    """Send SMS notification."""
    from sms_sender import SMSMessage

    try:
        sms_message = SMSMessage(
            to_phone=to_phone,
            message=message
        )

        result = sms_sender.send(sms_message)
        logger.info(f"SMS sent to {to_phone}")
        return result

    except Exception as e:
        logger.error(f"Failed to send SMS to {to_phone}: {e}")
        raise


@celery_app.task(base=NotificationTask)
def send_push_task(
    device_token: str,
    title: str,
    body: str,
    data: dict = None
):
    """Send push notification."""
    from push_sender import PushMessage

    try:
        push_message = PushMessage(
            device_token=device_token,
            title=title,
            body=body,
            data=data or {}
        )

        result = push_sender.send(push_message)
        logger.info(f"Push notification sent to {device_token}")
        return result

    except Exception as e:
        logger.error(f"Failed to send push to {device_token}: {e}")
        raise


@celery_app.task
def send_batch_notifications(
    user_ids: list[str],
    channel: str,
    template_name: str,
    data: dict
):
    """Send notifications to multiple users."""
    from notification_model import NotificationChannel

    results = []

    for user_id in user_ids:
        try:
            notification = notification_service.send(
                user_id=user_id,
                channel=NotificationChannel(channel),
                template_name=template_name,
                data=data
            )
            results.append({"user_id": user_id, "status": "sent", "notification_id": notification.id})
        except Exception as e:
            logger.error(f"Failed to send to {user_id}: {e}")
            results.append({"user_id": user_id, "status": "failed", "error": str(e)})

    return results


@celery_app.task
def send_scheduled_notification(notification_id: int):
    """Send scheduled notification."""
    with Session(engine) as session:
        notification = session.get(Notification, notification_id)

        if not notification:
            logger.error(f"Notification {notification_id} not found")
            return

        # Check if scheduled time has passed
        if notification.scheduled_for and notification.scheduled_for > datetime.utcnow():
            logger.info(f"Notification {notification_id} not yet due")
            return

        # Send notification
        notification_service._send_notification(notification, session)


@celery_app.task
def send_daily_digest(user_id: str):
    """Send daily digest notification."""
    from notification_model import NotificationChannel

    # Get user's tasks for today
    # This is a placeholder - implement actual logic
    tasks_data = {
        "user_name": "User",
        "date": datetime.utcnow().strftime("%Y-%m-%d"),
        "tasks_due_today": 5,
        "tasks_completed": 3,
        "tasks_overdue": 1,
        "upcoming_tasks": [],
        "dashboard_url": "https://app.example.com/dashboard"
    }

    notification = notification_service.send(
        user_id=user_id,
        channel=NotificationChannel.EMAIL,
        template_name="daily_digest",
        data=tasks_data
    )

    logger.info(f"Daily digest sent to {user_id}")
    return notification.id


@celery_app.task
def cleanup_old_notifications(days: int = 30):
    """Clean up old notifications."""
    from datetime import timedelta
    from sqlmodel import select, delete

    cutoff = datetime.utcnow() - timedelta(days=days)

    with Session(engine) as session:
        # Delete old notifications
        result = session.exec(
            delete(Notification)
            .where(Notification.created_at < cutoff)
            .where(Notification.status.in_([
                NotificationStatus.SENT,
                NotificationStatus.DELIVERED,
                NotificationStatus.FAILED
            ]))
        )

        session.commit()
        count = result.rowcount

    logger.info(f"Cleaned up {count} old notifications")
    return count


# Periodic tasks
from celery.schedules import crontab

celery_app.conf.beat_schedule = {
    'send-daily-digests': {
        'task': 'tasks.send_daily_digests_to_all',
        'schedule': crontab(hour=9, minute=0),  # 9 AM daily
    },
    'cleanup-old-notifications': {
        'task': 'tasks.cleanup_old_notifications',
        'schedule': crontab(hour=2, minute=0),  # 2 AM daily
    },
}


@celery_app.task
def send_daily_digests_to_all():
    """Send daily digests to all users who opted in."""
    from notification_preferences import PreferenceManager

    preference_manager = PreferenceManager(lambda: Session(engine))
    user_ids = preference_manager.get_digest_users(frequency="daily")

    for user_id in user_ids:
        send_daily_digest.delay(user_id)

    logger.info(f"Scheduled daily digests for {len(user_ids)} users")
    return len(user_ids)
```

### 4. FastAPI Integration (main.py)

```python
from fastapi import FastAPI, BackgroundTasks
from tasks import send_notification_task, send_email_task, send_batch_notifications

app = FastAPI()

@app.post("/notifications/send")
async def send_notification(notification_id: int):
    """Queue notification for sending."""
    # Queue task
    task = send_notification_task.delay(notification_id)

    return {
        "status": "queued",
        "task_id": task.id,
        "notification_id": notification_id
    }

@app.post("/notifications/send-email")
async def send_email(
    to_email: str,
    subject: str,
    html_content: str
):
    """Queue email for sending."""
    task = send_email_task.delay(to_email, subject, html_content)

    return {
        "status": "queued",
        "task_id": task.id
    }

@app.post("/notifications/send-batch")
async def send_batch(
    user_ids: list[str],
    channel: str,
    template_name: str,
    data: dict
):
    """Queue batch notifications."""
    task = send_batch_notifications.delay(user_ids, channel, template_name, data)

    return {
        "status": "queued",
        "task_id": task.id,
        "user_count": len(user_ids)
    }

@app.get("/tasks/{task_id}")
async def get_task_status(task_id: str):
    """Get task status."""
    from celery.result import AsyncResult

    task = AsyncResult(task_id, app=celery_app)

    return {
        "task_id": task_id,
        "status": task.status,
        "result": task.result if task.ready() else None
    }
```

## Running the System

### 1. Start Redis

```bash
docker run -d -p 6379:6379 redis:alpine
```

### 2. Start Celery Workers

```bash
# Start default worker
celery -A tasks worker --loglevel=info

# Start workers for specific queues
celery -A tasks worker -Q email --loglevel=info --concurrency=4
celery -A tasks worker -Q sms --loglevel=info --concurrency=2
celery -A tasks worker -Q push --loglevel=info --concurrency=4
celery -A tasks worker -Q batch --loglevel=info --concurrency=2
```

### 3. Start Celery Beat (for scheduled tasks)

```bash
celery -A tasks beat --loglevel=info
```

### 4. Start Flower (monitoring)

```bash
celery -A tasks flower --port=5555
```

Access Flower at http://localhost:5555

### 5. Start FastAPI

```bash
uvicorn main:app --reload
```

## Testing

```bash
# Send notification
curl -X POST http://localhost:8000/notifications/send \
  -H "Content-Type: application/json" \
  -d '{"notification_id": 1}'

# Send email
curl -X POST http://localhost:8000/notifications/send-email \
  -H "Content-Type: application/json" \
  -d '{
    "to_email": "user@example.com",
    "subject": "Test Email",
    "html_content": "<h1>Hello World</h1>"
  }'

# Send batch
curl -X POST http://localhost:8000/notifications/send-batch \
  -H "Content-Type: application/json" \
  -d '{
    "user_ids": ["user1", "user2", "user3"],
    "channel": "email",
    "template_name": "task_reminder",
    "data": {"task_title": "Test Task"}
  }'

# Check task status
curl http://localhost:8000/tasks/{task_id}
```

## Advanced Features

### 1. Task Chaining

```python
from celery import chain

# Send email, then SMS, then push
result = chain(
    send_email_task.s("user@example.com", "Subject", "Content"),
    send_sms_task.s("+1234567890", "SMS message"),
    send_push_task.s("device_token", "Title", "Body")
).apply_async()
```

### 2. Task Groups

```python
from celery import group

# Send to multiple users in parallel
job = group(
    send_email_task.s(f"user{i}@example.com", "Subject", "Content")
    for i in range(100)
)

result = job.apply_async()
```

### 3. Task Callbacks

```python
@celery_app.task
def on_success_callback(result):
    """Called when task succeeds."""
    logger.info(f"Task succeeded: {result}")

@celery_app.task
def on_failure_callback(exc, task_id, args, kwargs, einfo):
    """Called when task fails."""
    logger.error(f"Task {task_id} failed: {exc}")

# Use callbacks
send_email_task.apply_async(
    args=["user@example.com", "Subject", "Content"],
    link=on_success_callback.s(),
    link_error=on_failure_callback.s()
)
```

### 4. Rate Limiting

```python
@celery_app.task(rate_limit='10/m')  # 10 per minute
def rate_limited_task():
    pass
```

### 5. Task Priority

```python
# High priority
send_email_task.apply_async(
    args=["user@example.com", "Urgent", "Content"],
    priority=9
)

# Low priority
send_email_task.apply_async(
    args=["user@example.com", "Newsletter", "Content"],
    priority=1
)
```

## Monitoring

### Flower Dashboard

- **Tasks**: View all tasks and their status
- **Workers**: Monitor worker health and performance
- **Broker**: View queue lengths and message rates
- **Monitor**: Real-time task execution graphs

### Custom Monitoring

```python
from celery.events import EventReceiver
from kombu import Connection

def monitor_tasks():
    """Monitor task events."""
    connection = Connection('redis://localhost:6379/0')

    def on_task_sent(event):
        print(f"Task sent: {event['uuid']}")

    def on_task_succeeded(event):
        print(f"Task succeeded: {event['uuid']}")

    def on_task_failed(event):
        print(f"Task failed: {event['uuid']}")

    with connection as conn:
        recv = EventReceiver(conn, handlers={
            'task-sent': on_task_sent,
            'task-succeeded': on_task_succeeded,
            'task-failed': on_task_failed,
        })
        recv.capture(limit=None, timeout=None)
```

## Best Practices

1. **Use task queues**: Separate queues for different notification types
2. **Set timeouts**: Prevent tasks from running forever
3. **Implement retries**: Handle transient failures
4. **Monitor workers**: Use Flower for real-time monitoring
5. **Rate limit**: Prevent overwhelming providers
6. **Use priorities**: Ensure urgent notifications are sent first
7. **Clean up**: Regularly remove old task results
8. **Log everything**: Track task execution for debugging
9. **Test thoroughly**: Test retry logic and error handling
10. **Scale workers**: Add more workers for high load
