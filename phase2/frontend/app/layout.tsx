import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Tasks',
  description: 'Manage your tasks efficiently',
};

/**
 * Root layout with design system tokens
 * Feature: 006-ui-theme-motion (FR-016)
 *
 * - Dark theme by default
 * - Semantic color tokens from globals.css
 */
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className="bg-background-base text-text-primary antialiased scrollbar-calm">
        {children}
      </body>
    </html>
  );
}
