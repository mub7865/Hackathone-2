/**
 * TestimonialsSection Component
 *
 * Displays user testimonials with:
 * - Avatar, name, role
 * - Quote/testimonial text
 * - Star rating
 * - Responsive grid layout
 */

'use client';

const TESTIMONIALS = [
  {
    name: 'Sarah Johnson',
    role: 'Product Manager',
    avatar: 'SJ',
    quote: 'Calm Orbit has transformed how I manage my projects. The AI assistant understands exactly what I need, and the recurring tasks feature saves me hours every week.',
    rating: 5,
    color: 'from-blue-400 to-cyan-500',
  },
  {
    name: 'Michael Chen',
    role: 'Software Engineer',
    avatar: 'MC',
    quote: 'The smart prioritization is a game-changer. I no longer feel overwhelmed by my task list. Everything is organized exactly how I need it.',
    rating: 5,
    color: 'from-purple-400 to-pink-500',
  },
  {
    name: 'Emily Rodriguez',
    role: 'Freelance Designer',
    avatar: 'ER',
    quote: 'I love the clean interface and powerful features. The reminders keep me on track, and the progress tracking motivates me to stay productive.',
    rating: 5,
    color: 'from-green-400 to-teal-500',
  },
];

export function TestimonialsSection() {
  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-br from-purple-50 via-blue-50 to-cyan-50 dark:from-gray-900 dark:via-purple-900/10 dark:to-blue-900/10">
      <div className="max-w-7xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-4xl sm:text-5xl font-bold text-text-primary mb-4">
            Loved by Productive People
          </h2>
          <p className="text-xl text-text-secondary max-w-3xl mx-auto">
            Join thousands of users who have transformed their productivity with Calm Orbit.
          </p>
        </div>

        {/* Testimonials Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {TESTIMONIALS.map((testimonial, index) => (
            <TestimonialCard
              key={testimonial.name}
              {...testimonial}
              delay={index * 0.1}
            />
          ))}
        </div>
      </div>
    </section>
  );
}

interface TestimonialCardProps {
  name: string;
  role: string;
  avatar: string;
  quote: string;
  rating: number;
  color: string;
  delay: number;
}

function TestimonialCard({ name, role, avatar, quote, rating, color, delay }: TestimonialCardProps) {
  return (
    <div
      className="bg-background-elevated border border-border-subtle rounded-xl p-6 hover:border-border-visible hover:shadow-xl transition-all duration-normal animate-fade-in motion-reduce:animate-none"
      style={{ animationDelay: `${delay}s` }}
    >
      {/* Rating Stars */}
      <div className="flex gap-1 mb-4">
        {Array.from({ length: rating }).map((_, i) => (
          <svg
            key={i}
            className="w-5 h-5 text-yellow-400 fill-current"
            viewBox="0 0 20 20"
          >
            <path d="M10 15l-5.878 3.09 1.123-6.545L.489 6.91l6.572-.955L10 0l2.939 5.955 6.572.955-4.756 4.635 1.123 6.545z" />
          </svg>
        ))}
      </div>

      {/* Quote */}
      <blockquote className="text-body-md text-text-secondary mb-6 leading-relaxed">
        "{quote}"
      </blockquote>

      {/* Author */}
      <div className="flex items-center gap-3 pt-4 border-t border-border-subtle">
        <div className={`w-12 h-12 rounded-full bg-gradient-to-br ${color} flex items-center justify-center text-white font-semibold`}>
          {avatar}
        </div>
        <div>
          <p className="font-semibold text-text-primary">{name}</p>
          <p className="text-sm text-text-secondary">{role}</p>
        </div>
      </div>
    </div>
  );
}
