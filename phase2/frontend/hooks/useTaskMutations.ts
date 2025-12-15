'use client';

import { useState, useCallback } from 'react';
import { createTask, updateTask, deleteTask } from '@/lib/api/tasks';
import { extractFieldErrors, getErrorMessage, isAuthError, isValidationApiError } from '@/lib/api/client';
import { ApiError } from '@/types/api';
import { useRouter } from 'next/navigation';
import type { Task, TaskCreateRequest, TaskUpdateRequest, TaskFormErrors } from '@/types/task';

export interface UseTaskMutationsReturn {
  // Create
  isCreating: boolean;
  createErrors: TaskFormErrors;
  handleCreate: (data: TaskCreateRequest) => Promise<Task | null>;
  clearCreateErrors: () => void;

  // Update
  isUpdating: boolean;
  updateErrors: TaskFormErrors;
  handleUpdate: (id: string, data: TaskUpdateRequest) => Promise<Task | null>;
  clearUpdateErrors: () => void;

  // Delete
  isDeleting: boolean;
  deleteError: string | null;
  handleDelete: (id: string) => Promise<boolean>;
  clearDeleteError: () => void;

  // Toggle status
  togglingTaskId: string | null;
  handleToggleStatus: (task: Task) => Promise<Task | null>;
}

/**
 * Hook for task mutation operations with loading and error states
 */
export function useTaskMutations(): UseTaskMutationsReturn {
  const router = useRouter();

  // Create state
  const [isCreating, setIsCreating] = useState(false);
  const [createErrors, setCreateErrors] = useState<TaskFormErrors>({});

  // Update state
  const [isUpdating, setIsUpdating] = useState(false);
  const [updateErrors, setUpdateErrors] = useState<TaskFormErrors>({});

  // Delete state
  const [isDeleting, setIsDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  // Toggle status state
  const [togglingTaskId, setTogglingTaskId] = useState<string | null>(null);

  /**
   * Handle auth errors by redirecting to login
   */
  const handleAuthError = useCallback(() => {
    const currentPath = window.location.pathname;
    router.push(`/login?redirect=${encodeURIComponent(currentPath)}`);
  }, [router]);

  /**
   * Create a new task
   */
  const handleCreate = useCallback(
    async (data: TaskCreateRequest): Promise<Task | null> => {
      setIsCreating(true);
      setCreateErrors({});

      try {
        const task = await createTask(data);
        return task;
      } catch (err) {
        if (isAuthError(err)) {
          handleAuthError();
          return null;
        }

        if (isValidationApiError(err) && err instanceof ApiError) {
          const fieldErrors = extractFieldErrors(err);
          setCreateErrors(fieldErrors);
        } else {
          setCreateErrors({ general: getErrorMessage(err) });
        }

        return null;
      } finally {
        setIsCreating(false);
      }
    },
    [handleAuthError]
  );

  /**
   * Clear create errors
   */
  const clearCreateErrors = useCallback(() => {
    setCreateErrors({});
  }, []);

  /**
   * Update an existing task
   */
  const handleUpdate = useCallback(
    async (id: string, data: TaskUpdateRequest): Promise<Task | null> => {
      setIsUpdating(true);
      setUpdateErrors({});

      try {
        const task = await updateTask(id, data);
        return task;
      } catch (err) {
        if (isAuthError(err)) {
          handleAuthError();
          return null;
        }

        if (isValidationApiError(err) && err instanceof ApiError) {
          const fieldErrors = extractFieldErrors(err);
          setUpdateErrors(fieldErrors);
        } else {
          setUpdateErrors({ general: getErrorMessage(err) });
        }

        return null;
      } finally {
        setIsUpdating(false);
      }
    },
    [handleAuthError]
  );

  /**
   * Clear update errors
   */
  const clearUpdateErrors = useCallback(() => {
    setUpdateErrors({});
  }, []);

  /**
   * Delete a task
   */
  const handleDelete = useCallback(
    async (id: string): Promise<boolean> => {
      setIsDeleting(true);
      setDeleteError(null);

      try {
        await deleteTask(id);
        return true;
      } catch (err) {
        if (isAuthError(err)) {
          handleAuthError();
          return false;
        }

        setDeleteError(getErrorMessage(err));
        return false;
      } finally {
        setIsDeleting(false);
      }
    },
    [handleAuthError]
  );

  /**
   * Clear delete error
   */
  const clearDeleteError = useCallback(() => {
    setDeleteError(null);
  }, []);

  /**
   * Toggle task status (complete/uncomplete)
   */
  const handleToggleStatus = useCallback(
    async (task: Task): Promise<Task | null> => {
      setTogglingTaskId(task.id);

      try {
        const newStatus = task.status === 'pending' ? 'completed' : 'pending';
        const updatedTask = await updateTask(task.id, { status: newStatus });
        return updatedTask;
      } catch (err) {
        if (isAuthError(err)) {
          handleAuthError();
        }
        return null;
      } finally {
        setTogglingTaskId(null);
      }
    },
    [handleAuthError]
  );

  return {
    // Create
    isCreating,
    createErrors,
    handleCreate,
    clearCreateErrors,

    // Update
    isUpdating,
    updateErrors,
    handleUpdate,
    clearUpdateErrors,

    // Delete
    isDeleting,
    deleteError,
    handleDelete,
    clearDeleteError,

    // Toggle status
    togglingTaskId,
    handleToggleStatus,
  };
}
