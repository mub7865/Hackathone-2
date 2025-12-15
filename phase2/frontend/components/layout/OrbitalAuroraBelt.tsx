'use client';

import { useTimeOfDay, useReducedMotion } from '@/hooks';
import type { TimePeriod } from '@/types/theme';

/**
 * Orbital Aurora Belt – Ambient animated elliptical rings
 * Feature: 006-ui-theme-motion (FR-030, FR-030a, FR-031, FR-032, FR-035, FR-036)
 *
 * - 2-3 large ELLIPTICAL rings with gradient borders
 * - Centers positioned OUTSIDE viewport at bottom-left (partially off-screen)
 * - Responsive: rings shift more toward center on mobile/tablet for visibility
 * - Time-of-day gradient colors (including Night)
 * - Very slow rotation/scale animation (45-90s)
 * - Static when prefers-reduced-motion enabled
 * - Higher contrast: brighter aurora on dark background
 */

// Time-of-day color palettes for orbital rings (BRIGHTER for contrast)
const ORBITAL_COLORS: Record<TimePeriod, { primary: string; secondary: string }> = {
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

export function OrbitalAuroraBelt() {
  const timePeriod = useTimeOfDay();
  const prefersReducedMotion = useReducedMotion();
  const colors = ORBITAL_COLORS[timePeriod];

  return (
    <div
      className="fixed inset-0 pointer-events-none overflow-hidden z-0"
      aria-hidden="true"
    >
      {/* Large outer ring - responsive positioning for mobile visibility */}
      <div
        className={`
          absolute
          rounded-[50%]
          ${prefersReducedMotion ? '' : 'animate-orbital'}
          motion-reduce:animate-none

          /* Mobile: smaller, shifted more toward center */
          -bottom-[20%] -left-[5%]
          w-[90vw] h-[60vw]
          opacity-[0.18]

          /* Tablet (md): moderate positioning */
          md:-bottom-[25%] md:-left-[10%]
          md:w-[85vw] md:h-[55vw]
          md:opacity-[0.16]

          /* Desktop (lg+): original positioning */
          lg:-bottom-[30%] lg:-left-[20%]
          lg:w-[80vw] lg:h-[50vw]
          lg:opacity-[0.20]
        `.replace(/\s+/g, ' ').trim()}
        style={{
          background: `linear-gradient(135deg, ${colors.primary}50, ${colors.secondary}40, transparent)`,
          border: `2px solid ${colors.primary}35`,
          boxShadow: `0 0 80px ${colors.primary}25, inset 0 0 50px ${colors.secondary}15`,
        }}
      />

      {/* Medium ring - responsive positioning */}
      <div
        className={`
          absolute
          rounded-[50%]
          ${prefersReducedMotion ? '' : 'animate-orbital-reverse'}
          motion-reduce:animate-none

          /* Mobile: shifted toward center */
          -bottom-[15%] -left-[0%]
          w-[70vw] h-[45vw]
          opacity-[0.15]

          /* Tablet */
          md:-bottom-[20%] md:-left-[8%]
          md:w-[65vw] md:h-[42vw]
          md:opacity-[0.14]

          /* Desktop */
          lg:-bottom-[25%] lg:-left-[15%]
          lg:w-[60vw] lg:h-[40vw]
          lg:opacity-[0.16]
        `.replace(/\s+/g, ' ').trim()}
        style={{
          background: `linear-gradient(45deg, ${colors.secondary}45, ${colors.primary}35, transparent)`,
          border: `1.5px solid ${colors.secondary}30`,
          boxShadow: `0 0 60px ${colors.secondary}20, inset 0 0 40px ${colors.primary}12`,
        }}
      />

      {/* Small inner ring - responsive positioning */}
      <div
        className={`
          absolute
          rounded-[50%]
          ${prefersReducedMotion ? '' : 'animate-orbital-slow'}
          motion-reduce:animate-none

          /* Mobile: shifted toward center */
          -bottom-[10%] left-[5%]
          w-[50vw] h-[35vw]
          opacity-[0.12]

          /* Tablet */
          md:-bottom-[15%] md:left-[0%]
          md:w-[45vw] md:h-[30vw]
          md:opacity-[0.11]

          /* Desktop */
          lg:-bottom-[20%] lg:-left-[10%]
          lg:w-[40vw] lg:h-[28vw]
          lg:opacity-[0.14]
        `.replace(/\s+/g, ' ').trim()}
        style={{
          background: `linear-gradient(225deg, ${colors.primary}40, transparent)`,
          border: `1px solid ${colors.primary}25`,
          boxShadow: `0 0 50px ${colors.primary}15`,
        }}
      />
    </div>
  );
}
