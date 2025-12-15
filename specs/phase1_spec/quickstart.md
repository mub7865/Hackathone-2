# Quickstart: Todo Operations (View, Update, Delete, Mark Complete)

## Running the Application

1. Navigate to the project root directory
2. Run the main application:
   ```bash
   python src/cli/main.py
   ```

## Using Todo Operations

### Viewing Todos
1. Launch the application
2. Select "View Todos" from the main menu (option 2)
3. All todos will be displayed with ID, title, description, and completion status

### Updating a Todo
1. Select "Update Todo" from the main menu (option 3)
2. Enter the ID of the todo you want to update
3. Enter the new title (or press Enter to keep the current title)
4. Enter the new description (or press Enter to keep the current description)

### Deleting a Todo
1. Select "Delete Todo" from the main menu (option 4)
2. Enter the ID of the todo you want to delete
3. The system will confirm the deletion

### Marking Todo Complete
1. Select "Mark Todo Complete" from the main menu (option 5)
2. Enter the ID of the todo you want to mark complete
3. The system will confirm the status change

### Marking Todo Incomplete
1. Select "Mark Todo Incomplete" from the main menu (option 6)
2. Enter the ID of the todo you want to mark incomplete
3. The system will confirm the status change

## Example Usage

```
Welcome to the Todo App!
1. Add Todo
2. View Todos
3. Update Todo
4. Delete Todo
5. Mark Todo Complete
6. Mark Todo Incomplete
7. Exit

Enter your choice: 2
Your Todo List:
[○] 1. Buy groceries - Milk, bread, eggs
[✓] 2. Complete project - Final implementation
```

## Development Setup

1. Ensure Python 3.13+ is installed
2. No additional dependencies required (using standard library only)
3. Run tests with: `pytest tests/`

## Testing the Todo Operations

Run the unit tests:
```bash
pytest tests/unit/test_todo.py
```

Run the integration tests:
```bash
pytest tests/integration/test_todo_service.py
```