"""
Chat Router Template for FastAPI + OpenAI Agents SDK

PURPOSE:
- Implement the chat endpoint for AI agent conversations.
- Handle conversation history persistence.
- Integrate with JWT authentication.

HOW TO USE:
- Copy this template to your project (e.g. app/routers/chat.py).
- Import your agent configuration and database dependencies.
- Register the router in your main.py FastAPI app.

REFERENCES:
- https://openai.github.io/openai-agents-python/
"""

from typing import List, Optional
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlmodel import Session, select
from agents import Runner

# Import your dependencies - adjust paths as needed
from app.db import get_session
from app.chat.agent import agent
from app.models.chat import Conversation, Message
from app.auth.dependencies import get_current_user  # Your JWT auth dependency
from app.models import User  # Your user model


# --- Request/Response Schemas ---

class ChatRequest(BaseModel):
    """Request body for chat endpoint."""

    message: str
    conversation_id: Optional[int] = None

    class Config:
        json_schema_extra = {
            "example": {
                "message": "Add a task to buy groceries",
                "conversation_id": None,
            }
        }


class ToolCallInfo(BaseModel):
    """Information about a tool call made by the agent."""

    name: str
    arguments: dict
    result: dict


class ChatResponse(BaseModel):
    """Response from chat endpoint."""

    conversation_id: int
    response: str
    tool_calls: List[ToolCallInfo] = []

    class Config:
        json_schema_extra = {
            "example": {
                "conversation_id": 1,
                "response": "I've added 'Buy groceries' to your task list (Task #5).",
                "tool_calls": [
                    {
                        "name": "add_task",
                        "arguments": {"user_id": "user123", "title": "Buy groceries"},
                        "result": {"task_id": 5, "status": "created"},
                    }
                ],
            }
        }


# --- Router Setup ---

router = APIRouter(
    prefix="/api/{user_id}",
    tags=["chat"],
)


# --- Helper Functions ---

async def get_or_create_conversation(
    session: Session,
    user_id: str,
    conversation_id: Optional[int] = None,
) -> Conversation:
    """
    Get existing conversation or create a new one.

    Args:
        session: Database session.
        user_id: User ID for the conversation.
        conversation_id: Optional existing conversation ID.

    Returns:
        Conversation instance.

    Raises:
        HTTPException: If conversation_id is provided but not found.
    """
    if conversation_id:
        # Fetch existing conversation
        conversation = session.get(Conversation, conversation_id)
        if not conversation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found",
            )
        if conversation.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to access this conversation",
            )
        # Update timestamp
        conversation.updated_at = datetime.utcnow()
        session.add(conversation)
        session.commit()
        return conversation

    # Create new conversation
    conversation = Conversation(user_id=user_id)
    session.add(conversation)
    session.commit()
    session.refresh(conversation)
    return conversation


async def get_conversation_history(
    session: Session,
    conversation_id: int,
    limit: int = 20,
) -> List[dict]:
    """
    Fetch recent messages from a conversation.

    Args:
        session: Database session.
        conversation_id: ID of the conversation.
        limit: Maximum number of messages to retrieve.

    Returns:
        List of message dictionaries with role and content.
    """
    statement = (
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .order_by(Message.created_at.desc())
        .limit(limit)
    )
    messages = session.exec(statement).all()

    # Reverse to get chronological order
    return [
        {"role": msg.role, "content": msg.content}
        for msg in reversed(messages)
    ]


async def store_message(
    session: Session,
    conversation_id: int,
    user_id: str,
    role: str,
    content: str,
) -> Message:
    """
    Store a message in the conversation.

    Args:
        session: Database session.
        conversation_id: ID of the conversation.
        user_id: User ID for the message.
        role: Message role ("user" or "assistant").
        content: Message content.

    Returns:
        Created Message instance.
    """
    message = Message(
        conversation_id=conversation_id,
        user_id=user_id,
        role=role,
        content=content,
    )
    session.add(message)
    session.commit()
    session.refresh(message)
    return message


def extract_tool_calls(result) -> List[ToolCallInfo]:
    """
    Extract tool call information from agent result.

    Args:
        result: RunResult from agent execution.

    Returns:
        List of ToolCallInfo objects.
    """
    tool_calls = []

    # Check if result has tool calls information
    # The exact structure depends on your agent configuration
    if hasattr(result, "tool_calls") and result.tool_calls:
        for call in result.tool_calls:
            tool_calls.append(
                ToolCallInfo(
                    name=call.name,
                    arguments=call.arguments or {},
                    result=call.result or {},
                )
            )

    return tool_calls


# --- Chat Endpoint ---

@router.post(
    "/chat",
    response_model=ChatResponse,
    summary="Send a chat message",
    description="Send a message to the AI assistant and receive a response.",
)
async def chat(
    user_id: str,
    request: ChatRequest,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
) -> ChatResponse:
    """
    Process a chat message through the AI agent.

    This endpoint:
    1. Verifies user authorization
    2. Gets or creates a conversation
    3. Fetches conversation history
    4. Stores the user message
    5. Runs the AI agent with tools
    6. Stores the assistant response
    7. Returns the response with tool call info

    Args:
        user_id: User ID from path parameter.
        request: Chat request with message and optional conversation_id.
        session: Database session dependency.
        current_user: Authenticated user from JWT.

    Returns:
        ChatResponse with conversation_id, response, and tool_calls.

    Raises:
        HTTPException: On authorization failure or processing error.
    """
    # 1. Verify user authorization
    if current_user.id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this user's chat",
        )

    try:
        # 2. Get or create conversation
        conversation = await get_or_create_conversation(
            session, user_id, request.conversation_id
        )

        # 3. Fetch conversation history for context
        history = await get_conversation_history(session, conversation.id)

        # 4. Store user message
        await store_message(
            session,
            conversation.id,
            user_id,
            "user",
            request.message,
        )

        # 5. Run the AI agent
        # Pass user_id in context so tools can access it
        result = await Runner.run(
            agent,
            input=request.message,
            context={
                "user_id": user_id,
                "conversation_history": history,
            },
        )

        # 6. Store assistant response
        await store_message(
            session,
            conversation.id,
            user_id,
            "assistant",
            result.final_output,
        )

        # 7. Extract tool calls and return response
        tool_calls = extract_tool_calls(result)

        return ChatResponse(
            conversation_id=conversation.id,
            response=result.final_output,
            tool_calls=tool_calls,
        )

    except HTTPException:
        # Re-raise HTTP exceptions as-is
        raise
    except Exception as e:
        # Log the error for debugging
        import logging
        logging.error(f"Chat processing error: {e}", exc_info=True)

        # Return a user-friendly error
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process your message. Please try again.",
        )


# --- Optional: List Conversations Endpoint ---

@router.get(
    "/conversations",
    response_model=List[dict],
    summary="List user conversations",
)
async def list_conversations(
    user_id: str,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
) -> List[dict]:
    """
    List all conversations for a user.

    Args:
        user_id: User ID from path parameter.
        session: Database session dependency.
        current_user: Authenticated user from JWT.

    Returns:
        List of conversation summaries.
    """
    if current_user.id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized",
        )

    statement = (
        select(Conversation)
        .where(Conversation.user_id == user_id)
        .order_by(Conversation.updated_at.desc())
    )
    conversations = session.exec(statement).all()

    return [
        {
            "id": conv.id,
            "created_at": conv.created_at.isoformat(),
            "updated_at": conv.updated_at.isoformat(),
        }
        for conv in conversations
    ]
