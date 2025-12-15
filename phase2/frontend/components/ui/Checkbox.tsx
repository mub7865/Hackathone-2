'use client';

import { forwardRef, type InputHTMLAttributes, useId } from 'react';

export interface CheckboxProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type' | 'onChange'> {
  label?: string;
  checked?: boolean;
  onChange?: (checked: boolean) => void;
  isLoading?: boolean;
}

/**
 * Accessible checkbox component with smooth state transitions
 * Feature: 006-ui-theme-motion (FR-013, SC-003)
 *
 * - Smooth check/uncheck transition (150ms)
 * - Uses semantic color tokens
 * - Respects reduced motion preferences
 * - Loading state with spinner
 */
export const Checkbox = forwardRef<HTMLInputElement, CheckboxProps>(
  (
    {
      label,
      checked = false,
      onChange,
      isLoading = false,
      disabled,
      className = '',
      id: providedId,
      ...props
    },
    ref
  ) => {
    const generatedId = useId();
    const id = providedId || generatedId;
    const isDisabled = disabled || isLoading;

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      onChange?.(e.target.checked);
    };

    return (
      <div className={`flex items-center ${className}`}>
        <div className="relative flex items-center">
          {isLoading ? (
            <div className="w-5 h-5 flex items-center justify-center">
              <svg
                className="animate-spin h-4 w-4 text-accent-primary"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                aria-hidden="true"
              >
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                />
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                />
              </svg>
            </div>
          ) : (
            <input
              ref={ref}
              id={id}
              type="checkbox"
              checked={checked}
              onChange={handleChange}
              disabled={isDisabled}
              className={`
                w-5 h-5 rounded border-2
                bg-background-surface border-border-subtle
                text-accent-primary
                transition-all duration-fast
                focus:ring-2 focus:ring-accent-primary focus:ring-offset-2 focus:ring-offset-background-base
                checked:bg-accent-primary checked:border-accent-primary
                disabled:opacity-50 disabled:cursor-not-allowed
                motion-reduce:transition-none
              `.replace(/\s+/g, ' ').trim()}
              {...props}
            />
          )}
        </div>
        {label && (
          <label
            htmlFor={id}
            className={`ml-2 text-body-sm select-none ${
              isDisabled
                ? 'text-text-muted cursor-not-allowed'
                : 'text-text-secondary cursor-pointer'
            }`}
          >
            {label}
          </label>
        )}
      </div>
    );
  }
);

Checkbox.displayName = 'Checkbox';
