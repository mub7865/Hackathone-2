"""
Recurring Task Model Template

This template provides SQLModel definitions for recurring tasks with
scheduling patterns, next occurrence tracking, and configuration options.
"""

from sqlmodel import SQLModel, Field, Relationship
from datetime import datetime
from typing import Optional, List
from enum import Enum


# ============================================================================
# Enums
# ============================================================================

class RecurrencePattern(str, Enum):
    """Predefined recurrence patterns."""
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"
    CUSTOM = "custom"  # Uses cron expression


class MissedExecutionStrategy(str, Enum):
    """Strategy for handling missed executions."""
    SKIP = "skip"  # Skip missed executions
    RUN_ONCE = "run_once"  # Run once immediately, then continue schedule
    CATCH_UP = "catch_up"  # Run all missed executions
    COALESCE = "coalesce"  # Run once for all missed executions


class DayOfWeek(int, Enum):
    """Days of the week."""
    MONDAY = 0
    TUESDAY = 1
    WEDNESDAY = 2
    THURSDAY = 3
    FRIDAY = 4
    SATURDAY = 5
    SUNDAY = 6


# ============================================================================
# Models
# ============================================================================

class RecurringTaskBase(SQLModel):
    """Base model for recurring tasks."""
    title: str = Field(max_length=200)
    description: Optional[str] = None
    user_id: str = Field(index=True)

    # Scheduling
    pattern: RecurrencePattern = Field(default=RecurrencePattern.DAILY)
    cron_expression: Optional[str] = None  # Used when pattern is CUSTOM
    interval: int = Field(default=1, ge=1)  # Every N days/weeks/months

    # Time configuration
    hour: int = Field(default=9, ge=0, le=23)  # Hour of day (0-23)
    minute: int = Field(default=0, ge=0, le=59)  # Minute of hour (0-59)

    # Weekly configuration
    day_of_week: Optional[DayOfWeek] = None  # For weekly tasks

    # Monthly configuration
    day_of_month: Optional[int] = Field(default=None, ge=1, le=31)  # For monthly tasks

    # Date range
    start_date: datetime = Field(default_factory=datetime.utcnow)
    end_date: Optional[datetime] = None  # None = no end date

    # Execution tracking
    last_run: Optional[datetime] = None
    next_run: datetime  # Calculated on creation/update

    # Configuration
    is_active: bool = Field(default=True)
    missed_execution_strategy: MissedExecutionStrategy = Field(
        default=MissedExecutionStrategy.SKIP
    )

    # Metadata
    timezone: str = Field(default="UTC")  # User's timezone
    max_occurrences: Optional[int] = None  # Stop after N occurrences
    occurrence_count: int = Field(default=0)  # Number of times executed


class RecurringTask(RecurringTaskBase, table=True):
    """Recurring task database model."""
    __tablename__ = "recurring_tasks"

    id: Optional[int] = Field(default=None, primary_key=True)

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationships
    task_instances: List["Task"] = Relationship(back_populates="recurring_task")


class RecurringTaskCreate(RecurringTaskBase):
    """Schema for creating recurring tasks."""
    pass


class RecurringTaskUpdate(SQLModel):
    """Schema for updating recurring tasks."""
    title: Optional[str] = None
    description: Optional[str] = None
    pattern: Optional[RecurrencePattern] = None
    cron_expression: Optional[str] = None
    interval: Optional[int] = None
    hour: Optional[int] = None
    minute: Optional[int] = None
    day_of_week: Optional[DayOfWeek] = None
    day_of_month: Optional[int] = None
    end_date: Optional[datetime] = None
    is_active: Optional[bool] = None
    missed_execution_strategy: Optional[MissedExecutionStrategy] = None
    timezone: Optional[str] = None
    max_occurrences: Optional[int] = None


class RecurringTaskRead(RecurringTaskBase):
    """Schema for reading recurring tasks."""
    id: int
    created_at: datetime
    updated_at: datetime
    occurrence_count: int


# ============================================================================
# Task Instance Model (linked to recurring task)
# ============================================================================

class Task(SQLModel, table=True):
    """Task instance created from recurring task."""
    __tablename__ = "tasks"

    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    description: Optional[str] = None
    user_id: str = Field(index=True)

    # Task details
    completed: bool = Field(default=False)
    due_date: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    # Recurring task link
    is_recurring: bool = Field(default=False)
    recurring_task_id: Optional[int] = Field(default=None, foreign_key="recurring_tasks.id")
    recurring_task: Optional[RecurringTask] = Relationship(back_populates="task_instances")

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


# ============================================================================
# Execution Log Model
# ============================================================================

class RecurringTaskExecution(SQLModel, table=True):
    """Log of recurring task executions."""
    __tablename__ = "recurring_task_executions"

    id: Optional[int] = Field(default=None, primary_key=True)
    recurring_task_id: int = Field(foreign_key="recurring_tasks.id", index=True)

    # Execution details
    scheduled_time: datetime  # When it was supposed to run
    actual_time: datetime  # When it actually ran
    success: bool = Field(default=True)
    error_message: Optional[str] = None

    # Created task
    task_id: Optional[int] = Field(default=None, foreign_key="tasks.id")

    created_at: datetime = Field(default_factory=datetime.utcnow)


# ============================================================================
# Helper Functions
# ============================================================================

def validate_recurring_task(task: RecurringTaskCreate) -> None:
    """Validate recurring task configuration."""

    # Validate cron expression if pattern is CUSTOM
    if task.pattern == RecurrencePattern.CUSTOM:
        if not task.cron_expression:
            raise ValueError("cron_expression required for CUSTOM pattern")

        # Validate cron syntax
        from croniter import croniter
        if not croniter.is_valid(task.cron_expression):
            raise ValueError(f"Invalid cron expression: {task.cron_expression}")

    # Validate weekly configuration
    if task.pattern == RecurrencePattern.WEEKLY:
        if task.day_of_week is None:
            raise ValueError("day_of_week required for WEEKLY pattern")

    # Validate monthly configuration
    if task.pattern == RecurrencePattern.MONTHLY:
        if task.day_of_month is None:
            raise ValueError("day_of_month required for MONTHLY pattern")

    # Validate date range
    if task.end_date and task.end_date <= task.start_date:
        raise ValueError("end_date must be after start_date")

    # Validate max occurrences
    if task.max_occurrences is not None and task.max_occurrences <= 0:
        raise ValueError("max_occurrences must be positive")


def should_stop_recurring_task(task: RecurringTask) -> bool:
    """Check if recurring task should stop."""

    # Check if end date reached
    if task.end_date and datetime.utcnow() >= task.end_date:
        return True

    # Check if max occurrences reached
    if task.max_occurrences and task.occurrence_count >= task.max_occurrences:
        return True

    return False


# ============================================================================
# Usage Example
# ============================================================================

if __name__ == "__main__":
    # Create daily recurring task
    daily_task = RecurringTaskCreate(
        title="Daily standup reminder",
        description="Reminder for daily standup meeting",
        user_id="user_123",
        pattern=RecurrencePattern.DAILY,
        hour=9,
        minute=0,
        start_date=datetime(2024, 1, 1, 9, 0),
        timezone="America/New_York"
    )

    # Create weekly recurring task
    weekly_task = RecurringTaskCreate(
        title="Weekly report",
        description="Submit weekly progress report",
        user_id="user_123",
        pattern=RecurrencePattern.WEEKLY,
        day_of_week=DayOfWeek.FRIDAY,
        hour=17,
        minute=0,
        start_date=datetime(2024, 1, 5, 17, 0),
        timezone="America/New_York"
    )

    # Create monthly recurring task
    monthly_task = RecurringTaskCreate(
        title="Monthly review",
        description="Monthly performance review",
        user_id="user_123",
        pattern=RecurrencePattern.MONTHLY,
        day_of_month=1,
        hour=9,
        minute=0,
        start_date=datetime(2024, 1, 1, 9, 0),
        timezone="America/New_York"
    )

    # Create custom cron recurring task
    custom_task = RecurringTaskCreate(
        title="Custom schedule",
        description="Runs every 15 minutes",
        user_id="user_123",
        pattern=RecurrencePattern.CUSTOM,
        cron_expression="*/15 * * * *",
        start_date=datetime.utcnow(),
        timezone="UTC"
    )

    # Validate tasks
    validate_recurring_task(daily_task)
    validate_recurring_task(weekly_task)
    validate_recurring_task(monthly_task)
    validate_recurring_task(custom_task)

    print("All recurring tasks validated successfully!")
