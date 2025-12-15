'use client';

import Link from 'next/link';
import { GreetingHeader } from '@/components/layout/GreetingHeader';

/**
 * Home page - Welcome/Landing page
 * Shows greeting and navigation to tasks
 */
export default function HomePage() {
  return (
    <div className="min-h-screen flex flex-col">
      {/* Header */}
      <header className="border-b border-border-subtle bg-background-elevated">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <Link href="/" className="text-xl font-semibold text-text-primary">
            TaskFlow
          </Link>
          <nav className="flex items-center gap-4">
            <Link
              href="/tasks"
              className="text-text-secondary hover:text-text-primary transition-colors duration-fast"
            >
              Tasks
            </Link>
            <Link
              href="/login"
              className="text-text-secondary hover:text-text-primary transition-colors duration-fast"
            >
              Login
            </Link>
            <Link
              href="/register"
              className="px-4 py-2 bg-accent-primary text-background-base rounded-md hover:bg-accent-hover transition-colors duration-fast"
            >
              Get Started
            </Link>
          </nav>
        </div>
      </header>

      {/* Main content */}
      <main className="flex-1 flex items-center justify-center px-6">
        <div className="max-w-2xl text-center">
          {/* Time-aware greeting */}
          <div className="mb-8">
            <GreetingHeader className="mb-4" />
          </div>

          {/* Hero section */}
          <h1 className="text-4xl md:text-5xl font-bold text-text-primary mb-6">
            Organize Your Tasks,{' '}
            <span className="text-accent-primary">Simplify Your Life</span>
          </h1>

          <p className="text-lg text-text-secondary mb-8 max-w-lg mx-auto">
            A calm and focused task management app designed to help you stay productive
            without the overwhelm. Track, organize, and complete your tasks with ease.
          </p>

          {/* CTA buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/register"
              className="px-8 py-3 bg-accent-primary text-background-base rounded-lg font-medium hover:bg-accent-hover transition-all duration-fast active:scale-[0.98]"
            >
              Start For Free
            </Link>
            <Link
              href="/tasks"
              className="px-8 py-3 bg-background-surface text-text-primary border border-border-subtle rounded-lg font-medium hover:bg-background-elevated hover:border-border-visible transition-all duration-fast active:scale-[0.98]"
            >
              View Tasks
            </Link>
          </div>

          {/* Features preview */}
          <div className="mt-16 grid grid-cols-1 sm:grid-cols-3 gap-6">
            <div className="p-6 bg-background-surface rounded-lg border border-border-subtle">
              <div className="w-12 h-12 bg-accent-primary/10 rounded-lg flex items-center justify-center mb-4 mx-auto">
                <svg className="w-6 h-6 text-accent-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
                </svg>
              </div>
              <h3 className="text-text-primary font-medium mb-2">Simple & Clean</h3>
              <p className="text-text-muted text-sm">
                Minimal interface that keeps you focused on what matters.
              </p>
            </div>

            <div className="p-6 bg-background-surface rounded-lg border border-border-subtle">
              <div className="w-12 h-12 bg-accent-primary/10 rounded-lg flex items-center justify-center mb-4 mx-auto">
                <svg className="w-6 h-6 text-accent-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </div>
              <h3 className="text-text-primary font-medium mb-2">Fast & Responsive</h3>
              <p className="text-text-muted text-sm">
                Lightning fast performance with smooth animations.
              </p>
            </div>

            <div className="p-6 bg-background-surface rounded-lg border border-border-subtle">
              <div className="w-12 h-12 bg-accent-primary/10 rounded-lg flex items-center justify-center mb-4 mx-auto">
                <svg className="w-6 h-6 text-accent-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <h3 className="text-text-primary font-medium mb-2">Secure & Private</h3>
              <p className="text-text-muted text-sm">
                Your data is protected with industry-standard security.
              </p>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-border-subtle py-6">
        <div className="max-w-7xl mx-auto px-6 text-center text-text-muted text-sm">
          Built with care for productivity.
        </div>
      </footer>
    </div>
  );
}
