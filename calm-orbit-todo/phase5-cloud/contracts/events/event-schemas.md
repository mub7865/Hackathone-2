# Event Schemas for Phase 5 Event-Driven Architecture

**Feature**: Cloud-Native Event-Driven Todo Application (Phase 5)
**Branch**: `008-cloud-event-driven-phase5`
**Date**: 2026-01-12

## Overview

This document defines the event schemas for all task-related events published to Kafka/Redpanda topics. These schemas serve as contracts between event producers (backend API, MCP tools) and consumers (audit service, notification service, websocket service, recurring task service).

---

## Event Envelope Structure

All events follow a standard envelope format:

```json
{
  "event_id": "uuid",
  "event_type": "string",
  "timestamp": "ISO 8601 datetime",
  "schema_version": "string",
  "payload": {
    // Event-specific payload
  }
}
```

### Envelope Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `event_id` | UUID | Yes | Unique identifier for this event (for idempotency) |
| `event_type` | String | Yes | Event type (e.g., "task.created") |
| `timestamp` | ISO 8601 | Yes | UTC timestamp when event was created |
| `schema_version` | String | Yes | Schema version (currently "1.0") |
| `payload` | Object | Yes | Event-specific data |

---

## Event Types

### 1. task.created

**Topic**: `task-events`
**Description**: Published when a new task is created via API or MCP tools.

**Payload Schema**:

```json
{
  "task_id": "uuid",
  "user_id": "string",
  "title": "string",
  "description": "string | null",
  "status": "string",
  "priority": "string",
  "tags": ["string"],
  "due_date": "ISO 8601 datetime | null",
  "remind_at": "ISO 8601 datetime | null",
  "recurring_pattern_id": "uuid | null"
}
```

**Payload Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `task_id` | UUID | Yes | Unique task identifier |
| `user_id` | String | Yes | Owner's user ID (Better Auth UUID string) |
| `title` | String | Yes | Task title (1-255 characters) |
| `description` | String/Null | No | Task description (optional) |
| `status` | String | Yes | Task status ("pending" or "completed") |
| `priority` | String | Yes | Task priority ("high", "medium", "low") |
| `tags` | Array[String] | Yes | Array of tag strings (can be empty) |
| `due_date` | ISO 8601/Null | No | Due date with timezone (optional) |
| `remind_at` | ISO 8601/Null | No | Reminder timestamp with timezone (optional) |
| `recurring_pattern_id` | UUID/Null | No | Foreign key to recurring pattern (optional) |

**Example**:

```json
{
  "event_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "event_type": "task.created",
  "timestamp": "2026-01-12T10:30:00.000Z",
  "schema_version": "1.0",
  "payload": {
    "task_id": "123e4567-e89b-12d3-a456-426614174000",
    "user_id": "987fcdeb-51a2-43d7-9876-543210fedcba",
    "title": "Daily standup meeting",
    "description": "Team sync at 9 AM",
    "status": "pending",
    "priority": "high",
    "tags": ["work", "meetings"],
    "due_date": "2026-01-12T09:00:00.000Z",
    "remind_at": "2026-01-12T08:45:00.000Z",
    "recurring_pattern_id": "456e7890-e89b-12d3-a456-426614174111"
  }
}
```

**Consumers**:
- Audit Service: Log task creation event
- Notification Service: Send reminder if `remind_at` is set
- WebSocket Service: Broadcast task creation to user's connected clients
- Recurring Task Service: Process recurring pattern if `recurring_pattern_id` is set

---

### 2. task.updated

**Topic**: `task-events`
**Description**: Published when a task is updated via API or MCP tools.

**Payload Schema**:

```json
{
  "task_id": "uuid",
  "user_id": "string",
  "updates": {
    // Dictionary of updated fields
  }
}
```

**Payload Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `task_id` | UUID | Yes | Unique task identifier |
| `user_id` | String | Yes | Owner's user ID |
| `updates` | Object | Yes | Dictionary of fields that were updated |

**Updates Object** (all fields optional):

| Field | Type | Description |
|-------|------|-------------|
| `title` | String | New task title |
| `description` | String/Null | New task description |
| `status` | String | New task status |
| `priority` | String | New task priority |
| `tags` | Array[String] | New tags array |
| `due_date` | ISO 8601/Null | New due date |
| `remind_at` | ISO 8601/Null | New reminder time |

**Example**:

```json
{
  "event_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "event_type": "task.updated",
  "timestamp": "2026-01-12T11:00:00.000Z",
  "schema_version": "1.0",
  "payload": {
    "task_id": "123e4567-e89b-12d3-a456-426614174000",
    "user_id": "987fcdeb-51a2-43d7-9876-543210fedcba",
    "updates": {
      "priority": "medium",
      "tags": ["work", "meetings", "urgent"]
    }
  }
}
```

**Consumers**:
- Audit Service: Log task update event with changes
- WebSocket Service: Broadcast task update to user's connected clients
- Notification Service: Update reminder if `remind_at` changed

---

### 3. task.deleted

**Topic**: `task-events`
**Description**: Published when a task is deleted via API or MCP tools.

**Payload Schema**:

```json
{
  "task_id": "uuid",
  "user_id": "string"
}
```

**Payload Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `task_id` | UUID | Yes | Unique task identifier |
| `user_id` | String | Yes | Owner's user ID |

**Example**:

```json
{
  "event_id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
  "event_type": "task.deleted",
  "timestamp": "2026-01-12T12:00:00.000Z",
  "schema_version": "1.0",
  "payload": {
    "task_id": "123e4567-e89b-12d3-a456-426614174000",
    "user_id": "987fcdeb-51a2-43d7-9876-543210fedcba"
  }
}
```

**Consumers**:
- Audit Service: Log task deletion event
- WebSocket Service: Broadcast task deletion to user's connected clients
- Notification Service: Cancel any pending reminders for this task

---

### 4. task.completed

**Topic**: `task-events`
**Description**: Published when a task status changes to "completed" via API or MCP tools.

**Payload Schema**:

```json
{
  "task_id": "uuid",
  "user_id": "string"
}
```

**Payload Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `task_id` | UUID | Yes | Unique task identifier |
| `user_id` | String | Yes | Owner's user ID |

**Example**:

```json
{
  "event_id": "d4e5f6a7-b8c9-0123-def1-234567890123",
  "event_type": "task.completed",
  "timestamp": "2026-01-12T13:00:00.000Z",
  "schema_version": "1.0",
  "payload": {
    "task_id": "123e4567-e89b-12d3-a456-426614174000",
    "user_id": "987fcdeb-51a2-43d7-9876-543210fedcba"
  }
}
```

**Consumers**:
- Audit Service: Log task completion event
- WebSocket Service: Broadcast task completion to user's connected clients
- Notification Service: Send completion notification if configured
- Recurring Task Service: Create next occurrence if task is recurring

---

## Kafka Topics

### task-events

**Purpose**: All task lifecycle events (created, updated, deleted, completed)
**Partitions**: 3 (for parallel processing)
**Replication Factor**: 2 (for fault tolerance)
**Retention**: 7 days
**Partition Key**: `task_id` (ensures all events for a task go to same partition)

**Consumers**:
- Audit Service (consumer group: `audit-service`)
- Notification Service (consumer group: `notification-service`)
- WebSocket Service (consumer group: `websocket-service`)
- Recurring Task Service (consumer group: `recurring-task-service`)

### reminders

**Purpose**: Reminder notification events
**Partitions**: 3
**Replication Factor**: 2
**Retention**: 1 day
**Partition Key**: `user_id`

**Consumers**:
- Notification Service (consumer group: `notification-service`)

### task-updates

**Purpose**: Real-time task updates for WebSocket broadcasting
**Partitions**: 3
**Replication Factor**: 2
**Retention**: 1 hour (short retention for real-time updates)
**Partition Key**: `user_id`

**Consumers**:
- WebSocket Service (consumer group: `websocket-service`)

---

## Idempotency

All consumers MUST implement idempotency using the `event_id` field:

1. Before processing an event, check if `event_id` exists in `processed_events` table
2. If exists, skip processing (event already handled)
3. If not exists, process event and insert `event_id` into `processed_events` table
4. Use database transactions to ensure atomicity

**processed_events Table**:

```sql
CREATE TABLE processed_events (
    event_id UUID PRIMARY KEY,
    service_name VARCHAR(50) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    processed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_processed_events_service UNIQUE (event_id, service_name)
);
```

---

## Error Handling

### Producer Errors

If event publishing fails:
1. Log error with full context (event type, task ID, user ID)
2. DO NOT fail the main operation (task creation/update/deletion)
3. Return success to user (eventual consistency)
4. Retry mechanism handled by Kafka producer (3 retries with exponential backoff)

### Consumer Errors

If event processing fails:
1. Log error with full context (event ID, event type, error message)
2. DO NOT commit Kafka offset (event will be retried)
3. Implement exponential backoff for retries
4. After 5 failed attempts, move event to dead letter queue (DLQ)
5. Alert on-call engineer for DLQ events

---

## Schema Evolution

### Backward Compatibility Rules

1. **Adding Fields**: Always safe - new fields must be optional with defaults
2. **Removing Fields**: Requires coordination - deprecate first, remove after all consumers updated
3. **Changing Field Types**: Breaking change - requires new schema version
4. **Renaming Fields**: Breaking change - requires new schema version

### Version Migration

When introducing breaking changes:
1. Increment `schema_version` (e.g., "1.0" → "2.0")
2. Publish events with new schema version
3. Update all consumers to handle both old and new versions
4. After all consumers updated, stop publishing old version
5. Document migration in ADR

---

## Testing

### Unit Tests

Test event serialization/deserialization:
```python
def test_task_created_event_serialization():
    event = {
        "event_id": str(uuid4()),
        "event_type": "task.created",
        "timestamp": datetime.utcnow().isoformat(),
        "schema_version": "1.0",
        "payload": {
            "task_id": str(uuid4()),
            "user_id": "test-user",
            "title": "Test Task",
            "status": "pending",
            "priority": "medium",
            "tags": [],
        }
    }
    serialized = json.dumps(event)
    deserialized = json.loads(serialized)
    assert deserialized["event_type"] == "task.created"
```

### Integration Tests

Test end-to-end event flow:
1. Create task via API
2. Verify event published to Kafka
3. Verify consumers process event
4. Verify idempotency (duplicate events ignored)

---

## Monitoring

### Metrics to Track

1. **Producer Metrics**:
   - Events published per second (by event type)
   - Publishing failures (by event type)
   - Publishing latency (p50, p95, p99)

2. **Consumer Metrics**:
   - Events consumed per second (by service, by event type)
   - Processing failures (by service, by event type)
   - Processing latency (p50, p95, p99)
   - Consumer lag (events behind)

3. **Idempotency Metrics**:
   - Duplicate events detected (by service)
   - Idempotency check latency

### Alerts

1. **High Consumer Lag**: Alert if lag > 1000 events for > 5 minutes
2. **High Failure Rate**: Alert if failure rate > 5% for > 2 minutes
3. **DLQ Events**: Alert immediately when events move to DLQ
4. **Publishing Failures**: Alert if failure rate > 1% for > 5 minutes

---

## Next Steps

1. ✅ Event schemas defined
2. ⏭️ Implement consumer services (audit, notification, websocket, recurring-task)
3. ⏭️ Set up Kafka/Redpanda cluster
4. ⏭️ Configure Dapr pub/sub component
5. ⏭️ Add monitoring and alerting
