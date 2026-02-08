# Recurring Tasks Scheduling Skill

## Overview

This skill provides patterns and templates for implementing recurring task scheduling in Python applications. It covers cron-like scheduling, calculating next occurrences, handling missed executions, and integrating with FastAPI backends.

## When to Use This Skill

Use this skill when you need to:
- Schedule tasks to repeat at regular intervals (daily, weekly, monthly)
- Implement cron-like scheduling with flexible patterns
- Calculate next occurrence dates for recurring tasks
- Handle missed executions and catch-up logic
- Integrate scheduled tasks with FastAPI applications
- Store and manage recurring task definitions in a database
- Test scheduled task execution

## Technology Stack

- **APScheduler**: Advanced Python Scheduler for background jobs
- **Celery Beat**: Distributed task scheduler (alternative)
- **Cron Expressions**: Standard scheduling syntax
- **SQLModel**: Database models for recurring tasks
- **FastAPI**: REST API for managing schedules
- **Python datetime**: Date/time calculations

## Key Concepts

### 1. Scheduling Patterns

**Cron Expressions**: Standard Unix cron syntax
```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
* * * * *
```

Examples:
- `0 9 * * *` - Every day at 9:00 AM
- `0 9 * * 1` - Every Monday at 9:00 AM
- `0 9 1 * *` - First day of every month at 9:00 AM
- `*/15 * * * *` - Every 15 minutes
- `0 0 * * 0` - Every Sunday at midnight

**Simple Patterns**: Human-readable alternatives
- `daily` - Every day at specified time
- `weekly` - Every week on specified day
- `monthly` - Every month on specified day
- `yearly` - Every year on specified date

### 2. Recurrence Rules

**RRULE (RFC 5545)**: Internet Calendaring and Scheduling Core Object Specification
```python
FREQ=DAILY;INTERVAL=1;BYHOUR=9;BYMINUTE=0
FREQ=WEEKLY;INTERVAL=1;BYDAY=MO;BYHOUR=9
FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=1;BYHOUR=9
```

### 3. Next Occurrence Calculation

Calculate when a recurring task should run next:
```python
from datetime import datetime, timedelta

def calculate_next_occurrence(last_run: datetime, pattern: str) -> datetime:
    if pattern == 'daily':
        return last_run + timedelta(days=1)
    elif pattern == 'weekly':
        return last_run + timedelta(weeks=1)
    elif pattern == 'monthly':
        # Add one month (handle month boundaries)
        return last_run + relativedelta(months=1)
```

### 4. Missed Execution Handling

**Strategies**:
- **Skip**: Ignore missed executions
- **Run Once**: Run immediately, then continue schedule
- **Catch Up**: Run all missed executions
- **Coalesce**: Run once for all missed executions

## Quick Start

### 1. Install Dependencies

```bash
pip install apscheduler python-dateutil croniter
```

### 2. Create Recurring Task Model

```python
from sqlmodel import SQLModel, Field
from datetime import datetime
from typing import Optional

class RecurringTask(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    description: Optional[str] = None
    user_id: str

    # Scheduling
    pattern: str  # 'daily', 'weekly', 'monthly', or cron expression
    start_date: datetime
    end_date: Optional[datetime] = None
    last_run: Optional[datetime] = None
    next_run: datetime

    # Configuration
    is_active: bool = True
    missed_execution_strategy: str = "skip"  # skip, run_once, catch_up

    created_at: datetime = Field(default_factory=datetime.utcnow)
```

### 3. Calculate Next Occurrence

```python
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta

def calculate_next_occurrence(
    last_run: datetime,
    pattern: str,
    start_date: datetime
) -> datetime:
    """Calculate next occurrence based on pattern."""

    if pattern == 'daily':
        return last_run + timedelta(days=1)

    elif pattern == 'weekly':
        return last_run + timedelta(weeks=1)

    elif pattern == 'monthly':
        return last_run + relativedelta(months=1)

    elif pattern == 'yearly':
        return last_run + relativedelta(years=1)

    else:
        # Parse cron expression
        from croniter import croniter
        cron = croniter(pattern, last_run)
        return cron.get_next(datetime)
```

### 4. Set Up Scheduler

```python
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger

scheduler = BackgroundScheduler()

def create_task_instance(recurring_task_id: int):
    """Create a new task instance from recurring task."""
    # Fetch recurring task from database
    # Create new task instance
    # Update last_run and next_run
    pass

# Schedule all active recurring tasks
for recurring_task in get_active_recurring_tasks():
    if recurring_task.pattern in ['daily', 'weekly', 'monthly']:
        # Use simple trigger
        scheduler.add_job(
            create_task_instance,
            'interval',
            days=1 if recurring_task.pattern == 'daily' else 0,
            weeks=1 if recurring_task.pattern == 'weekly' else 0,
            args=[recurring_task.id],
            id=f'recurring_{recurring_task.id}'
        )
    else:
        # Use cron trigger
        scheduler.add_job(
            create_task_instance,
            CronTrigger.from_crontab(recurring_task.pattern),
            args=[recurring_task.id],
            id=f'recurring_{recurring_task.id}'
        )

scheduler.start()
```

### 5. FastAPI Integration

```python
from fastapi import FastAPI, Depends
from sqlmodel import Session

app = FastAPI()

@app.post("/recurring-tasks")
async def create_recurring_task(
    task: RecurringTaskCreate,
    session: Session = Depends(get_session)
):
    """Create a new recurring task."""

    # Calculate first occurrence
    next_run = calculate_next_occurrence(
        task.start_date,
        task.pattern,
        task.start_date
    )

    recurring_task = RecurringTask(
        **task.dict(),
        next_run=next_run
    )

    session.add(recurring_task)
    session.commit()
    session.refresh(recurring_task)

    # Add to scheduler
    scheduler.add_job(
        create_task_instance,
        CronTrigger.from_crontab(recurring_task.pattern),
        args=[recurring_task.id],
        id=f'recurring_{recurring_task.id}'
    )

    return recurring_task
```

## Integration with FastAPI

### Background Scheduler

```python
from contextlib import asynccontextmanager
from apscheduler.schedulers.background import BackgroundScheduler

scheduler = BackgroundScheduler()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Start scheduler
    scheduler.start()
    yield
    # Shutdown: Stop scheduler
    scheduler.shutdown()

app = FastAPI(lifespan=lifespan)
```

### Scheduler Service

```python
class SchedulerService:
    def __init__(self, scheduler: BackgroundScheduler, session: Session):
        self.scheduler = scheduler
        self.session = session

    def schedule_recurring_task(self, recurring_task: RecurringTask):
        """Add recurring task to scheduler."""
        self.scheduler.add_job(
            self.create_task_instance,
            CronTrigger.from_crontab(recurring_task.pattern),
            args=[recurring_task.id],
            id=f'recurring_{recurring_task.id}',
            replace_existing=True
        )

    def unschedule_recurring_task(self, recurring_task_id: int):
        """Remove recurring task from scheduler."""
        try:
            self.scheduler.remove_job(f'recurring_{recurring_task_id}')
        except JobLookupError:
            pass

    def create_task_instance(self, recurring_task_id: int):
        """Create new task instance from recurring task."""
        recurring_task = self.session.get(RecurringTask, recurring_task_id)

        if not recurring_task or not recurring_task.is_active:
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

        self.session.add(task)

        # Update recurring task
        recurring_task.last_run = datetime.utcnow()
        recurring_task.next_run = calculate_next_occurrence(
            recurring_task.last_run,
            recurring_task.pattern,
            recurring_task.start_date
        )

        self.session.commit()
```

## Best Practices

### 1. Timezone Handling
```python
from datetime import datetime
import pytz

# Always use UTC for storage
utc = pytz.UTC
now_utc = datetime.now(utc)

# Convert to user timezone for display
user_tz = pytz.timezone('America/New_York')
now_user = now_utc.astimezone(user_tz)
```

### 2. Idempotency
```python
def create_task_instance(recurring_task_id: int):
    """Create task instance (idempotent)."""

    # Check if already created for this occurrence
    existing = session.query(Task).filter(
        Task.recurring_task_id == recurring_task_id,
        Task.due_date == next_run
    ).first()

    if existing:
        return  # Already created

    # Create new instance
    task = Task(...)
    session.add(task)
    session.commit()
```

### 3. Error Handling
```python
def create_task_instance(recurring_task_id: int):
    try:
        # Create task instance
        pass
    except Exception as e:
        logger.error(f"Failed to create task instance: {e}")
        # Don't update next_run if failed
        # Will retry on next scheduler run
```

### 4. Performance
```python
# Batch process recurring tasks
def process_due_recurring_tasks():
    """Process all recurring tasks due now."""

    now = datetime.utcnow()
    due_tasks = session.query(RecurringTask).filter(
        RecurringTask.is_active == True,
        RecurringTask.next_run <= now
    ).all()

    for task in due_tasks:
        create_task_instance(task.id)
```

### 5. Testing
```python
def test_calculate_next_occurrence():
    """Test next occurrence calculation."""

    # Daily
    last_run = datetime(2024, 1, 1, 9, 0)
    next_run = calculate_next_occurrence(last_run, 'daily', last_run)
    assert next_run == datetime(2024, 1, 2, 9, 0)

    # Weekly
    next_run = calculate_next_occurrence(last_run, 'weekly', last_run)
    assert next_run == datetime(2024, 1, 8, 9, 0)

    # Monthly
    next_run = calculate_next_occurrence(last_run, 'monthly', last_run)
    assert next_run == datetime(2024, 2, 1, 9, 0)
```

## Common Patterns

### Daily Task at Specific Time
```python
pattern = "0 9 * * *"  # Every day at 9:00 AM
```

### Weekly Task on Specific Day
```python
pattern = "0 9 * * 1"  # Every Monday at 9:00 AM
```

### Monthly Task on Specific Date
```python
pattern = "0 9 1 * *"  # First day of every month at 9:00 AM
```

### Every N Days
```python
# Every 3 days
interval = timedelta(days=3)
next_run = last_run + interval
```

### Weekdays Only
```python
pattern = "0 9 * * 1-5"  # Monday to Friday at 9:00 AM
```

## Templates Available

1. **recurring-task-model.py.tpl** - SQLModel for recurring tasks
2. **scheduler-service.py.tpl** - Scheduler service implementation
3. **next-occurrence.py.tpl** - Next occurrence calculation
4. **apscheduler-setup.py.tpl** - APScheduler configuration
5. **celery-beat-setup.py.tpl** - Celery Beat configuration

## Examples Available

1. **fastapi-recurring-tasks.md** - Complete FastAPI integration
2. **cron-patterns.md** - Common cron expression examples
3. **timezone-handling.md** - Timezone best practices

## Testing Available

1. **test-recurring-tasks.py.tpl** - Unit tests for recurring tasks
2. **test-scheduler.py.tpl** - Scheduler integration tests
3. **verify-scheduling.sh** - End-to-end verification

## Troubleshooting Available

1. **scheduling-issues.md** - Common scheduling problems
2. **timezone-issues.md** - Timezone-related issues

## Related Skills

- **kafka-event-streaming** - Publish events when tasks are created
- **reminder-notifications** - Send reminders for recurring tasks
- **dapr-integration** - Use Dapr bindings for scheduling

## References

- [APScheduler Documentation](https://apscheduler.readthedocs.io/)
- [Celery Beat Documentation](https://docs.celeryproject.org/en/stable/userguide/periodic-tasks.html)
- [Cron Expression Guide](https://crontab.guru/)
- [RFC 5545 (iCalendar)](https://tools.ietf.org/html/rfc5545)
- [Python dateutil](https://dateutil.readthedocs.io/)
