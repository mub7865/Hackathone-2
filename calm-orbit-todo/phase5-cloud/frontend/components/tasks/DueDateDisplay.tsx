/**
 * DueDateDisplay Component
 *
 * Displays task due date with color-coded badges based on status:
 * - Red: Overdue (past due date)
 * - Orange: Today (due today)
 * - Blue: Upcoming (future date)
 *
 * Shows special labels for common dates: "Overdue", "Today", "Tomorrow"
 */

import { CalendarIcon } from '@heroicons/react/24/outline';

interface DueDateDisplayProps {
  dueDate: string;
  className?: string;
}

export function DueDateDisplay({ dueDate, className = '' }: DueDateDisplayProps) {
  const date = new Date(dueDate);
  const now = new Date();

  // Reset time to midnight for accurate day comparison
  const dateOnly = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const nowOnly = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  // Calculate difference in days
  const diffTime = dateOnly.getTime() - nowOnly.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  // Determine status
  const isOverdue = diffDays < 0;
  const isToday = diffDays === 0;
  const isTomorrow = diffDays === 1;

  // Format date
  const formatDate = (date: Date): string => {
    const options: Intl.DateTimeFormatOptions = {
      month: 'short',
      day: 'numeric',
      year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined
    };
    return date.toLocaleDateString('en-US', options);
  };

  // Determine label and styling
  let label: string;
  let badgeClasses: string;

  if (isOverdue) {
    label = 'Overdue';
    badgeClasses = 'bg-red-50 text-red-700 border-red-300 dark:bg-red-900/20 dark:text-red-400 dark:border-red-800';
  } else if (isToday) {
    label = 'Today';
    badgeClasses = 'bg-orange-50 text-orange-700 border-orange-300 dark:bg-orange-900/20 dark:text-orange-400 dark:border-orange-800';
  } else if (isTomorrow) {
    label = 'Tomorrow';
    badgeClasses = 'bg-blue-50 text-blue-700 border-blue-300 dark:bg-blue-900/20 dark:text-blue-400 dark:border-blue-800';
  } else {
    label = formatDate(date);
    badgeClasses = 'bg-blue-50 text-blue-700 border-blue-300 dark:bg-blue-900/20 dark:text-blue-400 dark:border-blue-800';
  }

  return (
    <div
      className={`
        flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium border
        transition-all duration-fast
        ${badgeClasses}
        ${className}
      `}
      aria-label={`Due date: ${label}`}
    >
      <CalendarIcon className="w-4 h-4 flex-shrink-0" aria-hidden="true" />
      <span className="whitespace-nowrap">{label}</span>
    </div>
  );
}
