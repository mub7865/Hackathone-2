'use client';

import { Modal, Button } from '@/components/ui';
import type { Task } from '@/types/task';

export interface DeleteConfirmModalProps {
  isOpen: boolean;
  task: Task | null;
  isDeleting: boolean;
  error?: string | null;
  onConfirm: () => void;
  onCancel: () => void;
}

/**
 * Confirmation dialog with calm error styling
 * Feature: 006-ui-theme-motion (FR-010, FR-011)
 *
 * - Calm, non-alarming styling
 * - Muted error colors
 * - Design system tokens
 */
export function DeleteConfirmModal({
  isOpen,
  task,
  isDeleting,
  error,
  onConfirm,
  onCancel,
}: DeleteConfirmModalProps) {
  const handleClose = () => {
    // Don't allow closing while deleting
    if (!isDeleting) {
      onCancel();
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={handleClose}
      title="Delete Task"
      size="sm"
    >
      <div className="space-y-4">
        {/* Warning icon and message - calm, not alarming */}
        <div className="flex flex-col items-center text-center">
          <div className="w-12 h-12 mb-4 rounded-full bg-accent-error/15 flex items-center justify-center">
            <svg
              className="w-6 h-6 text-accent-error"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              aria-hidden="true"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
              />
            </svg>
          </div>
          <p className="text-body-sm text-text-secondary">
            Are you sure you want to remove this task?
          </p>
          {task && (
            <p className="mt-2 text-body-sm font-medium text-text-primary max-w-full truncate">
              &quot;{task.title}&quot;
            </p>
          )}
          <p className="mt-2 text-caption text-text-muted">
            This action cannot be undone.
          </p>
        </div>

        {/* Error message - calm styling */}
        {error && (
          <div
            className="p-3 text-body-sm text-accent-error bg-accent-error/10 border border-accent-error/20 rounded-md"
            role="alert"
          >
            {error}
          </div>
        )}

        {/* Action buttons */}
        <div className="flex justify-end gap-3 pt-2">
          <Button
            type="button"
            variant="secondary"
            onClick={handleClose}
            disabled={isDeleting}
          >
            Cancel
          </Button>
          <Button
            type="button"
            variant="danger"
            onClick={onConfirm}
            isLoading={isDeleting}
            disabled={isDeleting}
          >
            Delete
          </Button>
        </div>
      </div>
    </Modal>
  );
}
