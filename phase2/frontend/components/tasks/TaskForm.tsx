'use client';

import { useState, useEffect, useCallback } from 'react';
import { Button, Input, Textarea } from '@/components/ui';
import type { Task, TaskStatus, TaskFormErrors } from '@/types/task';

export interface TaskFormData {
  title: string;
  description?: string;
  status?: TaskStatus;
}

export interface TaskFormProps {
  mode: 'create' | 'edit';
  initialData?: Task;
  isSubmitting: boolean;
  errors: TaskFormErrors;
  onSubmit: (data: TaskFormData) => void;
  onCancel: () => void;
}

const MAX_TITLE_LENGTH = 255;

/**
 * Task form component with design system tokens
 * Feature: 006-ui-theme-motion
 */
export function TaskForm({
  mode,
  initialData,
  isSubmitting,
  errors,
  onSubmit,
  onCancel,
}: TaskFormProps) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [status, setStatus] = useState<TaskStatus>('pending');
  const [touched, setTouched] = useState({ title: false });

  // Initialize form with initial data
  useEffect(() => {
    if (initialData) {
      setTitle(initialData.title);
      setDescription(initialData.description || '');
      setStatus(initialData.status);
    } else {
      setTitle('');
      setDescription('');
      setStatus('pending');
    }
    setTouched({ title: false });
  }, [initialData]);

  // Local validation
  const validateTitle = useCallback(() => {
    if (!title.trim()) {
      return 'Title is required';
    }
    return undefined;
  }, [title]);

  const titleError = touched.title ? (errors.title || validateTitle()) : errors.title;

  // Handle form submission
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setTouched({ title: true });

    // Validate before submitting
    const titleValidationError = validateTitle();
    if (titleValidationError) {
      return;
    }

    const data: TaskFormData = {
      title: title.trim(),
      description: description.trim() || undefined,
    };

    // Include status for edit mode
    if (mode === 'edit') {
      data.status = status;
    }

    onSubmit(data);
  };

  // Handle Enter key in form
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && e.ctrlKey) {
      handleSubmit(e);
    }
  };

  return (
    <form onSubmit={handleSubmit} onKeyDown={handleKeyDown} className="space-y-4">
      {/* General error message */}
      {errors.general && (
        <div
          className="p-3 text-body-sm text-accent-error bg-accent-error/10 border border-accent-error/20 rounded-md"
          role="alert"
        >
          {errors.general}
        </div>
      )}

      {/* Title field */}
      <Input
        label="Title"
        value={title}
        onChange={setTitle}
        error={titleError}
        showCharCount
        maxLength={MAX_TITLE_LENGTH}
        placeholder="What needs to be done?"
        disabled={isSubmitting}
        onBlur={() => setTouched((prev) => ({ ...prev, title: true }))}
        autoFocus
      />

      {/* Description field */}
      <Textarea
        label="Description (optional)"
        value={description}
        onChange={setDescription}
        error={errors.description}
        placeholder="Add more details..."
        disabled={isSubmitting}
        rows={3}
      />

      {/* Status field (edit mode only) */}
      {mode === 'edit' && (
        <div className="space-y-2">
          <label className="block text-body-sm font-medium text-text-secondary">
            Status
          </label>
          <div className="flex gap-4">
            <label className="flex items-center cursor-pointer">
              <input
                type="radio"
                name="status"
                value="pending"
                checked={status === 'pending'}
                onChange={() => setStatus('pending')}
                disabled={isSubmitting}
                className={`
                  w-4 h-4 text-accent-primary
                  border-border-subtle bg-background-surface
                  focus:ring-accent-primary focus:ring-offset-background-base
                `.replace(/\s+/g, ' ').trim()}
              />
              <span className="ml-2 text-body-sm text-text-secondary">Pending</span>
            </label>
            <label className="flex items-center cursor-pointer">
              <input
                type="radio"
                name="status"
                value="completed"
                checked={status === 'completed'}
                onChange={() => setStatus('completed')}
                disabled={isSubmitting}
                className={`
                  w-4 h-4 text-accent-primary
                  border-border-subtle bg-background-surface
                  focus:ring-accent-primary focus:ring-offset-background-base
                `.replace(/\s+/g, ' ').trim()}
              />
              <span className="ml-2 text-body-sm text-text-secondary">Completed</span>
            </label>
          </div>
        </div>
      )}

      {/* Form actions */}
      <div className="flex justify-end gap-3 pt-4">
        <Button
          type="button"
          variant="secondary"
          onClick={onCancel}
          disabled={isSubmitting}
        >
          Cancel
        </Button>
        <Button
          type="submit"
          isLoading={isSubmitting}
          disabled={isSubmitting}
        >
          {mode === 'create' ? 'Create Task' : 'Save Changes'}
        </Button>
      </div>

      {/* Keyboard hint */}
      <p className="text-caption text-text-muted text-center">
        Press Ctrl+Enter to submit
      </p>
    </form>
  );
}
