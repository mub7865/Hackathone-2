'use client';

import { useEffect, useState } from 'react';
import { createPortal } from 'react-dom';
import type { ToastMessage } from '@/types/task';

export interface ToastProps {
  toast: ToastMessage;
  onDismiss: (id: string) => void;
}

/**
 * Individual toast notification component with calm styling
 * Feature: 006-ui-theme-motion (FR-025, FR-026)
 *
 * - Calm colors (muted, not jarring)
 * - Smooth slide-in animation from right
 * - Respects reduced motion preferences
 */
export function Toast({ toast, onDismiss }: ToastProps) {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    // Trigger enter animation
    const timer = setTimeout(() => setIsVisible(true), 10);
    return () => clearTimeout(timer);
  }, []);

  const handleDismiss = () => {
    setIsVisible(false);
    setTimeout(() => onDismiss(toast.id), 200);
  };

  // Type-based styles using semantic tokens (calm colors)
  const typeStyles = {
    success: `
      bg-background-elevated border-l-4 border-accent-success
      text-text-secondary
    `,
    error: `
      bg-background-elevated border-l-4 border-accent-error
      text-text-secondary
    `,
    info: `
      bg-background-elevated border-l-4 border-accent-primary
      text-text-secondary
    `,
  };

  // Icon colors (calm, muted)
  const iconColors = {
    success: 'text-accent-success',
    error: 'text-accent-error',
    info: 'text-accent-primary',
  };

  // Icon for each type
  const icons = {
    success: (
      <svg className={`w-5 h-5 ${iconColors.success}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
      </svg>
    ),
    error: (
      <svg className={`w-5 h-5 ${iconColors.error}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
      </svg>
    ),
    info: (
      <svg className={`w-5 h-5 ${iconColors.info}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
  };

  return (
    <div
      role="alert"
      aria-live="polite"
      className={`
        flex items-center gap-3 px-4 py-3 rounded-lg shadow-lg
        border border-border-subtle
        transition-all duration-normal ease-out
        motion-reduce:transition-none
        ${typeStyles[toast.type]}
        ${isVisible
          ? 'translate-x-0 opacity-100'
          : 'translate-x-full opacity-0'
        }
      `.replace(/\s+/g, ' ').trim()}
    >
      {icons[toast.type]}
      <p className="flex-1 text-body-sm">{toast.message}</p>
      <button
        type="button"
        onClick={handleDismiss}
        className={`
          flex-shrink-0 p-1 rounded-md
          text-text-muted hover:text-text-secondary
          hover:bg-background-surface
          focus:outline-none focus:ring-2 focus:ring-accent-primary
          transition-colors duration-fast
          motion-reduce:transition-none
        `.replace(/\s+/g, ' ').trim()}
        aria-label="Dismiss notification"
      >
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
  );
}

export interface ToastContainerProps {
  toasts: ToastMessage[];
  onDismiss: (id: string) => void;
}

/**
 * Container for toast notifications - renders via Portal to document.body
 * This ensures toasts appear above all other content regardless of stacking context
 */
export function ToastContainer({ toasts, onDismiss }: ToastContainerProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted || toasts.length === 0) {
    return null;
  }

  return createPortal(
    <div
      className="fixed top-20 right-4 z-[9999] flex flex-col gap-2 max-w-sm w-full pointer-events-none"
      aria-label="Notifications"
    >
      {toasts.map((toast) => (
        <div key={toast.id} className="pointer-events-auto">
          <Toast toast={toast} onDismiss={onDismiss} />
        </div>
      ))}
    </div>,
    document.body
  );
}
