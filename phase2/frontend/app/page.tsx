'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { PageLayout } from '@/components/layout/PageLayout';
import { GreetingHeader } from '@/components/layout/GreetingHeader';
import { getSession, initAuth, onAuthStateChange } from '@/lib/auth/client';

/**
 * Home page - Welcome/Landing page
 * Feature: 006-ui-theme-motion
 *
 * - Premium calm aesthetic matching the app theme
 * - Time-aware greeting with user's name (if logged in)
 * - Feature highlights
 * - Smooth animations
 */
export default function HomePage() {
  const [userName, setUserName] = useState<string | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    initAuth();

    // Check session immediately
    const session = getSession();
    if (session?.user) {
      setIsAuthenticated(true);
      setUserName(session.user.name || null);
    }

    // Subscribe to auth changes
    const unsubscribe = onAuthStateChange((state) => {
      if (!state.isLoading) {
        const hasSession = state.session !== null;
        setIsAuthenticated(hasSession);
        if (hasSession && state.session?.user) {
          setUserName(state.session.user.name || null);
        } else {
          setUserName(null);
        }
      }
    });

    return unsubscribe;
  }, []);

  return (
    <PageLayout>
      <div className="flex-1 flex flex-col">
        {/* Hero Section */}
        <section className="flex-1 flex items-center justify-center px-4 sm:px-6 py-12 lg:py-20">
          <div className="max-w-4xl mx-auto text-center">
            {/* Time-aware greeting with user name */}
            <div className="mb-6 animate-fade-in motion-reduce:animate-none">
              <GreetingHeader userName={userName} className="justify-center" />
            </div>

            {/* Main headline */}
            <h1
              className="
                text-4xl sm:text-5xl lg:text-6xl font-bold text-text-primary mb-6
                animate-fade-in motion-reduce:animate-none
              "
              style={{ animationDelay: '100ms' }}
            >
              Organize Your Tasks,{' '}
              <span className="text-accent-primary">Simplify Your Life</span>
            </h1>

            {/* Subheadline */}
            <p
              className="
                text-lg sm:text-xl text-text-secondary mb-10 max-w-2xl mx-auto
                animate-fade-in motion-reduce:animate-none
              "
              style={{ animationDelay: '200ms' }}
            >
              A calm and focused task management app designed to help you stay productive
              without the overwhelm. Track, organize, and complete your tasks with ease.
            </p>

            {/* CTA buttons - different for authenticated vs non-authenticated */}
            <div
              className="
                flex flex-col sm:flex-row gap-4 justify-center
                animate-fade-in motion-reduce:animate-none
              "
              style={{ animationDelay: '300ms' }}
            >
              {isAuthenticated ? (
                /* Authenticated user - show "Go to Tasks" */
                <Link
                  href="/tasks"
                  className="
                    px-8 py-4 bg-accent-primary text-background-base rounded-lg font-medium text-lg
                    hover:bg-accent-hover transition-all duration-fast
                    active:scale-[0.98] motion-reduce:active:scale-100
                    shadow-lg shadow-accent-primary/20
                  "
                >
                  Go to My Tasks
                </Link>
              ) : (
                /* Non-authenticated - show register/login options */
                <>
                  <Link
                    href="/register"
                    className="
                      px-8 py-4 bg-accent-primary text-background-base rounded-lg font-medium text-lg
                      hover:bg-accent-hover transition-all duration-fast
                      active:scale-[0.98] motion-reduce:active:scale-100
                      shadow-lg shadow-accent-primary/20
                    "
                  >
                    Start For Free
                  </Link>
                  <Link
                    href="/login"
                    className="
                      px-8 py-4 bg-background-surface text-text-primary border border-border-subtle rounded-lg font-medium text-lg
                      hover:bg-background-elevated hover:border-border-visible transition-all duration-fast
                      active:scale-[0.98] motion-reduce:active:scale-100
                    "
                  >
                    Sign In
                  </Link>
                </>
              )}
            </div>
          </div>
        </section>

        {/* Features Section */}
        <section className="px-4 sm:px-6 pb-16 lg:pb-24">
          <div className="max-w-6xl mx-auto">
            <h2
              className="
                text-2xl sm:text-3xl font-semibold text-text-primary text-center mb-12
                animate-fade-in motion-reduce:animate-none
              "
              style={{ animationDelay: '400ms' }}
            >
              Why TaskFlow?
            </h2>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 lg:gap-8">
              {/* Feature 1 */}
              <div
                className="
                  p-6 lg:p-8 bg-background-elevated rounded-lg border border-border-subtle
                  hover:border-border-visible transition-colors duration-fast
                  animate-fade-in motion-reduce:animate-none
                "
                style={{ animationDelay: '500ms' }}
              >
                <div className="w-14 h-14 bg-accent-primary/10 rounded-xl flex items-center justify-center mb-5">
                  <svg className="w-7 h-7 text-accent-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
                  </svg>
                </div>
                <h3 className="text-xl font-semibold text-text-primary mb-3">Simple & Clean</h3>
                <p className="text-text-secondary">
                  Minimal interface that keeps you focused on what matters. No clutter, just clarity.
                </p>
              </div>

              {/* Feature 2 */}
              <div
                className="
                  p-6 lg:p-8 bg-background-elevated rounded-lg border border-border-subtle
                  hover:border-border-visible transition-colors duration-fast
                  animate-fade-in motion-reduce:animate-none
                "
                style={{ animationDelay: '600ms' }}
              >
                <div className="w-14 h-14 bg-accent-primary/10 rounded-xl flex items-center justify-center mb-5">
                  <svg className="w-7 h-7 text-accent-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                </div>
                <h3 className="text-xl font-semibold text-text-primary mb-3">Fast & Responsive</h3>
                <p className="text-text-secondary">
                  Lightning fast performance with smooth animations. Works beautifully on any device.
                </p>
              </div>

              {/* Feature 3 */}
              <div
                className="
                  p-6 lg:p-8 bg-background-elevated rounded-lg border border-border-subtle
                  hover:border-border-visible transition-colors duration-fast
                  animate-fade-in motion-reduce:animate-none
                "
                style={{ animationDelay: '700ms' }}
              >
                <div className="w-14 h-14 bg-accent-primary/10 rounded-xl flex items-center justify-center mb-5">
                  <svg className="w-7 h-7 text-accent-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                  </svg>
                </div>
                <h3 className="text-xl font-semibold text-text-primary mb-3">Secure & Private</h3>
                <p className="text-text-secondary">
                  Your data is protected with industry-standard security. Your tasks, your privacy.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* CTA Section - Only show for non-authenticated users */}
        {!isAuthenticated && (
          <section className="px-4 sm:px-6 pb-16">
            <div
              className="
                max-w-4xl mx-auto bg-background-elevated rounded-2xl border border-border-subtle p-8 lg:p-12 text-center
                animate-fade-in motion-reduce:animate-none
              "
              style={{ animationDelay: '800ms' }}
            >
              <h2 className="text-2xl sm:text-3xl font-semibold text-text-primary mb-4">
                Ready to get organized?
              </h2>
              <p className="text-text-secondary mb-8 max-w-lg mx-auto">
                Join thousands of people who have simplified their task management with TaskFlow.
              </p>
              <Link
                href="/register"
                className="
                  inline-flex px-8 py-4 bg-accent-primary text-background-base rounded-lg font-medium text-lg
                  hover:bg-accent-hover transition-all duration-fast
                  active:scale-[0.98] motion-reduce:active:scale-100
                  shadow-lg shadow-accent-primary/20
                "
              >
                Get Started — It&apos;s Free
              </Link>
            </div>
          </section>
        )}
      </div>
    </PageLayout>
  );
}
