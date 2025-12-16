'use client';

import { useState, useCallback, useEffect, useRef } from 'react';
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
 * - Responsive design with mobile hamburger menu
 */
export function Header() {
  const pathname = usePathname();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [user, setUser] = useState<{ name?: string | null; email: string } | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const mobileMenuRef = useRef<HTMLDivElement>(null);

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

  // Close mobile menu on route change
  useEffect(() => {
    setIsMobileMenuOpen(false);
  }, [pathname]);

  // Close mobile menu when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (mobileMenuRef.current && !mobileMenuRef.current.contains(event.target as Node)) {
        setIsMobileMenuOpen(false);
      }
    };

    if (isMobileMenuOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isMobileMenuOpen]);

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

  const toggleMobileMenu = useCallback(() => {
    setIsMobileMenuOpen((prev) => !prev);
  }, []);

  // Check if current page is active
  const isActive = (path: string) => pathname === path;

  // Nav link styles
  const navLinkClass = (path: string) => `
    px-3 py-2 rounded-md text-body-sm font-medium
    transition-colors duration-fast
    ${isActive(path)
      ? 'text-accent-primary bg-accent-primary/10'
      : 'text-text-secondary hover:text-text-primary hover:bg-background-surface'
    }
  `.replace(/\s+/g, ' ').trim();

  // Mobile nav link styles
  const mobileNavLinkClass = (path: string) => `
    block px-4 py-3 rounded-md text-base font-medium
    transition-colors duration-fast
    ${isActive(path)
      ? 'text-accent-primary bg-accent-primary/10'
      : 'text-text-secondary hover:text-text-primary hover:bg-background-surface'
    }
  `.replace(/\s+/g, ' ').trim();

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

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center gap-2 sm:gap-4">
            {/* Home link */}
            <Link href="/" className={navLinkClass('/')}>
              Home
            </Link>

            {/* Tasks link */}
            <Link href="/tasks" className={navLinkClass('/tasks')}>
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
                    <Link href="/login" className={navLinkClass('/login')}>
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

          {/* Mobile: Hamburger Button */}
          <button
            type="button"
            onClick={toggleMobileMenu}
            className="md:hidden relative w-10 h-10 flex items-center justify-center rounded-md text-text-secondary hover:text-text-primary hover:bg-background-surface transition-colors duration-fast focus:outline-none focus:ring-2 focus:ring-accent-primary focus:ring-offset-2 focus:ring-offset-background-base"
            aria-expanded={isMobileMenuOpen}
            aria-label="Toggle navigation menu"
          >
            {/* Hamburger Icon with Animation */}
            <div className="w-6 h-5 relative flex flex-col justify-between">
              <span
                className={`
                  block h-0.5 w-6 bg-current rounded-full
                  transition-all duration-300 ease-out origin-center
                  ${isMobileMenuOpen ? 'rotate-45 translate-y-[9px]' : ''}
                `}
              />
              <span
                className={`
                  block h-0.5 w-6 bg-current rounded-full
                  transition-all duration-300 ease-out
                  ${isMobileMenuOpen ? 'opacity-0 scale-x-0' : 'opacity-100 scale-x-100'}
                `}
              />
              <span
                className={`
                  block h-0.5 w-6 bg-current rounded-full
                  transition-all duration-300 ease-out origin-center
                  ${isMobileMenuOpen ? '-rotate-45 -translate-y-[9px]' : ''}
                `}
              />
            </div>
          </button>
        </div>
      </div>

      {/* Mobile Menu Dropdown */}
      <div
        ref={mobileMenuRef}
        className={`
          md:hidden absolute top-full left-0 right-0
          bg-[#1a1a2e] border-b border-border-subtle
          shadow-xl
          transition-all duration-300 ease-out
          ${isMobileMenuOpen
            ? 'opacity-100 translate-y-0 pointer-events-auto'
            : 'opacity-0 -translate-y-2 pointer-events-none'
          }
        `}
      >
        <div className="max-w-7xl mx-auto px-4 py-4 space-y-2">
          {/* Navigation Links */}
          <Link href="/" className={mobileNavLinkClass('/')}>
            Home
          </Link>
          <Link href="/tasks" className={mobileNavLinkClass('/tasks')}>
            Tasks
          </Link>

          {/* Divider */}
          <div className="border-t border-border-subtle my-3" />

          {/* Auth section */}
          {!isLoading && (
            <>
              {isAuthenticated && user ? (
                /* Authenticated: Show user info and sign out */
                <div className="space-y-2">
                  <div className="px-4 py-2 flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-accent-primary/20 flex items-center justify-center text-accent-primary font-semibold">
                      {user.name?.charAt(0).toUpperCase() || user.email.charAt(0).toUpperCase()}
                    </div>
                    <div className="flex-1 min-w-0">
                      {user.name && (
                        <p className="text-sm font-medium text-text-primary truncate">
                          {user.name}
                        </p>
                      )}
                      <p className="text-xs text-text-secondary truncate">
                        {user.email}
                      </p>
                    </div>
                  </div>
                  <button
                    onClick={handleSignOut}
                    className="w-full px-4 py-3 text-left rounded-md text-base font-medium text-status-error hover:bg-status-error/10 transition-colors duration-fast"
                  >
                    Sign Out
                  </button>
                </div>
              ) : (
                /* Not authenticated: Show Login & Get Started */
                <div className="space-y-2">
                  <Link href="/login" className={mobileNavLinkClass('/login')}>
                    Login
                  </Link>
                  <Link
                    href="/register"
                    className="block px-4 py-3 bg-accent-primary text-background-base rounded-md text-base font-medium text-center hover:bg-accent-hover transition-colors duration-fast"
                  >
                    Get Started
                  </Link>
                </div>
              )}
            </>
          )}

          {/* Loading state placeholder */}
          {isLoading && (
            <div className="px-4 py-3">
              <div className="w-full h-10 rounded-md bg-background-surface animate-pulse" />
            </div>
          )}
        </div>
      </div>

      {/* Mobile Menu Backdrop */}
      {isMobileMenuOpen && (
        <div
          className="md:hidden fixed inset-0 top-16 bg-black/20 backdrop-blur-sm z-[-1] transition-opacity duration-300"
          onClick={() => setIsMobileMenuOpen(false)}
          aria-hidden="true"
        />
      )}
    </header>
  );
}
