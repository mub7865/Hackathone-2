/**
 * Standard root layout for a Next.js 16 App Router project.
 *
 * RULES:
 * - Wraps the entire app with <html> and <body>.
 * - Imports global styles.
 * - Ideal place for top-level providers (theme, query, auth) if needed.
 */

import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "App",
  description: "Next.js App Router application",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
