"""Tags API endpoints - Tag management for user tasks.

All endpoints require JWT authentication and enforce user isolation.
Phase 6: Tag management functionality.
"""

from fastapi import APIRouter, Query
from sqlalchemy import func, distinct
from sqlmodel import select

from app.api.deps import CurrentUser, DbSession
from app.models.task import Task

router = APIRouter()


@router.get(
    "",
    response_model=list[str],
    summary="List all tags",
    description="Returns all unique tags used by the authenticated user across all tasks",
)
async def list_tags(
    db: DbSession,
    user_id: CurrentUser,
    min_count: int = Query(1, ge=1, description="Minimum number of tasks that must have the tag"),
) -> list[str]:
    """List all unique tags for the authenticated user.

    Returns a list of all unique tags used across the user's tasks,
    optionally filtered by minimum usage count.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        min_count: Minimum number of tasks that must have the tag (default 1)

    Returns:
        List of unique tag strings, sorted alphabetically
    """
    # Query to get all tags from user's tasks
    # Use unnest to expand the array into rows, then count occurrences
    query = select(
        func.unnest(Task.tags).label("tag"),
        func.count().label("count")
    ).where(
        Task.user_id == user_id
    ).group_by(
        "tag"
    ).having(
        func.count() >= min_count
    ).order_by(
        "tag"
    )

    result = await db.execute(query)
    tags = [row[0] for row in result.all()]

    return tags


@router.get(
    "/popular",
    response_model=list[dict],
    summary="List popular tags",
    description="Returns tags with their usage counts, sorted by popularity",
)
async def list_popular_tags(
    db: DbSession,
    user_id: CurrentUser,
    limit: int = Query(10, ge=1, le=50, description="Max number of tags to return"),
) -> list[dict]:
    """List popular tags with usage counts.

    Returns tags sorted by usage count (most popular first),
    with the count of tasks using each tag.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        limit: Maximum number of tags to return (default 10, max 50)

    Returns:
        List of dicts with 'tag' and 'count' keys, sorted by count descending
    """
    # Query to get tags with counts, sorted by popularity
    query = select(
        func.unnest(Task.tags).label("tag"),
        func.count().label("count")
    ).where(
        Task.user_id == user_id
    ).group_by(
        "tag"
    ).order_by(
        func.count().desc()
    ).limit(limit)

    result = await db.execute(query)
    tags = [{"tag": row[0], "count": row[1]} for row in result.all()]

    return tags


@router.get(
    "/search",
    response_model=list[str],
    summary="Search tags",
    description="Search for tags matching a pattern (case-insensitive)",
)
async def search_tags(
    db: DbSession,
    user_id: CurrentUser,
    q: str = Query(..., min_length=1, max_length=50, description="Search query"),
) -> list[str]:
    """Search for tags matching a pattern.

    Returns tags that contain the search query (case-insensitive).

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        q: Search query string

    Returns:
        List of matching tag strings, sorted alphabetically
    """
    # Query to search tags
    search_pattern = f"%{q.lower()}%"

    query = select(
        distinct(func.unnest(Task.tags)).label("tag")
    ).where(
        Task.user_id == user_id,
        func.lower(func.unnest(Task.tags)).like(search_pattern)
    ).order_by(
        "tag"
    )

    result = await db.execute(query)
    tags = [row[0] for row in result.all()]

    return tags
