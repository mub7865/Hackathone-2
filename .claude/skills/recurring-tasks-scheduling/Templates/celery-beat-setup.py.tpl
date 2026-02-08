"""
Celery Beat Setup Template

This template provides Celery Beat configuration for distributed
recurring task scheduling with Redis/RabbitMQ backend.
"""

from celery import Celery
from celery.schedules import crontab, solar
from datetime import timedelta
import os

# ============================================================================
# Celery Configuration
# ============================================================================

# Broker URL (Redis or RabbitMQ)
BROKER_URL = os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0')

# Result backend
RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# Create Celery app
app = Celery('recurring_tasks', broker=BROKER_URL, backend=RESULT_BACKEND)

# Configure Celery
app.conf.update(
    # Timezone
    timezone='UTC',
    enable_utc=True,

    # Task settings
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    result_expires=3600,  # 1 hour

    # Beat settings
    beat_schedule_filename='celerybeat-schedule',
    beat_max_loop_interval=5,  # Check for new tasks every 5 seconds

    # Worker settings
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=1000,

    # Result backend settings
    result_backend_transport_options={
        'master_name': 'mymaster',
        'visibility_timeout': 3600,
    },

    # Broker settings
    broker_connection_retry_on_startup=True,
    broker_connection_retry=True,
    broker_connection_max_retries=10,
)


# ============================================================================
# Beat Schedule (Static)
# ============================================================================

app.conf.beat_schedule = {
    # Daily task at 9:00 AM
    'daily-morning-task': {
        'task': 'tasks.create_daily_task',
        'schedule': crontab(hour=9, minute=0),
        'args': (),
    },

    # Weekly task every Monday at 9:00 AM
    'weekly-monday-task': {
        'task': 'tasks.create_weekly_task',
        'schedule': crontab(hour=9, minute=0, day_of_week=1),
        'args': (),
    },

    # Monthly task on 1st at 9:00 AM
    'monthly-first-task': {
        'task': 'tasks.create_monthly_task',
        'schedule': crontab(hour=9, minute=0, day_of_month=1),
        'args': (),
    },

    # Every 15 minutes
    'frequent-task': {
        'task': 'tasks.process_pending_tasks',
        'schedule': timedelta(minutes=15),
        'args': (),
    },

    # Every hour
    'hourly-cleanup': {
        'task': 'tasks.cleanup_old_tasks',
        'schedule': crontab(minute=0),  # Every hour at minute 0
        'args': (),
    },

    # Weekdays only (Monday-Friday) at 9:00 AM
    'weekday-task': {
        'task': 'tasks.weekday_reminder',
        'schedule': crontab(hour=9, minute=0, day_of_week='1-5'),
        'args': (),
    },

    # Solar schedule (sunrise/sunset)
    'sunrise-task': {
        'task': 'tasks.sunrise_notification',
        'schedule': solar('sunrise', 40.7128, -74.0060),  # NYC coordinates
        'args': (),
    },
}


# ============================================================================
# Task Definitions
# ============================================================================

@app.task(name='tasks.create_daily_task')
def create_daily_task():
    """Create daily task instance."""
    from sqlmodel import Session, create_engine

    engine = create_engine(os.getenv('DATABASE_URL'))
    with Session(engine) as session:
        # Create task instance
        from recurring_task_model import Task
        task = Task(
            title="Daily Task",
            description="Automatically created daily task",
            user_id="system"
        )
        session.add(task)
        session.commit()

    return f"Created daily task: {task.id}"


@app.task(name='tasks.create_weekly_task')
def create_weekly_task():
    """Create weekly task instance."""
    # Implementation similar to create_daily_task
    return "Created weekly task"


@app.task(name='tasks.create_monthly_task')
def create_monthly_task():
    """Create monthly task instance."""
    # Implementation similar to create_daily_task
    return "Created monthly task"


@app.task(name='tasks.process_pending_tasks')
def process_pending_tasks():
    """Process pending recurring tasks."""
    from sqlmodel import Session, create_engine, select
    from datetime import datetime

    engine = create_engine(os.getenv('DATABASE_URL'))
    with Session(engine) as session:
        from recurring_task_model import RecurringTask, Task

        # Get all active recurring tasks that are due
        now = datetime.utcnow()
        due_tasks = session.exec(
            select(RecurringTask).where(
                RecurringTask.is_active == True,
                RecurringTask.next_run <= now
            )
        ).all()

        created_count = 0
        for recurring_task in due_tasks:
            # Create task instance
            task = Task(
                title=recurring_task.title,
                description=recurring_task.description,
                user_id=recurring_task.user_id,
                due_date=recurring_task.next_run,
                is_recurring=True,
                recurring_task_id=recurring_task.id
            )
            session.add(task)

            # Update recurring task
            from next_occurrence import calculate_next_occurrence
            recurring_task.last_run = now
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

            created_count += 1

        session.commit()

    return f"Created {created_count} task instances"


@app.task(name='tasks.cleanup_old_tasks')
def cleanup_old_tasks():
    """Clean up old completed tasks."""
    from sqlmodel import Session, create_engine, select
    from datetime import datetime, timedelta

    engine = create_engine(os.getenv('DATABASE_URL'))
    with Session(engine) as session:
        from recurring_task_model import Task

        # Delete completed tasks older than 30 days
        cutoff_date = datetime.utcnow() - timedelta(days=30)
        old_tasks = session.exec(
            select(Task).where(
                Task.completed == True,
                Task.completed_at < cutoff_date
            )
        ).all()

        count = len(old_tasks)
        for task in old_tasks:
            session.delete(task)

        session.commit()

    return f"Deleted {count} old tasks"


@app.task(name='tasks.weekday_reminder')
def weekday_reminder():
    """Send weekday reminders."""
    # Implementation for sending reminders
    return "Sent weekday reminders"


@app.task(name='tasks.sunrise_notification')
def sunrise_notification():
    """Send sunrise notification."""
    # Implementation for sunrise notification
    return "Sent sunrise notification"


# ============================================================================
# Dynamic Beat Schedule (Database-backed)
# ============================================================================

from celery.beat import Scheduler, ScheduleEntry
from celery.utils.log import get_logger

logger = get_logger(__name__)


class DatabaseScheduler(Scheduler):
    """Custom scheduler that reads schedule from database."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.schedule = {}
        self.load_schedule_from_db()

    def load_schedule_from_db(self):
        """Load schedule from database."""
        from sqlmodel import Session, create_engine, select

        engine = create_engine(os.getenv('DATABASE_URL'))
        with Session(engine) as session:
            from recurring_task_model import RecurringTask

            active_tasks = session.exec(
                select(RecurringTask).where(RecurringTask.is_active == True)
            ).all()

            for task in active_tasks:
                # Create schedule entry
                schedule = self._create_schedule(task)
                entry = ScheduleEntry(
                    name=f'recurring_{task.id}',
                    task='tasks.process_pending_tasks',
                    schedule=schedule,
                    args=(),
                    kwargs={},
                )
                self.schedule[f'recurring_{task.id}'] = entry

        logger.info(f"Loaded {len(self.schedule)} tasks from database")

    def _create_schedule(self, task):
        """Create Celery schedule from recurring task."""
        from recurring_task_model import RecurrencePattern

        if task.pattern == RecurrencePattern.DAILY:
            return crontab(hour=task.hour, minute=task.minute)

        elif task.pattern == RecurrencePattern.WEEKLY:
            return crontab(
                hour=task.hour,
                minute=task.minute,
                day_of_week=task.day_of_week.value
            )

        elif task.pattern == RecurrencePattern.MONTHLY:
            return crontab(
                hour=task.hour,
                minute=task.minute,
                day_of_month=task.day_of_month
            )

        elif task.pattern == RecurrencePattern.CUSTOM:
            # Parse cron expression
            parts = task.cron_expression.split()
            return crontab(
                minute=parts[0],
                hour=parts[1],
                day_of_month=parts[2],
                month_of_year=parts[3],
                day_of_week=parts[4]
            )

        else:
            raise ValueError(f"Unknown pattern: {task.pattern}")

    def tick(self):
        """Check for due tasks and reload schedule periodically."""
        # Reload schedule every 5 minutes
        if not hasattr(self, '_last_reload'):
            self._last_reload = 0

        import time
        now = time.time()
        if now - self._last_reload > 300:  # 5 minutes
            self.load_schedule_from_db()
            self._last_reload = now

        return super().tick()


# To use DatabaseScheduler:
# celery -A celery_app beat --scheduler=celery_app:DatabaseScheduler


# ============================================================================
# Running Celery
# ============================================================================

"""
# Start Celery worker
celery -A celery_app worker --loglevel=info

# Start Celery beat (scheduler)
celery -A celery_app beat --loglevel=info

# Start both worker and beat together
celery -A celery_app worker --beat --loglevel=info

# With custom scheduler
celery -A celery_app beat --scheduler=celery_app:DatabaseScheduler --loglevel=info

# Monitor with Flower
celery -A celery_app flower

# Purge all tasks
celery -A celery_app purge
"""


# ============================================================================
# FastAPI Integration
# ============================================================================

from fastapi import FastAPI, BackgroundTasks

app_fastapi = FastAPI()


@app_fastapi.post("/tasks/trigger/{task_name}")
async def trigger_task(task_name: str, background_tasks: BackgroundTasks):
    """Manually trigger a Celery task."""

    # Get task by name
    task = app.tasks.get(f'tasks.{task_name}')

    if not task:
        return {"error": "Task not found"}

    # Trigger task asynchronously
    result = task.apply_async()

    return {
        "task_id": result.id,
        "status": "triggered"
    }


@app_fastapi.get("/tasks/status/{task_id}")
async def get_task_status(task_id: str):
    """Get status of a Celery task."""
    from celery.result import AsyncResult

    result = AsyncResult(task_id, app=app)

    return {
        "task_id": task_id,
        "status": result.status,
        "result": result.result if result.ready() else None
    }


# ============================================================================
# Docker Compose Setup
# ============================================================================

"""
# docker-compose.yml

version: '3.8'

services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  celery-worker:
    build: .
    command: celery -A celery_app worker --loglevel=info
    environment:
      - CELERY_BROKER_URL=redis://redis:6379/0
      - CELERY_RESULT_BACKEND=redis://redis:6379/0
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
    depends_on:
      - redis

  celery-beat:
    build: .
    command: celery -A celery_app beat --loglevel=info
    environment:
      - CELERY_BROKER_URL=redis://redis:6379/0
      - CELERY_RESULT_BACKEND=redis://redis:6379/0
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
    depends_on:
      - redis

  flower:
    build: .
    command: celery -A celery_app flower
    ports:
      - "5555:5555"
    environment:
      - CELERY_BROKER_URL=redis://redis:6379/0
      - CELERY_RESULT_BACKEND=redis://redis:6379/0
    depends_on:
      - redis
"""


# ============================================================================
# Usage Example
# ============================================================================

if __name__ == '__main__':
    # Start worker
    app.worker_main(['worker', '--loglevel=info'])
