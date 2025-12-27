"""Conversations API endpoints for AI Chatbot Phase III.

This module provides CRUD operations for conversation management:
- GET /conversations - List user's conversations
- GET /conversations/{id} - Get single conversation with messages
- DELETE /conversations/{id} - Delete conversation (cascade deletes messages)
"""

from typing import Any

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel

from app.api.deps import CurrentUser, DbSession
from app.models.conversation import Conversation
from app.models.message import Message

router = APIRouter()


# ----- Response Models -----


class ConversationSummary(BaseModel):
    """Conversation summary for list view."""

    id: int
    title: str | None
    created_at: str
    updated_at: str
    message_count: int


class ConversationListResponse(BaseModel):
    """Response for listing conversations."""

    conversations: list[ConversationSummary]


class MessageResponse(BaseModel):
    """Single message in conversation detail."""

    id: int
    role: str
    content: str
    created_at: str


class ConversationDetailResponse(BaseModel):
    """Response for getting a single conversation with messages."""

    id: int
    title: str | None
    created_at: str
    updated_at: str
    messages: list[MessageResponse]


class DeleteConversationResponse(BaseModel):
    """Response for deleting a conversation."""

    success: bool
    deleted_conversation_id: int
    deleted_message_count: int


# ----- Endpoints -----


@router.get("", response_model=ConversationListResponse)
async def list_conversations(
    db: DbSession,
    current_user: CurrentUser,
) -> dict[str, Any]:
    """List all conversations for the current user.

    Returns conversations sorted by most recent activity (updated_at DESC).
    Each conversation includes a message count for display in the sidebar.

    Returns:
        List of conversation summaries.
    """
    conversations = await Conversation.get_by_user(db, current_user)

    conversation_list = []
    for conv in conversations:
        message_count = await Message.count_by_conversation(db, conv.id)
        conversation_list.append(
            ConversationSummary(
                id=conv.id,
                title=conv.title,
                created_at=conv.created_at.isoformat() if conv.created_at else "",
                updated_at=conv.updated_at.isoformat() if conv.updated_at else "",
                message_count=message_count,
            )
        )

    return {"conversations": conversation_list}


@router.get("/{conversation_id}", response_model=ConversationDetailResponse)
async def get_conversation(
    conversation_id: int,
    db: DbSession,
    current_user: CurrentUser,
) -> dict[str, Any]:
    """Get a single conversation with all its messages.

    Args:
        conversation_id: The conversation ID to retrieve.

    Returns:
        Conversation details with full message history.

    Raises:
        HTTPException: 404 if conversation not found or not owned by user.
    """
    conversation = await Conversation.get_by_id_and_user(
        db, conversation_id, current_user
    )

    if conversation is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )

    messages = await Message.get_by_conversation(db, conversation_id)

    message_list = [
        MessageResponse(
            id=msg.id,
            role=msg.role,
            content=msg.content,
            created_at=msg.created_at.isoformat() if msg.created_at else "",
        )
        for msg in messages
    ]

    return {
        "id": conversation.id,
        "title": conversation.title,
        "created_at": conversation.created_at.isoformat() if conversation.created_at else "",
        "updated_at": conversation.updated_at.isoformat() if conversation.updated_at else "",
        "messages": message_list,
    }


@router.delete("/{conversation_id}", response_model=DeleteConversationResponse)
async def delete_conversation(
    conversation_id: int,
    db: DbSession,
    current_user: CurrentUser,
) -> dict[str, Any]:
    """Delete a conversation and all its messages.

    Messages are cascade deleted via foreign key constraint.

    Args:
        conversation_id: The conversation ID to delete.

    Returns:
        Success status with deleted counts.

    Raises:
        HTTPException: 404 if conversation not found or not owned by user.
    """
    # Get message count before deletion
    conversation = await Conversation.get_by_id_and_user(
        db, conversation_id, current_user
    )

    if conversation is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )

    message_count = await Message.count_by_conversation(db, conversation_id)

    # Delete conversation (messages cascade deleted)
    deleted = await Conversation.delete_by_id_and_user(
        db, conversation_id, current_user
    )

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )

    await db.commit()

    return {
        "success": True,
        "deleted_conversation_id": conversation_id,
        "deleted_message_count": message_count,
    }
