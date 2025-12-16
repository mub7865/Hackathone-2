'use client';

import { useState, Suspense, useEffect } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { signIn } from '@/lib/auth/client';
import { Button, Input } from '@/components/ui';
import { PageLayout } from '@/components/layout/PageLayout';

/**
 * Login page with design system tokens and animations
 * Feature: 006-ui-theme-motion (FR-016, FR-021)
 *
 * - Redirects to previous page after login (or home if none)
 * - Shows clear error if user is not registered
 * - Semantic color tokens
 * - Smooth focus transitions
 */
function LoginForm() {
  const searchParams = useSearchParams();
  // Get redirect URL from query params, default to current referrer or home
  const redirectParam = searchParams.get('redirect');

  const [redirectTo, setRedirectTo] = useState('/');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
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
    setIsLoading(true);

    try {
      await signIn(email, password);
      window.location.href = redirectTo;
    } catch (err) {
      // Check if it's a "user not found" or "invalid credentials" error
      const errorMessage = err instanceof Error ? err.message : 'Login failed';

      if (errorMessage.toLowerCase().includes('not found') ||
          errorMessage.toLowerCase().includes('invalid') ||
          errorMessage.toLowerCase().includes('unauthorized')) {
        setError('Account not found. Please check your email or register first.');
      } else {
        setError(errorMessage);
      }
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
        Welcome Back
      </h1>
      <p className="text-body-sm text-text-muted text-center mb-8">
        Sign in to continue to Calm Orbit Todo
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
          label="Email"
          type="email"
          value={email}
          onChange={setEmail}
          placeholder="Enter your email"
          disabled={isLoading}
          autoFocus
        />

        <Input
          label="Password"
          type="password"
          value={password}
          onChange={setPassword}
          placeholder="Enter your password"
          disabled={isLoading}
        />

        <Button
          type="submit"
          isLoading={isLoading}
          disabled={isLoading}
          className="w-full mt-6"
          size="lg"
        >
          Sign In
        </Button>
      </form>

      <p className="mt-8 text-center text-body-sm text-text-secondary">
        Don&apos;t have an account?{' '}
        <Link
          href={`/register${redirectParam ? `?redirect=${encodeURIComponent(redirectParam)}` : ''}`}
          className="text-accent-primary hover:text-accent-hover transition-colors duration-fast font-medium"
        >
          Sign up
        </Link>
      </p>
    </div>
  );
}

/**
 * Login page wrapper with PageLayout
 */
export default function LoginPage() {
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
              </div>
            </div>
          }
        >
          <LoginForm />
        </Suspense>
      </div>
    </PageLayout>
  );
}
