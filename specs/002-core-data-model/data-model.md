# Data Model: Core Data & Domain Model

**Feature**: 002-core-data-model
**Date**: 2025-12-12
**Spec**: [spec.md](./spec.md)
**Research**: [research.md](./research.md)

---

## Entity Overview

This feature defines a single entity (`Task`) that references users managed by Better Auth.

```
┌─────────────────────┐         ┌─────────────────────┐
│   Better Auth       │         │       Task          │
│   (external)        │         │   (this feature)    │
├─────────────────────┤         ├─────────────────────┤
│ id: UUID (PK)       │◄────────│ user_id: UUID (FK)  │
│ email: String       │    1:N  │ id: UUID (PK)       │
│ name: String        │         │ title: String(255)  │
│ ...                 │         │ description: Text   │
└─────────────────────┘         │ status: Enum        │
                                │ created_at: DateTime│
                                │ updated_at: DateTime│
                                └─────────────────────┘
```

**Relationship**: One User has many Tasks (1:N). Tasks cannot exist without an owner.

---

## Entity: Task

### Table Definition

| Property | Value |
|----------|-------|
| Table Name | `task` |
| Schema | `public` (default) |
| Primary Key | `id` (UUID) |
| Foreign Keys | `user_id` → Better Auth user (soft reference) |

### Columns

| Column | Type | Nullable | Default | Constraints | Description |
|--------|------|----------|---------|-------------|-------------|
| `id` | `UUID` | NO | `uuid4()` | PRIMARY KEY | Unique task identifier |
| `user_id` | `VARCHAR(36)` | NO | - | INDEX | Owner's Better Auth user ID |
| `title` | `VARCHAR(255)` | NO | - | NOT EMPTY CHECK | Task name (max 255 chars) |
| `description` | `TEXT` | YES | `NULL` | - | Optional task details |
| `status` | `VARCHAR(20)` | NO | `'pending'` | CHECK IN ('pending', 'completed') | Task state |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | NO | `now()` | - | Creation timestamp (immutable) |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | NO | `now()` | ON UPDATE `now()` | Last modification timestamp |

### Indexes

| Index Name | Columns | Type | Purpose |
|------------|---------|------|---------|
| `pk_task` | `id` | B-tree (PK) | Primary key lookup |
| `ix_task_user_id` | `user_id` | B-tree | Filter tasks by owner |
| `ix_task_user_status` | `user_id, status` | B-tree (composite) | Filter by owner + status |

### Constraints

| Constraint Name | Type | Definition | Purpose |
|-----------------|------|------------|---------|
| `pk_task` | PRIMARY KEY | `id` | Unique row identifier |
| `chk_task_status` | CHECK | `status IN ('pending', 'completed')` | Restrict to valid statuses |
| `chk_task_title_not_empty` | CHECK | `length(trim(title)) > 0` | Prevent empty/whitespace titles |

### SQLModel Definition (Conceptual)

```python
from datetime import datetime
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4

from sqlalchemy import Column, DateTime, String, Text, func, CheckConstraint
from sqlmodel import Field, SQLModel


class TaskStatus(str, Enum):
    """Valid task statuses."""
    PENDING = "pending"
    COMPLETED = "completed"


class Task(SQLModel, table=True):
    """
    Represents a single to-do item owned by a user.

    Invariants:
    - Every task belongs to exactly one user (user_id NOT NULL)
    - Title is required and non-empty (max 255 characters)
    - Status is constrained to 'pending' or 'completed'
    - Timestamps are managed automatically
    """
    __tablename__ = "task"
    __table_args__ = (
        CheckConstraint("status IN ('pending', 'completed')", name="chk_task_status"),
        CheckConstraint("length(trim(title)) > 0", name="chk_task_title_not_empty"),
    )

    # Primary key
    id: UUID = Field(
        default_factory=uuid4,
        primary_key=True,
        nullable=False,
        description="Unique task identifier"
    )

    # Owner reference (Better Auth user ID)
    user_id: str = Field(
        ...,
        max_length=36,
        nullable=False,
        index=True,
        description="Owner's Better Auth user ID (UUID string)"
    )

    # Task content
    title: str = Field(
        ...,
        max_length=255,
        nullable=False,
        description="Task name (required, max 255 characters)"
    )

    description: Optional[str] = Field(
        default=None,
        sa_column=Column(Text, nullable=True),
        description="Optional task details"
    )

    # Task state
    status: TaskStatus = Field(
        default=TaskStatus.PENDING,
        nullable=False,
        description="Task status: 'pending' or 'completed'"
    )

    # Timestamps
    created_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            server_default=func.now(),
            nullable=False
        ),
        description="Creation timestamp (immutable)"
    )

    updated_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            server_default=func.now(),
            onupdate=func.now(),
            nullable=False
        ),
        description="Last modification timestamp"
    )
```

---

## Validation Rules

### Application-Level Validation (Pydantic)

| Field | Rule | Error Message |
|-------|------|---------------|
| `title` | Not empty after trim | "Title cannot be empty" |
| `title` | Max 255 characters | "Title must be 255 characters or fewer" |
| `status` | Must be valid enum value | "Status must be 'pending' or 'completed'" |
| `user_id` | Valid UUID format | "Invalid user ID format" |

### Database-Level Validation (Constraints)

| Constraint | Enforcement | Failure Response |
|------------|-------------|------------------|
| `chk_task_status` | CHECK constraint | IntegrityError |
| `chk_task_title_not_empty` | CHECK constraint | IntegrityError |
| `user_id NOT NULL` | Column constraint | IntegrityError |

---

## State Transitions

```
                    ┌──────────────┐
                    │              │
    [Create] ──────►│   PENDING    │
                    │              │
                    └──────┬───────┘
                           │
                           │ [Update status]
                           ▼
                    ┌──────────────┐
                    │              │
                    │  COMPLETED   │
                    │              │
                    └──────┬───────┘
                           │
                           │ [Update status]
                           ▼
                    ┌──────────────┐
                    │              │
                    │   PENDING    │◄───┐
                    │              │    │ (reversible)
                    └──────────────┘────┘
```

**Transition Rules**:
- New tasks always start as `pending`
- Status can be changed between `pending` and `completed` freely
- Status changes update `updated_at` automatically
- No terminal state; tasks can be deleted at any time

---

## Query Patterns

### Primary Access Patterns

| Pattern | Query | Index Used |
|---------|-------|------------|
| Get user's tasks | `WHERE user_id = ?` | `ix_task_user_id` |
| Get user's pending tasks | `WHERE user_id = ? AND status = 'pending'` | `ix_task_user_status` |
| Get single task | `WHERE id = ?` | `pk_task` |
| Get task by ID for user | `WHERE id = ? AND user_id = ?` | `pk_task` + filter |

### User Isolation Pattern

**Critical**: All queries MUST include `user_id` filter to enforce isolation.

```python
# CORRECT: Always filter by authenticated user
tasks = session.exec(
    select(Task).where(Task.user_id == current_user.id)
).all()

# WRONG: Never query without user_id filter
tasks = session.exec(select(Task)).all()  # SECURITY VIOLATION
```

---

## Migration Strategy

### Initial Migration: `001_create_task_table`

**Upgrade**:
1. Create `task` table with all columns
2. Add CHECK constraints
3. Create indexes

**Downgrade**:
1. Drop indexes
2. Drop `task` table

### Migration SQL (Reference)

```sql
-- Upgrade
CREATE TABLE task (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT chk_task_status CHECK (status IN ('pending', 'completed')),
    CONSTRAINT chk_task_title_not_empty CHECK (length(trim(title)) > 0)
);

CREATE INDEX ix_task_user_id ON task (user_id);
CREATE INDEX ix_task_user_status ON task (user_id, status);

-- Downgrade
DROP TABLE IF EXISTS task;
```

---

## Data Lifecycle

### Creation
- `id`: Generated automatically (uuid4)
- `user_id`: Required; obtained from authenticated JWT
- `title`: Required; validated for length and non-empty
- `description`: Optional; defaults to NULL
- `status`: Defaults to 'pending'
- `created_at`: Set by database to current timestamp
- `updated_at`: Set by database to current timestamp

### Update
- `title`, `description`, `status`: Can be modified
- `updated_at`: Auto-refreshed on any change
- `id`, `user_id`, `created_at`: Immutable after creation

### Deletion
- Hard delete (no soft delete)
- Cascade delete when user is deleted (application-level enforcement)
- No orphaned tasks allowed

---

## Testing Checklist

- [ ] Task creation with valid data succeeds
- [ ] Task creation without title fails
- [ ] Task creation with empty/whitespace title fails
- [ ] Task creation with title > 255 chars fails
- [ ] Task creation without user_id fails
- [ ] Status defaults to 'pending' on creation
- [ ] Status update to 'completed' succeeds
- [ ] Status update to invalid value fails
- [ ] created_at is set automatically
- [ ] updated_at changes on modification
- [ ] User A cannot read User B's tasks
- [ ] User A cannot update User B's tasks
- [ ] User A cannot delete User B's tasks
- [ ] Migration applies cleanly to empty database
- [ ] Migration rollback works correctly
