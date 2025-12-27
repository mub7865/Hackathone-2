"""AI Agent for Todo Chatbot Phase III.

This module configures the AI agent using the OpenAI Agents SDK
connected to the MCP Server via HTTP transport (Streamable HTTP).

ARCHITECTURE (Updated 2025-12-21):
- MCP Server is mounted at /mcp endpoint in FastAPI
- Agent connects via MCPServerStreamableHttp to http://localhost:8000/mcp
- Agent uses mcp_servers=[mcp_server] parameter (NOT tools=[])
- Tools receive user_id via agent instructions

References:
- https://openai.github.io/openai-agents-python/mcp/
- https://modelcontextprotocol.io/docs/develop/build-server
- https://gofastmcp.com/servers/streamable-http
"""

import os
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from agents import Agent, set_tracing_disabled
from agents.mcp import MCPServerStreamableHttp
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Disable tracing for cleaner output
set_tracing_disabled(disabled=True)

# MCP Server URL - points to the /mcp/mcp endpoint mounted in FastAPI
# Note: streamable_http_app() mounts internally at /mcp, so full path is /mcp/mcp
# Production: https://hackathone-2-gamma.vercel.app/mcp/mcp
# Development: http://localhost:8000/mcp/mcp
MCP_SERVER_URL = os.environ.get("MCP_SERVER_URL", "https://hackathone-2-gamma.vercel.app/mcp/mcp")


def get_agent_instructions(user_id: str) -> str:
    """Generate agent instructions with user_id context.

    The MCP tools need user_id to enforce data isolation.
    We inject it into the agent instructions so the LLM
    includes it in tool calls.

    Args:
        user_id: The authenticated user's ID.

    Returns:
        Agent instructions with user_id context.
    """
    return f"""You are a helpful and friendly AI assistant that helps users manage their todo tasks through natural language conversation.

IMPORTANT - USER CONTEXT:
The current user's ID is: {user_id}
You MUST pass this user_id to EVERY tool call to ensure proper data isolation.

CAPABILITIES:
- Add new tasks (add_task) - Create tasks for users to track
- List tasks (list_tasks) - Show tasks with optional filtering by status
- Complete tasks (complete_task) - Mark tasks as done
- Delete tasks (delete_task) - Remove tasks from the list
- Update tasks (update_task) - Change task title or description

TOOL CALL FORMAT:
When calling tools, ALWAYS include the user_id parameter:
- add_task(user_id="{user_id}", title="...", description="...")
- list_tasks(user_id="{user_id}", status="all|pending|completed")
- complete_task(user_id="{user_id}", task_id="...")
- delete_task(user_id="{user_id}", task_id="...")
- update_task(user_id="{user_id}", task_id="...", title="...", description="...")

BEHAVIOR GUIDELINES:
1. Always be friendly and conversational in your responses
2. When listing tasks, format them clearly with task IDs so users can reference them
3. After performing an action, confirm what you did
4. If a task is not found, suggest listing tasks first to find the correct ID
5. Ask for clarification if the user's request is ambiguous
6. When the user mentions a task by name rather than ID, try to find it by listing tasks first

IMPORTANT NOTES:
- Task IDs are UUIDs (long strings like "550e8400-e29b-41d4-a716-446655440000")
- When showing tasks to users, display the ID so they can reference it
- The user can only see and manage their own tasks (user isolation via user_id)

RESPONSE STYLE:
- Keep responses concise but helpful
- Use bullet points or numbered lists when showing multiple tasks
- Don't over-explain - users want quick task management

EXAMPLE INTERACTIONS:

User: "Add a task to buy groceries"
Assistant: I've added "Buy groceries" to your task list!

User: "Show my tasks"
Assistant: Here are your tasks:
1. Buy groceries (ID: abc-123...) - Pending
2. Call mom (ID: def-456...) - Completed

User: "Mark the groceries task as done"
Assistant: Done! I've marked "Buy groceries" as completed.

User: "Delete task abc-123"
Assistant: I've deleted "Buy groceries" from your list.

User: "What do I need to do?"
Assistant: Here are your pending tasks:
1. Call mom (ID: def-456...) - Pending
"""


@asynccontextmanager
async def create_mcp_agent(user_id: str) -> AsyncGenerator[Agent, None]:
    """Create and configure the AI agent connected to MCP Server via HTTP.

    This is an async context manager that:
    1. Connects to the MCP Server via HTTP at /mcp endpoint
    2. Creates an agent with user_id in instructions
    3. Yields the configured agent
    4. Cleans up on exit

    IMPORTANT: Agent uses mcp_servers parameter, NOT tools parameter!
    This is the correct MCP integration as per hackathon requirements.

    Args:
        user_id: The authenticated user's ID for data isolation.

    Usage:
        async with create_mcp_agent(user_id) as agent:
            result = await Runner.run(agent, input="Show my tasks")

    Yields:
        Configured Agent instance connected to MCP Server.

    Raises:
        ValueError: If OPENAI_API_KEY environment variable is not set.
    """
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise ValueError(
            "OPENAI_API_KEY environment variable is required."
        )

    # Connect to MCP Server via HTTP (Streamable HTTP transport)
    async with MCPServerStreamableHttp(
        name="Todo MCP Server",
        params={"url": MCP_SERVER_URL},
    ) as mcp_server:
        # Create agent connected to MCP Server with user context
        # ✅ CORRECT: Using mcp_servers parameter, NOT tools parameter!
        agent = Agent(
            name="Todo Assistant",
            instructions=get_agent_instructions(user_id),
            mcp_servers=[mcp_server],  # ✅ MCP Server connection via mcp_servers!
            # NO tools=[] here - tools come from MCP Server automatically!
        )
        yield agent
