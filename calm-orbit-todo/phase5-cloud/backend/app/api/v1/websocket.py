"""WebSocket API endpoints for real-time task updates.

This module provides WebSocket endpoints for clients to receive
real-time updates about task changes.
"""

import asyncio
import logging
from typing import Optional

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, status
from jose import JWTError, jwt

from app.core.config import get_settings
from app.websocket.manager import get_connection_manager

logger = logging.getLogger(__name__)
router = APIRouter()

settings = get_settings()


async def get_user_from_token(token: str) -> Optional[str]:
    """Extract user ID from JWT token.

    Args:
        token: JWT token string

    Returns:
        User ID if valid, None otherwise
    """
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm]
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            return None
        return user_id
    except JWTError:
        return None


@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(..., description="JWT authentication token"),
):
    """WebSocket endpoint for real-time task updates.

    Clients connect with a JWT token in the query string and receive
    real-time updates about their tasks.

    Args:
        websocket: The WebSocket connection
        token: JWT authentication token from query parameter

    Message Format:
        {
            "type": "task_event",
            "event": "created" | "updated" | "deleted" | "completed",
            "data": {
                "id": "task-uuid",
                "title": "Task title",
                ...
            }
        }

    Heartbeat:
        Server sends {"type": "ping"} every 30 seconds
        Client should respond with {"type": "pong"}
    """
    # Authenticate user
    user_id = await get_user_from_token(token)
    if user_id is None:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    # Connect to manager
    manager = get_connection_manager()
    connection_id = await manager.connect(websocket, user_id)

    try:
        # Send welcome message
        await websocket.send_json({
            "type": "connected",
            "message": "WebSocket connection established",
            "connection_id": connection_id,
        })

        # Start heartbeat task
        heartbeat_task = asyncio.create_task(
            send_heartbeat(websocket, connection_id)
        )

        # Listen for messages (mainly for pong responses)
        while True:
            try:
                data = await websocket.receive_json()

                # Handle pong responses
                if data.get("type") == "pong":
                    logger.debug(f"Received pong from {user_id}")
                    continue

                # Handle other message types if needed
                logger.debug(f"Received message from {user_id}: {data}")

            except WebSocketDisconnect:
                logger.info(f"Client {user_id} disconnected")
                break
            except Exception as e:
                logger.error(f"Error receiving message from {user_id}: {e}")
                break

    except Exception as e:
        logger.error(f"WebSocket error for {user_id}: {e}")
    finally:
        # Cancel heartbeat task
        if 'heartbeat_task' in locals():
            heartbeat_task.cancel()
            try:
                await heartbeat_task
            except asyncio.CancelledError:
                pass

        # Disconnect from manager
        manager.disconnect(websocket, connection_id)


async def send_heartbeat(websocket: WebSocket, connection_id: str):
    """Send periodic heartbeat messages to keep connection alive.

    Args:
        websocket: The WebSocket connection
        connection_id: The connection ID for logging
    """
    try:
        while True:
            await asyncio.sleep(30)  # Send ping every 30 seconds
            try:
                await websocket.send_json({"type": "ping"})
                logger.debug(f"Sent ping to connection {connection_id}")
            except Exception as e:
                logger.error(f"Error sending heartbeat to {connection_id}: {e}")
                break
    except asyncio.CancelledError:
        logger.debug(f"Heartbeat cancelled for {connection_id}")


@router.get("/ws/stats")
async def get_websocket_stats():
    """Get WebSocket connection statistics.

    Returns:
        Dict with connection statistics
    """
    manager = get_connection_manager()
    return {
        "total_connections": manager.get_connection_count(),
        "active_users": len(manager.active_connections),
    }
