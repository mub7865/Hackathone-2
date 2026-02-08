"""Dapr client for distributed application runtime integration.

This module provides a Dapr client for interacting with Dapr building blocks:
- Pub/Sub: Publish events to Kafka via Dapr
- State Management: Store/retrieve state in PostgreSQL via Dapr
- Service Invocation: Call other microservices via Dapr
- Bindings: Input/output bindings for external systems
"""

import json
import logging
from typing import Any, Dict, Optional

import httpx
from dapr.clients import DaprClient as DaprGrpcClient
from dapr.clients.grpc._response import StateResponse

from app.config import get_settings

logger = logging.getLogger(__name__)


class DaprClient:
    """Dapr client for interacting with Dapr sidecar.

    This class provides methods to interact with Dapr building blocks
    using both HTTP and gRPC protocols.

    Attributes:
        settings: Application settings with Dapr configuration.
        http_client: HTTP client for Dapr HTTP API.
        grpc_client: gRPC client for Dapr gRPC API.
    """

    def __init__(self) -> None:
        """Initialize the Dapr client."""
        self.settings = get_settings()
        self.dapr_http_endpoint = f"http://localhost:{self.settings.dapr_http_port}"
        self.dapr_grpc_port = self.settings.dapr_grpc_port
        self.http_client: Optional[httpx.AsyncClient] = None
        self.grpc_client: Optional[DaprGrpcClient] = None

    async def start(self) -> None:
        """Start the Dapr client connections."""
        try:
            # Initialize HTTP client
            self.http_client = httpx.AsyncClient(
                base_url=self.dapr_http_endpoint,
                timeout=30.0,
            )

            # Initialize gRPC client
            self.grpc_client = DaprGrpcClient(
                address=f"localhost:{self.dapr_grpc_port}"
            )

            logger.info(
                f"Dapr client started: HTTP={self.dapr_http_endpoint}, gRPC={self.dapr_grpc_port}"
            )
        except Exception as e:
            logger.error(f"Failed to start Dapr client: {e}")
            raise

    async def stop(self) -> None:
        """Stop the Dapr client connections."""
        if self.http_client:
            await self.http_client.aclose()
        if self.grpc_client:
            self.grpc_client.close()
        logger.info("Dapr client stopped")

    # -------------------------------------------------------------------------
    # Pub/Sub Operations
    # -------------------------------------------------------------------------

    async def publish_event(
        self,
        pubsub_name: str,
        topic: str,
        data: Dict[str, Any],
        metadata: Optional[Dict[str, str]] = None,
    ) -> None:
        """Publish an event to a pub/sub topic via Dapr.

        Args:
            pubsub_name: Name of the pub/sub component (e.g., 'pubsub-kafka').
            topic: Topic name to publish to.
            data: Event data to publish.
            metadata: Optional metadata for the event.

        Raises:
            RuntimeError: If HTTP client is not started.
            httpx.HTTPError: If publishing fails.
        """
        if not self.http_client:
            raise RuntimeError("Dapr client not started. Call start() first.")

        url = f"/v1.0/publish/{pubsub_name}/{topic}"

        try:
            response = await self.http_client.post(
                url,
                json=data,
                headers={"Content-Type": "application/json"},
            )
            response.raise_for_status()
            logger.info(f"Published event to {pubsub_name}/{topic}")
        except httpx.HTTPError as e:
            logger.error(f"Failed to publish event to {pubsub_name}/{topic}: {e}")
            raise

    async def publish_task_event(
        self,
        topic: str,
        event_type: str,
        payload: Dict[str, Any],
    ) -> None:
        """Publish a task event via Dapr pub/sub.

        Args:
            topic: Kafka topic name.
            event_type: Event type (e.g., 'task.created').
            payload: Event payload data.
        """
        from datetime import datetime
        from uuid import uuid4

        event = {
            "event_id": str(uuid4()),
            "event_type": event_type,
            "timestamp": datetime.utcnow().isoformat(),
            "schema_version": "1.0",
            "payload": payload,
        }

        await self.publish_event(
            pubsub_name=self.settings.dapr_pubsub_name,
            topic=topic,
            data=event,
        )

    # -------------------------------------------------------------------------
    # State Management Operations
    # -------------------------------------------------------------------------

    async def save_state(
        self,
        store_name: str,
        key: str,
        value: Any,
        metadata: Optional[Dict[str, str]] = None,
    ) -> None:
        """Save state to a Dapr state store.

        Args:
            store_name: Name of the state store component (e.g., 'state-postgresql').
            key: State key.
            value: State value (will be JSON serialized).
            metadata: Optional metadata for the state.

        Raises:
            RuntimeError: If HTTP client is not started.
            httpx.HTTPError: If saving fails.
        """
        if not self.http_client:
            raise RuntimeError("Dapr client not started. Call start() first.")

        url = f"/v1.0/state/{store_name}"

        state_data = [
            {
                "key": key,
                "value": value,
                "metadata": metadata or {},
            }
        ]

        try:
            response = await self.http_client.post(
                url,
                json=state_data,
                headers={"Content-Type": "application/json"},
            )
            response.raise_for_status()
            logger.debug(f"Saved state: {store_name}/{key}")
        except httpx.HTTPError as e:
            logger.error(f"Failed to save state {store_name}/{key}: {e}")
            raise

    async def get_state(
        self,
        store_name: str,
        key: str,
    ) -> Optional[Any]:
        """Get state from a Dapr state store.

        Args:
            store_name: Name of the state store component.
            key: State key.

        Returns:
            State value if found, None otherwise.

        Raises:
            RuntimeError: If HTTP client is not started.
            httpx.HTTPError: If retrieval fails.
        """
        if not self.http_client:
            raise RuntimeError("Dapr client not started. Call start() first.")

        url = f"/v1.0/state/{store_name}/{key}"

        try:
            response = await self.http_client.get(url)
            response.raise_for_status()

            if response.status_code == 204:  # No content
                return None

            return response.json()
        except httpx.HTTPError as e:
            logger.error(f"Failed to get state {store_name}/{key}: {e}")
            raise

    async def delete_state(
        self,
        store_name: str,
        key: str,
    ) -> None:
        """Delete state from a Dapr state store.

        Args:
            store_name: Name of the state store component.
            key: State key.

        Raises:
            RuntimeError: If HTTP client is not started.
            httpx.HTTPError: If deletion fails.
        """
        if not self.http_client:
            raise RuntimeError("Dapr client not started. Call start() first.")

        url = f"/v1.0/state/{store_name}/{key}"

        try:
            response = await self.http_client.delete(url)
            response.raise_for_status()
            logger.debug(f"Deleted state: {store_name}/{key}")
        except httpx.HTTPError as e:
            logger.error(f"Failed to delete state {store_name}/{key}: {e}")
            raise

    # -------------------------------------------------------------------------
    # Service Invocation Operations
    # -------------------------------------------------------------------------

    async def invoke_service(
        self,
        app_id: str,
        method: str,
        data: Optional[Dict[str, Any]] = None,
        http_verb: str = "POST",
    ) -> Any:
        """Invoke a method on another service via Dapr service invocation.

        Args:
            app_id: Application ID of the target service.
            method: Method name to invoke.
            data: Optional request data.
            http_verb: HTTP verb (GET, POST, PUT, DELETE).

        Returns:
            Response data from the invoked service.

        Raises:
            RuntimeError: If HTTP client is not started.
            httpx.HTTPError: If invocation fails.
        """
        if not self.http_client:
            raise RuntimeError("Dapr client not started. Call start() first.")

        url = f"/v1.0/invoke/{app_id}/method/{method}"

        try:
            if http_verb.upper() == "GET":
                response = await self.http_client.get(url)
            elif http_verb.upper() == "POST":
                response = await self.http_client.post(url, json=data)
            elif http_verb.upper() == "PUT":
                response = await self.http_client.put(url, json=data)
            elif http_verb.upper() == "DELETE":
                response = await self.http_client.delete(url)
            else:
                raise ValueError(f"Unsupported HTTP verb: {http_verb}")

            response.raise_for_status()
            logger.info(f"Invoked service: {app_id}/{method}")

            if response.status_code == 204:  # No content
                return None

            return response.json()
        except httpx.HTTPError as e:
            logger.error(f"Failed to invoke service {app_id}/{method}: {e}")
            raise

    # -------------------------------------------------------------------------
    # Bindings Operations
    # -------------------------------------------------------------------------

    async def invoke_binding(
        self,
        binding_name: str,
        operation: str,
        data: Any,
        metadata: Optional[Dict[str, str]] = None,
    ) -> Any:
        """Invoke an output binding via Dapr.

        Args:
            binding_name: Name of the binding component.
            operation: Binding operation (e.g., 'create', 'get', 'delete').
            data: Data to send to the binding.
            metadata: Optional metadata for the binding.

        Returns:
            Response data from the binding.

        Raises:
            RuntimeError: If HTTP client is not started.
            httpx.HTTPError: If invocation fails.
        """
        if not self.http_client:
            raise RuntimeError("Dapr client not started. Call start() first.")

        url = f"/v1.0/bindings/{binding_name}"

        payload = {
            "operation": operation,
            "data": data,
            "metadata": metadata or {},
        }

        try:
            response = await self.http_client.post(url, json=payload)
            response.raise_for_status()
            logger.info(f"Invoked binding: {binding_name}/{operation}")

            if response.status_code == 204:  # No content
                return None

            return response.json()
        except httpx.HTTPError as e:
            logger.error(f"Failed to invoke binding {binding_name}/{operation}: {e}")
            raise

    # -------------------------------------------------------------------------
    # Secrets Management Operations
    # -------------------------------------------------------------------------

    async def get_secret(
        self,
        store_name: str,
        key: str,
        metadata: Optional[Dict[str, str]] = None,
    ) -> Optional[Dict[str, str]]:
        """Get a secret from a Dapr secret store.

        Args:
            store_name: Name of the secret store component.
            key: Secret key.
            metadata: Optional metadata for the secret.

        Returns:
            Secret value(s) as a dictionary.

        Raises:
            RuntimeError: If HTTP client is not started.
            httpx.HTTPError: If retrieval fails.
        """
        if not self.http_client:
            raise RuntimeError("Dapr client not started. Call start() first.")

        url = f"/v1.0/secrets/{store_name}/{key}"

        try:
            response = await self.http_client.get(
                url,
                params=metadata or {},
            )
            response.raise_for_status()
            logger.debug(f"Retrieved secret: {store_name}/{key}")
            return response.json()
        except httpx.HTTPError as e:
            logger.error(f"Failed to get secret {store_name}/{key}: {e}")
            raise


# Global Dapr client instance
_dapr_client: Optional[DaprClient] = None


async def get_dapr_client() -> DaprClient:
    """Get or create the global Dapr client instance.

    Returns:
        DaprClient instance.
    """
    global _dapr_client
    if _dapr_client is None:
        _dapr_client = DaprClient()
        await _dapr_client.start()
    return _dapr_client
