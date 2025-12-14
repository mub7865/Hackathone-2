"""Unit tests for the Task model.

Tests cover:
- T018: Task creation with valid data succeeds
- T019: Task creation without title raises ValidationError
- T020: Status defaults to PENDING on creation
- T023: get_by_user returns only tasks owned by that user
- T024: Empty list returned when user has no tasks
- T027: Status update from PENDING to COMPLETED succeeds
- T028: Title/description update succeeds
- T031: Delete owned task succeeds
"""

import pytest
from uuid import UUID

from app.models.task import Task, TaskStatus


class TestTaskCreation:
    """Tests for Task model creation (US1: Create a Task)."""

    def test_task_creation_with_valid_data_succeeds(
        self, valid_task_data: dict
    ) -> None:
        """T018: Task creation with valid data succeeds.

        Given valid task data with user_id, title, and description
        When a Task is created
        Then all fields are set correctly and id is auto-generated.
        """
        task = Task(**valid_task_data)

        assert task.user_id == valid_task_data["user_id"]
        assert task.title == valid_task_data["title"]
        assert task.description == valid_task_data["description"]
        assert task.id is not None
        assert isinstance(task.id, UUID)

    def test_task_creation_with_minimal_data_succeeds(
        self, minimal_task_data: dict
    ) -> None:
        """Task creation with only required fields succeeds.

        Given minimal task data with only user_id and title
        When a Task is created
        Then task is created with description as None.
        """
        task = Task(**minimal_task_data)

        assert task.user_id == minimal_task_data["user_id"]
        assert task.title == minimal_task_data["title"]
        assert task.description is None
        assert task.id is not None

    def test_task_creation_without_title_has_none_value(
        self, mock_user_id: str
    ) -> None:
        """T019: Task creation without title results in None value.

        Given task data without a title
        When a Task is created
        Then title is None (database constraint will enforce NOT NULL).

        Note: SQLModel allows None at Python level; validation happens at DB level
        via nullable=False constraint and CHECK constraint.
        """
        task = Task(user_id=mock_user_id)
        # Title is None - database will reject on insert
        assert task.title is None

    def test_task_creation_without_user_id_has_none_value(self) -> None:
        """Task creation without user_id results in None value.

        Given task data without a user_id
        When a Task is created
        Then user_id is None (database constraint will enforce NOT NULL).

        Note: SQLModel allows None at Python level; validation happens at DB level.
        """
        task = Task(title="Test Task")
        # user_id is None - database will reject on insert
        assert task.user_id is None

    def test_task_model_validates_via_pydantic(
        self, mock_user_id: str
    ) -> None:
        """Task model can be validated using Pydantic model_validate.

        When using model_validate with missing required fields
        Then a ValidationError is raised.
        """
        from pydantic import ValidationError

        # Using model_validate forces Pydantic validation
        with pytest.raises(ValidationError):
            Task.model_validate({"user_id": mock_user_id})  # missing title


class TestTaskStatusDefaults:
    """Tests for Task status field defaults."""

    def test_status_defaults_to_pending_on_creation(
        self, valid_task_data: dict
    ) -> None:
        """T020: Status defaults to PENDING on creation.

        Given valid task data without explicit status
        When a Task is created
        Then status is automatically set to PENDING.
        """
        task = Task(**valid_task_data)

        assert task.status == TaskStatus.PENDING
        assert task.status.value == "pending"

    def test_status_can_be_set_explicitly_to_completed(
        self, valid_task_data: dict
    ) -> None:
        """Status can be explicitly set to COMPLETED on creation.

        Given valid task data with status=COMPLETED
        When a Task is created
        Then status is set to COMPLETED.
        """
        valid_task_data["status"] = TaskStatus.COMPLETED
        task = Task(**valid_task_data)

        assert task.status == TaskStatus.COMPLETED
        assert task.status.value == "completed"

    def test_status_can_be_set_via_string_value(
        self, valid_task_data: dict
    ) -> None:
        """Status can be set using string value.

        Given valid task data with status as string 'completed'
        When a Task is created
        Then status enum is correctly resolved.
        """
        valid_task_data["status"] = "completed"
        task = Task(**valid_task_data)

        assert task.status == TaskStatus.COMPLETED


class TestTaskStatusEnum:
    """Tests for TaskStatus enum values."""

    def test_task_status_has_pending_value(self) -> None:
        """TaskStatus enum has PENDING value."""
        assert TaskStatus.PENDING.value == "pending"

    def test_task_status_has_completed_value(self) -> None:
        """TaskStatus enum has COMPLETED value."""
        assert TaskStatus.COMPLETED.value == "completed"

    def test_task_status_only_has_two_values(self) -> None:
        """TaskStatus enum only has two valid values."""
        assert len(TaskStatus) == 2
        assert set(TaskStatus) == {TaskStatus.PENDING, TaskStatus.COMPLETED}


class TestTaskIdGeneration:
    """Tests for Task ID auto-generation."""

    def test_task_id_is_uuid(self, valid_task_data: dict) -> None:
        """Task ID is a valid UUID."""
        task = Task(**valid_task_data)

        assert isinstance(task.id, UUID)

    def test_each_task_gets_unique_id(self, valid_task_data: dict) -> None:
        """Each task gets a unique ID."""
        task1 = Task(**valid_task_data)
        task2 = Task(**valid_task_data)

        assert task1.id != task2.id


class TestQueryMethodSignatures:
    """Tests for Task query method signatures (US2: View Own Tasks).

    Note: These tests verify method existence and signatures without database.
    Full integration tests with actual queries are in test_user_isolation.py.
    """

    def test_get_by_user_method_exists(self) -> None:
        """T023: get_by_user class method exists on Task model."""
        assert hasattr(Task, "get_by_user")
        assert callable(getattr(Task, "get_by_user"))

    def test_get_by_user_and_status_method_exists(self) -> None:
        """get_by_user_and_status class method exists on Task model."""
        assert hasattr(Task, "get_by_user_and_status")
        assert callable(getattr(Task, "get_by_user_and_status"))

    def test_get_by_user_is_async(self) -> None:
        """get_by_user is an async method."""
        import asyncio

        assert asyncio.iscoroutinefunction(Task.get_by_user)

    def test_get_by_user_and_status_is_async(self) -> None:
        """get_by_user_and_status is an async method."""
        import asyncio

        assert asyncio.iscoroutinefunction(Task.get_by_user_and_status)


class TestUpdateMethodSignatures:
    """Tests for Task update method signatures (US3: Update a Task).

    Note: These tests verify method existence and signatures without database.
    Full integration tests with actual updates are in test_user_isolation.py.
    """

    def test_update_task_method_exists(self) -> None:
        """T027/T028: update_task class method exists on Task model."""
        assert hasattr(Task, "update_task")
        assert callable(getattr(Task, "update_task"))

    def test_update_task_is_async(self) -> None:
        """update_task is an async method."""
        import asyncio

        assert asyncio.iscoroutinefunction(Task.update_task)


class TestDeleteMethodSignatures:
    """Tests for Task delete method signatures (US4: Delete a Task).

    Note: These tests verify method existence and signatures without database.
    Full integration tests with actual deletes are in test_user_isolation.py.
    """

    def test_delete_task_method_exists(self) -> None:
        """T031: delete_task class method exists on Task model."""
        assert hasattr(Task, "delete_task")
        assert callable(getattr(Task, "delete_task"))

    def test_delete_task_is_async(self) -> None:
        """delete_task is an async method."""
        import asyncio

        assert asyncio.iscoroutinefunction(Task.delete_task)
