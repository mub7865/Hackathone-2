'use client';

import { useState, useEffect } from 'react';

/**
 * Hook to detect user's motion preference for accessibility
 * Feature: 006-ui-theme-motion (FR-018)
 *
 * Returns true if user has enabled "reduce motion" in their OS/browser settings.
 * Updates reactively when the preference changes.
 *
 * @returns boolean - true if reduced motion is preferred
 *
 * @example
 * const prefersReduced = useReducedMotion();
 * // Use to conditionally skip animations in JS-controlled animations
 */
export function useReducedMotion(): boolean {
  // Default to false for SSR - will be updated on client
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false);

  useEffect(() => {
    // Check if window is available (client-side only)
    if (typeof window === 'undefined') {
      return;
    }

    // Query the media feature
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');

    // Set initial value
    setPrefersReducedMotion(mediaQuery.matches);

    // Handler for preference changes
    const handleChange = (event: MediaQueryListEvent) => {
      setPrefersReducedMotion(event.matches);
    };

    // Listen for changes
    mediaQuery.addEventListener('change', handleChange);

    // Cleanup listener on unmount
    return () => {
      mediaQuery.removeEventListener('change', handleChange);
    };
  }, []);

  return prefersReducedMotion;
}
