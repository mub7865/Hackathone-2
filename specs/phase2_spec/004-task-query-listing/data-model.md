# Data Model: Task Querying & Listing Behavior

**Feature**: 005-task-query-listing
**Date**: 2025-12-14
**Status**: Complete

---

## Overview

This chunk does **not introduce new entities**. It extends the query capabilities of the existing Task entity established in Chunks 1-3.

---

## Existing Entity: Task

**Location**: `phase2/backend/app/models/task.py`

### Current Schema

```python
class Task(SQLModel, table=True):
    __tablename__ = "task"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    user_id: str = Field(max_length=36, index=True)
    title: str = Field(max_length=255)
    description: Optional[str] = Field(default=None)
    status: TaskStatus = Field(default=TaskStatus.PENDING)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
```

### Fields Used for Querying

| Field | Type | Query Usage |
|-------|------|-------------|
| `user_id` | str(36) | **WHERE** - User isolation (always applied) |
| `status` | enum | **WHERE** - Status filter (pending/completed/all) |
| `title` | str(255) | **WHERE** - Search (ILIKE), **ORDER BY** - Sort |
| `description` | text | **WHERE** - Search (ILIKE) |
| `created_at` | datetime | **ORDER BY** - Sort (default) |

### No Schema Changes Required

The existing Task table supports all querying needs:
- Search: `title` and `description` are text fields suitable for ILIKE
- Sort: `created_at` (datetime) and `title` (string) are sortable
- Filter: `status` is an enum with existing index

---

## New Enums (Backend)

**Location**: `phase2/backend/app/schemas/task.py`

### SortField Enum

```python
from enum import Enum

class SortField(str, Enum):
    """Fields available for sorting tasks."""
    CREATED_AT = "created_at"
    TITLE = "title"
```

### SortOrder Enum

```python
class SortOrder(str, Enum):
    """Sort direction for task listing."""
    ASC = "asc"
    DESC = "desc"
```

---

## New Types (Frontend)

**Location**: `phase2/frontend/types/task.ts`

### SortField Type

```typescript
/**
 * Fields available for sorting tasks.
 */
export type SortField = 'created_at' | 'title';
```

### SortOrder Type

```typescript
/**
 * Sort direction for task listing.
 */
export type SortOrder = 'asc' | 'desc';
```

### TaskQueryParams Interface

```typescript
/**
 * Parameters for querying the task list.
 * All fields are optional; defaults apply when omitted.
 */
export interface TaskQueryParams {
  /** Filter by status. 'all' returns both pending and completed. */
  status?: TaskFilter;

  /** Free-text search on title and description. Max 100 chars. */
  search?: string;

  /** Field to sort by. Default: 'created_at'. */
  sort?: SortField;

  /** Sort direction. Default: 'desc'. */
  order?: SortOrder;

  /** Pagination offset. Default: 0. */
  offset?: number;

  /** Pagination limit. Default: 20, max: 100. */
  limit?: number;
}
```

---

## Existing Indices

**Location**: `phase2/backend/app/models/task.py`

### Current Index

```python
__table_args__ = (
    Index("ix_task_user_status", "user_id", "status"),
)
```

This composite index supports efficient queries filtering by:
- `user_id` only (index prefix)
- `user_id` + `status` (full index)

### Index Analysis for New Queries

| Query Pattern | Index Used | Performance |
|--------------|------------|-------------|
| `WHERE user_id = ?` | ix_task_user_status | Fast (index scan) |
| `WHERE user_id = ? AND status = ?` | ix_task_user_status | Fast (index scan) |
| `WHERE user_id = ? AND (title ILIKE ? OR desc ILIKE ?)` | ix_task_user_status (partial) | Acceptable (<1000 rows) |
| `ORDER BY created_at` | None (sequential) | Acceptable (<1000 rows) |
| `ORDER BY lower(title)` | None (sequential) | Acceptable (<1000 rows) |

### Optional Future Index

If performance becomes an issue with larger datasets, consider:

```python
Index("ix_task_user_created", "user_id", "created_at")
```

**Not required for Chunk 4** - Current scale (~1000 tasks/user) doesn't warrant additional indices.

---

## Query Patterns

### Base Query (User Isolation)

```sql
SELECT * FROM task
WHERE user_id = :user_id
```

### With Status Filter

```sql
SELECT * FROM task
WHERE user_id = :user_id
  AND status = :status
```

### With Search (title OR description)

```sql
SELECT * FROM task
WHERE user_id = :user_id
  AND (title ILIKE :search OR description ILIKE :search)
```

### With All Filters + Sort + Pagination

```sql
SELECT * FROM task
WHERE user_id = :user_id
  AND status = :status
  AND (title ILIKE :search OR description ILIKE :search)
ORDER BY lower(title) ASC
OFFSET :offset
LIMIT :limit
```

---

## Validation Rules

### Search Parameter

| Rule | Value | Enforcement |
|------|-------|-------------|
| Max length | 100 characters | FastAPI Query(max_length=100) |
| Empty handling | Treated as no filter | Backend trims and checks |
| Special characters | Escaped by SQLAlchemy | Automatic (parameterized query) |

### Sort Parameter

| Rule | Value | Enforcement |
|------|-------|-------------|
| Valid values | `created_at`, `title` | FastAPI Enum validation |
| Default | `created_at` | Query(default=SortField.CREATED_AT) |
| Invalid | Returns 422 | Automatic |

### Order Parameter

| Rule | Value | Enforcement |
|------|-------|-------------|
| Valid values | `asc`, `desc` | FastAPI Enum validation |
| Default | `desc` | Query(default=SortOrder.DESC) |
| Invalid | Returns 422 | Automatic |

### Pagination Parameters

| Rule | Value | Enforcement |
|------|-------|-------------|
| offset min | 0 | Query(ge=0) |
| offset default | 0 | Query(default=0) |
| limit min | 1 | Query(ge=1) |
| limit max | 100 | Query(le=100) |
| limit default | 20 | Query(default=20) |

---

## State Transitions

No state transitions introduced by this chunk. The existing Task lifecycle remains unchanged:

```
[Created] → status: pending
    │
    ▼ (user toggles)
[Completed] → status: completed
    │
    ▼ (user toggles)
[Pending] → status: pending
    │
    ▼ (user deletes)
[Deleted] → removed from database
```

Querying does not modify state - it's read-only.

---

## Relationships

No new relationships. Task remains a standalone entity owned by a user:

```
User (1) ────────< Task (many)
         user_id
```

The `user_id` field continues to enforce ownership and isolation.
