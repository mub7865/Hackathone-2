'use client';

import { Button, Checkbox } from '@/components/ui';
import { PriorityBadge } from '@/components/PrioritySelector';
import { TagList } from '@/components/TagInput';
import { DueDateDisplay } from './DueDateDisplay';
import { ReminderIndicator } from './ReminderIndicator';
import { RecurringIndicator } from './RecurringIndicator';
import type { Task } from '@/types/task';
import { PencilIcon, TrashIcon } from '@heroicons/react/24/outline';

export interface TaskItemProps {
  task: Task;
  isHighlighted?: boolean;
  isToggling?: boolean;
  onToggleStatus: (task: Task) => void;
  onEdit: (task: Task) => void;
  onDelete: (task: Task) => void;
}

/**
 * Enhanced task card with Phase 5 features
 *
 * Displays:
 * - Priority badge (high/medium/low)
 * - Tags with color-coded badges
 * - Due date with overdue indicator
 * - Reminder with bell icon
 * - Recurring task indicator
 *
 * Responsive design with smooth animations
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
    <div className="group relative animate-fade-in motion-reduce:animate-none">
      <div
        className={`
          bg-background-elevated border border-border-subtle rounded-lg p-5
          hover:border-border-visible hover:shadow-lg
          transition-all duration-normal
          motion-reduce:transition-none
          ${isHighlighted ? 'ring-2 ring-accent-primary' : ''}
          ${isCompleted ? 'opacity-60' : ''}
        `.replace(/\s+/g, ' ').trim()}
      >
        {/* Header: Checkbox + Title + Priority Badge */}
        <div className="flex items-start gap-4 mb-3">
          <div className="pt-0.5">
            <Checkbox
              checked={isCompleted}
              isLoading={isToggling}
              onChange={() => onToggleStatus(task)}
              aria-label={isCompleted ? 'Mark as pending' : 'Mark as completed'}
            />
          </div>

          <div className="flex-1 min-w-0">
            <h3
              className={`
                text-heading-md font-semibold
                ${isCompleted
                  ? 'text-text-muted line-through'
                  : 'text-text-primary'
                }
              `.replace(/\s+/g, ' ').trim()}
            >
              {task.title}
            </h3>
          </div>

          {task.priority && (
            <PriorityBadge priority={task.priority} size="md" showLabel={true} />
          )}
        </div>

        {/* Description */}
        {task.description && (
          <p
            className={`
              text-body-sm mb-3 line-clamp-2
              ${isCompleted
                ? 'text-text-muted'
                : 'text-text-secondary'
              }
            `.replace(/\s+/g, ' ').trim()}
          >
            {task.description}
          </p>
        )}

        {/* Metadata Row: Tags + Due Date + Reminder + Recurring */}
        {(task.tags?.length > 0 || task.due_date || task.remind_at || task.recurring_pattern_id) && (
          <div className="flex flex-wrap items-center gap-2 mb-3">
            {/* Tags */}
            {task.tags && task.tags.length > 0 && (
              <TagList tags={task.tags} maxDisplay={3} size="sm" />
            )}

            {/* Due Date */}
            {task.due_date && (
              <DueDateDisplay dueDate={task.due_date} />
            )}

            {/* Reminder */}
            {task.remind_at && (
              <ReminderIndicator remindAt={task.remind_at} />
            )}

            {/* Recurring */}
            {task.recurring_pattern_id && (
              <RecurringIndicator />
            )}
          </div>
        )}

        {/* Footer: Created Date + Actions */}
        <div className="flex items-center justify-between pt-3 border-t border-border-subtle">
          <span className="text-caption text-text-muted">
            Created {formatDate(task.created_at)}
          </span>

          <div className="flex gap-2">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onEdit(task)}
              aria-label={`Edit task: ${task.title}`}
              className="opacity-0 group-hover:opacity-100 transition-opacity duration-fast"
            >
              <PencilIcon className="w-4 h-4" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onDelete(task)}
              aria-label={`Delete task: ${task.title}`}
              className="opacity-0 group-hover:opacity-100 transition-opacity duration-fast text-accent-error hover:text-accent-error hover:bg-accent-error/10"
            >
              <TrashIcon className="w-4 h-4" />
            </Button>
          </div>
        </div>
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
