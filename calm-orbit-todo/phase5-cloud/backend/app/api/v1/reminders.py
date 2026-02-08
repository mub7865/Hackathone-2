"""Reminder notification API endpoints.

This module provides REST API endpoints for managing task reminders
and viewing reminder statistics.
"""

from datetime import datetime
from typing import List
from uuid import UUID

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from app.api.deps import CurrentUser, DbSession
from app.services.reminder_service import ReminderService

router = APIRouter()


# Request/Response Schemas
class ReminderSetRequest(BaseModel):
    """Schema for setting a reminder."""

    remind_at: datetime = Field(..., description="Reminder datetime (UTC)")


class ReminderResponse(BaseModel):
    """Schema for reminder response."""

    task_id: UUID
    title: str
    due_date: datetime | None
    remind_at: datetime | None
    message: str


class TaskSummary(BaseModel):
    """Schema for task summary in reminder lists."""

    id: UUID
    title: str
    description: str | None
    due_date: datetime | None
    remind_at: datetime | None
    priority: str
    tags: List[str]
    created_at: datetime

    class Config:
        from_attributes = True


class ReminderStatistics(BaseModel):
    """Schema for reminder statistics."""

    total_with_reminders: int
    upcoming_reminders_24h: int
    overdue_tasks: int
    due_today: int


@router.post(
    "/{task_id}/reminder",
    response_model=ReminderResponse,
    summary="Set a reminder for a task",
    description="Sets a reminder time for a task owned by authenticated user",
)
async def set_task_reminder(
    db: DbSession,
    user_id: CurrentUser,
    task_id: UUID,
    reminder_in: ReminderSetRequest,
) -> ReminderResponse:
    """Set a reminder for a task.

    Args:
        db: Database session.
        user_id: Authenticated user ID from JWT.
        task_id: Task UUID from path.
        reminder_in: Reminder datetime.

    Returns:
        ReminderResponse with updated task details.

    Raises:
        HTTPException: If task not found, not owned, or validation fails.
    """
    service = ReminderService(db)

    try:
        task = await service.set_reminder(task_id, user_id, reminder_in.remind_at)

        if task is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Task {task_id} not found",
            )

        await db.commit()
        await db.refresh(task)

        return ReminderResponse(
            task_id=task.id,
            title=task.title,
            due_date=task.due_date,
            remind_at=task.remind_at,
            message=f"Reminder set for {task.remind_at.isoformat()}",
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.delete(
    "/{task_id}/reminder",
    response_model=ReminderResponse,
    summary="Clear a task reminder",
    description="Removes the reminder from a task owned by authenticated user",
)
async def clear_task_reminder(
    db: DbSession,
    user_id: CurrentUser,
    task_id: UUID,
) -> ReminderResponse:
    """Clear a task reminder.

    Args:
        db: Database session.
        user_id: Authenticated user ID from JWT.
        task_id: Task UUID from path.

    Returns:
        ReminderResponse confirming reminder was cleared.

    Raises:
        HTTPException: If task not found or not owned.
    """
    service = ReminderService(db)

    task = await service.clear_reminder(task_id, user_id)

    if task is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task {task_id} not found",
        )

    await db.commit()
    await db.refresh(task)

    return ReminderResponse(
        task_id=task.id,
        title=task.title,
        due_date=task.due_date,
        remind_at=None,
        message="Reminder cleared",
    )


@router.get(
    "/upcoming",
    response_model=List[TaskSummary],
    summary="Get tasks with upcoming reminders",
    description="Returns tasks with reminders due in the next 24 hours",
)
async def get_upcoming_reminders(
    db: DbSession,
    user_id: CurrentUser,
) -> List[TaskSummary]:
    """Get tasks with upcoming reminders.

    Args:
        db: Database session.
        user_id: Authenticated user ID from JWT.

    Returns:
        List of TaskSummary objects with upcoming reminders.
    """
    service = ReminderService(db)
    tasks = await service.get_tasks_with_upcoming_reminders(time_window_minutes=1440)  # 24 hours

    # Filter by user
    user_tasks = [task for task in tasks if task.user_id == user_id]

    return [TaskSummary.model_validate(task) for task in user_tasks]


@router.get(
    "/overdue",
    response_model=List[TaskSummary],
    summary="Get overdue tasks",
    description="Returns tasks that are past their due date",
)
async def get_overdue_tasks(
    db: DbSession,
    user_id: CurrentUser,
) -> List[TaskSummary]:
    """Get overdue tasks.

    Args:
        db: Database session.
        user_id: Authenticated user ID from JWT.

    Returns:
        List of TaskSummary objects for overdue tasks.
    """
    service = ReminderService(db)
    tasks = await service.get_overdue_tasks(user_id)

    return [TaskSummary.model_validate(task) for task in tasks]


@router.get(
    "/due-today",
    response_model=List[TaskSummary],
    summary="Get tasks due today",
    description="Returns tasks due today",
)
async def get_tasks_due_today(
    db: DbSession,
    user_id: CurrentUser,
) -> List[TaskSummary]:
    """Get tasks due today.

    Args:
        db: Database session.
        user_id: Authenticated user ID from JWT.

    Returns:
        List of TaskSummary objects for tasks due today.
    """
    service = ReminderService(db)
    tasks = await service.get_tasks_due_today(user_id)

    return [TaskSummary.model_validate(task) for task in tasks]


@router.get(
    "/due-this-week",
    response_model=List[TaskSummary],
    summary="Get tasks due this week",
    description="Returns tasks due in the next 7 days",
)
async def get_tasks_due_this_week(
    db: DbSession,
    user_id: CurrentUser,
) -> List[TaskSummary]:
    """Get tasks due this week.

    Args:
        db: Database session.
        user_id: Authenticated user ID from JWT.

    Returns:
        List of TaskSummary objects for tasks due this week.
    """
    service = ReminderService(db)
    tasks = await service.get_tasks_due_this_week(user_id)

    return [TaskSummary.model_validate(task) for task in tasks]


@router.get(
    "/statistics",
    response_model=ReminderStatistics,
    summary="Get reminder statistics",
    description="Returns reminder statistics for authenticated user",
)
async def get_reminder_statistics(
    db: DbSession,
    user_id: CurrentUser,
) -> ReminderStatistics:
    """Get reminder statistics.

    Args:
        db: Database session.
        user_id: Authenticated user ID from JWT.

    Returns:
        ReminderStatistics with counts and metrics.
    """
    service = ReminderService(db)
    stats = await service.get_reminder_statistics(user_id)

    return ReminderStatistics(**stats)
