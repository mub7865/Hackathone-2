# FastAPI Recurring Tasks Integration

This example demonstrates a complete FastAPI application with recurring task scheduling using APScheduler.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     FastAPI Application                      │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │   REST API   │────────▶│  Scheduler   │                 │
│  │  Endpoints   │◀────────│   Service    │                 │
│  └──────────────┘         └──────────────┘                 │
│         │                         │                          │
│         │                         │                          │
│         ▼                         ▼                          │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │   Database   │         │ APScheduler  │                 │
│  │  (SQLModel)  │         │  Background  │                 │
│  └──────────────┘         └──────────────┘                 │
│         │                         │                          │
│         │                         │                          │
│         └─────────┬───────────────┘                          │
│                   │                                          │
│                   ▼                                          │
│            ┌──────────────┐                                 │
│            │ Task Instance│                                 │
│            │   Creation   │                                 │
│            └──────────────┘                                 │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
project/
├── app/
│   ├── main.py              # FastAPI app with scheduler
│   ├── models.py            # SQLModel definitions
│   ├── scheduler.py         # Scheduler service
│   ├── api/
│   │   ├── recurring_tasks.py  # Recurring tasks endpoints
│   │   └── tasks.py         # Task endpoints
│   └── utils/
│       └── next_occurrence.py  # Next occurrence calculation
├── alembic/                 # Database migrations
├── tests/
│   ├── test_recurring_tasks.py
│   └── test_scheduler.py
└── requirements.txt
```

## Implementation

### 1. Models (models.py)

```python
from sqlmodel import SQLModel, Field, Relationship
from datetime import datetime
from typing import Optional, List
from enum import Enum

class RecurrencePattern(str, Enum):
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    CUSTOM = "custom"

class RecurringTask(SQLModel, table=True):
    __tablename__ = "recurring_tasks"

    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    description: Optional[str] = None
    user_id: str = Field(index=True)

    # Scheduling
    pattern: RecurrencePattern
    cron_expression: Optional[str] = None
    hour: int = Field(default=9, ge=0, le=23)
    minute: int = Field(default=0, ge=0, le=59)
    day_of_week: Optional[int] = None  # 0-6 (Monday-Sunday)
    day_of_month: Optional[int] = None  # 1-31

    # Execution tracking
    start_date: datetime
    end_date: Optional[datetime] = None
    last_run: Optional[datetime] = None
    next_run: datetime

    # Configuration
    is_active: bool = True
    timezone: str = "UTC"

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationships
    task_instances: List["Task"] = Relationship(back_populates="recurring_task")

class Task(SQLModel, table=True):
    __tablename__ = "tasks"

    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    description: Optional[str] = None
    user_id: str = Field(index=True)
    completed: bool = False
    due_date: Optional[datetime] = None

    # Recurring task link
    is_recurring: bool = False
    recurring_task_id: Optional[int] = Field(default=None, foreign_key="recurring_tasks.id")
    recurring_task: Optional[RecurringTask] = Relationship(back_populates="task_instances")

    created_at: datetime = Field(default_factory=datetime.utcnow)
```

### 2. Scheduler Service (scheduler.py)

```python
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlmodel import Session, select
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class SchedulerService:
    def __init__(self, scheduler: BackgroundScheduler, session_factory):
        self.scheduler = scheduler
        self.session_factory = session_factory

    def schedule_recurring_task(self, recurring_task: RecurringTask):
        """Add recurring task to scheduler."""
        trigger = self._create_trigger(recurring_task)

        self.scheduler.add_job(
            func=self._create_task_instance,
            trigger=trigger,
            args=[recurring_task.id],
            id=f'recurring_{recurring_task.id}',
            replace_existing=True
        )

        logger.info(f"Scheduled recurring task: {recurring_task.id}")

    def _create_trigger(self, recurring_task):
        """Create APScheduler trigger."""
        import pytz
        tz = pytz.timezone(recurring_task.timezone)

        if recurring_task.pattern == RecurrencePattern.DAILY:
            return CronTrigger(
                hour=recurring_task.hour,
                minute=recurring_task.minute,
                timezone=tz
            )
        elif recurring_task.pattern == RecurrencePattern.WEEKLY:
            return CronTrigger(
                day_of_week=recurring_task.day_of_week,
                hour=recurring_task.hour,
                minute=recurring_task.minute,
                timezone=tz
            )
        elif recurring_task.pattern == RecurrencePattern.MONTHLY:
            return CronTrigger(
                day=recurring_task.day_of_month,
                hour=recurring_task.hour,
                minute=recurring_task.minute,
                timezone=tz
            )
        elif recurring_task.pattern == RecurrencePattern.CUSTOM:
            return CronTrigger.from_crontab(
                recurring_task.cron_expression,
                timezone=tz
            )

    def _create_task_instance(self, recurring_task_id: int):
        """Create new task instance."""
        with self.session_factory() as session:
            recurring_task = session.get(RecurringTask, recurring_task_id)

            if not recurring_task or not recurring_task.is_active:
                return

            # Create task instance
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
            recurring_task.last_run = datetime.utcnow()
            from utils.next_occurrence import calculate_next_occurrence
            recurring_task.next_run = calculate_next_occurrence(
                recurring_task.last_run,
                recurring_task.pattern,
                recurring_task.hour,
                recurring_task.minute,
                recurring_task.day_of_week,
                recurring_task.day_of_month,
                recurring_task.cron_expression,
                recurring_task.timezone
            )

            session.commit()
            logger.info(f"Created task instance {task.id}")
```

### 3. FastAPI Application (main.py)

```python
from fastapi import FastAPI, Depends
from sqlmodel import Session, create_engine, SQLModel
from contextlib import asynccontextmanager
from apscheduler.schedulers.background import BackgroundScheduler
from scheduler import SchedulerService
import logging

logging.basicConfig(level=logging.INFO)

# Database
DATABASE_URL = "sqlite:///./app.db"
engine = create_engine(DATABASE_URL)

def get_session():
    with Session(engine) as session:
        yield session

# Scheduler
scheduler = BackgroundScheduler()
scheduler_service = SchedulerService(
    scheduler=scheduler,
    session_factory=lambda: Session(engine)
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    SQLModel.metadata.create_all(engine)
    scheduler_service.schedule_all_active_tasks()
    scheduler.start()
    yield
    # Shutdown
    scheduler.shutdown()

app = FastAPI(lifespan=lifespan)

# Store in app state
app.state.scheduler_service = scheduler_service

# Include routers
from api import recurring_tasks, tasks
app.include_router(recurring_tasks.router)
app.include_router(tasks.router)

@app.get("/")
async def root():
    return {"message": "Recurring Tasks API"}
```

### 4. Recurring Tasks API (api/recurring_tasks.py)

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from models import RecurringTask, RecurrencePattern
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

router = APIRouter(prefix="/recurring-tasks", tags=["recurring-tasks"])

class RecurringTaskCreate(BaseModel):
    title: str
    description: Optional[str] = None
    pattern: RecurrencePattern
    cron_expression: Optional[str] = None
    hour: int = 9
    minute: int = 0
    day_of_week: Optional[int] = None
    day_of_month: Optional[int] = None
    start_date: datetime
    end_date: Optional[datetime] = None
    timezone: str = "UTC"

@router.post("/", response_model=RecurringTask)
async def create_recurring_task(
    task: RecurringTaskCreate,
    session: Session = Depends(get_session),
    scheduler_service = Depends(lambda: app.state.scheduler_service)
):
    """Create a new recurring task."""
    from utils.next_occurrence import calculate_first_occurrence

    # Calculate first occurrence
    next_run = calculate_first_occurrence(
        task.start_date,
        task.pattern,
        task.hour,
        task.minute,
        task.day_of_week,
        task.day_of_month,
        task.cron_expression,
        task.timezone
    )

    # Create recurring task
    recurring_task = RecurringTask(
        **task.dict(),
        user_id="user_123",  # Get from auth
        next_run=next_run
    )

    session.add(recurring_task)
    session.commit()
    session.refresh(recurring_task)

    # Schedule task
    scheduler_service.schedule_recurring_task(recurring_task)

    return recurring_task

@router.get("/", response_model=List[RecurringTask])
async def list_recurring_tasks(
    session: Session = Depends(get_session)
):
    """List all recurring tasks."""
    tasks = session.exec(select(RecurringTask)).all()
    return tasks

@router.get("/{task_id}", response_model=RecurringTask)
async def get_recurring_task(
    task_id: int,
    session: Session = Depends(get_session)
):
    """Get a specific recurring task."""
    task = session.get(RecurringTask, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task

@router.put("/{task_id}", response_model=RecurringTask)
async def update_recurring_task(
    task_id: int,
    task_update: RecurringTaskCreate,
    session: Session = Depends(get_session),
    scheduler_service = Depends(lambda: app.state.scheduler_service)
):
    """Update a recurring task."""
    task = session.get(RecurringTask, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Update fields
    for key, value in task_update.dict(exclude_unset=True).items():
        setattr(task, key, value)

    # Recalculate next run
    from utils.next_occurrence import calculate_next_occurrence
    task.next_run = calculate_next_occurrence(
        task.last_run or task.start_date,
        task.pattern,
        task.hour,
        task.minute,
        task.day_of_week,
        task.day_of_month,
        task.cron_expression,
        task.timezone
    )

    session.commit()
    session.refresh(task)

    # Reschedule
    scheduler_service.reschedule_recurring_task(task)

    return task

@router.delete("/{task_id}")
async def delete_recurring_task(
    task_id: int,
    session: Session = Depends(get_session),
    scheduler_service = Depends(lambda: app.state.scheduler_service)
):
    """Delete a recurring task."""
    task = session.get(RecurringTask, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Unschedule
    scheduler_service.unschedule_recurring_task(task_id)

    # Delete from database
    session.delete(task)
    session.commit()

    return {"message": "Task deleted"}

@router.post("/{task_id}/pause")
async def pause_recurring_task(
    task_id: int,
    session: Session = Depends(get_session),
    scheduler_service = Depends(lambda: app.state.scheduler_service)
):
    """Pause a recurring task."""
    task = session.get(RecurringTask, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    task.is_active = False
    session.commit()

    scheduler_service.pause_recurring_task(task_id)

    return {"message": "Task paused"}

@router.post("/{task_id}/resume")
async def resume_recurring_task(
    task_id: int,
    session: Session = Depends(get_session),
    scheduler_service = Depends(lambda: app.state.scheduler_service)
):
    """Resume a recurring task."""
    task = session.get(RecurringTask, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    task.is_active = True
    session.commit()

    scheduler_service.resume_recurring_task(task_id)

    return {"message": "Task resumed"}
```

## Running the Example

### 1. Install Dependencies

```bash
pip install fastapi uvicorn sqlmodel apscheduler python-dateutil croniter pytz
```

### 2. Run the Application

```bash
uvicorn main:app --reload
```

### 3. Test the API

```bash
# Create daily recurring task
curl -X POST http://localhost:8000/recurring-tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Daily standup",
    "description": "Daily standup meeting reminder",
    "pattern": "daily",
    "hour": 9,
    "minute": 0,
    "start_date": "2024-01-01T09:00:00",
    "timezone": "America/New_York"
  }'

# Create weekly recurring task
curl -X POST http://localhost:8000/recurring-tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Weekly report",
    "description": "Submit weekly progress report",
    "pattern": "weekly",
    "day_of_week": 4,
    "hour": 17,
    "minute": 0,
    "start_date": "2024-01-05T17:00:00",
    "timezone": "America/New_York"
  }'

# List all recurring tasks
curl http://localhost:8000/recurring-tasks

# Pause a recurring task
curl -X POST http://localhost:8000/recurring-tasks/1/pause

# Resume a recurring task
curl -X POST http://localhost:8000/recurring-tasks/1/resume

# Delete a recurring task
curl -X DELETE http://localhost:8000/recurring-tasks/1
```

## Key Features

1. **Multiple Patterns**: Daily, weekly, monthly, and custom cron expressions
2. **Timezone Support**: Each task can have its own timezone
3. **Pause/Resume**: Temporarily disable tasks without deleting them
4. **Automatic Scheduling**: Tasks are automatically scheduled on creation
5. **Next Occurrence Calculation**: Automatically calculates next run time
6. **Task Instance Creation**: Creates task instances at scheduled times
7. **Database Persistence**: All schedules stored in database

## Next Steps

- Add user authentication and authorization
- Implement task completion tracking
- Add notifications when tasks are created
- Implement missed execution handling
- Add task history and execution logs
- Create frontend UI for managing recurring tasks
