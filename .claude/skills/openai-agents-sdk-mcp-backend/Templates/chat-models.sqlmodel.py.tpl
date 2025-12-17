"""
Chat Database Models Template

PURPOSE:
- Define SQLModel models for conversation persistence.
- Store chat history for stateless server architecture.
- Enable conversation resumption across server restarts.

HOW TO USE:
- Copy this template to your project (e.g. app/models/chat.py).
- Run database migrations to create the tables.
- Import models in your chat router.

REFERENCES:
- https://sqlmodel.tiangolo.com/
"""

from typing import Optional, List
from datetime import datetime

from sqlmodel import SQLModel, Field, Relationship


class Conversation(SQLModel, table=True):
    """
    Represents a chat conversation/session.

    A conversation groups related messages together and belongs
    to a single user. Multiple conversations can exist per user.

    Attributes:
        id: Unique conversation identifier.
        user_id: ID of the user who owns this conversation.
        created_at: When the conversation was started.
        updated_at: When the conversation was last active.
        messages: List of messages in this conversation.
    """

    __tablename__ = "conversations"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: str = Field(index=True, description="User who owns this conversation")
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        description="Conversation creation timestamp",
    )
    updated_at: datetime = Field(
        default_factory=datetime.utcnow,
        description="Last activity timestamp",
    )

    # Relationship to messages
    messages: List["Message"] = Relationship(back_populates="conversation")


class Message(SQLModel, table=True):
    """
    Represents a single message in a conversation.

    Messages can be from the user or the assistant. They are
    stored to maintain conversation history for context.

    Attributes:
        id: Unique message identifier.
        conversation_id: ID of the parent conversation.
        user_id: ID of the user (for user isolation).
        role: Message sender - "user" or "assistant".
        content: The message text content.
        created_at: When the message was created.
        conversation: Reference to parent conversation.
    """

    __tablename__ = "messages"

    id: Optional[int] = Field(default=None, primary_key=True)
    conversation_id: int = Field(
        foreign_key="conversations.id",
        index=True,
        description="Parent conversation ID",
    )
    user_id: str = Field(
        index=True,
        description="User ID for isolation",
    )
    role: str = Field(
        description="Message role: 'user' or 'assistant'",
    )
    content: str = Field(
        description="Message text content",
    )
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        description="Message timestamp",
    )

    # Relationship to conversation
    conversation: Optional[Conversation] = Relationship(back_populates="messages")


# --- Optional: Tool Call Log Model ---

class ToolCallLog(SQLModel, table=True):
    """
    Logs tool calls made by the AI agent.

    Useful for debugging, analytics, and audit trails.
    This model is optional but recommended for production.

    Attributes:
        id: Unique log entry identifier.
        message_id: ID of the assistant message that triggered this call.
        user_id: User ID for filtering.
        tool_name: Name of the tool that was called.
        arguments: JSON string of tool arguments.
        result: JSON string of tool result.
        created_at: When the tool was called.
    """

    __tablename__ = "tool_call_logs"

    id: Optional[int] = Field(default=None, primary_key=True)
    message_id: Optional[int] = Field(
        default=None,
        foreign_key="messages.id",
        index=True,
        description="Associated assistant message",
    )
    user_id: str = Field(
        index=True,
        description="User ID for filtering",
    )
    tool_name: str = Field(
        description="Name of the tool called",
    )
    arguments: str = Field(
        default="{}",
        description="JSON string of tool arguments",
    )
    result: str = Field(
        default="{}",
        description="JSON string of tool result",
    )
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        description="Tool call timestamp",
    )


# --- Pydantic Schemas for API ---

class ConversationRead(SQLModel):
    """Schema for reading conversation data."""

    id: int
    user_id: str
    created_at: datetime
    updated_at: datetime


class MessageRead(SQLModel):
    """Schema for reading message data."""

    id: int
    conversation_id: int
    role: str
    content: str
    created_at: datetime


class ConversationWithMessages(ConversationRead):
    """Schema for conversation with its messages."""

    messages: List[MessageRead] = []
