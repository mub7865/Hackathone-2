import type { Metadata } from 'next';
import Script from 'next/script';
import './globals.css';

export const metadata: Metadata = {
  title: 'Calm Orbit Todo',
  description: 'A calm, focused task manager to organize your day without the overwhelm.',
};

/**
 * Root layout with design system tokens
 * Feature: 006-ui-theme-motion (FR-016)
 * Feature: 009-compliance-fixes (ChatKit integration)
 *
 * - Dark theme by default
 * - Semantic color tokens from globals.css
 * - ChatKit script loaded for AI chat functionality
 */
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <head>
        <Script
          src="https://cdn.platform.openai.com/deployments/chatkit/chatkit.js"
          strategy="beforeInteractive"
        />
      </head>
      <body className="bg-background-base text-text-primary antialiased scrollbar-calm">
        {children}
      </body>
    </html>
  );
}
