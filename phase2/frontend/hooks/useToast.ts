'use client';

import { useState, useCallback } from 'react';
import type { ToastMessage } from '@/types/task';

/**
 * Toast hook for managing toast notification state
 */
export function useToast() {
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  /**
   * Add a new toast notification
   */
  const addToast = useCallback(
    (type: ToastMessage['type'], message: string, duration: number = 5000) => {
      const id = `toast-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      const toast: ToastMessage = { id, type, message };

      setToasts((prev) => [...prev, toast]);

      // Auto-dismiss after duration
      if (duration > 0) {
        setTimeout(() => {
          removeToast(id);
        }, duration);
      }

      return id;
    },
    []
  );

  /**
   * Remove a toast by ID
   */
  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((toast) => toast.id !== id));
  }, []);

  /**
   * Show a success toast
   */
  const success = useCallback(
    (message: string, duration?: number) => {
      return addToast('success', message, duration);
    },
    [addToast]
  );

  /**
   * Show an error toast
   */
  const error = useCallback(
    (message: string, duration?: number) => {
      return addToast('error', message, duration);
    },
    [addToast]
  );

  /**
   * Show an info toast
   */
  const info = useCallback(
    (message: string, duration?: number) => {
      return addToast('info', message, duration);
    },
    [addToast]
  );

  /**
   * Clear all toasts
   */
  const clearAll = useCallback(() => {
    setToasts([]);
  }, []);

  return {
    toasts,
    addToast,
    removeToast,
    success,
    error,
    info,
    clearAll,
  };
}

export type UseToastReturn = ReturnType<typeof useToast>;
