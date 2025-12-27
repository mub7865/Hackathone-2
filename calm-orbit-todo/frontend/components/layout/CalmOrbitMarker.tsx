'use client';

import { useTimeOfDay, useReducedMotion } from '@/hooks';
import type { TimePeriod } from '@/types/theme';

/**
 * Calm Orbit Marker – Small gradient orb in bottom-right corner
 * Feature: 006-ui-theme-motion (FR-033, FR-034, FR-035)
 *
 * - Small circular orb (40-60px diameter)
 * - Position fixed in bottom-right corner
 * - Time-of-day gradient fill (including Night)
 * - Subtle pulse/rotate animation (10-15s loop)
 * - Static when prefers-reduced-motion enabled
 * - Higher contrast: brighter orb on dark background
 */

// Time-of-day color palettes (BRIGHTER for contrast, matching orbital aurora)
const ORB_COLORS: Record<TimePeriod, { primary: string; secondary: string }> = {
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

export function CalmOrbitMarker() {
  const timePeriod = useTimeOfDay();
  const prefersReducedMotion = useReducedMotion();
  const colors = ORB_COLORS[timePeriod];

  return (
    <div
      className="fixed bottom-6 right-6 pointer-events-none z-10"
      aria-hidden="true"
    >
      <div
        className={`
          w-12 h-12
          rounded-full
          ${prefersReducedMotion ? '' : 'animate-orb-pulse'}
          motion-reduce:animate-none
        `.replace(/\s+/g, ' ').trim()}
        style={{
          background: `radial-gradient(circle at 30% 30%, ${colors.primary}a0, ${colors.secondary}80, ${colors.primary}60)`,
          boxShadow: `
            0 0 25px ${colors.primary}50,
            0 0 50px ${colors.secondary}30,
            inset 0 0 20px ${colors.primary}40
          `,
          filter: 'blur(0.5px)',
        }}
      />
    </div>
  );
}
