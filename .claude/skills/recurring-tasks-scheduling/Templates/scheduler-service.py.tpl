"""
Scheduler Service Template

This template provides a complete scheduler service for managing
recurring tasks with APScheduler integration.
"""

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger
from apscheduler.triggers.date import DateTrigger
from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore
from apscheduler.executors.pool import ThreadPoolExecutor
from apscheduler.events import EVENT_JOB_EXECUTED, EVENT_JOB_ERROR
from sqlmodel import Session, select
from datetime import datetime, timedelta
import logging
from typing import Optional, List
import pytz

logger = logging.getLogger(__name__)


# ============================================================================
# Scheduler Service
# ============================================================================

class SchedulerService:
    """Service for managing recurring task scheduling."""

    def __init__(
        self,
        scheduler: BackgroundScheduler,
        session_factory,
        timezone: str = "UTC"
    ):
        """
        Initialize scheduler service.

        Args:
            scheduler: APScheduler instance
            session_factory: Factory function to create database sessions
            timezone: Default timezone for scheduling
        """
        self.scheduler = scheduler
        self.session_factory = session_factory
        self.timezone = pytz.timezone(timezone)

        # Register event listeners
        self.scheduler.add_listener(
            self._job_executed_listener,
            EVENT_JOB_EXECUTED
        )
        self.scheduler.add_listener(
            self._job_error_listener,
            EVENT_JOB_ERROR
        )

    # ========================================================================
    # Job Management
    # ========================================================================

    def schedule_recurring_task(self, recurring_task) -> None:
        """
        Add recurring task to scheduler.

        Args:
            recurring_task: RecurringTask model instance
        """
        try:
            # Create trigger based on pattern
            trigger = self._create_trigger(recurring_task)

            # Add job to scheduler
            self.scheduler.add_job(
                func=self._create_task_instance,
                trigger=trigger,
                args=[recurring_task.id],
                id=f'recurring_{recurring_task.id}',
                name=recurring_task.title,
                replace_existing=True,
                misfire_grace_time=300,  # 5 minutes
                coalesce=True  # Combine missed executions
            )

            logger.info(f"Scheduled recurring task: {recurring_task.id}")

        except Exception as e:
            logger.error(f"Failed to schedule recurring task {recurring_task.id}: {e}")
            raise

    def unschedule_recurring_task(self, recurring_task_id: int) -> None:
        """
        Remove recurring task from scheduler.

        Args:
            recurring_task_id: ID of recurring task to unschedule
        """
        try:
            job_id = f'recurring_{recurring_task_id}'
            self.scheduler.remove_job(job_id)
            logger.info(f"Unscheduled recurring task: {recurring_task_id}")

        except Exception as e:
            logger.warning(f"Failed to unschedule recurring task {recurring_task_id}: {e}")

    def reschedule_recurring_task(self, recurring_task) -> None:
        """
        Update recurring task schedule.

        Args:
            recurring_task: Updated RecurringTask model instance
        """
        # Remove old job
        self.unschedule_recurring_task(recurring_task.id)

        # Add new job
        self.schedule_recurring_task(recurring_task)

    def pause_recurring_task(self, recurring_task_id: int) -> None:
        """Pause recurring task execution."""
        try:
            job_id = f'recurring_{recurring_task_id}'
            self.scheduler.pause_job(job_id)
            logger.info(f"Paused recurring task: {recurring_task_id}")

        except Exception as e:
            logger.error(f"Failed to pause recurring task {recurring_task_id}: {e}")

    def resume_recurring_task(self, recurring_task_id: int) -> None:
        """Resume recurring task execution."""
        try:
            job_id = f'recurring_{recurring_task_id}'
            self.scheduler.resume_job(job_id)
            logger.info(f"Resumed recurring task: {recurring_task_id}")

        except Exception as e:
            logger.error(f"Failed to resume recurring task {recurring_task_id}: {e}")

    # ========================================================================
    # Trigger Creation
    # ========================================================================

    def _create_trigger(self, recurring_task):
        """Create APScheduler trigger from recurring task configuration."""

        from recurring_task_model import RecurrencePattern

        pattern = recurring_task.pattern
        tz = pytz.timezone(recurring_task.timezone)

        if pattern == RecurrencePattern.DAILY:
            # Daily at specific time
            return CronTrigger(
                hour=recurring_task.hour,
                minute=recurring_task.minute,
                timezone=tz
            )

        elif pattern == RecurrencePattern.WEEKLY:
            # Weekly on specific day
            return CronTrigger(
                day_of_week=recurring_task.day_of_week.value,
                hour=recurring_task.hour,
                minute=recurring_task.minute,
                timezone=tz
            )

        elif pattern == RecurrencePattern.MONTHLY:
            # Monthly on specific day
            return CronTrigger(
                day=recurring_task.day_of_month,
                hour=recurring_task.hour,
                minute=recurring_task.minute,
                timezone=tz
            )

        elif pattern == RecurrencePattern.YEARLY:
            # Yearly on same date
            return CronTrigger(
                month=recurring_task.start_date.month,
                day=recurring_task.start_date.day,
                hour=recurring_task.hour,
                minute=recurring_task.minute,
                timezone=tz
            )

        elif pattern == RecurrencePattern.CUSTOM:
            # Custom cron expression
            return CronTrigger.from_crontab(
                recurring_task.cron_expression,
                timezone=tz
            )

        else:
            raise ValueError(f"Unknown pattern: {pattern}")

    # ========================================================================
    # Task Instance Creation
    # ========================================================================

    def _create_task_instance(self, recurring_task_id: int) -> None:
        """
        Create new task instance from recurring task.

        Args:
            recurring_task_id: ID of recurring task
        """
        with self.session_factory() as session:
            try:
                # Get recurring task
                from recurring_task_model import RecurringTask, Task, should_stop_recurring_task

                recurring_task = session.get(RecurringTask, recurring_task_id)

                if not recurring_task:
                    logger.warning(f"Recurring task {recurring_task_id} not found")
                    return

                if not recurring_task.is_active:
                    logger.info(f"Recurring task {recurring_task_id} is inactive")
                    return

                # Check if should stop
                if should_stop_recurring_task(recurring_task):
                    logger.info(f"Recurring task {recurring_task_id} reached end condition")
                    recurring_task.is_active = False
                    session.commit()
                    self.unschedule_recurring_task(recurring_task_id)
                    return

                # Check for duplicate (idempotency)
                now = datetime.utcnow()
                existing = session.exec(
                    select(Task).where(
                        Task.recurring_task_id == recurring_task_id,
                        Task.due_date >= now - timedelta(minutes=5),
                        Task.due_date <= now + timedelta(minutes=5)
                    )
                ).first()

                if existing:
                    logger.info(f"Task instance already exists for recurring task {recurring_task_id}")
                    return

                # Create new task instance
                task = Task(
                    title=recurring_task.title,
                    description=recurring_task.description,
                    user_id=recurring_task.user_id,
                    due_date=recurring_task.next_run,
                    is_recurring=True,
                    recurring_task_id=recurring_task_id
                )

                session.add(task)

                # Update recurring task
                recurring_task.last_run = now
                recurring_task.occurrence_count += 1

                # Calculate next run
                from next_occurrence import calculate_next_occurrence

                recurring_task.next_run = calculate_next_occurrence(
                    last_run=now,
                    pattern=recurring_task.pattern,
                    interval=recurring_task.interval,
                    hour=recurring_task.hour,
                    minute=recurring_task.minute,
                    day_of_week=recurring_task.day_of_week,
                    day_of_month=recurring_task.day_of_month,
                    cron_expression=recurring_task.cron_expression,
                    timezone=recurring_task.timezone
                )

                session.commit()

                logger.info(
                    f"Created task instance {task.id} from recurring task {recurring_task_id}"
                )

                # Log execution
                self._log_execution(
                    session,
                    recurring_task_id,
                    recurring_task.next_run,
                    now,
                    True,
                    task.id
                )

            except Exception as e:
                logger.error(
                    f"Failed to create task instance for recurring task {recurring_task_id}: {e}",
                    exc_info=True
                )
                session.rollback()

                # Log failed execution
                self._log_execution(
                    session,
                    recurring_task_id,
                    datetime.utcnow(),
                    datetime.utcnow(),
                    False,
                    None,
                    str(e)
                )

    def _log_execution(
        self,
        session: Session,
        recurring_task_id: int,
        scheduled_time: datetime,
        actual_time: datetime,
        success: bool,
        task_id: Optional[int] = None,
        error_message: Optional[str] = None
    ) -> None:
        """Log recurring task execution."""
        try:
            from recurring_task_model import RecurringTaskExecution

            execution = RecurringTaskExecution(
                recurring_task_id=recurring_task_id,
                scheduled_time=scheduled_time,
                actual_time=actual_time,
                success=success,
                task_id=task_id,
                error_message=error_message
            )

            session.add(execution)
            session.commit()

        except Exception as e:
            logger.error(f"Failed to log execution: {e}")

    # ========================================================================
    # Event Listeners
    # ========================================================================

    def _job_executed_listener(self, event):
        """Handle job execution event."""
        logger.info(f"Job {event.job_id} executed successfully")

    def _job_error_listener(self, event):
        """Handle job error event."""
        logger.error(
            f"Job {event.job_id} failed: {event.exception}",
            exc_info=True
        )

    # ========================================================================
    # Bulk Operations
    # ========================================================================

    def schedule_all_active_tasks(self) -> int:
        """
        Schedule all active recurring tasks.

        Returns:
            Number of tasks scheduled
        """
        with self.session_factory() as session:
            from recurring_task_model import RecurringTask

            active_tasks = session.exec(
                select(RecurringTask).where(RecurringTask.is_active == True)
            ).all()

            count = 0
            for task in active_tasks:
                try:
                    self.schedule_recurring_task(task)
                    count += 1
                except Exception as e:
                    logger.error(f"Failed to schedule task {task.id}: {e}")

            logger.info(f"Scheduled {count} active recurring tasks")
            return count

    def unschedule_all_tasks(self) -> None:
        """Remove all scheduled jobs."""
        self.scheduler.remove_all_jobs()
        logger.info("Unscheduled all recurring tasks")

    # ========================================================================
    # Query Operations
    # ========================================================================

    def get_scheduled_jobs(self) -> List[dict]:
        """Get list of all scheduled jobs."""
        jobs = []
        for job in self.scheduler.get_jobs():
            jobs.append({
                'id': job.id,
                'name': job.name,
                'next_run_time': job.next_run_time,
                'trigger': str(job.trigger)
            })
        return jobs

    def get_job_info(self, recurring_task_id: int) -> Optional[dict]:
        """Get information about a specific scheduled job."""
        job_id = f'recurring_{recurring_task_id}'
        job = self.scheduler.get_job(job_id)

        if not job:
            return None

        return {
            'id': job.id,
            'name': job.name,
            'next_run_time': job.next_run_time,
            'trigger': str(job.trigger),
            'pending': job.pending
        }


# ============================================================================
# Scheduler Configuration
# ============================================================================

def create_scheduler(
    database_url: str,
    max_workers: int = 10,
    timezone: str = "UTC"
) -> BackgroundScheduler:
    """
    Create and configure APScheduler instance.

    Args:
        database_url: Database URL for job store
        max_workers: Maximum number of worker threads
        timezone: Default timezone

    Returns:
        Configured BackgroundScheduler instance
    """

    # Configure job stores
    jobstores = {
        'default': SQLAlchemyJobStore(url=database_url)
    }

    # Configure executors
    executors = {
        'default': ThreadPoolExecutor(max_workers)
    }

    # Configure job defaults
    job_defaults = {
        'coalesce': True,  # Combine missed executions
        'max_instances': 1,  # Only one instance per job
        'misfire_grace_time': 300  # 5 minutes grace period
    }

    # Create scheduler
    scheduler = BackgroundScheduler(
        jobstores=jobstores,
        executors=executors,
        job_defaults=job_defaults,
        timezone=timezone
    )

    return scheduler


# ============================================================================
# FastAPI Integration
# ============================================================================

from contextlib import asynccontextmanager
from fastapi import FastAPI

@asynccontextmanager
async def scheduler_lifespan(app: FastAPI):
    """FastAPI lifespan context manager for scheduler."""

    # Startup
    scheduler = app.state.scheduler
    scheduler_service = app.state.scheduler_service

    # Schedule all active tasks
    scheduler_service.schedule_all_active_tasks()

    # Start scheduler
    scheduler.start()
    logger.info("Scheduler started")

    yield

    # Shutdown
    scheduler.shutdown(wait=True)
    logger.info("Scheduler stopped")


# ============================================================================
# Usage Example
# ============================================================================

if __name__ == "__main__":
    from sqlmodel import create_engine, Session

    # Create database engine
    engine = create_engine("sqlite:///./test.db")

    # Create session factory
    def get_session():
        return Session(engine)

    # Create scheduler
    scheduler = create_scheduler(
        database_url="sqlite:///./scheduler.db",
        max_workers=10,
        timezone="UTC"
    )

    # Create scheduler service
    scheduler_service = SchedulerService(
        scheduler=scheduler,
        session_factory=get_session,
        timezone="UTC"
    )

    # Schedule all active tasks
    scheduler_service.schedule_all_active_tasks()

    # Start scheduler
    scheduler.start()

    # Keep running
    try:
        import time
        while True:
            time.sleep(1)
    except (KeyboardInterrupt, SystemExit):
        scheduler.shutdown()
