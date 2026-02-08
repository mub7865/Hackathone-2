/**
 * FeaturesSection Component
 *
 * Showcases 6 key features of the application:
 * - Smart Prioritization
 * - Flexible Organization
 * - Due Dates & Reminders
 * - Recurring Tasks
 * - AI Assistant
 * - Progress Tracking
 */

'use client';

import {
  SparklesIcon,
  TagIcon,
  CalendarIcon,
  ArrowPathIcon,
  ChatBubbleLeftRightIcon,
  ChartBarIcon,
} from '@heroicons/react/24/outline';

const FEATURES = [
  {
    icon: SparklesIcon,
    title: 'Smart Prioritization',
    description: 'Automatically organize tasks by priority. Focus on what matters most with intelligent sorting and color-coded badges.',
    color: 'from-yellow-400 to-orange-500',
  },
  {
    icon: TagIcon,
    title: 'Flexible Organization',
    description: 'Tag and categorize tasks your way. Create custom tags, filter by category, and find what you need instantly.',
    color: 'from-green-400 to-teal-500',
  },
  {
    icon: CalendarIcon,
    title: 'Due Dates & Reminders',
    description: 'Never miss a deadline. Set due dates and get timely reminders so you stay on track with every task.',
    color: 'from-blue-400 to-cyan-500',
  },
  {
    icon: ArrowPathIcon,
    title: 'Recurring Tasks',
    description: 'Automate repetitive work. Set up recurring patterns for daily, weekly, or monthly tasks that repeat automatically.',
    color: 'from-purple-400 to-indigo-500',
  },
  {
    icon: ChatBubbleLeftRightIcon,
    title: 'AI Assistant',
    description: 'Manage tasks with natural language. Chat with our AI to create, update, and organize tasks effortlessly.',
    color: 'from-pink-400 to-rose-500',
  },
  {
    icon: ChartBarIcon,
    title: 'Progress Tracking',
    description: 'Visualize your productivity. Track completion rates, maintain streaks, and celebrate your achievements.',
    color: 'from-violet-400 to-purple-500',
  },
];

export function FeaturesSection() {
  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 bg-background-base">
      <div className="max-w-7xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-4xl sm:text-5xl font-bold text-text-primary mb-4">
            Everything You Need to Stay Organized
          </h2>
          <p className="text-xl text-text-secondary max-w-3xl mx-auto">
            Powerful features designed to help you manage tasks efficiently and achieve your goals faster.
          </p>
        </div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {FEATURES.map((feature, index) => (
            <FeatureCard
              key={feature.title}
              icon={feature.icon}
              title={feature.title}
              description={feature.description}
              color={feature.color}
              delay={index * 0.1}
            />
          ))}
        </div>
      </div>
    </section>
  );
}

interface FeatureCardProps {
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  description: string;
  color: string;
  delay: number;
}

function FeatureCard({ icon: Icon, title, description, color, delay }: FeatureCardProps) {
  return (
    <div
      className="group bg-background-elevated border border-border-subtle rounded-xl p-6 hover:border-border-visible hover:shadow-xl transition-all duration-normal animate-fade-in motion-reduce:animate-none"
      style={{ animationDelay: `${delay}s` }}
    >
      {/* Icon */}
      <div className={`w-14 h-14 rounded-lg bg-gradient-to-br ${color} flex items-center justify-center mb-4 group-hover:scale-110 transition-transform duration-normal`}>
        <Icon className="w-8 h-8 text-white" />
      </div>

      {/* Title */}
      <h3 className="text-xl font-semibold text-text-primary mb-3">
        {title}
      </h3>

      {/* Description */}
      <p className="text-body-sm text-text-secondary leading-relaxed">
        {description}
      </p>
    </div>
  );
}
