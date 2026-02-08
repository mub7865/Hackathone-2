/**
 * NotificationSettingsModal Component
 *
 * Modal for managing notification preferences:
 * - Email notifications (reminders, daily summary, weekly report)
 * - In-app notifications (reminders, completions)
 * - Push notifications (enable/disable)
 */

'use client';

import { useState, useEffect } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { ToggleSwitch } from '@/components/ui/ToggleSwitch';

interface NotificationSettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const STORAGE_KEY = 'calm-orbit-notification-preferences';

export function NotificationSettingsModal({ isOpen, onClose }: NotificationSettingsModalProps) {
  // Email notifications
  const [emailReminders, setEmailReminders] = useState(true);
  const [emailDailySummary, setEmailDailySummary] = useState(false);
  const [emailWeeklyReport, setEmailWeeklyReport] = useState(true);

  // In-app notifications
  const [inAppReminders, setInAppReminders] = useState(true);
  const [inAppCompletions, setInAppCompletions] = useState(true);

  // Push notifications
  const [pushEnabled, setPushEnabled] = useState(false);

  const [isLoading, setIsLoading] = useState(false);

  // Load preferences from localStorage when modal opens
  useEffect(() => {
    if (isOpen && typeof window !== 'undefined') {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        try {
          const prefs = JSON.parse(saved);
          setEmailReminders(prefs.email?.reminders ?? true);
          setEmailDailySummary(prefs.email?.dailySummary ?? false);
          setEmailWeeklyReport(prefs.email?.weeklyReport ?? true);
          setInAppReminders(prefs.inApp?.reminders ?? true);
          setInAppCompletions(prefs.inApp?.completions ?? true);
          setPushEnabled(prefs.push?.enabled ?? false);
        } catch (err) {
          console.error('Failed to load notification preferences:', err);
        }
      }
    }
  }, [isOpen]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      const preferences = {
        email: { reminders: emailReminders, dailySummary: emailDailySummary, weeklyReport: emailWeeklyReport },
        inApp: { reminders: inAppReminders, completions: inAppCompletions },
        push: { enabled: pushEnabled },
      };

      // Save to localStorage
      if (typeof window !== 'undefined') {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(preferences));
      }

      // TODO: Implement API call to save notification preferences to backend
      console.log('Saving notification preferences:', preferences);

      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 500));

      // Success - close modal
      onClose();
    } catch (err) {
      console.error('Failed to save notification preferences:', err);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Notification Preferences">
      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Email Notifications Section */}
        <div>
          <h3 className="text-heading-md font-semibold text-text-primary mb-3">
            Email Notifications
          </h3>
          <div className="space-y-1">
            <ToggleSwitch
              label="Task reminders"
              checked={emailReminders}
              onChange={setEmailReminders}
              helperText="Get email reminders for upcoming tasks"
            />
            <ToggleSwitch
              label="Daily summary"
              checked={emailDailySummary}
              onChange={setEmailDailySummary}
              helperText="Receive a daily summary of your tasks"
            />
            <ToggleSwitch
              label="Weekly report"
              checked={emailWeeklyReport}
              onChange={setEmailWeeklyReport}
              helperText="Get a weekly productivity report"
            />
          </div>
        </div>

        {/* In-App Notifications Section */}
        <div className="pt-4 border-t border-border-subtle">
          <h3 className="text-heading-md font-semibold text-text-primary mb-3">
            In-App Notifications
          </h3>
          <div className="space-y-1">
            <ToggleSwitch
              label="Task reminders"
              checked={inAppReminders}
              onChange={setInAppReminders}
              helperText="Show in-app notifications for task reminders"
            />
            <ToggleSwitch
              label="Task completions"
              checked={inAppCompletions}
              onChange={setInAppCompletions}
              helperText="Celebrate when you complete tasks"
            />
          </div>
        </div>

        {/* Push Notifications Section */}
        <div className="pt-4 border-t border-border-subtle">
          <h3 className="text-heading-md font-semibold text-text-primary mb-3">
            Push Notifications
          </h3>
          <div className="space-y-1">
            <ToggleSwitch
              label="Enable push notifications"
              checked={pushEnabled}
              onChange={setPushEnabled}
              helperText="Receive notifications even when the app is closed"
            />
          </div>
          {pushEnabled && (
            <div className="mt-3 p-3 bg-blue-50 border border-blue-300 rounded-lg text-sm text-blue-700 dark:bg-blue-900/20 dark:border-blue-800 dark:text-blue-400">
              You'll be prompted to allow notifications in your browser.
            </div>
          )}
        </div>

        {/* Actions */}
        <div className="flex justify-end gap-3 pt-4">
          <Button
            type="button"
            variant="secondary"
            onClick={onClose}
            disabled={isLoading}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            isLoading={isLoading}
          >
            Save Preferences
          </Button>
        </div>
      </form>
    </Modal>
  );
}
