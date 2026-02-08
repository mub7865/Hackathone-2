"""WebSocket connection manager for real-time task updates.

This module manages WebSocket connections, broadcasts events to connected clients,
and handles connection lifecycle (connect, disconnect, heartbeat).
"""

import asyncio
import json
import logging
from typing import Dict, Set
from uuid import uuid4

from fastapi import WebSocket, WebSocketDisconnect

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manages WebSocket connections for real-time updates.

    Maintains a registry of active connections per user and provides
    methods for broadcasting events to specific users or all users.
    """

    def __init__(self):
        """Initialize the connection manager."""
        # Map of user_id -> set of WebSocket connections
        self.active_connections: Dict[str, Set[WebSocket]] = {}
        # Map of connection_id -> user_id for cleanup
        self.connection_users: Dict[str, str] = {}

    async def connect(self, websocket: WebSocket, user_id: str) -> str:
        """Accept a new WebSocket connection.

        Args:
            websocket: The WebSocket connection to accept
            user_id: The authenticated user's ID

        Returns:
            Connection ID (UUID string)
        """
        await websocket.accept()
        connection_id = str(uuid4())

        # Add to user's connection set
        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()
        self.active_connections[user_id].add(websocket)

        # Track connection for cleanup
        self.connection_users[connection_id] = user_id

        logger.info(f"WebSocket connected: user={user_id}, connection={connection_id}")
        return connection_id

    def disconnect(self, websocket: WebSocket, connection_id: str):
        """Remove a WebSocket connection.

        Args:
            websocket: The WebSocket connection to remove
            connection_id: The connection ID from connect()
        """
        # Get user_id from connection_id
        user_id = self.connection_users.pop(connection_id, None)
        if user_id is None:
            logger.warning(f"Connection {connection_id} not found in registry")
            return

        # Remove from user's connection set
        if user_id in self.active_connections:
            self.active_connections[user_id].discard(websocket)
            # Clean up empty sets
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

        logger.info(f"WebSocket disconnected: user={user_id}, connection={connection_id}")

    async def send_personal_message(self, message: dict, user_id: str):
        """Send a message to all connections for a specific user.

        Args:
            message: The message dict to send (will be JSON serialized)
            user_id: The user ID to send to
        """
        if user_id not in self.active_connections:
            logger.debug(f"No active connections for user {user_id}")
            return

        # Get all connections for this user
        connections = list(self.active_connections[user_id])
        if not connections:
            return

        # Serialize message once
        message_json = json.dumps(message)

        # Send to all user's connections
        disconnected = []
        for connection in connections:
            try:
                await connection.send_text(message_json)
            except WebSocketDisconnect:
                disconnected.append(connection)
            except Exception as e:
                logger.error(f"Error sending message to {user_id}: {e}")
                disconnected.append(connection)

        # Clean up disconnected connections
        for connection in disconnected:
            self.active_connections[user_id].discard(connection)

    async def broadcast(self, message: dict):
        """Broadcast a message to all connected users.

        Args:
            message: The message dict to send (will be JSON serialized)
        """
        if not self.active_connections:
            return

        # Serialize message once
        message_json = json.dumps(message)

        # Send to all connections
        disconnected = []
        for user_id, connections in self.active_connections.items():
            for connection in list(connections):
                try:
                    await connection.send_text(message_json)
                except WebSocketDisconnect:
                    disconnected.append((user_id, connection))
                except Exception as e:
                    logger.error(f"Error broadcasting to {user_id}: {e}")
                    disconnected.append((user_id, connection))

        # Clean up disconnected connections
        for user_id, connection in disconnected:
            if user_id in self.active_connections:
                self.active_connections[user_id].discard(connection)

    async def send_task_event(self, event_type: str, task_data: dict, user_id: str):
        """Send a task event to a specific user.

        Args:
            event_type: The event type (created, updated, deleted, completed)
            task_data: The task data to send
            user_id: The user ID to send to
        """
        message = {
            "type": "task_event",
            "event": event_type,
            "data": task_data,
        }
        await self.send_personal_message(message, user_id)

    def get_connection_count(self, user_id: str | None = None) -> int:
        """Get the number of active connections.

        Args:
            user_id: Optional user ID to get count for specific user

        Returns:
            Number of active connections
        """
        if user_id is not None:
            return len(self.active_connections.get(user_id, set()))
        return sum(len(conns) for conns in self.active_connections.values())


# Global connection manager instance
manager = ConnectionManager()


def get_connection_manager() -> ConnectionManager:
    """Get the global connection manager instance.

    Returns:
        ConnectionManager instance
    """
    return manager
