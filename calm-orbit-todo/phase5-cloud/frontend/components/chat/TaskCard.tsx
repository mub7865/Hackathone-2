/**
 * TaskCard Component
 *
 * Compact task display for chat messages.
 * Shows key task information with inline actions.
 */

'use client';

import { useState } from 'react';
import { Task } from '@/types/task';
import { PriorityBadge } from '@/components/PrioritySelector';
import { DueDateDisplay } from '@/components/tasks/DueDateDisplay';
import { ReminderIndicator } from '@/components/tasks/ReminderIndicator';
import { RecurringIndicator } from '@/components/tasks/RecurringIndicator';
import { CheckCircleIcon, PencilIcon, TrashIcon } from '@heroicons/react/24/outline';

interface TaskCardProps {
  task: Task;
  onComplete?: (task: Task) => void;
  onEdit?: (task: Task) => void;
  onDelete?: (task: Task) => void;
}

export function TaskCard({ task, onComplete, onEdit, onDelete }: TaskCardProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const isCompleted = task.status === 'completed';

  return (
    <div
      className={`
        bg-background-elevated border rounded-lg p-3 sm:p-4 transition-all duration-normal
        ${isCompleted ? 'border-green-300 bg-green-50 dark:bg-green-900/10 dark:border-green-800' : 'border-border-subtle hover:border-border-visible'}
        ${isExpanded ? 'shadow-lg' : 'hover:shadow-md'}
      `.replace(/\s+/g, ' ').trim()}
    >
      {/* Header: Title + Priority */}
      <div className="flex items-start gap-2 sm:gap-3 mb-2">
        <button
          onClick={() => setIsExpanded(!isExpanded)}
          className="flex-1 text-left min-w-0"
        >
          <h4 className={`text-sm font-semibold break-words ${isCompleted ? 'text-green-700 dark:text-green-400 line-through' : 'text-text-primary'}`}>
            {task.title}
          </h4>
        </button>
        {task.priority && <PriorityBadge priority={task.priority} size="sm" />}
      </div>

      {/* Metadata Row */}
      <div className="flex flex-wrap items-center gap-1.5 sm:gap-2 mb-2 sm:mb-3">
        {task.due_date && <DueDateDisplay dueDate={task.due_date} className="text-xs" />}
        {task.remind_at && <ReminderIndicator remindAt={task.remind_at} className="text-xs" />}
        {task.recurring_pattern_id && <RecurringIndicator className="text-xs" />}
        {task.tags && task.tags.length > 0 && (
          <div className="flex flex-wrap gap-1">
            {task.tags.slice(0, 2).map((tag) => (
              <span
                key={tag}
                className="px-1.5 sm:px-2 py-0.5 bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 rounded text-xs whitespace-nowrap"
              >
                {tag}
              </span>
            ))}
            {task.tags.length > 2 && (
              <span className="px-1.5 sm:px-2 py-0.5 bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400 rounded text-xs whitespace-nowrap">
                +{task.tags.length - 2}
              </span>
            )}
          </div>
        )}
      </div>

      {/* Expanded Description */}
      {isExpanded && task.description && (
        <p className="text-sm text-text-secondary mb-3 pb-3 border-b border-border-subtle break-words">
          {task.description}
        </p>
      )}

      {/* Actions */}
      <div className="flex flex-wrap items-center gap-1.5 sm:gap-2">
        {!isCompleted && onComplete && (
          <button
            onClick={() => onComplete(task)}
            className="flex items-center gap-1 px-2 sm:px-3 py-1.5 text-xs font-medium text-green-700 bg-green-100 hover:bg-green-200 dark:bg-green-900/30 dark:text-green-400 dark:hover:bg-green-900/50 rounded transition-colors duration-fast whitespace-nowrap"
          >
            <CheckCircleIcon className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
            <span className="hidden xs:inline sm:inline">Complete</span>
            <span className="xs:hidden sm:hidden">✓</span>
          </button>
        )}
        {onEdit && (
          <button
            onClick={() => onEdit(task)}
            className="flex items-center gap-1 px-2 sm:px-3 py-1.5 text-xs font-medium text-blue-700 bg-blue-100 hover:bg-blue-200 dark:bg-blue-900/30 dark:text-blue-400 dark:hover:bg-blue-900/50 rounded transition-colors duration-fast whitespace-nowrap"
          >
            <PencilIcon className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
            <span className="hidden xs:inline sm:inline">Edit</span>
          </button>
        )}
        {onDelete && (
          <button
            onClick={() => onDelete(task)}
            className="flex items-center gap-1 px-2 sm:px-3 py-1.5 text-xs font-medium text-red-700 bg-red-100 hover:bg-red-200 dark:bg-red-900/30 dark:text-red-400 dark:hover:bg-red-900/50 rounded transition-colors duration-fast whitespace-nowrap"
          >
            <TrashIcon className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
            <span className="hidden xs:inline sm:inline">Delete</span>
          </button>
        )}
      </div>

      {/* Completed Badge */}
      {isCompleted && (
        <div className="mt-3 pt-3 border-t border-green-300 dark:border-green-800">
          <span className="text-xs text-green-700 dark:text-green-400 font-medium">
            ✓ Completed
          </span>
        </div>
      )}
    </div>
  );
}
