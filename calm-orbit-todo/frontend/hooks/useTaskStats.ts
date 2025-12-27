import { useMemo } from 'react';
import type { Task } from '@/types/task';

export interface TaskStats {
  pending: number;
  completed: number;
  total: number;
  percentage: number;
}

/**
 * useTaskStats – Compute task statistics from task list
 * Feature: 006-ui-theme-motion (FR-044, SC-013)
 *
 * - Computes pending, completed, total counts
 * - Calculates completion percentage (0-100, rounded)
 * - Memoized for performance
 * - Stats computed from ALL current tasks (no date filtering)
 */
export function useTaskStats(tasks: Task[]): TaskStats {
  return useMemo(() => {
    const pending = tasks.filter((t) => t.status === 'pending').length;
    const completed = tasks.filter((t) => t.status === 'completed').length;
    const total = pending + completed;
    const percentage = total === 0 ? 0 : Math.round((completed / total) * 100);

    return { pending, completed, total, percentage };
  }, [tasks]);
}
