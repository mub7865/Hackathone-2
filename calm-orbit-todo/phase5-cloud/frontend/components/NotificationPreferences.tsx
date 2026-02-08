/**
 * NotificationPreferences component for managing user notification settings.
 *
 * This component provides a comprehensive UI for users to configure their
 * notification preferences including channels, frequency, quiet hours, and timezone.
 */

'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';

export type NotificationFrequency = 'immediate' | 'hourly' | 'daily' | 'weekly';

export interface NotificationPreferences {
  id: string;
  user_id: string;
  email_enabled: boolean;
  in_app_enabled: boolean;
  push_enabled: boolean;
  sms_enabled: boolean;
  reminder_frequency: NotificationFrequency;
  task_updates_enabled: boolean;
  recurring_task_enabled: boolean;
  quiet_hours_enabled: boolean;
  quiet_hours_start: string | null;
  quiet_hours_end: string | null;
  timezone: string;
  created_at: string;
  updated_at: string;
}

export interface NotificationPreferencesProps {
  apiUrl?: string;
  token?: string;
  onSave?: (preferences: NotificationPreferences) => void;
}

const FREQUENCY_OPTIONS = [
  { value: 'immediate', label: 'Immediate', description: 'Send notifications right away' },
  { value: 'hourly', label: 'Hourly', description: 'Batch notifications every hour' },
  { value: 'daily', label: 'Daily', description: 'Send daily digest' },
  { value: 'weekly', label: 'Weekly', description: 'Send weekly summary' },
];

export default function NotificationPreferences({
  apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
  token,
  onSave,
}: NotificationPreferencesProps) {
  const [_preferences, setPreferences] = useState<NotificationPreferences | null>(null);
  const [timezones, setTimezones] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Form state
  const [emailEnabled, setEmailEnabled] = useState(true);
  const [inAppEnabled, setInAppEnabled] = useState(true);
  const [pushEnabled, setPushEnabled] = useState(false);
  const [smsEnabled, setSmsEnabled] = useState(false);
  const [reminderFrequency, setReminderFrequency] = useState<NotificationFrequency>('immediate');
  const [taskUpdatesEnabled, setTaskUpdatesEnabled] = useState(true);
  const [recurringTaskEnabled, setRecurringTaskEnabled] = useState(true);
  const [quietHoursEnabled, setQuietHoursEnabled] = useState(false);
  const [quietHoursStart, setQuietHoursStart] = useState('22:00');
  const [quietHoursEnd, setQuietHoursEnd] = useState('08:00');
  const [timezone, setTimezone] = useState('UTC');

  useEffect(() => {
    if (token) {
      fetchPreferences();
      fetchTimezones();
    }
  }, [token]);

  const fetchPreferences = async () => {
    if (!token) return;

    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`${apiUrl}/api/v1/notification-preferences`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error('Failed to fetch notification preferences');
      }

      const data: NotificationPreferences = await response.json();
      setPreferences(data);

      // Update form state
      setEmailEnabled(data.email_enabled);
      setInAppEnabled(data.in_app_enabled);
      setPushEnabled(data.push_enabled);
      setSmsEnabled(data.sms_enabled);
      setReminderFrequency(data.reminder_frequency);
      setTaskUpdatesEnabled(data.task_updates_enabled);
      setRecurringTaskEnabled(data.recurring_task_enabled);
      setQuietHoursEnabled(data.quiet_hours_enabled);
      setQuietHoursStart(data.quiet_hours_start || '22:00');
      setQuietHoursEnd(data.quiet_hours_end || '08:00');
      setTimezone(data.timezone);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  const fetchTimezones = async () => {
    try {
      const response = await fetch(`${apiUrl}/api/v1/notification-preferences/timezones`);
      if (response.ok) {
        const data = await response.json();
        setTimezones(data.timezones);
      }
    } catch (err) {
      console.error('Failed to fetch timezones:', err);
    }
  };

  const handleSave = async () => {
    if (!token) return;

    // Validate at least one channel is enabled
    if (!emailEnabled && !inAppEnabled && !pushEnabled && !smsEnabled) {
      setError('At least one notification channel must be enabled');
      return;
    }

    setSaving(true);
    setError(null);
    setSuccessMessage(null);

    try {
      const updates = {
        email_enabled: emailEnabled,
        in_app_enabled: inAppEnabled,
        push_enabled: pushEnabled,
        sms_enabled: smsEnabled,
        reminder_frequency: reminderFrequency,
        task_updates_enabled: taskUpdatesEnabled,
        recurring_task_enabled: recurringTaskEnabled,
        quiet_hours_enabled: quietHoursEnabled,
        quiet_hours_start: quietHoursEnabled ? quietHoursStart : null,
        quiet_hours_end: quietHoursEnabled ? quietHoursEnd : null,
        timezone: timezone,
      };

      const response = await fetch(`${apiUrl}/api/v1/notification-preferences`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(updates),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Failed to update preferences');
      }

      const data: NotificationPreferences = await response.json();
      setPreferences(data);
      setSuccessMessage('Preferences saved successfully!');
      onSave?.(data);

      // Clear success message after 3 seconds
      setTimeout(() => setSuccessMessage(null), 3000);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setSaving(false);
    }
  };

  const handleReset = async () => {
    if (!token || !confirm('Reset all preferences to default values?')) return;

    setSaving(true);
    setError(null);
    setSuccessMessage(null);

    try {
      const response = await fetch(`${apiUrl}/api/v1/notification-preferences/reset`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error('Failed to reset preferences');
      }

      const data: NotificationPreferences = await response.json();
      setPreferences(data);

      // Update form state
      setEmailEnabled(data.email_enabled);
      setInAppEnabled(data.in_app_enabled);
      setPushEnabled(data.push_enabled);
      setSmsEnabled(data.sms_enabled);
      setReminderFrequency(data.reminder_frequency);
      setTaskUpdatesEnabled(data.task_updates_enabled);
      setRecurringTaskEnabled(data.recurring_task_enabled);
      setQuietHoursEnabled(data.quiet_hours_enabled);
      setQuietHoursStart(data.quiet_hours_start || '22:00');
      setQuietHoursEnd(data.quiet_hours_end || '08:00');
      setTimezone(data.timezone);

      setSuccessMessage('Preferences reset to defaults!');
      setTimeout(() => setSuccessMessage(null), 3000);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setSaving(false);
    }
  };

  if (!token) {
    return (
      <div className="p-4 text-center text-gray-500">
        Please log in to manage notification preferences
      </div>
    );
  }

  if (loading) {
    return (
      <div className="p-4 text-center text-gray-500">
        Loading preferences...
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Notification Preferences</h2>
        <p className="mt-1 text-sm text-gray-500">
          Customize how and when you receive notifications
        </p>
      </div>

      {/* Error Message */}
      {error && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700"
        >
          {error}
        </motion.div>
      )}

      {/* Success Message */}
      {successMessage && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-green-50 border border-green-200 rounded-lg p-4 text-green-700"
        >
          {successMessage}
        </motion.div>
      )}

      {/* Notification Channels */}
      <div className="bg-white border border-gray-200 rounded-lg p-6 shadow-sm">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Notification Channels
        </h3>
        <div className="space-y-4">
          <label className="flex items-center space-x-3 cursor-pointer">
            <input
              type="checkbox"
              checked={emailEnabled}
              onChange={(e) => setEmailEnabled(e.target.checked)}
              className="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <div>
              <div className="font-medium text-gray-900">Email</div>
              <div className="text-sm text-gray-500">Receive notifications via email</div>
            </div>
          </label>

          <label className="flex items-center space-x-3 cursor-pointer">
            <input
              type="checkbox"
              checked={inAppEnabled}
              onChange={(e) => setInAppEnabled(e.target.checked)}
              className="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <div>
              <div className="font-medium text-gray-900">In-App</div>
              <div className="text-sm text-gray-500">Receive real-time notifications in the app</div>
            </div>
          </label>

          <label className="flex items-center space-x-3 cursor-pointer opacity-50">
            <input
              type="checkbox"
              checked={pushEnabled}
              onChange={(e) => setPushEnabled(e.target.checked)}
              disabled
              className="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <div>
              <div className="font-medium text-gray-900">Push Notifications</div>
              <div className="text-sm text-gray-500">Coming soon</div>
            </div>
          </label>

          <label className="flex items-center space-x-3 cursor-pointer opacity-50">
            <input
              type="checkbox"
              checked={smsEnabled}
              onChange={(e) => setSmsEnabled(e.target.checked)}
              disabled
              className="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <div>
              <div className="font-medium text-gray-900">SMS</div>
              <div className="text-sm text-gray-500">Coming soon</div>
            </div>
          </label>
        </div>
      </div>

      {/* Reminder Frequency */}
      <div className="bg-white border border-gray-200 rounded-lg p-6 shadow-sm">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Reminder Frequency
        </h3>
        <div className="space-y-3">
          {FREQUENCY_OPTIONS.map((option) => (
            <label
              key={option.value}
              className="flex items-start space-x-3 cursor-pointer"
            >
              <input
                type="radio"
                name="frequency"
                value={option.value}
                checked={reminderFrequency === option.value}
                onChange={(e) => setReminderFrequency(e.target.value as NotificationFrequency)}
                className="mt-1 w-4 h-4 text-blue-600 border-gray-300 focus:ring-blue-500"
              />
              <div>
                <div className="font-medium text-gray-900">{option.label}</div>
                <div className="text-sm text-gray-500">{option.description}</div>
              </div>
            </label>
          ))}
        </div>
      </div>

      {/* Notification Types */}
      <div className="bg-white border border-gray-200 rounded-lg p-6 shadow-sm">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Notification Types
        </h3>
        <div className="space-y-4">
          <label className="flex items-center space-x-3 cursor-pointer">
            <input
              type="checkbox"
              checked={taskUpdatesEnabled}
              onChange={(e) => setTaskUpdatesEnabled(e.target.checked)}
              className="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <div>
              <div className="font-medium text-gray-900">Task Updates</div>
              <div className="text-sm text-gray-500">Notify when tasks are created, updated, or completed</div>
            </div>
          </label>

          <label className="flex items-center space-x-3 cursor-pointer">
            <input
              type="checkbox"
              checked={recurringTaskEnabled}
              onChange={(e) => setRecurringTaskEnabled(e.target.checked)}
              className="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <div>
              <div className="font-medium text-gray-900">Recurring Tasks</div>
              <div className="text-sm text-gray-500">Notify when recurring tasks are generated</div>
            </div>
          </label>
        </div>
      </div>

      {/* Quiet Hours */}
      <div className="bg-white border border-gray-200 rounded-lg p-6 shadow-sm">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Quiet Hours
        </h3>
        <div className="space-y-4">
          <label className="flex items-center space-x-3 cursor-pointer">
            <input
              type="checkbox"
              checked={quietHoursEnabled}
              onChange={(e) => setQuietHoursEnabled(e.target.checked)}
              className="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <div>
              <div className="font-medium text-gray-900">Enable Quiet Hours</div>
              <div className="text-sm text-gray-500">Pause notifications during specific hours</div>
            </div>
          </label>

          {quietHoursEnabled && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="grid grid-cols-2 gap-4 pl-8"
            >
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Start Time
                </label>
                <input
                  type="time"
                  value={quietHoursStart}
                  onChange={(e) => setQuietHoursStart(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  End Time
                </label>
                <input
                  type="time"
                  value={quietHoursEnd}
                  onChange={(e) => setQuietHoursEnd(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </motion.div>
          )}
        </div>
      </div>

      {/* Timezone */}
      <div className="bg-white border border-gray-200 rounded-lg p-6 shadow-sm">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Timezone
        </h3>
        <select
          value={timezone}
          onChange={(e) => setTimezone(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          {timezones.map((tz) => (
            <option key={tz} value={tz}>
              {tz}
            </option>
          ))}
        </select>
        <p className="mt-2 text-sm text-gray-500">
          Used for quiet hours and notification scheduling
        </p>
      </div>

      {/* Action Buttons */}
      <div className="flex items-center justify-between">
        <button
          onClick={handleReset}
          disabled={saving}
          className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          Reset to Defaults
        </button>
        <button
          onClick={handleSave}
          disabled={saving}
          className="px-6 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {saving ? 'Saving...' : 'Save Preferences'}
        </button>
      </div>
    </div>
  );
}
