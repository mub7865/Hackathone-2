"""Recurring task scheduler for automatic task instance generation.

This module provides a background scheduler that periodically checks for
recurring patterns and generates new task instances based on their schedules.
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import List

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.database import get_session
from app.events.producer import publish_task_event
from app.models.recurring_patterns import EndCondition, RecurringPattern
from app.services.recurring_task_service import RecurringTaskService

logger = logging.getLogger(__name__)


class RecurringScheduler:
    """Background scheduler for recurring task generation.

    This scheduler runs periodically to check for recurring patterns
    that need new task instances generated.
    """

    def __init__(self, check_interval_seconds: int = 60):
        """Initialize the recurring scheduler.

        Args:
            check_interval_seconds: How often to check for patterns (default: 60s).
        """
        self.check_interval_seconds = check_interval_seconds
        self._running = False
        self._task = None

    async def start(self) -> None:
        """Start the scheduler background task."""
        if self._running:
            logger.warning("Scheduler already running")
            return

        self._running = True
        self._task = asyncio.create_task(self._run_loop())
        logger.info(
            f"Recurring scheduler started (check interval: {self.check_interval_seconds}s)"
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

        logger.info("Recurring scheduler stopped")

    async def _run_loop(self) -> None:
        """Main scheduler loop."""
        while self._running:
            try:
                await self._check_and_generate_tasks()
            except Exception as e:
                logger.error(f"Error in scheduler loop: {e}", exc_info=True)

            # Wait for next check interval
            await asyncio.sleep(self.check_interval_seconds)

    async def _check_and_generate_tasks(self) -> None:
        """Check all recurring patterns and generate tasks as needed."""
        async for session in get_session():
            try:
                # Get all active recurring patterns
                patterns = await self._get_active_patterns(session)

                logger.debug(f"Checking {len(patterns)} active recurring patterns")

                for pattern in patterns:
                    try:
                        await self._process_pattern(session, pattern)
                    except Exception as e:
                        logger.error(
                            f"Error processing pattern {pattern.id}: {e}",
                            exc_info=True,
                        )

                await session.commit()

            except Exception as e:
                logger.error(f"Error in check_and_generate_tasks: {e}", exc_info=True)
                await session.rollback()

    async def _get_active_patterns(
        self, session: AsyncSession
    ) -> List[RecurringPattern]:
        """Get all active recurring patterns that need checking.

        Args:
            session: Database session.

        Returns:
            List of active RecurringPattern instances.
        """
        now = datetime.utcnow()

        # Query patterns that haven't ended
        statement = select(RecurringPattern).where(
            # Pattern is indefinite OR hasn't reached end date OR hasn't reached occurrence count
            (RecurringPattern.end_condition == EndCondition.INDEFINITE)
            | (
                (RecurringPattern.end_condition == EndCondition.DATE)
                & (RecurringPattern.end_date > now)
            )
            | (
                (RecurringPattern.end_condition == EndCondition.COUNT)
                & (RecurringPattern.current_count < RecurringPattern.occurrence_count)
            )
        )

        result = await session.execute(statement)
        return list(result.scalars().all())

    async def _process_pattern(
        self, session: AsyncSession, pattern: RecurringPattern
    ) -> None:
        """Process a single recurring pattern and generate tasks if needed.

        Args:
            session: Database session.
            pattern: RecurringPattern to process.
        """
        service = RecurringTaskService(session)

        # Calculate next occurrence
        next_occurrence = await service.calculate_next_occurrence(pattern)

        if next_occurrence is None:
            logger.debug(f"Pattern {pattern.id} has no more occurrences")
            return

        # Check if next occurrence is due (within next check interval)
        now = datetime.utcnow()
        check_window = now + timedelta(seconds=self.check_interval_seconds * 2)

        if next_occurrence <= check_window:
            # Generate task instance
            task = await service.generate_next_task_instance(pattern)

            if task:
                logger.info(
                    f"Generated task {task.id} for pattern {pattern.id} "
                    f"(occurrence {pattern.current_count})"
                )

                # Publish task.created event
                await publish_task_event(
                    event_type="created",
                    task_id=task.id,
                    user_id=task.user_id,
                    title=task.title,
                    description=task.description,
                    status=task.status.value,
                    priority=task.priority.value,
                    tags=task.tags,
                    due_date=task.due_date,
                    remind_at=task.remind_at,
                    recurring_pattern_id=task.recurring_pattern_id,
                )
            else:
                logger.warning(
                    f"Failed to generate task for pattern {pattern.id}"
                )


# Global scheduler instance
_scheduler: RecurringScheduler | None = None


async def start_recurring_scheduler(check_interval_seconds: int = 60) -> None:
    """Start the global recurring scheduler.

    Args:
        check_interval_seconds: How often to check for patterns (default: 60s).
    """
    global _scheduler

    if _scheduler is not None:
        logger.warning("Recurring scheduler already started")
        return

    _scheduler = RecurringScheduler(check_interval_seconds)
    await _scheduler.start()


async def stop_recurring_scheduler() -> None:
    """Stop the global recurring scheduler."""
    global _scheduler

    if _scheduler is None:
        return

    await _scheduler.stop()
    _scheduler = None


def get_recurring_scheduler() -> RecurringScheduler | None:
    """Get the global recurring scheduler instance.

    Returns:
        RecurringScheduler instance if started, None otherwise.
    """
    return _scheduler
