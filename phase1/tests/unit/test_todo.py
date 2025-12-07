"""
Unit tests for the TodoItem model and TodoService methods.
"""
import pytest
from src.models.todo import TodoItem
from src.services.todo_service import TodoService


class TestTodoItem:
    """
    Unit tests for the TodoItem class.
    """

    def test_todo_item_creation_with_all_fields(self):
        """
        Test creating a TodoItem with all fields provided.
        """
        todo = TodoItem(id=1, title="Test Title", description="Test Description", completed=False)

        assert todo.id == 1
        assert todo.title == "Test Title"
        assert todo.description == "Test Description"
        assert todo.completed is False

    def test_todo_item_creation_with_defaults(self):
        """
        Test creating a TodoItem with only required fields (defaults for others).
        """
        todo = TodoItem(id=1, title="Test Title")

        assert todo.id == 1
        assert todo.title == "Test Title"
        assert todo.description == ""
        assert todo.completed is False

    def test_todo_item_str_representation(self):
        """
        Test the string representation of a TodoItem.
        """
        todo = TodoItem(id=1, title="Test Title", description="Test Description", completed=True)
        expected = "[✓] 1. Test Title - Test Description"

        assert str(todo) == expected

    def test_todo_item_str_representation_incomplete(self):
        """
        Test the string representation of an incomplete TodoItem.
        """
        todo = TodoItem(id=1, title="Test Title", description="Test Description", completed=False)
        expected = "[○] 1. Test Title - Test Description"

        assert str(todo) == expected

    def test_todo_item_repr_representation(self):
        """
        Test the developer-friendly representation of a TodoItem.
        """
        todo = TodoItem(id=1, title="Test Title", description="Test Description", completed=True)
        expected = "TodoItem(id=1, title='Test Title', description='Test Description', completed=True)"

        assert repr(todo) == expected

    def test_todo_item_modification(self):
        """
        Test modifying the properties of a TodoItem after creation.
        """
        todo = TodoItem(id=1, title="Original Title", description="Original Description", completed=False)

        # Modify properties
        todo.title = "New Title"
        todo.description = "New Description"
        todo.completed = True

        assert todo.title == "New Title"
        assert todo.description == "New Description"
        assert todo.completed is True


class TestTodoService:
    """
    Unit tests for the TodoService methods.
    """

    def setup_method(self):
        """
        Set up a fresh TodoService instance before each test.
        """
        self.service = TodoService()

    def test_get_all_todos_empty(self):
        """
        Test getting all todos when the list is empty (T008).
        """
        todos = self.service.get_all_todos()

        assert todos == []
        assert len(todos) == 0

    def test_get_all_todos_with_items(self):
        """
        Test getting all todos with multiple items (T008).
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
        Test getting a specific todo by its ID when it exists (T008).
        """
        added_todo = self.service.add_todo("Test Title", "Test Description")

        retrieved_todo = self.service.get_todo_by_id(added_todo.id)

        assert retrieved_todo is not None
        assert retrieved_todo.id == added_todo.id
        assert retrieved_todo.title == added_todo.title
        assert retrieved_todo.description == added_todo.description

    def test_get_todo_by_id_not_found(self):
        """
        Test getting a specific todo by its ID when it doesn't exist (T008).
        """
        result = self.service.get_todo_by_id(999)

        assert result is None

    def test_update_todo_success(self):
        """
        Test updating an existing todo title successfully (T009).
        """
        original_todo = self.service.add_todo("Original Title", "Original Description")

        success = self.service.update_todo(
            todo_id=original_todo.id,
            title="Updated Title"
        )

        assert success is True

        # Verify the update
        updated_todo = self.service.get_todo_by_id(original_todo.id)
        assert updated_todo is not None
        assert updated_todo.title == "Updated Title"
        assert updated_todo.description == "Original Description"

    def test_update_todo_description_success(self):
        """
        Test updating an existing todo description successfully (T009).
        """
        original_todo = self.service.add_todo("Original Title", "Original Description")

        success = self.service.update_todo(
            todo_id=original_todo.id,
            description="Updated Description"
        )

        assert success is True

        # Verify the update
        updated_todo = self.service.get_todo_by_id(original_todo.id)
        assert updated_todo is not None
        assert updated_todo.title == "Original Title"
        assert updated_todo.description == "Updated Description"

    def test_update_todo_not_found(self):
        """
        Test attempting to update a non-existent todo (T009).
        """
        success = self.service.update_todo(
            todo_id=999,
            title="Updated Title"
        )

        assert success is False

    def test_delete_todo_success(self):
        """
        Test deleting an existing todo successfully (T010).
        """
        todo_to_delete = self.service.add_todo("Title to Delete", "Description to Delete")

        success = self.service.delete_todo(todo_to_delete.id)

        assert success is True
        assert self.service.get_todo_by_id(todo_to_delete.id) is None

    def test_delete_todo_not_found(self):
        """
        Test attempting to delete a non-existent todo (T010).
        """
        success = self.service.delete_todo(999)

        assert success is False

    def test_mark_complete_success(self):
        """
        Test marking an incomplete todo as complete (T011).
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
        Test attempting to mark a non-existent todo as complete (T011).
        """
        success = self.service.mark_complete(999)

        assert success is False

    def test_mark_incomplete_success(self):
        """
        Test marking a complete todo as incomplete (T011).
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
        Test attempting to mark a non-existent todo as incomplete (T011).
        """
        success = self.service.mark_incomplete(999)

        assert success is False