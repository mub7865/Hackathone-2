/**
 * Task-related TypeScript types
 * Mirrors backend Pydantic schemas from 003-tasks-crud-api
 */

// Task status enum
export type TaskStatus = 'pending' | 'completed';

// Task filter options for list view
export type TaskFilter = 'all' | 'pending' | 'completed';

// Sort field options (matches backend SortField enum)
export type SortField = 'created_at' | 'title';

// Sort order options (matches backend SortOrder enum)
export type SortOrder = 'asc' | 'desc';

// Query parameters for task listing (Chunk 4)
export interface TaskQueryParams {
  status?: TaskFilter;
  search?: string;
  sort?: SortField;
  order?: SortOrder;
  offset?: number;
  limit?: number;
}

// Task entity (matches backend TaskResponse schema)
export interface Task {
  id: string;
  user_id: string;
  title: string;
  description: string | null;
  status: TaskStatus;
  created_at: string;
  updated_at: string;
}

// POST /api/v1/tasks request body
export interface TaskCreateRequest {
  title: string;
  description?: string | null;
}

// PATCH /api/v1/tasks/{id} request body
export interface TaskUpdateRequest {
  title?: string;
  description?: string | null;
  status?: TaskStatus;
}

// Pagination state for task list
export interface PaginationState {
  offset: number;
  limit: number;
  hasMore: boolean;
}

// Task list state
export interface TaskListState {
  tasks: Task[];
  filter: TaskFilter;
  pagination: PaginationState;
  isLoading: boolean;
  error: string | null;
}

// Form validation errors
export interface TaskFormErrors {
  title?: string;
  description?: string;
  general?: string;
}

// Task form state
export interface TaskFormState {
  title: string;
  description: string;
  status?: TaskStatus;
  errors: TaskFormErrors;
  isSubmitting: boolean;
}

// Modal types
export type ModalType = 'create' | 'edit' | 'delete' | null;

// Modal state
export interface ModalState {
  type: ModalType;
  taskId?: string;
  isOpen: boolean;
}

// Toast message
export interface ToastMessage {
  id: string;
  type: 'success' | 'error' | 'info';
  message: string;
}

// Highlight state for newly created tasks
export interface HighlightState {
  taskId: string | null;
  expiresAt: number;
}
