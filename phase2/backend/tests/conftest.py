"""Pytest fixtures for Todo Backend tests."""

import os
from uuid import uuid4

import pytest

# Set test environment variables before importing app modules
os.environ.setdefault("JWT_SECRET", "test-secret-key-for-testing-only")
os.environ.setdefault("ENVIRONMENT", "test")


@pytest.fixture
def mock_user_id() -> str:
    """
    Generate a mock Better Auth user ID.

    Returns a UUID string in the format used by Better Auth.
    """
    return str(uuid4())


@pytest.fixture
def mock_user_id_b() -> str:
    """
    Generate a second mock user ID for isolation tests.

    Returns a different UUID string for multi-user test scenarios.
    """
    return str(uuid4())


@pytest.fixture
def valid_task_data(mock_user_id: str) -> dict:
    """
    Valid task creation data.

    Returns a dictionary with all required fields for creating a Task.
    """
    return {
        "user_id": mock_user_id,
        "title": "Test Task",
        "description": "Test description for the task",
    }


@pytest.fixture
def minimal_task_data(mock_user_id: str) -> dict:
    """
    Minimal valid task data (only required fields).

    Returns a dictionary with only the required fields.
    """
    return {
        "user_id": mock_user_id,
        "title": "Minimal Task",
    }
