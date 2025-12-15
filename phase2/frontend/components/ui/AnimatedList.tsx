'use client';

import { AnimatePresence, motion } from 'framer-motion';
import { useReducedMotion } from '@/hooks';
import type { ReactNode } from 'react';

export interface AnimatedListItemProps {
  children: ReactNode;
  itemKey: string;
  index?: number;
}

/**
 * Wrapper for individual animated list items
 * Feature: 006-ui-theme-motion (FR-012, FR-014, FR-015)
 *
 * - Fade + slide enter animation
 * - Fade + slide exit animation
 * - Layout animation for reordering
 * - Respects reduced motion preferences
 */
export function AnimatedListItem({
  children,
  itemKey,
  index = 0,
}: AnimatedListItemProps) {
  const prefersReducedMotion = useReducedMotion();

  // Skip animations if user prefers reduced motion
  if (prefersReducedMotion) {
    return <div key={itemKey}>{children}</div>;
  }

  return (
    <motion.div
      key={itemKey}
      layout
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, x: -20 }}
      transition={{
        duration: 0.2,
        delay: index * 0.02, // Stagger effect
        layout: { duration: 0.2 },
      }}
    >
      {children}
    </motion.div>
  );
}

export interface AnimatedListProps {
  children: ReactNode;
  className?: string;
}

/**
 * Container for animated list with AnimatePresence
 * Feature: 006-ui-theme-motion (FR-012, FR-014, FR-015)
 *
 * Wrap your list items in AnimatedListItem components within this container.
 *
 * @example
 * <AnimatedList>
 *   {items.map((item, index) => (
 *     <AnimatedListItem key={item.id} itemKey={item.id} index={index}>
 *       <YourItemComponent item={item} />
 *     </AnimatedListItem>
 *   ))}
 * </AnimatedList>
 */
export function AnimatedList({ children, className = '' }: AnimatedListProps) {
  return (
    <AnimatePresence mode="popLayout" initial={false}>
      <div className={className}>{children}</div>
    </AnimatePresence>
  );
}
