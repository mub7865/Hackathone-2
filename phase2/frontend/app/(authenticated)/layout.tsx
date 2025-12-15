'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { onAuthStateChange, initAuth, getSession, signOut } from '@/lib/auth/client';
import { OrbitalAuroraBelt } from '@/components/layout/OrbitalAuroraBelt';
import { CalmOrbitMarker } from '@/components/layout/CalmOrbitMarker';
import { ProfileAvatar } from '@/components/layout/ProfileAvatar';
import { ProfileDropdown } from '@/components/layout/ProfileDropdown';
import { GreetingHeader } from '@/components/layout/GreetingHeader';
import { Footer } from '@/components/layout/Footer';

/**
 * Authenticated layout with Wow Layer
 * Feature: 006-ui-theme-motion (FR-030, FR-033, FR-037, FR-043, FR-050)
 *
 * - Orbital Aurora Belt (ambient background)
 * - Calm Orbit Marker (corner orb)
 * - Refined header with profile avatar dropdown
 * - Sticky footer pattern
 * - Responsive header: desktop 3-column, mobile stacked
 */
export default function AuthenticatedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

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

  const handleSignOut = useCallback(async () => {
    console.log('handleSignOut called in layout'); // Debug
    try {
      // Clear session first
      localStorage.removeItem('auth_session');
      document.cookie = 'auth_token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
      await signOut();
      console.log('signOut completed'); // Debug
    } catch (err) {
      console.error('Sign out error:', err);
    }
    // Force redirect to login
    console.log('Redirecting to /login'); // Debug
    window.location.href = '/login';
  }, []);

  const toggleDropdown = useCallback(() => {
    setIsDropdownOpen((prev) => !prev);
  }, []);

  const closeDropdown = useCallback(() => {
    setIsDropdownOpen(false);
  }, []);

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

  const session = getSession();
  const user = session?.user || { email: 'user@example.com', name: undefined };

  return (
    <div className="min-h-screen bg-background-base flex flex-col">
      {/* Ambient Background */}
      <OrbitalAuroraBelt />
      <CalmOrbitMarker />

      {/* Header */}
      <header className="relative z-20 border-b border-border-subtle bg-background-elevated/95 backdrop-blur-sm">
        {/* Desktop layout: 3-column */}
        <div className="hidden lg:flex items-center justify-between px-8 py-4">
          {/* Left: Title */}
          <h1 className="text-heading-md font-semibold text-text-primary">
            Tasks
          </h1>

          {/* Center: Greeting */}
          <div className="flex-1 flex justify-center">
            <GreetingHeader userName={user.name} compact />
          </div>

          {/* Right: Avatar with dropdown */}
          <div className="relative">
            <ProfileAvatar
              user={user}
              onClick={toggleDropdown}
              isExpanded={isDropdownOpen}
            />
            <ProfileDropdown
              isOpen={isDropdownOpen}
              onClose={closeDropdown}
              onSignOut={handleSignOut}
            />
          </div>
        </div>

        {/* Mobile layout: stacked */}
        <div className="lg:hidden">
          {/* Top row: Title + Avatar */}
          <div className="flex items-center justify-between px-4 py-3">
            <h1 className="text-heading-md font-semibold text-text-primary">
              Tasks
            </h1>
            <div className="relative">
              <ProfileAvatar
                user={user}
                onClick={toggleDropdown}
                isExpanded={isDropdownOpen}
              />
              <ProfileDropdown
                isOpen={isDropdownOpen}
                onClose={closeDropdown}
                onSignOut={handleSignOut}
              />
            </div>
          </div>

          {/* Second row: Greeting */}
          <div className="px-4 pb-3">
            <GreetingHeader userName={user.name} compact />
          </div>
        </div>
      </header>

      {/* Main content - flex-grow for sticky footer */}
      <main className="relative z-10 flex-grow">
        {children}
      </main>

      {/* Footer */}
      <Footer />
    </div>
  );
}
