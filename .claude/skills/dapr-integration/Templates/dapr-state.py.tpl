"""
Dapr State Management Template

This template provides state management operations using Dapr state stores
with proper error handling, transactions, and TTL support.
"""

from dapr.clients import DaprClient
from dapr.clients.grpc._state import StateItem, StateOptions, Consistency, Concurrency
from typing import Optional, Dict, Any, List
from pydantic import BaseModel
from datetime import datetime, timedelta
import logging
import json

logger = logging.getLogger(__name__)

# Configuration
STATE_STORE_NAME = "statestore"  # Name of your state store component


# ============================================================================
# State Models
# ============================================================================

class StateMetadata(BaseModel):
    """Metadata for state operations."""
    ttl_in_seconds: Optional[int] = None
    content_type: str = "application/json"


class StateEntry(BaseModel):
    """State entry with key, value, and metadata."""
    key: str
    value: Dict[str, Any]
    etag: Optional[str] = None
    metadata: Optional[StateMetadata] = None


# ============================================================================
# State Manager
# ============================================================================

class DaprStateManager:
    """Manager for Dapr state store operations."""

    def __init__(self, store_name: str = STATE_STORE_NAME):
        self.store_name = store_name

    # ========================================================================
    # Basic CRUD Operations
    # ========================================================================

    def save(
        self,
        key: str,
        value: Dict[str, Any],
        ttl_seconds: Optional[int] = None,
        etag: Optional[str] = None
    ) -> bool:
        """
        Save state to Dapr state store.

        Args:
            key: State key
            value: State value (dict)
            ttl_seconds: Time-to-live in seconds (optional)
            etag: ETag for optimistic concurrency (optional)

        Returns:
            True if saved successfully
        """
        try:
            with DaprClient() as client:
                # Prepare metadata
                metadata = {}
                if ttl_seconds:
                    metadata["ttlInSeconds"] = str(ttl_seconds)

                # Save state
                client.save_state(
                    store_name=self.store_name,
                    key=key,
                    value=json.dumps(value),
                    etag=etag,
                    state_metadata=metadata
                )

                logger.info(f"Saved state: {key}")
                return True

        except Exception as e:
            logger.error(f"Failed to save state {key}: {e}", exc_info=True)
            return False

    def get(self, key: str) -> Optional[Dict[str, Any]]:
        """
        Get state from Dapr state store.

        Args:
            key: State key

        Returns:
            State value as dict, or None if not found
        """
        try:
            with DaprClient() as client:
                state = client.get_state(
                    store_name=self.store_name,
                    key=key
                )

                if state.data:
                    return json.loads(state.data)
                return None

        except Exception as e:
            logger.error(f"Failed to get state {key}: {e}", exc_info=True)
            return None

    def get_with_etag(self, key: str) -> Optional[tuple[Dict[str, Any], str]]:
        """
        Get state with ETag for optimistic concurrency.

        Args:
            key: State key

        Returns:
            Tuple of (value, etag) or None if not found
        """
        try:
            with DaprClient() as client:
                state = client.get_state(
                    store_name=self.store_name,
                    key=key
                )

                if state.data:
                    value = json.loads(state.data)
                    return (value, state.etag)
                return None

        except Exception as e:
            logger.error(f"Failed to get state with etag {key}: {e}", exc_info=True)
            return None

    def delete(self, key: str, etag: Optional[str] = None) -> bool:
        """
        Delete state from Dapr state store.

        Args:
            key: State key
            etag: ETag for optimistic concurrency (optional)

        Returns:
            True if deleted successfully
        """
        try:
            with DaprClient() as client:
                client.delete_state(
                    store_name=self.store_name,
                    key=key,
                    etag=etag
                )

                logger.info(f"Deleted state: {key}")
                return True

        except Exception as e:
            logger.error(f"Failed to delete state {key}: {e}", exc_info=True)
            return False

    # ========================================================================
    # Bulk Operations
    # ========================================================================

    def save_bulk(self, states: List[StateEntry]) -> bool:
        """
        Save multiple states in a single operation.

        Args:
            states: List of state entries to save

        Returns:
            True if all saved successfully
        """
        try:
            with DaprClient() as client:
                # Prepare state items
                state_items = []
                for state in states:
                    metadata = {}
                    if state.metadata and state.metadata.ttl_in_seconds:
                        metadata["ttlInSeconds"] = str(state.metadata.ttl_in_seconds)

                    state_items.append(
                        StateItem(
                            key=state.key,
                            value=json.dumps(state.value),
                            etag=state.etag,
                            metadata=metadata
                        )
                    )

                # Save bulk
                client.save_bulk_state(
                    store_name=self.store_name,
                    states=state_items
                )

                logger.info(f"Saved {len(states)} states in bulk")
                return True

        except Exception as e:
            logger.error(f"Failed to save bulk states: {e}", exc_info=True)
            return False

    def get_bulk(self, keys: List[str]) -> Dict[str, Dict[str, Any]]:
        """
        Get multiple states in a single operation.

        Args:
            keys: List of state keys

        Returns:
            Dictionary mapping keys to values
        """
        try:
            with DaprClient() as client:
                states = client.get_bulk_state(
                    store_name=self.store_name,
                    keys=keys
                )

                result = {}
                for item in states.items:
                    if item.data:
                        result[item.key] = json.loads(item.data)

                logger.info(f"Retrieved {len(result)} states in bulk")
                return result

        except Exception as e:
            logger.error(f"Failed to get bulk states: {e}", exc_info=True)
            return {}

    def delete_bulk(self, keys: List[str]) -> bool:
        """
        Delete multiple states in a single operation.

        Args:
            keys: List of state keys to delete

        Returns:
            True if all deleted successfully
        """
        try:
            with DaprClient() as client:
                state_items = [
                    StateItem(key=key, value="")
                    for key in keys
                ]

                client.delete_bulk_state(
                    store_name=self.store_name,
                    states=state_items
                )

                logger.info(f"Deleted {len(keys)} states in bulk")
                return True

        except Exception as e:
            logger.error(f"Failed to delete bulk states: {e}", exc_info=True)
            return False

    # ========================================================================
    # Transactions
    # ========================================================================

    def execute_transaction(
        self,
        operations: List[Dict[str, Any]]
    ) -> bool:
        """
        Execute multiple state operations as a transaction.

        Args:
            operations: List of operations, each with:
                - operation: "upsert" or "delete"
                - request: StateItem for the operation

        Returns:
            True if transaction succeeded

        Example:
            operations = [
                {
                    "operation": "upsert",
                    "request": StateItem(key="key1", value="value1")
                },
                {
                    "operation": "delete",
                    "request": StateItem(key="key2")
                }
            ]
        """
        try:
            with DaprClient() as client:
                client.execute_state_transaction(
                    store_name=self.store_name,
                    operations=operations
                )

                logger.info(f"Executed transaction with {len(operations)} operations")
                return True

        except Exception as e:
            logger.error(f"Failed to execute transaction: {e}", exc_info=True)
            return False

    # ========================================================================
    # Helper Methods
    # ========================================================================

    def increment_counter(self, key: str, increment: int = 1) -> Optional[int]:
        """
        Atomically increment a counter using optimistic concurrency.

        Args:
            key: Counter key
            increment: Amount to increment by

        Returns:
            New counter value, or None if failed
        """
        max_retries = 5
        for attempt in range(max_retries):
            try:
                # Get current value with etag
                result = self.get_with_etag(key)

                if result:
                    current_value, etag = result
                    new_value = current_value.get("count", 0) + increment
                else:
                    # Counter doesn't exist, create it
                    new_value = increment
                    etag = None

                # Save with etag
                success = self.save(
                    key=key,
                    value={"count": new_value},
                    etag=etag
                )

                if success:
                    return new_value

            except Exception as e:
                if attempt == max_retries - 1:
                    logger.error(f"Failed to increment counter {key}: {e}")
                    return None
                # Retry on conflict
                continue

        return None

    def set_with_ttl(
        self,
        key: str,
        value: Dict[str, Any],
        ttl_seconds: int
    ) -> bool:
        """
        Set state with automatic expiration.

        Args:
            key: State key
            value: State value
            ttl_seconds: Time-to-live in seconds

        Returns:
            True if saved successfully
        """
        return self.save(key, value, ttl_seconds=ttl_seconds)

    def exists(self, key: str) -> bool:
        """
        Check if a state key exists.

        Args:
            key: State key

        Returns:
            True if key exists
        """
        return self.get(key) is not None


# ============================================================================
# Common Use Cases
# ============================================================================

class SessionManager(DaprStateManager):
    """Session management using Dapr state store."""

    def save_session(
        self,
        session_id: str,
        user_id: str,
        data: Dict[str, Any],
        ttl_seconds: int = 3600
    ) -> bool:
        """Save user session with TTL."""
        session_data = {
            "user_id": user_id,
            "created_at": datetime.utcnow().isoformat(),
            "data": data
        }
        return self.save(
            key=f"session:{session_id}",
            value=session_data,
            ttl_seconds=ttl_seconds
        )

    def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get user session."""
        return self.get(key=f"session:{session_id}")

    def delete_session(self, session_id: str) -> bool:
        """Delete user session."""
        return self.delete(key=f"session:{session_id}")


class CacheManager(DaprStateManager):
    """Cache management using Dapr state store."""

    def cache_set(
        self,
        key: str,
        value: Any,
        ttl_seconds: int = 300
    ) -> bool:
        """Set cache value with TTL."""
        cache_data = {
            "value": value,
            "cached_at": datetime.utcnow().isoformat()
        }
        return self.save(
            key=f"cache:{key}",
            value=cache_data,
            ttl_seconds=ttl_seconds
        )

    def cache_get(self, key: str) -> Optional[Any]:
        """Get cached value."""
        data = self.get(key=f"cache:{key}")
        return data.get("value") if data else None

    def cache_delete(self, key: str) -> bool:
        """Delete cached value."""
        return self.delete(key=f"cache:{key}")


# ============================================================================
# Usage Example
# ============================================================================

if __name__ == "__main__":
    # Basic usage
    state_manager = DaprStateManager()

    # Save state
    state_manager.save("user:123", {"name": "John", "email": "john@example.com"})

    # Get state
    user = state_manager.get("user:123")
    print(f"User: {user}")

    # Save with TTL
    state_manager.set_with_ttl(
        "temp:data",
        {"value": "temporary"},
        ttl_seconds=60
    )

    # Increment counter
    new_count = state_manager.increment_counter("page:views")
    print(f"Page views: {new_count}")

    # Session management
    session_mgr = SessionManager()
    session_mgr.save_session(
        session_id="abc123",
        user_id="user_456",
        data={"preferences": {"theme": "dark"}},
        ttl_seconds=3600
    )
