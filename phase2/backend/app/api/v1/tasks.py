"""Tasks API endpoints - CRUD operations for user tasks.

All endpoints require JWT authentication and enforce user isolation.
Implements FR-001 to FR-024 from the spec (Chunk 4 additions for search/sort).
"""

from uuid import UUID

from fastapi import APIRouter, Query, Response, status
from sqlalchemy import func, or_
from sqlmodel import select

from app.api.deps import CurrentUser, DbSession
from app.core.exceptions import TaskNotFoundError
from app.models.task import Task, TaskStatus
from app.schemas.task import TaskCreate, TaskResponse, TaskUpdate, SortField, SortOrder

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
    search: str | None = Query(
        None,
        max_length=100,
        description="Search in title and description (case-insensitive, max 100 chars)",
    ),
    sort: SortField = Query(
        SortField.CREATED_AT,
        description="Field to sort by (created_at or title)",
    ),
    order: SortOrder = Query(
        SortOrder.DESC,
        description="Sort direction (asc or desc)",
    ),
) -> list[TaskResponse]:
    """List tasks for the authenticated user.

    Supports pagination via offset/limit, status filtering, free-text search,
    and configurable sorting.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        offset: Number of items to skip (default 0)
        limit: Max items to return (default 20, max 100)
        status: Optional status filter (pending or completed)
        search: Optional search term for title/description (case-insensitive)
        sort: Sort field (created_at or title, default created_at)
        order: Sort direction (asc or desc, default desc)

    Returns:
        List of TaskResponse objects
    """
    # Build query with user isolation (FR-024)
    query = select(Task).where(Task.user_id == user_id)

    # Apply status filter if provided (FR-004: AND logic)
    if status is not None:
        query = query.where(Task.status == status)

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

    # Apply sorting (FR-008, FR-009, FR-010)
    if sort == SortField.TITLE:
        # Case-insensitive title sort (FR-009)
        sort_column = func.lower(Task.title)
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
    response: Response,
) -> TaskResponse:
    """Create a new task for the authenticated user.

    The user_id is automatically set from the JWT token.
    Status defaults to 'pending'.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        task_in: Task creation data (title, optional description)
        response: FastAPI response object for setting headers

    Returns:
        Created TaskResponse with 201 status
    """
    # Create task with user_id from JWT
    task = Task(
        user_id=user_id,
        title=task_in.title,
        description=task_in.description,
    )

    db.add(task)
    await db.commit()
    await db.refresh(task)

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
) -> TaskResponse:
    """Update an existing task.

    Supports partial updates - only provided fields are updated.
    Returns 404 if task doesn't exist OR belongs to another user.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        task_id: Task UUID from path
        task_in: Update data (all fields optional)

    Returns:
        Updated TaskResponse

    Raises:
        TaskNotFoundError: If task not found or not owned
    """
    # Build updates dict from non-None fields
    updates = task_in.model_dump(exclude_unset=True)

    # Use the model's update method with ownership check
    task = await Task.update_task(db, task_id, user_id, updates)

    if task is None:
        raise TaskNotFoundError(str(task_id))

    await db.commit()
    await db.refresh(task)

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
) -> None:
    """Delete a task.

    Performs a hard delete. Returns 404 if task doesn't exist
    OR belongs to another user.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        task_id: Task UUID from path

    Returns:
        204 No Content on success

    Raises:
        TaskNotFoundError: If task not found or not owned
    """
    deleted = await Task.delete_task(db, task_id, user_id)

    if not deleted:
        raise TaskNotFoundError(str(task_id))

    await db.commit()
