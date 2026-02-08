/**
 * PricingSection Component
 *
 * Displays 3 pricing tiers:
 * - Free: Up to 50 tasks, basic features
 * - Pro: Unlimited tasks, AI assistant, $9/month (highlighted)
 * - Enterprise: Custom pricing, dedicated support
 */

'use client';

import Link from 'next/link';
import { Button } from '@/components/ui/Button';
import { CheckIcon } from '@heroicons/react/24/solid';

const PRICING_TIERS = [
  {
    name: 'Free',
    price: '$0',
    period: 'forever',
    description: 'Perfect for getting started',
    features: [
      'Up to 50 tasks',
      'Basic prioritization',
      'Tags and categories',
      'Due dates and reminders',
      'Mobile and desktop apps',
      'Email support',
    ],
    cta: 'Start Free',
    ctaLink: '/signup',
    highlighted: false,
  },
  {
    name: 'Pro',
    price: '$9',
    period: 'per month',
    description: 'For power users who want it all',
    features: [
      'Unlimited tasks',
      'AI-powered assistant',
      'Recurring tasks',
      'Advanced analytics',
      'Priority support',
      'Custom themes',
      'Export and backup',
      'Team collaboration (coming soon)',
    ],
    cta: 'Start Free Trial',
    ctaLink: '/signup?plan=pro',
    highlighted: true,
    badge: 'Most Popular',
  },
  {
    name: 'Enterprise',
    price: 'Custom',
    period: 'contact us',
    description: 'For teams and organizations',
    features: [
      'Everything in Pro',
      'Unlimited team members',
      'Dedicated account manager',
      'Custom integrations',
      'SLA guarantee',
      'Advanced security',
      'On-premise deployment',
      'Training and onboarding',
    ],
    cta: 'Contact Sales',
    ctaLink: '/contact',
    highlighted: false,
  },
];

export function PricingSection() {
  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 bg-background-base">
      <div className="max-w-7xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-4xl sm:text-5xl font-bold text-text-primary mb-4">
            Simple, Transparent Pricing
          </h2>
          <p className="text-xl text-text-secondary max-w-3xl mx-auto">
            Choose the plan that's right for you. All plans include a 14-day free trial.
          </p>
        </div>

        {/* Pricing Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {PRICING_TIERS.map((tier, index) => (
            <PricingCard
              key={tier.name}
              {...tier}
              delay={index * 0.1}
            />
          ))}
        </div>

        {/* FAQ Note */}
        <div className="mt-16 text-center">
          <p className="text-sm text-text-secondary">
            All plans include a 14-day free trial. No credit card required.{' '}
            <Link href="/faq" className="text-accent-primary hover:text-accent-hover underline">
              View FAQ
            </Link>
          </p>
        </div>
      </div>
    </section>
  );
}

interface PricingCardProps {
  name: string;
  price: string;
  period: string;
  description: string;
  features: string[];
  cta: string;
  ctaLink: string;
  highlighted: boolean;
  badge?: string;
  delay: number;
}

function PricingCard({
  name,
  price,
  period,
  description,
  features,
  cta,
  ctaLink,
  highlighted,
  badge,
  delay,
}: PricingCardProps) {
  return (
    <div
      className={`relative bg-background-elevated border rounded-xl p-8 transition-all duration-normal animate-fade-in motion-reduce:animate-none ${
        highlighted
          ? 'border-accent-primary shadow-xl scale-105 md:scale-110'
          : 'border-border-subtle hover:border-border-visible hover:shadow-lg'
      }`}
      style={{ animationDelay: `${delay}s` }}
    >
      {/* Badge */}
      {badge && (
        <div className="absolute -top-4 left-1/2 -translate-x-1/2">
          <span className="inline-block px-4 py-1 bg-gradient-to-r from-accent-primary to-accent-hover text-white text-sm font-semibold rounded-full shadow-lg">
            {badge}
          </span>
        </div>
      )}

      {/* Header */}
      <div className="text-center mb-6">
        <h3 className="text-2xl font-bold text-text-primary mb-2">{name}</h3>
        <p className="text-sm text-text-secondary mb-4">{description}</p>
        <div className="flex items-baseline justify-center gap-1">
          <span className="text-5xl font-bold text-text-primary">{price}</span>
          {price !== 'Custom' && (
            <span className="text-text-secondary">/{period}</span>
          )}
        </div>
        {price === 'Custom' && (
          <span className="text-sm text-text-secondary">{period}</span>
        )}
      </div>

      {/* CTA Button */}
      <Link href={ctaLink} className="block mb-6">
        <Button
          className="w-full"
          variant={highlighted ? 'primary' : 'secondary'}
          size="lg"
        >
          {cta}
        </Button>
      </Link>

      {/* Features List */}
      <ul className="space-y-3">
        {features.map((feature) => (
          <li key={feature} className="flex items-start gap-3">
            <CheckIcon className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" />
            <span className="text-sm text-text-secondary">{feature}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}
