"""
Integration tests for the TodoService.
"""
import pytest
from src.services.todo_service import TodoService
from src.models.todo import TodoItem


class TestTodoService:
    """
    Integration tests for the TodoService class.
    """

    def setup_method(self):
        """
        Set up a fresh TodoService instance before each test.
        """
        self.service = TodoService()

    def test_add_todo_success(self):
        """
        Test adding a todo item successfully.
        """
        title = "Test Title"
        description = "Test Description"

        result = self.service.add_todo(title, description)

        # Verify the returned todo
        assert isinstance(result, TodoItem)
        assert result.id == 1
        assert result.title == title
        assert result.description == description
        assert result.completed is False

        # Verify the todo is stored
        stored_todos = self.service.get_all_todos()
        assert len(stored_todos) == 1
        assert stored_todos[0].id == 1
        assert stored_todos[0].title == title

    def test_add_todo_without_description(self):
        """
        Test adding a todo item with only a title.
        """
        title = "Test Title"

        result = self.service.add_todo(title)

        # Verify the returned todo
        assert isinstance(result, TodoItem)
        assert result.id == 1
        assert result.title == title
        assert result.description == ""
        assert result.completed is False

    def test_add_todo_empty_title_error(self):
        """
        Test that adding a todo with an empty title raises ValueError.
        """
        with pytest.raises(ValueError, match="Title cannot be empty or contain only whitespace"):
            self.service.add_todo("")

    def test_add_todo_whitespace_only_title_error(self):
        """
        Test that adding a todo with a whitespace-only title raises ValueError.
        """
        with pytest.raises(ValueError, match="Title cannot be empty or contain only whitespace"):
            self.service.add_todo("   ")

    def test_add_todo_title_too_long_error(self):
        """
        Test that adding a todo with a title exceeding 100 characters raises ValueError.
        """
        long_title = "a" * 101  # 101 characters

        with pytest.raises(ValueError, match="Title cannot exceed 100 characters"):
            self.service.add_todo(long_title)

    def test_get_all_todos_empty(self):
        """
        Test getting all todos when the list is empty.
        """
        todos = self.service.get_all_todos()

        assert todos == []
        assert len(todos) == 0

    def test_get_all_todos_with_items(self):
        """
        Test getting all todos when the list has items.
        """
        # Add some todos
        self.service.add_todo("Title 1", "Description 1")
        self.service.add_todo("Title 2", "Description 2")

        todos = self.service.get_all_todos()

        assert len(todos) == 2
        assert todos[0].title == "Title 1"
        assert todos[1].title == "Title 2"

    def test_get_todo_by_id_found(self):
        """
        Test getting a specific todo by its ID when it exists.
        """
        added_todo = self.service.add_todo("Test Title", "Test Description")

        retrieved_todo = self.service.get_todo_by_id(added_todo.id)

        assert retrieved_todo is not None
        assert retrieved_todo.id == added_todo.id
        assert retrieved_todo.title == added_todo.title
        assert retrieved_todo.description == added_todo.description

    def test_get_todo_by_id_not_found(self):
        """
        Test getting a specific todo by its ID when it doesn't exist.
        """
        result = self.service.get_todo_by_id(999)

        assert result is None

    def test_update_todo_success(self):
        """
        Test updating an existing todo item.
        """
        original_todo = self.service.add_todo("Original Title", "Original Description")

        success = self.service.update_todo(
            todo_id=original_todo.id,
            title="Updated Title",
            description="Updated Description",
            completed=True
        )

        assert success is True

        # Verify the update
        updated_todo = self.service.get_todo_by_id(original_todo.id)
        assert updated_todo is not None
        assert updated_todo.title == "Updated Title"
        assert updated_todo.description == "Updated Description"
        assert updated_todo.completed is True

    def test_update_todo_not_found(self):
        """
        Test updating a todo that doesn't exist.
        """
        success = self.service.update_todo(
            todo_id=999,
            title="Updated Title"
        )

        assert success is False

    def test_update_todo_empty_title_error(self):
        """
        Test that updating a todo with an empty title raises ValueError.
        """
        original_todo = self.service.add_todo("Original Title", "Original Description")

        with pytest.raises(ValueError, match="Title cannot be empty or contain only whitespace"):
            self.service.update_todo(
                todo_id=original_todo.id,
                title=""
            )

    def test_delete_todo_success(self):
        """
        Test deleting an existing todo.
        """
        todo_to_delete = self.service.add_todo("Title to Delete", "Description to Delete")

        success = self.service.delete_todo(todo_to_delete.id)

        assert success is True
        assert self.service.get_todo_by_id(todo_to_delete.id) is None

    def test_delete_todo_not_found(self):
        """
        Test deleting a todo that doesn't exist.
        """
        success = self.service.delete_todo(999)

        assert success is False

    def test_mark_complete_success(self):
        """
        Test marking a todo as complete.
        """
        todo = self.service.add_todo("Test Title", "Test Description")
        assert todo.completed is False

        success = self.service.mark_complete(todo.id)

        assert success is True
        updated_todo = self.service.get_todo_by_id(todo.id)
        assert updated_todo is not None
        assert updated_todo.completed is True

    def test_mark_complete_not_found(self):
        """
        Test marking a todo as complete when it doesn't exist.
        """
        success = self.service.mark_complete(999)

        assert success is False

    def test_mark_incomplete_success(self):
        """
        Test marking a todo as incomplete.
        """
        todo = self.service.add_todo("Test Title", "Test Description")
        # First mark it complete
        self.service.mark_complete(todo.id)
        assert todo.completed is True

        success = self.service.mark_incomplete(todo.id)

        assert success is True
        updated_todo = self.service.get_todo_by_id(todo.id)
        assert updated_todo is not None
        assert updated_todo.completed is False

    def test_mark_incomplete_not_found(self):
        """
        Test marking a todo as incomplete when it doesn't exist.
        """
        success = self.service.mark_incomplete(999)

        assert success is False