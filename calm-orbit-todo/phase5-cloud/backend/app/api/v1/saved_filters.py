"""Saved Filters API endpoints - CRUD operations for user's saved search filters.

All endpoints require JWT authentication and enforce user isolation.
Phase 7: Advanced search and filtering functionality.
"""

import json
from uuid import UUID

from fastapi import APIRouter, Response, status
from sqlmodel import select

from app.api.deps import CurrentUser, DbSession
from app.core.exceptions import NotFoundError
from app.models.saved_filter import SavedFilter
from app.schemas.saved_filter import (
    SavedFilterCreate,
    SavedFilterResponse,
    SavedFilterUpdate,
)

router = APIRouter()


@router.get(
    "",
    response_model=list[SavedFilterResponse],
    summary="List user's saved filters",
    description="Returns all saved filters owned by the authenticated user",
)
async def list_saved_filters(
    db: DbSession,
    user_id: CurrentUser,
) -> list[SavedFilterResponse]:
    """List all saved filters for the authenticated user.

    Returns filters sorted by creation date (newest first).

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT

    Returns:
        List of SavedFilterResponse objects
    """
    query = select(SavedFilter).where(
        SavedFilter.user_id == user_id
    ).order_by(SavedFilter.created_at.desc())

    result = await db.execute(query)
    filters = result.scalars().all()

    return [
        SavedFilterResponse(
            **filter.model_dump(),
            filter_config=json.loads(filter.filter_config)
        )
        for filter in filters
    ]


@router.get(
    "/default",
    response_model=SavedFilterResponse | None,
    summary="Get user's default filter",
    description="Returns the user's default saved filter if one is set",
)
async def get_default_filter(
    db: DbSession,
    user_id: CurrentUser,
) -> SavedFilterResponse | None:
    """Get the user's default saved filter.

    Returns None if no default filter is set.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT

    Returns:
        SavedFilterResponse if default exists, None otherwise
    """
    query = select(SavedFilter).where(
        SavedFilter.user_id == user_id,
        SavedFilter.is_default == True
    )

    result = await db.execute(query)
    filter = result.scalar_one_or_none()

    if filter is None:
        return None

    return SavedFilterResponse(
        **filter.model_dump(),
        filter_config=json.loads(filter.filter_config)
    )


@router.post(
    "",
    response_model=SavedFilterResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new saved filter",
    description="Creates a saved filter owned by the authenticated user",
)
async def create_saved_filter(
    db: DbSession,
    user_id: CurrentUser,
    filter_in: SavedFilterCreate,
    response: Response,
) -> SavedFilterResponse:
    """Create a new saved filter for the authenticated user.

    If is_default is True, any existing default filter will be unset.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        filter_in: Filter creation data
        response: FastAPI response object for setting headers

    Returns:
        Created SavedFilterResponse with 201 status
    """
    # If setting as default, unset any existing default
    if filter_in.is_default:
        query = select(SavedFilter).where(
            SavedFilter.user_id == user_id,
            SavedFilter.is_default == True
        )
        result = await db.execute(query)
        existing_default = result.scalar_one_or_none()
        if existing_default:
            existing_default.is_default = False
            db.add(existing_default)

    # Create new filter
    filter = SavedFilter(
        user_id=user_id,
        name=filter_in.name,
        description=filter_in.description,
        filter_config=json.dumps(filter_in.filter_config.model_dump(exclude_none=True)),
        is_default=filter_in.is_default,
    )

    db.add(filter)
    await db.commit()
    await db.refresh(filter)

    # Set Location header
    response.headers["Location"] = f"/api/v1/saved-filters/{filter.id}"

    return SavedFilterResponse(
        **filter.model_dump(),
        filter_config=json.loads(filter.filter_config)
    )


@router.get(
    "/{filter_id}",
    response_model=SavedFilterResponse,
    summary="Get a single saved filter",
    description="Returns saved filter if owned by authenticated user",
)
async def get_saved_filter(
    db: DbSession,
    user_id: CurrentUser,
    filter_id: UUID,
) -> SavedFilterResponse:
    """Get a single saved filter by ID.

    Returns 404 if filter doesn't exist OR belongs to another user.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        filter_id: Filter UUID from path

    Returns:
        SavedFilterResponse if found and owned by user

    Raises:
        NotFoundError: If filter not found or not owned
    """
    query = select(SavedFilter).where(
        SavedFilter.id == filter_id,
        SavedFilter.user_id == user_id
    )
    result = await db.execute(query)
    filter = result.scalar_one_or_none()

    if filter is None:
        raise NotFoundError(f"Saved filter {filter_id} not found")

    return SavedFilterResponse(
        **filter.model_dump(),
        filter_config=json.loads(filter.filter_config)
    )


@router.patch(
    "/{filter_id}",
    response_model=SavedFilterResponse,
    summary="Update a saved filter",
    description="Partial update of saved filter owned by authenticated user",
)
async def update_saved_filter(
    db: DbSession,
    user_id: CurrentUser,
    filter_id: UUID,
    filter_in: SavedFilterUpdate,
) -> SavedFilterResponse:
    """Update an existing saved filter.

    Supports partial updates - only provided fields are updated.
    If setting as default, any existing default filter will be unset.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        filter_id: Filter UUID from path
        filter_in: Update data (all fields optional)

    Returns:
        Updated SavedFilterResponse

    Raises:
        NotFoundError: If filter not found or not owned
    """
    # Get existing filter
    query = select(SavedFilter).where(
        SavedFilter.id == filter_id,
        SavedFilter.user_id == user_id
    )
    result = await db.execute(query)
    filter = result.scalar_one_or_none()

    if filter is None:
        raise NotFoundError(f"Saved filter {filter_id} not found")

    # If setting as default, unset any existing default
    if filter_in.is_default is True and not filter.is_default:
        query = select(SavedFilter).where(
            SavedFilter.user_id == user_id,
            SavedFilter.is_default == True
        )
        result = await db.execute(query)
        existing_default = result.scalar_one_or_none()
        if existing_default:
            existing_default.is_default = False
            db.add(existing_default)

    # Apply updates
    update_data = filter_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if field == "filter_config" and value is not None:
            setattr(filter, field, json.dumps(value.model_dump(exclude_none=True)))
        else:
            setattr(filter, field, value)

    db.add(filter)
    await db.commit()
    await db.refresh(filter)

    return SavedFilterResponse(
        **filter.model_dump(),
        filter_config=json.loads(filter.filter_config)
    )


@router.delete(
    "/{filter_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a saved filter",
    description="Permanently deletes saved filter owned by authenticated user",
)
async def delete_saved_filter(
    db: DbSession,
    user_id: CurrentUser,
    filter_id: UUID,
) -> None:
    """Delete a saved filter.

    Performs a hard delete. Returns 404 if filter doesn't exist
    OR belongs to another user.

    Args:
        db: Database session
        user_id: Authenticated user ID from JWT
        filter_id: Filter UUID from path

    Returns:
        204 No Content on success

    Raises:
        NotFoundError: If filter not found or not owned
    """
    query = select(SavedFilter).where(
        SavedFilter.id == filter_id,
        SavedFilter.user_id == user_id
    )
    result = await db.execute(query)
    filter = result.scalar_one_or_none()

    if filter is None:
        raise NotFoundError(f"Saved filter {filter_id} not found")

    await db.delete(filter)
    await db.commit()
