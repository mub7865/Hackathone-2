'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { listTasks, type TaskQueryParams } from '@/lib/api/tasks';
import { isAuthError, getErrorMessage } from '@/lib/api/client';
import { useRouter } from 'next/navigation';
import type { Task, TaskFilter, TaskQueryParams as QueryParams, SortField, SortOrder, HighlightState } from '@/types/task';

const DEFAULT_LIMIT = 20;

export interface UseTasksOptions {
  initialFilter?: TaskFilter;
  initialSearch?: string;
  initialSort?: SortField;
  initialOrder?: SortOrder;
  // Controlled mode - when these change, re-fetch
  filter?: TaskFilter;
  search?: string;
  sort?: SortField;
  order?: SortOrder;
}

export interface UseTasksReturn {
  tasks: Task[];
  filter: TaskFilter;
  search: string;
  sort: SortField;
  order: SortOrder;
  isLoading: boolean;
  isLoadingMore: boolean;
  error: string | null;
  hasMore: boolean;
  highlightedTaskId: string | null;
  setFilter: (filter: TaskFilter) => void;
  setSearch: (search: string) => void;
  setSort: (sort: SortField) => void;
  setOrder: (order: SortOrder) => void;
  setQuery: (params: Partial<QueryParams>) => void;
  loadMore: () => Promise<void>;
  refresh: () => Promise<void>;
  addTask: (task: Task) => void;
  updateTaskInList: (updatedTask: Task) => void;
  removeTask: (taskId: string) => void;
  highlightTask: (taskId: string) => void;
}

/**
 * Hook for fetching and managing task list with filter, search, sort, and pagination
 * Implements Chunk 4 query functionality
 *
 * Supports two modes:
 * 1. Uncontrolled: Use initialFilter/Search/Sort/Order - hook manages state internally
 * 2. Controlled: Pass filter/search/sort/order props - external source of truth (e.g., URL)
 */
export function useTasks({
  initialFilter = 'pending',
  initialSearch = '',
  initialSort = 'created_at',
  initialOrder = 'desc',
  // Controlled props - when provided, these override internal state
  filter: controlledFilter,
  search: controlledSearch,
  sort: controlledSort,
  order: controlledOrder,
}: UseTasksOptions = {}): UseTasksReturn {
  const router = useRouter();
  const [tasks, setTasks] = useState<Task[]>([]);

  // Internal state (used when not controlled)
  const [internalFilter, setFilterState] = useState<TaskFilter>(initialFilter);
  const [internalSearch, setSearchState] = useState<string>(initialSearch);
  const [internalSort, setSortState] = useState<SortField>(initialSort);
  const [internalOrder, setOrderState] = useState<SortOrder>(initialOrder);

  // Use controlled values if provided, otherwise use internal state
  const filter = controlledFilter ?? internalFilter;
  const search = controlledSearch ?? internalSearch;
  const sort = controlledSort ?? internalSort;
  const order = controlledOrder ?? internalOrder;

  const [isLoading, setIsLoading] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [offset, setOffset] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [highlight, setHighlight] = useState<HighlightState>({ taskId: null, expiresAt: 0 });

  // Track if component is mounted
  const isMounted = useRef(true);

  useEffect(() => {
    isMounted.current = true;
    return () => {
      isMounted.current = false;
    };
  }, []);

  // Compute highlighted task ID
  const highlightedTaskId =
    highlight.taskId && Date.now() < highlight.expiresAt ? highlight.taskId : null;

  /**
   * Fetch tasks from API
   */
  const fetchTasks = useCallback(
    async (params: TaskQueryParams & { append?: boolean } = {}) => {
      const { append = false, ...apiParams } = params;

      try {
        if (append) {
          setIsLoadingMore(true);
        } else {
          setIsLoading(true);
          setError(null);
        }

        const fetchedTasks = await listTasks(apiParams);

        if (!isMounted.current) return;

        if (append) {
          setTasks((prev) => [...prev, ...fetchedTasks]);
        } else {
          setTasks(fetchedTasks);
        }

        // Check if there are more tasks to load (FR-014: results.length === limit means has more)
        setHasMore(fetchedTasks.length === (apiParams.limit || DEFAULT_LIMIT));
        setOffset((apiParams.offset || 0) + fetchedTasks.length);
      } catch (err) {
        if (!isMounted.current) return;

        // Handle auth errors by redirecting to login
        if (isAuthError(err)) {
          const currentPath = window.location.pathname;
          router.push(`/login?redirect=${encodeURIComponent(currentPath)}`);
          return;
        }

        setError(getErrorMessage(err));
      } finally {
        if (isMounted.current) {
          setIsLoading(false);
          setIsLoadingMore(false);
        }
      }
    },
    [router]
  );

  /**
   * Initial fetch and query change handler
   * Re-fetches when filter, search, sort, or order changes
   */
  useEffect(() => {
    setOffset(0);
    setHasMore(true);
    fetchTasks({
      status: filter,
      search: search || undefined,
      sort,
      order,
      offset: 0,
      limit: DEFAULT_LIMIT,
    });
  }, [filter, search, sort, order, fetchTasks]);

  /**
   * Set filter and reset pagination
   */
  const setFilter = useCallback((newFilter: TaskFilter) => {
    setFilterState(newFilter);
  }, []);

  /**
   * Set search term
   */
  const setSearch = useCallback((newSearch: string) => {
    setSearchState(newSearch);
  }, []);

  /**
   * Set sort field
   */
  const setSort = useCallback((newSort: SortField) => {
    setSortState(newSort);
  }, []);

  /**
   * Set sort order
   */
  const setOrder = useCallback((newOrder: SortOrder) => {
    setOrderState(newOrder);
  }, []);

  /**
   * Set multiple query params at once (useful for URL state sync)
   */
  const setQuery = useCallback((params: Partial<QueryParams>) => {
    if (params.status !== undefined) setFilterState(params.status);
    if (params.search !== undefined) setSearchState(params.search);
    if (params.sort !== undefined) setSortState(params.sort);
    if (params.order !== undefined) setOrderState(params.order);
  }, []);

  /**
   * Load more tasks (pagination)
   */
  const loadMore = useCallback(async () => {
    if (isLoadingMore || !hasMore) return;

    await fetchTasks({
      status: filter,
      search: search || undefined,
      sort,
      order,
      offset,
      limit: DEFAULT_LIMIT,
      append: true,
    });
  }, [fetchTasks, filter, search, sort, order, offset, isLoadingMore, hasMore]);

  /**
   * Refresh task list
   */
  const refresh = useCallback(async () => {
    setOffset(0);
    setHasMore(true);
    await fetchTasks({
      status: filter,
      search: search || undefined,
      sort,
      order,
      offset: 0,
      limit: DEFAULT_LIMIT,
    });
  }, [fetchTasks, filter, search, sort, order]);

  /**
   * Add a new task to the top of the list
   */
  const addTask = useCallback(
    (task: Task) => {
      // Only add if task matches current filter
      const matchesFilter =
        filter === 'all' ||
        (filter === 'pending' && task.status === 'pending') ||
        (filter === 'completed' && task.status === 'completed');

      if (matchesFilter) {
        setTasks((prev) => [task, ...prev]);
      }
    },
    [filter]
  );

  /**
   * Update a task in the list
   */
  const updateTaskInList = useCallback(
    (updatedTask: Task) => {
      // Check if task matches current filter
      const matchesFilter =
        filter === 'all' ||
        (filter === 'pending' && updatedTask.status === 'pending') ||
        (filter === 'completed' && updatedTask.status === 'completed');

      setTasks((prev) => {
        if (matchesFilter) {
          // Update the task in place
          return prev.map((task) => (task.id === updatedTask.id ? updatedTask : task));
        } else {
          // Remove the task from the list (filtered out)
          return prev.filter((task) => task.id !== updatedTask.id);
        }
      });
    },
    [filter]
  );

  /**
   * Remove a task from the list
   */
  const removeTask = useCallback((taskId: string) => {
    setTasks((prev) => prev.filter((task) => task.id !== taskId));
  }, []);

  /**
   * Highlight a task temporarily (for newly created tasks)
   */
  const highlightTask = useCallback((taskId: string) => {
    setHighlight({
      taskId,
      expiresAt: Date.now() + 3000, // 3 seconds highlight
    });

    // Clear highlight after expiry
    setTimeout(() => {
      setHighlight((prev) => (prev.taskId === taskId ? { taskId: null, expiresAt: 0 } : prev));
    }, 3000);
  }, []);

  return {
    tasks,
    filter,
    search,
    sort,
    order,
    isLoading,
    isLoadingMore,
    error,
    hasMore,
    highlightedTaskId,
    setFilter,
    setSearch,
    setSort,
    setOrder,
    setQuery,
    loadMore,
    refresh,
    addTask,
    updateTaskInList,
    removeTask,
    highlightTask,
  };
}
