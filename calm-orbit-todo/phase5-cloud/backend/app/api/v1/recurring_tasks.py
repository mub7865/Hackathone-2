"""Recurring tasks API endpoints.

This module provides REST API endpoints for managing recurring task patterns.
All endpoints require JWT authentication and enforce user isolation.
"""

from datetime import datetime
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from app.api.deps import CurrentUser, DbSession
from app.models.recurring_patterns import EndCondition, RecurrenceFrequency
from app.services.recurring_task_service import RecurringTaskService

router = APIRouter()


# Request/Response Schemas
class RecurringPatternCreate(BaseModel):
    """Schema for creating a recurring pattern."""

    original_task_id: UUID = Field(..., description="ID of the original task")
    frequency: RecurrenceFrequency = Field(..., description="Recurrence frequency")
    interval: int = Field(1, ge=1, description="Interval for recurrence")
    days_of_week: Optional[List[int]] = Field(
        None, description="Weekday numbers (0=Sunday, 6=Saturday)"
    )
    day_of_month: Optional[int] = Field(
        None, ge=-1, le=31, description="Day of month (1-31, -1=last day)"
    )
    month_of_year: Optional[int] = Field(
        None, ge=1, le=12, description="Month number (1-12)"
    )
    cron_expression: Optional[str] = Field(
        None, max_length=100, description="Cron expression for custom recurrence"
    )
    end_condition: EndCondition = Field(
        EndCondition.INDEFINITE, description="How the pattern ends"
    )
    end_date: Optional[datetime] = Field(None, description="End date")
    occurrence_count: Optional[int] = Field(
        None, ge=1, description="Total occurrences"
    )


class RecurringPatternUpdate(BaseModel):
    """Schema for updating a recurring pattern."""

    interval: Optional[int] = Field(None, ge=1)
    days_of_week: Optional[List[int]] = None
    day_of_month: Optional[int] = Field(None, ge=-1, le=31)
    month_of_year: Optional[int] = Field(None, ge=1, le=12)
    cron_expression: Optional[str] = Field(None, max_length=100)
    end_condition: Optional[EndCondition] = None
    end_date: Optional[datetime] = None
    occurrence_count: Optional[int] = Field(None, ge=1)


class RecurringPatternResponse(BaseModel):
    """Schema for recurring pattern response."""

    id: UUID
    user_id: str
    original_task_id: UUID
    frequency: RecurrenceFrequency
    interval: int
    days_of_week: Optional[List[int]]
    day_of_month: Optional[int]
    month_of_year: Optional[int]
    cron_expression: Optional[str]
    end_condition: EndCondition
    end_date: Optional[datetime]
    occurrence_count: Optional[int]
    current_count: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class TaskInstanceResponse(BaseModel):
    """Schema for generated task instance response."""

    task_id: UUID
    title: str
    due_date: Optional[datetime]
    status: str
    message: str


@router.post(
    "",
    response_model=RecurringPatternResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a recurring pattern",
    description="Creates a recurring pattern for automatic task generation",
)
async def create_recurring_pattern(
    db: DbSession,
    user_id: CurrentUser,
    pattern_in: RecurringPatternCreate,
) -> RecurringPatternResponse:
    """Create a new recurring pattern.

    Args:
        db: Database session.
        user_id: Authenticated user ID from JWT.
        pattern_in: Recurring pattern creation data.

    Returns:
        Created RecurringPatternResponse with 201 status.

    Raises:
        HTTPException: If validation fails or original task not found.
    """
    service = RecurringTaskService(db)

    try:
        pattern = await service.create_recurring_pattern(
            user_id=user_id,
            original_task_id=pattern_in.original_task_id,
            frequency=pattern_in.frequency,
            interval=pattern_in.interval,
            days_of_week=pattern_in.days_of_week,
            day_of_month=pattern_in.day_of_month,
            month_of_year=pattern_in.month_of_year,
            cron_expression=pattern_in.cron_expression,
            end_condition=pattern_in.end_condition,
            end_date=pattern_in.end_date,
            occurrence_count=pattern_in.occurrence_count,
        )

        await db.commit()
        await db.refresh(pattern)

        return RecurringPatternResponse.model_validate(pattern)

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.get(
    "",
    response_model=List[RecurringPatternResponse],
    summary="List user's recurring patterns",
    description="Returns all recurring patterns owned by authenticated user",
)
async def list_recurring_patterns(
    db: DbSession,
    user_id: CurrentUser,
) -> List[RecurringPatternResponse]:
    """List all recurring patterns for the authenticated user.

    Args:
        db: Database session.
        user_id: Authenticated user ID from JWT.

    Returns:
        List of RecurringPatternResponse objects.
    """
    service = RecurringTaskService(db)
    patterns = await service.get_patterns_by_user(user_id)

    return [RecurringPatternResponse.model_validate(p) for p in patterns]


@router.get(
    "/{pattern_id}",
    response_model=RecurringPatternResponse,
    summary="Get a recurring pattern",
    description="Returns recurring pattern if owned by authenticated user",
)
async def get_recurring_pattern(
    db: DbSession,
    user_id: CurrentUser,
    pattern_id: UUID,
) -> RecurringPatternResponse:
    """Get a single recurring pattern by ID.

    Args:
        db: Database session.
        user_id: Authenticated user ID from JWT.
        pattern_id: Pattern UUID from path.

    Returns:
        RecurringPatternResponse if found and owned by user.

    Raises:
        HTTPException: If pattern not found or not owned.
    """
    service = RecurringTaskService(db)
    pattern = await service.get_pattern_by_id(pattern_id, user_id)

    if pattern is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Recurring pattern {pattern_id} not found",
        )

    return RecurringPatternResponse.model_validate(pattern)


@router.patch(
    "/{pattern_id}",
    response_model=RecurringPatternResponse,
    summary="Update a recurring pattern",
    description="Partial update of recurring pattern owned by authenticated user",
)
async def update_recurring_pattern(
    db: DbSession,
    user_id: CurrentUser,
    pattern_id: UUID,
    pattern_in: RecurringPatternUpdate,
) -> RecurringPatternResponse:
    """Update an existing recurring pattern.

    Args:
        db: Database session.
        user_id: Authenticated user ID from JWT.
        pattern_id: Pattern UUID from path.
        pattern_in: Update data (all fields optional).

    Returns:
        Updated RecurringPatternResponse.

    Raises:
        HTTPException: If pattern not found or not owned.
    """
    service = RecurringTaskService(db)

    # Build updates dict from non-None fields
    updates = pattern_in.model_dump(exclude_unset=True)

    pattern = await service.update_pattern(pattern_id, user_id, updates)

    if pattern is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Recurring pattern {pattern_id} not found",
        )

    await db.commit()
    await db.refresh(pattern)

    return RecurringPatternResponse.model_validate(pattern)


@router.delete(
    "/{pattern_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a recurring pattern",
    description="Permanently deletes recurring pattern owned by authenticated user",
)
async def delete_recurring_pattern(
    db: DbSession,
    user_id: CurrentUser,
    pattern_id: UUID,
) -> None:
    """Delete a recurring pattern.

    Args:
        db: Database session.
        user_id: Authenticated user ID from JWT.
        pattern_id: Pattern UUID from path.

    Returns:
        204 No Content on success.

    Raises:
        HTTPException: If pattern not found or not owned.
    """
    service = RecurringTaskService(db)
    deleted = await service.delete_pattern(pattern_id, user_id)

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Recurring pattern {pattern_id} not found",
        )

    await db.commit()


@router.post(
    "/{pattern_id}/generate",
    response_model=TaskInstanceResponse,
    summary="Generate next task instance",
    description="Manually generate the next task instance for a recurring pattern",
)
async def generate_task_instance(
    db: DbSession,
    user_id: CurrentUser,
    pattern_id: UUID,
) -> TaskInstanceResponse:
    """Generate the next task instance for a recurring pattern.

    This endpoint is primarily for testing and manual triggering.
    In production, the scheduler service will automatically generate instances.

    Args:
        db: Database session.
        user_id: Authenticated user ID from JWT.
        pattern_id: Pattern UUID from path.

    Returns:
        TaskInstanceResponse with generated task details.

    Raises:
        HTTPException: If pattern not found, not owned, or has ended.
    """
    service = RecurringTaskService(db)

    # Get pattern
    pattern = await service.get_pattern_by_id(pattern_id, user_id)
    if pattern is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Recurring pattern {pattern_id} not found",
        )

    # Generate next task instance
    task = await service.generate_next_task_instance(pattern)

    if task is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Recurring pattern has ended or cannot generate next occurrence",
        )

    await db.commit()
    await db.refresh(task)

    return TaskInstanceResponse(
        task_id=task.id,
        title=task.title,
        due_date=task.due_date,
        status=task.status.value,
        message=f"Generated task instance {pattern.current_count} of {pattern.occurrence_count or 'unlimited'}",
    )
