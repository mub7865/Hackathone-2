"""Event broadcaster for WebSocket real-time updates.

This module integrates with the event publishing system to broadcast
task events to connected WebSocket clients.
"""

import logging
from typing import Any, Dict

from app.websocket.manager import get_connection_manager

logger = logging.getLogger(__name__)


async def broadcast_task_event(
    event_type: str,
    task_id: str,
    user_id: str,
    task_data: Dict[str, Any] | None = None,
):
    """Broadcast a task event to WebSocket clients.

    This function is called by the event publishing system to send
    real-time updates to connected clients.

    Args:
        event_type: The event type (created, updated, deleted, completed)
        task_id: The task ID
        user_id: The user ID who owns the task
        task_data: Optional task data to include in the event
    """
    manager = get_connection_manager()

    # Build event message
    message = {
        "type": "task_event",
        "event": event_type,
        "task_id": task_id,
        "data": task_data or {},
    }

    # Send to user's connections
    try:
        await manager.send_personal_message(message, user_id)
        logger.debug(f"Broadcasted {event_type} event for task {task_id} to user {user_id}")
    except Exception as e:
        logger.error(f"Error broadcasting task event: {e}")


async def broadcast_reminder_event(
    task_id: str,
    user_id: str,
    task_data: Dict[str, Any],
):
    """Broadcast a reminder event to WebSocket clients.

    Args:
        task_id: The task ID
        user_id: The user ID who owns the task
        task_data: Task data to include in the event
    """
    manager = get_connection_manager()

    # Build reminder message
    message = {
        "type": "reminder",
        "task_id": task_id,
        "data": task_data,
    }

    # Send to user's connections
    try:
        await manager.send_personal_message(message, user_id)
        logger.debug(f"Broadcasted reminder for task {task_id} to user {user_id}")
    except Exception as e:
        logger.error(f"Error broadcasting reminder: {e}")


async def broadcast_system_message(
    message: str,
    user_id: str | None = None,
):
    """Broadcast a system message to WebSocket clients.

    Args:
        message: The system message to broadcast
        user_id: Optional user ID to send to specific user, None for all users
    """
    manager = get_connection_manager()

    # Build system message
    msg = {
        "type": "system",
        "message": message,
    }

    # Send to user or broadcast to all
    try:
        if user_id:
            await manager.send_personal_message(msg, user_id)
        else:
            await manager.broadcast(msg)
        logger.debug(f"Broadcasted system message: {message}")
    except Exception as e:
        logger.error(f"Error broadcasting system message: {e}")
