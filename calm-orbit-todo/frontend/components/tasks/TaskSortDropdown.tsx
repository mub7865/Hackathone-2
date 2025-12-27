'use client';

import { useId, useCallback } from 'react';
import type { SortField, SortOrder } from '@/types/task';

export interface TaskSortDropdownProps {
  sort: SortField;
  order: SortOrder;
  onSortChange: (sort: SortField, order: SortOrder) => void;
  className?: string;
}

// Sort options combining field and order (FR-008, FR-009, FR-010)
interface SortOption {
  value: string;
  label: string;
  sort: SortField;
  order: SortOrder;
}

const SORT_OPTIONS: SortOption[] = [
  { value: 'created_at-desc', label: 'Newest first', sort: 'created_at', order: 'desc' },
  { value: 'created_at-asc', label: 'Oldest first', sort: 'created_at', order: 'asc' },
  { value: 'title-asc', label: 'Title A-Z', sort: 'title', order: 'asc' },
  { value: 'title-desc', label: 'Title Z-A', sort: 'title', order: 'desc' },
];

/**
 * Sort dropdown component with design system tokens
 * Feature: 006-ui-theme-motion (FR-016)
 *
 * - Semantic color tokens
 * - Smooth focus transitions
 * - Design system consistency
 */
export function TaskSortDropdown({
  sort,
  order,
  onSortChange,
  className = '',
}: TaskSortDropdownProps) {
  const id = useId();

  // Get current value for the select
  const currentValue = `${sort}-${order}`;

  // Handle select change
  const handleChange = useCallback((e: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedOption = SORT_OPTIONS.find((opt) => opt.value === e.target.value);
    if (selectedOption) {
      onSortChange(selectedOption.sort, selectedOption.order);
    }
  }, [onSortChange]);

  // Design system select styles
  const selectStyles = `
    block w-full rounded-md px-3 py-2 pr-10 text-body-sm
    appearance-none cursor-pointer
    bg-background-surface text-text-primary
    border border-border-subtle
    transition-colors duration-fast
    focus:outline-none focus:ring-1 focus:border-accent-primary focus:ring-accent-primary
    motion-reduce:transition-none
  `.replace(/\s+/g, ' ').trim();

  return (
    <div className={`relative ${className}`}>
      <label htmlFor={id} className="sr-only">
        Sort tasks
      </label>
      <select
        id={id}
        value={currentValue}
        onChange={handleChange}
        className={selectStyles}
        aria-label="Sort tasks"
      >
        {SORT_OPTIONS.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>

      {/* Custom dropdown arrow */}
      <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3">
        <svg
          className="h-4 w-4 text-text-muted"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          aria-hidden="true"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M19 9l-7 7-7-7"
          />
        </svg>
      </div>
    </div>
  );
}
