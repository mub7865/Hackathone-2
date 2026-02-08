"""Audit logging middleware for automatic request tracking.

This middleware automatically logs API requests to create an audit trail.
It captures user context, request metadata, and integrates with the audit service.
"""

import logging
import re
from typing import Callable, Optional
from uuid import UUID

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp

from app.models.audit_log import AuditAction
from app.services.audit_service import AuditService

logger = logging.getLogger(__name__)


class AuditMiddleware(BaseHTTPMiddleware):
    """Middleware for automatic audit logging of API requests.

    This middleware intercepts requests to task-related endpoints and
    automatically creates audit log entries. It extracts user context,
    resource information, and request metadata.

    Note: This middleware logs basic request information. For detailed
    change tracking (before/after state), use explicit audit logging
    calls in the endpoint handlers.
    """

    # Patterns for extracting resource information from URLs
    TASK_PATTERNS = [
        (re.compile(r'^/api/v1/tasks$'), 'task', None),  # List/Create
        (re.compile(r'^/api/v1/tasks/([0-9a-f-]+)$'), 'task', 1),  # Get/Update/Delete
        (re.compile(r'^/api/v1/tasks/([0-9a-f-]+)/complete$'), 'task', 1),  # Complete
    ]

    def __init__(self, app: ASGIApp):
        """Initialize the audit middleware.

        Args:
            app: The ASGI application
        """
        super().__init__(app)

    async def dispatch(
        self, request: Request, call_next: Callable
    ) -> Response:
        """Process the request and log audit information.

        Args:
            request: The incoming request
            call_next: The next middleware/handler in the chain

        Returns:
            The response from the next handler
        """
        # Only audit specific endpoints (task operations)
        if not self._should_audit(request):
            return await call_next(request)

        # Extract user context from request state (set by auth dependency)
        user_id = self._get_user_id(request)
        if not user_id:
            # No user context, skip audit logging
            return await call_next(request)

        # Extract resource information from URL
        resource_type, resource_id = self._extract_resource_info(request)
        if not resource_type:
            # Could not determine resource, skip audit logging
            return await call_next(request)

        # Determine action from HTTP method
        action = self._determine_action(request, resource_id)
        if not action:
            # Not an auditable action (e.g., GET requests)
            return await call_next(request)

        # Extract request metadata
        ip_address = self._get_client_ip(request)
        user_agent = request.headers.get("user-agent")

        # Process the request
        response = await call_next(request)

        # Only log successful operations (2xx status codes)
        if 200 <= response.status_code < 300:
            try:
                # Create audit log entry
                # Note: We need a database session here, which is tricky in middleware
                # For now, we'll log the intent and implement actual logging in endpoints
                logger.info(
                    f"Audit: user={user_id}, action={action}, "
                    f"resource={resource_type}/{resource_id or 'N/A'}, "
                    f"ip={ip_address}, status={response.status_code}"
                )

                # TODO: Implement actual audit logging with database session
                # This requires access to the database session, which is better
                # handled at the endpoint level for detailed change tracking

            except Exception as e:
                # Don't block the request if audit logging fails
                logger.error(f"Audit logging failed: {e}", exc_info=True)

        return response

    def _should_audit(self, request: Request) -> bool:
        """Check if the request should be audited.

        Args:
            request: The incoming request

        Returns:
            True if the request should be audited
        """
        path = request.url.path

        # Audit task-related endpoints
        if path.startswith("/api/v1/tasks"):
            return True

        # Audit saved filter endpoints
        if path.startswith("/api/v1/saved-filters"):
            return True

        return False

    def _get_user_id(self, request: Request) -> Optional[str]:
        """Extract user ID from request state.

        The user ID should be set by the authentication dependency.

        Args:
            request: The incoming request

        Returns:
            User ID if available, None otherwise
        """
        # Check if user_id is in request state (set by auth dependency)
        return getattr(request.state, "user_id", None)

    def _extract_resource_info(
        self, request: Request
    ) -> tuple[Optional[str], Optional[UUID]]:
        """Extract resource type and ID from the request URL.

        Args:
            request: The incoming request

        Returns:
            Tuple of (resource_type, resource_id)
        """
        path = request.url.path

        # Try to match against known patterns
        for pattern, resource_type, id_group in self.TASK_PATTERNS:
            match = pattern.match(path)
            if match:
                resource_id = None
                if id_group is not None:
                    try:
                        resource_id = UUID(match.group(id_group))
                    except (ValueError, IndexError):
                        pass
                return resource_type, resource_id

        # Check for saved filters
        if path.startswith("/api/v1/saved-filters"):
            match = re.match(r'^/api/v1/saved-filters/([0-9a-f-]+)$', path)
            if match:
                try:
                    resource_id = UUID(match.group(1))
                    return "saved_filter", resource_id
                except ValueError:
                    pass
            return "saved_filter", None

        return None, None

    def _determine_action(
        self, request: Request, resource_id: Optional[UUID]
    ) -> Optional[AuditAction]:
        """Determine the audit action from the HTTP method and context.

        Args:
            request: The incoming request
            resource_id: The resource ID if available

        Returns:
            The audit action, or None if not auditable
        """
        method = request.method
        path = request.url.path

        # Map HTTP methods to audit actions
        if method == "POST":
            return AuditAction.CREATED
        elif method == "PUT" or method == "PATCH":
            # Check if it's a complete action
            if path.endswith("/complete"):
                return AuditAction.COMPLETED
            return AuditAction.UPDATED
        elif method == "DELETE":
            return AuditAction.DELETED
        elif method == "GET" and resource_id:
            # Only log GET for individual resources (not lists)
            # This is optional and can be disabled to reduce log volume
            return AuditAction.VIEWED

        return None

    def _get_client_ip(self, request: Request) -> Optional[str]:
        """Extract client IP address from request.

        Handles X-Forwarded-For header for proxied requests.

        Args:
            request: The incoming request

        Returns:
            Client IP address
        """
        # Check X-Forwarded-For header (for proxied requests)
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            # Take the first IP in the chain
            return forwarded_for.split(",")[0].strip()

        # Fall back to direct client IP
        if request.client:
            return request.client.host

        return None
