"""Recurring patterns model for recurring tasks.

This module defines the RecurringPattern entity for managing task recurrence rules.
"""

from datetime import datetime
from enum import Enum
from typing import TYPE_CHECKING, List, Optional
from uuid import UUID, uuid4

from sqlalchemy import CheckConstraint, Column, DateTime, Index, Integer, String, ARRAY
from sqlmodel import Field, SQLModel

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession


class RecurrenceFrequency(str, Enum):
    """Valid recurrence frequencies.

    Attributes:
        DAILY: Task recurs daily.
        WEEKLY: Task recurs weekly.
        MONTHLY: Task recurs monthly.
        YEARLY: Task recurs yearly.
        CUSTOM: Task recurs based on custom cron expression.
    """

    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"
    CUSTOM = "custom"


class EndCondition(str, Enum):
    """Valid end conditions for recurring patterns.

    Attributes:
        DATE: Pattern ends on a specific date.
        COUNT: Pattern ends after a specific number of occurrences.
        INDEFINITE: Pattern continues indefinitely.
    """

    DATE = "date"
    COUNT = "count"
    INDEFINITE = "indefinite"


class RecurringPattern(SQLModel, table=True):
    """Represents a recurrence rule for recurring tasks.

    Invariants:
        - Every pattern belongs to exactly one user (user_id NOT NULL)
        - Frequency is constrained to valid values
        - End condition is constrained to valid values
        - Interval must be positive
        - Day of month must be between -1 and 31
        - Month of year must be between 1 and 12
        - Occurrence count must be positive if set

    Attributes:
        id: Unique pattern identifier (UUID, auto-generated).
        user_id: Owner's Better Auth user ID (UUID string, max 36 chars).
        original_task_id: Reference to the first task in the series.
        frequency: Recurrence frequency (daily, weekly, monthly, yearly, custom).
        interval: Interval for recurrence (e.g., every N days).
        days_of_week: Array of weekday numbers (0=Sunday, 6=Saturday) for weekly recurrence.
        day_of_month: Day of month (1-31, or -1 for last day) for monthly recurrence.
        month_of_year: Month number (1-12) for yearly recurrence.
        cron_expression: Cron expression for custom recurrence.
        end_condition: How the pattern ends (date, count, indefinite).
        end_date: End date for date-based end condition.
        occurrence_count: Total number of occurrences for count-based end condition.
        current_count: Current occurrence number.
        created_at: Creation timestamp (immutable, auto-set).
        updated_at: Last modification timestamp (auto-updated).
    """

    __tablename__ = "recurring_patterns"
    __table_args__ = (
        CheckConstraint(
            "frequency IN ('daily', 'weekly', 'monthly', 'yearly', 'custom')",
            name="chk_frequency",
        ),
        CheckConstraint(
            "end_condition IN ('date', 'count', 'indefinite')",
            name="chk_end_condition",
        ),
        CheckConstraint("interval > 0", name="chk_interval_positive"),
        CheckConstraint(
            "day_of_month BETWEEN -1 AND 31 OR day_of_month IS NULL",
            name="chk_day_of_month",
        ),
        CheckConstraint(
            "month_of_year BETWEEN 1 AND 12 OR month_of_year IS NULL",
            name="chk_month_of_year",
        ),
        CheckConstraint(
            "occurrence_count IS NULL OR occurrence_count > 0",
            name="chk_occurrence_count",
        ),
        Index("ix_recurring_patterns_user_id", "user_id"),
        Index("ix_recurring_patterns_original_task_id", "original_task_id"),
    )

    # Primary key
    id: UUID = Field(
        default_factory=uuid4,
        primary_key=True,
        nullable=False,
        description="Unique pattern identifier",
    )

    # Owner reference (Better Auth user ID)
    user_id: str = Field(
        ...,
        max_length=36,
        nullable=False,
        index=True,
        description="Owner's Better Auth user ID (UUID string)",
    )

    # Original task reference
    original_task_id: UUID = Field(
        ...,
        nullable=False,
        description="Reference to the first task in the series",
    )

    # Recurrence configuration
    frequency: RecurrenceFrequency = Field(
        ...,
        sa_column=Column(
            String(20),
            nullable=False,
        ),
        description="Recurrence frequency",
    )

    interval: int = Field(
        default=1,
        nullable=False,
        description="Interval for recurrence (e.g., every N days)",
    )

    days_of_week: Optional[List[int]] = Field(
        default=None,
        sa_column=Column(
            ARRAY(Integer),
            nullable=True,
        ),
        description="Array of weekday numbers (0=Sunday, 6=Saturday)",
    )

    day_of_month: Optional[int] = Field(
        default=None,
        nullable=True,
        description="Day of month (1-31, or -1 for last day)",
    )

    month_of_year: Optional[int] = Field(
        default=None,
        nullable=True,
        description="Month number (1-12)",
    )

    cron_expression: Optional[str] = Field(
        default=None,
        max_length=100,
        nullable=True,
        description="Cron expression for custom recurrence",
    )

    # End condition configuration
    end_condition: EndCondition = Field(
        ...,
        sa_column=Column(
            String(20),
            nullable=False,
        ),
        description="How the pattern ends",
    )

    end_date: Optional[datetime] = Field(
        default=None,
        sa_column=Column(
            DateTime(timezone=True),
            nullable=True,
        ),
        description="End date for date-based end condition",
    )

    occurrence_count: Optional[int] = Field(
        default=None,
        nullable=True,
        description="Total number of occurrences for count-based end condition",
    )

    current_count: int = Field(
        default=0,
        nullable=False,
        description="Current occurrence number",
    )

    # Timestamps
    created_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            server_default="NOW()",
            nullable=False,
        ),
        description="Creation timestamp (immutable)",
    )

    updated_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            server_default="NOW()",
            nullable=False,
        ),
        description="Last modification timestamp",
    )
