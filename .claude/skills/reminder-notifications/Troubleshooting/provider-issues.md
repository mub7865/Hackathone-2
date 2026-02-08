# Troubleshooting Provider-Specific Issues

This guide covers common issues specific to notification providers.

## Table of Contents

1. [SendGrid Issues](#sendgrid-issues)
2. [Twilio Issues](#twilio-issues)
3. [Firebase Issues](#firebase-issues)
4. [AWS SES/SNS Issues](#aws-sesssns-issues)
5. [Mailgun Issues](#mailgun-issues)
6. [OneSignal Issues](#onesignal-issues)

---

## SendGrid Issues

### Issue 1: API Key Authentication Failed

**Error:** `401 Unauthorized` or `403 Forbidden`

**Diagnosis:**

```python
from sendgrid import SendGridAPIClient

def test_sendgrid_auth(api_key):
    """Test SendGrid API key."""
    try:
        sg = SendGridAPIClient(api_key)
        # Test with a simple API call
        response = sg.client.api_keys.get()
        return response.status_code == 200
    except Exception as e:
        print(f"Auth failed: {e}")
        return False
```

**Solutions:**

1. **Verify API Key:**
   - Check API key is correct
   - Ensure no extra spaces
   - Verify key has correct permissions

2. **Check API Key Permissions:**
   ```
   Required permissions:
   - Mail Send: Full Access
   - Stats: Read Access (optional)
   ```

3. **Regenerate API Key:**
   - Go to SendGrid dashboard
   - Settings → API Keys
   - Create new key with correct permissions

### Issue 2: Email Rejected by SendGrid

**Error:** `400 Bad Request` with error message

**Common Error Codes:**

| Code | Message | Solution |
|------|---------|----------|
| 400 | Invalid email address | Validate email format |
| 413 | Payload too large | Reduce email size/attachments |
| 429 | Too many requests | Implement rate limiting |
| 451 | Unsubscribed address | Remove from list |

**Solutions:**

```python
def handle_sendgrid_error(error):
    """Handle SendGrid-specific errors."""
    if hasattr(error, 'status_code'):
        if error.status_code == 400:
            # Validation error
            print(f"Validation error: {error.body}")
        elif error.status_code == 429:
            # Rate limit
            print("Rate limit exceeded, retry later")
        elif error.status_code == 451:
            # Unsubscribed
            print("Email unsubscribed")
```

### Issue 3: SendGrid Webhook Not Working

**Symptoms:**
- Not receiving delivery/bounce notifications
- Webhook endpoint not being called

**Solutions:**

1. **Verify Webhook URL:**
   ```python
   # Webhook endpoint
   @app.post("/webhooks/sendgrid")
   async def sendgrid_webhook(request: Request):
       """Handle SendGrid webhook events."""
       data = await request.json()

       for event in data:
           event_type = event.get('event')
           email = event.get('email')

           if event_type == 'delivered':
               mark_as_delivered(email)
           elif event_type == 'bounce':
               handle_bounce(email)

       return {"status": "ok"}
   ```

2. **Configure Webhook in SendGrid:**
   - Settings → Mail Settings → Event Webhook
   - Enable webhook
   - Add your endpoint URL
   - Select events to track

3. **Verify Webhook Signature:**
   ```python
   import hmac
   import hashlib
   import base64

   def verify_sendgrid_signature(payload, signature, public_key):
       """Verify SendGrid webhook signature."""
       expected = base64.b64encode(
           hmac.new(
               public_key.encode(),
               payload.encode(),
               hashlib.sha256
           ).digest()
       ).decode()

       return hmac.compare_digest(expected, signature)
   ```

---

## Twilio Issues

### Issue 1: Invalid Phone Number

**Error:** `21211: Invalid 'To' Phone Number`

**Solutions:**

```python
def validate_twilio_phone(phone):
    """Validate phone number for Twilio."""
    import re

    # Must be E.164 format: +[country code][number]
    pattern = r'^\+[1-9]\d{1,14}$'

    if not re.match(pattern, phone):
        return False, "Invalid E.164 format"

    # Check country code
    if phone.startswith('+0'):
        return False, "Country code cannot start with 0"

    return True, "Valid"

# Format phone number
def format_for_twilio(phone, default_country='+1'):
    """Format phone number for Twilio."""
    # Remove all non-digits
    digits = ''.join(filter(str.isdigit, phone))

    # Add country code if missing
    if not phone.startswith('+'):
        return f"{default_country}{digits}"

    return f"+{digits}"
```

### Issue 2: Account Suspended or Restricted

**Error:** `20003: Authentication Error` or `20404: Account not found`

**Solutions:**

1. **Check Account Status:**
   - Log into Twilio console
   - Check for suspension notices
   - Verify account is active

2. **Verify Credentials:**
   ```python
   from twilio.rest import Client

   def test_twilio_auth(account_sid, auth_token):
       """Test Twilio authentication."""
       try:
           client = Client(account_sid, auth_token)
           # Test with account fetch
           account = client.api.accounts(account_sid).fetch()
           return account.status == 'active'
       except Exception as e:
           print(f"Auth failed: {e}")
           return False
   ```

3. **Check Trial Account Limitations:**
   - Trial accounts can only send to verified numbers
   - Upgrade to paid account for production use

### Issue 3: Message Delivery Failed

**Error:** `30003: Unreachable destination handset`

**Common Error Codes:**

| Code | Meaning | Solution |
|------|---------|----------|
| 30003 | Unreachable | Phone off or no signal |
| 30004 | Message blocked | Carrier filtering |
| 30005 | Unknown destination | Invalid number |
| 30006 | Landline/unreachable | Cannot receive SMS |
| 30007 | Carrier violation | Content filtered |

**Solutions:**

```python
def handle_twilio_error(error_code, message):
    """Handle Twilio delivery errors."""
    if error_code == 30003:
        # Retry later
        schedule_retry(message, delay=3600)  # 1 hour
    elif error_code == 30004:
        # Content blocked
        log_blocked_message(message)
    elif error_code in [30005, 30006]:
        # Invalid number
        mark_number_invalid(message.to_phone)
    elif error_code == 30007:
        # Carrier violation
        review_message_content(message)
```

### Issue 4: High Costs

**Symptoms:**
- Unexpected high bills
- Messages sent to premium numbers

**Solutions:**

1. **Block Premium Numbers:**
   ```python
   PREMIUM_PREFIXES = [
       '+1900',  # US premium
       '+1976',  # US premium
       # Add more based on your region
   ]

   def is_premium_number(phone):
       """Check if phone is premium number."""
       return any(phone.startswith(prefix) for prefix in PREMIUM_PREFIXES)
   ```

2. **Set Spending Limits:**
   - Twilio Console → Account → Notifications
   - Set daily/monthly spending limits
   - Configure alerts

3. **Monitor Usage:**
   ```python
   def get_twilio_usage(account_sid, auth_token):
       """Get Twilio usage statistics."""
       client = Client(account_sid, auth_token)

       # Get today's usage
       usage = client.usage.records.today.list()

       total_cost = sum(float(record.price) for record in usage)
       return total_cost
   ```

---

## Firebase Issues

### Issue 1: Invalid Registration Token

**Error:** `messaging/invalid-registration-token`

**Solutions:**

```python
def handle_invalid_token(user_id, device_token):
    """Handle invalid Firebase token."""
    # Remove invalid token from database
    with session_factory() as session:
        user = session.get(User, user_id)
        if user and user.push_token == device_token:
            user.push_token = None
            session.commit()
            logger.info(f"Removed invalid token for user {user_id}")
```

### Issue 2: Authentication Error

**Error:** `messaging/authentication-error`

**Solutions:**

1. **Verify Service Account:**
   ```python
   import firebase_admin
   from firebase_admin import credentials

   def initialize_firebase(credentials_path):
       """Initialize Firebase with service account."""
       try:
           cred = credentials.Certificate(credentials_path)
           firebase_admin.initialize_app(cred)
           return True
       except Exception as e:
           print(f"Firebase init failed: {e}")
           return False
   ```

2. **Check Credentials File:**
   - Verify JSON file is valid
   - Check file permissions
   - Ensure correct project

3. **Verify Project ID:**
   ```python
   def verify_firebase_project():
       """Verify Firebase project configuration."""
       import firebase_admin

       app = firebase_admin.get_app()
       project_id = app.project_id
       print(f"Connected to project: {project_id}")
       return project_id
   ```

### Issue 3: Quota Exceeded

**Error:** `messaging/quota-exceeded`

**Solutions:**

1. **Check Quotas:**
   - Firebase Console → Usage
   - Check message quota
   - Upgrade plan if needed

2. **Implement Rate Limiting:**
   ```python
   from datetime import datetime, timedelta

   class FirebaseRateLimiter:
       def __init__(self, max_per_minute=1000):
           self.max_per_minute = max_per_minute
           self.sent_count = {}

       def can_send(self):
           """Check if can send message."""
           now = datetime.now()
           minute_key = now.strftime('%Y-%m-%d-%H-%M')

           if minute_key not in self.sent_count:
               self.sent_count = {minute_key: 0}

           return self.sent_count[minute_key] < self.max_per_minute
   ```

### Issue 4: Message Too Large

**Error:** `messaging/invalid-payload`

**Solutions:**

```python
def validate_fcm_payload(notification):
    """Validate FCM payload size."""
    import json

    payload = {
        'notification': {
            'title': notification.title,
            'body': notification.body
        },
        'data': notification.data
    }

    payload_size = len(json.dumps(payload).encode('utf-8'))

    # FCM limit is 4KB
    if payload_size > 4096:
        raise ValueError(f"Payload too large: {payload_size} bytes")

    return True
```

---

## AWS SES/SNS Issues

### Issue 1: Email in Sandbox Mode

**Error:** `MessageRejected: Email address is not verified`

**Solutions:**

1. **Verify Email Addresses:**
   ```bash
   aws ses verify-email-identity --email-address user@example.com
   ```

2. **Request Production Access:**
   - AWS Console → SES → Account Dashboard
   - Request production access
   - Provide use case details

3. **Check Sandbox Status:**
   ```python
   import boto3

   def check_ses_sandbox():
       """Check if SES is in sandbox mode."""
       ses = boto3.client('ses', region_name='us-east-1')

       try:
           # Try to get sending quota
           quota = ses.get_send_quota()

           # If max_24_hour_send is 200, likely in sandbox
           if quota['Max24HourSend'] == 200:
               print("Account is in sandbox mode")
               return True

           return False
       except Exception as e:
           print(f"Error checking sandbox: {e}")
           return None
   ```

### Issue 2: Sending Quota Exceeded

**Error:** `Throttling: Maximum sending rate exceeded`

**Solutions:**

1. **Check Current Quota:**
   ```python
   def get_ses_quota():
       """Get SES sending quota."""
       ses = boto3.client('ses')
       quota = ses.get_send_quota()

       return {
           'max_24_hour': quota['Max24HourSend'],
           'max_per_second': quota['MaxSendRate'],
           'sent_last_24_hours': quota['SentLast24Hours']
       }
   ```

2. **Request Quota Increase:**
   - AWS Console → SES → Sending Statistics
   - Request sending limit increase
   - Provide justification

3. **Implement Throttling:**
   ```python
   import time

   def send_with_throttling(emails, max_per_second=14):
       """Send emails with rate limiting."""
       delay = 1.0 / max_per_second

       for email in emails:
           ses_client.send_email(**email)
           time.sleep(delay)
   ```

### Issue 3: SNS SMS Not Delivered

**Error:** No error, but SMS not received

**Solutions:**

1. **Check SMS Preferences:**
   ```python
   def check_sns_sms_preferences():
       """Check SNS SMS preferences."""
       sns = boto3.client('sns')

       attributes = sns.get_sms_attributes()

       print("SMS Type:", attributes.get('DefaultSMSType'))
       print("Sender ID:", attributes.get('DefaultSenderID'))

       return attributes
   ```

2. **Set SMS Attributes:**
   ```python
   def configure_sns_sms():
       """Configure SNS SMS settings."""
       sns = boto3.client('sns')

       sns.set_sms_attributes(
           attributes={
               'DefaultSMSType': 'Transactional',  # or 'Promotional'
               'DefaultSenderID': 'YourApp'
           }
       )
   ```

3. **Check Spending Limit:**
   ```python
   def get_sns_spending():
       """Get SNS SMS spending."""
       sns = boto3.client('sns')

       # Get monthly spending
       spending = sns.get_sms_attributes()
       limit = spending.get('MonthlySpendLimit', '1.00')

       print(f"Monthly spend limit: ${limit}")
       return float(limit)
   ```

---

## Mailgun Issues

### Issue 1: Domain Not Verified

**Error:** `Domain not found` or `Forbidden`

**Solutions:**

1. **Verify Domain:**
   ```bash
   # Check DNS records
   dig TXT mg.example.com
   dig MX mg.example.com
   ```

2. **Add DNS Records:**
   ```
   # TXT record for verification
   mg.example.com TXT "v=spf1 include:mailgun.org ~all"

   # MX records
   mg.example.com MX 10 mxa.mailgun.org
   mg.example.com MX 10 mxb.mailgun.org
   ```

3. **Check Domain Status:**
   ```python
   import requests

   def check_mailgun_domain(api_key, domain):
       """Check Mailgun domain status."""
       response = requests.get(
           f"https://api.mailgun.net/v3/domains/{domain}",
           auth=("api", api_key)
       )

       if response.status_code == 200:
           data = response.json()
           print(f"Domain state: {data['domain']['state']}")
           return data

       return None
   ```

### Issue 2: API Key Invalid

**Error:** `401 Unauthorized`

**Solutions:**

```python
def test_mailgun_auth(api_key, domain):
    """Test Mailgun API key."""
    import requests

    response = requests.get(
        f"https://api.mailgun.net/v3/domains/{domain}",
        auth=("api", api_key)
    )

    return response.status_code == 200
```

---

## OneSignal Issues

### Issue 1: Invalid Player ID

**Error:** `Invalid player_id`

**Solutions:**

```python
def validate_onesignal_player_id(player_id):
    """Validate OneSignal player ID format."""
    import re

    # Player IDs are UUIDs
    pattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

    return bool(re.match(pattern, player_id, re.IGNORECASE))
```

### Issue 2: App Not Found

**Error:** `App not found`

**Solutions:**

1. **Verify App ID:**
   ```python
   def verify_onesignal_app(app_id, api_key):
       """Verify OneSignal app exists."""
       import requests

       response = requests.get(
           f"https://onesignal.com/api/v1/apps/{app_id}",
           headers={"Authorization": f"Basic {api_key}"}
       )

       return response.status_code == 200
   ```

2. **Check API Key:**
   - OneSignal Dashboard → Settings → Keys & IDs
   - Verify REST API Key
   - Check App ID

---

## General Provider Debugging

### Enable Debug Logging

```python
import logging

# Enable debug logging for all providers
logging.basicConfig(level=logging.DEBUG)

# Provider-specific logging
logging.getLogger('sendgrid').setLevel(logging.DEBUG)
logging.getLogger('twilio').setLevel(logging.DEBUG)
logging.getLogger('firebase_admin').setLevel(logging.DEBUG)
logging.getLogger('boto3').setLevel(logging.DEBUG)
```

### Test Provider Connectivity

```python
def test_all_providers():
    """Test connectivity to all notification providers."""
    results = {}

    # Test email
    try:
        email_sender.send(test_email_message())
        results['email'] = 'OK'
    except Exception as e:
        results['email'] = str(e)

    # Test SMS
    try:
        sms_sender.send(test_sms_message())
        results['sms'] = 'OK'
    except Exception as e:
        results['sms'] = str(e)

    # Test push
    try:
        push_sender.send(test_push_message())
        results['push'] = 'OK'
    except Exception as e:
        results['push'] = str(e)

    return results
```

### Monitor Provider Status

```python
def check_provider_status():
    """Check status of notification providers."""
    import requests

    status_pages = {
        'sendgrid': 'https://status.sendgrid.com/api/v2/status.json',
        'twilio': 'https://status.twilio.com/api/v2/status.json',
        'aws': 'https://status.aws.amazon.com/',
    }

    for provider, url in status_pages.items():
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                data = response.json()
                print(f"{provider}: {data.get('status', {}).get('description', 'Unknown')}")
        except:
            print(f"{provider}: Unable to check status")
```

## Best Practices

1. **Always test in staging**: Test with real providers before production
2. **Monitor provider status**: Subscribe to status pages
3. **Implement fallbacks**: Have backup providers configured
4. **Keep credentials secure**: Use environment variables
5. **Log all errors**: Track provider-specific errors
6. **Set up alerts**: Get notified of delivery failures
7. **Review provider docs**: Stay updated with API changes
8. **Test error handling**: Simulate provider failures
9. **Monitor costs**: Track usage and spending
10. **Keep SDKs updated**: Use latest provider libraries
