'use client';

import { Button } from '@/components/ui';
import type { TaskFilter } from '@/types/task';

export interface EmptyStateProps {
  filter: TaskFilter;
  onCreateTask: () => void;
}

/**
 * Empty state component with serene, encouraging copy
 * Feature: 006-ui-theme-motion (FR-027, SC-006)
 *
 * - Calm, positive messaging (no harsh "No data" language)
 * - Design system tokens
 * - Subtle fade-in animation
 */
export function EmptyState({ filter, onCreateTask }: EmptyStateProps) {
  // Get serene message based on filter
  const getMessage = () => {
    switch (filter) {
      case 'pending':
        return {
          title: "You're all caught up",
          description: "Enjoy the calm. When you're ready, add a new task.",
          icon: CheckCircleIcon,
        };
      case 'completed':
        return {
          title: 'No completed tasks yet',
          description: 'Complete a task to see your progress here.',
          icon: ClipboardIcon,
        };
      case 'all':
      default:
        return {
          title: 'Your task list is clear',
          description: 'Take a moment to breathe. Start with just one small step.',
          icon: SparklesIcon,
        };
    }
  };

  const { title, description, icon: Icon } = getMessage();

  return (
    <div
      className={`
        flex flex-col items-center justify-center py-16 px-4 text-center
        animate-fade-in motion-reduce:animate-none
      `.replace(/\s+/g, ' ').trim()}
    >
      {/* Serene icon */}
      <div className="w-16 h-16 mb-6 rounded-full bg-background-surface flex items-center justify-center">
        <Icon className="w-8 h-8 text-text-muted" />
      </div>

      {/* Serene message */}
      <h3 className="text-heading-md text-text-primary mb-2">
        {title}
      </h3>
      <p className="text-body-sm text-text-secondary mb-6 max-w-sm">
        {description}
      </p>

      {/* CTA button - only show for 'all' or 'pending' filters */}
      {(filter === 'all' || filter === 'pending') && (
        <Button onClick={onCreateTask}>
          <svg
            className="w-4 h-4 mr-2"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 4v16m8-8H4"
            />
          </svg>
          Add Task
        </Button>
      )}
    </div>
  );
}

// Serene icons for empty states
function SparklesIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"
      />
    </svg>
  );
}

function CheckCircleIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
      />
    </svg>
  );
}

function ClipboardIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
      />
    </svg>
  );
}
