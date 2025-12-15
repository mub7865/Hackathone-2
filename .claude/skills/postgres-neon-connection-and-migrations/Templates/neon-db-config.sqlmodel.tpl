"""
Standard Neon Postgres configuration for SQLModel-based apps.

PURPOSE:
- Centralize Neon connection configuration (engine + URL).
- Respect serverless behaviour (pool_pre_ping, env-based URLs).
- Provide a single metadata reference for migrations (Alembic).

HOW TO USE:
- Place this file as `app/db.py` or equivalent.
- Import `engine` and `SQLModel.metadata` in your Alembic env.py.
- Use `get_engine()` or `engine` in your session helpers.
"""

import os
from typing import Optional

from sqlmodel import SQLModel, create_engine
from sqlalchemy.engine import Engine


NEON_DATABASE_URL_ENV = "DATABASE_URL"  # Neon connection string env var


def _get_database_url() -> str:
    url = os.getenv(NEON_DATABASE_URL_ENV)
    if not url:
        raise RuntimeError(f"{NEON_DATABASE_URL_ENV} environment variable is not set")
    return url


_engine: Optional[Engine] = None


def get_engine() -> Engine:
    """
    Returns a singleton SQLModel engine configured for Neon Postgres.

    RULES:
    - Use a single engine per process for long-running app servers
      (e.g. FastAPI, background workers).
    - Do NOT create a new engine on every request.
    - For serverless/edge runtimes, follow the platform + Neon guidance
      and adapt this pattern if needed.
    """
    global _engine
    if _engine is None:
        database_url = _get_database_url()

        # Neon-specific recommendations:
        # - Use pool_pre_ping to handle idle connection drops.
        # - Avoid extremely large pools; Neon has a built-in pooler.
        _engine = create_engine(
            database_url,
            pool_pre_ping=True,
            echo=bool(os.getenv("SQL_ECHO", "0") == "1"),
        )
    return _engine


def init_db() -> None:
    """
    Convenience helper for development/tests to create all tables.

    NOTE:
    - In production, prefer running migrations (e.g. Alembic) instead of
      calling create_all() on startup.
    """
    engine = get_engine()
    SQLModel.metadata.create_all(bind=engine)


# Re-export metadata for migrations (Alembic target_metadata)
metadata = SQLModel.metadata
