"""Pydantic schemas for Task API request/response validation."""

from datetime import datetime
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.task import TaskStatus, TaskPriority


class SortField(str, Enum):
    """Fields available for sorting tasks.

    Used by the list_tasks endpoint to specify sort column.
    """

    CREATED_AT = "created_at"
    TITLE = "title"
    PRIORITY = "priority"


class SortOrder(str, Enum):
    """Sort direction for task listing.

    Used by the list_tasks endpoint to specify ascending/descending order.
    """

    ASC = "asc"
    DESC = "desc"


class TaskCreate(BaseModel):
    """Schema for creating a new task (POST request body).

    The user_id is set from the JWT token, not from the request body.
    Status defaults to 'pending' and cannot be set on creation.
    Priority defaults to 'medium' if not specified.
    """

    title: str = Field(
        ...,
        min_length=1,
        max_length=255,
        description="Task title (required, 1-255 characters)",
    )
    description: str | None = Field(
        default=None,
        description="Optional task description",
    )
    priority: TaskPriority | None = Field(
        default=None,
        description="Task priority (high, medium, or low). Defaults to medium if not specified.",
    )
    tags: list[str] | None = Field(
        default=None,
        description="Optional list of tags for categorization (max 10 tags, each max 50 chars)",
    )

    model_config = {
        "json_schema_extra": {
            "examples": [
                {"title": "Buy groceries"},
                {"title": "Read book", "description": "Chapter 5-7", "priority": "high"},
                {"title": "Fix bug", "tags": ["urgent", "backend", "api"]},
            ]
        }
    }


class TaskUpdate(BaseModel):
    """Schema for updating an existing task (PATCH request body).

    All fields are optional for partial updates.
    """

    title: str | None = Field(
        default=None,
        min_length=1,
        max_length=255,
        description="Updated task title",
    )
    description: str | None = Field(
        default=None,
        description="Updated task description",
    )
    status: TaskStatus | None = Field(
        default=None,
        description="Updated task status (pending or completed)",
    )
    priority: TaskPriority | None = Field(
        default=None,
        description="Updated task priority (high, medium, or low)",
    )
    tags: list[str] | None = Field(
        default=None,
        description="Updated list of tags for categorization",
    )

    model_config = {
        "json_schema_extra": {
            "examples": [
                {"status": "completed"},
                {"title": "Updated title", "description": "New description"},
                {"priority": "high", "status": "pending"},
                {"tags": ["urgent", "backend"]},
            ]
        }
    }


class TaskResponse(BaseModel):
    """Schema for task responses (all endpoints).

    Maps directly from the Task SQLModel entity.
    """

    id: UUID = Field(description="Unique task identifier")
    user_id: str = Field(description="Owner's user ID from Better Auth")
    title: str = Field(description="Task title")
    description: str | None = Field(description="Optional task description")
    status: TaskStatus = Field(description="Task status (pending or completed)")
    priority: TaskPriority = Field(description="Task priority (high, medium, or low)")
    tags: list[str] = Field(description="List of tags for categorization")
    created_at: datetime = Field(description="Creation timestamp (UTC)")
    updated_at: datetime = Field(description="Last modification timestamp (UTC)")

    model_config = {
        "from_attributes": True,  # Enable ORM mode for SQLModel conversion
        "json_schema_extra": {
            "examples": [
                {
                    "id": "550e8400-e29b-41d4-a716-446655440000",
                    "user_id": "user-123",
                    "title": "Buy groceries",
                    "description": "Milk, eggs, bread",
                    "status": "pending",
                    "priority": "medium",
                    "tags": ["shopping", "food"],
                    "created_at": "2025-12-13T10:00:00Z",
                    "updated_at": "2025-12-13T10:00:00Z",
                }
            ]
        },
    }
