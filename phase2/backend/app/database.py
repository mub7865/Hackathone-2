"""Database connection and session management for Neon Postgres."""

from collections.abc import AsyncGenerator
from typing import Any

from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

from app.config import get_settings

# Module-level engine reference (lazy initialization)
_engine: AsyncEngine | None = None
_async_session: Any = None


def get_engine() -> AsyncEngine:
    """Get or create the async database engine.

    Uses lazy initialization to avoid event loop binding issues in tests.

    Returns:
        AsyncEngine instance
    """
    global _engine, _async_session

    if _engine is None:
        settings = get_settings()
        _engine = create_async_engine(
            settings.database_url,
            echo=settings.is_development,  # SQL logging in dev only
            pool_size=5,
            max_overflow=10,
        )
        _async_session = sessionmaker(
            _engine,
            class_=AsyncSession,
            expire_on_commit=False,
        )

    return _engine


def get_session_factory() -> Any:
    """Get the session factory, initializing engine if needed."""
    global _async_session
    if _async_session is None:
        get_engine()  # This will also create _async_session
    return _async_session


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency for FastAPI routes.

    Yields an async database session that automatically closes after use.

    Usage:
        @app.get("/tasks")
        async def get_tasks(session: AsyncSession = Depends(get_session)):
            ...
    """
    session_factory = get_session_factory()
    async with session_factory() as session:
        yield session


async def init_db() -> None:
    """
    Create all tables (for development only).

    In production, use Alembic migrations instead.
    """
    engine = get_engine()
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)


def reset_engine() -> None:
    """Reset the engine for testing purposes.

    This allows tests to create a fresh engine bound to their event loop.
    """
    global _engine, _async_session
    _engine = None
    _async_session = None
