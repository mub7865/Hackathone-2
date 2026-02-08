# Troubleshooting Notification Delivery Issues

This guide covers common notification delivery problems and their solutions.

## Table of Contents

1. [Email Delivery Issues](#email-delivery-issues)
2. [SMS Delivery Issues](#sms-delivery-issues)
3. [Push Notification Issues](#push-notification-issues)
4. [In-App Notification Issues](#in-app-notification-issues)
5. [General Delivery Problems](#general-delivery-problems)

---

## Email Delivery Issues

### Issue 1: Emails Going to Spam

**Symptoms:**
- Emails are sent but users don't receive them
- Emails found in spam/junk folder

**Diagnosis:**

```python
# Check email headers
def check_spam_score(email_content):
    """Check spam score of email."""
    # Use SpamAssassin or similar tool
    pass
```

**Common Causes and Solutions:**

#### Cause 1: Missing SPF/DKIM/DMARC Records

**Solution:** Configure email authentication

```bash
# Check SPF record
dig TXT example.com | grep spf

# Check DKIM record
dig TXT default._domainkey.example.com

# Check DMARC record
dig TXT _dmarc.example.com
```

Add records to DNS:

```
# SPF
v=spf1 include:_spf.google.com ~all

# DKIM
default._domainkey IN TXT "v=DKIM1; k=rsa; p=YOUR_PUBLIC_KEY"

# DMARC
_dmarc IN TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"
```

#### Cause 2: Poor Email Content

**Solution:** Improve email content

```python
# ❌ Spam triggers
- ALL CAPS SUBJECT
- Too many exclamation marks!!!
- Suspicious links (bit.ly, etc.)
- No unsubscribe link
- Image-only emails

# ✅ Best practices
- Clear, descriptive subject
- Balanced text-to-image ratio
- Legitimate links
- Unsubscribe link
- Plain text alternative
```

#### Cause 3: Low Sender Reputation

**Solution:** Warm up your sending domain

```python
# Gradual sending schedule
day_1 = 50    # emails
day_2 = 100
day_3 = 250
day_4 = 500
day_5 = 1000
# Continue increasing gradually
```

### Issue 2: Emails Not Delivered

**Symptoms:**
- Emails fail to send
- Bounce notifications received

**Diagnosis:**

```python
def check_email_deliverability(email):
    """Check if email address is valid and deliverable."""
    import dns.resolver

    domain = email.split('@')[1]

    try:
        # Check MX records
        mx_records = dns.resolver.resolve(domain, 'MX')
        return len(mx_records) > 0
    except:
        return False
```

**Solutions:**

#### Solution 1: Validate Email Addresses

```python
import re

def validate_email(email):
    """Validate email format."""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))

def check_disposable_email(email):
    """Check if email is from disposable provider."""
    disposable_domains = [
        'tempmail.com',
        '10minutemail.com',
        'guerrillamail.com'
    ]
    domain = email.split('@')[1]
    return domain in disposable_domains
```

#### Solution 2: Handle Bounces

```python
def handle_email_bounce(bounce_event):
    """Handle email bounce notification."""
    if bounce_event['bounce_type'] == 'hard':
        # Permanent failure - remove from list
        mark_email_invalid(bounce_event['email'])
    elif bounce_event['bounce_type'] == 'soft':
        # Temporary failure - retry later
        schedule_retry(bounce_event['email'])
```

### Issue 3: Slow Email Delivery

**Symptoms:**
- Emails take minutes/hours to arrive
- Inconsistent delivery times

**Solutions:**

#### Solution 1: Use Background Tasks

```python
from celery import Celery

@celery_app.task
def send_email_async(email_data):
    """Send email in background."""
    email_sender.send(email_data)
```

#### Solution 2: Batch Sending

```python
def send_batch_emails(emails, batch_size=100):
    """Send emails in batches."""
    for i in range(0, len(emails), batch_size):
        batch = emails[i:i + batch_size]
        email_sender.send_batch(batch)
        time.sleep(1)  # Rate limiting
```

---

## SMS Delivery Issues

### Issue 1: SMS Not Delivered

**Symptoms:**
- SMS fails to send
- No delivery confirmation

**Diagnosis:**

```python
def check_sms_status(message_id):
    """Check SMS delivery status."""
    status = sms_sender.get_message_status(message_id)

    if status['status'] == 'failed':
        print(f"Error: {status['error_code']} - {status['error_message']}")

    return status
```

**Common Error Codes:**

| Code | Meaning | Solution |
|------|---------|----------|
| 21211 | Invalid phone number | Validate phone format |
| 21408 | Permission denied | Check account permissions |
| 21610 | Unsubscribed | Remove from list |
| 30003 | Unreachable | Phone is off/no signal |
| 30005 | Unknown destination | Invalid number |

**Solutions:**

#### Solution 1: Validate Phone Numbers

```python
def validate_phone_number(phone):
    """Validate phone number format (E.164)."""
    import re
    pattern = r'^\+[1-9]\d{1,14}$'
    return bool(re.match(pattern, phone))

def format_phone_number(phone, country_code='+1'):
    """Format phone to E.164."""
    digits = ''.join(filter(str.isdigit, phone))
    if not phone.startswith('+'):
        return f"{country_code}{digits}"
    return f"+{digits}"
```

#### Solution 2: Handle Carrier Filtering

```python
# Avoid spam triggers in SMS
spam_triggers = [
    'FREE',
    'WINNER',
    'CLICK HERE',
    'LIMITED TIME',
    'ACT NOW'
]

def check_sms_content(message):
    """Check if SMS content might be filtered."""
    message_upper = message.upper()
    for trigger in spam_triggers:
        if trigger in message_upper:
            return False, f"Contains spam trigger: {trigger}"
    return True, "OK"
```

### Issue 2: High SMS Costs

**Symptoms:**
- Unexpected high bills
- SMS sent to wrong numbers

**Solutions:**

#### Solution 1: Implement Rate Limiting

```python
class SMSRateLimiter:
    """Rate limiter for SMS sending."""

    def __init__(self, max_per_hour=100):
        self.max_per_hour = max_per_hour
        self.sent_count = {}

    def can_send(self, user_id):
        """Check if user can send SMS."""
        now = datetime.now()
        hour_key = now.strftime('%Y-%m-%d-%H')

        if hour_key not in self.sent_count:
            self.sent_count = {hour_key: {}}

        count = self.sent_count[hour_key].get(user_id, 0)
        return count < self.max_per_hour
```

#### Solution 2: Use SMS Fallback

```python
async def send_with_cost_optimization(user_id, message):
    """Send notification with cost optimization."""

    # Try free channels first
    try:
        # Try push notification (free)
        await send_push(user_id, message)
        return 'push'
    except:
        pass

    try:
        # Try email (cheap)
        await send_email(user_id, message)
        return 'email'
    except:
        pass

    # Only use SMS as last resort (expensive)
    await send_sms(user_id, message)
    return 'sms'
```

---

## Push Notification Issues

### Issue 1: Push Not Received

**Symptoms:**
- Push notifications not appearing
- No error messages

**Diagnosis:**

```python
def diagnose_push_issue(device_token):
    """Diagnose push notification issues."""

    # Check token validity
    if not device_token or len(device_token) < 64:
        return "Invalid device token"

    # Check if token is registered
    # Check if app has notification permissions
    # Check if device is online

    return "OK"
```

**Common Causes:**

#### Cause 1: Invalid Device Token

**Solution:** Refresh device tokens

```python
def refresh_device_token(user_id, old_token, new_token):
    """Update device token."""
    with session_factory() as session:
        user = session.get(User, user_id)
        if user:
            user.push_token = new_token
            session.commit()
```

#### Cause 2: App Not Running

**Solution:** Use high-priority notifications

```python
from firebase_admin import messaging

message = messaging.Message(
    notification=messaging.Notification(
        title="Important Update",
        body="Your task is due soon"
    ),
    android=messaging.AndroidConfig(
        priority='high',  # Wake up device
        notification=messaging.AndroidNotification(
            sound='default',
            priority='high'
        )
    ),
    apns=messaging.APNSConfig(
        headers={'apns-priority': '10'},  # High priority
        payload=messaging.APNSPayload(
            aps=messaging.Aps(
                content_available=True
            )
        )
    ),
    token=device_token
)
```

#### Cause 3: Notification Permissions Disabled

**Solution:** Check and request permissions

```javascript
// Frontend: Check notification permission
if (Notification.permission === 'default') {
    // Request permission
    Notification.requestPermission().then(permission => {
        if (permission === 'granted') {
            // Register for push
            registerForPush();
        }
    });
}
```

### Issue 2: Push Notifications Delayed

**Symptoms:**
- Notifications arrive late
- Inconsistent delivery times

**Solutions:**

#### Solution 1: Use High Priority

```python
# Firebase: Set high priority
android_config = messaging.AndroidConfig(
    priority='high'
)

apns_config = messaging.APNSConfig(
    headers={'apns-priority': '10'}
)
```

#### Solution 2: Check TTL Settings

```python
# Set appropriate TTL (time to live)
android_config = messaging.AndroidConfig(
    ttl=3600  # 1 hour
)
```

---

## In-App Notification Issues

### Issue 1: Notifications Not Appearing

**Symptoms:**
- In-app notifications not showing
- Notification count not updating

**Solutions:**

#### Solution 1: Implement Polling

```javascript
// Frontend: Poll for new notifications
setInterval(async () => {
    const response = await fetch('/api/notifications?unread_only=true');
    const notifications = await response.json();
    updateNotificationBadge(notifications.length);
}, 30000); // Every 30 seconds
```

#### Solution 2: Use WebSocket

```python
# Backend: WebSocket for real-time notifications
from fastapi import WebSocket

@app.websocket("/ws/notifications/{user_id}")
async def websocket_notifications(websocket: WebSocket, user_id: str):
    await websocket.accept()

    while True:
        # Send new notifications
        notifications = get_unread_notifications(user_id)
        await websocket.send_json(notifications)
        await asyncio.sleep(5)
```

---

## General Delivery Problems

### Issue 1: Rate Limiting

**Symptoms:**
- Notifications failing after certain count
- "Rate limit exceeded" errors

**Solutions:**

#### Solution 1: Implement Backoff

```python
import time

def send_with_backoff(notification, max_retries=3):
    """Send notification with exponential backoff."""
    for attempt in range(max_retries):
        try:
            return notification_service.send(notification)
        except RateLimitError:
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt
                time.sleep(wait_time)
            else:
                raise
```

#### Solution 2: Queue Management

```python
from celery import Celery

# Configure rate limits
celery_app.conf.task_routes = {
    'send_email': {'rate_limit': '100/m'},  # 100 per minute
    'send_sms': {'rate_limit': '10/m'},     # 10 per minute
}
```

### Issue 2: Duplicate Notifications

**Symptoms:**
- Users receiving same notification multiple times

**Solutions:**

#### Solution 1: Idempotency Keys

```python
def send_notification_idempotent(notification_data, idempotency_key):
    """Send notification with idempotency check."""

    # Check if already sent
    existing = get_notification_by_idempotency_key(idempotency_key)
    if existing:
        return existing

    # Send notification
    notification = notification_service.send(**notification_data)
    notification.idempotency_key = idempotency_key

    return notification
```

#### Solution 2: Deduplication

```python
from datetime import timedelta

def deduplicate_notifications(user_id, template_name, window_minutes=5):
    """Check for duplicate notifications."""

    cutoff = datetime.utcnow() - timedelta(minutes=window_minutes)

    recent = session.exec(
        select(Notification)
        .where(Notification.user_id == user_id)
        .where(Notification.template_name == template_name)
        .where(Notification.created_at >= cutoff)
    ).first()

    return recent is not None
```

### Issue 3: Notification Fatigue

**Symptoms:**
- Users unsubscribing
- Low engagement rates

**Solutions:**

#### Solution 1: Smart Frequency Control

```python
def should_send_notification(user_id, urgency):
    """Determine if notification should be sent based on frequency."""

    # Get recent notification count
    recent_count = get_recent_notification_count(user_id, hours=24)

    # Urgency-based thresholds
    thresholds = {
        'critical': float('inf'),  # Always send
        'high': 10,
        'normal': 5,
        'low': 2
    }

    return recent_count < thresholds.get(urgency, 5)
```

#### Solution 2: Digest Notifications

```python
def create_digest(user_id, notifications):
    """Combine multiple notifications into digest."""

    digest_data = {
        'user_name': get_user_name(user_id),
        'notification_count': len(notifications),
        'notifications': [
            {
                'title': n.data.get('title'),
                'summary': n.data.get('summary'),
                'url': n.data.get('url')
            }
            for n in notifications
        ]
    }

    return digest_data
```

## Monitoring and Debugging

### Enable Debug Logging

```python
import logging

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('notification_service').setLevel(logging.DEBUG)
```

### Track Delivery Metrics

```python
def track_delivery_metrics():
    """Track notification delivery metrics."""

    metrics = {
        'total_sent': 0,
        'delivered': 0,
        'failed': 0,
        'bounced': 0,
        'opened': 0,
        'clicked': 0
    }

    notifications = get_recent_notifications(hours=24)

    for notification in notifications:
        metrics['total_sent'] += 1

        if notification.status == NotificationStatus.DELIVERED:
            metrics['delivered'] += 1
        elif notification.status == NotificationStatus.FAILED:
            metrics['failed'] += 1
        elif notification.status == NotificationStatus.BOUNCED:
            metrics['bounced'] += 1
        elif notification.status == NotificationStatus.OPENED:
            metrics['opened'] += 1
        elif notification.status == NotificationStatus.CLICKED:
            metrics['clicked'] += 1

    return metrics
```

### Test Notification Delivery

```bash
# Test email delivery
curl -X POST http://localhost:8000/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "channel": "email",
    "template_name": "test",
    "data": {"message": "Test"}
  }'

# Check status
curl http://localhost:8000/notifications/{notification_id}
```

## Best Practices

1. **Always validate input**: Check email/phone format before sending
2. **Implement retry logic**: Handle transient failures gracefully
3. **Monitor delivery rates**: Track success/failure rates
4. **Respect user preferences**: Check opt-outs before sending
5. **Use appropriate channels**: Match urgency to channel
6. **Test thoroughly**: Test with real providers in staging
7. **Log everything**: Keep detailed logs for debugging
8. **Handle errors gracefully**: Don't crash on delivery failures
9. **Implement rate limiting**: Prevent overwhelming users
10. **Monitor costs**: Track SMS usage to control expenses
