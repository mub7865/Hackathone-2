'use client';

export interface SkeletonProps {
  className?: string;
  variant?: 'text' | 'circular' | 'rectangular';
  width?: string | number;
  height?: string | number;
}

/**
 * Skeleton loading placeholder with calm, subtle pulse animation
 * Feature: 006-ui-theme-motion (FR-023, FR-024)
 *
 * - Uses semantic color tokens (calm background)
 * - Subtle opacity-based pulse (2s duration)
 * - Respects reduced motion (static, no pulse)
 */
export function Skeleton({
  className = '',
  variant = 'rectangular',
  width,
  height,
}: SkeletonProps) {
  // Base styles with calm colors and subtle animation
  const baseStyles = `
    bg-background-surface
    animate-pulse-subtle
    motion-reduce:animate-none
  `;

  // Variant-specific styles
  const variantStyles = {
    text: 'rounded',
    circular: 'rounded-full',
    rectangular: 'rounded-md',
  };

  // Build inline styles for custom dimensions
  const style: React.CSSProperties = {};
  if (width) {
    style.width = typeof width === 'number' ? `${width}px` : width;
  }
  if (height) {
    style.height = typeof height === 'number' ? `${height}px` : height;
  }

  const combinedClassName = `
    ${baseStyles}
    ${variantStyles[variant]}
    ${className}
  `.replace(/\s+/g, ' ').trim();

  return <div className={combinedClassName} style={style} aria-hidden="true" />;
}

/**
 * Task item skeleton for loading states
 * Uses design system colors for calm appearance
 */
export function TaskItemSkeleton() {
  return (
    <div className="flex items-center gap-3 p-4 border-b border-border-subtle">
      <Skeleton variant="circular" className="w-5 h-5 flex-shrink-0" />
      <div className="flex-1 min-w-0">
        <Skeleton className="h-4 w-3/4 mb-2" />
        <Skeleton className="h-3 w-1/2" />
      </div>
      <div className="flex gap-2 flex-shrink-0">
        <Skeleton className="h-8 w-16" />
        <Skeleton className="h-8 w-16" />
      </div>
    </div>
  );
}

/**
 * Task list skeleton - shows multiple task item skeletons
 */
export function TaskListSkeleton({ count = 5 }: { count?: number }) {
  return (
    <div className="divide-y divide-border-subtle">
      {Array.from({ length: count }).map((_, index) => (
        <TaskItemSkeleton key={index} />
      ))}
    </div>
  );
}
