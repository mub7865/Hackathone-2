"""
APScheduler Setup Template

This template provides complete APScheduler configuration for
recurring task scheduling with FastAPI integration.
"""

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore
from apscheduler.jobstores.memory import MemoryJobStore
from apscheduler.executors.pool import ThreadPoolExecutor, ProcessPoolExecutor
from apscheduler.events import (
    EVENT_JOB_EXECUTED,
    EVENT_JOB_ERROR,
    EVENT_JOB_MISSED,
    EVENT_JOB_ADDED,
    EVENT_JOB_REMOVED
)
from contextlib import asynccontextmanager
from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)


# ============================================================================
# Scheduler Configuration
# ============================================================================

def create_background_scheduler(
    database_url: str = "sqlite:///./scheduler.db",
    max_workers: int = 10,
    timezone: str = "UTC"
) -> BackgroundScheduler:
    """
    Create BackgroundScheduler for synchronous applications.

    Args:
        database_url: Database URL for persistent job store
        max_workers: Maximum number of worker threads
        timezone: Default timezone for scheduling

    Returns:
        Configured BackgroundScheduler instance
    """

    # Job stores
    jobstores = {
        'default': SQLAlchemyJobStore(url=database_url),
        'memory': MemoryJobStore()  # For temporary jobs
    }

    # Executors
    executors = {
        'default': ThreadPoolExecutor(max_workers),
        'processpool': ProcessPoolExecutor(max_workers=5)
    }

    # Job defaults
    job_defaults = {
        'coalesce': True,  # Combine multiple missed executions into one
        'max_instances': 1,  # Only one instance of job can run at a time
        'misfire_grace_time': 300,  # 5 minutes grace period for missed jobs
        'replace_existing': False  # Don't replace existing jobs by default
    }

    # Create scheduler
    scheduler = BackgroundScheduler(
        jobstores=jobstores,
        executors=executors,
        job_defaults=job_defaults,
        timezone=timezone
    )

    # Add event listeners
    scheduler.add_listener(
        job_executed_listener,
        EVENT_JOB_EXECUTED
    )
    scheduler.add_listener(
        job_error_listener,
        EVENT_JOB_ERROR
    )
    scheduler.add_listener(
        job_missed_listener,
        EVENT_JOB_MISSED
    )

    return scheduler


def create_asyncio_scheduler(
    database_url: str = "sqlite:///./scheduler.db",
    max_workers: int = 10,
    timezone: str = "UTC"
) -> AsyncIOScheduler:
    """
    Create AsyncIOScheduler for async applications.

    Args:
        database_url: Database URL for persistent job store
        max_workers: Maximum number of worker threads
        timezone: Default timezone for scheduling

    Returns:
        Configured AsyncIOScheduler instance
    """

    # Job stores
    jobstores = {
        'default': SQLAlchemyJobStore(url=database_url)
    }

    # Executors
    executors = {
        'default': ThreadPoolExecutor(max_workers)
    }

    # Job defaults
    job_defaults = {
        'coalesce': True,
        'max_instances': 1,
        'misfire_grace_time': 300
    }

    # Create scheduler
    scheduler = AsyncIOScheduler(
        jobstores=jobstores,
        executors=executors,
        job_defaults=job_defaults,
        timezone=timezone
    )

    # Add event listeners
    scheduler.add_listener(
        job_executed_listener,
        EVENT_JOB_EXECUTED
    )
    scheduler.add_listener(
        job_error_listener,
        EVENT_JOB_ERROR
    )

    return scheduler


# ============================================================================
# Event Listeners
# ============================================================================

def job_executed_listener(event):
    """Handle successful job execution."""
    logger.info(
        f"Job {event.job_id} executed successfully",
        extra={
            'job_id': event.job_id,
            'scheduled_run_time': event.scheduled_run_time,
            'retval': event.retval
        }
    )


def job_error_listener(event):
    """Handle job execution errors."""
    logger.error(
        f"Job {event.job_id} failed: {event.exception}",
        extra={
            'job_id': event.job_id,
            'scheduled_run_time': event.scheduled_run_time,
            'exception': str(event.exception)
        },
        exc_info=True
    )


def job_missed_listener(event):
    """Handle missed job executions."""
    logger.warning(
        f"Job {event.job_id} missed execution",
        extra={
            'job_id': event.job_id,
            'scheduled_run_time': event.scheduled_run_time
        }
    )


def job_added_listener(event):
    """Handle job addition."""
    logger.info(f"Job {event.job_id} added to scheduler")


def job_removed_listener(event):
    """Handle job removal."""
    logger.info(f"Job {event.job_id} removed from scheduler")


# ============================================================================
# FastAPI Integration
# ============================================================================

@asynccontextmanager
async def scheduler_lifespan(app: FastAPI):
    """
    FastAPI lifespan context manager for scheduler.

    Usage:
        app = FastAPI(lifespan=scheduler_lifespan)
    """

    # Startup
    logger.info("Starting scheduler...")

    # Get scheduler from app state
    scheduler = app.state.scheduler

    # Start scheduler
    scheduler.start()
    logger.info("Scheduler started")

    # Schedule initial jobs
    if hasattr(app.state, 'scheduler_service'):
        scheduler_service = app.state.scheduler_service
        count = scheduler_service.schedule_all_active_tasks()
        logger.info(f"Scheduled {count} active recurring tasks")

    yield

    # Shutdown
    logger.info("Stopping scheduler...")
    scheduler.shutdown(wait=True)
    logger.info("Scheduler stopped")


def setup_scheduler(app: FastAPI, database_url: str, session_factory):
    """
    Set up scheduler for FastAPI application.

    Args:
        app: FastAPI application instance
        database_url: Database URL for job store
        session_factory: Factory function to create database sessions
    """

    # Create scheduler
    scheduler = create_background_scheduler(
        database_url=database_url,
        max_workers=10,
        timezone="UTC"
    )

    # Store in app state
    app.state.scheduler = scheduler

    # Create scheduler service
    from scheduler_service import SchedulerService

    scheduler_service = SchedulerService(
        scheduler=scheduler,
        session_factory=session_factory,
        timezone="UTC"
    )

    app.state.scheduler_service = scheduler_service


# ============================================================================
# Scheduler Management Endpoints
# ============================================================================

from fastapi import APIRouter, Depends, HTTPException
from typing import List

router = APIRouter(prefix="/scheduler", tags=["scheduler"])


@router.get("/jobs")
async def list_jobs(
    scheduler_service = Depends(lambda: app.state.scheduler_service)
) -> List[dict]:
    """List all scheduled jobs."""
    return scheduler_service.get_scheduled_jobs()


@router.get("/jobs/{recurring_task_id}")
async def get_job(
    recurring_task_id: int,
    scheduler_service = Depends(lambda: app.state.scheduler_service)
) -> dict:
    """Get information about a specific job."""
    job_info = scheduler_service.get_job_info(recurring_task_id)

    if not job_info:
        raise HTTPException(status_code=404, detail="Job not found")

    return job_info


@router.post("/jobs/{recurring_task_id}/pause")
async def pause_job(
    recurring_task_id: int,
    scheduler_service = Depends(lambda: app.state.scheduler_service)
):
    """Pause a scheduled job."""
    scheduler_service.pause_recurring_task(recurring_task_id)
    return {"message": "Job paused"}


@router.post("/jobs/{recurring_task_id}/resume")
async def resume_job(
    recurring_task_id: int,
    scheduler_service = Depends(lambda: app.state.scheduler_service)
):
    """Resume a paused job."""
    scheduler_service.resume_recurring_task(recurring_task_id)
    return {"message": "Job resumed"}


@router.post("/jobs/{recurring_task_id}/trigger")
async def trigger_job(
    recurring_task_id: int,
    scheduler_service = Depends(lambda: app.state.scheduler_service)
):
    """Manually trigger a job execution."""
    scheduler = scheduler_service.scheduler
    job_id = f'recurring_{recurring_task_id}'

    try:
        job = scheduler.get_job(job_id)
        if not job:
            raise HTTPException(status_code=404, detail="Job not found")

        # Trigger job immediately
        job.modify(next_run_time=datetime.now())

        return {"message": "Job triggered"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/status")
async def scheduler_status(
    scheduler_service = Depends(lambda: app.state.scheduler_service)
) -> dict:
    """Get scheduler status."""
    scheduler = scheduler_service.scheduler

    return {
        "running": scheduler.running,
        "state": scheduler.state,
        "job_count": len(scheduler.get_jobs())
    }


# ============================================================================
# Complete FastAPI Application Example
# ============================================================================

from sqlmodel import create_engine, Session

# Create database engine
engine = create_engine("sqlite:///./app.db")


def get_session():
    """Database session dependency."""
    with Session(engine) as session:
        yield session


# Create FastAPI app
app = FastAPI(lifespan=scheduler_lifespan)

# Setup scheduler
setup_scheduler(
    app=app,
    database_url="sqlite:///./scheduler.db",
    session_factory=lambda: Session(engine)
)

# Include scheduler management routes
app.include_router(router)


@app.get("/")
async def root():
    return {"message": "Recurring Tasks API"}


@app.get("/health")
async def health():
    """Health check endpoint."""
    scheduler = app.state.scheduler

    return {
        "status": "healthy",
        "scheduler_running": scheduler.running,
        "job_count": len(scheduler.get_jobs())
    }


# ============================================================================
# Standalone Scheduler (without FastAPI)
# ============================================================================

def run_standalone_scheduler():
    """Run scheduler as standalone application."""

    # Create scheduler
    scheduler = create_background_scheduler(
        database_url="sqlite:///./scheduler.db",
        max_workers=10,
        timezone="UTC"
    )

    # Create session factory
    engine = create_engine("sqlite:///./app.db")

    def get_session():
        return Session(engine)

    # Create scheduler service
    from scheduler_service import SchedulerService

    scheduler_service = SchedulerService(
        scheduler=scheduler,
        session_factory=get_session,
        timezone="UTC"
    )

    # Schedule all active tasks
    scheduler_service.schedule_all_active_tasks()

    # Start scheduler
    scheduler.start()
    logger.info("Scheduler started")

    # Keep running
    try:
        import time
        while True:
            time.sleep(1)
    except (KeyboardInterrupt, SystemExit):
        logger.info("Shutting down scheduler...")
        scheduler.shutdown(wait=True)
        logger.info("Scheduler stopped")


# ============================================================================
# Usage Example
# ============================================================================

if __name__ == "__main__":
    # Option 1: Run with FastAPI
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

    # Option 2: Run standalone
    # run_standalone_scheduler()
