'use client';

import type { TaskStats } from '@/hooks';

export interface ReflectionPanelProps {
  stats: TaskStats;
  className?: string;
}

/**
 * Reflection Panel – Context-aware motivational text
 * Feature: 006-ui-theme-motion (FR-047, FR-048, SC-014)
 *
 * - Displays title "Reflection"
 * - Motivational text based on simple rules (no AI):
 *   - 0 tasks: "A calm moment — you're all clear."
 *   - 0 completed: "Start with just one small task to build momentum."
 *   - <50%: "Nice start. Keep a steady pace."
 *   - >=50%: "Great progress. Protect your focus and finish strong."
 */

function getReflectionText(stats: TaskStats): string {
  const { total, completed, percentage } = stats;

  if (total === 0) {
    return "A calm moment — you're all clear.";
  }

  if (completed === 0) {
    return "Start with just one small task to build momentum.";
  }

  if (percentage < 50) {
    return "Nice start. Keep a steady pace.";
  }

  return "Great progress. Protect your focus and finish strong.";
}

export function ReflectionPanel({ stats, className = '' }: ReflectionPanelProps) {
  const reflectionText = getReflectionText(stats);

  return (
    <div
      className={`
        bg-background-elevated border border-border-subtle rounded-lg
        p-4
        ${className}
      `.replace(/\s+/g, ' ').trim()}
    >
      {/* Title */}
      <h3 className="text-heading-md font-semibold text-text-primary mb-3">
        Reflection
      </h3>

      {/* Motivational text */}
      <p className="text-body-sm text-text-secondary leading-relaxed">
        {reflectionText}
      </p>
    </div>
  );
}
