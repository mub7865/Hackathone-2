# Data Model: Tasks CRUD UX (Web App)

**Feature**: 004-tasks-crud-ux
**Date**: 2025-12-13
**Purpose**: Define frontend TypeScript types and state shapes

---

## Backend Types (Mirror from API)

These types match the backend Pydantic schemas from `003-tasks-crud-api`.

### Task Entity

```typescript
// Types matching backend TaskResponse schema
type TaskStatus = 'pending' | 'completed';

interface Task {
  id: string;           // UUID
  user_id: string;      // Owner's user ID
  title: string;        // 1-255 characters
  description: string | null;
  status: TaskStatus;
  created_at: string;   // ISO 8601 datetime
  updated_at: string;   // ISO 8601 datetime
}
```

### API Request Types

```typescript
// POST /api/v1/tasks
interface TaskCreateRequest {
  title: string;              // Required, 1-255 chars
  description?: string | null;
}

// PATCH /api/v1/tasks/{id}
interface TaskUpdateRequest {
  title?: string;             // Optional, 1-255 chars if provided
  description?: string | null;
  status?: TaskStatus;
}
```

### API Response Types

```typescript
// GET /api/v1/tasks - returns array
type TaskListResponse = Task[];

// POST, GET single, PATCH - returns single task
type TaskResponse = Task;

// DELETE - returns 204 No Content (empty body)
```

### API Error Types

```typescript
// RFC 7807 Problem Details
interface ProblemDetail {
  type: string;       // URI, default "about:blank"
  title: string;      // Short summary
  status: number;     // HTTP status code
  detail?: string;    // Detailed explanation
  instance?: string;  // Request path
}

// 422 Validation Error extension
interface ValidationError extends ProblemDetail {
  errors: Array<{
    loc: (string | number)[];
    msg: string;
    type: string;
  }>;
}
```

---

## Frontend State Types

### Filter State

```typescript
type TaskFilter = 'all' | 'pending' | 'completed';

interface TaskFilterState {
  status: TaskFilter;  // Current filter selection
}
```

### Pagination State

```typescript
interface PaginationState {
  offset: number;      // Current offset (0-based)
  limit: number;       // Items per page (default 20)
  hasMore: boolean;    // Whether more items exist
}
```

### Task List State

```typescript
interface TaskListState {
  tasks: Task[];
  filter: TaskFilter;
  pagination: PaginationState;
  isLoading: boolean;
  error: string | null;
}
```

### Form State

```typescript
interface TaskFormState {
  title: string;
  description: string;
  status?: TaskStatus;     // Only for edit form
  errors: {
    title?: string;
    description?: string;
    general?: string;
  };
  isSubmitting: boolean;
}

// For edit form - track original values for reset
interface TaskEditState extends TaskFormState {
  originalTask: Task;
}
```

### Modal State

```typescript
type ModalType = 'create' | 'edit' | 'delete' | null;

interface ModalState {
  type: ModalType;
  taskId?: string;        // For edit/delete modals
  isOpen: boolean;
}
```

### UI Feedback State

```typescript
interface ToastMessage {
  id: string;
  type: 'success' | 'error' | 'info';
  message: string;
}

// Track newly created task for highlight effect
interface HighlightState {
  taskId: string | null;
  expiresAt: number;      // Timestamp when highlight should end
}
```

---

## State Transitions

### Task Status Transitions

```
[pending] --complete--> [completed]
[completed] --uncomplete--> [pending]
```

### Modal Flow States

```
[closed] --"Add Task"--> [create open]
[closed] --"Edit"--> [edit open]
[closed] --"Delete"--> [delete confirm open]

[create open] --submit success--> [closed] + refresh list
[create open] --submit error--> [create open] + show error
[create open] --close/cancel--> [closed]

[edit open] --submit success--> [closed] + refresh list
[edit open] --submit error--> [edit open] + show error
[edit open] --close/cancel--> [closed]

[delete confirm] --confirm--> [closed] + refresh list
[delete confirm] --cancel--> [closed]
```

### Filter Transitions

```
[all] --click "Pending"--> [pending] + reset pagination + fetch
[all] --click "Completed"--> [completed] + reset pagination + fetch
[pending] --click "All"--> [all] + reset pagination + fetch
[pending] --click "Completed"--> [completed] + reset pagination + fetch
[completed] --click "All"--> [all] + reset pagination + fetch
[completed] --click "Pending"--> [pending] + reset pagination + fetch
```

---

## Validation Rules

### Title Field
- Required: Cannot be empty
- Max length: 255 characters
- Min length: 1 character (no whitespace-only)
- Frontend: Prevent input beyond 255 chars
- Frontend: Show character counter

### Description Field
- Optional: Can be null/empty
- No length limit in spec (backend may have one)

### Status Field
- Enum: 'pending' | 'completed'
- Default on create: 'pending' (set by backend)
- Editable: Yes, in edit form

---

## URL State Mapping

```
/tasks                    → filter: 'pending' (default)
/tasks?status=all         → filter: 'all'
/tasks?status=pending     → filter: 'pending'
/tasks?status=completed   → filter: 'completed'
```

Note: Pagination offset not in URL (reset on filter change, maintained in component state)
