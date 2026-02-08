# Phase 1: Data Model & Database Schema

**Feature**: Cloud-Native Event-Driven Todo Application (Phase 5)
**Branch**: `008-cloud-event-driven-phase5`
**Date**: 2026-01-11

## Overview

This document defines the complete database schema for Phase 5, including modifications to existing tables and new tables for event-driven features. All schema changes are designed to maintain backward compatibility with Phase IV.

---

## Database Strategy

**Database**: Neon Postgres (existing from Phase III)
**Schema Organization**: Single database with logical schema separation
**Migration Tool**: Alembic (existing from Phase III)
**Connection Pooling**: PgBouncer (built-in to Neon)

---

## Schema Changes Summary

### Modified Tables
1. **tasks** - Add priority, tags, due_date, remind_at, recurring_pattern_id

### New Tables
1. **recurring_patterns** - Recurrence rules for recurring tasks
2. **audit_log** - Event history for compliance tracking
3. **notification_preferences** - User notification settings
4. **saved_filters** - User-defined filter combinations
5. **processed_events** - Idempotency tracking for event consumers

---

## Table Definitions

### 1. tasks (Modified)

**Purpose**: Core task entity with Phase V enhancements

**Existing Columns** (from Phase III):
```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'active',  -- 'active' or 'complete'
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Indexes
    INDEX idx_tasks_user_id (user_id),
    INDEX idx_tasks_status (status),
    INDEX idx_tasks_created_at (created_at)
);
```

**New Columns** (Phase V additions):
```sql
ALTER TABLE tasks ADD COLUMN priority VARCHAR(10) DEFAULT 'medium';  -- 'high', 'medium', 'low'
ALTER TABLE tasks ADD COLUMN tags TEXT[] DEFAULT '{}';  -- Array of tag strings
ALTER TABLE tasks ADD COLUMN due_date TIMESTAMP WITH TIME ZONE;  -- NULL if no due date
ALTER TABLE tasks ADD COLUMN remind_at TIMESTAMP WITH TIME ZONE;  -- NULL if no reminder
ALTER TABLE tasks ADD COLUMN recurring_pattern_id UUID;  -- Foreign key to recurring_patterns

-- Add foreign key constraint
ALTER TABLE tasks ADD CONSTRAINT fk_tasks_recurring_pattern
    FOREIGN KEY (recurring_pattern_id) REFERENCES recurring_patterns(id) ON DELETE SET NULL;

-- Add new indexes for Phase V queries
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_tags ON tasks USING GIN(tags);  -- GIN index for array queries
CREATE INDEX idx_tasks_due_date ON tasks(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_tasks_remind_at ON tasks(remind_at) WHERE remind_at IS NOT NULL;
CREATE INDEX idx_tasks_recurring_pattern_id ON tasks(recurring_pattern_id) WHERE recurring_pattern_id IS NOT NULL;

-- Composite index for common queries
CREATE INDEX idx_tasks_user_status_priority ON tasks(user_id, status, priority);
```

**Constraints**:
- `priority` must be one of: 'high', 'medium', 'low'
- `status` must be one of: 'active', 'complete'
- `due_date` must be in the future when set (application-level validation)
- `remind_at` must be before `due_date` when both are set (application-level validation)

**Sample Data**:
```sql
INSERT INTO tasks (id, user_id, title, description, status, priority, tags, due_date, remind_at, recurring_pattern_id)
VALUES (
    '123e4567-e89b-12d3-a456-426614174000',
    '987fcdeb-51a2-43d7-9876-543210fedcba',
    'Daily standup meeting',
    'Team sync at 9 AM',
    'active',
    'high',
    ARRAY['work', 'meetings'],
    '2026-01-12 09:00:00+00',
    '2026-01-12 08:45:00+00',
    '456e7890-e89b-12d3-a456-426614174111'
);
```

---

### 2. recurring_patterns (New)

**Purpose**: Store recurrence rules for recurring tasks

```sql
CREATE TABLE recurring_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    original_task_id UUID NOT NULL,  -- Reference to the first task in the series
    frequency VARCHAR(20) NOT NULL,  -- 'daily', 'weekly', 'monthly', 'yearly', 'custom'
    interval INTEGER NOT NULL DEFAULT 1,  -- For daily: every N days
    days_of_week INTEGER[],  -- For weekly: [0=Sunday, 1=Monday, ..., 6=Saturday]
    day_of_month INTEGER,  -- For monthly: 1-31, or -1 for last day
    month_of_year INTEGER,  -- For yearly: 1-12
    cron_expression VARCHAR(100),  -- For custom: cron expression
    end_condition VARCHAR(20) NOT NULL,  -- 'date', 'count', 'indefinite'
    end_date TIMESTAMP WITH TIME ZONE,  -- For end_condition='date'
    occurrence_count INTEGER,  -- For end_condition='count': total occurrences
    current_count INTEGER NOT NULL DEFAULT 0,  -- Current occurrence number
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT chk_frequency CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly', 'custom')),
    CONSTRAINT chk_end_condition CHECK (end_condition IN ('date', 'count', 'indefinite')),
    CONSTRAINT chk_interval_positive CHECK (interval > 0),
    CONSTRAINT chk_day_of_month CHECK (day_of_month BETWEEN -1 AND 31),
    CONSTRAINT chk_month_of_year CHECK (month_of_year BETWEEN 1 AND 12),
    CONSTRAINT chk_occurrence_count CHECK (occurrence_count IS NULL OR occurrence_count > 0),

    -- Indexes
    INDEX idx_recurring_patterns_user_id (user_id),
    INDEX idx_recurring_patterns_original_task_id (original_task_id)
);
```

**Sample Data**:
```sql
-- Daily recurring task (every day)
INSERT INTO recurring_patterns (id, user_id, original_task_id, frequency, interval, end_condition)
VALUES (
    '456e7890-e89b-12d3-a456-426614174111',
    '987fcdeb-51a2-43d7-9876-543210fedcba',
    '123e4567-e89b-12d3-a456-426614174000',
    'daily',
    1,
    'indefinite'
);

-- Weekly recurring task (Monday, Wednesday, Friday)
INSERT INTO recurring_patterns (id, user_id, original_task_id, frequency, days_of_week, end_condition, occurrence_count)
VALUES (
    '456e7890-e89b-12d3-a456-426614174222',
    '987fcdeb-51a2-43d7-9876-543210fedcba',
    '123e4567-e89b-12d3-a456-426614174001',
    'weekly',
    ARRAY[1, 3, 5],  -- Monday, Wednesday, Friday
    'count',
    10
);

-- Monthly recurring task (15th of every month)
INSERT INTO recurring_patterns (id, user_id, original_task_id, frequency, day_of_month, end_condition, end_date)
VALUES (
    '456e7890-e89b-12d3-a456-426614174333',
    '987fcdeb-51a2-43d7-9876-543210fedcba',
    '123e4567-e89b-12d3-a456-426614174002',
    'monthly',
    15,
    'date',
    '2026-12-31 23:59:59+00'
);

-- Custom cron pattern (weekdays at 9 AM)
INSERT INTO recurring_patterns (id, user_id, original_task_id, frequency, cron_expression, end_condition)
VALUES (
    '456e7890-e89b-12d3-a456-426614174444',
    '987fcdeb-51a2-43d7-9876-543210fedcba',
    '123e4567-e89b-12d3-a456-426614174003',
    'custom',
    '0 9 * * 1-5',  -- 9 AM on weekdays
    'indefinite'
);
```

---

### 3. audit_log (New)

**Purpose**: Track all task operations for compliance and history

```sql
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL UNIQUE,  -- From Kafka event
    event_type VARCHAR(50) NOT NULL,  -- 'task.created', 'task.updated', 'task.deleted', 'task.completed'
    task_id UUID NOT NULL,
    user_id UUID NOT NULL,
    operation VARCHAR(20) NOT NULL,  -- 'create', 'update', 'delete', 'complete'
    event_payload JSONB NOT NULL,  -- Full event data
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    processed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Indexes
    INDEX idx_audit_log_event_id (event_id),
    INDEX idx_audit_log_task_id (task_id),
    INDEX idx_audit_log_user_id (user_id),
    INDEX idx_audit_log_event_type (event_type),
    INDEX idx_audit_log_timestamp (timestamp),
    INDEX idx_audit_log_event_payload ON audit_log USING GIN(event_payload)  -- JSONB index
);
```

**Sample Data**:
```sql
INSERT INTO audit_log (event_id, event_type, task_id, user_id, operation, event_payload, timestamp)
VALUES (
    'aaa11111-e89b-12d3-a456-426614174000',
    'task.created',
    '123e4567-e89b-12d3-a456-426614174000',
    '987fcdeb-51a2-43d7-9876-543210fedcba',
    'create',
    '{"schema_version": "1.0", "event_type": "task.created", "payload": {"task_id": "123e4567-e89b-12d3-a456-426614174000", "title": "Daily standup meeting", "status": "active"}}'::jsonb,
    '2026-01-11 10:30:00+00'
);
```

---

### 4. notification_preferences (New)

**Purpose**: Store user notification settings

```sql
CREATE TABLE notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,  -- One preference record per user
    email_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    inapp_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    quiet_hours_start TIME,  -- e.g., '22:00:00' for 10 PM
    quiet_hours_end TIME,  -- e.g., '08:00:00' for 8 AM
    max_notifications_per_hour INTEGER NOT NULL DEFAULT 10,
    timezone VARCHAR(50) NOT NULL DEFAULT 'UTC',  -- IANA timezone (e.g., 'America/New_York')
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT chk_max_notifications_positive CHECK (max_notifications_per_hour > 0),

    -- Indexes
    INDEX idx_notification_preferences_user_id (user_id)
);
```

**Sample Data**:
```sql
INSERT INTO notification_preferences (user_id, email_enabled, inapp_enabled, quiet_hours_start, quiet_hours_end, max_notifications_per_hour, timezone)
VALUES (
    '987fcdeb-51a2-43d7-9876-543210fedcba',
    TRUE,
    TRUE,
    '22:00:00',
    '08:00:00',
    10,
    'America/New_York'
);
```

---

### 5. saved_filters (New)

**Purpose**: Store user-defined filter combinations for quick access

```sql
CREATE TABLE saved_filters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,  -- User-defined name (e.g., "Urgent Work Items")
    filter_criteria JSONB NOT NULL,  -- JSON object with filter parameters
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT uq_saved_filters_user_name UNIQUE (user_id, name),

    -- Indexes
    INDEX idx_saved_filters_user_id (user_id)
);
```

**Sample Data**:
```sql
INSERT INTO saved_filters (user_id, name, filter_criteria)
VALUES (
    '987fcdeb-51a2-43d7-9876-543210fedcba',
    'Urgent Work Items',
    '{"status": "active", "priority": "high", "tags": ["work", "urgent"], "due_date_range": {"start": "2026-01-11", "end": "2026-01-18"}}'::jsonb
);
```

---

### 6. processed_events (New)

**Purpose**: Track processed events for idempotency across all consumer services

```sql
CREATE TABLE processed_events (
    event_id UUID PRIMARY KEY,  -- From Kafka event
    service_name VARCHAR(50) NOT NULL,  -- 'recurring-task-service', 'notification-service', 'audit-service', 'websocket-service'
    event_type VARCHAR(50) NOT NULL,
    processed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Composite unique constraint (event can be processed once per service)
    CONSTRAINT uq_processed_events_service UNIQUE (event_id, service_name),

    -- Indexes
    INDEX idx_processed_events_service_name (service_name),
    INDEX idx_processed_events_processed_at (processed_at)
);

-- Cleanup old processed events (retention: 7 days)
CREATE INDEX idx_processed_events_cleanup ON processed_events(processed_at)
    WHERE processed_at < NOW() - INTERVAL '7 days';
```

**Sample Data**:
```sql
INSERT INTO processed_events (event_id, service_name, event_type)
VALUES (
    'aaa11111-e89b-12d3-a456-426614174000',
    'audit-service',
    'task.created'
);
```

---

## Existing Tables (No Changes)

### conversations (from Phase III)
```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    INDEX idx_conversations_user_id (user_id)
);
```

### messages (from Phase III)
```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL,
    role VARCHAR(20) NOT NULL,  -- 'user' or 'assistant'
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    INDEX idx_messages_conversation_id (conversation_id)
);
```

---

## Migration Strategy

### Migration File: `005_phase5_schema.py`

**Location**: `calm-orbit-todo/phase5-cloud/backend/alembic/versions/005_phase5_schema.py`

**Upgrade Steps**:
1. Add new columns to `tasks` table
2. Create `recurring_patterns` table
3. Create `audit_log` table
4. Create `notification_preferences` table
5. Create `saved_filters` table
6. Create `processed_events` table
7. Add foreign key constraint from `tasks` to `recurring_patterns`
8. Create all indexes

**Downgrade Steps**:
1. Drop foreign key constraint from `tasks`
2. Drop new indexes
3. Drop new tables (in reverse order)
4. Drop new columns from `tasks`

**Data Preservation**:
- All existing tasks remain unchanged
- New columns have sensible defaults (priority='medium', tags='{}', due_date=NULL, etc.)
- No data loss during migration

---

## Query Patterns

### 1. Get User's Active Tasks with Priority and Tags
```sql
SELECT id, title, description, status, priority, tags, due_date, remind_at, created_at
FROM tasks
WHERE user_id = $1 AND status = 'active'
ORDER BY priority DESC, due_date ASC NULLS LAST;
```

### 2. Search Tasks by Keyword and Filter by Priority/Tags
```sql
SELECT id, title, description, status, priority, tags, due_date
FROM tasks
WHERE user_id = $1
  AND status = 'active'
  AND (title ILIKE $2 OR description ILIKE $2)
  AND priority = $3
  AND tags && $4  -- Array overlap operator
ORDER BY due_date ASC NULLS LAST;
```

### 3. Get Tasks Due Today with Reminders
```sql
SELECT id, title, due_date, remind_at
FROM tasks
WHERE user_id = $1
  AND status = 'active'
  AND due_date::date = CURRENT_DATE
  AND remind_at IS NOT NULL
ORDER BY due_date ASC;
```

### 4. Get Recurring Pattern for Task
```sql
SELECT rp.*
FROM recurring_patterns rp
JOIN tasks t ON t.recurring_pattern_id = rp.id
WHERE t.id = $1;
```

### 5. Get Audit History for Task
```sql
SELECT event_type, operation, event_payload, timestamp
FROM audit_log
WHERE task_id = $1
ORDER BY timestamp DESC;
```

### 6. Check if Event Already Processed (Idempotency)
```sql
SELECT 1
FROM processed_events
WHERE event_id = $1 AND service_name = $2;
```

### 7. Get User's Notification Preferences
```sql
SELECT email_enabled, inapp_enabled, quiet_hours_start, quiet_hours_end, max_notifications_per_hour, timezone
FROM notification_preferences
WHERE user_id = $1;
```

### 8. Get User's Saved Filters
```sql
SELECT id, name, filter_criteria
FROM saved_filters
WHERE user_id = $1
ORDER BY name ASC;
```

---

## Performance Considerations

### Indexes
- **GIN indexes** on `tags` (array) and `event_payload` (JSONB) for efficient queries
- **Partial indexes** on `due_date` and `remind_at` (only index non-NULL values)
- **Composite indexes** for common query patterns (user_id + status + priority)

### Query Optimization
- Use `EXPLAIN ANALYZE` to verify index usage
- Avoid `SELECT *`; specify only needed columns
- Use pagination for large result sets (LIMIT/OFFSET or cursor-based)

### Data Retention
- **audit_log**: Retain for 90 days; archive older records
- **processed_events**: Retain for 7 days; cleanup with scheduled job
- **messages**: Retain for 30 days; archive older conversations

---

## Data Integrity

### Foreign Key Constraints
- `tasks.recurring_pattern_id` → `recurring_patterns.id` (ON DELETE SET NULL)
- `messages.conversation_id` → `conversations.id` (ON DELETE CASCADE)

### Application-Level Validation
- `due_date` must be in the future when set
- `remind_at` must be before `due_date` when both are set
- `priority` must be one of: 'high', 'medium', 'low'
- `status` must be one of: 'active', 'complete'
- `tags` array must not contain empty strings

### Unique Constraints
- `notification_preferences.user_id` (one preference record per user)
- `saved_filters(user_id, name)` (unique filter names per user)
- `processed_events(event_id, service_name)` (event processed once per service)
- `audit_log.event_id` (each event logged once)

---

## Backup and Recovery

### Neon Postgres Features
- **Automated Backups**: Daily backups with 7-day retention
- **Point-in-Time Recovery**: Restore to any point within retention period
- **Database Branching**: Create test branches for schema changes

### Backup Strategy
1. **Pre-Migration Backup**: Create database branch before running migration
2. **Post-Migration Verification**: Run test queries to verify schema
3. **Rollback Plan**: Use Alembic downgrade if issues detected

---

## Next Steps

1. ✅ Data model complete - all tables and indexes defined
2. ⏭️ Create Alembic migration file (`005_phase5_schema.py`)
3. ⏭️ Define event schemas in `contracts/events/`
4. ⏭️ Define API contracts in `contracts/apis/`
5. ⏭️ Create quickstart guide for setup
