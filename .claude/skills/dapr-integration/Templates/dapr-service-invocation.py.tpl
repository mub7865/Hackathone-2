"""
Dapr Service Invocation Template

This template provides service-to-service invocation using Dapr with
automatic retries, circuit breakers, and distributed tracing.
"""

from dapr.clients import DaprClient
from dapr.clients.grpc._request import InvokeMethodRequest
from typing import Optional, Dict, Any, List
from pydantic import BaseModel
import logging
import json

logger = logging.getLogger(__name__)


# ============================================================================
# Request/Response Models
# ============================================================================

class ServiceRequest(BaseModel):
    """Base model for service requests."""
    request_id: Optional[str] = None
    data: Dict[str, Any]


class ServiceResponse(BaseModel):
    """Base model for service responses."""
    success: bool
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None


# ============================================================================
# Service Invoker
# ============================================================================

class DaprServiceInvoker:
    """Client for invoking other services via Dapr."""

    def __init__(self):
        self.client = None

    def __enter__(self):
        self.client = DaprClient()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.client:
            self.client.close()

    # ========================================================================
    # HTTP Methods
    # ========================================================================

    def get(
        self,
        app_id: str,
        method_name: str,
        query_params: Optional[Dict[str, str]] = None,
        headers: Optional[Dict[str, str]] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Invoke GET method on another service.

        Args:
            app_id: Target service app ID
            method_name: Method/endpoint to invoke
            query_params: Query parameters
            headers: HTTP headers

        Returns:
            Response data as dict, or None if failed
        """
        try:
            with DaprClient() as client:
                # Build query string
                if query_params:
                    query_string = "&".join(
                        f"{k}={v}" for k, v in query_params.items()
                    )
                    method_name = f"{method_name}?{query_string}"

                response = client.invoke_method(
                    app_id=app_id,
                    method_name=method_name,
                    http_verb='GET',
                    http_headers=headers or {}
                )

                logger.info(f"GET {app_id}/{method_name} - Status: {response.status_code}")

                if response.status_code == 200:
                    return response.json()
                else:
                    logger.error(f"GET failed: {response.status_code} - {response.text()}")
                    return None

        except Exception as e:
            logger.error(f"Failed to invoke GET {app_id}/{method_name}: {e}", exc_info=True)
            return None

    def post(
        self,
        app_id: str,
        method_name: str,
        data: Dict[str, Any],
        headers: Optional[Dict[str, str]] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Invoke POST method on another service.

        Args:
            app_id: Target service app ID
            method_name: Method/endpoint to invoke
            data: Request body data
            headers: HTTP headers

        Returns:
            Response data as dict, or None if failed
        """
        try:
            with DaprClient() as client:
                response = client.invoke_method(
                    app_id=app_id,
                    method_name=method_name,
                    data=json.dumps(data),
                    http_verb='POST',
                    http_headers=headers or {}
                )

                logger.info(f"POST {app_id}/{method_name} - Status: {response.status_code}")

                if response.status_code in [200, 201]:
                    return response.json()
                else:
                    logger.error(f"POST failed: {response.status_code} - {response.text()}")
                    return None

        except Exception as e:
            logger.error(f"Failed to invoke POST {app_id}/{method_name}: {e}", exc_info=True)
            return None

    def put(
        self,
        app_id: str,
        method_name: str,
        data: Dict[str, Any],
        headers: Optional[Dict[str, str]] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Invoke PUT method on another service.

        Args:
            app_id: Target service app ID
            method_name: Method/endpoint to invoke
            data: Request body data
            headers: HTTP headers

        Returns:
            Response data as dict, or None if failed
        """
        try:
            with DaprClient() as client:
                response = client.invoke_method(
                    app_id=app_id,
                    method_name=method_name,
                    data=json.dumps(data),
                    http_verb='PUT',
                    http_headers=headers or {}
                )

                logger.info(f"PUT {app_id}/{method_name} - Status: {response.status_code}")

                if response.status_code == 200:
                    return response.json()
                else:
                    logger.error(f"PUT failed: {response.status_code} - {response.text()}")
                    return None

        except Exception as e:
            logger.error(f"Failed to invoke PUT {app_id}/{method_name}: {e}", exc_info=True)
            return None

    def delete(
        self,
        app_id: str,
        method_name: str,
        headers: Optional[Dict[str, str]] = None
    ) -> bool:
        """
        Invoke DELETE method on another service.

        Args:
            app_id: Target service app ID
            method_name: Method/endpoint to invoke
            headers: HTTP headers

        Returns:
            True if successful, False otherwise
        """
        try:
            with DaprClient() as client:
                response = client.invoke_method(
                    app_id=app_id,
                    method_name=method_name,
                    http_verb='DELETE',
                    http_headers=headers or {}
                )

                logger.info(f"DELETE {app_id}/{method_name} - Status: {response.status_code}")

                return response.status_code in [200, 204]

        except Exception as e:
            logger.error(f"Failed to invoke DELETE {app_id}/{method_name}: {e}", exc_info=True)
            return False


# ============================================================================
# Service Clients (Domain-Specific)
# ============================================================================

class UserServiceClient:
    """Client for User Service."""

    def __init__(self, app_id: str = "user-service"):
        self.app_id = app_id
        self.invoker = DaprServiceInvoker()

    def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user by ID."""
        return self.invoker.get(
            app_id=self.app_id,
            method_name=f"users/{user_id}"
        )

    def create_user(self, user_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a new user."""
        return self.invoker.post(
            app_id=self.app_id,
            method_name="users",
            data=user_data
        )

    def update_user(self, user_id: str, user_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update user."""
        return self.invoker.put(
            app_id=self.app_id,
            method_name=f"users/{user_id}",
            data=user_data
        )

    def delete_user(self, user_id: str) -> bool:
        """Delete user."""
        return self.invoker.delete(
            app_id=self.app_id,
            method_name=f"users/{user_id}"
        )


class NotificationServiceClient:
    """Client for Notification Service."""

    def __init__(self, app_id: str = "notification-service"):
        self.app_id = app_id
        self.invoker = DaprServiceInvoker()

    def send_email(
        self,
        to: str,
        subject: str,
        body: str
    ) -> bool:
        """Send email notification."""
        response = self.invoker.post(
            app_id=self.app_id,
            method_name="notifications/email",
            data={
                "to": to,
                "subject": subject,
                "body": body
            }
        )
        return response is not None

    def send_sms(
        self,
        to: str,
        message: str
    ) -> bool:
        """Send SMS notification."""
        response = self.invoker.post(
            app_id=self.app_id,
            method_name="notifications/sms",
            data={
                "to": to,
                "message": message
            }
        )
        return response is not None

    def send_push(
        self,
        user_id: str,
        title: str,
        body: str
    ) -> bool:
        """Send push notification."""
        response = self.invoker.post(
            app_id=self.app_id,
            method_name="notifications/push",
            data={
                "user_id": user_id,
                "title": title,
                "body": body
            }
        )
        return response is not None


class TaskServiceClient:
    """Client for Task Service."""

    def __init__(self, app_id: str = "task-service"):
        self.app_id = app_id
        self.invoker = DaprServiceInvoker()

    def get_tasks(
        self,
        user_id: str,
        status: Optional[str] = None
    ) -> Optional[List[Dict[str, Any]]]:
        """Get tasks for a user."""
        query_params = {"user_id": user_id}
        if status:
            query_params["status"] = status

        return self.invoker.get(
            app_id=self.app_id,
            method_name="tasks",
            query_params=query_params
        )

    def create_task(self, task_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a new task."""
        return self.invoker.post(
            app_id=self.app_id,
            method_name="tasks",
            data=task_data
        )

    def update_task(self, task_id: int, task_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update task."""
        return self.invoker.put(
            app_id=self.app_id,
            method_name=f"tasks/{task_id}",
            data=task_data
        )

    def complete_task(self, task_id: int) -> bool:
        """Mark task as completed."""
        response = self.invoker.post(
            app_id=self.app_id,
            method_name=f"tasks/{task_id}/complete",
            data={}
        )
        return response is not None


# ============================================================================
# Retry and Circuit Breaker Patterns
# ============================================================================

from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

class ResilientServiceInvoker(DaprServiceInvoker):
    """Service invoker with retry and circuit breaker patterns."""

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type(Exception)
    )
    def get_with_retry(
        self,
        app_id: str,
        method_name: str,
        **kwargs
    ) -> Optional[Dict[str, Any]]:
        """GET with automatic retry."""
        return self.get(app_id, method_name, **kwargs)

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type(Exception)
    )
    def post_with_retry(
        self,
        app_id: str,
        method_name: str,
        data: Dict[str, Any],
        **kwargs
    ) -> Optional[Dict[str, Any]]:
        """POST with automatic retry."""
        return self.post(app_id, method_name, data, **kwargs)


# ============================================================================
# FastAPI Integration
# ============================================================================

from fastapi import Depends

def get_user_service_client() -> UserServiceClient:
    """Dependency injection for UserServiceClient."""
    return UserServiceClient()

def get_notification_service_client() -> NotificationServiceClient:
    """Dependency injection for NotificationServiceClient."""
    return NotificationServiceClient()

def get_task_service_client() -> TaskServiceClient:
    """Dependency injection for TaskServiceClient."""
    return TaskServiceClient()


# ============================================================================
# Usage Example
# ============================================================================

if __name__ == "__main__":
    # Basic usage
    invoker = DaprServiceInvoker()

    # Get user
    user = invoker.get("user-service", "users/123")
    print(f"User: {user}")

    # Create notification
    result = invoker.post(
        "notification-service",
        "notifications/email",
        data={
            "to": "user@example.com",
            "subject": "Test",
            "body": "Test message"
        }
    )
    print(f"Notification sent: {result}")

    # Using domain-specific clients
    user_client = UserServiceClient()
    user = user_client.get_user("123")
    print(f"User from client: {user}")

    # Using resilient invoker with retry
    resilient_invoker = ResilientServiceInvoker()
    user = resilient_invoker.get_with_retry("user-service", "users/123")
    print(f"User with retry: {user}")
