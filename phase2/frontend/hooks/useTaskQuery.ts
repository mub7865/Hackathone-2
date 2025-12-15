'use client';

import { useCallback, useMemo } from 'react';
import { useSearchParams, useRouter, usePathname } from 'next/navigation';
import type { TaskFilter, SortField, SortOrder } from '@/types/task';

// Default values (used for URL omission and fallback)
const DEFAULTS = {
  status: 'pending' as TaskFilter,
  sort: 'created_at' as SortField,
  order: 'desc' as SortOrder,
  search: '',
} as const;

// Valid values for validation
const VALID_STATUS: TaskFilter[] = ['all', 'pending', 'completed'];
const VALID_SORT: SortField[] = ['created_at', 'title'];
const VALID_ORDER: SortOrder[] = ['asc', 'desc'];

export interface TaskQueryState {
  status: TaskFilter;
  search: string;
  sort: SortField;
  order: SortOrder;
}

export interface UseTaskQueryReturn {
  query: TaskQueryState;
  setStatus: (status: TaskFilter) => void;
  setSearch: (search: string) => void;
  setSort: (sort: SortField) => void;
  setOrder: (order: SortOrder) => void;
  setSortAndOrder: (sort: SortField, order: SortOrder) => void;
  setQuery: (params: Partial<TaskQueryState>) => void;
  resetQuery: () => void;
}

/**
 * Validate and parse status from URL
 */
function parseStatus(value: string | null): TaskFilter {
  if (value && VALID_STATUS.includes(value as TaskFilter)) {
    return value as TaskFilter;
  }
  return DEFAULTS.status;
}

/**
 * Validate and parse sort field from URL
 */
function parseSort(value: string | null): SortField {
  if (value && VALID_SORT.includes(value as SortField)) {
    return value as SortField;
  }
  return DEFAULTS.sort;
}

/**
 * Validate and parse sort order from URL
 */
function parseOrder(value: string | null): SortOrder {
  if (value && VALID_ORDER.includes(value as SortOrder)) {
    return value as SortOrder;
  }
  return DEFAULTS.order;
}

/**
 * Validate and parse search from URL
 * Implements FR-006: max 100 chars
 */
function parseSearch(value: string | null): string {
  if (value) {
    // Truncate to 100 chars if needed
    return value.slice(0, 100);
  }
  return DEFAULTS.search;
}

/**
 * Hook for managing task query state with URL synchronization
 * Implements FR-016, FR-017, FR-018, FR-019 for URL state management
 */
export function useTaskQuery(): UseTaskQueryReturn {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  // Parse query state from URL (FR-017: restore from URL)
  // Uses defaults for invalid values (FR-019)
  const query = useMemo<TaskQueryState>(() => ({
    status: parseStatus(searchParams.get('status')),
    search: parseSearch(searchParams.get('search')),
    sort: parseSort(searchParams.get('sort')),
    order: parseOrder(searchParams.get('order')),
  }), [searchParams]);

  /**
   * Build URL with updated params, omitting defaults (FR-018)
   */
  const buildUrl = useCallback((newState: TaskQueryState): string => {
    const params = new URLSearchParams();

    // Only add non-default values (FR-018)
    if (newState.status !== DEFAULTS.status) {
      params.set('status', newState.status);
    }
    if (newState.search && newState.search.trim()) {
      params.set('search', newState.search.trim());
    }
    if (newState.sort !== DEFAULTS.sort) {
      params.set('sort', newState.sort);
    }
    if (newState.order !== DEFAULTS.order) {
      params.set('order', newState.order);
    }

    const queryString = params.toString();
    return queryString ? `${pathname}?${queryString}` : pathname;
  }, [pathname]);

  /**
   * Update URL without page navigation (FR-016)
   */
  const updateUrl = useCallback((newState: TaskQueryState) => {
    const newUrl = buildUrl(newState);
    router.replace(newUrl, { scroll: false });
  }, [buildUrl, router]);

  /**
   * Set status filter
   */
  const setStatus = useCallback((status: TaskFilter) => {
    const newState = { ...query, status };
    updateUrl(newState);
  }, [query, updateUrl]);

  /**
   * Set search term (FR-006: max 100 chars enforced)
   */
  const setSearch = useCallback((search: string) => {
    const newState = { ...query, search: search.slice(0, 100) };
    updateUrl(newState);
  }, [query, updateUrl]);

  /**
   * Set sort field
   */
  const setSort = useCallback((sort: SortField) => {
    const newState = { ...query, sort };
    updateUrl(newState);
  }, [query, updateUrl]);

  /**
   * Set sort order
   */
  const setOrder = useCallback((order: SortOrder) => {
    const newState = { ...query, order };
    updateUrl(newState);
  }, [query, updateUrl]);

  /**
   * Set both sort and order at once (for dropdown selection)
   */
  const setSortAndOrder = useCallback((sort: SortField, order: SortOrder) => {
    const newState = { ...query, sort, order };
    updateUrl(newState);
  }, [query, updateUrl]);

  /**
   * Set multiple query params at once
   */
  const setQuery = useCallback((params: Partial<TaskQueryState>) => {
    const newState = {
      status: params.status ?? query.status,
      search: params.search !== undefined ? params.search.slice(0, 100) : query.search,
      sort: params.sort ?? query.sort,
      order: params.order ?? query.order,
    };
    updateUrl(newState);
  }, [query, updateUrl]);

  /**
   * Reset to default query state
   */
  const resetQuery = useCallback(() => {
    updateUrl(DEFAULTS);
  }, [updateUrl]);

  return {
    query,
    setStatus,
    setSearch,
    setSort,
    setOrder,
    setSortAndOrder,
    setQuery,
    resetQuery,
  };
}
