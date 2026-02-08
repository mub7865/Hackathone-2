'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import { MenuItem } from '@/components/ui/MenuItem';
import { ProfileAvatar } from './ProfileAvatar';
import { ProfileSettingsModal } from '@/components/profile/ProfileSettingsModal';
import { NotificationSettingsModal } from '@/components/profile/NotificationSettingsModal';
import { ThemeSettingsModal } from '@/components/profile/ThemeSettingsModal';
import { AccountStatsModal } from '@/components/profile/AccountStatsModal';
import {
  UserIcon,
  BellIcon,
  PaintBrushIcon,
  ChartBarIcon,
  ArrowRightOnRectangleIcon,
} from '@heroicons/react/24/outline';

export interface ProfileDropdownProps {
  isOpen: boolean;
  onClose: () => void;
  onSignOut: () => void;
  user?: {
    name: string;
    email: string;
  };
  onOpenModal?: (modalType: 'profile' | 'notifications' | 'theme' | 'stats') => void;
}

type ModalType = 'profile' | 'notifications' | 'theme' | 'stats' | null;

/**
 * Enhanced Profile Dropdown with comprehensive settings menu
 *
 * Features:
 * - User info header with avatar
 * - Profile Settings
 * - Notification Preferences
 * - Theme/Appearance Settings
 * - Account Statistics
 * - Sign Out
 */
export function ProfileDropdown({ isOpen, onClose, onSignOut, user, onOpenModal }: ProfileDropdownProps) {
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

    // Delay to prevent immediate close from the same click that opened it
    const timer = setTimeout(() => {
      document.addEventListener('click', handleClickOutside);
    }, 200);

    document.addEventListener('keydown', handleKeyDown);

    return () => {
      clearTimeout(timer);
      document.removeEventListener('keydown', handleKeyDown);
      document.removeEventListener('click', handleClickOutside);
    };
  }, [isOpen, onClose]);

  // Memoize callbacks to prevent unnecessary re-renders of modals
  const handleMenuItemClick = useCallback((modal: 'profile' | 'notifications' | 'theme' | 'stats') => {
    onOpenModal?.(modal);
    onClose(); // Close dropdown when opening modal
  }, [onOpenModal, onClose]);

  const handleSignOutClick = useCallback(() => {
    console.log('Sign out clicked');
    onSignOut();
  }, [onSignOut]);

  return (
    <>
      {isOpen && (
        <div
          ref={dropdownRef}
          role="menu"
          className="absolute top-full right-0 mt-2 w-80 bg-background-elevated border border-border-subtle rounded-lg shadow-xl z-[100] animate-scale-in motion-reduce:animate-none"
        >
        {/* User Info Header */}
        {user && (
          <div className="p-4 border-b border-border-subtle">
            <div className="flex items-center gap-3">
              <ProfileAvatar user={user} size="lg" />
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-text-primary truncate">{user.name}</p>
                <p className="text-sm text-text-secondary truncate">{user.email}</p>
              </div>
            </div>
          </div>
        )}

        {/* Menu Items */}
        <div className="py-2">
          <MenuItem
            icon={<UserIcon className="w-5 h-5" />}
            label="Profile Settings"
            onClick={() => handleMenuItemClick('profile')}
          />
          <MenuItem
            icon={<BellIcon className="w-5 h-5" />}
            label="Notifications"
            onClick={() => handleMenuItemClick('notifications')}
          />
          <MenuItem
            icon={<PaintBrushIcon className="w-5 h-5" />}
            label="Appearance"
            onClick={() => handleMenuItemClick('theme')}
          />
          <MenuItem
            icon={<ChartBarIcon className="w-5 h-5" />}
            label="Statistics"
            onClick={() => handleMenuItemClick('stats')}
          />

          {/* Divider */}
          <div className="border-t border-border-subtle my-2" />

          {/* Sign Out */}
          <MenuItem
            icon={<ArrowRightOnRectangleIcon className="w-5 h-5" />}
            label="Sign Out"
            onClick={handleSignOutClick}
            variant="danger"
          />
        </div>
        </div>
      )}

      {/* Modals removed - now rendered at app root level via GlobalModals */}
    </>
  );
}
