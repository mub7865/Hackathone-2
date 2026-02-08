/**
 * ReminderIndicator Component
 *
 * Displays task reminder time with a purple badge and bell icon.
 * Shows relative time (e.g., "in 2 hours", "tomorrow at 9am").
 */

import { BellIcon } from '@heroicons/react/24/outline';

interface ReminderIndicatorProps {
  remindAt: string;
  className?: string;
}

export function ReminderIndicator({ remindAt, className = '' }: ReminderIndicatorProps) {
  const reminderDate = new Date(remindAt);
  const now = new Date();

  // Calculate time difference
  const diffMs = reminderDate.getTime() - now.getTime();
  const diffMinutes = Math.floor(diffMs / (1000 * 60));
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  // Format relative time
  const formatRelativeTime = (): string => {
    if (diffMinutes < 0) {
      return 'Past due';
    } else if (diffMinutes < 60) {
      return `in ${diffMinutes}m`;
    } else if (diffHours < 24) {
      return `in ${diffHours}h`;
    } else if (diffDays === 1) {
      // Tomorrow - show time
      const timeStr = reminderDate.toLocaleTimeString('en-US', {
        hour: 'numeric',
        minute: '2-digit',
        hour12: true
      });
      return `Tomorrow ${timeStr}`;
    } else if (diffDays < 7) {
      // This week - show day and time
      const dayStr = reminderDate.toLocaleDateString('en-US', { weekday: 'short' });
      const timeStr = reminderDate.toLocaleTimeString('en-US', {
        hour: 'numeric',
        minute: '2-digit',
        hour12: true
      });
      return `${dayStr} ${timeStr}`;
    } else {
      // Future - show date and time
      const dateStr = reminderDate.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric'
      });
      const timeStr = reminderDate.toLocaleTimeString('en-US', {
        hour: 'numeric',
        minute: '2-digit',
        hour12: true
      });
      return `${dateStr} ${timeStr}`;
    }
  };

  const label = formatRelativeTime();
  const isPastDue = diffMinutes < 0;

  return (
    <div
      className={`
        flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium border
        transition-all duration-fast
        ${isPastDue
          ? 'bg-red-50 text-red-700 border-red-300 dark:bg-red-900/20 dark:text-red-400 dark:border-red-800'
          : 'bg-purple-50 text-purple-700 border-purple-300 dark:bg-purple-900/20 dark:text-purple-400 dark:border-purple-800'
        }
        ${className}
      `}
      aria-label={`Reminder: ${label}`}
    >
      <BellIcon className="w-4 h-4 flex-shrink-0" aria-hidden="true" />
      <span className="whitespace-nowrap">{label}</span>
    </div>
  );
}
