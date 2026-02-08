/**
 * RecurringIndicator Component
 *
 * Displays a badge indicating that a task is recurring.
 * Shows an indigo badge with a repeat icon.
 */

import { ArrowPathIcon } from '@heroicons/react/24/outline';

interface RecurringIndicatorProps {
  className?: string;
}

export function RecurringIndicator({ className = '' }: RecurringIndicatorProps) {
  return (
    <div
      className={`
        flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium border
        bg-indigo-50 text-indigo-700 border-indigo-300
        dark:bg-indigo-900/20 dark:text-indigo-400 dark:border-indigo-800
        transition-all duration-fast
        ${className}
      `}
      aria-label="Recurring task"
    >
      <ArrowPathIcon className="w-4 h-4 flex-shrink-0" aria-hidden="true" />
      <span className="whitespace-nowrap">Recurring</span>
    </div>
  );
}
