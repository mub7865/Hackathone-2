'use client';

import { useState, useEffect, useCallback } from 'react';
import { Button, Input, Textarea } from '@/components/ui';
import PrioritySelector from '@/components/PrioritySelector';
import TagInput from '@/components/TagInput';
import DueDatePicker from '@/components/DueDatePicker';
import type { Task, TaskStatus, TaskPriority, TaskFormErrors } from '@/types/task';

export interface TaskFormData {
  title: string;
  description?: string;
  status?: TaskStatus;
  priority?: TaskPriority; // Phase 5
  tags?: string[]; // Phase 5
  due_date?: string | null; // Phase 5
  remind_at?: string | null; // Phase 5
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
  const [priority, setPriority] = useState<TaskPriority>('medium'); // Phase 5
  const [tags, setTags] = useState<string[]>([]); // Phase 5
  const [dueDate, setDueDate] = useState<string | null>(null); // Phase 5
  const [remindAt, setRemindAt] = useState<string | null>(null); // Phase 5
  const [showDatePicker, setShowDatePicker] = useState(false); // Phase 5
  const [touched, setTouched] = useState({ title: false });

  // Initialize form with initial data
  useEffect(() => {
    if (initialData) {
      setTitle(initialData.title);
      setDescription(initialData.description || '');
      setStatus(initialData.status);
      setPriority(initialData.priority || 'medium'); // Phase 5
      setTags(initialData.tags || []); // Phase 5
      setDueDate(initialData.due_date || null); // Phase 5
      setRemindAt(initialData.remind_at || null); // Phase 5
    } else {
      setTitle('');
      setDescription('');
      setStatus('pending');
      setPriority('medium'); // Phase 5
      setTags([]); // Phase 5
      setDueDate(null); // Phase 5
      setRemindAt(null); // Phase 5
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
      priority, // Phase 5
      tags, // Phase 5
      due_date: dueDate, // Phase 5
      remind_at: remindAt, // Phase 5
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

      {/* Phase 5: Priority Selector */}
      <div className="space-y-2">
        <label className="block text-body-sm font-medium text-text-secondary">
          Priority
        </label>
        <PrioritySelector
          value={priority}
          onChange={setPriority}
          disabled={isSubmitting}
        />
      </div>

      {/* Phase 5: Tag Input */}
      <div className="space-y-2">
        <label className="block text-body-sm font-medium text-text-secondary">
          Tags
        </label>
        <TagInput
          value={tags}
          onChange={setTags}
          disabled={isSubmitting}
          placeholder="Add tags (press Enter or comma)"
        />
      </div>

      {/* Phase 5: Due Date and Reminder */}
      <div className="space-y-2">
        <label className="block text-body-sm font-medium text-text-secondary">
          Due Date & Reminder
        </label>
        {!showDatePicker && (
          <Button
            type="button"
            variant="secondary"
            onClick={() => setShowDatePicker(true)}
            disabled={isSubmitting}
            className="w-full"
          >
            {dueDate ? `Due: ${new Date(dueDate).toLocaleDateString()}` : 'Set Due Date'}
          </Button>
        )}
        {showDatePicker && (
          <DueDatePicker
            taskId={initialData?.id || ''}
            currentDueDate={dueDate}
            currentRemindAt={remindAt}
            onSave={async (due, remind) => {
              setDueDate(due);
              setRemindAt(remind);
              setShowDatePicker(false);
            }}
            onCancel={() => setShowDatePicker(false)}
          />
        )}
      </div>

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
