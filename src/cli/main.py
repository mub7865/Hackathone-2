"""
Main CLI interface for the Todo application.
"""
from src.services.todo_service import TodoService


class TodoCLI:
    """
    Command-line interface for the Todo application.
    """

    def __init__(self):
        """
        Initialize the CLI with a TodoService instance.
        """
        self.service = TodoService()

    def display_menu(self):
        """o
        Display the main menu options.
        """
        print("\n" + "="*40)
        print("Welcome to the Todo App!")
        print("="*40)
        print("1. Add Todo")
        print("2. View Todos")
        print("3. Update Todo")
        print("4. Delete Todo")
        print("5. Mark Todo Complete")
        print("6. Mark Todo Incomplete")
        print("7. Exit")
        print("="*40)

    def get_user_choice(self) -> str:
        """
        Get user's menu choice.

        Returns:
            User's choice as a string
        """
        return input("Enter your choice (1-7): ").strip()

    def add_todo(self):
        """
        Handle adding a new todo item.
        """
        try:
            title = input("Enter title: ").strip()
            description = input("Enter description (optional): ").strip()

            todo = self.service.add_todo(title, description)
            print(f"Todo added successfully with ID: {todo.id}")
        except ValueError as e:
            print(f"Error: {e}")

    def view_todos(self):
        """
        Display all todo items.
        """
        todos = self.service.get_all_todos()
        if not todos:
            print("No todos found.")
            return

        print("\nYour Todo List:")
        for todo in todos:
            status = "✓" if todo.completed else "○"
            print(f"[{status}] {todo.id}. {todo.title} - {todo.description}")

    def update_todo(self):
        """
        Handle updating an existing todo item.
        """
        try:
            todo_id = int(input("Enter ID of the todo to update: "))
        except ValueError:
            print("Error: Please enter a valid ID number.")
            return

        # Get current todo to display current values
        current_todo = self.service.get_todo_by_id(todo_id)
        if not current_todo:
            print(f"Error: Todo with ID {todo_id} not found.")
            return

        print(f"Current values - Title: {current_todo.title}, Description: {current_todo.description}")

        new_title = input(f"Enter new title (current: '{current_todo.title}', press Enter to keep current): ").strip()
        if new_title == "":
            new_title = None

        new_description = input(f"Enter new description (current: '{current_todo.description}', press Enter to keep current): ").strip()
        if new_description == "":
            new_description = None

        try:
            success = self.service.update_todo(
                todo_id,
                title=new_title if new_title is not None else current_todo.title,
                description=new_description if new_description is not None else current_todo.description
            )
            if success:
                print("Todo updated successfully.")
            else:
                print("Error updating todo.")
        except ValueError as e:
            print(f"Error: {e}")

    def delete_todo(self):
        """
        Handle deleting a todo item.
        """
        try:
            todo_id = int(input("Enter ID of the todo to delete: "))
        except ValueError:
            print("Error: Please enter a valid ID number.")
            return

        success = self.service.delete_todo(todo_id)
        if success:
            print("Todo deleted successfully.")
        else:
            print(f"Error: Todo with ID {todo_id} not found.")

    def mark_complete(self):
        """
        Handle marking a todo item as complete.
        """
        try:
            todo_id = int(input("Enter ID of the todo to mark complete: "))
        except ValueError:
            print("Error: Please enter a valid ID number.")
            return

        success = self.service.mark_complete(todo_id)
        if success:
            print("Todo marked as complete.")
        else:
            print(f"Error: Todo with ID {todo_id} not found.")

    def mark_incomplete(self):
        """
        Handle marking a todo item as incomplete.
        """
        try:
            todo_id = int(input("Enter ID of the todo to mark incomplete: "))
        except ValueError:
            print("Error: Please enter a valid ID number.")
            return

        success = self.service.mark_incomplete(todo_id)
        if success:
            print("Todo marked as incomplete.")
        else:
            print(f"Error: Todo with ID {todo_id} not found.")

    def run(self):
        """
        Run the main application loop.
        """
        while True:
            self.display_menu()
            choice = self.get_user_choice()

            if choice == "1":
                self.add_todo()
            elif choice == "2":
                self.view_todos()
            elif choice == "3":
                self.update_todo()
            elif choice == "4":
                self.delete_todo()
            elif choice == "5":
                self.mark_complete()
            elif choice == "6":
                self.mark_incomplete()
            elif choice == "7":
                print("Thank you for using the Todo App. Goodbye!")
                break
            else:
                print("Invalid choice. Please enter a number between 1 and 7.")

            input("\nPress Enter to continue...")


def main():
    """
    Main function to start the application.
    """
    app = TodoCLI()
    app.run()


if __name__ == "__main__":
    main()