"""Reminder service for managing task reminders and notifications.

This module provides business logic for scheduling reminders, checking due tasks,
and triggering notifications for upcoming deadlines.
"""

import logging
from datetime import datetime, timedelta
from typing import List, Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.models.task import Task, TaskStatus

logger = logging.getLogger(__name__)


class ReminderService:
    """Service for managing task reminders and notifications."""

    def __init__(self, session: AsyncSession):
        """Initialize the reminder service.

        Args:
            session: Database session.
        """
        self.session = session

    async def get_tasks_with_upcoming_reminders(
        self, time_window_minutes: int = 60
    ) -> List[Task]:
        """Get tasks with reminders due within the specified time window.

        Args:
            time_window_minutes: Time window in minutes to check for reminders.

        Returns:
            List of Task instances with upcoming reminders.
        """
        now = datetime.utcnow()
        window_end = now + timedelta(minutes=time_window_minutes)

        statement = (
            select(Task)
            .where(
                Task.status == TaskStatus.PENDING,
                Task.remind_at.isnot(None),
                Task.remind_at <= window_end,
                Task.remind_at > now,
            )
            .order_by(Task.remind_at)
        )

        result = await self.session.execute(statement)
        return list(result.scalars().all())

    async def get_overdue_tasks(self, user_id: Optional[str] = None) -> List[Task]:
        """Get tasks that are overdue (past due date).

        Args:
            user_id: Optional user ID to filter by specific user.

        Returns:
            List of overdue Task instances.
        """
        now = datetime.utcnow()

        statement = select(Task).where(
            Task.status == TaskStatus.PENDING,
            Task.due_date.isnot(None),
            Task.due_date < now,
        )

        if user_id:
            statement = statement.where(Task.user_id == user_id)

        statement = statement.order_by(Task.due_date)

        result = await self.session.execute(statement)
        return list(result.scalars().all())

    async def get_tasks_due_today(self, user_id: Optional[str] = None) -> List[Task]:
        """Get tasks due today.

        Args:
            user_id: Optional user ID to filter by specific user.

        Returns:
            List of Task instances due today.
        """
        now = datetime.utcnow()
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        today_end = today_start + timedelta(days=1)

        statement = select(Task).where(
            Task.status == TaskStatus.PENDING,
            Task.due_date.isnot(None),
            Task.due_date >= today_start,
            Task.due_date < today_end,
        )

        if user_id:
            statement = statement.where(Task.user_id == user_id)

        statement = statement.order_by(Task.due_date)

        result = await self.session.execute(statement)
        return list(result.scalars().all())

    async def get_tasks_due_this_week(
        self, user_id: Optional[str] = None
    ) -> List[Task]:
        """Get tasks due this week.

        Args:
            user_id: Optional user ID to filter by specific user.

        Returns:
            List of Task instances due this week.
        """
        now = datetime.utcnow()
        week_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        week_end = week_start + timedelta(days=7)

        statement = select(Task).where(
            Task.status == TaskStatus.PENDING,
            Task.due_date.isnot(None),
            Task.due_date >= week_start,
            Task.due_date < week_end,
        )

        if user_id:
            statement = statement.where(Task.user_id == user_id)

        statement = statement.order_by(Task.due_date)

        result = await self.session.execute(statement)
        return list(result.scalars().all())

    async def set_reminder(
        self, task_id: UUID, user_id: str, remind_at: datetime
    ) -> Optional[Task]:
        """Set a reminder for a task.

        Args:
            task_id: Task UUID.
            user_id: User ID for ownership check.
            remind_at: Reminder datetime.

        Returns:
            Updated Task if found and owned, None otherwise.

        Raises:
            ValueError: If remind_at is in the past or after due_date.
        """
        # Get task
        statement = select(Task).where(Task.id == task_id, Task.user_id == user_id)
        result = await self.session.execute(statement)
        task = result.scalar_one_or_none()

        if task is None:
            return None

        # Validate remind_at
        now = datetime.utcnow()
        if remind_at <= now:
            raise ValueError("Reminder time must be in the future")

        if task.due_date and remind_at >= task.due_date:
            raise ValueError("Reminder time must be before due date")

        # Update task
        task.remind_at = remind_at
        await self.session.flush()
        await self.session.refresh(task)

        logger.info(f"Set reminder for task {task_id} at {remind_at}")
        return task

    async def clear_reminder(
        self, task_id: UUID, user_id: str
    ) -> Optional[Task]:
        """Clear the reminder for a task.

        Args:
            task_id: Task UUID.
            user_id: User ID for ownership check.

        Returns:
            Updated Task if found and owned, None otherwise.
        """
        # Get task
        statement = select(Task).where(Task.id == task_id, Task.user_id == user_id)
        result = await self.session.execute(statement)
        task = result.scalar_one_or_none()

        if task is None:
            return None

        # Clear reminder
        task.remind_at = None
        await self.session.flush()
        await self.session.refresh(task)

        logger.info(f"Cleared reminder for task {task_id}")
        return task

    async def calculate_suggested_reminder(
        self, due_date: datetime, advance_hours: int = 24
    ) -> datetime:
        """Calculate a suggested reminder time based on due date.

        Args:
            due_date: Task due date.
            advance_hours: Hours before due date to remind (default: 24).

        Returns:
            Suggested reminder datetime.
        """
        reminder_time = due_date - timedelta(hours=advance_hours)

        # Ensure reminder is not in the past
        now = datetime.utcnow()
        if reminder_time <= now:
            # If calculated reminder is in the past, set it to 1 hour from now
            reminder_time = now + timedelta(hours=1)

        return reminder_time

    async def get_reminder_statistics(self, user_id: str) -> dict:
        """Get reminder statistics for a user.

        Args:
            user_id: User ID.

        Returns:
            Dictionary with reminder statistics.
        """
        now = datetime.utcnow()

        # Count tasks with reminders
        statement = select(Task).where(
            Task.user_id == user_id,
            Task.status == TaskStatus.PENDING,
            Task.remind_at.isnot(None),
        )
        result = await self.session.execute(statement)
        tasks_with_reminders = list(result.scalars().all())

        # Count upcoming reminders (next 24 hours)
        upcoming_count = sum(
            1
            for task in tasks_with_reminders
            if task.remind_at and task.remind_at <= now + timedelta(hours=24)
        )

        # Count overdue tasks
        overdue_tasks = await self.get_overdue_tasks(user_id)

        # Count tasks due today
        due_today = await self.get_tasks_due_today(user_id)

        return {
            "total_with_reminders": len(tasks_with_reminders),
            "upcoming_reminders_24h": upcoming_count,
            "overdue_tasks": len(overdue_tasks),
            "due_today": len(due_today),
        }
