/**
 * Theme types for UI Theme, Motion & Calm Experience
 * Feature: 006-ui-theme-motion
 */

/**
 * Time periods for time-of-day theming
 * - morning: 05:00 - 11:59
 * - afternoon: 12:00 - 17:59
 * - evening: 18:00 - 21:59
 * - night: 22:00 - 04:59
 */
export type TimePeriod = 'morning' | 'afternoon' | 'evening' | 'night';

/**
 * Gradient class mapping for time periods
 */
export type GradientMap = Record<TimePeriod, string>;

/**
 * Default gradient classes for each time period
 */
export const TIME_GRADIENTS: GradientMap = {
  morning: 'bg-gradient-morning',
  afternoon: 'bg-gradient-afternoon',
  evening: 'bg-gradient-evening',
  night: 'bg-gradient-night',
};

/**
 * Greeting prefixes for each time period
 */
export const TIME_GREETINGS: Record<TimePeriod, string> = {
  morning: 'Good morning',
  afternoon: 'Good afternoon',
  evening: 'Good evening',
  night: 'Good night',
};
