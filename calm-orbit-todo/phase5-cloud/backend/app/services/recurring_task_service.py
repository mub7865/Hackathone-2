"""Recurring task service for managing recurring task patterns.

This module provides business logic for creating, updating, and managing
recurring task patterns and their generated task instances.
"""

import logging
from datetime import datetime, timedelta
from typing import List, Optional
from uuid import UUID

from croniter import croniter
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.models.recurring_patterns import (
    EndCondition,
    RecurringPattern,
    RecurrenceFrequency,
)
from app.models.task import Task, TaskPriority, TaskStatus

logger = logging.getLogger(__name__)


class RecurringTaskService:
    """Service for managing recurring task patterns and instances."""

    def __init__(self, session: AsyncSession):
        """Initialize the recurring task service.

        Args:
            session: Database session.
        """
        self.session = session

    async def create_recurring_pattern(
        self,
        user_id: str,
        original_task_id: UUID,
        frequency: RecurrenceFrequency,
        interval: int = 1,
        days_of_week: Optional[List[int]] = None,
        day_of_month: Optional[int] = None,
        month_of_year: Optional[int] = None,
        cron_expression: Optional[str] = None,
        end_condition: EndCondition = EndCondition.INDEFINITE,
        end_date: Optional[datetime] = None,
        occurrence_count: Optional[int] = None,
    ) -> RecurringPattern:
        """Create a new recurring pattern.

        Args:
            user_id: Owner's user ID.
            original_task_id: ID of the original task.
            frequency: Recurrence frequency.
            interval: Interval for recurrence.
            days_of_week: Weekday numbers for weekly recurrence.
            day_of_month: Day of month for monthly recurrence.
            month_of_year: Month number for yearly recurrence.
            cron_expression: Cron expression for custom recurrence.
            end_condition: How the pattern ends.
            end_date: End date for date-based end condition.
            occurrence_count: Total occurrences for count-based end condition.

        Returns:
            Created RecurringPattern instance.

        Raises:
            ValueError: If validation fails.
        """
        # Validate frequency-specific fields
        if frequency == RecurrenceFrequency.WEEKLY and not days_of_week:
            raise ValueError("days_of_week is required for weekly recurrence")
        if frequency == RecurrenceFrequency.MONTHLY and day_of_month is None:
            raise ValueError("day_of_month is required for monthly recurrence")
        if frequency == RecurrenceFrequency.YEARLY and (
            day_of_month is None or month_of_year is None
        ):
            raise ValueError(
                "day_of_month and month_of_year are required for yearly recurrence"
            )
        if frequency == RecurrenceFrequency.CUSTOM and not cron_expression:
            raise ValueError("cron_expression is required for custom recurrence")

        # Validate end condition fields
        if end_condition == EndCondition.DATE and not end_date:
            raise ValueError("end_date is required for date-based end condition")
        if end_condition == EndCondition.COUNT and not occurrence_count:
            raise ValueError(
                "occurrence_count is required for count-based end condition"
            )

        # Validate cron expression if provided
        if cron_expression:
            try:
                croniter(cron_expression)
            except Exception as e:
                raise ValueError(f"Invalid cron expression: {e}")

        # Create pattern
        pattern = RecurringPattern(
            user_id=user_id,
            original_task_id=original_task_id,
            frequency=frequency,
            interval=interval,
            days_of_week=days_of_week,
            day_of_month=day_of_month,
            month_of_year=month_of_year,
            cron_expression=cron_expression,
            end_condition=end_condition,
            end_date=end_date,
            occurrence_count=occurrence_count,
            current_count=0,
        )

        self.session.add(pattern)
        await self.session.flush()
        await self.session.refresh(pattern)

        logger.info(f"Created recurring pattern {pattern.id} for user {user_id}")
        return pattern

    async def get_pattern_by_id(
        self, pattern_id: UUID, user_id: str
    ) -> Optional[RecurringPattern]:
        """Get a recurring pattern by ID.

        Args:
            pattern_id: Pattern UUID.
            user_id: User ID for ownership check.

        Returns:
            RecurringPattern if found and owned by user, None otherwise.
        """
        statement = select(RecurringPattern).where(
            RecurringPattern.id == pattern_id, RecurringPattern.user_id == user_id
        )
        result = await self.session.execute(statement)
        return result.scalar_one_or_none()

    async def get_patterns_by_user(self, user_id: str) -> List[RecurringPattern]:
        """Get all recurring patterns for a user.

        Args:
            user_id: User ID.

        Returns:
            List of RecurringPattern instances.
        """
        statement = select(RecurringPattern).where(
            RecurringPattern.user_id == user_id
        )
        result = await self.session.execute(statement)
        return list(result.scalars().all())

    async def calculate_next_occurrence(
        self, pattern: RecurringPattern, base_date: Optional[datetime] = None
    ) -> Optional[datetime]:
        """Calculate the next occurrence date for a recurring pattern.

        Args:
            pattern: RecurringPattern instance.
            base_date: Base date to calculate from (defaults to now).

        Returns:
            Next occurrence datetime, or None if pattern has ended.
        """
        if base_date is None:
            base_date = datetime.utcnow()

        # Check if pattern has ended
        if pattern.end_condition == EndCondition.DATE:
            if pattern.end_date and base_date >= pattern.end_date:
                return None
        elif pattern.end_condition == EndCondition.COUNT:
            if (
                pattern.occurrence_count
                and pattern.current_count >= pattern.occurrence_count
            ):
                return None

        # Calculate next occurrence based on frequency
        if pattern.frequency == RecurrenceFrequency.DAILY:
            return base_date + timedelta(days=pattern.interval)

        elif pattern.frequency == RecurrenceFrequency.WEEKLY:
            # Find next occurrence on specified weekdays
            if not pattern.days_of_week:
                return None

            next_date = base_date
            for _ in range(7 * pattern.interval):
                next_date += timedelta(days=1)
                if next_date.weekday() in [
                    (d - 1) % 7 for d in pattern.days_of_week
                ]:  # Convert Sunday=0 to Monday=0
                    return next_date
            return None

        elif pattern.frequency == RecurrenceFrequency.MONTHLY:
            # Calculate next month occurrence
            if pattern.day_of_month is None:
                return None

            next_date = base_date
            for _ in range(pattern.interval):
                # Move to next month
                if next_date.month == 12:
                    next_date = next_date.replace(year=next_date.year + 1, month=1)
                else:
                    next_date = next_date.replace(month=next_date.month + 1)

            # Handle last day of month
            if pattern.day_of_month == -1:
                # Get last day of month
                if next_date.month == 12:
                    last_day = 31
                else:
                    next_month = next_date.replace(month=next_date.month + 1, day=1)
                    last_day = (next_month - timedelta(days=1)).day
                return next_date.replace(day=last_day)
            else:
                return next_date.replace(day=min(pattern.day_of_month, 31))

        elif pattern.frequency == RecurrenceFrequency.YEARLY:
            # Calculate next year occurrence
            if pattern.day_of_month is None or pattern.month_of_year is None:
                return None

            next_date = base_date.replace(
                year=base_date.year + pattern.interval,
                month=pattern.month_of_year,
                day=pattern.day_of_month,
            )
            return next_date

        elif pattern.frequency == RecurrenceFrequency.CUSTOM:
            # Use croniter for custom cron expressions
            if not pattern.cron_expression:
                return None

            try:
                cron = croniter(pattern.cron_expression, base_date)
                return cron.get_next(datetime)
            except Exception as e:
                logger.error(f"Error calculating next occurrence with cron: {e}")
                return None

        return None

    async def generate_next_task_instance(
        self, pattern: RecurringPattern
    ) -> Optional[Task]:
        """Generate the next task instance for a recurring pattern.

        Args:
            pattern: RecurringPattern instance.

        Returns:
            Created Task instance, or None if pattern has ended.
        """
        # Calculate next occurrence
        next_date = await self.calculate_next_occurrence(pattern)
        if next_date is None:
            logger.info(f"Pattern {pattern.id} has ended, no more occurrences")
            return None

        # Get original task to copy properties
        statement = select(Task).where(Task.id == pattern.original_task_id)
        result = await self.session.execute(statement)
        original_task = result.scalar_one_or_none()

        if original_task is None:
            logger.error(
                f"Original task {pattern.original_task_id} not found for pattern {pattern.id}"
            )
            return None

        # Create new task instance
        new_task = Task(
            user_id=pattern.user_id,
            title=original_task.title,
            description=original_task.description,
            status=TaskStatus.PENDING,
            priority=original_task.priority,
            tags=original_task.tags,
            due_date=next_date,
            remind_at=None,  # Will be set by reminder service if needed
            recurring_pattern_id=pattern.id,
        )

        self.session.add(new_task)
        await self.session.flush()
        await self.session.refresh(new_task)

        # Update pattern current count
        pattern.current_count += 1
        await self.session.flush()

        logger.info(
            f"Generated task instance {new_task.id} for pattern {pattern.id} (occurrence {pattern.current_count})"
        )
        return new_task

    async def delete_pattern(self, pattern_id: UUID, user_id: str) -> bool:
        """Delete a recurring pattern.

        Args:
            pattern_id: Pattern UUID.
            user_id: User ID for ownership check.

        Returns:
            True if deleted, False if not found or not owned.
        """
        pattern = await self.get_pattern_by_id(pattern_id, user_id)
        if pattern is None:
            return False

        await self.session.delete(pattern)
        await self.session.flush()

        logger.info(f"Deleted recurring pattern {pattern_id}")
        return True

    async def update_pattern(
        self,
        pattern_id: UUID,
        user_id: str,
        updates: dict,
    ) -> Optional[RecurringPattern]:
        """Update a recurring pattern.

        Args:
            pattern_id: Pattern UUID.
            user_id: User ID for ownership check.
            updates: Dictionary of fields to update.

        Returns:
            Updated RecurringPattern if found and owned, None otherwise.
        """
        pattern = await self.get_pattern_by_id(pattern_id, user_id)
        if pattern is None:
            return None

        # Apply allowed updates
        allowed_fields = {
            "interval",
            "days_of_week",
            "day_of_month",
            "month_of_year",
            "cron_expression",
            "end_condition",
            "end_date",
            "occurrence_count",
        }

        for field, value in updates.items():
            if field in allowed_fields:
                setattr(pattern, field, value)

        await self.session.flush()
        await self.session.refresh(pattern)

        logger.info(f"Updated recurring pattern {pattern_id}")
        return pattern
