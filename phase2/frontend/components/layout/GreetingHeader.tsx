'use client';

import { useTimeOfDay } from '@/hooks';
import { TIME_GREETINGS } from '@/types/theme';

export interface GreetingHeaderProps {
  /**
   * User's name from session (optional)
   * If not provided, shows generic greeting
   */
  userName?: string | null;
  className?: string;
  /**
   * Compact mode for header integration
   * Uses smaller text and horizontal layout
   */
  compact?: boolean;
}

/**
 * Time-aware personalized greeting component
 * Feature: 006-ui-theme-motion (FR-006, FR-007, FR-008, SC-002)
 *
 * - Displays time-appropriate greeting (morning/afternoon/evening)
 * - Shows personalized greeting with user's name if available
 * - Falls back to generic greeting when name is not provided
 * - Subtle fade-in animation on mount
 *
 * @example
 * // With name: "Good morning, Sarah"
 * <GreetingHeader userName="Sarah" />
 *
 * // Without name: "Good afternoon"
 * <GreetingHeader />
 */
export function GreetingHeader({ userName, className = '', compact = false }: GreetingHeaderProps) {
  const timePeriod = useTimeOfDay();
  const greeting = TIME_GREETINGS[timePeriod];

  // Build the full greeting text
  const fullGreeting = userName
    ? `${greeting}, ${userName}`
    : greeting;

  if (compact) {
    // Compact mode: smaller text, text-center for header
    return (
      <div
        className={`
          animate-fade-in motion-reduce:animate-none
          text-center
          ${className}
        `.replace(/\s+/g, ' ').trim()}
      >
        <span className="text-body-sm text-text-primary font-medium">
          {fullGreeting}
        </span>
        <span className="text-body-sm text-text-muted ml-2">
          — {getMotivationalSubtext(timePeriod)}
        </span>
      </div>
    );
  }

  // Default mode: larger text, stacked layout
  return (
    <div
      className={`
        animate-fade-in motion-reduce:animate-none
        ${className}
      `.replace(/\s+/g, ' ').trim()}
    >
      <h1 className="text-heading-lg text-text-primary">
        {fullGreeting}
      </h1>
      <p className="text-body-sm text-text-muted mt-1">
        {getMotivationalSubtext(timePeriod)}
      </p>
    </div>
  );
}

/**
 * Get a calm, motivational subtext based on time of day
 */
function getMotivationalSubtext(timePeriod: 'morning' | 'afternoon' | 'evening' | 'night'): string {
  switch (timePeriod) {
    case 'morning':
      return 'Start your day with intention.';
    case 'afternoon':
      return 'Keep your momentum going.';
    case 'evening':
      return 'Wind down and reflect on your progress.';
    case 'night':
      return 'Rest well, tomorrow awaits.';
  }
}
