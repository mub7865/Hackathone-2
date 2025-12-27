"""Chat API endpoint for AI Chatbot Phase III.

This module provides the main chat endpoint that:
1. Receives user messages
2. Creates/updates conversations
3. Runs the AI agent connected to MCP Server via HTTP transport
4. Stores messages and returns AI response

ARCHITECTURE (Updated 2025-12-21):
- MCP Server mounted at /mcp endpoint in FastAPI
- Agent connects via MCPServerStreamableHttp to /mcp
- Agent uses mcp_servers=[mcp_server] parameter (NOT tools=[])
- Tools receive user_id via agent instructions
- Each tool creates its own database session
"""

from typing import Any

from agents import Runner
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from app.api.deps import CurrentUser, DbSession
from app.models.conversation import Conversation
from app.models.message import Message
from app.services.agent import create_mcp_agent

router = APIRouter()


# ----- Request/Response Models -----


class ChatRequest(BaseModel):
    """Request body for chat endpoint."""

    message: str = Field(..., min_length=1, max_length=4000)
    conversation_id: int | None = None


class ToolCallResponse(BaseModel):
    """Tool call details in response."""

    name: str
    arguments: dict[str, Any]
    result: dict[str, Any]


class ChatResponse(BaseModel):
    """Response from chat endpoint."""

    conversation_id: int
    response: str
    tool_calls: list[ToolCallResponse] = []


# ----- Endpoint -----


@router.post("", response_model=ChatResponse)
async def chat(
    request: ChatRequest,
    db: DbSession,
    current_user: CurrentUser,
) -> dict[str, Any]:
    """Send a message to the AI assistant and receive a response.

    This endpoint handles the complete chat flow:
    1. Get or create conversation
    2. Store user message
    3. Load conversation history for context
    4. Run AI agent connected to MCP Server via HTTP
    5. Store assistant response
    6. Return response with tool call details

    The agent connects to the MCP Server via mcp_servers parameter
    using MCPServerStreamableHttp, following the hackathon requirement
    for proper MCP integration.

    Args:
        request: Chat request with message and optional conversation_id.

    Returns:
        ChatResponse with conversation_id, response text, and tool calls.

    Raises:
        HTTPException: 400 if message is empty, 404 if conversation not found,
                       500 if agent fails.
    """
    message = request.message.strip()
    if not message:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message cannot be empty",
        )

    # Step 1: Get or create conversation
    conversation: Conversation
    if request.conversation_id is not None:
        # Load existing conversation
        conversation = await Conversation.get_by_id_and_user(
            db, request.conversation_id, current_user
        )
        if conversation is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found",
            )
    else:
        # Create new conversation with title from first message
        title = message[:50] if len(message) > 50 else message
        conversation = await Conversation.create(db, current_user, title)

    # Step 2: Store user message
    await Message.create(
        db,
        conversation_id=conversation.id,
        role="user",
        content=message,
    )

    # Step 3: Load conversation history for context (last 100 messages)
    history_messages = await Message.get_last_n(db, conversation.id, n=100)

    # Convert to agent message format
    agent_history = [
        {"role": msg.role, "content": msg.content}
        for msg in history_messages
    ]

    # Step 4: Run AI agent with MCP Server connection
    # Agent connects via mcp_servers=[MCPServerStreamableHttp]
    # Tools are discovered automatically via MCP protocol
    try:
        async with create_mcp_agent(current_user) as agent:
            result = await Runner.run(
                agent,
                input=agent_history,
            )
            response_text = result.final_output or "I apologize, but I couldn't process that request."
            tool_calls = _extract_tool_calls(result)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process message. Please try again. Error: {str(e)}",
        )

    # Step 5: Store assistant response
    await Message.create(
        db,
        conversation_id=conversation.id,
        role="assistant",
        content=response_text,
    )

    # Update conversation timestamp
    await conversation.touch(db)

    # Commit all changes
    await db.commit()

    # Step 6: Return response
    return {
        "conversation_id": conversation.id,
        "response": response_text,
        "tool_calls": tool_calls,
    }


def _extract_tool_calls(result) -> list[ToolCallResponse]:
    """Extract tool call details from agent result.

    Args:
        result: The Runner result object.

    Returns:
        List of ToolCallResponse objects.
    """
    tool_calls: list[ToolCallResponse] = []
    if hasattr(result, "new_items"):
        for item in result.new_items:
            if hasattr(item, "type") and item.type == "tool_call_item":
                # Get tool call details
                if hasattr(item, "raw_item"):
                    raw = item.raw_item
                    if hasattr(raw, "name") and hasattr(raw, "arguments"):
                        tool_calls.append(
                            ToolCallResponse(
                                name=raw.name,
                                arguments=raw.arguments if isinstance(raw.arguments, dict) else {},
                                result={},
                            )
                        )
    return tool_calls
