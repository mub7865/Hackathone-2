# Troubleshooting Recurring Task Scheduling Issues

This guide covers common issues with recurring task scheduling and their solutions.

## Table of Contents

1. [Jobs Not Executing](#jobs-not-executing)
2. [Missed Executions](#missed-executions)
3. [Duplicate Executions](#duplicate-executions)
4. [Performance Issues](#performance-issues)
5. [Database Issues](#database-issues)
6. [Memory Leaks](#memory-leaks)
7. [Scheduler Not Starting](#scheduler-not-starting)
8. [Jobs Not Persisting](#jobs-not-persisting)

---

## Jobs Not Executing

### Symptom
Jobs are scheduled but never execute.

### Diagnosis

1. **Check if scheduler is running:**
```python
print(f"Scheduler running: {scheduler.running}")
```

2. **Check if job exists:**
```python
job = scheduler.get_job('job_id')
print(f"Job exists: {job is not None}")
if job:
    print(f"Next run time: {job.next_run_time}")
```

3. **Check job state:**
```python
jobs = scheduler.get_jobs()
for job in jobs:
    print(f"Job {job.id}: next_run={job.next_run_time}, paused={job.next_run_time is None}")
```

### Common Causes and Solutions

#### Cause 1: Scheduler Not Started
**Solution:** Ensure scheduler is started
```python
if not scheduler.running:
    scheduler.start()
```

#### Cause 2: Job is Paused
**Solution:** Resume the job
```python
scheduler.resume_job('job_id')
```

#### Cause 3: Next Run Time in Past
**Solution:** Reschedule the job
```python
from datetime import datetime, timedelta

scheduler.reschedule_job(
    'job_id',
    trigger='date',
    run_date=datetime.now() + timedelta(seconds=10)
)
```

#### Cause 4: Job Function Not Callable
**Solution:** Verify job function is properly defined
```python
# ❌ Wrong: Function not defined
scheduler.add_job(undefined_function, 'interval', seconds=60)

# ✅ Correct: Function defined
def my_job():
    print("Job executed")

scheduler.add_job(my_job, 'interval', seconds=60)
```

#### Cause 5: Exception in Job Function
**Solution:** Add error handling and logging
```python
import logging

logger = logging.getLogger(__name__)

def my_job():
    try:
        # Job logic
        pass
    except Exception as e:
        logger.error(f"Job failed: {e}", exc_info=True)
        raise  # Re-raise to trigger APScheduler error handling
```

---

## Missed Executions

### Symptom
Jobs don't execute when they should, especially after downtime.

### Diagnosis

1. **Check misfire grace time:**
```python
job = scheduler.get_job('job_id')
print(f"Misfire grace time: {job.misfire_grace_time}")
```

2. **Check coalesce setting:**
```python
print(f"Coalesce: {job.coalesce}")
```

3. **Check execution history:**
```python
# Query execution log
from sqlmodel import select
executions = session.exec(
    select(RecurringTaskExecution)
    .where(RecurringTaskExecution.recurring_task_id == task_id)
    .order_by(RecurringTaskExecution.scheduled_time.desc())
).all()

for exec in executions:
    print(f"Scheduled: {exec.scheduled_time}, Executed: {exec.executed_time}, Status: {exec.status}")
```

### Solutions

#### Solution 1: Increase Misfire Grace Time
```python
scheduler.add_job(
    my_job,
    'interval',
    seconds=60,
    misfire_grace_time=600  # 10 minutes
)
```

#### Solution 2: Enable Coalescing
```python
scheduler.add_job(
    my_job,
    'interval',
    seconds=60,
    coalesce=True  # Combine missed executions into one
)
```

#### Solution 3: Implement Catch-Up Logic
```python
from datetime import datetime
from utils.next_occurrence import calculate_missed_occurrences

def catch_up_missed_executions(recurring_task):
    """Create task instances for missed executions."""
    missed = calculate_missed_occurrences(
        last_run=recurring_task.last_run,
        next_run=recurring_task.next_run,
        pattern=recurring_task.pattern,
        interval=recurring_task.interval,
        hour=recurring_task.hour,
        minute=recurring_task.minute,
        timezone=recurring_task.timezone
    )

    for missed_time in missed:
        # Create task instance for missed execution
        task = Task(
            title=recurring_task.title,
            user_id=recurring_task.user_id,
            due_date=missed_time,
            is_recurring=True,
            recurring_task_id=recurring_task.id
        )
        session.add(task)

    session.commit()
```

#### Solution 4: Use Persistent Job Store
```python
from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore

jobstores = {
    'default': SQLAlchemyJobStore(url='postgresql://user:pass@localhost/db')
}

scheduler = BackgroundScheduler(jobstores=jobstores)
```

---

## Duplicate Executions

### Symptom
Jobs execute multiple times when they should only execute once.

### Diagnosis

1. **Check max_instances:**
```python
job = scheduler.get_job('job_id')
print(f"Max instances: {job.max_instances}")
```

2. **Check for multiple schedulers:**
```python
# In your application
print(f"Scheduler instances: {id(scheduler)}")
```

3. **Check job store for duplicates:**
```python
jobs = scheduler.get_jobs()
job_ids = [job.id for job in jobs]
duplicates = [id for id in job_ids if job_ids.count(id) > 1]
print(f"Duplicate job IDs: {duplicates}")
```

### Solutions

#### Solution 1: Set max_instances to 1
```python
scheduler.add_job(
    my_job,
    'interval',
    seconds=60,
    max_instances=1  # Only one instance at a time
)
```

#### Solution 2: Use replace_existing
```python
scheduler.add_job(
    my_job,
    'interval',
    seconds=60,
    id='unique_job_id',
    replace_existing=True  # Replace if already exists
)
```

#### Solution 3: Implement Idempotency
```python
def idempotent_job(task_id: int):
    """Job that can be safely executed multiple times."""
    with session_factory() as session:
        # Check if already processed
        existing = session.exec(
            select(Task)
            .where(Task.recurring_task_id == task_id)
            .where(Task.created_at >= datetime.utcnow() - timedelta(minutes=5))
        ).first()

        if existing:
            logger.info(f"Task {task_id} already processed, skipping")
            return

        # Process task
        task = Task(...)
        session.add(task)
        session.commit()
```

#### Solution 4: Use Singleton Scheduler
```python
# scheduler.py
_scheduler_instance = None

def get_scheduler():
    global _scheduler_instance
    if _scheduler_instance is None:
        _scheduler_instance = BackgroundScheduler()
        _scheduler_instance.start()
    return _scheduler_instance
```

---

## Performance Issues

### Symptom
Scheduler is slow or consuming too many resources.

### Diagnosis

1. **Check number of jobs:**
```python
jobs = scheduler.get_jobs()
print(f"Total jobs: {len(jobs)}")
```

2. **Check job execution time:**
```python
import time

def timed_job():
    start = time.time()
    # Job logic
    duration = time.time() - start
    logger.info(f"Job took {duration:.2f} seconds")
```

3. **Check thread pool size:**
```python
print(f"Thread pool size: {scheduler._executors['default'].max_workers}")
```

### Solutions

#### Solution 1: Increase Thread Pool Size
```python
from apscheduler.executors.pool import ThreadPoolExecutor

executors = {
    'default': ThreadPoolExecutor(max_workers=20)
}

scheduler = BackgroundScheduler(executors=executors)
```

#### Solution 2: Use Process Pool for CPU-Intensive Jobs
```python
from apscheduler.executors.pool import ProcessPoolExecutor

executors = {
    'default': ThreadPoolExecutor(max_workers=10),
    'processpool': ProcessPoolExecutor(max_workers=5)
}

scheduler = BackgroundScheduler(executors=executors)

# Use process pool for CPU-intensive job
scheduler.add_job(
    cpu_intensive_job,
    'interval',
    seconds=60,
    executor='processpool'
)
```

#### Solution 3: Optimize Job Function
```python
# ❌ Slow: Query in loop
def slow_job():
    for user_id in user_ids:
        user = session.get(User, user_id)  # N+1 query
        process_user(user)

# ✅ Fast: Batch query
def fast_job():
    users = session.exec(
        select(User).where(User.id.in_(user_ids))
    ).all()
    for user in users:
        process_user(user)
```

#### Solution 4: Use Async Jobs
```python
import asyncio
from apscheduler.schedulers.asyncio import AsyncIOScheduler

async def async_job():
    async with aiohttp.ClientSession() as session:
        async with session.get('https://api.example.com') as response:
            data = await response.json()
            # Process data

scheduler = AsyncIOScheduler()
scheduler.add_job(async_job, 'interval', seconds=60)
scheduler.start()

# Keep event loop running
asyncio.get_event_loop().run_forever()
```

---

## Database Issues

### Symptom
Jobs not persisting or database errors.

### Diagnosis

1. **Check database connection:**
```python
from sqlalchemy import create_engine

engine = create_engine(DATABASE_URL)
try:
    with engine.connect() as conn:
        print("Database connection successful")
except Exception as e:
    print(f"Database connection failed: {e}")
```

2. **Check job store tables:**
```python
from sqlalchemy import inspect

inspector = inspect(engine)
tables = inspector.get_table_names()
print(f"APScheduler tables: {[t for t in tables if 'apscheduler' in t]}")
```

### Solutions

#### Solution 1: Create Job Store Tables
```python
from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore
from sqlalchemy import create_engine

engine = create_engine(DATABASE_URL)

# Create tables
SQLAlchemyJobStore(url=DATABASE_URL).start(scheduler, 'default')
```

#### Solution 2: Use Connection Pooling
```python
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True  # Verify connections before use
)

jobstores = {
    'default': SQLAlchemyJobStore(engine=engine)
}
```

#### Solution 3: Handle Database Errors
```python
from sqlalchemy.exc import OperationalError

def robust_job():
    max_retries = 3
    for attempt in range(max_retries):
        try:
            with session_factory() as session:
                # Database operations
                session.commit()
            break
        except OperationalError as e:
            if attempt < max_retries - 1:
                logger.warning(f"Database error, retrying: {e}")
                time.sleep(2 ** attempt)  # Exponential backoff
            else:
                logger.error(f"Database error after {max_retries} attempts: {e}")
                raise
```

---

## Memory Leaks

### Symptom
Memory usage grows over time.

### Diagnosis

1. **Monitor memory usage:**
```python
import psutil
import os

def log_memory():
    process = psutil.Process(os.getpid())
    memory_mb = process.memory_info().rss / 1024 / 1024
    logger.info(f"Memory usage: {memory_mb:.2f} MB")

scheduler.add_job(log_memory, 'interval', minutes=5)
```

2. **Check for unclosed resources:**
```python
import gc

def check_objects():
    objects = gc.get_objects()
    sessions = [obj for obj in objects if isinstance(obj, Session)]
    print(f"Open sessions: {len(sessions)}")
```

### Solutions

#### Solution 1: Close Database Sessions
```python
# ❌ Wrong: Session not closed
def leaky_job():
    session = Session(engine)
    # Do work
    # Session never closed

# ✅ Correct: Use context manager
def clean_job():
    with Session(engine) as session:
        # Do work
        session.commit()
    # Session automatically closed
```

#### Solution 2: Clear Job References
```python
def job_with_large_data():
    large_data = load_large_dataset()
    process_data(large_data)
    # Clear reference
    del large_data
    gc.collect()
```

#### Solution 3: Limit Job History
```python
# Clean up old execution logs
def cleanup_old_executions():
    cutoff = datetime.utcnow() - timedelta(days=30)
    with session_factory() as session:
        session.exec(
            delete(RecurringTaskExecution)
            .where(RecurringTaskExecution.executed_time < cutoff)
        )
        session.commit()

scheduler.add_job(cleanup_old_executions, 'cron', hour=2)
```

---

## Scheduler Not Starting

### Symptom
Scheduler fails to start or crashes on startup.

### Diagnosis

1. **Check for errors:**
```python
try:
    scheduler.start()
except Exception as e:
    logger.error(f"Failed to start scheduler: {e}", exc_info=True)
```

2. **Check port conflicts:**
```python
# If using web interface
import socket

def is_port_in_use(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

if is_port_in_use(8080):
    print("Port 8080 already in use")
```

### Solutions

#### Solution 1: Check Dependencies
```bash
pip install apscheduler pytz croniter sqlalchemy
```

#### Solution 2: Verify Configuration
```python
from apscheduler.schedulers.background import BackgroundScheduler

# Minimal configuration
scheduler = BackgroundScheduler()

try:
    scheduler.start()
    print("Scheduler started successfully")
except Exception as e:
    print(f"Failed to start: {e}")
```

#### Solution 3: Check for Blocking Operations
```python
# ❌ Wrong: Blocking operation in startup
scheduler.start()
time.sleep(1000)  # Blocks forever

# ✅ Correct: Non-blocking
scheduler.start()
# Continue with application
```

---

## Jobs Not Persisting

### Symptom
Jobs disappear after application restart.

### Diagnosis

1. **Check job store configuration:**
```python
print(f"Job stores: {scheduler._jobstores}")
```

2. **Check if using memory store:**
```python
from apscheduler.jobstores.memory import MemoryJobStore

for name, store in scheduler._jobstores.items():
    if isinstance(store, MemoryJobStore):
        print(f"Warning: {name} is using memory store (not persistent)")
```

### Solutions

#### Solution 1: Use Persistent Job Store
```python
from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore

jobstores = {
    'default': SQLAlchemyJobStore(url='postgresql://user:pass@localhost/db')
}

scheduler = BackgroundScheduler(jobstores=jobstores)
```

#### Solution 2: Reload Jobs on Startup
```python
def reload_recurring_tasks():
    """Reload all active recurring tasks on startup."""
    with session_factory() as session:
        tasks = session.exec(
            select(RecurringTask).where(RecurringTask.is_active == True)
        ).all()

        for task in tasks:
            scheduler_service.schedule_recurring_task(task)

        logger.info(f"Reloaded {len(tasks)} recurring tasks")

# Call on application startup
reload_recurring_tasks()
```

---

## Quick Reference: Common Error Messages

| Error Message | Cause | Solution |
|--------------|-------|----------|
| `No trigger defined` | Trigger not specified | Add trigger parameter |
| `Job not found` | Invalid job ID | Check job ID exists |
| `Scheduler not running` | Scheduler not started | Call `scheduler.start()` |
| `Database connection failed` | Invalid connection string | Verify DATABASE_URL |
| `Maximum number of running instances reached` | max_instances exceeded | Increase max_instances or wait |
| `Misfire grace time exceeded` | Job missed by too long | Increase misfire_grace_time |
| `Trigger has no next fire time` | Invalid cron expression | Verify cron syntax |

---

## Debugging Tips

1. **Enable debug logging:**
```python
import logging

logging.basicConfig(level=logging.DEBUG)
logging.getLogger('apscheduler').setLevel(logging.DEBUG)
```

2. **Add event listeners:**
```python
from apscheduler.events import EVENT_JOB_EXECUTED, EVENT_JOB_ERROR

def job_executed(event):
    logger.info(f"Job {event.job_id} executed successfully")

def job_error(event):
    logger.error(f"Job {event.job_id} failed: {event.exception}")

scheduler.add_listener(job_executed, EVENT_JOB_EXECUTED)
scheduler.add_listener(job_error, EVENT_JOB_ERROR)
```

3. **Monitor job queue:**
```python
def monitor_jobs():
    jobs = scheduler.get_jobs()
    for job in jobs:
        logger.info(f"Job {job.id}: next_run={job.next_run_time}")

scheduler.add_job(monitor_jobs, 'interval', minutes=5)
```

---

## Resources

- [APScheduler Documentation](https://apscheduler.readthedocs.io/)
- [Crontab Guru](https://crontab.guru/) - Cron expression tester
- [Python Logging](https://docs.python.org/3/library/logging.html)
