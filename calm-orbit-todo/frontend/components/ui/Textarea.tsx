'use client';

import { forwardRef, type TextareaHTMLAttributes, useId } from 'react';

export interface TextareaProps extends Omit<TextareaHTMLAttributes<HTMLTextAreaElement>, 'onChange'> {
  label?: string;
  error?: string;
  value?: string;
  onChange?: (value: string) => void;
}

/**
 * Textarea component with design system tokens and smooth focus transitions
 * Feature: 006-ui-theme-motion (FR-020)
 *
 * - Matches Input component styling pattern
 * - Uses semantic color tokens
 * - Smooth border transition on focus
 */
export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  (
    {
      label,
      error,
      value = '',
      onChange,
      className = '',
      id: providedId,
      disabled,
      rows = 3,
      ...props
    },
    ref
  ) => {
    const generatedId = useId();
    const id = providedId || generatedId;
    const errorId = `${id}-error`;

    const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
      onChange?.(e.target.value);
    };

    // Base textarea styles matching Input component
    const baseTextareaStyles = `
      block w-full rounded-md px-3 py-2 text-body-sm
      bg-background-surface text-text-primary
      placeholder:text-text-muted
      border transition-colors duration-fast
      focus:outline-none focus:ring-1
      resize-none
      disabled:bg-background-elevated disabled:cursor-not-allowed disabled:opacity-50
      motion-reduce:transition-none
    `;

    // Error vs normal styles
    const textareaStateStyles = error
      ? `
        border-accent-error text-text-primary
        focus:border-accent-error focus:ring-accent-error
      `
      : `
        border-border-subtle
        focus:border-accent-primary focus:ring-accent-primary
      `;

    const combinedTextareaClassName = `
      ${baseTextareaStyles}
      ${textareaStateStyles}
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
        <textarea
          ref={ref}
          id={id}
          value={value}
          onChange={handleChange}
          disabled={disabled}
          rows={rows}
          aria-invalid={!!error}
          aria-describedby={error ? errorId : undefined}
          className={combinedTextareaClassName}
          {...props}
        />
        {error && (
          <p id={errorId} className="mt-1 text-caption text-accent-error" role="alert">
            {error}
          </p>
        )}
      </div>
    );
  }
);

Textarea.displayName = 'Textarea';
