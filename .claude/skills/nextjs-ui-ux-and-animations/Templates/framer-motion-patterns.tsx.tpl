/**
 * Reusable Framer Motion patterns for Next.js App Router.
 *
 * PURPOSE:
 * - Centralize animation patterns so pages/components don't reinvent motion.
 * - Keep animations GPU-friendly (transform + opacity only).
 * - Respect `prefers-reduced-motion` for accessible experiences.
 *
 * HOW TO USE:
 * - Place this file under something like `frontend/components/motion/patterns.tsx`.
 * - Import and wrap page sections / cards / buttons as needed.
 */

"use client";

import { ReactNode } from "react";
import {
  motion,
  useReducedMotion,
  MotionProps,
  Variants,
} from "framer-motion";

type MotionDivProps = MotionProps & {
  children: ReactNode;
  className?: string;
};

/* Shared duration + easing tokens (can be moved to a design-tokens file) */
const DURATION_FAST = 0.16;
const DURATION_NORMAL = 0.22;
const DURATION_SLOW = 0.32;

const EASE_OUT = [0.16, 1, 0.3, 1];
const EASE_IN = [0.4, 0, 1, 1];

/**
 * Fade + slight slide-up when component enters viewport.
 * Uses whileInView + viewport options for scroll-based reveal.
 */
export function FadeInSection({
  children,
  className,
  delay = 0,
}: {
  children: ReactNode;
  className?: string;
  delay?: number;
}) {
  const shouldReduceMotion = useReducedMotion();

  if (shouldReduceMotion) {
    return <div className={className}>{children}</div>;
  }

  const variants: Variants = {
    hidden: { opacity: 0, y: 12, filter: "blur(2px)" },
    visible: {
      opacity: 1,
      y: 0,
      filter: "blur(0px)",
      transition: {
        duration: DURATION_NORMAL,
        ease: EASE_OUT,
        delay,
      },
    },
  };

  return (
    <motion.section
      className={className}
      initial="hidden"
      whileInView="visible"
      viewport={{ once: true, amount: 0.18 }}
      variants={variants}
    >
      {children}
    </motion.section>
  );
}

/**
 * Page-level transition wrapper for App Router pages.
 * Wrap the main content of a page with this to get subtle enter/exit motion.
 */
export function PageTransition({ children, className }: MotionDivProps) {
  const shouldReduceMotion = useReducedMotion();

  if (shouldReduceMotion) {
    return <div className={className}>{children}</div>;
  }

  const variants: Variants = {
    initial: { opacity: 0, y: 10 },
    animate: {
      opacity: 1,
      y: 0,
      transition: { duration: DURATION_NORMAL, ease: EASE_OUT },
    },
    exit: {
      opacity: 0,
      y: -4,
      transition: { duration: DURATION_FAST, ease: EASE_IN },
    },
  };

  return (
    <motion.main
      className={className}
      variants={variants}
      initial="initial"
      animate="animate"
      exit="exit"
    >
      {children}
    </motion.main>
  );
}

/**
 * Subtle hover effect for cards / buttons:
 * - Small scale-up + translateY
 * - Soft shadow increase (set via className)
 */
export function HoverLift({ children, className }: MotionDivProps) {
  const shouldReduceMotion = useReducedMotion();

  if (shouldReduceMotion) {
    return <div className={className}>{children}</div>;
  }

  return (
    <motion.div
      className={className}
      whileHover={{
        y: -2,
        scale: 1.02,
        transition: { duration: DURATION_FAST, ease: EASE_OUT },
      }}
      whileTap={{
        y: 0,
        scale: 0.99,
        transition: { duration: DURATION_FAST, ease: EASE_IN },
      }}
    >
      {children}
    </motion.div>
  );
}

/**
 * Staggered list reveal helper: wrap parent in this and apply children
 * as <motion.div> with variants.child.
 */
export const staggerContainer: Variants = {
  hidden: {},
  visible: {
    transition: {
      staggerChildren: 0.06,
      delayChildren: 0.04,
    },
  },
};

export const fadeInUpItem: Variants = {
  hidden: { opacity: 0, y: 10 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: DURATION_NORMAL,
      ease: EASE_OUT,
    },
  },
};

/**
 * Example usage:
 *
 * <motion.ul variants={staggerContainer} initial="hidden" animate="visible">
 *   {items.map(item => (
 *     <motion.li key={item.id} variants={fadeInUpItem}>
 *       ...
 *     </motion.li>
 *   ))}
 * </motion.ul>
 */
