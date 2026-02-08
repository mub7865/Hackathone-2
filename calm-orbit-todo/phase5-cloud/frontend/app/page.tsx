'use client';

import { useEffect, useState } from 'react';
import { Navbar } from '@/components/landing/Navbar';
import { HeroSection } from '@/components/landing/HeroSection';
import { FeaturesSection } from '@/components/landing/FeaturesSection';
import { TestimonialsSection } from '@/components/landing/TestimonialsSection';
import { PricingSection } from '@/components/landing/PricingSection';
import { LandingFooter } from '@/components/landing/LandingFooter';
import { getSession, initAuth, onAuthStateChange } from '@/lib/auth/client';

/**
 * Home page - Market-ready Landing Page
 *
 * Showcases Phase 5 features with:
 * - Navigation header
 * - Hero section with animated background
 * - 6 feature highlights
 * - User testimonials
 * - Pricing tiers
 * - Comprehensive footer
 *
 * Adapts based on authentication state
 */
export default function HomePage() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    initAuth();

    // Check session immediately
    const session = getSession();
    if (session?.user) {
      setIsAuthenticated(true);
    }

    // Subscribe to auth changes
    const unsubscribe = onAuthStateChange((state) => {
      if (!state.isLoading) {
        setIsAuthenticated(state.session !== null);
      }
    });

    return unsubscribe;
  }, []);

  return (
    <main className="min-h-screen bg-background-base">
      <Navbar isAuthenticated={isAuthenticated} />
      <HeroSection isAuthenticated={isAuthenticated} />
      <FeaturesSection />
      <TestimonialsSection />
      <PricingSection />
      <LandingFooter />
    </main>
  );
}
