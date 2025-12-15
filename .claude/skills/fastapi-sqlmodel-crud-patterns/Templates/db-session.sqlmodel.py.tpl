"""
Standard SQLModel engine and session dependency for FastAPI.

PURPOSE:
- Provide a single place to configure the database engine.
- Provide a shared get_session() dependency for all routers.
- Avoid creating engines or sessions inside endpoint functions.

HOW TO USE:
- Place this file as `app/db.py` or similar.
- Import `get_session` in router modules and use with Depends().
"""

from contextlib import contextmanager
from typing import Generator, Optional

from sqlmodel import Session, SQLModel, create_engine
import os


DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
  raise RuntimeError("DATABASE_URL environment variable is not set")


engine = create_engine(
  DATABASE_URL,
  echo=bool(os.getenv("SQL_ECHO", "0") == "1"),
  pool_pre_ping=True,
)


def init_db() -> None:
  """
  Create all tables.

  In real projects, prefer proper migrations (e.g. Alembic), but this
  helper is useful for development and tests.
  """
  SQLModel.metadata.create_all(bind=engine)


@contextmanager
def session_scope() -> Generator[Session, None, None]:
  """
  Context manager for ad-hoc scripts or jobs.
  Not typically used in request handlers; get_session() is preferred there.
  """
  with Session(engine) as session:
    yield session


def get_session() -> Generator[Session, None, None]:
  """
  FastAPI dependency that yields a SQLModel Session.

  Example usage in routers:

      from fastapi import APIRouter, Depends
      from sqlmodel import Session
      from app.db import get_session

      router = APIRouter()

      @router.get("/items")
      def list_items(session: Session = Depends(get_session)):
          ...

  """
  with Session(engine) as session:
    yield session
