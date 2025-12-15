'use client';

import { useCallback } from 'react';
import { Tabs, type Tab } from '@/components/ui';
import type { TaskFilter } from '@/types/task';

export interface TaskFilterTabsProps {
  activeFilter: TaskFilter;
  onFilterChange: (filter: TaskFilter) => void;
  className?: string;
}

// Define filter tabs
const FILTER_TABS: Tab[] = [
  { id: 'pending', label: 'Pending' },
  { id: 'completed', label: 'Completed' },
  { id: 'all', label: 'All' },
];

/**
 * Task filter tabs component
 * URL sync is handled by useTaskQuery in the parent
 * Default filter is "Pending" per spec
 */
export function TaskFilterTabs({
  activeFilter,
  onFilterChange,
  className = '',
}: TaskFilterTabsProps) {
  // Handle filter change - parent manages URL updates
  const handleFilterChange = useCallback((filterId: string) => {
    const newFilter = filterId as TaskFilter;
    onFilterChange(newFilter);
  }, [onFilterChange]);

  return (
    <Tabs
      tabs={FILTER_TABS}
      activeTab={activeFilter}
      onChange={handleFilterChange}
      className={className}
    />
  );
}
