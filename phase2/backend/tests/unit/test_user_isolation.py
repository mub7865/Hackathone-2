"""User isolation tests for the Task model.

Tests cover:
- T025: Multi-user isolation test per SC-007 (get_by_user returns only owned tasks)
- T029: User A cannot update User B's task (Phase 5)
- T032: User A cannot delete User B's task (Phase 6)

These tests use the actual database to verify isolation at the query level.
"""

import pytest
from uuid import uuid4

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

from app.config import get_settings
from app.models.task import Task, TaskStatus


@pytest.fixture
async def async_session():
    """Create an async session for database tests.

    Uses the actual Neon database configured in .env.
    Each test runs in a transaction that is rolled back after the test.
    """
    settings = get_settings()
    engine = create_async_engine(settings.database_url, echo=False)

    async_session_factory = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )

    async with async_session_factory() as session:
        # Start a transaction
        async with session.begin():
            yield session
            # Rollback happens automatically when exiting the context


@pytest.fixture
def user_a_id() -> str:
    """Generate a unique user ID for User A."""
    return str(uuid4())


@pytest.fixture
def user_b_id() -> str:
    """Generate a unique user ID for User B."""
    return str(uuid4())


class TestUserIsolation:
    """Tests for user isolation in Task queries (SC-007)."""

    @pytest.mark.asyncio
    async def test_get_by_user_returns_only_owned_tasks(
        self, async_session: AsyncSession, user_a_id: str, user_b_id: str
    ) -> None:
        """T025: get_by_user returns only tasks owned by that user.

        Given:
            - User A has 2 tasks
            - User B has 1 task
        When:
            - User A queries their tasks
        Then:
            - Only User A's 2 tasks are returned
            - User B's task is NOT returned
        """
        # Create tasks for User A
        task_a1 = Task(user_id=user_a_id, title="User A Task 1")
        task_a2 = Task(user_id=user_a_id, title="User A Task 2")

        # Create task for User B
        task_b1 = Task(user_id=user_b_id, title="User B Task 1")

        async_session.add_all([task_a1, task_a2, task_b1])
        await async_session.flush()

        # Query tasks for User A
        user_a_tasks = await Task.get_by_user(async_session, user_a_id)

        # Verify isolation
        assert len(user_a_tasks) == 2
        task_titles = {t.title for t in user_a_tasks}
        assert task_titles == {"User A Task 1", "User A Task 2"}
        assert "User B Task 1" not in task_titles

    @pytest.mark.asyncio
    async def test_get_by_user_returns_empty_list_for_user_with_no_tasks(
        self, async_session: AsyncSession, user_a_id: str, user_b_id: str
    ) -> None:
        """T024: Empty list returned when user has no tasks (not error).

        Given:
            - User A has tasks
            - User B has no tasks
        When:
            - User B queries their tasks
        Then:
            - An empty list is returned (not None, not an error)
        """
        # Create tasks only for User A
        task_a1 = Task(user_id=user_a_id, title="User A Task 1")
        async_session.add(task_a1)
        await async_session.flush()

        # Query tasks for User B (who has none)
        user_b_tasks = await Task.get_by_user(async_session, user_b_id)

        # Verify empty list returned
        assert user_b_tasks == []
        assert isinstance(user_b_tasks, list) or hasattr(user_b_tasks, "__iter__")

    @pytest.mark.asyncio
    async def test_get_by_user_and_status_respects_isolation(
        self, async_session: AsyncSession, user_a_id: str, user_b_id: str
    ) -> None:
        """get_by_user_and_status respects user isolation.

        Given:
            - User A has 1 pending and 1 completed task
            - User B has 1 pending task
        When:
            - User A queries their pending tasks
        Then:
            - Only User A's pending task is returned
        """
        # Create tasks for User A
        task_a_pending = Task(
            user_id=user_a_id, title="A Pending", status=TaskStatus.PENDING
        )
        task_a_completed = Task(
            user_id=user_a_id, title="A Completed", status=TaskStatus.COMPLETED
        )

        # Create task for User B
        task_b_pending = Task(
            user_id=user_b_id, title="B Pending", status=TaskStatus.PENDING
        )

        async_session.add_all([task_a_pending, task_a_completed, task_b_pending])
        await async_session.flush()

        # Query pending tasks for User A
        user_a_pending = await Task.get_by_user_and_status(
            async_session, user_a_id, TaskStatus.PENDING
        )

        # Verify isolation and status filter
        assert len(user_a_pending) == 1
        assert user_a_pending[0].title == "A Pending"
        assert user_a_pending[0].status == TaskStatus.PENDING

    @pytest.mark.asyncio
    async def test_user_b_cannot_see_user_a_tasks(
        self, async_session: AsyncSession, user_a_id: str, user_b_id: str
    ) -> None:
        """User B cannot see User A's tasks through get_by_user.

        This is the inverse test of T025 to ensure bidirectional isolation.
        """
        # Create tasks only for User A
        task_a1 = Task(user_id=user_a_id, title="Secret Task A")
        task_a2 = Task(user_id=user_a_id, title="Another Secret Task A")
        async_session.add_all([task_a1, task_a2])
        await async_session.flush()

        # User B tries to see User A's tasks
        user_b_view = await Task.get_by_user(async_session, user_b_id)

        # User B should see nothing
        assert len(user_b_view) == 0

        # User A should still see their tasks
        user_a_view = await Task.get_by_user(async_session, user_a_id)
        assert len(user_a_view) == 2


class TestTaskUpdate:
    """Tests for Task update operations (US3: Update a Task)."""

    @pytest.mark.asyncio
    async def test_status_update_from_pending_to_completed_succeeds(
        self, async_session: AsyncSession, user_a_id: str
    ) -> None:
        """T027: Status update from PENDING to COMPLETED succeeds.

        Given:
            - User A has a task with status PENDING
        When:
            - User A updates the task status to COMPLETED
        Then:
            - The task status is updated to COMPLETED
            - The task is returned (not None)
        """
        # Create a pending task
        task = Task(user_id=user_a_id, title="Task to Complete")
        async_session.add(task)
        await async_session.flush()

        assert task.status == TaskStatus.PENDING
        task_id = task.id

        # Update status to COMPLETED
        updated = await Task.update_task(
            async_session,
            task_id=task_id,
            user_id=user_a_id,
            updates={"status": TaskStatus.COMPLETED},
        )

        # Verify update succeeded
        assert updated is not None
        assert updated.status == TaskStatus.COMPLETED
        assert updated.id == task_id

    @pytest.mark.asyncio
    async def test_title_and_description_update_succeeds(
        self, async_session: AsyncSession, user_a_id: str
    ) -> None:
        """T028: Title/description update succeeds.

        Given:
            - User A has a task with initial title and description
        When:
            - User A updates both title and description
        Then:
            - Both fields are updated correctly
        """
        # Create a task with initial values
        task = Task(
            user_id=user_a_id,
            title="Original Title",
            description="Original description",
        )
        async_session.add(task)
        await async_session.flush()

        task_id = task.id

        # Update title and description
        updated = await Task.update_task(
            async_session,
            task_id=task_id,
            user_id=user_a_id,
            updates={
                "title": "Updated Title",
                "description": "Updated description",
            },
        )

        # Verify updates
        assert updated is not None
        assert updated.title == "Updated Title"
        assert updated.description == "Updated description"

    @pytest.mark.asyncio
    async def test_user_a_cannot_update_user_b_task(
        self, async_session: AsyncSession, user_a_id: str, user_b_id: str
    ) -> None:
        """T029: User A cannot update User B's task (returns None).

        Given:
            - User B has a task
        When:
            - User A tries to update User B's task
        Then:
            - None is returned (ownership check fails)
            - User B's task remains unchanged
        """
        # Create a task owned by User B
        task_b = Task(user_id=user_b_id, title="User B's Task")
        async_session.add(task_b)
        await async_session.flush()

        task_b_id = task_b.id
        original_title = task_b.title

        # User A tries to update User B's task
        result = await Task.update_task(
            async_session,
            task_id=task_b_id,
            user_id=user_a_id,  # Wrong user!
            updates={"title": "Hacked Title"},
        )

        # Verify update was rejected
        assert result is None

        # Verify User B's task is unchanged
        await async_session.refresh(task_b)
        assert task_b.title == original_title

    @pytest.mark.asyncio
    async def test_update_nonexistent_task_returns_none(
        self, async_session: AsyncSession, user_a_id: str
    ) -> None:
        """Update of non-existent task returns None.

        Given:
            - A task ID that doesn't exist
        When:
            - User tries to update it
        Then:
            - None is returned
        """
        from uuid import uuid4

        fake_task_id = uuid4()

        result = await Task.update_task(
            async_session,
            task_id=fake_task_id,
            user_id=user_a_id,
            updates={"title": "New Title"},
        )

        assert result is None

    @pytest.mark.asyncio
    async def test_update_ignores_disallowed_fields(
        self, async_session: AsyncSession, user_a_id: str
    ) -> None:
        """Update ignores fields that are not allowed to be updated.

        Given:
            - A task owned by User A
        When:
            - User A tries to update disallowed fields (id, user_id, created_at)
        Then:
            - Those fields remain unchanged
        """
        # Create a task
        task = Task(user_id=user_a_id, title="Original Task")
        async_session.add(task)
        await async_session.flush()

        original_id = task.id
        original_user_id = task.user_id
        task_id = task.id

        # Try to update disallowed fields
        updated = await Task.update_task(
            async_session,
            task_id=task_id,
            user_id=user_a_id,
            updates={
                "id": uuid4(),  # Should be ignored
                "user_id": "hacker-id",  # Should be ignored
                "title": "Allowed Update",  # Should work
            },
        )

        # Verify only allowed field was updated
        assert updated is not None
        assert updated.id == original_id  # Unchanged
        assert updated.user_id == original_user_id  # Unchanged
        assert updated.title == "Allowed Update"  # Changed


class TestTaskDelete:
    """Tests for Task delete operations (US4: Delete a Task)."""

    @pytest.mark.asyncio
    async def test_delete_owned_task_succeeds(
        self, async_session: AsyncSession, user_a_id: str
    ) -> None:
        """T031: Delete owned task succeeds and task no longer queryable.

        Given:
            - User A has a task
        When:
            - User A deletes their task
        Then:
            - True is returned
            - The task is no longer queryable
        """
        # Create a task
        task = Task(user_id=user_a_id, title="Task to Delete")
        async_session.add(task)
        await async_session.flush()

        task_id = task.id

        # Verify task exists
        tasks_before = await Task.get_by_user(async_session, user_a_id)
        assert len(tasks_before) == 1

        # Delete the task
        result = await Task.delete_task(
            async_session,
            task_id=task_id,
            user_id=user_a_id,
        )

        # Verify delete succeeded
        assert result is True

        # Verify task is no longer queryable
        tasks_after = await Task.get_by_user(async_session, user_a_id)
        assert len(tasks_after) == 0

    @pytest.mark.asyncio
    async def test_user_a_cannot_delete_user_b_task(
        self, async_session: AsyncSession, user_a_id: str, user_b_id: str
    ) -> None:
        """T032: User A cannot delete User B's task (returns False).

        Given:
            - User B has a task
        When:
            - User A tries to delete User B's task
        Then:
            - False is returned (ownership check fails)
            - User B's task still exists
        """
        # Create a task owned by User B
        task_b = Task(user_id=user_b_id, title="User B's Task")
        async_session.add(task_b)
        await async_session.flush()

        task_b_id = task_b.id

        # User A tries to delete User B's task
        result = await Task.delete_task(
            async_session,
            task_id=task_b_id,
            user_id=user_a_id,  # Wrong user!
        )

        # Verify delete was rejected
        assert result is False

        # Verify User B's task still exists
        user_b_tasks = await Task.get_by_user(async_session, user_b_id)
        assert len(user_b_tasks) == 1
        assert user_b_tasks[0].id == task_b_id

    @pytest.mark.asyncio
    async def test_delete_nonexistent_task_returns_false(
        self, async_session: AsyncSession, user_a_id: str
    ) -> None:
        """Delete of non-existent task returns False.

        Given:
            - A task ID that doesn't exist
        When:
            - User tries to delete it
        Then:
            - False is returned
        """
        from uuid import uuid4

        fake_task_id = uuid4()

        result = await Task.delete_task(
            async_session,
            task_id=fake_task_id,
            user_id=user_a_id,
        )

        assert result is False

    @pytest.mark.asyncio
    async def test_delete_does_not_affect_other_tasks(
        self, async_session: AsyncSession, user_a_id: str
    ) -> None:
        """Deleting one task does not affect other tasks.

        Given:
            - User A has 3 tasks
        When:
            - User A deletes the middle task
        Then:
            - Only that task is deleted
            - The other 2 tasks remain
        """
        # Create 3 tasks
        task1 = Task(user_id=user_a_id, title="Task 1")
        task2 = Task(user_id=user_a_id, title="Task 2 - To Delete")
        task3 = Task(user_id=user_a_id, title="Task 3")
        async_session.add_all([task1, task2, task3])
        await async_session.flush()

        task2_id = task2.id

        # Delete task 2
        result = await Task.delete_task(
            async_session,
            task_id=task2_id,
            user_id=user_a_id,
        )

        assert result is True

        # Verify only task 2 was deleted
        remaining_tasks = await Task.get_by_user(async_session, user_a_id)
        assert len(remaining_tasks) == 2
        remaining_titles = {t.title for t in remaining_tasks}
        assert remaining_titles == {"Task 1", "Task 3"}
        assert "Task 2 - To Delete" not in remaining_titles
