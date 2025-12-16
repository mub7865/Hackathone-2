'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { onAuthStateChange, initAuth } from '@/lib/auth/client';
import { PageLayout } from '@/components/layout/PageLayout';

/**
 * Authenticated layout - wraps pages that require authentication
 * Feature: 006-ui-theme-motion
 *
 * - Auth check and redirect to login if not authenticated
 * - Uses unified PageLayout for consistent header/footer/animations
 * - Loading state while checking auth
 */
export default function AuthenticatedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    // Initialize auth on mount
    initAuth();

    // Subscribe to auth state changes
    const unsubscribe = onAuthStateChange((state) => {
      setIsLoading(state.isLoading);

      if (!state.isLoading) {
        const hasSession = state.session !== null;
        setIsAuthenticated(hasSession);

        // Redirect to login if not authenticated
        if (!hasSession) {
          const currentPath = window.location.pathname;
          window.location.href = `/login?redirect=${encodeURIComponent(currentPath)}`;
        }
      }
    });

    // Cleanup subscription on unmount
    return unsubscribe;
  }, [router]);

  // Show loading state while checking auth
  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background-base">
        <div className="w-10 h-10 border-4 border-border-subtle border-t-accent-primary rounded-full animate-spin" />
      </div>
    );
  }

  // Don't render children until authenticated
  if (!isAuthenticated) {
    return null;
  }

  return (
    <PageLayout>
      {children}
    </PageLayout>
  );
}
