'use client';

import { useState, useEffect, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { signUp } from '@/lib/auth/client';
import { Button, Input } from '@/components/ui';

/**
 * Modern Register Page with Enhanced UI
 *
 * Features:
 * - Clean card-based design
 * - Smooth animations
 * - Password validation
 * - Responsive layout
 */
function RegisterForm() {
  const searchParams = useSearchParams();
  const redirectParam = searchParams.get('redirect');

  const [redirectTo, setRedirectTo] = useState('/tasks');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (redirectParam) {
      setRedirectTo(redirectParam);
    }
  }, [redirectParam]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!name.trim()) {
      setError('Name is required');
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }

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
    <>
      <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50 dark:from-gray-900 dark:via-purple-900/20 dark:to-blue-900/20">
        <div className="w-full max-w-md">
          {/* Logo */}
          <div className="text-center mb-8 animate-fade-in motion-reduce:animate-none">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-blue-600 to-purple-600 rounded-2xl mb-4 shadow-lg">
              <span className="text-white font-bold text-2xl">C</span>
            </div>
            <h1 className="text-3xl font-bold text-text-primary">Create Account</h1>
            <p className="text-text-secondary mt-2">Get started with Calm Orbit</p>
          </div>

          {/* Register Card */}
          <div
            className="bg-background-elevated border border-border-subtle rounded-2xl p-8 shadow-xl animate-scale-in motion-reduce:animate-none"
            style={{ animationDelay: '0.1s' }}
          >
            <form onSubmit={handleSubmit} className="space-y-5">
              {error && (
                <div
                  className="p-4 text-sm text-accent-error bg-accent-error/10 border border-accent-error/20 rounded-lg animate-fade-in motion-reduce:animate-none"
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
                required
              />

              <Input
                label="Email"
                type="email"
                value={email}
                onChange={setEmail}
                placeholder="Enter your email"
                disabled={isLoading}
                required
              />

              <Input
                label="Password"
                type="password"
                value={password}
                onChange={setPassword}
                placeholder="At least 8 characters"
                disabled={isLoading}
                required
              />

              <Input
                label="Confirm Password"
                type="password"
                value={confirmPassword}
                onChange={setConfirmPassword}
                placeholder="Re-enter your password"
                disabled={isLoading}
                required
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

            <div className="mt-6 text-center">
              <p className="text-sm text-text-secondary">
                Already have an account?{' '}
                <Link
                  href={`/login${redirectParam ? `?redirect=${encodeURIComponent(redirectParam)}` : ''}`}
                  className="text-accent-primary hover:text-accent-hover transition-colors duration-fast font-semibold"
                >
                  Sign in
                </Link>
              </p>
            </div>
          </div>

          {/* Back to Home */}
          <div className="text-center mt-6 animate-fade-in motion-reduce:animate-none" style={{ animationDelay: '0.2s' }}>
            <Link
              href="/"
              className="text-sm text-text-secondary hover:text-text-primary transition-colors duration-fast"
            >
              ← Back to Home
            </Link>
          </div>
        </div>
      </div>
    </>
  );
}

export default function RegisterPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-background-base">
          <div className="w-10 h-10 border-4 border-border-subtle border-t-accent-primary rounded-full animate-spin" />
        </div>
      }
    >
      <RegisterForm />
    </Suspense>
  );
}
