'use client';

import { forwardRef, type InputHTMLAttributes, useId, memo } from 'react';

export interface InputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'onChange'> {
  label?: string;
  error?: string;
  helperText?: string;
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
const InputComponent = forwardRef<HTMLInputElement, InputProps>(
  (
    {
      label,
      error,
      helperText,
      showCharCount = false,
      maxLength = 255,
      value,
      onChange,
      className = '',
      id: providedId,
      disabled,
      defaultValue,
      ...props
    },
    ref
  ) => {
    const generatedId = useId();
    const id = providedId || generatedId;
    const errorId = `${id}-error`;

    // Support both controlled and uncontrolled modes
    const isControlled = value !== undefined;
    const charCount = isControlled ? (value?.length || 0) : 0;
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

    // Build input props based on controlled vs uncontrolled
    const inputProps: any = {
      ref,
      id,
      maxLength,
      disabled,
      'aria-invalid': !!error,
      'aria-describedby': error ? errorId : undefined,
      className: combinedInputClassName,
      ...props,
    };

    // Add controlled or uncontrolled props
    if (isControlled) {
      inputProps.value = value;
      inputProps.onChange = handleChange;
    } else {
      inputProps.defaultValue = defaultValue;
    }

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
          <input {...inputProps} />
        </div>
        <div className="flex justify-between mt-1">
          {error ? (
            <p id={errorId} className="text-caption text-accent-error" role="alert">
              {error}
            </p>
          ) : helperText ? (
            <p className="text-caption text-text-muted">
              {helperText}
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

InputComponent.displayName = 'Input';

// Export memoized version to prevent unnecessary re-renders
export const Input = memo(InputComponent);
