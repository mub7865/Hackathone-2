"""Message model for AI Chatbot Phase III.

This module defines the Message entity for storing individual chat messages
within conversations.
"""

from datetime import datetime
from enum import Enum
from typing import TYPE_CHECKING, Optional, Sequence

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text, func
from sqlmodel import Field, SQLModel, select

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession


class MessageRole(str, Enum):
    """Valid message roles.

    Attributes:
        USER: Message from the user.
        ASSISTANT: Message from the AI assistant.
    """

    USER = "user"
    ASSISTANT = "assistant"


class Message(SQLModel, table=True):
    """Represents a single message in a conversation.

    Invariants:
        - Every message belongs to exactly one conversation (conversation_id NOT NULL)
        - Role must be 'user' or 'assistant'
        - Content cannot be empty
        - Cascade delete when parent conversation is deleted

    Attributes:
        id: Unique message identifier (auto-increment).
        conversation_id: Parent conversation ID (FK with cascade delete).
        role: Message sender - 'user' or 'assistant'.
        content: Message text content.
        created_at: When message was sent (auto-set).
    """

    __tablename__ = "messages"

    # Primary key
    id: Optional[int] = Field(default=None, primary_key=True)

    # Parent conversation (with cascade delete)
    conversation_id: int = Field(
        sa_column=Column(
            Integer,
            ForeignKey("conversations.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        description="Parent conversation ID (cascade delete)",
    )

    # Message role
    role: str = Field(
        ...,
        max_length=20,
        sa_column=Column(String(20), nullable=False),
        description="Message sender: 'user' or 'assistant'",
    )

    # Message content
    content: str = Field(
        ...,
        sa_column=Column(Text, nullable=False),
        description="Message text content",
    )

    # Timestamp
    created_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            server_default=func.now(),
            nullable=False,
        ),
        description="When message was sent",
    )

    # -------------------------------------------------------------------------
    # Query Methods
    # -------------------------------------------------------------------------

    @classmethod
    async def get_by_conversation(
        cls,
        session: "AsyncSession",
        conversation_id: int,
        limit: Optional[int] = None,
    ) -> Sequence["Message"]:
        """Get all messages for a conversation, ordered by creation time.

        Args:
            session: Async database session.
            conversation_id: The parent conversation ID.
            limit: Optional limit on number of messages (for context window).

        Returns:
            List of messages ordered by created_at ASC.
        """
        statement = (
            select(cls)
            .where(cls.conversation_id == conversation_id)
            .order_by(cls.created_at.asc())
        )
        if limit is not None:
            # Get last N messages by ordering desc, limiting, then reversing
            statement = (
                select(cls)
                .where(cls.conversation_id == conversation_id)
                .order_by(cls.created_at.desc())
                .limit(limit)
            )
            result = await session.execute(statement)
            messages = list(result.scalars().all())
            return list(reversed(messages))

        result = await session.execute(statement)
        return result.scalars().all()

    @classmethod
    async def count_by_conversation(
        cls, session: "AsyncSession", conversation_id: int
    ) -> int:
        """Count messages in a conversation.

        Args:
            session: Async database session.
            conversation_id: The parent conversation ID.

        Returns:
            Number of messages in the conversation.
        """
        from sqlalchemy import func as sql_func

        statement = (
            select(sql_func.count(cls.id))
            .where(cls.conversation_id == conversation_id)
        )
        result = await session.execute(statement)
        return result.scalar_one()

    @classmethod
    async def create(
        cls,
        session: "AsyncSession",
        conversation_id: int,
        role: str,
        content: str,
    ) -> "Message":
        """Create a new message in a conversation.

        Args:
            session: Async database session.
            conversation_id: The parent conversation ID.
            role: Message sender ('user' or 'assistant').
            content: Message text content.

        Returns:
            Newly created Message.
        """
        message = cls(
            conversation_id=conversation_id,
            role=role,
            content=content,
        )
        session.add(message)
        await session.flush()
        await session.refresh(message)
        return message

    @classmethod
    async def get_last_n(
        cls,
        session: "AsyncSession",
        conversation_id: int,
        n: int = 100,
    ) -> Sequence["Message"]:
        """Get the last N messages for AI context.

        Args:
            session: Async database session.
            conversation_id: The parent conversation ID.
            n: Number of messages to retrieve (default 100).

        Returns:
            Last N messages ordered by created_at ASC for context.
        """
        return await cls.get_by_conversation(session, conversation_id, limit=n)
