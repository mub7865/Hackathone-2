"""
OpenAI Agents SDK - Agent Configuration Template with MCP Server Connection

PURPOSE:
- Configure the AI agent to connect to an MCP server.
- Define agent behavior and capabilities.
- Set up model settings and MCP server connection.

HOW TO USE:
- Copy this template to your project (e.g. app/chat/agent.py).
- Update MCP_SERVER_URL to point to your MCP server.
- Customize instructions for your specific use case.

REFERENCES:
- https://openai.github.io/openai-agents-python/mcp/
- https://github.com/openai/openai-agents-python
"""

import os
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from agents import Agent, Runner
from agents.mcp import MCPServerStreamableHttp
from agents.model_settings import ModelSettings
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# MCP Server URL - adjust to your MCP server location
MCP_SERVER_URL = os.environ.get("MCP_SERVER_URL", "http://localhost:8001/mcp")

# Agent instructions - customize for your use case
AGENT_INSTRUCTIONS = """You are a helpful assistant that helps users manage their tasks.

## CAPABILITIES
You can help users with the following:
- Add new tasks with titles and optional descriptions
- List all tasks, or filter by status (pending/completed)
- Mark tasks as complete
- Delete tasks they no longer need
- Update task titles or descriptions

## BEHAVIOR GUIDELINES
1. Always confirm actions with a friendly, concise message
2. When listing tasks, format them clearly with task IDs
3. If a task is not found, explain politely and suggest alternatives
4. Ask for clarification if the user's request is ambiguous
5. Be proactive in suggesting related actions (e.g., after adding a task, offer to add more)

## RESPONSE FORMAT
- Keep responses conversational but concise
- Use task IDs when referring to specific tasks
- Format task lists with clear structure:
  - Task ID: [id]
  - Title: [title]
  - Status: [pending/completed]

## EXAMPLE INTERACTIONS
User: "Add a task to buy groceries"
You: Use add_task tool, then respond: "I've added 'Buy groceries' to your list (Task #5). Would you like to add any details or another task?"

User: "What do I need to do?"
You: Use list_tasks with status="pending", then list them clearly

User: "Done with task 3"
You: Use complete_task with task_id=3, then confirm: "Great job! Task #3 '[title]' is now marked as complete."

User: "Remove task 2"
You: Use delete_task with task_id=2, then confirm: "Task #2 '[title]' has been removed from your list."
"""


@asynccontextmanager
async def create_agent() -> AsyncGenerator[Agent, None]:
    """
    Create and configure the todo assistant agent with MCP server connection.

    This is an async context manager that establishes connection to the
    MCP server and yields the configured agent.

    Usage:
        async with create_agent() as agent:
            result = await Runner.run(agent, input="Show my tasks")

    Yields:
        Configured Agent instance connected to MCP server.
    """
    async with MCPServerStreamableHttp(
        name="Todo MCP Server",
        params={
            "url": MCP_SERVER_URL,
            "timeout": 30,
        },
        cache_tools_list=True,  # Cache tools list for better performance
    ) as mcp_server:
        agent = Agent(
            name="Todo Assistant",
            instructions=AGENT_INSTRUCTIONS,
            mcp_servers=[mcp_server],
            # Optional: Configure model settings
            model_settings=ModelSettings(
                # Use tool_choice="auto" for normal behavior
                # Use tool_choice="required" to force tool usage
                tool_choice="auto",
            ),
        )
        yield agent


async def process_message(user_message: str, user_id: str) -> str:
    """
    Process a user message through the agent.

    Args:
        user_message: The user's natural language message.
        user_id: The user's unique identifier for task isolation.

    Returns:
        The agent's response as a string.
    """
    async with create_agent() as agent:
        result = await Runner.run(
            agent,
            input=user_message,
            context={"user_id": user_id},
        )
        return result.final_output


# ============================================================================
# ALTERNATIVE: Agent with Gemini Model
# ============================================================================


async def create_agent_with_gemini() -> AsyncGenerator[Agent, None]:
    """
    Create agent with Google Gemini model instead of OpenAI.

    Requires GEMINI_API_KEY environment variable.

    Usage:
        async with create_agent_with_gemini() as agent:
            result = await Runner.run(agent, input="Show my tasks")
    """
    from openai import AsyncOpenAI
    from agents import OpenAIChatCompletionsModel, set_tracing_disabled

    # Disable tracing for non-OpenAI providers
    set_tracing_disabled(disabled=True)

    # Configure Gemini client
    gemini_client = AsyncOpenAI(
        api_key=os.environ["GEMINI_API_KEY"],
        base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
    )

    async with MCPServerStreamableHttp(
        name="Todo MCP Server",
        params={"url": MCP_SERVER_URL},
    ) as mcp_server:
        agent = Agent(
            name="Todo Assistant",
            instructions=AGENT_INSTRUCTIONS,
            model=OpenAIChatCompletionsModel(
                model="gemini-2.0-flash",  # or "gemini-1.5-pro", "gemini-1.5-flash"
                openai_client=gemini_client,
            ),
            mcp_servers=[mcp_server],
        )
        yield agent


# ============================================================================
# ALTERNATIVE: Agent with Function Tools (not MCP standard)
# ============================================================================
# If you prefer simpler setup without separate MCP server, you can use
# @function_tool decorator directly. See mcp-tools.py.tpl for this approach.
# Note: This does NOT follow MCP protocol and is not recommended for hackathon.
#
# from agents import Agent
# from app.chat.tools import add_task, list_tasks, complete_task
#
# agent = Agent(
#     name="Todo Assistant",
#     instructions=AGENT_INSTRUCTIONS,
#     tools=[add_task, list_tasks, complete_task, delete_task, update_task],
# )
