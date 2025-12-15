'use client';

export interface ProgressBarProps {
  percentage: number;
  className?: string;
}

/**
 * ProgressBar – Visual progress indicator
 * Feature: 006-ui-theme-motion (FR-045)
 *
 * - Accepts percentage (0-100)
 * - Smooth transition on percentage change
 * - Uses accent-primary color for fill
 * - Respects reduced motion for transitions
 */
export function ProgressBar({ percentage, className = '' }: ProgressBarProps) {
  // Clamp percentage between 0 and 100
  const clampedPercentage = Math.max(0, Math.min(100, percentage));

  return (
    <div
      className={`
        w-full h-2 rounded-full
        bg-background-surface
        overflow-hidden
        ${className}
      `.replace(/\s+/g, ' ').trim()}
      role="progressbar"
      aria-valuenow={clampedPercentage}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-label={`${clampedPercentage}% complete`}
    >
      <div
        className={`
          h-full rounded-full
          bg-accent-primary
          transition-all duration-slow ease-out
          motion-reduce:transition-none
        `.replace(/\s+/g, ' ').trim()}
        style={{ width: `${clampedPercentage}%` }}
      />
    </div>
  );
}
