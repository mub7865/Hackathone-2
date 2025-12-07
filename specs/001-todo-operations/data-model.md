# Data Model: Todo Operations (View, Update, Delete, Mark Complete)

## Entity: TodoItem (Extended)

### Fields
- **id**: Integer - Unique identifier for the todo item (auto-generated)
- **title**: String - The title of the todo item (required, non-empty)
- **description**: String - Optional description of the todo item (can be empty)
- **completed**: Boolean - Completion status of the todo item (default: False)

### Validation Rules
- Title must not be empty or contain only whitespace
- ID must be unique within the current session
- Title should be less than 100 characters (for UI readability)

### State Transitions
- New TodoItem: `completed = False` (default)
- After marking complete: `completed = True`
- After marking incomplete: `completed = False`
- After update: Specific fields change while others remain unchanged

### Relationships
- None (standalone entity for this feature)

## Storage Model: TodoList (Extended)
- **todos**: List[TodoItem] - Collection of all todo items in the current session
- **next_id**: Integer - Counter for generating unique IDs (starts at 1, increments)

## Operations Added
- **View**: Retrieve all todos or a specific todo by ID
- **Update**: Modify specific fields of an existing todo
- **Delete**: Remove a todo from the collection
- **Mark Complete/Incomplete**: Toggle the completion status of a todo