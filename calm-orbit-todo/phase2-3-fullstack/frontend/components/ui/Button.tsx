'use client';

import { forwardRef, type ButtonHTMLAttributes } from 'react';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
}

/**
 * Button component with design system tokens and micro-interactions
 * Feature: 006-ui-theme-motion (FR-016, FR-020, SC-003)
 *
 * - Uses semantic color tokens from design system
 * - Smooth hover/active transitions (150ms)
 * - Subtle press feedback (scale 0.98)
 * - Respects reduced motion preferences
 * - Clear focus states for accessibility
 */
export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      children,
      variant = 'primary',
      size = 'md',
      isLoading = false,
      disabled,
      className = '',
      type = 'button',
      ...props
    },
    ref
  ) => {
    const isDisabled = disabled || isLoading;

    // Base styles with design system tokens
    const baseStyles = `
      inline-flex items-center justify-center font-medium rounded-md
      transition-all duration-fast ease-out
      focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-background-base
      disabled:opacity-50 disabled:cursor-not-allowed
      active:scale-[0.98] motion-reduce:transform-none motion-reduce:transition-none
    `;

    // Variant styles using semantic tokens
    const variantStyles = {
      primary: `
        bg-accent-primary text-background-base
        hover:bg-accent-hover
        focus:ring-accent-primary
      `,
      secondary: `
        bg-background-surface text-text-primary
        border border-border-subtle
        hover:bg-background-elevated hover:border-border-visible
        focus:ring-accent-primary
      `,
      danger: `
        bg-accent-error text-white
        hover:brightness-110
        focus:ring-accent-error
      `,
      ghost: `
        bg-transparent text-text-secondary
        hover:bg-background-surface hover:text-text-primary
        focus:ring-accent-primary
      `,
    };

    // Size styles
    const sizeStyles = {
      sm: 'px-3 py-1.5 text-sm',
      md: 'px-4 py-2 text-sm',
      lg: 'px-6 py-3 text-base',
    };

    const combinedClassName = `
      ${baseStyles}
      ${variantStyles[variant]}
      ${sizeStyles[size]}
      ${className}
    `.replace(/\s+/g, ' ').trim();

    return (
      <button
        ref={ref}
        type={type}
        disabled={isDisabled}
        className={combinedClassName}
        aria-busy={isLoading}
        {...props}
      >
        {isLoading && (
          <svg
            className="animate-spin -ml-1 mr-2 h-4 w-4"
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
        )}
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';
