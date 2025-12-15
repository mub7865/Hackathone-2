'use client';

import { ProgressBar } from '@/components/ui';
import type { TaskStats } from '@/hooks';

export interface FocusSummaryPanelProps {
  stats: TaskStats;
  className?: string;
}

/**
 * Focus Summary Panel – Task statistics with progress bar
 * Feature: 006-ui-theme-motion (FR-044, FR-045, FR-046, SC-013)
 *
 * - Displays: pending count, completed count, total count, completion percentage
 * - Includes progress bar reflecting completion percentage
 * - Calm motivational text with actual percentage
 * - Card-like styling with design system tokens
 */
export function FocusSummaryPanel({ stats, className = '' }: FocusSummaryPanelProps) {
  const { pending, completed, total, percentage } = stats;

  return (
    <div
      className={`
        bg-background-elevated border border-border-subtle rounded-lg
        p-4
        ${className}
      `.replace(/\s+/g, ' ').trim()}
    >
      {/* Title */}
      <h3 className="text-heading-md font-semibold text-text-primary mb-4">
        Today&apos;s Focus
      </h3>

      {/* Stats grid */}
      <div className="grid grid-cols-3 gap-3 mb-4">
        <div className="text-center">
          <div className="text-heading-lg font-bold text-accent-primary">
            {pending}
          </div>
          <div className="text-caption text-text-muted">Pending</div>
        </div>
        <div className="text-center">
          <div className="text-heading-lg font-bold text-accent-success">
            {completed}
          </div>
          <div className="text-caption text-text-muted">Completed</div>
        </div>
        <div className="text-center">
          <div className="text-heading-lg font-bold text-text-secondary">
            {total}
          </div>
          <div className="text-caption text-text-muted">Total</div>
        </div>
      </div>

      {/* Progress bar */}
      <ProgressBar percentage={percentage} className="mb-3" />

      {/* Motivational text with percentage */}
      <p className="text-body-sm text-text-secondary text-center">
        {total === 0
          ? "Add your first task to get started."
          : `You're ${percentage}% through today's plan.`}
      </p>
    </div>
  );
}
