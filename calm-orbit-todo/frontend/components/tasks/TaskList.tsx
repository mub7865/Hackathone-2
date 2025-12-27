'use client';

import { AnimatePresence, motion } from 'framer-motion';
import { TaskItem } from './TaskItem';
import { EmptyState } from './EmptyState';
import { TaskListSkeleton, Button } from '@/components/ui';
import { useReducedMotion } from '@/hooks';
import type { Task, TaskFilter } from '@/types/task';

export interface TaskListProps {
  tasks: Task[];
  filter: TaskFilter;
  isLoading: boolean;
  isLoadingMore: boolean;
  error: string | null;
  hasMore: boolean;
  highlightedTaskId: string | null;
  togglingTaskId: string | null;
  onToggleStatus: (task: Task) => void;
  onEdit: (task: Task) => void;
  onDelete: (task: Task) => void;
  onLoadMore: () => void;
  onRetry: () => void;
  onCreateTask: () => void;
}

/**
 * Task list container with Framer Motion animations
 * Feature: 006-ui-theme-motion (FR-012, FR-014, FR-015, SC-003)
 *
 * - AnimatePresence for enter/exit animations
 * - Layout animations for reordering
 * - Respects reduced motion preferences
 * - Design system tokens throughout
 */
export function TaskList({
  tasks,
  filter,
  isLoading,
  isLoadingMore,
  error,
  hasMore,
  highlightedTaskId,
  togglingTaskId,
  onToggleStatus,
  onEdit,
  onDelete,
  onLoadMore,
  onRetry,
  onCreateTask,
}: TaskListProps) {
  const prefersReducedMotion = useReducedMotion();

  // Loading state
  if (isLoading) {
    return (
      <div className="bg-background-elevated rounded-lg border border-border-subtle overflow-hidden">
        <TaskListSkeleton count={5} />
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="bg-background-elevated rounded-lg border border-border-subtle p-8">
        <div className="flex flex-col items-center justify-center text-center">
          <div className="w-12 h-12 mb-4 rounded-full bg-accent-error/20 flex items-center justify-center">
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
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
              />
            </svg>
          </div>
          <h3 className="text-heading-md text-text-primary mb-1">
            Something went wrong
          </h3>
          <p className="text-body-sm text-text-secondary mb-4">
            {error}
          </p>
          <Button onClick={onRetry}>
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
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
            Try again
          </Button>
        </div>
      </div>
    );
  }

  // Empty state
  if (tasks.length === 0) {
    return (
      <div className="bg-background-elevated rounded-lg border border-border-subtle">
        <EmptyState filter={filter} onCreateTask={onCreateTask} />
      </div>
    );
  }

  // Task list with animations
  return (
    <div className="bg-background-elevated rounded-lg border border-border-subtle overflow-hidden">
      {/* Task items with AnimatePresence */}
      <div className="divide-y divide-border-subtle">
        <AnimatePresence mode="popLayout" initial={false}>
          {tasks.map((task, index) => (
            <motion.div
              key={task.id}
              layout={!prefersReducedMotion}
              initial={prefersReducedMotion ? false : { opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={prefersReducedMotion ? { opacity: 0 } : { opacity: 0, x: -20 }}
              transition={{
                duration: prefersReducedMotion ? 0 : 0.2,
                delay: prefersReducedMotion ? 0 : index * 0.02,
                layout: { duration: prefersReducedMotion ? 0 : 0.2 },
              }}
            >
              <TaskItem
                task={task}
                isHighlighted={task.id === highlightedTaskId}
                isToggling={task.id === togglingTaskId}
                onToggleStatus={onToggleStatus}
                onEdit={onEdit}
                onDelete={onDelete}
              />
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {/* Load more button */}
      {hasMore && (
        <div className="p-4 border-t border-border-subtle">
          <Button
            variant="secondary"
            onClick={onLoadMore}
            isLoading={isLoadingMore}
            disabled={isLoadingMore}
            className="w-full"
          >
            {isLoadingMore ? 'Loading...' : 'Load More'}
          </Button>
        </div>
      )}
    </div>
  );
}
