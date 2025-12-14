# Quickstart: Core Data & Domain Model

**Feature**: 002-core-data-model
**Date**: 2025-12-12
**Prerequisites**: Python 3.13+, UV, Neon Postgres account

---

## Overview

This guide covers setting up the backend data model for the Todo application. After completing these steps, you'll have:

- A working FastAPI backend project structure
- SQLModel Task entity with Pydantic validation
- Alembic migrations configured for Neon Postgres
- Test fixtures for model validation

---

## 1. Project Setup

### 1.1 Create Backend Directory Structure

```bash
mkdir -p backend/app/models
mkdir -p backend/alembic/versions
mkdir -p backend/tests/unit
```

### 1.2 Initialize Python Project

Create `backend/pyproject.toml`:

```toml
[project]
name = "todo-backend"
version = "0.1.0"
description = "Todo App Backend - Phase II"
requires-python = ">=3.13"
dependencies = [
    "fastapi>=0.115.0",
    "sqlmodel>=0.0.22",
    "asyncpg>=0.30.0",
    "alembic>=1.14.0",
    "uvicorn>=0.32.0",
    "python-dotenv>=1.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.24.0",
    "httpx>=0.28.0",
]
```

### 1.3 Install Dependencies

```bash
cd backend
uv sync
uv sync --dev  # Include dev dependencies
```

---

## 2. Database Configuration

### 2.1 Environment Variables

Create `backend/.env`:

```env
# Neon Postgres Connection
DATABASE_URL=postgresql+asyncpg://user:password@host.neon.tech/dbname?sslmode=require

# Environment
ENVIRONMENT=development
```

### 2.2 Database Module

Create `backend/app/database.py`:

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel
import os

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_async_engine(
    DATABASE_URL,
    echo=True,  # SQL logging (disable in production)
    pool_size=5,
    max_overflow=10,
)

async_session = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

async def get_session() -> AsyncSession:
    """Dependency for FastAPI routes."""
    async with async_session() as session:
        yield session

async def init_db():
    """Create tables (for development only; use migrations in production)."""
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
```

---

## 3. Task Model

### 3.1 Status Enum

Create `backend/app/models/__init__.py`:

```python
from .task import Task, TaskStatus

__all__ = ["Task", "TaskStatus"]
```

### 3.2 Task Entity

Create `backend/app/models/task.py`:

```python
from datetime import datetime
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4

from sqlalchemy import Column, DateTime, String, Text, func, CheckConstraint
from sqlmodel import Field, SQLModel


class TaskStatus(str, Enum):
    """Valid task statuses."""
    PENDING = "pending"
    COMPLETED = "completed"


class Task(SQLModel, table=True):
    """Task entity with user ownership."""

    __tablename__ = "task"
    __table_args__ = (
        CheckConstraint("status IN ('pending', 'completed')", name="chk_task_status"),
        CheckConstraint("length(trim(title)) > 0", name="chk_task_title_not_empty"),
    )

    id: UUID = Field(
        default_factory=uuid4,
        primary_key=True,
        nullable=False,
    )

    user_id: str = Field(
        ...,
        max_length=36,
        nullable=False,
        index=True,
    )

    title: str = Field(
        ...,
        max_length=255,
        nullable=False,
    )

    description: Optional[str] = Field(
        default=None,
        sa_column=Column(Text, nullable=True),
    )

    status: TaskStatus = Field(
        default=TaskStatus.PENDING,
        nullable=False,
    )

    created_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            server_default=func.now(),
            nullable=False,
        )
    )

    updated_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            server_default=func.now(),
            onupdate=func.now(),
            nullable=False,
        )
    )
```

---

## 4. Alembic Setup

### 4.1 Initialize Alembic

```bash
cd backend
alembic init alembic
```

### 4.2 Configure Alembic

Edit `backend/alembic/env.py`:

```python
import asyncio
from logging.config import fileConfig
import os

from sqlalchemy import pool
from sqlalchemy.ext.asyncio import create_async_engine
from alembic import context

from app.models import Task  # Import models
from sqlmodel import SQLModel

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = SQLModel.metadata

def get_url():
    return os.getenv("DATABASE_URL")

def run_migrations_offline() -> None:
    url = get_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()

def do_run_migrations(connection):
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()

async def run_async_migrations():
    connectable = create_async_engine(get_url(), poolclass=pool.NullPool)
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()

def run_migrations_online() -> None:
    asyncio.run(run_async_migrations())

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

### 4.3 Create Initial Migration

```bash
cd backend
alembic revision --autogenerate -m "create_task_table"
```

### 4.4 Run Migration

```bash
alembic upgrade head
```

---

## 5. Testing

### 5.1 Test Configuration

Create `backend/tests/conftest.py`:

```python
import pytest
from uuid import uuid4

@pytest.fixture
def mock_user_id() -> str:
    """Generate a mock Better Auth user ID."""
    return str(uuid4())

@pytest.fixture
def valid_task_data(mock_user_id: str) -> dict:
    """Valid task creation data."""
    return {
        "user_id": mock_user_id,
        "title": "Test Task",
        "description": "Test description",
    }
```

### 5.2 Model Tests

Create `backend/tests/unit/test_task_model.py`:

```python
import pytest
from uuid import uuid4
from app.models import Task, TaskStatus

def test_task_creation_with_valid_data(valid_task_data):
    """Task can be created with valid data."""
    task = Task(**valid_task_data)
    assert task.title == "Test Task"
    assert task.status == TaskStatus.PENDING
    assert task.user_id == valid_task_data["user_id"]

def test_task_default_status():
    """New tasks default to pending status."""
    task = Task(user_id=str(uuid4()), title="Test")
    assert task.status == TaskStatus.PENDING

def test_task_status_enum_values():
    """TaskStatus enum has expected values."""
    assert TaskStatus.PENDING.value == "pending"
    assert TaskStatus.COMPLETED.value == "completed"
```

### 5.3 Run Tests

```bash
cd backend
uv run pytest tests/ -v
```

---

## 6. Verification Checklist

After completing setup, verify:

- [ ] `uv sync` completes without errors
- [ ] `.env` file contains valid Neon connection string
- [ ] `alembic upgrade head` creates the `task` table
- [ ] `pytest tests/` passes all tests
- [ ] Task table has correct columns in Neon console

---

## Common Issues

### SSL Connection Error

Ensure `?sslmode=require` is in your DATABASE_URL.

### Alembic Import Error

Make sure `PYTHONPATH` includes the backend directory:
```bash
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

### Migration Not Detecting Changes

Ensure all models are imported in `alembic/env.py` before `target_metadata` is set.

---

## Next Steps

1. Run `/sp.tasks` to generate implementation tasks
2. Implement tasks in dependency order
3. Add API endpoints (separate spec)
4. Add frontend integration (separate spec)
