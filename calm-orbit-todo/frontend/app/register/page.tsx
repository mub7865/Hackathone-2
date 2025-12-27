'use client';

import { useState, useEffect, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { signUp } from '@/lib/auth/client';
import { Button, Input } from '@/components/ui';
import { PageLayout } from '@/components/layout/PageLayout';

/**
 * Registration page with design system tokens and animations
 * Feature: 006-ui-theme-motion (FR-016, FR-022)
 *
 * - Name is required
 * - Redirects to previous page after registration (or home if none)
 * - Semantic color tokens
 * - Smooth focus transitions
 */
function RegisterForm() {
  const searchParams = useSearchParams();
  const redirectParam = searchParams.get('redirect');

  const [redirectTo, setRedirectTo] = useState('/');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  // Set redirect URL on client side
  useEffect(() => {
    if (redirectParam) {
      setRedirectTo(redirectParam);
    } else {
      // Use referrer if available and it's from our site
      const referrer = document.referrer;
      if (referrer && referrer.includes(window.location.host)) {
        const referrerPath = new URL(referrer).pathname;
        // Don't redirect back to login/register pages
        if (referrerPath !== '/login' && referrerPath !== '/register') {
          setRedirectTo(referrerPath);
        }
      }
    }
  }, [redirectParam]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    // Validate name is provided
    if (!name.trim()) {
      setError('Name is required');
      return;
    }

    // Validate passwords match
    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    // Validate password length
    if (password.length < 8) {
      setError('Password must be at least 8 characters');
      return;
    }

    setIsLoading(true);

    try {
      await signUp(email, password, name.trim());
      window.location.href = redirectTo;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Registration failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div
      className="
        w-full max-w-md p-8 bg-background-elevated border border-border-subtle rounded-xl
        animate-scale-in motion-reduce:animate-none
        shadow-xl shadow-black/20
      "
    >
      <h1 className="text-heading-lg font-semibold mb-2 text-center text-text-primary">
        Create Account
      </h1>
      <p className="text-body-sm text-text-muted text-center mb-8">
        Get started with Calm Orbit Todo
      </p>

      <form onSubmit={handleSubmit} className="space-y-5">
        {error && (
          <div
            className="
              p-3 text-body-sm text-accent-error bg-accent-error/10 border border-accent-error/20 rounded-md
              animate-fade-in motion-reduce:animate-none
            "
            role="alert"
          >
            {error}
          </div>
        )}

        <Input
          label="Name"
          type="text"
          value={name}
          onChange={setName}
          placeholder="Enter your name"
          disabled={isLoading}
          autoFocus
        />

        <Input
          label="Email"
          type="email"
          value={email}
          onChange={setEmail}
          placeholder="Enter your email"
          disabled={isLoading}
        />

        <div>
          <Input
            label="Password"
            type="password"
            value={password}
            onChange={setPassword}
            placeholder="Enter your password"
            disabled={isLoading}
          />
          <p className="mt-1.5 text-caption text-text-muted">
            Must be at least 8 characters
          </p>
        </div>

        <Input
          label="Confirm Password"
          type="password"
          value={confirmPassword}
          onChange={setConfirmPassword}
          placeholder="Confirm your password"
          disabled={isLoading}
        />

        <Button
          type="submit"
          isLoading={isLoading}
          disabled={isLoading}
          className="w-full mt-6"
          size="lg"
        >
          Create Account
        </Button>
      </form>

      <p className="mt-8 text-center text-body-sm text-text-secondary">
        Already have an account?{' '}
        <Link
          href={`/login${redirectParam ? `?redirect=${encodeURIComponent(redirectParam)}` : ''}`}
          className="text-accent-primary hover:text-accent-hover transition-colors duration-fast font-medium"
        >
          Sign in
        </Link>
      </p>
    </div>
  );
}

/**
 * Register page wrapper with PageLayout
 */
export default function RegisterPage() {
  return (
    <PageLayout>
      <div className="flex-1 flex items-center justify-center p-4">
        <Suspense
          fallback={
            <div className="w-full max-w-md p-8 bg-background-elevated border border-border-subtle rounded-xl">
              <div className="h-8 w-32 mx-auto mb-6 bg-background-surface rounded animate-pulse" />
              <div className="space-y-4">
                <div className="h-12 bg-background-surface rounded animate-pulse" />
                <div className="h-12 bg-background-surface rounded animate-pulse" />
                <div className="h-12 bg-background-surface rounded animate-pulse" />
                <div className="h-12 bg-background-surface rounded animate-pulse" />
              </div>
            </div>
          }
        >
          <RegisterForm />
        </Suspense>
      </div>
    </PageLayout>
  );
}
