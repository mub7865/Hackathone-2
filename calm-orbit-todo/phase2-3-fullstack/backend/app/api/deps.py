"""Shared FastAPI dependencies for API routes.

Provides dependency injection for database sessions and authentication.
"""

from collections.abc import AsyncGenerator
from typing import Annotated

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings, get_settings
from app.core.auth import get_current_user as _get_current_user
from app.core.auth import get_current_user_dual as _get_current_user_dual
from app.database import get_session


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency to get async database session.

    Yields an AsyncSession that automatically closes after the request.

    Usage:
        @router.get("/tasks")
        async def list_tasks(db: AsyncSession = Depends(get_db)):
            ...
    """
    async for session in get_session():
        yield session


async def get_current_user_with_migration(
    settings: Annotated[Settings, Depends(get_settings)],
    user_id_legacy: Annotated[str | None, Depends(_get_current_user)] = None,
    user_id_dual: Annotated[str | None, Depends(_get_current_user_dual)] = None,
) -> str:
    """Get current user with migration support.

    Uses dual token validation when auth_migration_enabled=true,
    otherwise uses legacy validation only.

    Args:
        settings: Application settings
        user_id_legacy: User ID from legacy validation (optional)
        user_id_dual: User ID from dual validation (optional)

    Returns:
        User ID string
    """
    if settings.auth_migration_enabled:
        return user_id_dual
    return user_id_legacy


async def get_current_user_with_state(
    request: Request,
    settings: Annotated[Settings, Depends(get_settings)],
) -> str:
    """Get current user and store in request state for logging.

    This wrapper stores the user_id in request.state so the logging
    middleware can include it in structured logs.

    Args:
        request: FastAPI request object
        settings: Application settings

    Returns:
        User ID string
    """
    # Use dual validation if migration is enabled
    if settings.auth_migration_enabled:
        user_id = await _get_current_user_dual(
            authorization=request.headers.get("authorization"),
            settings=settings,
        )
    else:
        user_id = await _get_current_user(
            authorization=request.headers.get("authorization"),
            settings=settings,
        )

    request.state.user_id = user_id
    return user_id


# Type aliases for cleaner route signatures
DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[str, Depends(get_current_user_with_state)]
