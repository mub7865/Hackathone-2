"""AuditLog model for tracking all task operations.

This module defines the AuditLog entity for maintaining a complete
audit trail of all task operations for compliance and history.
"""

from datetime import datetime
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4

from sqlalchemy import Column, DateTime, Index, String, Text, func
from sqlmodel import Field, SQLModel


class AuditAction(str, Enum):
    """Valid audit actions.

    Attributes:
        CREATED: Task was created.
        UPDATED: Task was updated.
        DELETED: Task was deleted.
        COMPLETED: Task was marked as completed.
        VIEWED: Task was viewed (optional, for sensitive data).
    """

    CREATED = "created"
    UPDATED = "updated"
    DELETED = "deleted"
    COMPLETED = "completed"
    VIEWED = "viewed"


class AuditLog(SQLModel, table=True):
    """Represents an audit log entry for task operations.

    Invariants:
        - Every log entry belongs to exactly one user (user_id NOT NULL)
        - Action is constrained to valid audit actions
        - Task ID is required for task-related operations
        - Timestamps are managed automatically by the database

    Attributes:
        id: Unique log entry identifier (UUID, auto-generated).
        user_id: User who performed the action (UUID string, max 36 chars).
        action: The action performed (created, updated, deleted, completed, viewed).
        resource_type: Type of resource (e.g., "task", "filter").
        resource_id: ID of the resource affected (UUID).
        changes: JSON string containing before/after values for updates.
        ip_address: IP address of the client (optional).
        user_agent: User agent string (optional).
        created_at: Timestamp when action occurred (immutable, auto-set).
    """

    __tablename__ = "audit_log"
    __table_args__ = (
        Index("ix_audit_log_user_id", "user_id"),
        Index("ix_audit_log_resource", "resource_type", "resource_id"),
        Index("ix_audit_log_action", "action"),
        Index("ix_audit_log_created_at", "created_at"),
        Index("ix_audit_log_user_created", "user_id", "created_at"),
    )

    # Primary key
    id: UUID = Field(
        default_factory=uuid4,
        primary_key=True,
        nullable=False,
        description="Unique log entry identifier",
    )

    # User reference (Better Auth user ID)
    user_id: str = Field(
        ...,
        max_length=36,
        nullable=False,
        index=True,
        description="User who performed the action (UUID string)",
    )

    # Action details
    action: AuditAction = Field(
        ...,
        sa_column=Column(String(20), nullable=False),
        description="The action performed",
    )

    resource_type: str = Field(
        ...,
        max_length=50,
        nullable=False,
        description="Type of resource (e.g., 'task', 'filter')",
    )

    resource_id: UUID = Field(
        ...,
        nullable=False,
        description="ID of the resource affected",
    )

    # Change tracking
    changes: Optional[str] = Field(
        default=None,
        sa_column=Column(Text, nullable=True),
        description="JSON string containing before/after values",
    )

    # Request metadata
    ip_address: Optional[str] = Field(
        default=None,
        max_length=45,  # IPv6 max length
        description="IP address of the client",
    )

    user_agent: Optional[str] = Field(
        default=None,
        sa_column=Column(Text, nullable=True),
        description="User agent string",
    )

    # Timestamp
    created_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            server_default=func.now(),
            nullable=False,
        ),
        description="Timestamp when action occurred (immutable)",
    )
