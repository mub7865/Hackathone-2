'use client';

import { ProfileSettingsModal } from '@/components/profile/ProfileSettingsModal';
import { NotificationSettingsModal } from '@/components/profile/NotificationSettingsModal';
import { ThemeSettingsModal } from '@/components/profile/ThemeSettingsModal';
import { AccountStatsModal } from '@/components/profile/AccountStatsModal';

interface GlobalModalsProps {
  profileSettings: {
    isOpen: boolean;
    onClose: () => void;
    user?: { name: string; email: string };
  };
  notificationSettings: {
    isOpen: boolean;
    onClose: () => void;
  };
  themeSettings: {
    isOpen: boolean;
    onClose: () => void;
  };
  accountStats: {
    isOpen: boolean;
    onClose: () => void;
  };
}

/**
 * Global Modals Container
 * Renders all modals at app root level to prevent unmounting issues
 */
export function GlobalModals({
  profileSettings,
  notificationSettings,
  themeSettings,
  accountStats,
}: GlobalModalsProps) {
  return (
    <>
      <ProfileSettingsModal
        isOpen={profileSettings.isOpen}
        onClose={profileSettings.onClose}
        user={profileSettings.user}
      />

      <NotificationSettingsModal
        isOpen={notificationSettings.isOpen}
        onClose={notificationSettings.onClose}
      />

      <ThemeSettingsModal
        isOpen={themeSettings.isOpen}
        onClose={themeSettings.onClose}
      />

      <AccountStatsModal
        isOpen={accountStats.isOpen}
        onClose={accountStats.onClose}
      />
    </>
  );
}
