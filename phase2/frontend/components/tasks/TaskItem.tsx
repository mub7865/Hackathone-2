'use client';

import { Button, Checkbox } from '@/components/ui';
import type { Task } from '@/types/task';

export interface TaskItemProps {
  task: Task;
  isHighlighted?: boolean;
  isToggling?: boolean;
  onToggleStatus: (task: Task) => void;
  onEdit: (task: Task) => void;
  onDelete: (task: Task) => void;
}

/**
 * Single task item row with design system tokens
 * Feature: 006-ui-theme-motion (FR-001, FR-002)
 *
 * - Uses semantic color tokens
 * - Subtle hover state
 * - Completed state with muted text
 */
export function TaskItem({
  task,
  isHighlighted = false,
  isToggling = false,
  onToggleStatus,
  onEdit,
  onDelete,
}: TaskItemProps) {
  const isCompleted = task.status === 'completed';

  return (
    <div
      className={`
        flex items-start gap-3 p-4
        border-b border-border-subtle
        transition-colors duration-fast
        motion-reduce:transition-none
        ${isHighlighted
          ? 'bg-accent-primary/10'
          : 'bg-background-elevated hover:bg-background-surface'
        }
      `.replace(/\s+/g, ' ').trim()}
    >
      {/* Status checkbox */}
      <div className="pt-0.5">
        <Checkbox
          checked={isCompleted}
          isLoading={isToggling}
          onChange={() => onToggleStatus(task)}
          aria-label={isCompleted ? 'Mark as pending' : 'Mark as completed'}
        />
      </div>

      {/* Task content */}
      <div className="flex-1 min-w-0">
        <h3
          className={`
            text-body-sm font-medium
            ${isCompleted
              ? 'text-text-muted line-through'
              : 'text-text-primary'
            }
          `.replace(/\s+/g, ' ').trim()}
        >
          {task.title}
        </h3>
        {task.description && (
          <p
            className={`
              mt-1 text-body-sm truncate
              ${isCompleted
                ? 'text-text-muted'
                : 'text-text-secondary'
              }
            `.replace(/\s+/g, ' ').trim()}
          >
            {task.description}
          </p>
        )}
        <p className="mt-1 text-caption text-text-muted">
          Created {formatDate(task.created_at)}
        </p>
      </div>

      {/* Action buttons */}
      <div className="flex gap-2 flex-shrink-0">
        <Button
          variant="ghost"
          size="sm"
          onClick={() => onEdit(task)}
          aria-label={`Edit task: ${task.title}`}
        >
          <svg
            className="w-4 h-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
            />
          </svg>
        </Button>
        <Button
          variant="ghost"
          size="sm"
          onClick={() => onDelete(task)}
          aria-label={`Delete task: ${task.title}`}
          className="text-accent-error hover:text-accent-error hover:bg-accent-error/10"
        >
          <svg
            className="w-4 h-4"
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
        </Button>
      </div>
    </div>
  );
}

/**
 * Format date string for display
 */
function formatDate(dateString: string): string {
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  if (diffDays === 0) {
    return 'today';
  } else if (diffDays === 1) {
    return 'yesterday';
  } else if (diffDays < 7) {
    return `${diffDays} days ago`;
  } else {
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined,
    });
  }
}
