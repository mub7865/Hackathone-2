/**
 * Tasks API client
 * Provides typed functions for task CRUD operations
 */



import { apiRequest } from './client';
import type { Task, TaskCreateRequest, TaskUpdateRequest, TaskQueryParams } from '@/types/task';

// API endpoints
const TASKS_ENDPOINT = '/api/v1/tasks';

// Default values for query params (used to omit from URL when unchanged)
const DEFAULT_SORT = 'created_at';
const DEFAULT_ORDER = 'desc';
const DEFAULT_OFFSET = 0;
const DEFAULT_LIMIT = 20;

/**
 * Build query string for task listing, omitting default values
 * Implements FR-018: Default values MUST be omitted from URL to keep it clean
 */
function buildQueryString(params: TaskQueryParams): string {
  const queryParams = new URLSearchParams();

  // Only add status filter if not 'all' (FR-004)
  if (params.status && params.status !== 'all') {
    queryParams.append('status', params.status);
  }

  // Only add search if provided and not empty (FR-005)
  if (params.search && params.search.trim()) {
    queryParams.append('search', params.search.trim());
  }

  // Only add sort if not default (FR-018)
  if (params.sort && params.sort !== DEFAULT_SORT) {
    queryParams.append('sort', params.sort);
  }

  // Only add order if not default (FR-018)
  if (params.order && params.order !== DEFAULT_ORDER) {
    queryParams.append('order', params.order);
  }

  // Only add offset if not default
  if (params.offset !== undefined && params.offset !== DEFAULT_OFFSET) {
    queryParams.append('offset', String(params.offset));
  }

  // Only add limit if not default
  if (params.limit !== undefined && params.limit !== DEFAULT_LIMIT) {
    queryParams.append('limit', String(params.limit));
  }

  return queryParams.toString();
}

/**
 * Fetch list of tasks with optional filtering, search, sort, and pagination
 * Implements FR-020, FR-021, FR-022 for API query params
 */
export async function listTasks(params: TaskQueryParams = {}): Promise<Task[]> {
  const queryString = buildQueryString(params);
  const endpoint = queryString ? `${TASKS_ENDPOINT}?${queryString}` : TASKS_ENDPOINT;

  return apiRequest<Task[]>(endpoint);
}

// Re-export types for convenience
export type { TaskQueryParams };

/**
 * Create a new task
 */
export async function createTask(data: TaskCreateRequest): Promise<Task> {
  return apiRequest<Task>(TASKS_ENDPOINT, {
    method: 'POST',
    body: data,
  });
}

/**
 * Update an existing task
 */
export async function updateTask(id: string, data: TaskUpdateRequest): Promise<Task> {
  return apiRequest<Task>(`${TASKS_ENDPOINT}/${id}`, {
    method: 'PATCH',
    body: data,
  });
}

/**
 * Delete a task
 */
export async function deleteTask(id: string): Promise<void> {
  return apiRequest<void>(`${TASKS_ENDPOINT}/${id}`, {
    method: 'DELETE',
  });
}

/**
 * Get a single task by ID
 */
export async function getTask(id: string): Promise<Task> {
  return apiRequest<Task>(`${TASKS_ENDPOINT}/${id}`);
}
