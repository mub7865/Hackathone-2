'use client';

import { useEffect, useRef } from 'react';

export interface ProfileDropdownProps {
  isOpen: boolean;
  onClose: () => void;
  onSignOut: () => void;
}

/**
 * Profile Dropdown – Minimal dropdown with ONLY "Sign out" action
 * Feature: 006-ui-theme-motion (FR-039, FR-040, FR-041, FR-042, FR-043, SC-012)
 */
export function ProfileDropdown({ isOpen, onClose, onSignOut }: ProfileDropdownProps) {
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Handle Escape key and click outside
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    const handleClickOutside = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        onClose();
      }
    };

    // Small delay before adding click listener
    const timer = setTimeout(() => {
      document.addEventListener('click', handleClickOutside);
    }, 100);

    document.addEventListener('keydown', handleKeyDown);

    return () => {
      clearTimeout(timer);
      document.removeEventListener('keydown', handleKeyDown);
      document.removeEventListener('click', handleClickOutside);
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const handleSignOutClick = () => {
    console.log('Sign out clicked'); // Debug log
    onSignOut();
  };

  return (
    <div
      ref={dropdownRef}
      role="menu"
      className="absolute top-full right-0 mt-2 min-w-[120px] bg-background-elevated border border-border-subtle rounded-lg shadow-lg py-1 z-[100]"
    >
      <button
        type="button"
        role="menuitem"
        onClick={handleSignOutClick}
        className="w-full px-4 py-2 text-body-sm text-text-secondary text-left hover:bg-background-surface hover:text-text-primary focus:outline-none focus:bg-background-surface cursor-pointer"
      >
        Sign out
      </button>
    </div>
  );
}
