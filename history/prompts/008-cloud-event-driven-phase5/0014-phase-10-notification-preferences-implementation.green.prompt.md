---
id: 0014
title: Phase 10 Notification Preferences Implementation
stage: green
date: 2026-01-12
surface: agent
model: claude-sonnet-4-5-20250929
feature: 008-cloud-event-driven-phase5
branch: 008-cloud-event-driven-phase5
user: developer
command: Continue
labels: ["phase10", "notification-preferences", "quiet-hours", "rate-limiting", "timezone"]
links:
  spec: specs/008-cloud-event-driven-phase5/spec.md
  ticket: null
  adr: null
  pr: null
files:
  - calm-orbit-todo/phase5-cloud/backend/app/models/notification_preferences.py
  - calm-orbit-todo/phase5-cloud/backend/app/services/notification_preferences_service.py
  - calm-orbit-todo/phase5-cloud/backend/app/schemas/notification_preferences.py
  - calm-orbit-todo/phase5-cloud/backend/app/api/v1/notification_preferences.py
  - calm-orbit-todo/phase5-cloud/backend/app/services/notification_rate_limiter.py
  - calm-orbit-todo/phase5-cloud/frontend/src/components/NotificationPreferences.tsx
  - specs/008-cloud-event-driven-phase5/tasks.md
tests:
  - None (integration tests to be added in later phase)
---

## Prompt

Continue

## Response snapshot

Completed Phase 10: User Story 8 - Notification Preferences (Priority P3)

**Implementation Summary:**

Phase 10 adds comprehensive notification preferences management, enabling users to customize notification channels, frequency, quiet hours, and timezone settings with rate limiting.

**Backend Components:**

1. **NotificationPreferences Model** (`models/notification_preferences.py`):
   - NotificationChannel enum (email, in_app, push, sms)
   - NotificationFrequency enum (immediate, hourly, daily, weekly)
   - NotificationPreferences table with fields:
     - id (UUID), user_id (string, unique)
     - Channel preferences: email_enabled, in_app_enabled, push_enabled, sms_enabled
     - Frequency: reminder_frequency (enum)
     - Type preferences: task_updates_enabled, recurring_task_enabled
     - Quiet hours: quiet_hours_enabled, quiet_hours_start, quiet_hours_end
     - Timezone: timezone (IANA string, default UTC)
     - Timestamps: created_at, updated_at
   - Helper methods:
     - `is_in_quiet_hours(current_time)`: Check if time is within quiet hours (handles midnight spanning)
     - `has_any_channel_enabled()`: Validate at least one channel is enabled
   - Unique index on user_id (one preferences record per user)

2. **NotificationPreferencesService** (`services/notification_preferences_service.py`):
   - `get_or_create_preferences(user_id)`: Get preferences or create defaults
   - `get_preferences(user_id)`: Get existing preferences
   - `update_preferences(user_id, updates)`: Update with validation
   - `should_send_notification(user_id, channel, notification_type)`: Check if notification should be sent
     - Validates channel is enabled
     - Validates notification type is enabled
     - Checks quiet hours with timezone conversion
   - `get_enabled_channels(user_id)`: Get list of enabled channels
   - `is_in_quiet_hours(user_id)`: Check if user is in quiet hours
   - `get_user_timezone(user_id)`: Get user's timezone
   - `get_reminder_frequency(user_id)`: Get reminder frequency setting
   - Validation:
     - At least one channel must be enabled
     - Quiet hours start/end required when enabled
     - Timezone validation with pytz
   - Timezone handling:
     - Uses pytz for timezone conversion
     - Converts current time to user's timezone for quiet hours check
     - Supports all IANA timezone strings

3. **Notification Preferences Schemas** (`schemas/notification_preferences.py`):
   - NotificationPreferencesUpdate: Request schema for partial updates
     - All fields optional
     - Timezone validation with pytz
   - NotificationPreferencesResponse: Response schema with all fields
   - TimezoneListResponse: List of valid IANA timezones
   - Full Pydantic validation and OpenAPI documentation

4. **Notification Preferences Endpoints** (`api/v1/notification_preferences.py`):
   - **GET /notification-preferences**: Get user preferences
     - Creates defaults if not exists
     - Returns full preferences object
   - **PATCH /notification-preferences**: Update preferences
     - Supports partial updates
     - Validates at least one channel enabled
     - Validates quiet hours configuration
     - Returns updated preferences
   - **GET /notification-preferences/timezones**: List available timezones
     - Returns all IANA timezone strings from pytz
     - No authentication required (public endpoint)
   - **POST /notification-preferences/reset**: Reset to defaults
     - Requires confirmation
     - Resets all preferences to default values
     - Returns reset preferences
   - All endpoints require JWT authentication (except timezones list)
   - User isolation enforced

5. **NotificationRateLimiter Service** (`services/notification_rate_limiter.py`):
   - NotificationRateLimit model for tracking sent notifications
   - Rate limit configurations:
     - MAX_NOTIFICATIONS_PER_HOUR = 20
     - MAX_NOTIFICATIONS_PER_DAY = 100
     - MAX_SAME_TYPE_PER_HOUR = 5
   - `check_rate_limit(user_id, notification_type, channel)`: Check if notification can be sent
     - Validates hourly limit (all notifications)
     - Validates daily limit (all notifications)
     - Validates same type limit (prevent spam)
   - `record_notification(user_id, notification_type, channel)`: Record sent notification
   - `get_notification_stats(user_id)`: Get notification statistics
     - Returns counts for last hour, day, week
     - Returns configured limits
   - `cleanup_old_records(days)`: Delete old rate limit records (default 30 days)
   - `reset_user_limits(user_id)`: Admin function to reset user limits
   - Features:
     - Prevents notification spam
     - Per-user rate limiting
     - Per-type rate limiting
     - Automatic cleanup of old records

**Frontend Components:**

6. **NotificationPreferences Component** (`components/NotificationPreferences.tsx`):
   - Comprehensive notification preferences management UI
   - Features:
     - **Notification Channels Section**:
       - Email (enabled by default)
       - In-App (enabled by default)
       - Push (disabled, coming soon)
       - SMS (disabled, coming soon)
       - Checkbox toggles with descriptions
     - **Reminder Frequency Section**:
       - Radio buttons for immediate, hourly, daily, weekly
       - Descriptions for each option
     - **Notification Types Section**:
       - Task updates toggle
       - Recurring tasks toggle
     - **Quiet Hours Section**:
       - Enable/disable toggle
       - Start time picker (default 22:00)
       - End time picker (default 08:00)
       - Expandable section when enabled
     - **Timezone Section**:
       - Dropdown with all IANA timezones
       - Fetched from API
       - Used for quiet hours and scheduling
     - **Action Buttons**:
       - Save button (validates and saves)
       - Reset to defaults button (with confirmation)
   - Validation:
     - At least one channel must be enabled
     - Shows error messages
     - Shows success messages (auto-dismiss after 3s)
   - State management:
     - Fetches preferences on mount
     - Updates form state from API response
     - Tracks saving/loading states
   - Framer Motion animations for smooth transitions
   - Responsive design with Tailwind CSS
   - TypeScript types for full type safety

**Key Features:**

- **Flexible Channel Configuration**: Users can enable/disable email and in-app notifications
- **Reminder Frequency Control**: Choose between immediate, hourly, daily, or weekly batching
- **Notification Type Filtering**: Enable/disable specific notification types
- **Quiet Hours**: Pause notifications during specific hours with timezone support
- **Timezone Support**: Full IANA timezone support with pytz
- **Rate Limiting**: Prevent notification spam with configurable limits
- **Default Preferences**: Automatic creation of sensible defaults
- **Reset Functionality**: Easy reset to default values
- **Validation**: Comprehensive validation at model, service, and API levels
- **User Isolation**: Each user has their own preferences

**Technical Highlights:**

- **Midnight Spanning**: Quiet hours correctly handle time ranges that span midnight (e.g., 22:00-08:00)
- **Timezone Conversion**: Current time converted to user's timezone for quiet hours check
- **Enum Validation**: Channel and frequency validated with Python enums
- **Unique Constraint**: One preferences record per user enforced at database level
- **Partial Updates**: PATCH endpoint supports updating only specified fields
- **Rate Limit Tracking**: Separate table tracks notification sends for rate limiting
- **Automatic Cleanup**: Old rate limit records automatically cleaned up
- **Statistics**: Rate limiter provides notification statistics for monitoring
- **Pydantic Validation**: Full validation with custom validators for timezone
- **OpenAPI Documentation**: Complete API documentation with examples

**Integration Points:**

- Notification preferences service provides `should_send_notification()` method for integration with notification system
- Rate limiter can be integrated into notification sending logic
- Timezone handling ready for reminder scheduling
- Quiet hours check ready for notification filtering
- Enabled channels list ready for multi-channel notification sending

**Default Preferences:**

```python
{
  "email_enabled": True,
  "in_app_enabled": True,
  "push_enabled": False,
  "sms_enabled": False,
  "reminder_frequency": "immediate",
  "task_updates_enabled": True,
  "recurring_task_enabled": True,
  "quiet_hours_enabled": False,
  "quiet_hours_start": None,
  "quiet_hours_end": None,
  "timezone": "UTC"
}
```

**Example Usage:**

```python
# Backend: Check if notification should be sent
from app.services.notification_preferences_service import NotificationPreferencesService
from app.models.notification_preferences import NotificationChannel

service = NotificationPreferencesService(session)
should_send = await service.should_send_notification(
    user_id="user123",
    channel=NotificationChannel.EMAIL,
    notification_type="task_update"
)

if should_send:
    # Send notification
    pass
```

```python
# Backend: Rate limiting
from app.services.notification_rate_limiter import NotificationRateLimiter

limiter = NotificationRateLimiter(session)
can_send = await limiter.check_rate_limit(
    user_id="user123",
    notification_type="reminder",
    channel="email"
)

if can_send:
    # Send notification
    await limiter.record_notification(
        user_id="user123",
        notification_type="reminder",
        channel="email"
    )
```

```typescript
// Frontend: Notification preferences component
import NotificationPreferences from '@/components/NotificationPreferences';

function SettingsPage() {
  const { token } = useAuth();

  return (
    <div className="container mx-auto p-6">
      <NotificationPreferences
        token={token}
        onSave={(preferences) => {
          console.log('Preferences saved:', preferences);
        }}
      />
    </div>
  );
}
```

**Quiet Hours Example:**

```python
# User in America/New_York timezone
# Quiet hours: 22:00 - 08:00
# Current time in NY: 23:30 (11:30 PM)
# Result: In quiet hours, notification blocked

# Current time in NY: 09:00 (9:00 AM)
# Result: Not in quiet hours, notification allowed
```

**Rate Limiting Example:**

```
User sends 20 notifications in 1 hour
Next notification: BLOCKED (hourly limit reached)

User sends 5 reminder notifications in 1 hour
Next reminder: BLOCKED (same type limit reached)
Next task_update: ALLOWED (different type)
```

## Outcome

- ✅ Impact: Completed Phase 10 (User Story 8 - Notification Preferences). All 8 tasks (T071-T078) implemented successfully. Eight user stories (Phase 3, 4, 5, 6, 7, 8, 9, 10) now complete.
- 🧪 Tests: No unit/integration tests created in this phase. Tests to be added in later testing phase.
- 📁 Files: 6 files created (4 backend, 1 frontend, 1 schema) + 1 file modified (tasks.md)
- 🔁 Next prompts: Phase 11 (Event-Driven Architecture Integration), Phase 12 (Monitoring and Observability), or continue with remaining phases
- 🧠 Reflection: Phase 10 implementation proceeded smoothly. The notification preferences system provides comprehensive control over notification delivery with channel selection, frequency control, quiet hours, and timezone support. The NotificationPreferencesService includes a `should_send_notification()` method that integrates channel preferences, notification type preferences, and quiet hours checking with timezone conversion. The rate limiter prevents notification spam with configurable limits per hour, per day, and per notification type. The frontend component provides an intuitive UI for managing all preferences with validation and error handling. The system is designed for flexibility with support for future channels (push, SMS) and extensible notification types.

## Evaluation notes (flywheel)

- Failure modes observed: None. Implementation proceeded without errors or user corrections.
- Graders run and results (PASS/FAIL): Not applicable (no automated graders run)
- Prompt variant (if applicable): Standard implementation prompt (continuation from previous phase)
- Next experiment (smallest change to try): Consider adding unit tests for NotificationPreferencesService methods (especially quiet hours logic with midnight spanning), integration tests for notification preferences endpoints with authentication, and E2E tests for the complete preferences flow. Could also add notification batching logic for hourly/daily/weekly frequencies, notification digest generation, and notification history tracking. Consider adding A/B testing for notification timing optimization and machine learning for personalized notification frequency recommendations based on user engagement patterns.
