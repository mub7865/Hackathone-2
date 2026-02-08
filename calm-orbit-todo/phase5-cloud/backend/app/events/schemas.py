"""Event validation schemas for ensuring event structure consistency.

This module defines Pydantic schemas for validating event payloads
before publishing and after consuming.
"""

from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


class EventEnvelope(BaseModel):
    """Base event envelope structure.

    All events follow this envelope format for consistency.
    """

    event_type: str = Field(..., description="Type of event (e.g., 'task.created')")
    event_id: str = Field(..., description="Unique event identifier (UUID)")
    timestamp: str = Field(..., description="ISO 8601 timestamp when event was created")
    data: Dict[str, Any] = Field(..., description="Event payload")

    @field_validator("timestamp")
    @classmethod
    def validate_timestamp(cls, v: str) -> str:
        """Validate timestamp is valid ISO 8601 format."""
        try:
            datetime.fromisoformat(v.replace("Z", "+00:00"))
        except ValueError:
            raise ValueError(f"Invalid ISO 8601 timestamp: {v}")
        return v


class TaskCreatedEvent(BaseModel):
    """Schema for task.created event payload."""

    task_id: str = Field(..., description="Task UUID")
    user_id: str = Field(..., description="User who created the task")
    title: str = Field(..., min_length=1, max_length=200, description="Task title")
    description: Optional[str] = Field(default=None, description="Task description")
    priority: Optional[str] = Field(default=None, description="Task priority (high, medium, low)")
    tags: List[str] = Field(default_factory=list, description="Task tags")

    @field_validator("task_id", "user_id")
    @classmethod
    def validate_uuid(cls, v: str) -> str:
        """Validate UUID format."""
        try:
            UUID(v)
        except ValueError:
            raise ValueError(f"Invalid UUID: {v}")
        return v

    @field_validator("priority")
    @classmethod
    def validate_priority(cls, v: Optional[str]) -> Optional[str]:
        """Validate priority value."""
        if v is not None and v not in ["high", "medium", "low"]:
            raise ValueError(f"Invalid priority: {v}")
        return v


class TaskUpdatedEvent(BaseModel):
    """Schema for task.updated event payload."""

    task_id: str = Field(..., description="Task UUID")
    user_id: str = Field(..., description="User who updated the task")
    updates: Dict[str, Any] = Field(..., description="Dictionary of updated fields")

    @field_validator("task_id", "user_id")
    @classmethod
    def validate_uuid(cls, v: str) -> str:
        """Validate UUID format."""
        try:
            UUID(v)
        except ValueError:
            raise ValueError(f"Invalid UUID: {v}")
        return v


class TaskDeletedEvent(BaseModel):
    """Schema for task.deleted event payload."""

    task_id: str = Field(..., description="Task UUID")
    user_id: str = Field(..., description="User who deleted the task")

    @field_validator("task_id", "user_id")
    @classmethod
    def validate_uuid(cls, v: str) -> str:
        """Validate UUID format."""
        try:
            UUID(v)
        except ValueError:
            raise ValueError(f"Invalid UUID: {v}")
        return v


class TaskCompletedEvent(BaseModel):
    """Schema for task.completed event payload."""

    task_id: str = Field(..., description="Task UUID")
    user_id: str = Field(..., description="User who completed the task")

    @field_validator("task_id", "user_id")
    @classmethod
    def validate_uuid(cls, v: str) -> str:
        """Validate UUID format."""
        try:
            UUID(v)
        except ValueError:
            raise ValueError(f"Invalid UUID: {v}")
        return v


class ReminderDueEvent(BaseModel):
    """Schema for reminder.due event payload."""

    task_id: str = Field(..., description="Task UUID")
    user_id: str = Field(..., description="User to remind")
    title: str = Field(..., min_length=1, max_length=200, description="Task title")
    due_date: str = Field(..., description="ISO 8601 due date")

    @field_validator("task_id", "user_id")
    @classmethod
    def validate_uuid(cls, v: str) -> str:
        """Validate UUID format."""
        try:
            UUID(v)
        except ValueError:
            raise ValueError(f"Invalid UUID: {v}")
        return v

    @field_validator("due_date")
    @classmethod
    def validate_due_date(cls, v: str) -> str:
        """Validate due date is valid ISO 8601 format."""
        try:
            datetime.fromisoformat(v.replace("Z", "+00:00"))
        except ValueError:
            raise ValueError(f"Invalid ISO 8601 date: {v}")
        return v


class RecurringTaskGeneratedEvent(BaseModel):
    """Schema for recurring_task.generated event payload."""

    pattern_id: str = Field(..., description="Recurring pattern UUID")
    task_id: str = Field(..., description="Generated task UUID")
    user_id: str = Field(..., description="User who owns the task")
    title: str = Field(..., min_length=1, max_length=200, description="Task title")

    @field_validator("pattern_id", "task_id", "user_id")
    @classmethod
    def validate_uuid(cls, v: str) -> str:
        """Validate UUID format."""
        try:
            UUID(v)
        except ValueError:
            raise ValueError(f"Invalid UUID: {v}")
        return v


# Event type to schema mapping
EVENT_SCHEMAS = {
    "task.created": TaskCreatedEvent,
    "task.updated": TaskUpdatedEvent,
    "task.deleted": TaskDeletedEvent,
    "task.completed": TaskCompletedEvent,
    "reminder.due": ReminderDueEvent,
    "recurring_task.generated": RecurringTaskGeneratedEvent,
}


def validate_event(event_type: str, event_data: Dict[str, Any]) -> bool:
    """Validate event data against its schema.

    Args:
        event_type: Type of event
        event_data: Event payload to validate

    Returns:
        True if valid, False otherwise

    Raises:
        ValueError: If validation fails
    """
    schema = EVENT_SCHEMAS.get(event_type)
    if schema is None:
        raise ValueError(f"Unknown event type: {event_type}")

    try:
        schema(**event_data)
        return True
    except Exception as e:
        raise ValueError(f"Event validation failed: {e}")


def validate_event_envelope(event: Dict[str, Any]) -> bool:
    """Validate event envelope structure.

    Args:
        event: Event envelope to validate

    Returns:
        True if valid, False otherwise

    Raises:
        ValueError: If validation fails
    """
    try:
        envelope = EventEnvelope(**event)
        # Also validate the payload
        validate_event(envelope.event_type, envelope.data)
        return True
    except Exception as e:
        raise ValueError(f"Event envelope validation failed: {e}")
