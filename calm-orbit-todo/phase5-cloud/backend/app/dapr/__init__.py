"""Dapr integration module for distributed application runtime.

This module provides Dapr client functionality for pub/sub, state management,
service invocation, and other Dapr building blocks.
"""

from app.dapr.client import DaprClient, get_dapr_client

__all__ = [
    "DaprClient",
    "get_dapr_client",
]
