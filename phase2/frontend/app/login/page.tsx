'use client';

import { useState, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { signIn } from '@/lib/auth/client';
import { Button, Input } from '@/components/ui';

/**
 * Login page with design system tokens
 * Feature: 006-ui-theme-motion (FR-016)
 *
 * - Semantic color tokens
 * - Smooth focus transitions
 * - Design system consistency
 */
function LoginForm() {
  const searchParams = useSearchParams();
  const redirectTo = searchParams.get('redirect') || '/tasks';

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    try {
      // Use auth client's signIn helper
      await signIn(email, password);

      // Redirect to tasks page (cookie is already set by signIn)
      window.location.href = redirectTo;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="w-full max-w-md p-8 bg-background-elevated border border-border-subtle rounded-lg">
      <h1 className="text-heading-lg font-semibold mb-6 text-center text-text-primary">
        Sign In
      </h1>

      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div
            className="p-3 text-body-sm text-accent-error bg-accent-error/10 border border-accent-error/20 rounded-md"
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
        >
          Sign In
        </Button>
      </form>

      <p className="mt-6 text-center text-body-sm text-text-secondary">
        Don&apos;t have an account?{' '}
        <Link
          href="/register"
          className="text-accent-primary hover:text-accent-primary/80 transition-colors duration-fast"
        >
          Sign up
        </Link>
      </p>
    </div>
  );
}

/**
 * Login page wrapper
 */
export default function LoginPage() {
  return (
    <main className="flex min-h-screen items-center justify-center p-4 bg-background-base">
      <Suspense
        fallback={
          <div className="w-full max-w-md p-8 bg-background-elevated border border-border-subtle rounded-lg">
            <div className="h-8 w-24 mx-auto mb-6 bg-background-surface rounded animate-pulse" />
            <div className="space-y-4">
              <div className="h-10 bg-background-surface rounded animate-pulse" />
              <div className="h-10 bg-background-surface rounded animate-pulse" />
              <div className="h-10 bg-background-surface rounded animate-pulse" />
            </div>
          </div>
        }
      >
        <LoginForm />
      </Suspense>
    </main>
  );
}
