# Reminder Notifications Skill

## Overview

This skill provides comprehensive patterns for implementing multi-channel notification systems in Python applications. It covers email, SMS, push notifications, and in-app notifications with delivery tracking, retry logic, and template management.

## When to Use This Skill

Use this skill when you need to:
- Send email notifications (transactional, marketing, reminders)
- Send SMS notifications (alerts, OTPs, reminders)
- Send push notifications (mobile, web push)
- Implement in-app notification systems
- Track notification delivery and engagement
- Manage notification templates
- Handle notification preferences and opt-outs
- Implement retry logic for failed deliveries
- Rate limit notification sending

## Technology Stack

### Email Providers
- **SMTP**: Direct email sending via SMTP servers
- **SendGrid**: Cloud-based email delivery service
- **AWS SES**: Amazon Simple Email Service
- **Mailgun**: Email API service
- **Postmark**: Transactional email service

### SMS Providers
- **Twilio**: SMS, voice, and messaging API
- **AWS SNS**: Amazon Simple Notification Service
- **Vonage (Nexmo)**: SMS and voice API
- **MessageBird**: Multi-channel messaging platform

### Push Notification Providers
- **Firebase Cloud Messaging (FCM)**: Mobile and web push
- **OneSignal**: Multi-platform push notifications
- **AWS SNS**: Mobile push notifications
- **Apple Push Notification Service (APNs)**: iOS push
- **Web Push**: Browser push notifications

### Python Libraries
- **smtplib**: Built-in SMTP client
- **sendgrid**: SendGrid Python library
- **boto3**: AWS SDK for Python (SES, SNS)
- **twilio**: Twilio Python library
- **firebase-admin**: Firebase Admin SDK
- **jinja2**: Template engine
- **celery**: Async task queue for background sending

## Key Concepts

### 1. Notification Channels
Different channels for different use cases:
- **Email**: Detailed information, receipts, reports
- **SMS**: Urgent alerts, OTPs, time-sensitive reminders
- **Push**: Real-time updates, engagement
- **In-App**: Non-urgent updates, feature announcements

### 2. Notification Templates
Reusable templates with variable substitution:
```python
template = """
Hello {{user_name}},

Your task "{{task_title}}" is due on {{due_date}}.

Best regards,
The Team
"""
```

### 3. Delivery Tracking
Track notification lifecycle:
- **Queued**: Notification created, waiting to send
- **Sent**: Successfully sent to provider
- **Delivered**: Confirmed delivery by provider
- **Failed**: Delivery failed
- **Bounced**: Email bounced
- **Opened**: User opened notification (email tracking)
- **Clicked**: User clicked link in notification

### 4. Retry Logic
Handle transient failures:
- Exponential backoff
- Maximum retry attempts
- Dead letter queue for permanent failures

### 5. Rate Limiting
Prevent spam and respect provider limits:
- Per-user rate limits
- Per-channel rate limits
- Global rate limits

### 6. User Preferences
Respect user notification preferences:
- Channel preferences (email, SMS, push)
- Frequency preferences (immediate, daily digest, weekly)
- Opt-out management
- Quiet hours

## Quick Start

### 1. Email Notification with SendGrid

```python
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

def send_email_notification(
    to_email: str,
    subject: str,
    html_content: str
):
    """Send email via SendGrid."""
    message = Mail(
        from_email='noreply@example.com',
        to_emails=to_email,
        subject=subject,
        html_content=html_content
    )

    sg = SendGridAPIClient(os.environ.get('SENDGRID_API_KEY'))
    response = sg.send(message)

    return response.status_code == 202
```

### 2. SMS Notification with Twilio

```python
from twilio.rest import Client

def send_sms_notification(
    to_phone: str,
    message: str
):
    """Send SMS via Twilio."""
    client = Client(
        os.environ.get('TWILIO_ACCOUNT_SID'),
        os.environ.get('TWILIO_AUTH_TOKEN')
    )

    message = client.messages.create(
        body=message,
        from_=os.environ.get('TWILIO_PHONE_NUMBER'),
        to=to_phone
    )

    return message.sid
```

### 3. Push Notification with Firebase

```python
from firebase_admin import messaging

def send_push_notification(
    device_token: str,
    title: str,
    body: str,
    data: dict = None
):
    """Send push notification via Firebase."""
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        data=data or {},
        token=device_token
    )

    response = messaging.send(message)
    return response
```

### 4. FastAPI Integration

```python
from fastapi import FastAPI, BackgroundTasks
from notification_service import NotificationService

app = FastAPI()
notification_service = NotificationService()

@app.post("/notifications/send")
async def send_notification(
    notification: NotificationCreate,
    background_tasks: BackgroundTasks
):
    """Send notification in background."""
    background_tasks.add_task(
        notification_service.send,
        notification
    )
    return {"status": "queued"}
```

## File Structure

```
reminder-notifications/
├── SKILL.md                           # This file
├── Templates/
│   ├── email-sender.py.tpl           # Email sending service
│   ├── sms-sender.py.tpl             # SMS sending service
│   ├── push-sender.py.tpl            # Push notification service
│   ├── notification-service.py.tpl   # Unified notification service
│   ├── notification-model.py.tpl     # Database models
│   ├── notification-templates.py.tpl # Template management
│   └── notification-preferences.py.tpl # User preferences
├── Examples/
│   ├── fastapi-notifications.md      # FastAPI integration
│   ├── celery-notifications.md       # Async with Celery
│   ├── notification-templates.md     # Template examples
│   └── multi-channel-flow.md         # Multi-channel workflow
├── Testing/
│   ├── test-email-sender.py.tpl     # Email tests
│   ├── test-sms-sender.py.tpl       # SMS tests
│   └── verify-notifications.sh       # Verification script
└── Troubleshooting/
    ├── delivery-issues.md            # Delivery problems
    └── provider-issues.md            # Provider-specific issues
```

## Integration Patterns

### Pattern 1: Background Task Queue

```python
from celery import Celery

celery_app = Celery('notifications')

@celery_app.task(bind=True, max_retries=3)
def send_notification_task(self, notification_id: int):
    """Send notification as background task."""
    try:
        notification = get_notification(notification_id)
        notification_service.send(notification)
    except Exception as e:
        # Retry with exponential backoff
        raise self.retry(exc=e, countdown=2 ** self.request.retries)
```

### Pattern 2: Multi-Channel Fallback

```python
async def send_with_fallback(
    user: User,
    message: str,
    channels: list[str] = ['push', 'email', 'sms']
):
    """Try channels in order until one succeeds."""
    for channel in channels:
        try:
            if channel == 'push' and user.push_token:
                await send_push(user.push_token, message)
                return 'push'
            elif channel == 'email' and user.email:
                await send_email(user.email, message)
                return 'email'
            elif channel == 'sms' and user.phone:
                await send_sms(user.phone, message)
                return 'sms'
        except Exception as e:
            logger.warning(f"Failed to send via {channel}: {e}")
            continue

    raise Exception("All notification channels failed")
```

### Pattern 3: Batch Notifications

```python
async def send_batch_notifications(
    notifications: list[Notification]
):
    """Send notifications in batches."""
    batch_size = 100

    for i in range(0, len(notifications), batch_size):
        batch = notifications[i:i + batch_size]

        # Send batch
        tasks = [
            send_notification(notif)
            for notif in batch
        ]

        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Log results
        for notif, result in zip(batch, results):
            if isinstance(result, Exception):
                logger.error(f"Failed to send {notif.id}: {result}")
```

## Best Practices

1. **Use Background Tasks**: Never send notifications synchronously in API requests
2. **Implement Retry Logic**: Handle transient failures with exponential backoff
3. **Track Delivery**: Store notification status for debugging and analytics
4. **Respect Preferences**: Always check user notification preferences
5. **Rate Limit**: Prevent spam and respect provider limits
6. **Use Templates**: Centralize notification content for consistency
7. **Test Thoroughly**: Test with real providers in staging environment
8. **Monitor Metrics**: Track delivery rates, open rates, click rates
9. **Handle Opt-Outs**: Respect unsubscribe requests immediately
10. **Secure Credentials**: Store API keys in environment variables

## Common Use Cases

### Use Case 1: Task Reminder
```python
# Send reminder 1 hour before task due
notification = Notification(
    user_id=task.user_id,
    channel='email',
    template='task_reminder',
    data={
        'task_title': task.title,
        'due_date': task.due_date,
        'task_url': f'https://app.example.com/tasks/{task.id}'
    }
)
```

### Use Case 2: OTP Verification
```python
# Send OTP via SMS
otp = generate_otp()
notification = Notification(
    user_id=user.id,
    channel='sms',
    template='otp_verification',
    data={'otp': otp}
)
```

### Use Case 3: Daily Digest
```python
# Send daily summary email
tasks = get_user_tasks_for_today(user.id)
notification = Notification(
    user_id=user.id,
    channel='email',
    template='daily_digest',
    data={
        'tasks': tasks,
        'date': datetime.now().strftime('%Y-%m-%d')
    }
)
```

## Next Steps

1. Choose notification providers based on your needs
2. Set up provider accounts and get API keys
3. Implement notification service using templates
4. Create notification templates for your use cases
5. Set up background task queue (Celery)
6. Implement delivery tracking
7. Add user preference management
8. Test with real providers
9. Monitor delivery metrics
10. Optimize based on engagement data

## Resources

- [SendGrid Documentation](https://docs.sendgrid.com/)
- [Twilio Documentation](https://www.twilio.com/docs)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [AWS SES Documentation](https://docs.aws.amazon.com/ses/)
- [Celery Documentation](https://docs.celeryproject.org/)
