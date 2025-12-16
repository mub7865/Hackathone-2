'use client';

import { useState, useCallback, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { ProfileAvatar } from './ProfileAvatar';
import { ProfileDropdown } from './ProfileDropdown';
import { getSession, signOut, onAuthStateChange, initAuth } from '@/lib/auth/client';

/**
 * Unified Header component for all pages
 * Feature: 006-ui-theme-motion
 *
 * - Shows on all pages (home, login, register, tasks)
 * - Shows profile avatar + dropdown when authenticated
 * - Shows Login/Get Started when not authenticated
 * - Responsive design with mobile support
 */
export function Header() {
  const pathname = usePathname();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [user, setUser] = useState<{ name?: string | null; email: string } | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    initAuth();

    const unsubscribe = onAuthStateChange((state) => {
      setIsLoading(state.isLoading);
      if (!state.isLoading) {
        const hasSession = state.session !== null;
        setIsAuthenticated(hasSession);
        if (hasSession && state.session?.user) {
          setUser({
            name: state.session.user.name,
            email: state.session.user.email,
          });
        } else {
          setUser(null);
        }
      }
    });

    // Also check immediate session
    const session = getSession();
    if (session?.user) {
      setIsAuthenticated(true);
      setUser({
        name: session.user.name,
        email: session.user.email,
      });
    }

    return unsubscribe;
  }, []);

  const handleSignOut = useCallback(async () => {
    try {
      localStorage.removeItem('auth_session');
      document.cookie = 'auth_token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
      await signOut();
    } catch (err) {
      console.error('Sign out error:', err);
    }
    window.location.href = '/login';
  }, []);

  const toggleDropdown = useCallback(() => {
    setIsDropdownOpen((prev) => !prev);
  }, []);

  const closeDropdown = useCallback(() => {
    setIsDropdownOpen(false);
  }, []);

  // Check if current page is active
  const isActive = (path: string) => pathname === path;

  return (
    <header className="relative z-20 border-b border-border-subtle bg-background-elevated/95 backdrop-blur-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Left: Logo/Brand */}
          <Link
            href="/"
            className="text-xl font-semibold text-text-primary hover:text-accent-primary transition-colors duration-fast"
          >
            Calm Orbit Todo
          </Link>

          {/* Right: Navigation */}
          <nav className="flex items-center gap-2 sm:gap-4">
            {/* Home link */}
            <Link
              href="/"
              className={`
                px-3 py-2 rounded-md text-body-sm font-medium
                transition-colors duration-fast
                ${isActive('/')
                  ? 'text-accent-primary bg-accent-primary/10'
                  : 'text-text-secondary hover:text-text-primary hover:bg-background-surface'
                }
              `.replace(/\s+/g, ' ').trim()}
            >
              Home
            </Link>

            {/* Tasks link */}
            <Link
              href="/tasks"
              className={`
                px-3 py-2 rounded-md text-body-sm font-medium
                transition-colors duration-fast
                ${isActive('/tasks')
                  ? 'text-accent-primary bg-accent-primary/10'
                  : 'text-text-secondary hover:text-text-primary hover:bg-background-surface'
                }
              `.replace(/\s+/g, ' ').trim()}
            >
              Tasks
            </Link>

            {/* Auth section */}
            {!isLoading && (
              <>
                {isAuthenticated && user ? (
                  /* Authenticated: Show avatar with dropdown */
                  <div className="relative ml-2">
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
                ) : (
                  /* Not authenticated: Show Login & Get Started */
                  <>
                    <Link
                      href="/login"
                      className={`
                        px-3 py-2 rounded-md text-body-sm font-medium
                        transition-colors duration-fast
                        ${isActive('/login')
                          ? 'text-accent-primary bg-accent-primary/10'
                          : 'text-text-secondary hover:text-text-primary hover:bg-background-surface'
                        }
                      `.replace(/\s+/g, ' ').trim()}
                    >
                      Login
                    </Link>
                    <Link
                      href="/register"
                      className="px-4 py-2 bg-accent-primary text-background-base rounded-md text-body-sm font-medium hover:bg-accent-hover transition-colors duration-fast"
                    >
                      Get Started
                    </Link>
                  </>
                )}
              </>
            )}

            {/* Loading state placeholder */}
            {isLoading && (
              <div className="w-10 h-10 rounded-full bg-background-surface animate-pulse" />
            )}
          </nav>
        </div>
      </div>
    </header>
  );
}
