import type { Config } from 'tailwindcss';

/**
 * Tailwind CSS Configuration with Design System Tokens
 * Feature: 006-ui-theme-motion
 *
 * Design tokens for the calm, premium dark theme:
 * - Colors: Semantic naming for backgrounds, text, accents, borders
 * - Spacing: Consistent scale (xs through 2xl)
 * - Border Radius: sm (4px), md (8px), lg (12px), xl (16px)
 * - Typography: Heading and body scales
 * - Animation: Fast (150ms), normal (200ms), slow (300ms)
 */

const config: Config = {
  darkMode: 'class', // Enable class-based dark mode
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      /**
       * Semantic Color Tokens
       * Using CSS variables for light/dark mode support
       */
      colors: {
        // Legacy primary colors (kept for backwards compatibility)
        primary: {
          DEFAULT: '#2563eb',
          hover: '#1d4ed8',
        },

        // Background colors - using CSS variables
        background: {
          base: 'rgb(var(--color-bg-base) / <alpha-value>)',
          elevated: 'rgb(var(--color-bg-elevated) / <alpha-value>)',
          surface: 'rgb(var(--color-bg-surface) / <alpha-value>)',
        },

        // Text colors - using CSS variables
        text: {
          primary: 'rgb(var(--color-text-primary) / <alpha-value>)',
          secondary: 'rgb(var(--color-text-secondary) / <alpha-value>)',
          muted: 'rgb(var(--color-text-muted) / <alpha-value>)',
        },

        // Accent colors - same in both modes
        accent: {
          primary: '#3b82f6',   // blue-500
          hover: '#2563eb',     // blue-600
          success: '#10b981',   // emerald-500
          warning: '#f59e0b',   // amber-500
          error: '#ef4444',     // red-500
        },

        // Border colors - using CSS variables
        border: {
          subtle: 'rgb(var(--color-border-subtle) / <alpha-value>)',
          visible: 'rgb(var(--color-border-visible) / <alpha-value>)',
        },
      },

      /**
       * Border Radius Tokens
       * Consistent roundness across the UI
       */
      borderRadius: {
        sm: '4px',
        md: '8px',
        lg: '12px',
        xl: '16px',
      },

      /**
       * Spacing Tokens
       * Tailwind default scale is sufficient, but we document our semantic usage:
       * - xs: 4px (p-1, gap-1)
       * - sm: 8px (p-2, gap-2)
       * - md: 16px (p-4, gap-4)
       * - lg: 24px (p-6, gap-6)
       * - xl: 32px (p-8, gap-8)
       * - 2xl: 48px (p-12, gap-12)
       */

      /**
       * Animation Duration Tokens
       * For consistent micro-interactions
       */
      transitionDuration: {
        fast: '150ms',
        normal: '200ms',
        slow: '300ms',
      },

      /**
       * Animation Keyframes
       * Custom animations for the calm experience
       */
      keyframes: {
        'fade-in': {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        'fade-out': {
          '0%': { opacity: '1' },
          '100%': { opacity: '0' },
        },
        'scale-in': {
          '0%': { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        'scale-out': {
          '0%': { opacity: '1', transform: 'scale(1)' },
          '100%': { opacity: '0', transform: 'scale(0.95)' },
        },
        'slide-in-right': {
          '0%': { opacity: '0', transform: 'translateX(10px)' },
          '100%': { opacity: '1', transform: 'translateX(0)' },
        },
        'slide-out-left': {
          '0%': { opacity: '1', transform: 'translateX(0)' },
          '100%': { opacity: '0', transform: 'translateX(-20px)' },
        },
        'slide-in-down': {
          '0%': { opacity: '0', transform: 'translateY(-10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'pulse-subtle': {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.6' },
        },
      },

      /**
       * Animation Classes
       * Reusable animation presets
       */
      animation: {
        'spin-slow': 'spin 1s linear infinite',
        'fade-in': 'fade-in 200ms ease-out',
        'fade-out': 'fade-out 200ms ease-out',
        'scale-in': 'scale-in 200ms ease-out',
        'scale-out': 'scale-out 200ms ease-out',
        'slide-in-right': 'slide-in-right 200ms ease-out',
        'slide-out-left': 'slide-out-left 200ms ease-out',
        'slide-in-down': 'slide-in-down 200ms ease-out',
        'pulse-subtle': 'pulse-subtle 2s ease-in-out infinite',
      },

      /**
       * Typography - Font Size Scale
       * Using Tailwind defaults with semantic aliases:
       * - heading-lg: text-2xl (24px/32px)
       * - heading-md: text-xl (20px/28px)
       * - body: text-base (16px/24px)
       * - body-sm: text-sm (14px/20px)
       * - caption: text-xs (12px/16px)
       */
      fontSize: {
        'heading-lg': ['1.5rem', { lineHeight: '2rem', fontWeight: '600' }],
        'heading-md': ['1.25rem', { lineHeight: '1.75rem', fontWeight: '600' }],
        'body': ['1rem', { lineHeight: '1.5rem', fontWeight: '400' }],
        'body-sm': ['0.875rem', { lineHeight: '1.25rem', fontWeight: '400' }],
        'caption': ['0.75rem', { lineHeight: '1rem', fontWeight: '400' }],
      },
    },
  },
  plugins: [],
};

export default config;
