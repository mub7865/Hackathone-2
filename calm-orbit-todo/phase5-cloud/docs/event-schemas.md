# Event Schemas: Cloud-Native Event-Driven Todo Application

**Version**: 1.0
**Last Updated**: 2026-01-12
**Event Format**: JSON

---

## Table of Contents

1. [Overview](#overview)
2. [Event Structure](#event-structure)
3. [Task Events](#task-events)
4. [Reminder Events](#reminder-events)
5. [Recurring Task Events](#recurring-task-events)
6. [Task Update Events](#task-update-events)
7. [Event Validation](#event-validation)
8. [Event Processing](#event-processing)
9. [Idempotency](#idempotency)

---

## Overview

The Todo Application uses event-driven architecture with Kafka/Redpanda for asynchronous communication between services. All events follow a consistent schema and are published to specific topics based on their type.

### Event Topics

| Topic | Purpose | Partitions | Retention |
|-------|---------|------------|-----------|
| `todo-app.task-events` | Task lifecycle events | 3 | 7 days |
| `todo-app.reminders` | Reminder notifications | 3 | 7 days |
| `todo-app.recurring-tasks` | Recurring task generation | 3 | 7 days |
| `todo-app.task-updates` | Real-time task updates | 3 | 7 days |

### Event Flow

```
API Endpoint → Database Write → Event Producer → Kafka Topic → Event Consumer → Side Effects
                                                                                    ↓
                                                                            - Notifications
                                                                            - WebSocket Broadcast
                                                                            - Analytics
                                                                            - Audit Logging
```

---

## Event Structure

All events follow a consistent base structure:

```json
{
  "event_type": "string",
  "event_id": "uuid",
  "timestamp": "ISO8601",
  "data": {
    // Event-specific data
  }
}
```

### Base Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `event_type` | string | Yes | Event type identifier (e.g., "task.created") |
| `event_id` | UUID | Yes | Unique event identifier for idempotency |
| `timestamp` | ISO8601 | Yes | Event creation timestamp in UTC |
| `data` | object | Yes | Event-specific payload |

### Event Type Naming Convention

Events follow the pattern: `<resource>.<action>`

Examples:
- `task.created`
- `task.updated`
- `task.deleted`
- `task.completed`
- `reminder.due`
- `recurring.pattern.created`
- `recurring.task.generated`

---

## Task Events

### task.created

Published when a new task is created.

**Topic**: `todo-app.task-events`

**Schema**:
```json
{
  "event_type": "task.created",
  "event_id": "123e4567-e89b-12d3-a456-426614174000",
  "timestamp": "2026-01-12T10:00:00.000Z",
  "data": {
    "task_id": "456e7890-e89b-12d3-a456-426614174001",
    "user_id": "user123",
    "title": "Complete project documentation",
    "description": "Write comprehensive API documentation",
    "status": "pending",
    "priority": "high",
    "tags": ["documentation", "urgent"],
    "due_date": "2026-01-15T17:00:00.000Z",
    "remind_at": "2026-01-15T09:00:00.000Z",
    "recurring_pattern_id": null,
    "created_at": "2026-01-12T10:00:00.000Z"
  }
}
```

**Data Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `task_id` | UUID | Yes | Task identifier |
| `user_id` | string | Yes | User who created the task |
| `title` | string | Yes | Task title |
| `description` | string | No | Task description |
| `status` | enum | Yes | Task status (pending, in_progress, completed) |
| `priority` | enum | No | Task priority (low, medium, high) |
| `tags` | array | No | Task tags |
| `due_date` | ISO8601 | No | Task due date |
| `remind_at` | ISO8601 | No | Reminder time |
| `recurring_pattern_id` | UUID | No | Associated recurring pattern |
| `created_at` | ISO8601 | Yes | Task creation timestamp |

**Consumer Actions**:
- Send welcome notification to user
- Broadcast to WebSocket connections
- Update analytics dashboard
- Log to audit trail

**Example Consumer**:
```python
async def handle_task_created(data: Dict[str, Any]):
    # Send notification
    await notification_service.send(
        user_id=data["user_id"],
        message=f"Task created: {data['title']}",
        channel="in_app"
    )

    # Broadcast to WebSocket
    await websocket_manager.broadcast_to_user(
        user_id=data["user_id"],
        message={
            "type": "task.created",
            "data": data
        }
    )
```

---

### task.updated

Published when a task is updated.

**Topic**: `todo-app.task-events`

**Schema**:
```json
{
  "event_type": "task.updated",
  "event_id": "789e0123-e89b-12d3-a456-426614174002",
  "timestamp": "2026-01-12T11:00:00.000Z",
  "data": {
    "task_id": "456e7890-e89b-12d3-a456-426614174001",
    "user_id": "user123",
    "changes": {
      "status": {
        "before": "pending",
        "after": "in_progress"
      },
      "priority": {
        "before": "high",
        "after": "medium"
      }
    },
    "updated_at": "2026-01-12T11:00:00.000Z"
  }
}
```

**Data Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `task_id` | UUID | Yes | Task identifier |
| `user_id` | string | Yes | User who updated the task |
| `changes` | object | Yes | Field-level changes with before/after values |
| `updated_at` | ISO8601 | Yes | Update timestamp |

**Consumer Actions**:
- Send update notification
- Broadcast to WebSocket
- Update search index
- Log changes to audit trail

---

### task.deleted

Published when a task is deleted.

**Topic**: `todo-app.task-events`

**Schema**:
```json
{
  "event_type": "task.deleted",
  "event_id": "abc12345-e89b-12d3-a456-426614174003",
  "timestamp": "2026-01-12T12:00:00.000Z",
  "data": {
    "task_id": "456e7890-e89b-12d3-a456-426614174001",
    "user_id": "user123",
    "deleted_at": "2026-01-12T12:00:00.000Z"
  }
}
```

**Data Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `task_id` | UUID | Yes | Task identifier |
| `user_id` | string | Yes | User who deleted the task |
| `deleted_at` | ISO8601 | Yes | Deletion timestamp |

**Consumer Actions**:
- Broadcast deletion to WebSocket
- Remove from search index
- Archive in data warehouse
- Log to audit trail

---

### task.completed

Published when a task is marked as completed.

**Topic**: `todo-app.task-events`

**Schema**:
```json
{
  "event_type": "task.completed",
  "event_id": "def45678-e89b-12d3-a456-426614174004",
  "timestamp": "2026-01-12T13:00:00.000Z",
  "data": {
    "task_id": "456e7890-e89b-12d3-a456-426614174001",
    "user_id": "user123",
    "title": "Complete project documentation",
    "completed_at": "2026-01-12T13:00:00.000Z",
    "time_to_complete_hours": 72.5
  }
}
```

**Data Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `task_id` | UUID | Yes | Task identifier |
| `user_id` | string | Yes | User who completed the task |
| `title` | string | Yes | Task title |
| `completed_at` | ISO8601 | Yes | Completion timestamp |
| `time_to_complete_hours` | float | No | Hours from creation to completion |

**Consumer Actions**:
- Send completion notification
- Update user statistics
- Broadcast to WebSocket
- Trigger recurring task generation (if applicable)

---

## Reminder Events

### reminder.scheduled

Published when a reminder is scheduled.

**Topic**: `todo-app.reminders`

**Schema**:
```json
{
  "event_type": "reminder.scheduled",
  "event_id": "ghi78901-e89b-12d3-a456-426614174005",
  "timestamp": "2026-01-12T10:00:00.000Z",
  "data": {
    "reminder_id": "jkl23456-e89b-12d3-a456-426614174006",
    "task_id": "456e7890-e89b-12d3-a456-426614174001",
    "user_id": "user123",
    "remind_at": "2026-01-15T09:00:00.000Z",
    "task_title": "Complete project documentation",
    "task_due_date": "2026-01-15T17:00:00.000Z"
  }
}
```

**Data Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reminder_id` | UUID | Yes | Reminder identifier |
| `task_id` | UUID | Yes | Associated task identifier |
| `user_id` | string | Yes | User to remind |
| `remind_at` | ISO8601 | Yes | Reminder time |
| `task_title` | string | Yes | Task title for notification |
| `task_due_date` | ISO8601 | No | Task due date |

**Consumer Actions**:
- Schedule reminder job
- Update reminder queue

---

### reminder.due

Published when a reminder time is reached.

**Topic**: `todo-app.reminders`

**Schema**:
```json
{
  "event_type": "reminder.due",
  "event_id": "mno34567-e89b-12d3-a456-426614174007",
  "timestamp": "2026-01-15T09:00:00.000Z",
  "data": {
    "reminder_id": "jkl23456-e89b-12d3-a456-426614174006",
    "task_id": "456e7890-e89b-12d3-a456-426614174001",
    "user_id": "user123",
    "task_title": "Complete project documentation",
    "task_due_date": "2026-01-15T17:00:00.000Z",
    "hours_until_due": 8
  }
}
```

**Data Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reminder_id` | UUID | Yes | Reminder identifier |
| `task_id` | UUID | Yes | Associated task identifier |
| `user_id` | string | Yes | User to remind |
| `task_title` | string | Yes | Task title |
| `task_due_date` | ISO8601 | No | Task due date |
| `hours_until_due` | float | No | Hours until task is due |

**Consumer Actions**:
- Send email notification
- Send push notification
- Send in-app notification
- Broadcast to WebSocket
- Respect user notification preferences and quiet hours

**Example Consumer**:
```python
async def handle_reminder_due(data: Dict[str, Any]):
    # Check notification preferences
    preferences = await notification_preferences_service.get_or_create_preferences(
        user_id=data["user_id"]
    )

    # Check if we should send notification
    if await notification_preferences_service.should_send_notification(
        user_id=data["user_id"],
        channel="email",
        notification_type="reminder"
    ):
        # Send email
        await email_service.send_reminder(
            to=user.email,
            task_title=data["task_title"],
            due_date=data["task_due_date"]
        )

    # Broadcast to WebSocket (always)
    await websocket_manager.broadcast_to_user(
        user_id=data["user_id"],
        message={
            "type": "reminder.due",
            "data": data
        }
    )
```

---

## Recurring Task Events

### recurring.pattern.created

Published when a recurring pattern is created.

**Topic**: `todo-app.recurring-tasks`

**Schema**:
```json
{
  "event_type": "recurring.pattern.created",
  "event_id": "pqr45678-e89b-12d3-a456-426614174008",
  "timestamp": "2026-01-12T10:00:00.000Z",
  "data": {
    "pattern_id": "stu56789-e89b-12d3-a456-426614174009",
    "user_id": "user123",
    "frequency": "weekly",
    "interval": 1,
    "days_of_week": [1, 3, 5],
    "start_date": "2026-01-01",
    "next_occurrence": "2026-01-13T09:00:00.000Z",
    "task_template": {
      "title": "Weekly team meeting",
      "description": "Discuss project progress",
      "priority": "medium",
      "tags": ["meeting"]
    }
  }
}
```

**Data Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `pattern_id` | UUID | Yes | Pattern identifier |
| `user_id` | string | Yes | Pattern owner |
| `frequency` | enum | Yes | Frequency (daily, weekly, monthly, yearly) |
| `interval` | integer | Yes | Interval (every N days/weeks/months) |
| `days_of_week` | array | No | Days of week (0-6, for weekly) |
| `day_of_month` | integer | No | Day of month (1-31, for monthly) |
| `start_date` | ISO8601 | Yes | Pattern start date |
| `next_occurrence` | ISO8601 | Yes | Next task generation time |
| `task_template` | object | Yes | Template for generated tasks |

**Consumer Actions**:
- Schedule recurring task generation
- Update scheduler queue

---

### recurring.task.generated

Published when a task is generated from a recurring pattern.

**Topic**: `todo-app.recurring-tasks`

**Schema**:
```json
{
  "event_type": "recurring.task.generated",
  "event_id": "vwx67890-e89b-12d3-a456-426614174010",
  "timestamp": "2026-01-13T09:00:00.000Z",
  "data": {
    "pattern_id": "stu56789-e89b-12d3-a456-426614174009",
    "task_id": "yza78901-e89b-12d3-a456-426614174011",
    "user_id": "user123",
    "occurrence_date": "2026-01-13",
    "next_occurrence": "2026-01-15T09:00:00.000Z"
  }
}
```

**Data Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `pattern_id` | UUID | Yes | Source pattern identifier |
| `task_id` | UUID | Yes | Generated task identifier |
| `user_id` | string | Yes | Task owner |
| `occurrence_date` | ISO8601 | Yes | Occurrence date |
| `next_occurrence` | ISO8601 | Yes | Next generation time |

**Consumer Actions**:
- Send notification about new task
- Broadcast to WebSocket
- Update pattern next_occurrence

---

## Task Update Events

### task.status.changed

Published when task status changes (for real-time updates).

**Topic**: `todo-app.task-updates`

**Schema**:
```json
{
  "event_type": "task.status.changed",
  "event_id": "bcd89012-e89b-12d3-a456-426614174012",
  "timestamp": "2026-01-12T11:00:00.000Z",
  "data": {
    "task_id": "456e7890-e89b-12d3-a456-426614174001",
    "user_id": "user123",
    "old_status": "pending",
    "new_status": "in_progress"
  }
}
```

**Consumer Actions**:
- Broadcast to WebSocket immediately
- Update real-time dashboard

---

### task.priority.changed

Published when task priority changes.

**Topic**: `todo-app.task-updates`

**Schema**:
```json
{
  "event_type": "task.priority.changed",
  "event_id": "efg90123-e89b-12d3-a456-426614174013",
  "timestamp": "2026-01-12T11:00:00.000Z",
  "data": {
    "task_id": "456e7890-e89b-12d3-a456-426614174001",
    "user_id": "user123",
    "old_priority": "high",
    "new_priority": "medium"
  }
}
```

**Consumer Actions**:
- Broadcast to WebSocket
- Update priority-based views

---

## Event Validation

All events are validated using Pydantic schemas before publishing.

### Base Event Schema

```python
from pydantic import BaseModel, Field
from datetime import datetime
from uuid import UUID

class BaseEvent(BaseModel):
    event_type: str = Field(..., min_length=1, max_length=100)
    event_id: UUID
    timestamp: datetime
    data: dict
```

### Task Created Event Schema

```python
from typing import Optional, List
from enum import Enum

class TaskStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"

class TaskPriority(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"

class TaskCreatedEventData(BaseModel):
    task_id: UUID
    user_id: str = Field(..., min_length=1, max_length=255)
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    status: TaskStatus
    priority: Optional[TaskPriority]
    tags: Optional[List[str]] = Field(None, max_items=10)
    due_date: Optional[datetime]
    remind_at: Optional[datetime]
    recurring_pattern_id: Optional[UUID]
    created_at: datetime

class TaskCreatedEvent(BaseEvent):
    event_type: str = "task.created"
    data: TaskCreatedEventData
```

### Validation Example

```python
# Validate event before publishing
try:
    event = TaskCreatedEvent(
        event_id=uuid4(),
        timestamp=datetime.utcnow(),
        data=TaskCreatedEventData(
            task_id=task.id,
            user_id=task.user_id,
            title=task.title,
            status=task.status,
            created_at=task.created_at
        )
    )
    await producer.publish(event.dict())
except ValidationError as e:
    logger.error(f"Event validation failed: {e}")
    raise
```

---

## Event Processing

### Consumer Pattern

```python
from aiokafka import AIOKafkaConsumer
from typing import Dict, Any, Callable

class EventConsumer:
    def __init__(self, topic: str, consumer_group: str):
        self.topic = topic
        self.consumer_group = consumer_group
        self.handlers: Dict[str, Callable] = {}

    def register_handler(self, event_type: str, handler: Callable):
        """Register handler for specific event type"""
        self.handlers[event_type] = handler

    async def consume(self):
        """Start consuming events"""
        consumer = AIOKafkaConsumer(
            self.topic,
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            group_id=self.consumer_group,
            value_deserializer=lambda m: json.loads(m.decode('utf-8'))
        )

        await consumer.start()
        try:
            async for message in consumer:
                event = message.value
                event_type = event.get("event_type")
                event_id = event.get("event_id")

                # Check idempotency
                if await idempotency_service.is_processed(event_id, self.consumer_group):
                    logger.info(f"Skipping duplicate event: {event_id}")
                    continue

                # Get handler
                handler = self.handlers.get(event_type)
                if handler:
                    try:
                        await handler(event.get("data", {}))

                        # Mark as processed
                        await idempotency_service.mark_processed(
                            event_id=event_id,
                            event_type=event_type,
                            consumer_group=self.consumer_group
                        )
                    except Exception as e:
                        logger.error(f"Error processing event {event_id}: {e}")
                        # Don't mark as processed - will retry
                else:
                    logger.warning(f"No handler for event type: {event_type}")
        finally:
            await consumer.stop()
```

---

## Idempotency

All event consumers implement idempotency to prevent duplicate processing.

### Idempotency Table

```sql
CREATE TABLE processed_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    consumer_group VARCHAR(100) NOT NULL,
    processed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (event_id, consumer_group)
);

CREATE INDEX idx_processed_events_event_id ON processed_events(event_id);
CREATE INDEX idx_processed_events_consumer_group ON processed_events(consumer_group);
```

### Idempotency Service

```python
class IdempotencyService:
    async def is_processed(self, event_id: str, consumer_group: str) -> bool:
        """Check if event has been processed"""
        query = select(ProcessedEvent).where(
            ProcessedEvent.event_id == event_id,
            ProcessedEvent.consumer_group == consumer_group
        )
        result = await self.session.execute(query)
        return result.scalar_one_or_none() is not None

    async def mark_processed(
        self,
        event_id: str,
        event_type: str,
        consumer_group: str
    ) -> bool:
        """Mark event as processed"""
        try:
            processed_event = ProcessedEvent(
                event_id=event_id,
                event_type=event_type,
                consumer_group=consumer_group
            )
            self.session.add(processed_event)
            await self.session.commit()
            return True
        except IntegrityError:
            # Race condition - event already processed
            await self.session.rollback()
            return False
```

---

## Best Practices

### Event Publishing

1. **Always validate events** before publishing
2. **Use unique event IDs** (UUID v4)
3. **Include timestamp** in UTC
4. **Partition by user_id** for ordering guarantees
5. **Keep events immutable** - never modify published events
6. **Include enough context** for consumers to process independently

### Event Consumption

1. **Implement idempotency** for all consumers
2. **Handle errors gracefully** - don't mark as processed on failure
3. **Log all processing** for debugging
4. **Monitor consumer lag** to detect issues
5. **Use dead letter queues** for failed events
6. **Respect user preferences** (quiet hours, notification settings)

### Event Schema Evolution

1. **Add fields only** - never remove or rename
2. **Make new fields optional** for backward compatibility
3. **Version events** if breaking changes needed
4. **Document all changes** in changelog
5. **Test with old and new schemas** before deployment

---

## Monitoring

### Key Metrics

- **Event publish rate** by topic
- **Event consumption rate** by consumer group
- **Consumer lag** by topic and partition
- **Event processing duration** by event type
- **Failed event count** by consumer group
- **Duplicate event rate** by consumer group

### Alerts

- Consumer lag > 1000 messages
- Event publish failures > 1%
- Event consumption failures > 1%
- Duplicate event rate > 10%
- Consumer group down for > 1 minute

---

## Troubleshooting

### Common Issues

**Issue**: Events not being consumed
- Check consumer is running
- Verify consumer group configuration
- Check Kafka connectivity
- Review consumer logs for errors

**Issue**: Duplicate event processing
- Verify idempotency implementation
- Check processed_events table
- Review unique constraint on (event_id, consumer_group)

**Issue**: High consumer lag
- Increase consumer instances
- Optimize event processing logic
- Check for slow database queries
- Review resource limits

**Issue**: Event validation failures
- Check event schema matches Pydantic model
- Verify all required fields present
- Review field types and constraints
- Check for null values in required fields

---

## References

- [Architecture Overview](architecture.md)
- [API Reference](api-reference.md)
- [Deployment Guide](deployment.md)
- [Monitoring Guide](monitoring.md)

---

## Changelog

### v1.0 (2026-01-12)
- Initial event schema documentation
- Task events (created, updated, deleted, completed)
- Reminder events (scheduled, due)
- Recurring task events (pattern.created, task.generated)
- Task update events (status.changed, priority.changed)
- Event validation with Pydantic
- Idempotency implementation
- Consumer patterns and best practices
