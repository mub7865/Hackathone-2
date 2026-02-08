# Multi-Channel Notification Flow

This guide demonstrates how to implement multi-channel notification workflows with fallback strategies.

## Overview

Multi-channel notifications allow you to:
- Send the same notification via multiple channels
- Implement fallback strategies when primary channel fails
- Respect user preferences for each channel
- Track delivery across all channels

## Basic Multi-Channel Flow

```python
from notification_service import NotificationService
from notification_model import NotificationChannel

# Send via multiple channels
notifications = notification_service.send_multi_channel(
    user_id="user_123",
    channels=[
        NotificationChannel.PUSH,
        NotificationChannel.EMAIL,
        NotificationChannel.SMS
    ],
    template_name="task_reminder",
    data={
        "task_title": "Complete project",
        "due_date": "2024-01-10"
    },
    fallback=False  # Send to all channels
)
```

## Fallback Strategy

### Strategy 1: Sequential Fallback

Try channels in order until one succeeds:

```python
async def send_with_fallback(
    user_id: str,
    message_data: dict,
    channels: list[NotificationChannel] = None
):
    """Send notification with fallback to next channel on failure."""

    # Default channel priority
    if channels is None:
        channels = [
            NotificationChannel.PUSH,    # Try push first (fastest)
            NotificationChannel.EMAIL,   # Then email (reliable)
            NotificationChannel.SMS      # Finally SMS (most expensive)
        ]

    for channel in channels:
        try:
            notification = notification_service.send(
                user_id=user_id,
                channel=channel,
                template_name="task_reminder",
                data=message_data
            )

            # Check if sent successfully
            if notification.status == NotificationStatus.SENT:
                logger.info(f"Notification sent via {channel}")
                return {
                    "success": True,
                    "channel": channel,
                    "notification_id": notification.id
                }

        except Exception as e:
            logger.warning(f"Failed to send via {channel}: {e}")
            continue

    # All channels failed
    raise Exception("All notification channels failed")
```

### Strategy 2: Parallel with First Success

Send to all channels simultaneously, use first successful delivery:

```python
import asyncio

async def send_parallel_first_success(
    user_id: str,
    message_data: dict,
    channels: list[NotificationChannel]
):
    """Send to all channels, return first successful delivery."""

    async def send_to_channel(channel):
        try:
            notification = notification_service.send(
                user_id=user_id,
                channel=channel,
                template_name="task_reminder",
                data=message_data
            )
            return {"success": True, "channel": channel, "notification": notification}
        except Exception as e:
            return {"success": False, "channel": channel, "error": str(e)}

    # Send to all channels in parallel
    tasks = [send_to_channel(channel) for channel in channels]

    # Wait for first successful result
    for coro in asyncio.as_completed(tasks):
        result = await coro
        if result["success"]:
            return result

    raise Exception("All channels failed")
```

### Strategy 3: Smart Channel Selection

Choose channel based on user preferences and context:

```python
def select_best_channel(
    user_id: str,
    urgency: str,
    time_of_day: datetime
) -> NotificationChannel:
    """Select best channel based on context."""

    # Get user preferences
    preferences = preference_manager.get_preferences(user_id)

    # Check quiet hours
    if preferences.quiet_hours_enabled and is_quiet_hours(preferences, time_of_day):
        # During quiet hours, only use in-app
        return NotificationChannel.IN_APP

    # Urgent notifications
    if urgency == "urgent":
        # Try push first, then SMS
        if preferences.push_enabled:
            return NotificationChannel.PUSH
        elif preferences.sms_enabled:
            return NotificationChannel.SMS
        else:
            return NotificationChannel.EMAIL

    # Normal notifications
    if urgency == "normal":
        # Prefer email for detailed content
        if preferences.email_enabled:
            return NotificationChannel.EMAIL
        elif preferences.push_enabled:
            return NotificationChannel.PUSH
        else:
            return NotificationChannel.IN_APP

    # Low priority
    return NotificationChannel.IN_APP
```

## Use Case Examples

### Use Case 1: Critical Alert

Send critical alerts via all available channels:

```python
async def send_critical_alert(user_id: str, alert_message: str):
    """Send critical alert via all channels."""

    channels = [
        NotificationChannel.PUSH,
        NotificationChannel.SMS,
        NotificationChannel.EMAIL,
        NotificationChannel.IN_APP
    ]

    data = {
        "alert_message": alert_message,
        "severity": "critical",
        "timestamp": datetime.utcnow().isoformat()
    }

    # Send to all channels (no fallback, send to all)
    notifications = notification_service.send_multi_channel(
        user_id=user_id,
        channels=channels,
        template_name="critical_alert",
        data=data,
        fallback=False  # Send to ALL channels
    )

    return {
        "sent_count": len(notifications),
        "channels": [n.channel for n in notifications]
    }
```

### Use Case 2: Task Reminder with Escalation

Start with push, escalate to email if not acknowledged:

```python
async def send_reminder_with_escalation(
    user_id: str,
    task_data: dict,
    escalation_delay_minutes: int = 30
):
    """Send reminder with escalation if not acknowledged."""

    # Send push notification first
    push_notification = notification_service.send(
        user_id=user_id,
        channel=NotificationChannel.PUSH,
        template_name="task_reminder",
        data=task_data
    )

    # Schedule escalation email
    from celery import current_app

    current_app.send_task(
        'tasks.escalate_notification',
        args=[push_notification.id, user_id, task_data],
        countdown=escalation_delay_minutes * 60
    )

    return push_notification


# Celery task for escalation
@celery_app.task
def escalate_notification(
    original_notification_id: int,
    user_id: str,
    task_data: dict
):
    """Escalate notification if not acknowledged."""

    with Session(engine) as session:
        notification = session.get(Notification, original_notification_id)

        # Check if user acknowledged (read) the notification
        if notification.read_at is None:
            # Not acknowledged, send email
            notification_service.send(
                user_id=user_id,
                channel=NotificationChannel.EMAIL,
                template_name="task_reminder_escalated",
                data={
                    **task_data,
                    "escalation_reason": "No response to push notification"
                }
            )
            logger.info(f"Escalated notification {original_notification_id} to email")
```

### Use Case 3: Digest with Channel Preference

Send daily digest via user's preferred channel:

```python
async def send_daily_digest(user_id: str, digest_data: dict):
    """Send daily digest via user's preferred channel."""

    preferences = preference_manager.get_preferences(user_id)

    # Determine channel based on email frequency preference
    if preferences.email_frequency == "daily":
        channel = NotificationChannel.EMAIL
    elif preferences.push_enabled:
        channel = NotificationChannel.PUSH
    else:
        channel = NotificationChannel.IN_APP

    notification = notification_service.send(
        user_id=user_id,
        channel=channel,
        template_name="daily_digest",
        data=digest_data
    )

    return notification
```

### Use Case 4: OTP with SMS Fallback

Send OTP via push, fallback to SMS if push fails:

```python
async def send_otp(user_id: str, otp: str):
    """Send OTP with SMS fallback."""

    data = {
        "otp": otp,
        "validity_minutes": 5
    }

    try:
        # Try push first (free)
        notification = notification_service.send(
            user_id=user_id,
            channel=NotificationChannel.PUSH,
            template_name="otp_verification",
            data=data
        )

        # Wait a few seconds to see if delivered
        await asyncio.sleep(3)

        # Check delivery status
        status = notification_service.get_notification_status(notification.id)

        if status["status"] in [NotificationStatus.DELIVERED, NotificationStatus.OPENED]:
            return {"channel": "push", "notification_id": notification.id}

    except Exception as e:
        logger.warning(f"Push notification failed: {e}")

    # Fallback to SMS (costs money)
    notification = notification_service.send(
        user_id=user_id,
        channel=NotificationChannel.SMS,
        template_name="otp_verification",
        data=data
    )

    return {"channel": "sms", "notification_id": notification.id}
```

## Channel-Specific Considerations

### Push Notifications

**Pros:**
- Instant delivery
- Free (after setup)
- High engagement

**Cons:**
- Requires app installation
- User can disable
- May not be delivered if app not running

**Best for:**
- Real-time updates
- Urgent alerts
- Engagement notifications

### Email

**Pros:**
- Reliable delivery
- Rich content support
- Universal (everyone has email)

**Cons:**
- May go to spam
- Slower delivery
- Lower open rates

**Best for:**
- Detailed information
- Receipts and confirmations
- Digest notifications

### SMS

**Pros:**
- High open rate (98%)
- Works without internet
- Immediate delivery

**Cons:**
- Expensive
- Character limit
- Requires phone number

**Best for:**
- OTP codes
- Critical alerts
- Time-sensitive reminders

### In-App

**Pros:**
- Free
- Always available
- Rich UI support

**Cons:**
- Requires app to be open
- Not real-time
- Easy to miss

**Best for:**
- Non-urgent updates
- Feature announcements
- Social interactions

## Decision Tree

```python
def choose_notification_channels(
    urgency: str,
    content_length: str,
    cost_sensitive: bool,
    user_preferences: NotificationPreference
) -> list[NotificationChannel]:
    """Choose appropriate channels based on context."""

    channels = []

    # Critical/Urgent
    if urgency == "critical":
        # Use all available channels
        if user_preferences.push_enabled:
            channels.append(NotificationChannel.PUSH)
        if user_preferences.sms_enabled:
            channels.append(NotificationChannel.SMS)
        if user_preferences.email_enabled:
            channels.append(NotificationChannel.EMAIL)
        channels.append(NotificationChannel.IN_APP)
        return channels

    # High urgency
    if urgency == "high":
        # Push + SMS or Email
        if user_preferences.push_enabled:
            channels.append(NotificationChannel.PUSH)

        if not cost_sensitive and user_preferences.sms_enabled:
            channels.append(NotificationChannel.SMS)
        elif user_preferences.email_enabled:
            channels.append(NotificationChannel.EMAIL)

        return channels

    # Normal urgency
    if urgency == "normal":
        # Long content -> Email
        if content_length == "long" and user_preferences.email_enabled:
            channels.append(NotificationChannel.EMAIL)
        # Short content -> Push or In-App
        elif user_preferences.push_enabled:
            channels.append(NotificationChannel.PUSH)
        else:
            channels.append(NotificationChannel.IN_APP)

        return channels

    # Low urgency
    # In-App only
    channels.append(NotificationChannel.IN_APP)
    return channels
```

## Monitoring Multi-Channel Delivery

```python
async def monitor_multi_channel_delivery(notification_ids: list[int]):
    """Monitor delivery across multiple channels."""

    results = []

    for notification_id in notification_ids:
        status = notification_service.get_notification_status(notification_id)
        results.append({
            "notification_id": notification_id,
            "channel": status["channel"],
            "status": status["status"],
            "sent_at": status["sent_at"],
            "delivered_at": status["delivered_at"]
        })

    # Calculate metrics
    total = len(results)
    delivered = sum(1 for r in results if r["status"] == NotificationStatus.DELIVERED)
    failed = sum(1 for r in results if r["status"] == NotificationStatus.FAILED)

    return {
        "total": total,
        "delivered": delivered,
        "failed": failed,
        "delivery_rate": (delivered / total * 100) if total > 0 else 0,
        "details": results
    }
```

## Best Practices

1. **Start with cheapest channel**: Try push before SMS
2. **Respect user preferences**: Always check before sending
3. **Consider time zones**: Don't send SMS at 3 AM
4. **Track delivery**: Monitor which channels work best
5. **Implement rate limiting**: Prevent spam across all channels
6. **Use appropriate urgency**: Don't overuse critical alerts
7. **Test fallback logic**: Ensure fallbacks work correctly
8. **Monitor costs**: Track SMS usage to control expenses
9. **Optimize templates**: Different content for different channels
10. **Measure engagement**: Track open/click rates per channel

## Testing Multi-Channel Flow

```python
import pytest

@pytest.mark.asyncio
async def test_multi_channel_fallback():
    """Test fallback to next channel on failure."""

    # Mock push failure
    with patch.object(push_sender, 'send', side_effect=Exception("Push failed")):
        result = await send_with_fallback(
            user_id="user_123",
            message_data={"task_title": "Test"},
            channels=[NotificationChannel.PUSH, NotificationChannel.EMAIL]
        )

    # Should fallback to email
    assert result["success"] is True
    assert result["channel"] == NotificationChannel.EMAIL


@pytest.mark.asyncio
async def test_all_channels_fail():
    """Test when all channels fail."""

    # Mock all failures
    with patch.object(push_sender, 'send', side_effect=Exception("Failed")), \
         patch.object(email_sender, 'send', side_effect=Exception("Failed")), \
         patch.object(sms_sender, 'send', side_effect=Exception("Failed")):

        with pytest.raises(Exception, match="All notification channels failed"):
            await send_with_fallback(
                user_id="user_123",
                message_data={"task_title": "Test"},
                channels=[
                    NotificationChannel.PUSH,
                    NotificationChannel.EMAIL,
                    NotificationChannel.SMS
                ]
            )
```

## Cost Optimization

```python
def calculate_notification_cost(
    channel: NotificationChannel,
    count: int
) -> float:
    """Calculate cost of sending notifications."""

    # Cost per notification (example prices)
    costs = {
        NotificationChannel.PUSH: 0.0,      # Free
        NotificationChannel.EMAIL: 0.001,   # $0.001 per email
        NotificationChannel.SMS: 0.05,      # $0.05 per SMS
        NotificationChannel.IN_APP: 0.0     # Free
    }

    return costs.get(channel, 0.0) * count


def optimize_channel_selection(
    user_count: int,
    budget: float,
    urgency: str
) -> NotificationChannel:
    """Select most cost-effective channel within budget."""

    if urgency == "critical":
        # Cost doesn't matter for critical alerts
        return NotificationChannel.SMS

    # Calculate cost for each channel
    sms_cost = calculate_notification_cost(NotificationChannel.SMS, user_count)
    email_cost = calculate_notification_cost(NotificationChannel.EMAIL, user_count)

    if sms_cost <= budget:
        return NotificationChannel.SMS
    elif email_cost <= budget:
        return NotificationChannel.EMAIL
    else:
        return NotificationChannel.PUSH  # Free fallback
```
