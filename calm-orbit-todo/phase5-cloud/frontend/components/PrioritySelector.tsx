/**
 * PrioritySelector component for setting task priority levels.
 *
 * This component provides an interface for users to:
 * - Select priority level (high, medium, low)
 * - View visual indicators for each priority level
 * - See color-coded priority badges
 */

'use client';

import { motion } from 'framer-motion';

export type Priority = 'high' | 'medium' | 'low';

interface PrioritySelectorProps {
  value: Priority;
  onChange: (priority: Priority) => void;
  disabled?: boolean;
  size?: 'sm' | 'md' | 'lg';
}

const PRIORITY_CONFIG = {
  high: {
    label: 'High',
    color: 'bg-red-500',
    hoverColor: 'hover:bg-red-600',
    textColor: 'text-red-700',
    bgColor: 'bg-red-50',
    borderColor: 'border-red-500',
    icon: '🔴',
  },
  medium: {
    label: 'Medium',
    color: 'bg-orange-500',
    hoverColor: 'hover:bg-orange-600',
    textColor: 'text-orange-700',
    bgColor: 'bg-orange-50',
    borderColor: 'border-orange-500',
    icon: '🟠',
  },
  low: {
    label: 'Low',
    color: 'bg-green-500',
    hoverColor: 'hover:bg-green-600',
    textColor: 'text-green-700',
    bgColor: 'bg-green-50',
    borderColor: 'border-green-500',
    icon: '🟢',
  },
};

const SIZE_CLASSES = {
  sm: {
    button: 'px-2 py-1 text-xs',
    icon: 'text-sm',
  },
  md: {
    button: 'px-3 py-2 text-sm',
    icon: 'text-base',
  },
  lg: {
    button: 'px-4 py-3 text-base',
    icon: 'text-lg',
  },
};

export default function PrioritySelector({
  value,
  onChange,
  disabled = false,
  size = 'md',
}: PrioritySelectorProps) {
  const priorities: Priority[] = ['high', 'medium', 'low'];
  const sizeClasses = SIZE_CLASSES[size];

  return (
    <div className="flex gap-2">
      {priorities.map((priority) => {
        const config = PRIORITY_CONFIG[priority];
        const isSelected = value === priority;

        return (
          <motion.button
            key={priority}
            type="button"
            onClick={() => !disabled && onChange(priority)}
            disabled={disabled}
            whileHover={!disabled ? { scale: 1.05 } : {}}
            whileTap={!disabled ? { scale: 0.95 } : {}}
            className={`
              ${sizeClasses.button}
              rounded-lg font-medium transition-all duration-200
              flex items-center gap-2
              ${
                isSelected
                  ? `${config.color} text-white border-2 ${config.borderColor}`
                  : `${config.bgColor} ${config.textColor} border-2 border-transparent ${config.hoverColor}`
              }
              ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
            `}
          >
            <span className={sizeClasses.icon}>{config.icon}</span>
            <span>{config.label}</span>
          </motion.button>
        );
      })}
    </div>
  );
}

/**
 * PriorityBadge component for displaying priority in task lists.
 */
interface PriorityBadgeProps {
  priority: Priority;
  size?: 'sm' | 'md' | 'lg';
  showLabel?: boolean;
}

export function PriorityBadge({
  priority,
  size = 'sm',
  showLabel = true,
}: PriorityBadgeProps) {
  const config = PRIORITY_CONFIG[priority];
  const sizeClasses = SIZE_CLASSES[size];

  return (
    <span
      className={`
        inline-flex items-center gap-1
        ${sizeClasses.button}
        ${config.bgColor} ${config.textColor}
        rounded-full font-medium
      `}
    >
      <span className={sizeClasses.icon}>{config.icon}</span>
      {showLabel && <span>{config.label}</span>}
    </span>
  );
}

/**
 * PriorityFilter component for filtering tasks by priority.
 */
interface PriorityFilterProps {
  value: Priority | null;
  onChange: (priority: Priority | null) => void;
}

export function PriorityFilter({ value, onChange }: PriorityFilterProps) {
  const priorities: (Priority | null)[] = [null, 'high', 'medium', 'low'];

  return (
    <div className="flex gap-2 flex-wrap">
      {priorities.map((priority) => {
        const isSelected = value === priority;
        const config = priority ? PRIORITY_CONFIG[priority] : null;

        return (
          <motion.button
            key={priority || 'all'}
            type="button"
            onClick={() => onChange(priority)}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className={`
              px-3 py-1.5 text-sm rounded-lg font-medium transition-all duration-200
              flex items-center gap-1.5
              ${
                isSelected
                  ? priority
                    ? `${config!.color} text-white`
                    : 'bg-blue-500 text-white'
                  : priority
                  ? `${config!.bgColor} ${config!.textColor} hover:${config!.color} hover:text-white`
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }
            `}
          >
            {priority ? (
              <>
                <span>{config!.icon}</span>
                <span>{config!.label}</span>
              </>
            ) : (
              <span>All</span>
            )}
          </motion.button>
        );
      })}
    </div>
  );
}
