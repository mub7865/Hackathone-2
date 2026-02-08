"""SavedFilter model for storing user's saved search filters.

This module defines the SavedFilter entity for managing user-defined
search filters that can be reused across sessions.
"""

from datetime import datetime
from typing import Optional
from uuid import UUID, uuid4

from sqlalchemy import Column, DateTime, Index, String, Text, func
from sqlmodel import Field, SQLModel


class SavedFilter(SQLModel, table=True):
    """Represents a saved search filter configuration.

    Invariants:
        - Every filter belongs to exactly one user (user_id NOT NULL)
        - Name is required and non-empty (max 100 characters)
        - Filter configuration is stored as JSON text
        - Timestamps are managed automatically by the database

    Attributes:
        id: Unique filter identifier (UUID, auto-generated).
        user_id: Owner's Better Auth user ID (UUID string, max 36 chars).
        name: Filter name (required, max 100 characters).
        description: Optional filter description.
        filter_config: JSON string containing filter parameters.
        is_default: Whether this is the user's default filter.
        created_at: Creation timestamp (immutable, auto-set).
        updated_at: Last modification timestamp (auto-updated).
    """

    __tablename__ = "saved_filter"
    __table_args__ = (
        Index("ix_saved_filter_user_id", "user_id"),
        Index("ix_saved_filter_user_default", "user_id", "is_default"),
    )

    # Primary key
    id: UUID = Field(
        default_factory=uuid4,
        primary_key=True,
        nullable=False,
        description="Unique filter identifier",
    )

    # Owner reference (Better Auth user ID)
    user_id: str = Field(
        ...,
        max_length=36,
        nullable=False,
        index=True,
        description="Owner's Better Auth user ID (UUID string)",
    )

    # Filter metadata
    name: str = Field(
        ...,
        max_length=100,
        nullable=False,
        description="Filter name (required, max 100 characters)",
    )

    description: Optional[str] = Field(
        default=None,
        sa_column=Column(Text, nullable=True),
        description="Optional filter description",
    )

    # Filter configuration (stored as JSON)
    filter_config: str = Field(
        ...,
        sa_column=Column(Text, nullable=False),
        description="JSON string containing filter parameters",
    )

    # Default filter flag
    is_default: bool = Field(
        default=False,
        nullable=False,
        description="Whether this is the user's default filter",
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
