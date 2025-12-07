"""
TodoItem model representing a single todo task.
"""
from typing import Optional


class TodoItem:
    """
    Represents a single todo item with an ID, title, description, and completion status.
    """

    def __init__(self, id: int, title: str, description: str = "", completed: bool = False):
        """
        Initialize a TodoItem instance.

        Args:
            id: Unique identifier for the todo item
            title: Title of the todo item (required)
            description: Optional description of the todo item
            completed: Completion status (default: False)
        """
        # Validate title during initialization
        self.validate_title(title)

        self.id = id
        self.title = title
        self.description = description
        self.completed = completed

    @staticmethod
    def validate_title(title: str) -> None:
        """
        Validate the title according to business rules.

        Args:
            title: The title to validate

        Raises:
            ValueError: If title is empty, contains only whitespace, or exceeds length limit
        """
        if not title or title.strip() == "":
            raise ValueError("Title cannot be empty or contain only whitespace")

        if len(title) > 100:
            raise ValueError("Title cannot exceed 100 characters")

    def update_title(self, new_title: str) -> None:
        """
        Update the title after validation.

        Args:
            new_title: The new title to set

        Raises:
            ValueError: If the new title is invalid
        """
        self.validate_title(new_title)
        self.title = new_title

    def __str__(self) -> str:
        """
        String representation of the TodoItem.

        Returns:
            Formatted string showing the todo item details
        """
        status = "✓" if self.completed else "○"
        return f"[{status}] {self.id}. {self.title} - {self.description}"

    def __repr__(self) -> str:
        """
        Developer-friendly representation of the TodoItem.

        Returns:
            String representation suitable for debugging
        """
        return f"TodoItem(id={self.id}, title='{self.title}', description='{self.description}', completed={self.completed})"