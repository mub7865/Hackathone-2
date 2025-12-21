"""
Function Tools Definition Template (ALTERNATIVE - Not MCP Standard)

PURPOSE:
- Define function tools using @function_tool decorator from OpenAI Agents SDK.
- This is a SIMPLER but NOT MCP-STANDARD approach.
- Use this only for quick prototypes, NOT for hackathon submission.

IMPORTANT:
- For hackathon, use mcp-server.py.tpl with @mcp.tool() instead!
- @function_tool creates agent-specific tools, not MCP protocol tools.
- Tools defined here are NOT reusable by other MCP clients.

HOW TO USE:
- Copy this template ONLY if you need a quick prototype.
- For proper MCP implementation, use mcp-server.py.tpl instead.

COMPARISON:
| Aspect | @mcp.tool() | @function_tool |
|--------|-------------|----------------|
| Protocol | MCP Standard | OpenAI-specific |
| Reusability | Any MCP client | This agent only |
| Architecture | Separate server | Same process |
| Hackathon | RECOMMENDED | Not recommended |

REFERENCES:
- https://openai.github.io/openai-agents-python/tools/
"""

from typing import Any, List, Optional

from agents import function_tool

# Import your database session and models
# from app.db import get_session
# from app.models import Task


@function_tool
async def add_task(
    user_id: str,
    title: str,
    description: str = "",
) -> dict[str, Any]:
    """Add a new task for the user.

    NOTE: This uses @function_tool (OpenAI Agents SDK), not @mcp.tool() (MCP SDK).
    For hackathon, prefer using mcp-server.py.tpl with @mcp.tool() instead.

    Args:
        user_id: The unique identifier of the user.
        title: The title of the task (required, 1-200 characters).
        description: Optional detailed description of the task.

    Returns:
        Dictionary containing task_id, status, and title.
    """
    # TODO: Replace with actual database implementation
    # async with get_session() as session:
    #     task = Task(user_id=user_id, title=title, description=description)
    #     session.add(task)
    #     await session.commit()
    #     await session.refresh(task)
    #     return {"task_id": task.id, "status": "created", "title": task.title}

    # Placeholder implementation
    return {
        "task_id": "1",
        "status": "created",
        "title": title,
    }


@function_tool
async def list_tasks(
    user_id: str,
    status: str = "all",
) -> dict[str, Any]:
    """List tasks for the user.

    Args:
        user_id: The unique identifier of the user.
        status: Filter by status - "all", "pending", or "completed".

    Returns:
        Dictionary containing tasks list, count, and filter applied.
    """
    # TODO: Replace with actual database implementation
    # Placeholder implementation
    return {
        "tasks": [
            {
                "id": "1",
                "title": "Example Task",
                "description": "",
                "completed": False,
            }
        ],
        "count": 1,
        "filter": status,
    }


@function_tool
async def complete_task(
    user_id: str,
    task_id: str,
) -> dict[str, Any]:
    """Mark a task as complete.

    Args:
        user_id: The unique identifier of the user.
        task_id: The ID of the task to mark as complete.

    Returns:
        Dictionary with task_id, status, and title.
    """
    # Placeholder implementation
    return {
        "task_id": task_id,
        "status": "completed",
        "title": "Example Task",
    }


@function_tool
async def delete_task(
    user_id: str,
    task_id: str,
) -> dict[str, Any]:
    """Delete a task from the list.

    Args:
        user_id: The unique identifier of the user.
        task_id: The ID of the task to delete.

    Returns:
        Dictionary with task_id, status, and title.
    """
    # Placeholder implementation
    return {
        "task_id": task_id,
        "status": "deleted",
        "title": "Example Task",
    }


@function_tool
async def update_task(
    user_id: str,
    task_id: str,
    title: Optional[str] = None,
    description: Optional[str] = None,
) -> dict[str, Any]:
    """Update a task's title or description.

    Args:
        user_id: The unique identifier of the user.
        task_id: The ID of the task to update.
        title: New title for the task (optional).
        description: New description for the task (optional).

    Returns:
        Dictionary with task_id, status, and title.
    """
    # Placeholder implementation
    return {
        "task_id": task_id,
        "status": "updated",
        "title": title or "Example Task",
    }


# ============================================================================
# USAGE WITH AGENT (NOT RECOMMENDED FOR HACKATHON)
# ============================================================================
#
# from agents import Agent
#
# agent = Agent(
#     name="Todo Assistant",
#     instructions="Help users manage tasks.",
#     tools=[add_task, list_tasks, complete_task, delete_task, update_task],
# )
#
# # This does NOT use MCP protocol - tools are directly embedded in agent.
# # For hackathon, use mcp-server.py.tpl with proper MCP server instead.
