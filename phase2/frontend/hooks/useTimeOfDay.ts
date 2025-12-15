'use client';

import { useState, useEffect } from 'react';
import type { TimePeriod } from '@/types/theme';

/**
 * Hook to detect current time period for time-of-day theming
 * Feature: 006-ui-theme-motion (FR-004, FR-005, FR-006, FR-007, FR-008)
 *
 * Time periods:
 * - morning: 05:00 - 11:59
 * - afternoon: 12:00 - 17:59
 * - evening: 18:00 - 21:59
 * - night: 22:00 - 04:59
 *
 * Uses client's local time for accurate detection.
 *
 * @returns TimePeriod - 'morning' | 'afternoon' | 'evening' | 'night'
 *
 * @example
 * const timePeriod = useTimeOfDay();
 * // Returns 'morning' at 9am, 'afternoon' at 2pm, 'evening' at 8pm, 'night' at 11pm
 */
export function useTimeOfDay(): TimePeriod {
  // Default to 'morning' for SSR - will be updated on client
  const [timePeriod, setTimePeriod] = useState<TimePeriod>('morning');

  useEffect(() => {
    // Detect time period based on current hour
    const detectTimePeriod = (): TimePeriod => {
      const hour = new Date().getHours();

      if (hour >= 5 && hour < 12) {
        return 'morning';
      } else if (hour >= 12 && hour < 18) {
        return 'afternoon';
      } else if (hour >= 18 && hour < 22) {
        return 'evening';
      } else {
        // 22:00 - 04:59
        return 'night';
      }
    };

    // Set initial time period
    setTimePeriod(detectTimePeriod());

    // Optional: Update periodically (every minute) to handle edge cases
    // where user keeps the app open across time boundaries
    const interval = setInterval(() => {
      setTimePeriod(detectTimePeriod());
    }, 60000); // Check every minute

    return () => clearInterval(interval);
  }, []);

  return timePeriod;
}
