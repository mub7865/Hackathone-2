'use client';

import { useTimeOfDay } from '@/hooks';
import type { TimePeriod } from '@/types/theme';

export interface ProfileAvatarProps {
  user: {
    name?: string | null;
    email: string;
  };
  onClick: () => void;
  isExpanded: boolean;
}

/**
 * Profile Avatar – Circular avatar with user initials and time-of-day gradient
 * Feature: 006-ui-theme-motion (FR-038, SC-011)
 *
 * - Circular with time-of-day aware gradient background
 * - Displays user initials (first letter of first/last name, or first letter of email)
 * - Keyboard accessible (focusable, Enter to activate)
 * - ARIA attributes for dropdown trigger
 */

// Time-of-day color palettes (BRIGHTER for contrast, matching orbital aurora)
const AVATAR_COLORS: Record<TimePeriod, { primary: string; secondary: string }> = {
  morning: {
    primary: '#93c5fd', // brighter soft blue (blue-300)
    secondary: '#5eead4', // brighter teal (teal-300)
  },
  afternoon: {
    primary: '#60a5fa', // brighter blue (blue-400)
    secondary: '#67e8f9', // brighter cyan (cyan-300)
  },
  evening: {
    primary: '#c4b5fd', // brighter purple (violet-300)
    secondary: '#818cf8', // brighter indigo (indigo-400)
  },
  night: {
    primary: '#a78bfa', // violet-400 (lighter than background)
    secondary: '#6366f1', // indigo-500
  },
};

/**
 * Extract initials from user name or email
 * - "Sarah Johnson" → "SJ"
 * - "Madonna" → "M"
 * - No name, email "alex@example.com" → "A"
 */
function getInitials(name?: string | null, email?: string): string {
  if (name && name.trim()) {
    const words = name.trim().split(/\s+/);
    if (words.length >= 2) {
      return (words[0][0] + words[words.length - 1][0]).toUpperCase();
    }
    return words[0][0].toUpperCase();
  }

  if (email) {
    return email[0].toUpperCase();
  }

  return '?';
}

export function ProfileAvatar({ user, onClick, isExpanded }: ProfileAvatarProps) {
  const timePeriod = useTimeOfDay();
  const colors = AVATAR_COLORS[timePeriod];
  const initials = getInitials(user.name, user.email);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onClick();
    }
  };

  return (
    <button
      type="button"
      onClick={onClick}
      onKeyDown={handleKeyDown}
      aria-haspopup="menu"
      aria-expanded={isExpanded}
      aria-label="Open profile menu"
      className={`
        relative w-10 h-10 rounded-full
        flex items-center justify-center
        text-white font-medium text-body-sm
        transition-all duration-fast
        focus:outline-none focus:ring-2 focus:ring-accent-primary focus:ring-offset-2 focus:ring-offset-background-base
        hover:scale-105
        active:scale-95
        motion-reduce:transition-none motion-reduce:hover:scale-100 motion-reduce:active:scale-100
      `.replace(/\s+/g, ' ').trim()}
      style={{
        background: `linear-gradient(135deg, ${colors.primary}, ${colors.secondary})`,
        boxShadow: `0 2px 8px ${colors.primary}40`,
      }}
    >
      {initials}
    </button>
  );
}
