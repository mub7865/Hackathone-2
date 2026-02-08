/**
 * HeroSection Component
 *
 * Hero section for landing page with:
 * - Animated gradient background
 * - Compelling headline and subheadline
 * - CTA buttons (Start Free Trial + Sign In)
 * - Social proof
 * - Responsive design
 */

'use client';

import Link from 'next/link';
import { Button } from '@/components/ui/Button';
import { CheckCircleIcon } from '@heroicons/react/24/solid';

interface HeroSectionProps {
  isAuthenticated?: boolean;
}

export function HeroSection({ isAuthenticated = false }: HeroSectionProps) {
  return (
    <section className="relative min-h-[90vh] flex items-center justify-center overflow-hidden bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50 dark:from-gray-900 dark:via-purple-900/20 dark:to-blue-900/20">
      {/* Animated Background Orbs */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-blue-400/30 rounded-full blur-3xl animate-float motion-reduce:animate-none" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-purple-400/30 rounded-full blur-3xl animate-float-delayed motion-reduce:animate-none" />
        <div className="absolute top-1/2 left-1/2 w-96 h-96 bg-pink-400/20 rounded-full blur-3xl animate-float-slow motion-reduce:animate-none" />
      </div>

      {/* Content */}
      <div className="relative z-10 max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-20 text-center">
        {/* Headline */}
        <h1 className="text-5xl sm:text-6xl lg:text-7xl font-bold text-text-primary mb-6 animate-fade-in motion-reduce:animate-none">
          Organize Your Life,{' '}
          <span className="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
            Effortlessly
          </span>
        </h1>

        {/* Subheadline */}
        <p className="text-xl sm:text-2xl text-text-secondary max-w-3xl mx-auto mb-8 animate-fade-in motion-reduce:animate-none" style={{ animationDelay: '0.1s' }}>
          The intelligent task manager that adapts to your workflow.
          Prioritize what matters, automate the rest, and achieve more with less stress.
        </p>

        {/* CTA Buttons */}
        {!isAuthenticated ? (
          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-12 animate-fade-in motion-reduce:animate-none" style={{ animationDelay: '0.2s' }}>
            <Link href="/register">
              <Button
                size="lg"
                className="text-lg px-8 py-4 shadow-lg hover:shadow-xl transition-shadow duration-normal"
              >
                Start Free Trial
              </Button>
            </Link>
            <Link href="/login">
              <Button
                variant="secondary"
                size="lg"
                className="text-lg px-8 py-4"
              >
                Sign In
              </Button>
            </Link>
          </div>
        ) : (
          <div className="flex justify-center mb-12 animate-fade-in motion-reduce:animate-none" style={{ animationDelay: '0.2s' }}>
            <Link href="/tasks">
              <Button
                size="lg"
                className="text-lg px-8 py-4 shadow-lg hover:shadow-xl transition-shadow duration-normal"
              >
                Go to Dashboard
              </Button>
            </Link>
          </div>
        )}

        {/* Social Proof */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-6 text-text-secondary animate-fade-in motion-reduce:animate-none" style={{ animationDelay: '0.3s' }}>
          <div className="flex items-center gap-2">
            <div className="flex -space-x-2">
              {[1, 2, 3, 4].map((i) => (
                <div
                  key={i}
                  className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-400 to-purple-500 border-2 border-white dark:border-gray-900 flex items-center justify-center text-white font-semibold text-sm"
                >
                  {String.fromCharCode(64 + i)}
                </div>
              ))}
            </div>
            <span className="text-sm font-medium">
              Join 10,000+ productive users
            </span>
          </div>

          <div className="hidden sm:block w-px h-6 bg-border-subtle" />

          <div className="flex items-center gap-2">
            <div className="flex gap-1">
              {[1, 2, 3, 4, 5].map((i) => (
                <svg
                  key={i}
                  className="w-5 h-5 text-yellow-400 fill-current"
                  viewBox="0 0 20 20"
                >
                  <path d="M10 15l-5.878 3.09 1.123-6.545L.489 6.91l6.572-.955L10 0l2.939 5.955 6.572.955-4.756 4.635 1.123 6.545z" />
                </svg>
              ))}
            </div>
            <span className="text-sm font-medium">4.9/5 rating</span>
          </div>
        </div>

        {/* Feature Highlights */}
        <div className="mt-16 grid grid-cols-1 sm:grid-cols-3 gap-6 max-w-4xl mx-auto animate-fade-in motion-reduce:animate-none" style={{ animationDelay: '0.4s' }}>
          <FeatureHighlight
            icon={<CheckCircleIcon className="w-6 h-6" />}
            text="Smart prioritization"
          />
          <FeatureHighlight
            icon={<CheckCircleIcon className="w-6 h-6" />}
            text="AI-powered assistant"
          />
          <FeatureHighlight
            icon={<CheckCircleIcon className="w-6 h-6" />}
            text="Works on all devices"
          />
        </div>
      </div>
    </section>
  );
}

interface FeatureHighlightProps {
  icon: React.ReactNode;
  text: string;
}

function FeatureHighlight({ icon, text }: FeatureHighlightProps) {
  return (
    <div className="flex items-center justify-center gap-2 text-text-primary">
      <span className="text-green-500">{icon}</span>
      <span className="text-sm font-medium">{text}</span>
    </div>
  );
}
