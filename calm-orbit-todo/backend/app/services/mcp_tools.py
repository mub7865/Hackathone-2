"""MCP Tools for AI Chatbot Phase III.

This module defines function tools that the AI agent can use to manage
user tasks through natural language commands.

Each tool is decorated with @function_tool from the OpenAI Agents SDK.
"""

from typing import Any
from uuid import UUID

from agents import function_tool
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.models.task import Task, TaskStatus


# We'll store a reference to the current session for tools to use
# This is set by the chat endpoint before running the agent
_current_session: AsyncSession | None = None
_current_user_id: str | None = None


def set_context(session: AsyncSession, user_id: str) -> None:
    """Set the database session and user context for MCP tools.

    This should be called before running the agent to provide
    database access to the tools.

    Args:
        session: Async database session.
        user_id: The authenticated user's ID.
    """
    global _current_session, _current_user_id
    _current_session = session
    _current_user_id = user_id


def clear_context() -> None:
    """Clear the database session and user context after agent run."""
    global _current_session, _current_user_id
    _current_session = None
    _current_user_id = None


def _get_context() -> tuple[AsyncSession, str]:
    """Get the current database session and user ID.

    Returns:
        Tuple of (session, user_id).

    Raises:
        RuntimeError: If context not set.
    """
    if _current_session is None or _current_user_id is None:
        raise RuntimeError("MCP tools context not set. Call set_context first.")
    return _current_session, _current_user_id


@function_tool
async def add_task(title: str, description: str = "") -> dict[str, Any]:
    """Add a new task for the user.

    Use this tool when the user wants to create a new task, add something
    to their todo list, or remember to do something.

    Args:
        title: The task title (required, 1-255 characters).
        description: Optional task description for more details.

    Returns:
        Dictionary with task_id, status, and title on success.
        Dictionary with error message on failure.

    Examples:
        - "Add a task to buy groceries" -> add_task(title="Buy groceries")
        - "Remember to call mom" -> add_task(title="Call mom")
        - "I need to finish the report by Friday" -> add_task(title="Finish the report by Friday")
    """
    session, user_id = _get_context()

    if not title or not title.strip():
        return {"error": "Failed to create task", "details": "Title is required"}

    title = title.strip()
    if len(title) > 255:
        title = title[:255]

    try:
        task = Task(
            user_id=user_id,
            title=title,
            description=description.strip() if description else None,
            status=TaskStatus.PENDING,
        )
        session.add(task)
        await session.flush()
        await session.refresh(task)

        return {
            "task_id": str(task.id),
            "status": "created",
            "title": task.title,
        }
    except Exception as e:
        return {"error": "Failed to create task", "details": str(e)}


@function_tool
async def list_tasks(status: str = "all") -> dict[str, Any]:
    """Retrieve the user's tasks with optional status filter.

    Use this tool when the user wants to see their tasks, check what's
    pending, or review completed items.

    Args:
        status: Filter by status - "all", "pending", or "completed".
                Default is "all" to show all tasks.

    Returns:
        Dictionary with tasks list, count, and filter applied.

    Examples:
        - "Show my tasks" -> list_tasks(status="all")
        - "What's pending?" -> list_tasks(status="pending")
        - "What have I completed?" -> list_tasks(status="completed")
        - "What do I have to do?" -> list_tasks(status="pending")
    """
    session, user_id = _get_context()

    try:
        # Build query based on status filter
        if status == "pending":
            tasks = await Task.get_by_user_and_status(
                session, user_id, TaskStatus.PENDING
            )
        elif status == "completed":
            tasks = await Task.get_by_user_and_status(
                session, user_id, TaskStatus.COMPLETED
            )
        else:
            tasks = await Task.get_by_user(session, user_id)

        task_list = [
            {
                "id": str(task.id),
                "title": task.title,
                "description": task.description or "",
                "completed": task.status == TaskStatus.COMPLETED,
                "created_at": task.created_at.isoformat() if task.created_at else None,
            }
            for task in tasks
        ]

        return {
            "tasks": task_list,
            "count": len(task_list),
            "filter": status,
        }
    except Exception as e:
        return {"error": "Failed to list tasks", "details": str(e)}


@function_tool
async def complete_task(task_id: str) -> dict[str, Any]:
    """Mark a task as completed.

    Use this tool when the user wants to mark a task as done, complete
    a task, or indicate they've finished something.

    Args:
        task_id: The task ID to complete (UUID string).

    Returns:
        Dictionary with task_id, status, and title on success.
        Dictionary with error message if task not found.

    Examples:
        - "Mark task abc123 as done" -> complete_task(task_id="abc123")
        - "I finished task xyz789" -> complete_task(task_id="xyz789")
        - "Complete task 1" -> complete_task(task_id="1")
    """
    session, user_id = _get_context()

    try:
        task_uuid = UUID(task_id)
    except (ValueError, TypeError):
        return {"error": "Task not found", "task_id": task_id}

    try:
        updated = await Task.update_task(
            session,
            task_id=task_uuid,
            user_id=user_id,
            updates={"status": TaskStatus.COMPLETED},
        )

        if updated is None:
            return {"error": "Task not found", "task_id": task_id}

        return {
            "task_id": str(updated.id),
            "status": "completed",
            "title": updated.title,
        }
    except Exception as e:
        return {"error": "Failed to complete task", "details": str(e)}


@function_tool
async def delete_task(task_id: str) -> dict[str, Any]:
    """Delete a task from the list.

    Use this tool when the user wants to remove a task, delete something
    from their list, or cancel a task.

    Args:
        task_id: The task ID to delete (UUID string).

    Returns:
        Dictionary with task_id and status on success.
        Dictionary with error message if task not found.

    Examples:
        - "Delete task abc123" -> delete_task(task_id="abc123")
        - "Remove task xyz789" -> delete_task(task_id="xyz789")
        - "Cancel task 1" -> delete_task(task_id="1")
    """
    session, user_id = _get_context()

    try:
        task_uuid = UUID(task_id)
    except (ValueError, TypeError):
        return {"error": "Task not found", "task_id": task_id}

    try:
        # First get the task to return its title
        statement = select(Task).where(
            Task.id == task_uuid, Task.user_id == user_id
        )
        result = await session.execute(statement)
        task = result.scalar_one_or_none()

        if task is None:
            return {"error": "Task not found", "task_id": task_id}

        task_title = task.title

        deleted = await Task.delete_task(session, task_uuid, user_id)

        if not deleted:
            return {"error": "Task not found", "task_id": task_id}

        return {
            "task_id": task_id,
            "status": "deleted",
            "title": task_title,
        }
    except Exception as e:
        return {"error": "Failed to delete task", "details": str(e)}


@function_tool
async def update_task(
    task_id: str,
    title: str | None = None,
    description: str | None = None,
) -> dict[str, Any]:
    """Update an existing task's title or description.

    Use this tool when the user wants to change a task's name, update
    details, or modify task information.

    Args:
        task_id: The task ID to update (UUID string).
        title: New title (optional, if changing).
        description: New description (optional, if changing).

    Returns:
        Dictionary with task_id, status, title, and changes on success.
        Dictionary with error message if task not found.

    Examples:
        - "Change task abc123 to Buy fruits" -> update_task(task_id="abc123", title="Buy fruits")
        - "Update task xyz789 description to Include deadline" -> update_task(task_id="xyz789", description="Include deadline")
        - "Rename task 1 to New title" -> update_task(task_id="1", title="New title")
    """
    session, user_id = _get_context()

    if title is None and description is None:
        return {"error": "No updates provided", "details": "Specify title or description to update"}

    try:
        task_uuid = UUID(task_id)
    except (ValueError, TypeError):
        return {"error": "Task not found", "task_id": task_id}

    try:
        updates: dict[str, Any] = {}
        changes: list[str] = []

        if title is not None:
            title = title.strip()
            if title:
                updates["title"] = title[:255] if len(title) > 255 else title
                changes.append("title")

        if description is not None:
            updates["description"] = description.strip() if description else None
            changes.append("description")

        if not updates:
            return {"error": "No valid updates provided"}

        updated = await Task.update_task(
            session,
            task_id=task_uuid,
            user_id=user_id,
            updates=updates,
        )

        if updated is None:
            return {"error": "Task not found", "task_id": task_id}

        return {
            "task_id": str(updated.id),
            "status": "updated",
            "title": updated.title,
            "changes": changes,
        }
    except Exception as e:
        return {"error": "Failed to update task", "details": str(e)}
