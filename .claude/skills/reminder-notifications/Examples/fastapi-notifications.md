# FastAPI Notifications Integration

This example demonstrates a complete FastAPI application with multi-channel notification support.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     FastAPI Application                      │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │   REST API   │────────▶│ Notification │                 │
│  │  Endpoints   │◀────────│   Service    │                 │
│  └──────────────┘         └──────────────┘                 │
│         │                         │                          │
│         │                         │                          │
│         ▼                         ▼                          │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │   Database   │         │   Providers  │                 │
│  │  (SQLModel)  │         │ Email/SMS/   │                 │
│  └──────────────┘         │ Push/In-App  │                 │
│                           └──────────────┘                 │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
project/
├── app/
│   ├── main.py                    # FastAPI app
│   ├── config.py                  # Configuration
│   ├── models.py                  # Database models
│   ├── services/
│   │   ├── notification_service.py
│   │   ├── email_sender.py
│   │   ├── sms_sender.py
│   │   └── push_sender.py
│   └── api/
│       ├── notifications.py       # Notification endpoints
│       └── preferences.py         # Preference endpoints
├── requirements.txt
└── .env
```

## Implementation

### 1. Configuration (config.py)

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "postgresql://user:pass@localhost/db"

    # Email (SendGrid)
    SENDGRID_API_KEY: str
    FROM_EMAIL: str = "noreply@example.com"
    FROM_NAME: str = "My App"

    # SMS (Twilio)
    TWILIO_ACCOUNT_SID: str
    TWILIO_AUTH_TOKEN: str
    TWILIO_PHONE_NUMBER: str

    # Push (Firebase)
    FIREBASE_CREDENTIALS_PATH: str

    # Application
    APP_NAME: str = "My App"
    BASE_URL: str = "https://app.example.com"

    class Config:
        env_file = ".env"

settings = Settings()
```

### 2. FastAPI Application (main.py)

```python
from fastapi import FastAPI, Depends, BackgroundTasks
from sqlmodel import Session, create_engine, SQLModel
from contextlib import asynccontextmanager

from config import settings
from services.notification_service import NotificationService
from services.email_sender import create_email_sender, EmailProvider
from services.sms_sender import create_sms_sender, SMSProvider
from services.push_sender import create_push_sender, PushProvider

# Database
engine = create_engine(settings.DATABASE_URL)

def get_session():
    with Session(engine) as session:
        yield session

# Notification service
email_sender = create_email_sender(
    provider=EmailProvider.SENDGRID,
    from_email=settings.FROM_EMAIL,
    api_key=settings.SENDGRID_API_KEY
)

sms_sender = create_sms_sender(
    provider=SMSProvider.TWILIO,
    from_phone=settings.TWILIO_PHONE_NUMBER,
    account_sid=settings.TWILIO_ACCOUNT_SID,
    auth_token=settings.TWILIO_AUTH_TOKEN
)

push_sender = create_push_sender(
    provider=PushProvider.FIREBASE,
    credentials_path=settings.FIREBASE_CREDENTIALS_PATH
)

notification_service = NotificationService(
    session_factory=lambda: Session(engine),
    email_sender=email_sender,
    sms_sender=sms_sender,
    push_sender=push_sender
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    SQLModel.metadata.create_all(engine)
    yield
    # Shutdown
    pass

app = FastAPI(lifespan=lifespan)

# Store in app state
app.state.notification_service = notification_service

# Include routers
from api import notifications, preferences
app.include_router(notifications.router)
app.include_router(preferences.router)

@app.get("/")
async def root():
    return {"message": "Notification API"}
```

### 3. Notification API (api/notifications.py)

```python
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlmodel import Session
from typing import List, Optional
from datetime import datetime

from models import (
    NotificationCreate,
    NotificationResponse,
    NotificationChannel,
    NotificationStats
)
from main import get_session, notification_service

router = APIRouter(prefix="/notifications", tags=["notifications"])

@router.post("/send", response_model=NotificationResponse)
async def send_notification(
    notification: NotificationCreate,
    background_tasks: BackgroundTasks,
    session: Session = Depends(get_session)
):
    """Send notification via specified channel."""
    try:
        # Send in background
        result = notification_service.send(
            user_id=notification.user_id,
            channel=notification.channel,
            template_name=notification.template_name,
            data=notification.data,
            priority=notification.priority,
            scheduled_for=notification.scheduled_for
        )

        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/send-multi-channel")
async def send_multi_channel(
    user_id: str,
    channels: List[NotificationChannel],
    template_name: str,
    data: dict,
    fallback: bool = True
):
    """Send notification via multiple channels."""
    try:
        notifications = notification_service.send_multi_channel(
            user_id=user_id,
            channels=channels,
            template_name=template_name,
            data=data,
            fallback=fallback
        )

        return {
            "sent": len(notifications),
            "notifications": notifications
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/send-batch")
async def send_batch(
    user_ids: List[str],
    channel: NotificationChannel,
    template_name: str,
    data: dict
):
    """Send notification to multiple users."""
    try:
        notifications = notification_service.send_batch(
            user_ids=user_ids,
            channel=channel,
            template_name=template_name,
            data=data
        )

        return {
            "sent": len(notifications),
            "notifications": notifications
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{notification_id}", response_model=NotificationResponse)
async def get_notification(
    notification_id: int,
    session: Session = Depends(get_session)
):
    """Get notification by ID."""
    try:
        status = notification_service.get_notification_status(notification_id)
        return status
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/user/{user_id}", response_model=List[NotificationResponse])
async def get_user_notifications(
    user_id: str,
    channel: Optional[NotificationChannel] = None,
    unread_only: bool = False,
    limit: int = 50
):
    """Get user's notifications."""
    notifications = notification_service.get_user_notifications(
        user_id=user_id,
        channel=channel,
        unread_only=unread_only,
        limit=limit
    )
    return notifications

@router.post("/{notification_id}/mark-read")
async def mark_as_read(notification_id: int):
    """Mark notification as read."""
    success = notification_service.mark_as_read(notification_id)
    if not success:
        raise HTTPException(status_code=404, detail="Notification not found")
    return {"status": "success"}

@router.post("/user/{user_id}/mark-all-read")
async def mark_all_as_read(user_id: str):
    """Mark all user notifications as read."""
    count = notification_service.mark_all_as_read(user_id)
    return {"marked_read": count}

@router.delete("/{notification_id}")
async def delete_notification(notification_id: int):
    """Delete notification."""
    success = notification_service.delete_notification(notification_id)
    if not success:
        raise HTTPException(status_code=404, detail="Notification not found")
    return {"status": "deleted"}

@router.post("/{notification_id}/retry")
async def retry_notification(notification_id: int):
    """Retry failed notification."""
    try:
        success = notification_service.retry_failed(notification_id)
        return {"status": "success" if success else "failed"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/stats/{user_id}", response_model=NotificationStats)
async def get_stats(
    user_id: str,
    channel: Optional[NotificationChannel] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    session: Session = Depends(get_session)
):
    """Get notification statistics."""
    from models import get_notification_stats

    stats = get_notification_stats(
        session=session,
        user_id=user_id,
        channel=channel,
        start_date=start_date,
        end_date=end_date
    )
    return stats
```

### 4. Preference API (api/preferences.py)

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from models import NotificationPreference, NotificationPreferenceUpdate, NotificationChannel
from main import get_session, notification_service

router = APIRouter(prefix="/preferences", tags=["preferences"])

@router.get("/{user_id}", response_model=NotificationPreference)
async def get_preferences(user_id: str):
    """Get user notification preferences."""
    preferences = notification_service.preference_manager.get_preferences(user_id)
    return preferences

@router.put("/{user_id}", response_model=NotificationPreference)
async def update_preferences(
    user_id: str,
    updates: NotificationPreferenceUpdate
):
    """Update user notification preferences."""
    preferences = notification_service.preference_manager.update_preferences(
        user_id,
        **updates.dict(exclude_unset=True)
    )
    return preferences

@router.post("/{user_id}/channels/{channel}/enable")
async def enable_channel(user_id: str, channel: NotificationChannel):
    """Enable notification channel."""
    success = notification_service.preference_manager.enable_channel(user_id, channel)
    return {"status": "enabled" if success else "failed"}

@router.post("/{user_id}/channels/{channel}/disable")
async def disable_channel(user_id: str, channel: NotificationChannel):
    """Disable notification channel."""
    success = notification_service.preference_manager.disable_channel(user_id, channel)
    return {"status": "disabled" if success else "failed"}

@router.post("/{user_id}/categories/{category}/enable")
async def enable_category(user_id: str, category: str):
    """Enable notification category."""
    success = notification_service.preference_manager.enable_category(user_id, category)
    return {"status": "enabled" if success else "failed"}

@router.post("/{user_id}/categories/{category}/disable")
async def disable_category(user_id: str, category: str):
    """Disable notification category."""
    success = notification_service.preference_manager.disable_category(user_id, category)
    return {"status": "disabled" if success else "failed"}

@router.post("/{user_id}/quiet-hours")
async def set_quiet_hours(
    user_id: str,
    enabled: bool,
    start: str = "22:00",
    end: str = "08:00",
    timezone: str = "UTC"
):
    """Set quiet hours."""
    preferences = notification_service.preference_manager.set_quiet_hours(
        user_id=user_id,
        enabled=enabled,
        start=start,
        end=end,
        timezone=timezone
    )
    return preferences

@router.post("/{user_id}/unsubscribe")
async def unsubscribe_all(user_id: str):
    """Unsubscribe from all notifications."""
    preferences = notification_service.preference_manager.unsubscribe_all(user_id)
    return {"status": "unsubscribed"}
```

## Running the Example

### 1. Install Dependencies

```bash
pip install fastapi uvicorn sqlmodel sendgrid twilio firebase-admin jinja2 pytz
```

### 2. Configure Environment

Create `.env` file:

```env
DATABASE_URL=postgresql://user:pass@localhost/db
SENDGRID_API_KEY=your_sendgrid_api_key
FROM_EMAIL=noreply@example.com
FROM_NAME=My App
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
TWILIO_PHONE_NUMBER=+1234567890
FIREBASE_CREDENTIALS_PATH=/path/to/firebase-credentials.json
APP_NAME=My App
BASE_URL=https://app.example.com
```

### 3. Run the Application

```bash
uvicorn main:app --reload
```

### 4. Test the API

```bash
# Send email notification
curl -X POST http://localhost:8000/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_123",
    "channel": "email",
    "template_name": "task_reminder",
    "data": {
      "user_name": "John Doe",
      "task_title": "Complete project",
      "due_date": "2024-01-10",
      "task_url": "https://app.example.com/tasks/123"
    },
    "priority": "normal"
  }'

# Send multi-channel notification
curl -X POST http://localhost:8000/notifications/send-multi-channel \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_123",
    "channels": ["push", "email"],
    "template_name": "task_reminder",
    "data": {
      "task_title": "Complete project",
      "due_date": "2024-01-10"
    },
    "fallback": true
  }'

# Get user notifications
curl http://localhost:8000/notifications/user/user_123

# Get user preferences
curl http://localhost:8000/preferences/user_123

# Update preferences
curl -X PUT http://localhost:8000/preferences/user_123 \
  -H "Content-Type: application/json" \
  -d '{
    "email_enabled": true,
    "sms_enabled": false,
    "quiet_hours_enabled": true,
    "quiet_hours_start": "22:00",
    "quiet_hours_end": "08:00"
  }'

# Disable channel
curl -X POST http://localhost:8000/preferences/user_123/channels/sms/disable

# Get statistics
curl http://localhost:8000/notifications/stats/user_123
```

## Key Features

1. **Multi-Channel Support**: Email, SMS, Push, In-App
2. **Template Management**: Reusable templates with Jinja2
3. **User Preferences**: Channel, category, and quiet hours
4. **Background Processing**: Async notification sending
5. **Delivery Tracking**: Status tracking and statistics
6. **Rate Limiting**: Prevent spam
7. **Retry Logic**: Automatic retry for failed notifications
8. **Batch Sending**: Send to multiple users
9. **Multi-Channel Fallback**: Try multiple channels in order

## Next Steps

1. Add Celery for background task processing
2. Implement webhook handlers for delivery tracking
3. Add notification scheduling
4. Implement digest notifications
5. Add A/B testing for templates
6. Implement notification analytics dashboard
7. Add support for more providers
8. Implement notification campaigns
