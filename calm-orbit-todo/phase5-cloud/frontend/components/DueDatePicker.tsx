/**
 * DueDatePicker component for setting task due dates and reminders.
 *
 * This component provides an interface for users to:
 * - Set due dates for tasks
 * - Configure reminder times (before due date)
 * - Clear due dates and reminders
 * - View suggested reminder times
 */

'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

interface DueDatePickerProps {
  taskId: string;
  currentDueDate?: string | null;
  currentRemindAt?: string | null;
  onSave: (dueDate: string | null, remindAt: string | null) => Promise<void>;
  onCancel?: () => void;
}

const REMINDER_PRESETS = [
  { label: '15 minutes before', hours: 0.25 },
  { label: '30 minutes before', hours: 0.5 },
  { label: '1 hour before', hours: 1 },
  { label: '2 hours before', hours: 2 },
  { label: '1 day before', hours: 24 },
  { label: '2 days before', hours: 48 },
  { label: '1 week before', hours: 168 },
];

export default function DueDatePicker({
  taskId: _taskId,
  currentDueDate,
  currentRemindAt,
  onSave,
  onCancel,
}: DueDatePickerProps) {
  const [dueDate, setDueDate] = useState<string>('');
  const [dueTime, setDueTime] = useState<string>('');
  const [remindAt, setRemindAt] = useState<string>('');
  const [remindTime, setRemindTime] = useState<string>('');
  const [useReminder, setUseReminder] = useState<boolean>(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Initialize form with current values
  useEffect(() => {
    if (currentDueDate) {
      const date = new Date(currentDueDate);
      setDueDate(date.toISOString().split('T')[0]);
      setDueTime(date.toTimeString().slice(0, 5));
    }

    if (currentRemindAt) {
      const date = new Date(currentRemindAt);
      setRemindAt(date.toISOString().split('T')[0]);
      setRemindTime(date.toTimeString().slice(0, 5));
      setUseReminder(true);
    }
  }, [currentDueDate, currentRemindAt]);

  const handleDueDateChange = (date: string) => {
    setDueDate(date);
    setError(null);

    // If reminder is enabled, update it to maintain the time difference
    if (useReminder && remindAt) {
      const dueDateObj = new Date(`${date}T${dueTime || '09:00'}`);
      const reminderOffset = 24 * 60 * 60 * 1000; // 1 day default
      const newReminder = new Date(dueDateObj.getTime() - reminderOffset);
      setRemindAt(newReminder.toISOString().split('T')[0]);
      setRemindTime(newReminder.toTimeString().slice(0, 5));
    }
  };

  const handleReminderPreset = (hoursBeforeDue: number) => {
    if (!dueDate) {
      setError('Please set a due date first');
      return;
    }

    const dueDateObj = new Date(`${dueDate}T${dueTime || '09:00'}`);
    const reminderOffset = hoursBeforeDue * 60 * 60 * 1000;
    const reminderDate = new Date(dueDateObj.getTime() - reminderOffset);

    // Check if reminder is in the past
    if (reminderDate < new Date()) {
      setError('Reminder time would be in the past. Please choose a later due date.');
      return;
    }

    setRemindAt(reminderDate.toISOString().split('T')[0]);
    setRemindTime(reminderDate.toTimeString().slice(0, 5));
    setUseReminder(true);
    setError(null);
  };

  const validateForm = (): boolean => {
    setError(null);

    if (!dueDate) {
      setError('Please select a due date');
      return false;
    }

    const dueDateObj = new Date(`${dueDate}T${dueTime || '00:00'}`);
    const now = new Date();

    if (dueDateObj < now) {
      setError('Due date must be in the future');
      return false;
    }

    if (useReminder) {
      if (!remindAt) {
        setError('Please select a reminder date');
        return false;
      }

      const remindAtObj = new Date(`${remindAt}T${remindTime || '00:00'}`);

      if (remindAtObj < now) {
        setError('Reminder time must be in the future');
        return false;
      }

      if (remindAtObj >= dueDateObj) {
        setError('Reminder must be before the due date');
        return false;
      }
    }

    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);

    try {
      const dueDateISO = dueDate
        ? new Date(`${dueDate}T${dueTime || '00:00'}:00Z`).toISOString()
        : null;

      const remindAtISO =
        useReminder && remindAt
          ? new Date(`${remindAt}T${remindTime || '00:00'}:00Z`).toISOString()
          : null;

      await onSave(dueDateISO, remindAtISO);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save due date');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClear = async () => {
    setIsSubmitting(true);
    try {
      await onSave(null, null);
      setDueDate('');
      setDueTime('');
      setRemindAt('');
      setRemindTime('');
      setUseReminder(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to clear due date');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="bg-white rounded-lg shadow-lg p-6 max-w-md mx-auto"
    >
      <h2 className="text-xl font-bold mb-4">Set Due Date & Reminder</h2>

      <div className="space-y-6">
        {/* Due Date */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Due Date *
          </label>
          <div className="grid grid-cols-2 gap-3">
            <input
              type="date"
              value={dueDate}
              onChange={(e) => handleDueDateChange(e.target.value)}
              min={new Date().toISOString().split('T')[0]}
              className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              required
            />
            <input
              type="time"
              value={dueTime}
              onChange={(e) => setDueTime(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          <p className="mt-1 text-xs text-gray-500">
            {dueDate && dueTime
              ? `Due: ${new Date(`${dueDate}T${dueTime}`).toLocaleString()}`
              : 'Select a date and time'}
          </p>
        </div>

        {/* Reminder Toggle */}
        <div>
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={useReminder}
              onChange={(e) => {
                setUseReminder(e.target.checked);
                if (!e.target.checked) {
                  setRemindAt('');
                  setRemindTime('');
                }
              }}
              className="w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
            />
            <span className="text-sm font-medium text-gray-700">
              Set a reminder
            </span>
          </label>
        </div>

        {/* Reminder Settings */}
        {useReminder && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="space-y-4"
          >
            {/* Quick Presets */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Quick Presets
              </label>
              <div className="grid grid-cols-2 gap-2">
                {REMINDER_PRESETS.map((preset) => (
                  <button
                    key={preset.label}
                    type="button"
                    onClick={() => handleReminderPreset(preset.hours)}
                    className="px-3 py-2 text-sm bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200 transition-colors"
                  >
                    {preset.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Custom Reminder Time */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Custom Reminder Time
              </label>
              <div className="grid grid-cols-2 gap-3">
                <input
                  type="date"
                  value={remindAt}
                  onChange={(e) => setRemindAt(e.target.value)}
                  min={new Date().toISOString().split('T')[0]}
                  max={dueDate}
                  className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
                <input
                  type="time"
                  value={remindTime}
                  onChange={(e) => setRemindTime(e.target.value)}
                  className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              {remindAt && remindTime && (
                <p className="mt-1 text-xs text-gray-500">
                  Reminder: {new Date(`${remindAt}T${remindTime}`).toLocaleString()}
                </p>
              )}
            </div>
          </motion.div>
        )}

        {/* Error Message */}
        {error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-md">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex justify-between gap-3 pt-4 border-t">
          <button
            type="button"
            onClick={handleClear}
            disabled={isSubmitting || (!currentDueDate && !dueDate)}
            className="px-4 py-2 text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200 transition-colors disabled:opacity-50"
          >
            Clear
          </button>

          <div className="flex gap-3">
            {onCancel && (
              <button
                type="button"
                onClick={onCancel}
                disabled={isSubmitting}
                className="px-4 py-2 text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200 transition-colors disabled:opacity-50"
              >
                Cancel
              </button>
            )}
            <button
              type="button"
              onClick={handleSubmit}
              disabled={isSubmitting || !dueDate}
              className="px-4 py-2 text-white bg-blue-600 rounded-md hover:bg-blue-700 transition-colors disabled:opacity-50 flex items-center gap-2"
            >
              {isSubmitting ? (
                <>
                  <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                    <circle
                      className="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      strokeWidth="4"
                      fill="none"
                    />
                    <path
                      className="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    />
                  </svg>
                  Saving...
                </>
              ) : (
                'Save'
              )}
            </button>
          </div>
        </div>
      </div>
    </motion.div>
  );
}
