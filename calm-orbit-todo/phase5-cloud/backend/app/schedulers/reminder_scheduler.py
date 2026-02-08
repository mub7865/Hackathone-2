"""Reminder scheduler for automatic reminder notifications.

This module provides a background scheduler that periodically checks for
tasks with upcoming reminders and triggers notifications via email and events.
"""

import asyncio
import logging
from datetime import datetime
from typing import List

from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.events.producer import publish_task_event
from app.models.task import Task
from app.services.reminder_service import ReminderService

logger = logging.getLogger(__name__)


class ReminderScheduler:
    """Background scheduler for reminder notifications.

    This scheduler runs periodically to check for tasks with upcoming
    reminders and publishes reminder events to the notification service.
    """

    def __init__(self, check_interval_seconds: int = 60):
        """Initialize the reminder scheduler.

        Args:
            check_interval_seconds: How often to check for reminders (default: 60s).
        """
        self.check_interval_seconds = check_interval_seconds
        self._running = False
        self._task = None

    async def start(self) -> None:
        """Start the scheduler background task."""
        if self._running:
            logger.warning("Reminder scheduler already running")
            return

        self._running = True
        self._task = asyncio.create_task(self._run_loop())
        logger.info(
            f"Reminder scheduler started (check interval: {self.check_interval_seconds}s)"
        )

    async def stop(self) -> None:
        """Stop the scheduler background task."""
        if not self._running:
            return

        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass

        logger.info("Reminder scheduler stopped")

    async def _run_loop(self) -> None:
        """Main scheduler loop."""
        while self._running:
            try:
                await self._check_and_send_reminders()
            except Exception as e:
                logger.error(f"Error in reminder scheduler loop: {e}", exc_info=True)

            # Wait for next check interval
            await asyncio.sleep(self.check_interval_seconds)

    async def _check_and_send_reminders(self) -> None:
        """Check for upcoming reminders and send notifications."""
        async for session in get_session():
            try:
                service = ReminderService(session)

                # Get tasks with reminders due in the next check interval
                # Add buffer to ensure we don't miss any reminders
                time_window = self.check_interval_seconds // 60 + 5  # minutes

                tasks = await service.get_tasks_with_upcoming_reminders(time_window)

                logger.debug(f"Found {len(tasks)} tasks with upcoming reminders")

                for task in tasks:
                    try:
                        await self._send_reminder(task)
                    except Exception as e:
                        logger.error(
                            f"Error sending reminder for task {task.id}: {e}",
                            exc_info=True,
                        )

                await session.commit()

            except Exception as e:
                logger.error(f"Error in check_and_send_reminders: {e}", exc_info=True)
                await session.rollback()

    async def _send_reminder(self, task: Task) -> None:
        """Send a reminder notification for a task.

        Args:
            task: Task to send reminder for.
        """
        now = datetime.utcnow()

        # Check if reminder time has passed
        if task.remind_at and task.remind_at <= now:
            logger.info(
                f"Sending reminder for task {task.id} ('{task.title}') to user {task.user_id}"
            )

            # Publish reminder event to Kafka
            # This will be consumed by the notification service
            await publish_task_event(
                event_type="reminder",
                task_id=task.id,
                user_id=task.user_id,
                title=task.title,
                description=task.description,
                due_date=task.due_date,
                remind_at=task.remind_at,
                priority=task.priority.value,
                tags=task.tags,
            )

            # Clear the reminder so it doesn't fire again
            # (User can set a new reminder if needed)
            task.remind_at = None

            logger.info(f"Reminder sent and cleared for task {task.id}")


# Global scheduler instance
_reminder_scheduler: ReminderScheduler | None = None


async def start_reminder_scheduler(check_interval_seconds: int = 60) -> None:
    """Start the global reminder scheduler.

    Args:
        check_interval_seconds: How often to check for reminders (default: 60s).
    """
    global _reminder_scheduler

    if _reminder_scheduler is not None:
        logger.warning("Reminder scheduler already started")
        return

    _reminder_scheduler = ReminderScheduler(check_interval_seconds)
    await _reminder_scheduler.start()


async def stop_reminder_scheduler() -> None:
    """Stop the global reminder scheduler."""
    global _reminder_scheduler

    if _reminder_scheduler is None:
        return

    await _reminder_scheduler.stop()
    _reminder_scheduler = None


def get_reminder_scheduler() -> ReminderScheduler | None:
    """Get the global reminder scheduler instance.

    Returns:
        ReminderScheduler instance if started, None otherwise.
    """
    return _reminder_scheduler
