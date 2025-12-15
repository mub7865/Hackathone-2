# Data Model: Tasks API & Endpoints

**Feature**: 003-tasks-crud-api
**Date**: 2025-12-13
**Status**: Complete

---

## Overview

This document defines the Pydantic schemas for the Tasks API request/response contracts. These schemas build on the existing `Task` SQLModel entity from `002-core-data-model`.

---

## Existing Entity (from 002-core-data-model)

### Task (SQLModel)

| Field | Type | Nullable | Default | Constraints |
|-------|------|----------|---------|-------------|
| `id` | UUID | NO | `uuid4()` | PRIMARY KEY |
| `user_id` | VARCHAR(36) | NO | - | INDEX, NOT NULL |
| `title` | VARCHAR(255) | NO | - | CHECK `length(trim(title)) > 0` |
| `description` | TEXT | YES | NULL | - |
| `status` | VARCHAR(20) | NO | `'pending'` | CHECK `IN ('pending', 'completed')` |
| `created_at` | TIMESTAMP WITH TZ | NO | `now()` | Immutable |
| `updated_at` | TIMESTAMP WITH TZ | NO | `now()` | Auto-updated |

### TaskStatus (Enum)

```python
class TaskStatus(str, Enum):
    PENDING = "pending"
    COMPLETED = "completed"
```

---

## API Schemas (Pydantic v2)

### TaskCreate

**Purpose**: Request body for `POST /api/v1/tasks`

```python
from pydantic import BaseModel, Field

class TaskCreate(BaseModel):
    """Schema for creating a new task."""

    title: str = Field(
        ...,
        min_length=1,
        max_length=255,
        description="Task title (required, 1-255 characters)"
    )
    description: str | None = Field(
        None,
        description="Optional task description"
    )

    model_config = {
        "json_schema_extra": {
            "examples": [
                {"title": "Buy groceries"},
                {"title": "Read book", "description": "Chapter 5-7"}
            ]
        }
    }
```

**Validation Rules**:
- `title`: Required, 1-255 characters, whitespace-only rejected
- `description`: Optional, no length limit
- `status`: Not accepted (always defaults to "pending")
- `user_id`: Not accepted (set from JWT)

---

### TaskUpdate

**Purpose**: Request body for `PATCH /api/v1/tasks/{id}`

```python
class TaskUpdate(BaseModel):
    """Schema for updating an existing task (partial update)."""

    title: str | None = Field(
        None,
        min_length=1,
        max_length=255,
        description="Updated task title"
    )
    description: str | None = Field(
        None,
        description="Updated task description"
    )
    status: TaskStatus | None = Field(
        None,
        description="Updated task status"
    )

    model_config = {
        "json_schema_extra": {
            "examples": [
                {"status": "completed"},
                {"title": "Updated title", "description": "New description"}
            ]
        }
    }
```

**Validation Rules**:
- All fields optional (partial update)
- `title`: If provided, 1-255 characters
- `status`: If provided, must be "pending" or "completed"
- Empty object `{}` is valid (no-op update)

---

### TaskResponse

**Purpose**: Response body for all task endpoints

```python
from datetime import datetime
from uuid import UUID

class TaskResponse(BaseModel):
    """Schema for task responses."""

    id: UUID = Field(description="Unique task identifier")
    user_id: str = Field(description="Owner's user ID")
    title: str = Field(description="Task title")
    description: str | None = Field(description="Task description")
    status: TaskStatus = Field(description="Task status")
    created_at: datetime = Field(description="Creation timestamp")
    updated_at: datetime = Field(description="Last modification timestamp")

    model_config = {
        "from_attributes": True,  # Enable ORM mode for SQLModel
        "json_schema_extra": {
            "examples": [
                {
                    "id": "550e8400-e29b-41d4-a716-446655440000",
                    "user_id": "user-123",
                    "title": "Buy groceries",
                    "description": "Milk, eggs, bread",
                    "status": "pending",
                    "created_at": "2025-12-13T10:00:00Z",
                    "updated_at": "2025-12-13T10:00:00Z"
                }
            ]
        }
    }
```

**Notes**:
- `from_attributes=True` enables automatic conversion from SQLModel Task
- Timestamps serialized as ISO 8601 strings

---

### ProblemDetail (RFC 7807)

**Purpose**: Consistent error response format

```python
class ProblemDetail(BaseModel):
    """RFC 7807 Problem Details error response."""

    type: str = Field(
        "about:blank",
        description="URI reference identifying the problem type"
    )
    title: str = Field(
        description="Short human-readable summary"
    )
    status: int = Field(
        description="HTTP status code"
    )
    detail: str | None = Field(
        None,
        description="Human-readable explanation specific to this occurrence"
    )
    instance: str | None = Field(
        None,
        description="URI reference identifying the specific occurrence"
    )

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "type": "about:blank",
                    "title": "Not Found",
                    "status": 404,
                    "detail": "Task not found",
                    "instance": "/api/v1/tasks/550e8400-e29b-41d4-a716-446655440000"
                },
                {
                    "type": "about:blank",
                    "title": "Unauthorized",
                    "status": 401,
                    "detail": "Missing or invalid authentication token"
                }
            ]
        }
    }
```

---

### ValidationErrorDetail

**Purpose**: Extended error format for 422 validation errors

```python
class ValidationErrorItem(BaseModel):
    """Single validation error."""

    loc: list[str | int] = Field(description="Error location path")
    msg: str = Field(description="Error message")
    type: str = Field(description="Error type")

class ValidationErrorDetail(ProblemDetail):
    """RFC 7807 with validation error details."""

    errors: list[ValidationErrorItem] = Field(
        default_factory=list,
        description="List of validation errors"
    )
```

---

## Query Parameters

### ListTasksParams

**Purpose**: Query parameters for `GET /api/v1/tasks`

| Parameter | Type | Default | Constraints | Description |
|-----------|------|---------|-------------|-------------|
| `offset` | int | 0 | >= 0 | Number of items to skip |
| `limit` | int | 20 | 1-100 | Max items to return |
| `status` | TaskStatus | None | pending/completed | Filter by status |

**FastAPI Definition**:
```python
from fastapi import Query

async def list_tasks(
    offset: int = Query(0, ge=0, description="Skip N items"),
    limit: int = Query(20, ge=1, le=100, description="Max items (1-100)"),
    status: TaskStatus | None = Query(None, description="Filter by status"),
    ...
):
```

---

## Path Parameters

### TaskId

| Parameter | Type | Format | Description |
|-----------|------|--------|-------------|
| `task_id` | UUID | UUID v4 | Task identifier |

**FastAPI Definition**:
```python
from uuid import UUID

async def get_task(
    task_id: UUID = Path(description="Task UUID"),
    ...
):
```

---

## Response Examples

### Success: List Tasks (200)
```json
[
    {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "user_id": "user-123",
        "title": "Buy groceries",
        "description": null,
        "status": "pending",
        "created_at": "2025-12-13T10:00:00Z",
        "updated_at": "2025-12-13T10:00:00Z"
    }
]
```

### Success: Create Task (201)
```json
{
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "user_id": "user-123",
    "title": "New task",
    "description": "Task description",
    "status": "pending",
    "created_at": "2025-12-13T11:00:00Z",
    "updated_at": "2025-12-13T11:00:00Z"
}
```

### Error: Unauthorized (401)
```json
{
    "type": "about:blank",
    "title": "Unauthorized",
    "status": 401,
    "detail": "Missing or invalid authentication token"
}
```

### Error: Not Found (404)
```json
{
    "type": "about:blank",
    "title": "Not Found",
    "status": 404,
    "detail": "Task not found",
    "instance": "/api/v1/tasks/550e8400-e29b-41d4-a716-446655440099"
}
```

### Error: Validation Error (422)
```json
{
    "type": "about:blank",
    "title": "Validation Error",
    "status": 422,
    "detail": "Request validation failed",
    "errors": [
        {
            "loc": ["body", "title"],
            "msg": "Field required",
            "type": "missing"
        }
    ]
}
```

---

## Schema File Structure

```text
phase2/backend/app/schemas/
├── __init__.py          # Exports all schemas
├── task.py              # TaskCreate, TaskUpdate, TaskResponse
└── error.py             # ProblemDetail, ValidationErrorDetail
```

### __init__.py
```python
from .task import TaskCreate, TaskUpdate, TaskResponse
from .error import ProblemDetail, ValidationErrorDetail, ValidationErrorItem

__all__ = [
    "TaskCreate",
    "TaskUpdate",
    "TaskResponse",
    "ProblemDetail",
    "ValidationErrorDetail",
    "ValidationErrorItem",
]
```
