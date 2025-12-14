"""Shared FastAPI dependencies for API routes.

Provides dependency injection for database sessions and authentication.
"""

from collections.abc import AsyncGenerator
from typing import Annotated

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import get_current_user as _get_current_user
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


async def get_current_user_with_state(
    request: Request,
    user_id: Annotated[str, Depends(_get_current_user)],
) -> str:
    """Get current user and store in request state for logging.

    This wrapper stores the user_id in request.state so the logging
    middleware can include it in structured logs.

    Args:
        request: FastAPI request object
        user_id: User ID from JWT (injected by get_current_user)

    Returns:
        User ID string
    """
    request.state.user_id = user_id
    return user_id


# Type aliases for cleaner route signatures
DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[str, Depends(get_current_user_with_state)]
