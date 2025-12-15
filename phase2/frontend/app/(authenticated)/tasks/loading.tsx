import { TaskListSkeleton } from '@/components/ui';

/**
 * Loading state for tasks page - shows skeleton placeholders
 */
export default function TasksLoading() {
  return (
    <div className="max-w-3xl mx-auto p-6">
      {/* Header skeleton */}
      <div className="flex items-center justify-between mb-6">
        <div className="h-8 w-32 bg-gray-200 dark:bg-gray-700 rounded animate-pulse" />
        <div className="h-10 w-28 bg-gray-200 dark:bg-gray-700 rounded animate-pulse" />
      </div>

      {/* Filter tabs skeleton */}
      <div className="flex gap-4 mb-6 border-b border-gray-200 dark:border-gray-700 pb-2">
        <div className="h-8 w-20 bg-gray-200 dark:bg-gray-700 rounded animate-pulse" />
        <div className="h-8 w-24 bg-gray-200 dark:bg-gray-700 rounded animate-pulse" />
        <div className="h-8 w-16 bg-gray-200 dark:bg-gray-700 rounded animate-pulse" />
      </div>

      {/* Task list skeleton */}
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
        <TaskListSkeleton count={5} />
      </div>
    </div>
  );
}
