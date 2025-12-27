"""Structured JSON logging middleware for request/response logging.

Implements FR-017: Structured JSON logs with request_id, user_id, endpoint, status, duration.
"""

import json
import logging
import sys
from time import perf_counter
from typing import Callable
from uuid import uuid4

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware


class JSONFormatter(logging.Formatter):
    """Format log records as JSON for structured logging."""

    def format(self, record: logging.LogRecord) -> str:
        log_data = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }

        # Add extra fields if present
        if hasattr(record, "extra") and record.extra:
            log_data.update(record.extra)

        return json.dumps(log_data)


def setup_logging(level: int = logging.INFO) -> logging.Logger:
    """Configure structured JSON logging.

    Args:
        level: Logging level (default INFO)

    Returns:
        Configured logger instance
    """
    logger = logging.getLogger("todo-api")
    logger.setLevel(level)

    # Remove existing handlers
    logger.handlers.clear()

    # Add JSON handler for stdout
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JSONFormatter())
    logger.addHandler(handler)

    return logger


# Global logger instance
logger = setup_logging()


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Middleware to log all HTTP requests with structured JSON.

    Logs include:
    - request_id: Unique identifier for the request
    - user_id: Authenticated user ID (if available)
    - method: HTTP method
    - endpoint: Request path
    - status: HTTP response status code
    - duration_ms: Request processing time in milliseconds
    """

    async def dispatch(
        self, request: Request, call_next: Callable
    ) -> Response:
        # Generate unique request ID
        request_id = str(uuid4())
        request.state.request_id = request_id

        # Record start time
        start_time = perf_counter()

        # Process request
        response = await call_next(request)

        # Calculate duration
        duration_ms = (perf_counter() - start_time) * 1000

        # Get user_id from request state (set by auth dependency)
        user_id = getattr(request.state, "user_id", None)

        # Log request details
        log_extra = {
            "request_id": request_id,
            "user_id": user_id,
            "method": request.method,
            "endpoint": request.url.path,
            "status": response.status_code,
            "duration_ms": round(duration_ms, 2),
        }

        # Create a new log record with extra data
        logger.info(
            f"{request.method} {request.url.path} - {response.status_code}",
            extra={"extra": log_extra},
        )

        # Add request_id to response headers for tracing
        response.headers["X-Request-ID"] = request_id

        return response
