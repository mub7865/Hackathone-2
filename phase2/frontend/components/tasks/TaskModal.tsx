'use client';

import { Modal } from '@/components/ui';
import { TaskForm, type TaskFormData } from './TaskForm';
import type { Task, TaskFormErrors } from '@/types/task';

export interface TaskModalProps {
  isOpen: boolean;
  mode: 'create' | 'edit';
  task?: Task | null;
  isSubmitting: boolean;
  errors: TaskFormErrors;
  onSubmit: (data: TaskFormData) => void;
  onClose: () => void;
}

/**
 * Modal wrapper for TaskForm - handles create and edit modes
 */
export function TaskModal({
  isOpen,
  mode,
  task,
  isSubmitting,
  errors,
  onSubmit,
  onClose,
}: TaskModalProps) {
  const title = mode === 'create' ? 'Create New Task' : 'Edit Task';

  const handleClose = () => {
    // Don't allow closing while submitting
    if (!isSubmitting) {
      onClose();
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={handleClose}
      title={title}
      size="md"
    >
      <TaskForm
        mode={mode}
        initialData={task || undefined}
        isSubmitting={isSubmitting}
        errors={errors}
        onSubmit={onSubmit}
        onCancel={handleClose}
      />
    </Modal>
  );
}
