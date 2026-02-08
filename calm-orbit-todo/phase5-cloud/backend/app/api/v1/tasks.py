"""Tasks API endpoints - CRUD operations for user tasks.

All endpoints require JWT authentication and enforce user isolation.
Implements FR-001 to FR-024 from the spec (Chunk 4 additions for search/sort).
Phase 5: Added event publishing for task operations.
Phase 9: Added audit logging for task operations.
"""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Query, Request, Response, status
from sqlalchemy import func, or_
from sqlmodel import select

from app.api.deps import CurrentUser, DbSession
from app.core.exceptions import TaskNotFoundError
from app.events.producer import publish_task_event
from app.models.audit_log import AuditAction
from app.models.task import Task, TaskStatus, TaskPriority
from app.schemas.task import TaskCreate, TaskResponse, TaskUpdate, SortField, SortOrder
from app.services.audit_service import AuditService

router = APIRouter()


@router.get(
    "",
    response_model=list[TaskResponse],
    summary="List user's tasks",
    description="Returns paginated list of tasks owned by authenticated user with search, sort, and filter options",
)
async def list_tasks(
    db: DbSession,
    user_id: CurrentUser,
    offset: int = Query(0, ge=0, description="Number of items to skip"),
    limit: int = Query(20, ge=1, le=100, description="Max items to return (1-100)"),
    status: TaskStatus | None = Query(None, description="Filter by status"),
    priority: TaskPriority | None = Query(None, description="Filter by priority (high, medium, or low)"),
    tags: list[str] | None = Query(None, description="Filter by tags (returns tasks with ANY of the specified tags)"),
    search: str | None = Query(
        None,
        max_length=100,
        description="Search in title and description (case-insensitive, max 100 chars)",
    ),
    sort: SortField = Query(
        SortField.CREATED_AT,
        description="Field to sort by (created_at, title, or priority)",
    ),
    order: SortOrder = Query(
        SortOrder.DESC,
        description="Sort direction (asc or desc)",
    ),
) -> list[TaskResponse]:
    """List tasks for the authenticated user.

    Supports pagination via offset/limit, status and priority filtering, tag filtering,
    free-text search, and configurable sorting.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        offset: Number of items to skip (default 0)
        limit: Max items to return (default 20, max 100)
        status: Optional status filter (pending or completed)
        priority: Optional priority filter (high, medium, or low)
        tags: Optional tag filter (returns tasks with ANY of the specified tags)
        search: Optional search term for title/description (case-insensitive)
        sort: Sort field (created_at, title, or priority, default created_at)
        order: Sort direction (asc or desc, default desc)

    Returns:
        List of TaskResponse objects
    """
    # Build query with user isolation (FR-024)
    query = select(Task).where(Task.user_id == user_id)

    # Apply status filter if provided (FR-004: AND logic)
    if status is not None:
        query = query.where(Task.status == status)

    # Phase 5: Apply priority filter if provided
    if priority is not None:
        query = query.where(Task.priority == priority)

    # Phase 6: Apply tags filter if provided (returns tasks with ANY of the specified tags)
    if tags is not None and len(tags) > 0:
        # Use PostgreSQL array overlap operator to check if any tags match
        query = query.where(Task.tags.overlap(tags))

    # Apply search filter if provided (FR-001, FR-002, FR-003, FR-005)
    if search is not None:
        search_term = search.strip()
        if search_term:  # Only apply if not empty/whitespace
            search_pattern = f"%{search_term}%"
            query = query.where(
                or_(
                    Task.title.ilike(search_pattern),
                    Task.description.ilike(search_pattern),
                )
            )

    # Apply sorting (FR-008, FR-009, FR-010, Phase 5: added priority)
    if sort == SortField.TITLE:
        # Case-insensitive title sort (FR-009)
        sort_column = func.lower(Task.title)
    elif sort == SortField.PRIORITY:
        # Phase 5: Priority sort (high > medium > low)
        # Use CASE to map priority to numeric values for sorting
        sort_column = func.case(
            (Task.priority == TaskPriority.HIGH, 3),
            (Task.priority == TaskPriority.MEDIUM, 2),
            (Task.priority == TaskPriority.LOW, 1),
            else_=0
        )
    else:
        # Default: created_at (FR-010)
        sort_column = Task.created_at

    if order == SortOrder.ASC:
        query = query.order_by(sort_column.asc())
    else:
        query = query.order_by(sort_column.desc())

    # Apply pagination (FR-012, FR-013)
    query = query.offset(offset).limit(limit)

    result = await db.execute(query)
    tasks = result.scalars().all()

    return [TaskResponse.model_validate(task) for task in tasks]


@router.post(
    "",
    response_model=TaskResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new task",
    description="Creates a task owned by the authenticated user",
)
async def create_task(
    db: DbSession,
    user_id: CurrentUser,
    task_in: TaskCreate,
    request: Request,
    response: Response,
) -> TaskResponse:
    """Create a new task for the authenticated user.

    The user_id is automatically set from the JWT token.
    Status defaults to 'pending'.
    Priority defaults to 'medium' if not specified.
    Tags default to empty list if not specified.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        task_in: Task creation data (title, optional description, optional priority, optional tags)
        request: FastAPI request object for audit metadata
        response: FastAPI response object for setting headers

    Returns:
        Created TaskResponse with 201 status
    """
    # Create task with user_id from JWT
    task = Task(
        user_id=user_id,
        title=task_in.title,
        description=task_in.description,
        priority=task_in.priority if task_in.priority is not None else TaskPriority.MEDIUM,
        tags=task_in.tags if task_in.tags is not None else [],
    )

    db.add(task)
    await db.commit()
    await db.refresh(task)

    # Phase 5: Publish task.created event
    await publish_task_event(
        event_type="created",
        task_id=task.id,
        user_id=user_id,
        title=task.title,
        description=task.description,
        status=task.status.value if hasattr(task.status, 'value') else task.status,
        priority=task.priority.value if hasattr(task.priority, 'value') else task.priority,
        tags=task.tags,
        due_date=task.due_date,
        remind_at=task.remind_at,
        recurring_pattern_id=task.recurring_pattern_id,
    )

    # Phase 9: Log audit trail
    audit_service = AuditService(db)
    await audit_service.log_action(
        user_id=user_id,
        action=AuditAction.CREATED,
        resource_type="task",
        resource_id=task.id,
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    )

    # Set Location header per FR-014
    response.headers["Location"] = f"/api/v1/tasks/{task.id}"

    return TaskResponse.model_validate(task)


@router.get(
    "/{task_id}",
    response_model=TaskResponse,
    summary="Get a single task",
    description="Returns task if owned by authenticated user",
)
async def get_task(
    db: DbSession,
    user_id: CurrentUser,
    task_id: UUID,
) -> TaskResponse:
    """Get a single task by ID.

    Returns 404 if task doesn't exist OR belongs to another user
    (to prevent enumeration attacks).

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        task_id: Task UUID from path

    Returns:
        TaskResponse if found and owned by user

    Raises:
        TaskNotFoundError: If task not found or not owned
    """
    query = select(Task).where(Task.id == task_id, Task.user_id == user_id)
    result = await db.execute(query)
    task = result.scalar_one_or_none()

    if task is None:
        raise TaskNotFoundError(str(task_id))

    return TaskResponse.model_validate(task)


@router.patch(
    "/{task_id}",
    response_model=TaskResponse,
    summary="Update a task",
    description="Partial update of task owned by authenticated user",
)
async def update_task(
    db: DbSession,
    user_id: CurrentUser,
    task_id: UUID,
    task_in: TaskUpdate,
    request: Request,
) -> TaskResponse:
    """Update an existing task.

    Supports partial updates - only provided fields are updated.
    Returns 404 if task doesn't exist OR belongs to another user.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        task_id: Task UUID from path
        task_in: Update data (all fields optional)
        request: FastAPI request object for audit metadata

    Returns:
        Updated TaskResponse

    Raises:
        TaskNotFoundError: If task not found or not owned
    """
    # Phase 9: Get old task state for audit trail
    query = select(Task).where(Task.id == task_id, Task.user_id == user_id)
    result = await db.execute(query)
    old_task = result.scalar_one_or_none()

    if old_task is None:
        raise TaskNotFoundError(str(task_id))

    # Build updates dict from non-None fields
    updates = task_in.model_dump(exclude_unset=True)

    # Phase 9: Track changes for audit trail
    changes = {}
    for field, new_value in updates.items():
        old_value = getattr(old_task, field, None)
        # Convert enum values to strings for JSON serialization
        if hasattr(old_value, 'value'):
            old_value = old_value.value
        if hasattr(new_value, 'value'):
            new_value = new_value.value
        # Only track if value actually changed
        if old_value != new_value:
            changes[field] = {
                "before": old_value,
                "after": new_value,
            }

    # Use the model's update method with ownership check
    task = await Task.update_task(db, task_id, user_id, updates)

    if task is None:
        raise TaskNotFoundError(str(task_id))

    await db.commit()
    await db.refresh(task)

    # Phase 5: Publish task.updated event
    await publish_task_event(
        event_type="updated",
        task_id=task.id,
        user_id=user_id,
        updates=updates,
    )

    # Phase 5: If status changed to completed, publish task.completed event
    if "status" in updates and updates["status"] == TaskStatus.COMPLETED:
        await publish_task_event(
            event_type="completed",
            task_id=task.id,
            user_id=user_id,
        )

    # Phase 9: Log audit trail with changes
    audit_service = AuditService(db)
    action = AuditAction.COMPLETED if ("status" in updates and updates["status"] == TaskStatus.COMPLETED) else AuditAction.UPDATED
    await audit_service.log_action(
        user_id=user_id,
        action=action,
        resource_type="task",
        resource_id=task.id,
        changes=changes if changes else None,
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    )

    return TaskResponse.model_validate(task)


@router.delete(
    "/{task_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a task",
    description="Permanently deletes task owned by authenticated user",
)
async def delete_task(
    db: DbSession,
    user_id: CurrentUser,
    task_id: UUID,
    request: Request,
) -> None:
    """Delete a task.

    Performs a hard delete. Returns 404 if task doesn't exist
    OR belongs to another user.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        task_id: Task UUID from path
        request: FastAPI request object for audit metadata

    Returns:
        204 No Content on success

    Raises:
        TaskNotFoundError: If task not found or not owned
    """
    deleted = await Task.delete_task(db, task_id, user_id)

    if not deleted:
        raise TaskNotFoundError(str(task_id))

    await db.commit()

    # Phase 5: Publish task.deleted event
    await publish_task_event(
        event_type="deleted",
        task_id=task_id,
        user_id=user_id,
    )

    # Phase 9: Log audit trail
    audit_service = AuditService(db)
    await audit_service.log_action(
        user_id=user_id,
        action=AuditAction.DELETED,
        resource_type="task",
        resource_id=task_id,
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    )
