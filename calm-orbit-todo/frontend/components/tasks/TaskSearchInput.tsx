'use client';

import { useState, useEffect, useCallback, useId } from 'react';
import { useDebouncedCallback } from 'use-debounce';

export interface TaskSearchInputProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  className?: string;
}

// Maximum search length (FR-006)
const MAX_SEARCH_LENGTH = 100;

// Debounce delay (FR-007)
const DEBOUNCE_DELAY_MS = 300;

/**
 * Search input component with design system tokens
 * Feature: 006-ui-theme-motion (FR-016)
 *
 * - Semantic color tokens
 * - Smooth focus transitions
 * - Clear button animation
 */
export function TaskSearchInput({
  value,
  onChange,
  placeholder = 'Search tasks...',
  className = '',
}: TaskSearchInputProps) {
  const id = useId();

  // Local state for immediate input feedback
  const [localValue, setLocalValue] = useState(value);

  // Sync local state when external value changes (e.g., URL navigation)
  useEffect(() => {
    setLocalValue(value);
  }, [value]);

  // Debounced callback for parent notification (FR-007: 300ms)
  const debouncedOnChange = useDebouncedCallback(
    (newValue: string) => {
      onChange(newValue);
    },
    DEBOUNCE_DELAY_MS
  );

  // Handle input change
  const handleChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;

    // Enforce max length (FR-006)
    const truncatedValue = newValue.slice(0, MAX_SEARCH_LENGTH);

    // Update local state immediately for responsive UI
    setLocalValue(truncatedValue);

    // Notify parent after debounce
    debouncedOnChange(truncatedValue);
  }, [debouncedOnChange]);

  // Handle clear button click
  const handleClear = useCallback(() => {
    setLocalValue('');
    onChange(''); // Immediate clear (no debounce needed)
  }, [onChange]);

  return (
    <div className={`relative ${className}`}>
      {/* Search icon */}
      <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
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
            d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
          />
        </svg>
      </div>

      {/* Input field */}
      <input
        id={id}
        type="text"
        value={localValue}
        onChange={handleChange}
        placeholder={placeholder}
        maxLength={MAX_SEARCH_LENGTH}
        className={`
          block w-full rounded-md px-3 py-2 pl-10 pr-10 text-body-sm
          bg-background-surface text-text-primary
          placeholder:text-text-muted
          border border-border-subtle
          transition-colors duration-fast
          focus:outline-none focus:ring-1 focus:border-accent-primary focus:ring-accent-primary
          motion-reduce:transition-none
        `.replace(/\s+/g, ' ').trim()}
        aria-label="Search tasks"
      />

      {/* Clear button (only shown when there's input) */}
      {localValue && (
        <button
          type="button"
          onClick={handleClear}
          className={`
            absolute inset-y-0 right-0 flex items-center pr-3
            text-text-muted hover:text-text-secondary
            transition-colors duration-fast
            motion-reduce:transition-none
          `.replace(/\s+/g, ' ').trim()}
          aria-label="Clear search"
        >
          <svg
            className="h-4 w-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>
      )}
    </div>
  );
}
