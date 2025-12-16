'use client';

import { useState, useEffect } from 'react';
import { listTasks } from '@/lib/api/tasks';
import { isAuthError } from '@/lib/api/client';
import type { Task } from '@/types/task';

export interface AllTaskStats {
  pending: number;
  completed: number;
  total: number;
  percentage: number;
  isLoading: boolean;
  error: string | null;
}

/**
 * useAllTaskStats – Fetch ALL tasks and compute statistics
 * Feature: 006-ui-theme-motion (FR-044, SC-013)
 *
 * This hook fetches ALL tasks (not filtered) to compute global stats
 * for the Focus Summary Panel. This ensures stats are accurate
 * regardless of which filter tab is active.
 */
export function useAllTaskStats(refreshTrigger: number = 0): AllTaskStats {
  const [stats, setStats] = useState<AllTaskStats>({
    pending: 0,
    completed: 0,
    total: 0,
    percentage: 0,
    isLoading: true,
    error: null,
  });

  useEffect(() => {
    let cancelled = false;

    const fetchAllTasks = async () => {
      try {
        // Fetch ALL tasks (no status filter = backend returns all)
        // Backend max limit is 100, so we use that
        const allTasks = await listTasks({
          limit: 100,
          offset: 0,
        });

        if (cancelled) return;

        // Compute stats from all tasks
        const pending = allTasks.filter((t: Task) => t.status === 'pending').length;
        const completed = allTasks.filter((t: Task) => t.status === 'completed').length;
        const total = pending + completed;
        const percentage = total === 0 ? 0 : Math.round((completed / total) * 100);

        setStats({
          pending,
          completed,
          total,
          percentage,
          isLoading: false,
          error: null,
        });
      } catch (err) {
        if (cancelled) return;

        // Don't set error for auth errors (will redirect)
        if (isAuthError(err)) {
          return;
        }

        console.error('Failed to fetch task stats:', err);
        setStats(prev => ({
          ...prev,
          isLoading: false,
          error: 'Failed to load task stats',
        }));
      }
    };

    fetchAllTasks();

    return () => {
      cancelled = true;
    };
  }, [refreshTrigger]);

  return stats;
}
