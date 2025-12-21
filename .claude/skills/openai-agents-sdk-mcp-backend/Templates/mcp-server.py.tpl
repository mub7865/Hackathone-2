"""
MCP Server Template using Official MCP Python SDK

PURPOSE:
- Create a standalone MCP server that exposes tools via MCP protocol.
- This is the RECOMMENDED approach for the hackathon.
- Tools defined here can be used by any MCP-compatible client.

HOW TO USE:
- Copy this template to your project (e.g. app/mcp_server.py).
- Replace placeholder implementations with actual database operations.
- Run as a separate process: python mcp_server.py

REFERENCES:
- https://modelcontextprotocol.io/docs/develop/build-server
- https://github.com/modelcontextprotocol/python-sdk
- https://openai.github.io/openai-agents-python/mcp/

INSTALLATION:
- pip install "mcp[cli]" sqlmodel
- or: uv add "mcp[cli]" sqlmodel
"""

import os
from typing import Any

from dotenv import load_dotenv
from mcp.server.fastmcp import FastMCP
from sqlmodel import Session, create_engine, select

# Load environment variables
load_dotenv()

# Import your database models
# from app.models.task import Task

# Initialize FastMCP server with a descriptive name
mcp = FastMCP("todo-mcp-server")

# Database setup (adjust connection string as needed)
DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./test.db")
engine = create_engine(DATABASE_URL)


# ============================================================================
# MCP TOOLS - These are exposed to AI agents via MCP protocol
# ============================================================================


@mcp.tool()
async def add_task(
    user_id: str,
    title: str,
    description: str = "",
) -> dict[str, Any]:
    """Add a new task for the user.

    Creates a new task with the given title and optional description.
    The task is associated with the specified user for isolation.

    Args:
        user_id: The unique identifier of the user (required for user isolation).
        title: The title of the task (required, 1-200 characters).
        description: Optional detailed description of the task.

    Returns:
        Dictionary containing:
        - task_id: The ID of the created task
        - status: "created" if successful
        - title: The title of the created task

    Example:
        >>> await add_task("user123", "Buy groceries", "Milk, eggs, bread")
        {"task_id": "5", "status": "created", "title": "Buy groceries"}
    """
    # TODO: Replace with actual database implementation
    # with Session(engine) as session:
    #     task = Task(
    #         user_id=user_id,
    #         title=title,
    #         description=description,
    #         completed=False,
    #     )
    #     session.add(task)
    #     session.commit()
    #     session.refresh(task)
    #     return {
    #         "task_id": str(task.id),
    #         "status": "created",
    #         "title": task.title,
    #     }

    # Placeholder implementation
    return {
        "task_id": "1",
        "status": "created",
        "title": title,
    }


@mcp.tool()
async def list_tasks(
    user_id: str,
    status: str = "all",
) -> dict[str, Any]:
    """List tasks for the user.

    Retrieves tasks belonging to the specified user, optionally
    filtered by completion status.

    Args:
        user_id: The unique identifier of the user.
        status: Filter by status - "all", "pending", or "completed".
                Defaults to "all".

    Returns:
        Dictionary containing:
        - tasks: List of task objects
        - count: Number of tasks returned
        - filter: The status filter applied

    Example:
        >>> await list_tasks("user123", status="pending")
        {"tasks": [{"id": "1", "title": "Buy groceries", ...}], "count": 1, "filter": "pending"}
    """
    # TODO: Replace with actual database implementation
    # with Session(engine) as session:
    #     query = select(Task).where(Task.user_id == user_id)
    #
    #     if status == "pending":
    #         query = query.where(Task.completed == False)
    #     elif status == "completed":
    #         query = query.where(Task.completed == True)
    #
    #     tasks = session.exec(query).all()
    #     task_list = [
    #         {
    #             "id": str(task.id),
    #             "title": task.title,
    #             "description": task.description or "",
    #             "completed": task.completed,
    #         }
    #         for task in tasks
    #     ]
    #     return {
    #         "tasks": task_list,
    #         "count": len(task_list),
    #         "filter": status,
    #     }

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


@mcp.tool()
async def complete_task(
    user_id: str,
    task_id: str,
) -> dict[str, Any]:
    """Mark a task as complete.

    Updates the specified task to completed status. Only tasks
    belonging to the specified user can be completed.

    Args:
        user_id: The unique identifier of the user.
        task_id: The ID of the task to mark as complete.

    Returns:
        Dictionary containing:
        - task_id: The ID of the completed task
        - status: "completed" if successful, or error info
        - title: The title of the completed task

    Example:
        >>> await complete_task("user123", "5")
        {"task_id": "5", "status": "completed", "title": "Buy groceries"}
    """
    # TODO: Replace with actual database implementation
    # with Session(engine) as session:
    #     task = session.get(Task, task_id)
    #
    #     if not task or task.user_id != user_id:
    #         return {"error": "Task not found", "task_id": task_id}
    #
    #     task.completed = True
    #     session.add(task)
    #     session.commit()
    #     return {
    #         "task_id": str(task.id),
    #         "status": "completed",
    #         "title": task.title,
    #     }

    # Placeholder implementation
    return {
        "task_id": task_id,
        "status": "completed",
        "title": "Example Task",
    }


@mcp.tool()
async def delete_task(
    user_id: str,
    task_id: str,
) -> dict[str, Any]:
    """Delete a task from the list.

    Permanently removes the specified task. Only tasks belonging
    to the specified user can be deleted.

    Args:
        user_id: The unique identifier of the user.
        task_id: The ID of the task to delete.

    Returns:
        Dictionary containing:
        - task_id: The ID of the deleted task
        - status: "deleted" if successful, or error info
        - title: The title of the deleted task

    Example:
        >>> await delete_task("user123", "5")
        {"task_id": "5", "status": "deleted", "title": "Buy groceries"}
    """
    # TODO: Replace with actual database implementation
    # with Session(engine) as session:
    #     task = session.get(Task, task_id)
    #
    #     if not task or task.user_id != user_id:
    #         return {"error": "Task not found", "task_id": task_id}
    #
    #     title = task.title
    #     session.delete(task)
    #     session.commit()
    #     return {
    #         "task_id": task_id,
    #         "status": "deleted",
    #         "title": title,
    #     }

    # Placeholder implementation
    return {
        "task_id": task_id,
        "status": "deleted",
        "title": "Example Task",
    }


@mcp.tool()
async def update_task(
    user_id: str,
    task_id: str,
    title: str | None = None,
    description: str | None = None,
) -> dict[str, Any]:
    """Update a task's title or description.

    Modifies the specified task with new values. Only provided
    fields will be updated. Only tasks belonging to the specified
    user can be updated.

    Args:
        user_id: The unique identifier of the user.
        task_id: The ID of the task to update.
        title: New title for the task (optional).
        description: New description for the task (optional).

    Returns:
        Dictionary containing:
        - task_id: The ID of the updated task
        - status: "updated" if successful, or error info
        - title: The current title of the task

    Example:
        >>> await update_task("user123", "5", title="Buy groceries and fruits")
        {"task_id": "5", "status": "updated", "title": "Buy groceries and fruits"}
    """
    # TODO: Replace with actual database implementation
    # with Session(engine) as session:
    #     task = session.get(Task, task_id)
    #
    #     if not task or task.user_id != user_id:
    #         return {"error": "Task not found", "task_id": task_id}
    #
    #     if title is not None:
    #         task.title = title
    #     if description is not None:
    #         task.description = description
    #
    #     session.add(task)
    #     session.commit()
    #     return {
    #         "task_id": str(task.id),
    #         "status": "updated",
    #         "title": task.title,
    #     }

    # Placeholder implementation
    return {
        "task_id": task_id,
        "status": "updated",
        "title": title or "Example Task",
    }


# ============================================================================
# SERVER ENTRY POINT
# ============================================================================


def main():
    """Run the MCP server with HTTP transport.

    The server will listen on the specified port and expose all
    tools defined with @mcp.tool() decorator.

    Transport options:
    - "streamable-http": HTTP-based, use MCPServerStreamableHttp to connect
    - "sse": Server-Sent Events, use MCPServerSse to connect
    - "stdio": Standard I/O, use MCPServerStdio to connect
    """
    # Get port from environment or use default
    port = int(os.environ.get("MCP_SERVER_PORT", "8001"))

    print(f"Starting MCP Server on port {port}...")
    print("Available tools: add_task, list_tasks, complete_task, delete_task, update_task")

    # Run with HTTP transport (recommended for web applications)
    mcp.run(transport="streamable-http", port=port)


if __name__ == "__main__":
    main()
