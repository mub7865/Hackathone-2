"""Core utilities: authentication, exceptions, and logging."""

from .auth import get_current_user
from .exceptions import (
    AuthenticationError,
    TaskNotFoundError,
    register_exception_handlers,
)

__all__ = [
    "get_current_user",
    "AuthenticationError",
    "TaskNotFoundError",
    "register_exception_handlers",
]
