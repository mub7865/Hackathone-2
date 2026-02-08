"""
Event Schema Definitions

This template provides Pydantic models for event schemas with validation.
"""

from pydantic import BaseModel, Field, validator
from datetime import datetime
from typing import Optional, Dict, Any, Literal
from enum import Enum


# Event Types
class EventType(str, Enum):
    """Standard event types for task operations."""
    CREATED = "created"
    UPDATED = "updated"
    COMPLETED = "completed"
    DELETED = "deleted"
    ASSIGNED = "assigned"
    COMMENTED = "commented"


class Priority(str, Enum):
    """Task priority levels."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class RecurrencePattern(str, Enum):
    """Recurrence patterns for recurring tasks."""
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"


# Base Event Schema
class BaseEvent(BaseModel):
    """
    Base event schema with common fields.
    All events should inherit from this.
    """
    event_id: str = Field(..., description="Unique event identifier")
    event_type: str = Field(..., description="Type of event")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Event timestamp")
    version: str = Field(default="1.0", description="Event schema version")
    source: str = Field(..., description="Service that generated the event")

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


# Task Events
class TaskEventData(BaseModel):
    """Task data included in events."""
    id: int
    title: str
    description: Optional[str] = None
    status: str
    priority: Optional[Priority] = None
    tags: list[str] = []
    due_date: Optional[datetime] = None
    is_recurring: bool = False
    recurrence_pattern: Optional[RecurrencePattern] = None
    created_at: datetime
    updated_at: datetime


class TaskEvent(BaseEvent):
    """
    Event for task operations.

    Example:
        event = TaskEvent(
            event_id="evt_123",
            event_type=EventType.CREATED,
            source="task-service",
            user_id="user_456",
            task_id=789,
            task_data=TaskEventData(...)
        )
    """
    event_type: EventType
    user_id: str = Field(..., description="User who performed the action")
    task_id: int = Field(..., description="Task identifier")
    task_data: TaskEventData = Field(..., description="Task details")

    @validator('event_type')
    def validate_event_type(cls, v):
        """Ensure event_type is valid."""
        if v not in EventType.__members__.values():
            raise ValueError(f"Invalid event_type: {v}")
        return v


# Reminder Events
class ReminderEvent(BaseEvent):
    """
    Event for task reminders.

    Example:
        event = ReminderEvent(
            event_id="evt_123",
            event_type="reminder",
            source="reminder-service",
            task_id=789,
            user_id="user_456",
            title="Complete project report",
            due_at=datetime.now(),
            remind_at=datetime.now()
        )
    """
    event_type: Literal["reminder"] = "reminder"
    task_id: int
    user_id: str
    title: str
    due_at: datetime
    remind_at: datetime
    notification_type: Literal["email", "push", "sms"] = "email"


# Notification Events
class NotificationEvent(BaseEvent):
    """
    Generic notification event.

    Example:
        event = NotificationEvent(
            event_id="evt_123",
            event_type="notification",
            source="notification-service",
            user_id="user_456",
            notification_type="email",
            subject="Task Reminder",
            message="Your task is due soon"
        )
    """
    event_type: Literal["notification"] = "notification"
    user_id: str
    notification_type: Literal["email", "push", "sms"]
    subject: str
    message: str
    metadata: Dict[str, Any] = {}


# Audit Events
class AuditEvent(BaseEvent):
    """
    Event for audit logging.

    Example:
        event = AuditEvent(
            event_id="evt_123",
            event_type="audit",
            source="task-service",
            user_id="user_456",
            action="task.created",
            resource_type="task",
            resource_id="789",
            changes={"title": "New Task"}
        )
    """
    event_type: Literal["audit"] = "audit"
    user_id: str
    action: str = Field(..., description="Action performed (e.g., 'task.created')")
    resource_type: str = Field(..., description="Type of resource (e.g., 'task')")
    resource_id: str = Field(..., description="Resource identifier")
    changes: Dict[str, Any] = Field(default={}, description="Changes made")
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None


# Recurring Task Events
class RecurringTaskEvent(BaseEvent):
    """
    Event for recurring task operations.

    Example:
        event = RecurringTaskEvent(
            event_id="evt_123",
            event_type="recurring_task_completed",
            source="task-service",
            original_task_id=789,
            user_id="user_456",
            recurrence_pattern=RecurrencePattern.WEEKLY,
            next_occurrence_date=datetime.now()
        )
    """
    event_type: Literal["recurring_task_completed"] = "recurring_task_completed"
    original_task_id: int
    user_id: str
    recurrence_pattern: RecurrencePattern
    next_occurrence_date: datetime
    task_template: TaskEventData


# Error Events
class ErrorEvent(BaseEvent):
    """
    Event for error tracking.

    Example:
        event = ErrorEvent(
            event_id="evt_123",
            event_type="error",
            source="task-service",
            error_type="ValidationError",
            error_message="Invalid task data",
            context={"task_id": 789}
        )
    """
    event_type: Literal["error"] = "error"
    error_type: str
    error_message: str
    stack_trace: Optional[str] = None
    context: Dict[str, Any] = {}
    severity: Literal["low", "medium", "high", "critical"] = "medium"


# Event Factory
class EventFactory:
    """
    Factory for creating events with automatic ID generation.

    Usage:
        factory = EventFactory(source="task-service")
        event = factory.create_task_event(
            event_type=EventType.CREATED,
            user_id="user_456",
            task_id=789,
            task_data=task_data
        )
    """

    def __init__(self, source: str):
        self.source = source

    def _generate_event_id(self) -> str:
        """Generate unique event ID."""
        import uuid
        return f"evt_{uuid.uuid4().hex[:12]}"

    def create_task_event(
        self,
        event_type: EventType,
        user_id: str,
        task_id: int,
        task_data: TaskEventData
    ) -> TaskEvent:
        """Create a task event."""
        return TaskEvent(
            event_id=self._generate_event_id(),
            event_type=event_type,
            source=self.source,
            user_id=user_id,
            task_id=task_id,
            task_data=task_data
        )

    def create_reminder_event(
        self,
        task_id: int,
        user_id: str,
        title: str,
        due_at: datetime,
        remind_at: datetime,
        notification_type: str = "email"
    ) -> ReminderEvent:
        """Create a reminder event."""
        return ReminderEvent(
            event_id=self._generate_event_id(),
            source=self.source,
            task_id=task_id,
            user_id=user_id,
            title=title,
            due_at=due_at,
            remind_at=remind_at,
            notification_type=notification_type
        )

    def create_notification_event(
        self,
        user_id: str,
        notification_type: str,
        subject: str,
        message: str,
        metadata: Dict[str, Any] = None
    ) -> NotificationEvent:
        """Create a notification event."""
        return NotificationEvent(
            event_id=self._generate_event_id(),
            source=self.source,
            user_id=user_id,
            notification_type=notification_type,
            subject=subject,
            message=message,
            metadata=metadata or {}
        )

    def create_audit_event(
        self,
        user_id: str,
        action: str,
        resource_type: str,
        resource_id: str,
        changes: Dict[str, Any] = None
    ) -> AuditEvent:
        """Create an audit event."""
        return AuditEvent(
            event_id=self._generate_event_id(),
            source=self.source,
            user_id=user_id,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            changes=changes or {}
        )


# Event Validator
def validate_event(event_data: dict) -> BaseEvent:
    """
    Validate and parse event data into appropriate event type.

    Args:
        event_data: Raw event dictionary

    Returns:
        Parsed event object

    Raises:
        ValueError: If event type is unknown or validation fails
    """
    event_type = event_data.get('event_type')

    event_map = {
        'created': TaskEvent,
        'updated': TaskEvent,
        'completed': TaskEvent,
        'deleted': TaskEvent,
        'reminder': ReminderEvent,
        'notification': NotificationEvent,
        'audit': AuditEvent,
        'recurring_task_completed': RecurringTaskEvent,
        'error': ErrorEvent,
    }

    event_class = event_map.get(event_type)
    if not event_class:
        raise ValueError(f"Unknown event type: {event_type}")

    return event_class(**event_data)
