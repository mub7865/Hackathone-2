"""
OpenAI Agents SDK - Agent Configuration Template

PURPOSE:
- Configure the AI agent with instructions and tools.
- Define agent behavior and capabilities.
- Set up model settings and tool configuration.

HOW TO USE:
- Copy this template to your project (e.g. app/chat/agent.py).
- Import your MCP tools and add them to the tools list.
- Customize instructions for your specific use case.

REFERENCES:
- https://openai.github.io/openai-agents-python/
- https://github.com/openai/openai-agents-python
"""

from agents import Agent
from agents.model_settings import ModelSettings

# Import your MCP tools
from app.chat.tools import (
    add_task,
    list_tasks,
    complete_task,
    delete_task,
    update_task,
)


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


def create_agent() -> Agent:
    """
    Create and configure the todo assistant agent.

    Returns:
        Configured Agent instance ready for use.
    """
    agent = Agent(
        name="Todo Assistant",
        instructions=AGENT_INSTRUCTIONS,
        tools=[
            add_task,
            list_tasks,
            complete_task,
            delete_task,
            update_task,
        ],
        # Optional: Configure model settings
        model_settings=ModelSettings(
            # Use tool_choice="auto" for normal behavior
            # Use tool_choice="required" to force tool usage
            tool_choice="auto",
        ),
    )
    return agent


# Create singleton agent instance
agent = create_agent()


# Optional: Create agent with MCP server connection
async def create_agent_with_mcp(mcp_server_url: str) -> Agent:
    """
    Create agent connected to an external MCP server.

    Use this when tools are hosted on a separate MCP server
    rather than defined as function tools.

    Args:
        mcp_server_url: URL of the MCP server (e.g., http://localhost:8001/mcp)

    Returns:
        Configured Agent instance with MCP server connection.
    """
    from agents.mcp import MCPServerStreamableHttp

    async with MCPServerStreamableHttp(
        name="Todo MCP Server",
        params={
            "url": mcp_server_url,
            "timeout": 30,
        },
        cache_tools_list=True,
    ) as mcp_server:
        agent = Agent(
            name="Todo Assistant",
            instructions=AGENT_INSTRUCTIONS,
            mcp_servers=[mcp_server],
        )
        return agent
