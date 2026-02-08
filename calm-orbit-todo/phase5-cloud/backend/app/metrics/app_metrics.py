"""Custom application metrics for Prometheus monitoring.

This module provides Prometheus metrics for monitoring application performance,
business metrics, and system health.
"""

import logging
import time
from functools import wraps
from typing import Callable

from prometheus_client import Counter, Gauge, Histogram, Info, generate_latest
from prometheus_client.core import CollectorRegistry

logger = logging.getLogger(__name__)

# Create a custom registry
registry = CollectorRegistry()

# Application info
app_info = Info(
    "todo_app",
    "Todo application information",
    registry=registry,
)
app_info.info({
    "version": "1.0.0",
    "environment": "development",
})

# HTTP request metrics
http_requests_total = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
    registry=registry,
)

http_request_duration_seconds = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0),
    registry=registry,
)

http_requests_in_progress = Gauge(
    "http_requests_in_progress",
    "Number of HTTP requests in progress",
    ["method", "endpoint"],
    registry=registry,
)

# Task operation metrics
task_operations_total = Counter(
    "task_operations_total",
    "Total task operations",
    ["operation", "status"],
    registry=registry,
)

task_operations_duration_seconds = Histogram(
    "task_operations_duration_seconds",
    "Task operation latency in seconds",
    ["operation"],
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0),
    registry=registry,
)

tasks_total = Gauge(
    "tasks_total",
    "Total number of tasks",
    ["user_id", "status"],
    registry=registry,
)

tasks_by_priority = Gauge(
    "tasks_by_priority",
    "Number of tasks by priority",
    ["priority"],
    registry=registry,
)

# Event publishing metrics
events_published_total = Counter(
    "events_published_total",
    "Total events published",
    ["event_type", "topic"],
    registry=registry,
)

events_publish_failures_total = Counter(
    "events_publish_failures_total",
    "Total event publish failures",
    ["event_type", "topic", "error"],
    registry=registry,
)

events_publish_duration_seconds = Histogram(
    "events_publish_duration_seconds",
    "Event publish latency in seconds",
    ["event_type"],
    buckets=(0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0),
    registry=registry,
)

# Event consumption metrics
events_consumed_total = Counter(
    "events_consumed_total",
    "Total events consumed",
    ["event_type", "consumer_group"],
    registry=registry,
)

events_consumption_failures_total = Counter(
    "events_consumption_failures_total",
    "Total event consumption failures",
    ["event_type", "consumer_group", "error"],
    registry=registry,
)

events_consumption_duration_seconds = Histogram(
    "events_consumption_duration_seconds",
    "Event consumption latency in seconds",
    ["event_type"],
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0),
    registry=registry,
)

events_duplicate_total = Counter(
    "events_duplicate_total",
    "Total duplicate events detected",
    ["event_type", "consumer_group"],
    registry=registry,
)

# Database metrics
db_queries_total = Counter(
    "db_queries_total",
    "Total database queries",
    ["operation", "table"],
    registry=registry,
)

db_query_duration_seconds = Histogram(
    "db_query_duration_seconds",
    "Database query latency in seconds",
    ["operation", "table"],
    buckets=(0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5),
    registry=registry,
)

db_connections_active = Gauge(
    "db_connections_active",
    "Number of active database connections",
    registry=registry,
)

db_connections_idle = Gauge(
    "db_connections_idle",
    "Number of idle database connections",
    registry=registry,
)

# WebSocket metrics
websocket_connections_active = Gauge(
    "websocket_connections_active",
    "Number of active WebSocket connections",
    registry=registry,
)

websocket_connections_total = Counter(
    "websocket_connections_total",
    "Total WebSocket connections",
    ["status"],
    registry=registry,
)

websocket_messages_sent_total = Counter(
    "websocket_messages_sent_total",
    "Total WebSocket messages sent",
    ["message_type"],
    registry=registry,
)

websocket_messages_received_total = Counter(
    "websocket_messages_received_total",
    "Total WebSocket messages received",
    ["message_type"],
    registry=registry,
)

# Notification metrics
notifications_sent_total = Counter(
    "notifications_sent_total",
    "Total notifications sent",
    ["channel", "notification_type"],
    registry=registry,
)

notifications_failed_total = Counter(
    "notifications_failed_total",
    "Total notification failures",
    ["channel", "notification_type", "error"],
    registry=registry,
)

notifications_rate_limited_total = Counter(
    "notifications_rate_limited_total",
    "Total notifications blocked by rate limiting",
    ["channel", "notification_type"],
    registry=registry,
)

notifications_quiet_hours_blocked_total = Counter(
    "notifications_quiet_hours_blocked_total",
    "Total notifications blocked by quiet hours",
    ["channel", "notification_type"],
    registry=registry,
)

# Audit log metrics
audit_logs_created_total = Counter(
    "audit_logs_created_total",
    "Total audit logs created",
    ["action", "resource_type"],
    registry=registry,
)

# Cache metrics (if using cache)
cache_hits_total = Counter(
    "cache_hits_total",
    "Total cache hits",
    ["cache_name"],
    registry=registry,
)

cache_misses_total = Counter(
    "cache_misses_total",
    "Total cache misses",
    ["cache_name"],
    registry=registry,
)

# Business metrics
users_active_total = Gauge(
    "users_active_total",
    "Number of active users",
    registry=registry,
)

tasks_completed_today = Gauge(
    "tasks_completed_today",
    "Number of tasks completed today",
    registry=registry,
)

recurring_patterns_active = Gauge(
    "recurring_patterns_active",
    "Number of active recurring patterns",
    registry=registry,
)


def track_http_request(method: str, endpoint: str):
    """Decorator to track HTTP request metrics.

    Args:
        method: HTTP method (GET, POST, etc.)
        endpoint: API endpoint path
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args, **kwargs):
            http_requests_in_progress.labels(method=method, endpoint=endpoint).inc()
            start_time = time.time()

            try:
                result = await func(*args, **kwargs)
                status = "success"
                return result
            except Exception as e:
                status = "error"
                raise
            finally:
                duration = time.time() - start_time
                http_requests_in_progress.labels(method=method, endpoint=endpoint).dec()
                http_requests_total.labels(method=method, endpoint=endpoint, status=status).inc()
                http_request_duration_seconds.labels(method=method, endpoint=endpoint).observe(duration)

        return wrapper
    return decorator


def track_task_operation(operation: str):
    """Decorator to track task operation metrics.

    Args:
        operation: Operation name (create, update, delete, complete)
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args, **kwargs):
            start_time = time.time()

            try:
                result = await func(*args, **kwargs)
                status = "success"
                return result
            except Exception as e:
                status = "error"
                raise
            finally:
                duration = time.time() - start_time
                task_operations_total.labels(operation=operation, status=status).inc()
                task_operations_duration_seconds.labels(operation=operation).observe(duration)

        return wrapper
    return decorator


def track_event_publish(event_type: str, topic: str):
    """Track event publishing metrics.

    Args:
        event_type: Type of event
        topic: Kafka topic
    """
    start_time = time.time()

    def success():
        duration = time.time() - start_time
        events_published_total.labels(event_type=event_type, topic=topic).inc()
        events_publish_duration_seconds.labels(event_type=event_type).observe(duration)

    def failure(error: str):
        events_publish_failures_total.labels(event_type=event_type, topic=topic, error=error).inc()

    return success, failure


def track_event_consumption(event_type: str, consumer_group: str):
    """Track event consumption metrics.

    Args:
        event_type: Type of event
        consumer_group: Consumer group name
    """
    start_time = time.time()

    def success():
        duration = time.time() - start_time
        events_consumed_total.labels(event_type=event_type, consumer_group=consumer_group).inc()
        events_consumption_duration_seconds.labels(event_type=event_type).observe(duration)

    def failure(error: str):
        events_consumption_failures_total.labels(
            event_type=event_type,
            consumer_group=consumer_group,
            error=error,
        ).inc()

    def duplicate():
        events_duplicate_total.labels(event_type=event_type, consumer_group=consumer_group).inc()

    return success, failure, duplicate


def get_metrics() -> bytes:
    """Get Prometheus metrics in text format.

    Returns:
        Metrics in Prometheus text format
    """
    return generate_latest(registry)


# Metrics endpoint for FastAPI
async def metrics_endpoint():
    """FastAPI endpoint for Prometheus metrics."""
    from fastapi import Response
    return Response(content=get_metrics(), media_type="text/plain")
