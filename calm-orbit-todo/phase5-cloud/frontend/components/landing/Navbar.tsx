/**
 * Unified Navbar Component - Used across ALL pages
 *
 * Features:
 * - Logo and brand name
 * - Navigation links (Home, Tasks, Chatbot)
 * - Sign In / Sign Up buttons (when not authenticated)
 * - User Profile dropdown (when authenticated)
 * - Responsive mobile menu with smooth animations
 * - Sticky header with backdrop blur
 */

'use client';

import { useState, useMemo, useCallback } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Button } from '@/components/ui/Button';
import { ProfileDropdown } from '@/components/layout/ProfileDropdown';
import { ProfileSettingsModal } from '@/components/profile/ProfileSettingsModal';
import { NotificationSettingsModal } from '@/components/profile/NotificationSettingsModal';
import { ThemeSettingsModal } from '@/components/profile/ThemeSettingsModal';
import { AccountStatsModal } from '@/components/profile/AccountStatsModal';
import { Bars3Icon, XMarkIcon, UserCircleIcon } from '@heroicons/react/24/outline';
import { getSession, signOut } from '@/lib/auth/client';

interface NavbarProps {
  isAuthenticated?: boolean;
}

export function Navbar({ isAuthenticated = false }: NavbarProps) {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [isMobileProfileExpanded, setIsMobileProfileExpanded] = useState(false);
  const [activeModal, setActiveModal] = useState<'profile' | 'notifications' | 'theme' | 'stats' | null>(null);
  const pathname = usePathname();
  const session = getSession();

  // Memoize user object to prevent unnecessary re-renders
  const user = useMemo(() => {
    if (!session?.user) return undefined;
    return {
      name: session.user.name || 'User',
      email: session.user.email
    };
  }, [session?.user?.name, session?.user?.email]);

  const handleOpenModal = useCallback((modalType: 'profile' | 'notifications' | 'theme' | 'stats') => {
    setActiveModal(modalType);
  }, []);

  const handleCloseModal = useCallback(() => {
    setActiveModal(null);
  }, []);

  const isActive = (path: string) => pathname === path;

  // Debug logging
  console.log('🔍 Navbar render:', {
    isMobileMenuOpen,
    isMobileProfileExpanded,
    isAuthenticated
  });

  return (
    <>
    <nav className="sticky top-0 z-50 bg-background-base/80 backdrop-blur-lg border-b border-border-subtle">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo and Brand */}
          <Link href="/" className="flex items-center gap-2 group">
            <div className="w-8 h-8 bg-gradient-to-br from-blue-600 to-purple-600 rounded-lg flex items-center justify-center group-hover:scale-110 transition-transform duration-normal">
              <span className="text-white font-bold text-lg">C</span>
            </div>
            <span className="text-xl font-bold text-text-primary">
              Calm Orbit
            </span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center gap-6">
            <Link
              href="/"
              className={`px-3 py-2 rounded-md text-sm font-medium transition-all duration-fast ${
                isActive('/')
                  ? 'bg-accent-primary/10 text-accent-primary'
                  : 'text-text-secondary hover:text-text-primary hover:bg-background-surface'
              }`}
            >
              Home
            </Link>
            {isAuthenticated && (
              <>
                <Link
                  href="/tasks"
                  className={`px-3 py-2 rounded-md text-sm font-medium transition-all duration-fast ${
                    isActive('/tasks')
                      ? 'bg-accent-primary/10 text-accent-primary'
                      : 'text-text-secondary hover:text-text-primary hover:bg-background-surface'
                  }`}
                >
                  Tasks
                </Link>
                <Link
                  href="/chatbot"
                  className={`px-3 py-2 rounded-md text-sm font-medium transition-all duration-fast ${
                    isActive('/chatbot')
                      ? 'bg-accent-primary/10 text-accent-primary'
                      : 'text-text-secondary hover:text-text-primary hover:bg-background-surface'
                  }`}
                >
                  Chatbot
                </Link>
              </>
            )}
          </div>

          {/* Desktop Auth Buttons / Profile */}
          <div className="hidden md:flex items-center gap-4">
            {!isAuthenticated ? (
              <>
                <Link href="/login">
                  <Button variant="ghost">Sign In</Button>
                </Link>
                <Link href="/register">
                  <Button>Get Started</Button>
                </Link>
              </>
            ) : (
              <div className="relative">
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    setIsProfileOpen(!isProfileOpen);
                  }}
                  className="flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium text-text-secondary hover:text-text-primary hover:bg-background-surface transition-all duration-fast"
                  aria-label="Open profile menu"
                >
                  <UserCircleIcon className="w-6 h-6" />
                  <span>{user?.name || 'User'}</span>
                </button>
                <ProfileDropdown
                  isOpen={isProfileOpen}
                  onClose={() => setIsProfileOpen(false)}
                  onSignOut={async () => {
                    await signOut();
                    window.location.href = '/login';
                  }}
                  user={user}
                  onOpenModal={handleOpenModal}
                />
              </div>
            )}
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className="md:hidden p-2 text-text-secondary hover:text-text-primary transition-colors duration-fast"
            aria-label="Toggle menu"
          >
            {isMobileMenuOpen ? (
              <XMarkIcon className="w-6 h-6 animate-rotate-in motion-reduce:animate-none" />
            ) : (
              <Bars3Icon className="w-6 h-6 animate-rotate-in motion-reduce:animate-none" />
            )}
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      {isMobileMenuOpen && (
        <div className="md:hidden border-t border-border-subtle bg-background-elevated animate-slide-down motion-reduce:animate-none">
          <div className="px-4 py-4 space-y-2">
            <Link
              href="/"
              className={`block px-3 py-2 rounded-md text-base font-medium transition-all duration-fast ${
                isActive('/')
                  ? 'bg-accent-primary/10 text-accent-primary'
                  : 'text-text-secondary hover:text-text-primary hover:bg-background-surface'
              }`}
              onClick={() => setIsMobileMenuOpen(false)}
            >
              Home
            </Link>
            {isAuthenticated && (
              <>
                <Link
                  href="/tasks"
                  className={`block px-3 py-2 rounded-md text-base font-medium transition-all duration-fast ${
                    isActive('/tasks')
                      ? 'bg-accent-primary/10 text-accent-primary'
                      : 'text-text-secondary hover:text-text-primary hover:bg-background-surface'
                  }`}
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  Tasks
                </Link>
                <Link
                  href="/chatbot"
                  className={`block px-3 py-2 rounded-md text-base font-medium transition-all duration-fast ${
                    isActive('/chatbot')
                      ? 'bg-accent-primary/10 text-accent-primary'
                      : 'text-text-secondary hover:text-text-primary hover:bg-background-surface'
                  }`}
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  Chatbot
                </Link>
              </>
            )}

            <div className="pt-4 border-t border-border-subtle space-y-2">
              {!isAuthenticated ? (
                <>
                  <Link href="/login" className="block">
                    <Button variant="ghost" className="w-full">
                      Sign In
                    </Button>
                  </Link>
                  <Link href="/register" className="block">
                    <Button className="w-full">Get Started</Button>
                  </Link>
                </>
              ) : (
                <div className="space-y-2">
                  {/* Mobile Profile Header - Expandable */}
                  <button
                    onClick={(e) => {
                      e.preventDefault();
                      e.stopPropagation();
                      console.log('🔵 Mobile profile clicked, current state:', isMobileProfileExpanded);
                      setIsMobileProfileExpanded(!isMobileProfileExpanded);
                    }}
                    className="w-full flex items-center justify-between px-3 py-2 rounded-md text-base font-medium text-text-secondary hover:text-text-primary hover:bg-background-surface transition-all duration-fast"
                    aria-label="Toggle profile menu"
                  >
                    <div className="flex items-center gap-2">
                      <UserCircleIcon className="w-6 h-6" />
                      <span>{user?.name || 'User'}</span>
                    </div>
                    <svg
                      className={`w-5 h-5 transition-transform duration-fast ${
                        isMobileProfileExpanded ? 'rotate-180' : ''
                      }`}
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                    </svg>
                  </button>

                  {/* Mobile Profile Menu Items */}
                  {isMobileProfileExpanded && (
                    <div className="pl-4 space-y-1 animate-slide-down motion-reduce:animate-none">
                      <button
                        onClick={() => {
                          handleOpenModal('profile');
                          setIsMobileMenuOpen(false);
                          setIsMobileProfileExpanded(false);
                        }}
                        className="w-full flex items-center gap-3 px-3 py-2 rounded-md text-sm text-text-secondary hover:text-text-primary hover:bg-background-surface transition-all duration-fast"
                      >
                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                        <span>Profile Settings</span>
                      </button>

                      <button
                        onClick={() => {
                          handleOpenModal('notifications');
                          setIsMobileMenuOpen(false);
                          setIsMobileProfileExpanded(false);
                        }}
                        className="w-full flex items-center gap-3 px-3 py-2 rounded-md text-sm text-text-secondary hover:text-text-primary hover:bg-background-surface transition-all duration-fast"
                      >
                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                        </svg>
                        <span>Notifications</span>
                      </button>

                      <button
                        onClick={() => {
                          handleOpenModal('theme');
                          setIsMobileMenuOpen(false);
                          setIsMobileProfileExpanded(false);
                        }}
                        className="w-full flex items-center gap-3 px-3 py-2 rounded-md text-sm text-text-secondary hover:text-text-primary hover:bg-background-surface transition-all duration-fast"
                      >
                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                        </svg>
                        <span>Appearance</span>
                      </button>

                      <button
                        onClick={() => {
                          handleOpenModal('stats');
                          setIsMobileMenuOpen(false);
                          setIsMobileProfileExpanded(false);
                        }}
                        className="w-full flex items-center gap-3 px-3 py-2 rounded-md text-sm text-text-secondary hover:text-text-primary hover:bg-background-surface transition-all duration-fast"
                      >
                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                        </svg>
                        <span>Statistics</span>
                      </button>

                      <div className="border-t border-border-subtle my-2" />

                      <button
                        onClick={async () => {
                          await signOut();
                          window.location.href = '/login';
                        }}
                        className="w-full flex items-center gap-3 px-3 py-2 rounded-md text-sm text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 transition-all duration-fast"
                      >
                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                        </svg>
                        <span>Sign Out</span>
                      </button>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </nav>

    {/* Modals rendered at Navbar root level - won't be affected by dropdown re-renders */}
    <>
      <ProfileSettingsModal
        isOpen={activeModal === 'profile'}
        onClose={handleCloseModal}
        user={user}
      />

      <NotificationSettingsModal
        isOpen={activeModal === 'notifications'}
        onClose={handleCloseModal}
      />

      <ThemeSettingsModal
        isOpen={activeModal === 'theme'}
        onClose={handleCloseModal}
      />

      <AccountStatsModal
        isOpen={activeModal === 'stats'}
        onClose={handleCloseModal}
      />
    </>
    </>
  );
}
