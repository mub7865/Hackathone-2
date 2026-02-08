"""Task model for the Todo application.

This module defines the Task entity and TaskStatus enum for managing
user tasks with proper validation and user isolation.
"""

from datetime import datetime
from enum import Enum
from typing import TYPE_CHECKING, List, Optional, Sequence
from uuid import UUID, uuid4

from sqlalchemy import ARRAY, CheckConstraint, Column, DateTime, ForeignKey, Index, String, Text, func
from sqlmodel import Field, SQLModel, select

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession


class TaskStatus(str, Enum):
    """Valid task statuses.

    Attributes:
        PENDING: Task is not yet completed (default state).
        COMPLETED: Task has been marked as done.
    """

    PENDING = "pending"
    COMPLETED = "completed"


class TaskPriority(str, Enum):
    """Valid task priorities.

    Attributes:
        HIGH: High priority task.
        MEDIUM: Medium priority task (default state).
        LOW: Low priority task.
    """

    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class Task(SQLModel, table=True):
    """Represents a single to-do item owned by a user.

    Invariants:
        - Every task belongs to exactly one user (user_id NOT NULL)
        - Title is required and non-empty (max 255 characters)
        - Status is constrained to 'pending' or 'completed'
        - Priority is constrained to 'high', 'medium', or 'low'
        - Timestamps are managed automatically by the database

    Attributes:
        id: Unique task identifier (UUID, auto-generated).
        user_id: Owner's Better Auth user ID (UUID string, max 36 chars).
        title: Task name (required, max 255 characters).
        description: Optional task details (text).
        status: Task state - 'pending' or 'completed'.
        priority: Task priority - 'high', 'medium', or 'low' (default: 'medium').
        tags: Array of tag strings for categorization (default: empty array).
        due_date: Optional due date with timezone.
        remind_at: Optional reminder timestamp with timezone.
        recurring_pattern_id: Optional foreign key to recurring_patterns table.
        created_at: Creation timestamp (immutable, auto-set).
        updated_at: Last modification timestamp (auto-updated).
    """

    __tablename__ = "task"
    __table_args__ = (
        CheckConstraint(
            "status IN ('pending', 'completed')", name="chk_task_status"
        ),
        CheckConstraint(
            "priority IN ('high', 'medium', 'low')", name="chk_task_priority"
        ),
        CheckConstraint(
            "length(trim(title)) > 0", name="chk_task_title_not_empty"
        ),
        Index("ix_task_user_status", "user_id", "status"),
        Index("ix_task_priority", "priority"),
        Index("ix_task_tags", "tags", postgresql_using="gin"),
        Index("ix_task_due_date", "due_date", postgresql_where="due_date IS NOT NULL"),
        Index("ix_task_remind_at", "remind_at", postgresql_where="remind_at IS NOT NULL"),
        Index("ix_task_recurring_pattern_id", "recurring_pattern_id", postgresql_where="recurring_pattern_id IS NOT NULL"),
        Index("ix_task_user_status_priority", "user_id", "status", "priority"),
    )

    # Primary key
    id: UUID = Field(
        default_factory=uuid4,
        primary_key=True,
        nullable=False,
        description="Unique task identifier",
    )

    # Owner reference (Better Auth user ID)
    user_id: str = Field(
        ...,
        max_length=36,
        nullable=False,
        index=True,
        sa_column_kwargs={"name": "user_id"},
        description="Owner's Better Auth user ID (UUID string)",
    )

    # Task content
    title: str = Field(
        ...,
        max_length=255,
        nullable=False,
        description="Task name (required, max 255 characters)",
    )

    description: Optional[str] = Field(
        default=None,
        sa_column=Column(Text, nullable=True),
        description="Optional task details",
    )

    # Task state
    status: TaskStatus = Field(
        default=TaskStatus.PENDING,
        sa_column=Column(
            String(20),
            nullable=False,
            default="pending",
        ),
        description="Task status: 'pending' or 'completed'",
    )

    # Phase 5: Priority and categorization
    priority: TaskPriority = Field(
        default=TaskPriority.MEDIUM,
        sa_column=Column(
            String(10),
            nullable=False,
            default="medium",
        ),
        description="Task priority: 'high', 'medium', or 'low'",
    )

    tags: List[str] = Field(
        default_factory=list,
        sa_column=Column(
            ARRAY(String),
            nullable=False,
            server_default="{}",
        ),
        description="Array of tag strings for categorization",
    )

    # Phase 5: Scheduling
    due_date: Optional[datetime] = Field(
        default=None,
        sa_column=Column(
            DateTime(timezone=True),
            nullable=True,
        ),
        description="Optional due date with timezone",
    )

    remind_at: Optional[datetime] = Field(
        default=None,
        sa_column=Column(
            DateTime(timezone=True),
            nullable=True,
        ),
        description="Optional reminder timestamp with timezone",
    )

    # Phase 5: Recurring tasks
    recurring_pattern_id: Optional[UUID] = Field(
        default=None,
        sa_column=Column(
            ForeignKey("recurring_patterns.id", ondelete="SET NULL"),
            nullable=True,
        ),
        description="Optional foreign key to recurring_patterns table",
    )

    # Timestamps
    created_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            server_default=func.now(),
            nullable=False,
        ),
        description="Creation timestamp (immutable)",
    )

    updated_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            server_default=func.now(),
            onupdate=func.now(),
            nullable=False,
        ),
        description="Last modification timestamp",
    )

    # -------------------------------------------------------------------------
    # Query Methods (User Story 2: View Own Tasks)
    # -------------------------------------------------------------------------

    @classmethod
    async def get_by_user(
        cls, session: "AsyncSession", user_id: str
    ) -> Sequence["Task"]:
        """Get all tasks for a specific user.

        Args:
            session: Async database session.
            user_id: The user's Better Auth ID.

        Returns:
            List of tasks owned by the user, or empty list if none exist.

        Example:
            tasks = await Task.get_by_user(session, current_user.id)
        """
        statement = select(cls).where(cls.user_id == user_id)
        result = await session.execute(statement)
        return result.scalars().all()

    @classmethod
    async def get_by_user_and_status(
        cls, session: "AsyncSession", user_id: str, status: TaskStatus
    ) -> Sequence["Task"]:
        """Get tasks for a specific user filtered by status.

        Args:
            session: Async database session.
            user_id: The user's Better Auth ID.
            status: The task status to filter by (PENDING or COMPLETED).

        Returns:
            List of tasks matching the user and status, or empty list if none.

        Example:
            pending = await Task.get_by_user_and_status(
                session, current_user.id, TaskStatus.PENDING
            )
        """
        statement = select(cls).where(
            cls.user_id == user_id,
            cls.status == status,
        )
        result = await session.execute(statement)
        return result.scalars().all()

    # -------------------------------------------------------------------------
    # Mutation Methods (User Story 3: Update a Task)
    # -------------------------------------------------------------------------

    @classmethod
    async def update_task(
        cls,
        session: "AsyncSession",
        task_id: UUID,
        user_id: str,
        updates: dict,
    ) -> Optional["Task"]:
        """Update a task owned by a specific user.

        Enforces ownership by querying with both task_id AND user_id.
        Only allows updating: title, description, status, priority, tags, due_date, remind_at.

        Args:
            session: Async database session.
            task_id: The task's UUID.
            user_id: The user's Better Auth ID (ownership check).
            updates: Dictionary of fields to update. Valid keys:
                - title: str
                - description: str | None
                - status: TaskStatus | str
                - priority: TaskPriority | str (Phase 5)
                - tags: List[str] (Phase 5)
                - due_date: datetime | None (Phase 5)
                - remind_at: datetime | None (Phase 5)

        Returns:
            Updated Task if found and owned by user, None otherwise.

        Example:
            updated = await Task.update_task(
                session,
                task_id=task.id,
                user_id=current_user.id,
                updates={"status": TaskStatus.COMPLETED, "priority": TaskPriority.HIGH}
            )
            if updated is None:
                raise NotFoundError("Task not found or not owned")
        """
        # Query task by id AND user_id (ownership check)
        statement = select(cls).where(cls.id == task_id, cls.user_id == user_id)
        result = await session.execute(statement)
        task = result.scalar_one_or_none()

        if task is None:
            return None

        # Apply allowed updates (Phase 5: added priority, tags, due_date, remind_at)
        allowed_fields = {"title", "description", "status", "priority", "tags", "due_date", "remind_at"}
        for field, value in updates.items():
            if field in allowed_fields:
                setattr(task, field, value)

        # Flush to trigger onupdate for updated_at
        await session.flush()
        await session.refresh(task)

        return task

    # -------------------------------------------------------------------------
    # Mutation Methods (User Story 4: Delete a Task)
    # -------------------------------------------------------------------------

    @classmethod
    async def delete_task(
        cls,
        session: "AsyncSession",
        task_id: UUID,
        user_id: str,
    ) -> bool:
        """Delete a task owned by a specific user.

        Enforces ownership by querying with both task_id AND user_id.
        Performs a hard delete (not soft delete).

        Args:
            session: Async database session.
            task_id: The task's UUID.
            user_id: The user's Better Auth ID (ownership check).

        Returns:
            True if task was found, owned by user, and deleted.
            False if task not found or not owned by user.

        Example:
            deleted = await Task.delete_task(
                session,
                task_id=task.id,
                user_id=current_user.id,
            )
            if not deleted:
                raise NotFoundError("Task not found or not owned")
        """
        # Query task by id AND user_id (ownership check)
        statement = select(cls).where(cls.id == task_id, cls.user_id == user_id)
        result = await session.execute(statement)
        task = result.scalar_one_or_none()

        if task is None:
            return False

        # Delete the task
        await session.delete(task)
        await session.flush()

        return True
