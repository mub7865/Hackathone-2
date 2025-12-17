"""
MCP Tools Definition Template

PURPOSE:
- Define function tools for AI agent to call.
- Wrap existing CRUD operations as agent-callable tools.
- Provide proper type hints and docstrings for schema generation.

HOW TO USE:
- Copy this template to your project (e.g. app/chat/tools.py).
- Replace placeholder implementations with actual database operations.
- Ensure docstrings follow Google/Sphinx/NumPy format for parsing.

REFERENCES:
- https://openai.github.io/openai-agents-python/tools/
- https://github.com/modelcontextprotocol/python-sdk
"""

from typing import List, Optional
from agents import function_tool

# Import your database session and models
# from app.db import get_session
# from app.models import Task


@function_tool
async def add_task(
    user_id: str,
    title: str,
    description: str = "",
) -> dict:
    """Add a new task for the user.

    Creates a new task with the given title and optional description.
    The task is associated with the specified user.

    Args:
        user_id: The unique identifier of the user.
        title: The title of the task (required, 1-200 characters).
        description: Optional detailed description of the task.

    Returns:
        Dictionary containing:
        - task_id: The ID of the created task.
        - status: "created" if successful.
        - title: The title of the created task.

    Example:
        >>> await add_task("user123", "Buy groceries", "Milk, eggs, bread")
        {"task_id": 5, "status": "created", "title": "Buy groceries"}
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
        "task_id": 1,
        "status": "created",
        "title": title,
    }


@function_tool
async def list_tasks(
    user_id: str,
    status: str = "all",
) -> List[dict]:
    """List tasks for the user.

    Retrieves tasks belonging to the specified user, optionally
    filtered by completion status.

    Args:
        user_id: The unique identifier of the user.
        status: Filter by status - "all", "pending", or "completed".
                Defaults to "all".

    Returns:
        List of task dictionaries, each containing:
        - id: Task ID
        - title: Task title
        - description: Task description (may be empty)
        - completed: Boolean completion status
        - created_at: Creation timestamp

    Example:
        >>> await list_tasks("user123", status="pending")
        [{"id": 1, "title": "Buy groceries", "completed": False, ...}]
    """
    # TODO: Replace with actual database implementation
    # async with get_session() as session:
    #     query = select(Task).where(Task.user_id == user_id)
    #     if status == "pending":
    #         query = query.where(Task.completed == False)
    #     elif status == "completed":
    #         query = query.where(Task.completed == True)
    #     result = await session.exec(query)
    #     tasks = result.all()
    #     return [task.dict() for task in tasks]

    # Placeholder implementation
    return [
        {
            "id": 1,
            "title": "Example Task",
            "description": "",
            "completed": False,
            "created_at": "2025-01-01T00:00:00Z",
        }
    ]


@function_tool
async def complete_task(
    user_id: str,
    task_id: int,
) -> dict:
    """Mark a task as complete.

    Updates the specified task to completed status. Only tasks
    belonging to the specified user can be completed.

    Args:
        user_id: The unique identifier of the user.
        task_id: The ID of the task to mark as complete.

    Returns:
        Dictionary containing:
        - task_id: The ID of the completed task.
        - status: "completed" if successful, "error" if task not found.
        - title: The title of the completed task.
        - error: Error message if task not found.

    Example:
        >>> await complete_task("user123", 5)
        {"task_id": 5, "status": "completed", "title": "Buy groceries"}
    """
    # TODO: Replace with actual database implementation
    # async with get_session() as session:
    #     task = await session.get(Task, task_id)
    #     if not task or task.user_id != user_id:
    #         return {"task_id": task_id, "status": "error", "error": "Task not found"}
    #     task.completed = True
    #     session.add(task)
    #     await session.commit()
    #     return {"task_id": task.id, "status": "completed", "title": task.title}

    # Placeholder implementation
    return {
        "task_id": task_id,
        "status": "completed",
        "title": "Example Task",
    }


@function_tool
async def delete_task(
    user_id: str,
    task_id: int,
) -> dict:
    """Delete a task from the list.

    Permanently removes the specified task. Only tasks belonging
    to the specified user can be deleted.

    Args:
        user_id: The unique identifier of the user.
        task_id: The ID of the task to delete.

    Returns:
        Dictionary containing:
        - task_id: The ID of the deleted task.
        - status: "deleted" if successful, "error" if task not found.
        - title: The title of the deleted task.
        - error: Error message if task not found.

    Example:
        >>> await delete_task("user123", 5)
        {"task_id": 5, "status": "deleted", "title": "Buy groceries"}
    """
    # TODO: Replace with actual database implementation
    # async with get_session() as session:
    #     task = await session.get(Task, task_id)
    #     if not task or task.user_id != user_id:
    #         return {"task_id": task_id, "status": "error", "error": "Task not found"}
    #     title = task.title
    #     await session.delete(task)
    #     await session.commit()
    #     return {"task_id": task_id, "status": "deleted", "title": title}

    # Placeholder implementation
    return {
        "task_id": task_id,
        "status": "deleted",
        "title": "Example Task",
    }


@function_tool
async def update_task(
    user_id: str,
    task_id: int,
    title: Optional[str] = None,
    description: Optional[str] = None,
) -> dict:
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
        - task_id: The ID of the updated task.
        - status: "updated" if successful, "error" if task not found.
        - title: The current title of the task.
        - error: Error message if task not found.

    Example:
        >>> await update_task("user123", 5, title="Buy groceries and fruits")
        {"task_id": 5, "status": "updated", "title": "Buy groceries and fruits"}
    """
    # TODO: Replace with actual database implementation
    # async with get_session() as session:
    #     task = await session.get(Task, task_id)
    #     if not task or task.user_id != user_id:
    #         return {"task_id": task_id, "status": "error", "error": "Task not found"}
    #     if title is not None:
    #         task.title = title
    #     if description is not None:
    #         task.description = description
    #     session.add(task)
    #     await session.commit()
    #     return {"task_id": task.id, "status": "updated", "title": task.title}

    # Placeholder implementation
    return {
        "task_id": task_id,
        "status": "updated",
        "title": title or "Example Task",
    }
