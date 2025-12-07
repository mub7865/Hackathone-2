"""
TodoService handles the business logic for todo operations.
"""
from typing import List, Optional
from src.models.todo import TodoItem


class TodoService:
    """
    Service class for managing todo items with in-memory storage.
    """

    def __init__(self):
        """
        Initialize the TodoService with empty storage and ID counter.
        """
        self.todos: List[TodoItem] = []
        self.next_id: int = 1

    def add_todo(self, title: str, description: str = "") -> TodoItem:
        """
        Add a new todo item to the in-memory storage.

        Args:
            title: Title of the todo item (required)
            description: Optional description of the todo item

        Returns:
            The created TodoItem instance

        Raises:
            ValueError: If title is invalid according to business rules
        """
        # The TodoItem constructor will validate the title
        todo = TodoItem(id=self.next_id, title=title.strip(), description=description.strip())
        self.todos.append(todo)
        self.next_id += 1
        return todo

    def get_all_todos(self) -> List[TodoItem]:
        """
        Get all todo items from storage.

        Returns:
            List of all TodoItem instances
        """
        return self.todos.copy()

    def get_todo_by_id(self, todo_id: int) -> Optional[TodoItem]:
        """
        Get a specific todo item by its ID.

        Args:
            todo_id: ID of the todo item to retrieve

        Returns:
            TodoItem instance if found, None otherwise
        """
        for todo in self.todos:
            if todo.id == todo_id:
                return todo
        return None

    def update_todo(self, todo_id: int, title: Optional[str] = None,
                   description: Optional[str] = None, completed: Optional[bool] = None) -> bool:
        """
        Update an existing todo item.

        Args:
            todo_id: ID of the todo item to update
            title: New title (optional)
            description: New description (optional)
            completed: New completion status (optional)

        Returns:
            True if the todo was updated, False if not found
        """
        todo = self.get_todo_by_id(todo_id)
        if not todo:
            return False

        if title is not None:
            # Use the TodoItem validation
            todo.update_title(title.strip())

        if description is not None:
            todo.description = description.strip()

        if completed is not None:
            todo.completed = completed

        return True

    def delete_todo(self, todo_id: int) -> bool:
        """
        Delete a todo item by its ID.

        Args:
            todo_id: ID of the todo item to delete

        Returns:
            True if the todo was deleted, False if not found
        """
        todo = self.get_todo_by_id(todo_id)
        if not todo:
            return False

        self.todos.remove(todo)
        return True

    def mark_complete(self, todo_id: int) -> bool:
        """
        Mark a todo item as complete.

        Args:
            todo_id: ID of the todo item to mark complete

        Returns:
            True if the todo was marked complete, False if not found
        """
        todo = self.get_todo_by_id(todo_id)
        if not todo:
            return False

        todo.completed = True
        return True

    def mark_incomplete(self, todo_id: int) -> bool:
        """
        Mark a todo item as incomplete.

        Args:
            todo_id: ID of the todo item to mark incomplete

        Returns:
            True if the todo was marked incomplete, False if not found
        """
        todo = self.get_todo_by_id(todo_id)
        if not todo:
            return False

        todo.completed = False
        return True