"""Conversation model for AI Chatbot Phase III.

This module defines the Conversation entity for storing chat sessions
between users and the AI assistant.
"""

from datetime import datetime
from typing import TYPE_CHECKING, Optional, Sequence

from sqlalchemy import Column, DateTime, String, func
from sqlmodel import Field, SQLModel, select

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession


class Conversation(SQLModel, table=True):
    """Represents a chat session between a user and the AI assistant.

    Invariants:
        - Every conversation belongs to exactly one user (user_id NOT NULL)
        - Title is auto-generated from first message (max 100 chars)
        - Timestamps are managed automatically by the database

    Attributes:
        id: Unique conversation identifier (auto-increment).
        user_id: Owner's Better Auth user ID (UUID string, max 36 chars).
        title: Auto-generated title from first message (truncated to 50 chars).
        created_at: Creation timestamp (immutable, auto-set).
        updated_at: Last activity timestamp (auto-updated).
    """

    __tablename__ = "conversations"

    # Primary key
    id: Optional[int] = Field(default=None, primary_key=True)

    # Owner reference (Better Auth user ID)
    user_id: str = Field(
        ...,
        max_length=36,
        nullable=False,
        index=True,
        description="Owner's Better Auth user ID (UUID string)",
    )

    # Conversation title (auto-generated from first message)
    title: Optional[str] = Field(
        default=None,
        max_length=100,
        sa_column=Column(String(100), nullable=True),
        description="Auto-generated title from first message (50 chars truncated)",
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
        description="Last activity timestamp",
    )

    # -------------------------------------------------------------------------
    # Query Methods
    # -------------------------------------------------------------------------

    @classmethod
    async def get_by_user(
        cls, session: "AsyncSession", user_id: str
    ) -> Sequence["Conversation"]:
        """Get all conversations for a specific user, ordered by most recent.

        Args:
            session: Async database session.
            user_id: The user's Better Auth ID.

        Returns:
            List of conversations owned by the user, ordered by updated_at DESC.
        """
        statement = (
            select(cls)
            .where(cls.user_id == user_id)
            .order_by(cls.updated_at.desc())
        )
        result = await session.execute(statement)
        return result.scalars().all()

    @classmethod
    async def get_by_id_and_user(
        cls, session: "AsyncSession", conversation_id: int, user_id: str
    ) -> Optional["Conversation"]:
        """Get a conversation by ID if owned by user.

        Args:
            session: Async database session.
            conversation_id: The conversation ID.
            user_id: The user's Better Auth ID (ownership check).

        Returns:
            Conversation if found and owned by user, None otherwise.
        """
        statement = select(cls).where(
            cls.id == conversation_id, cls.user_id == user_id
        )
        result = await session.execute(statement)
        return result.scalar_one_or_none()

    @classmethod
    async def create(
        cls, session: "AsyncSession", user_id: str, title: Optional[str] = None
    ) -> "Conversation":
        """Create a new conversation for a user.

        Args:
            session: Async database session.
            user_id: The user's Better Auth ID.
            title: Optional title (auto-generated from first message later).

        Returns:
            Newly created Conversation.
        """
        conversation = cls(user_id=user_id, title=title)
        session.add(conversation)
        await session.flush()
        await session.refresh(conversation)
        return conversation

    @classmethod
    async def delete_by_id_and_user(
        cls, session: "AsyncSession", conversation_id: int, user_id: str
    ) -> bool:
        """Delete a conversation if owned by user.

        Messages are cascade deleted via foreign key constraint.

        Args:
            session: Async database session.
            conversation_id: The conversation ID.
            user_id: The user's Better Auth ID (ownership check).

        Returns:
            True if deleted, False if not found or not owned.
        """
        conversation = await cls.get_by_id_and_user(
            session, conversation_id, user_id
        )
        if conversation is None:
            return False

        await session.delete(conversation)
        await session.flush()
        return True

    async def update_title(
        self, session: "AsyncSession", title: str
    ) -> "Conversation":
        """Update the conversation title.

        Args:
            session: Async database session.
            title: New title (will be truncated to 50 chars).

        Returns:
            Updated Conversation.
        """
        self.title = title[:50] if len(title) > 50 else title
        await session.flush()
        await session.refresh(self)
        return self

    async def touch(self, session: "AsyncSession") -> "Conversation":
        """Update the updated_at timestamp (for activity tracking).

        Args:
            session: Async database session.

        Returns:
            Updated Conversation.
        """
        self.updated_at = datetime.utcnow()
        await session.flush()
        await session.refresh(self)
        return self
