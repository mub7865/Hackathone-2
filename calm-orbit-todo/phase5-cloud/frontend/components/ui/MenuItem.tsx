/**
 * MenuItem Component
 *
 * Reusable menu item for dropdown menus.
 * Used in ProfileDropdown for settings options.
 */

'use client';

import { ReactNode } from 'react';

interface MenuItemProps {
  icon: ReactNode;
  label: string;
  onClick: () => void;
  variant?: 'default' | 'danger';
  className?: string;
}

export function MenuItem({
  icon,
  label,
  onClick,
  variant = 'default',
  className = '',
}: MenuItemProps) {
  const variantClasses = {
    default: 'text-text-primary hover:bg-background-surface',
    danger: 'text-accent-error hover:bg-accent-error/10',
  };

  return (
    <button
      onClick={(e) => {
        e.stopPropagation();
        onClick();
      }}
      className={`
        w-full flex items-center gap-3 px-4 py-2.5
        text-sm font-medium text-left
        transition-colors duration-fast
        ${variantClasses[variant]}
        ${className}
      `.replace(/\s+/g, ' ').trim()}
      type="button"
    >
      <span className="w-5 h-5 flex-shrink-0" aria-hidden="true">
        {icon}
      </span>
      <span>{label}</span>
    </button>
  );
}
