'use client';

import { useState } from 'react';
import Link from 'next/link';
import { signUp } from '@/lib/auth/client';
import { Button, Input } from '@/components/ui';

/**
 * Registration page with design system tokens
 * Feature: 006-ui-theme-motion (FR-016)
 *
 * - Semantic color tokens
 * - Smooth focus transitions
 * - Design system consistency
 */
export default function RegisterPage() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

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
      // Use auth client's signUp helper
      await signUp(email, password, name || undefined);

      // Redirect to tasks page (cookie is already set by signUp)
      window.location.href = '/tasks';
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Registration failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="flex min-h-screen items-center justify-center p-4 bg-background-base">
      <div className="w-full max-w-md p-8 bg-background-elevated border border-border-subtle rounded-lg">
        <h1 className="text-heading-lg font-semibold mb-6 text-center text-text-primary">
          Create Account
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
            label="Name (optional)"
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
            <p className="mt-1 text-caption text-text-muted">
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
          >
            Create Account
          </Button>
        </form>

        <p className="mt-6 text-center text-body-sm text-text-secondary">
          Already have an account?{' '}
          <Link
            href="/login"
            className="text-accent-primary hover:text-accent-primary/80 transition-colors duration-fast"
          >
            Sign in
          </Link>
        </p>
      </div>
    </main>
  );
}
