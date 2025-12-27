'use client';

import { forwardRef, type InputHTMLAttributes, useId } from 'react';

export interface InputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'onChange'> {
  label?: string;
  error?: string;
  showCharCount?: boolean;
  maxLength?: number;
  value?: string;
  onChange?: (value: string) => void;
}

/**
 * Input component with design system tokens and smooth focus transitions
 * Feature: 006-ui-theme-motion (FR-020, SC-005)
 *
 * - Uses semantic color tokens
 * - Smooth border color transition on focus (150ms)
 * - Clear focus ring for accessibility
 * - Character count with warning states
 */
export const Input = forwardRef<HTMLInputElement, InputProps>(
  (
    {
      label,
      error,
      showCharCount = false,
      maxLength = 255,
      value = '',
      onChange,
      className = '',
      id: providedId,
      disabled,
      ...props
    },
    ref
  ) => {
    const generatedId = useId();
    const id = providedId || generatedId;
    const errorId = `${id}-error`;
    const charCount = value.length;
    const remainingChars = maxLength - charCount;

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      const newValue = e.target.value;
      // Prevent input beyond maxLength
      if (newValue.length <= maxLength) {
        onChange?.(newValue);
      }
    };

    // Base input styles with design system tokens
    const baseInputStyles = `
      block w-full rounded-md px-3 py-2 text-body-sm
      bg-background-surface text-text-primary
      placeholder:text-text-muted
      border transition-colors duration-fast
      focus:outline-none focus:ring-1
      disabled:bg-background-elevated disabled:cursor-not-allowed disabled:opacity-50
      motion-reduce:transition-none
    `;

    // Error vs normal styles
    const inputStateStyles = error
      ? `
        border-accent-error text-text-primary
        focus:border-accent-error focus:ring-accent-error
      `
      : `
        border-border-subtle
        focus:border-accent-primary focus:ring-accent-primary
      `;

    const combinedInputClassName = `
      ${baseInputStyles}
      ${inputStateStyles}
      ${className}
    `.replace(/\s+/g, ' ').trim();

    return (
      <div className="w-full">
        {label && (
          <label
            htmlFor={id}
            className="block text-body-sm font-medium text-text-secondary mb-1"
          >
            {label}
          </label>
        )}
        <div className="relative">
          <input
            ref={ref}
            id={id}
            value={value}
            onChange={handleChange}
            maxLength={maxLength}
            disabled={disabled}
            aria-invalid={!!error}
            aria-describedby={error ? errorId : undefined}
            className={combinedInputClassName}
            {...props}
          />
        </div>
        <div className="flex justify-between mt-1">
          {error ? (
            <p id={errorId} className="text-caption text-accent-error" role="alert">
              {error}
            </p>
          ) : (
            <span />
          )}
          {showCharCount && (
            <span
              className={`text-caption ${
                remainingChars <= 20
                  ? 'text-accent-warning'
                  : 'text-text-muted'
              }`}
              aria-live="polite"
            >
              {charCount}/{maxLength}
            </span>
          )}
        </div>
      </div>
    );
  }
);

Input.displayName = 'Input';
