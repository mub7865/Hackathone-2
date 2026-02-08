/**
 * RecurringTaskForm component for creating and managing recurring task patterns.
 *
 * This component provides a form interface for users to:
 * - Create new recurring patterns
 * - Configure recurrence rules (daily, weekly, monthly, yearly, custom)
 * - Set end conditions (date, count, indefinite)
 * - Preview next occurrences
 */

'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';

type RecurrenceFrequency = 'daily' | 'weekly' | 'monthly' | 'yearly' | 'custom';
type EndCondition = 'date' | 'count' | 'indefinite';

interface RecurringPatternFormData {
  originalTaskId: string;
  frequency: RecurrenceFrequency;
  interval: number;
  daysOfWeek: number[];
  dayOfMonth: number | null;
  monthOfYear: number | null;
  cronExpression: string;
  endCondition: EndCondition;
  endDate: string;
  occurrenceCount: number | null;
}

interface RecurringTaskFormProps {
  taskId: string;
  taskTitle: string;
  onSubmit: (pattern: RecurringPatternFormData) => Promise<void>;
  onCancel: () => void;
}

const WEEKDAYS = [
  { value: 0, label: 'Sun' },
  { value: 1, label: 'Mon' },
  { value: 2, label: 'Tue' },
  { value: 3, label: 'Wed' },
  { value: 4, label: 'Thu' },
  { value: 5, label: 'Fri' },
  { value: 6, label: 'Sat' },
];

const MONTHS = [
  { value: 1, label: 'January' },
  { value: 2, label: 'February' },
  { value: 3, label: 'March' },
  { value: 4, label: 'April' },
  { value: 5, label: 'May' },
  { value: 6, label: 'June' },
  { value: 7, label: 'July' },
  { value: 8, label: 'August' },
  { value: 9, label: 'September' },
  { value: 10, label: 'October' },
  { value: 11, label: 'November' },
  { value: 12, label: 'December' },
];

export default function RecurringTaskForm({
  taskId,
  taskTitle,
  onSubmit,
  onCancel,
}: RecurringTaskFormProps) {
  const [formData, setFormData] = useState<RecurringPatternFormData>({
    originalTaskId: taskId,
    frequency: 'daily',
    interval: 1,
    daysOfWeek: [],
    dayOfMonth: null,
    monthOfYear: null,
    cronExpression: '',
    endCondition: 'indefinite',
    endDate: '',
    occurrenceCount: null,
  });

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleFrequencyChange = (frequency: RecurrenceFrequency) => {
    setFormData({
      ...formData,
      frequency,
      daysOfWeek: frequency === 'weekly' ? [1] : [],
      dayOfMonth: frequency === 'monthly' || frequency === 'yearly' ? 1 : null,
      monthOfYear: frequency === 'yearly' ? 1 : null,
      cronExpression: frequency === 'custom' ? '0 9 * * *' : '',
    });
  };

  const handleDayOfWeekToggle = (day: number) => {
    const newDays = formData.daysOfWeek.includes(day)
      ? formData.daysOfWeek.filter((d) => d !== day)
      : [...formData.daysOfWeek, day].sort();
    setFormData({ ...formData, daysOfWeek: newDays });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      // Validate form data
      if (formData.frequency === 'weekly' && formData.daysOfWeek.length === 0) {
        throw new Error('Please select at least one day of the week');
      }

      if (formData.endCondition === 'date' && !formData.endDate) {
        throw new Error('Please select an end date');
      }

      if (formData.endCondition === 'count' && !formData.occurrenceCount) {
        throw new Error('Please enter the number of occurrences');
      }

      await onSubmit(formData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create recurring pattern');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="bg-white rounded-lg shadow-lg p-6 max-w-2xl mx-auto"
    >
      <h2 className="text-2xl font-bold mb-4">Create Recurring Pattern</h2>
      <p className="text-gray-600 mb-6">
        Task: <span className="font-semibold">{taskTitle}</span>
      </p>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Frequency Selection */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Recurrence Frequency
          </label>
          <div className="grid grid-cols-5 gap-2">
            {(['daily', 'weekly', 'monthly', 'yearly', 'custom'] as RecurrenceFrequency[]).map(
              (freq) => (
                <button
                  key={freq}
                  type="button"
                  onClick={() => handleFrequencyChange(freq)}
                  className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                    formData.frequency === freq
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  {freq.charAt(0).toUpperCase() + freq.slice(1)}
                </button>
              )
            )}
          </div>
        </div>

        {/* Interval */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Repeat Every
          </label>
          <div className="flex items-center gap-2">
            <input
              type="number"
              min="1"
              value={formData.interval}
              onChange={(e) =>
                setFormData({ ...formData, interval: parseInt(e.target.value) || 1 })
              }
              className="w-20 px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <span className="text-gray-700">
              {formData.frequency === 'daily' && 'day(s)'}
              {formData.frequency === 'weekly' && 'week(s)'}
              {formData.frequency === 'monthly' && 'month(s)'}
              {formData.frequency === 'yearly' && 'year(s)'}
            </span>
          </div>
        </div>

        {/* Weekly: Days of Week */}
        {formData.frequency === 'weekly' && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Repeat On
            </label>
            <div className="flex gap-2">
              {WEEKDAYS.map((day) => (
                <button
                  key={day.value}
                  type="button"
                  onClick={() => handleDayOfWeekToggle(day.value)}
                  className={`w-12 h-12 rounded-full text-sm font-medium transition-colors ${
                    formData.daysOfWeek.includes(day.value)
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  {day.label}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Monthly: Day of Month */}
        {formData.frequency === 'monthly' && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Day of Month
            </label>
            <div className="flex items-center gap-4">
              <input
                type="number"
                min="1"
                max="31"
                value={formData.dayOfMonth || ''}
                onChange={(e) =>
                  setFormData({ ...formData, dayOfMonth: parseInt(e.target.value) || null })
                }
                className="w-20 px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <button
                type="button"
                onClick={() => setFormData({ ...formData, dayOfMonth: -1 })}
                className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                  formData.dayOfMonth === -1
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                Last Day
              </button>
            </div>
          </div>
        )}

        {/* Yearly: Month and Day */}
        {formData.frequency === 'yearly' && (
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Month
              </label>
              <select
                value={formData.monthOfYear || ''}
                onChange={(e) =>
                  setFormData({ ...formData, monthOfYear: parseInt(e.target.value) || null })
                }
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                {MONTHS.map((month) => (
                  <option key={month.value} value={month.value}>
                    {month.label}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Day
              </label>
              <input
                type="number"
                min="1"
                max="31"
                value={formData.dayOfMonth || ''}
                onChange={(e) =>
                  setFormData({ ...formData, dayOfMonth: parseInt(e.target.value) || null })
                }
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>
        )}

        {/* Custom: Cron Expression */}
        {formData.frequency === 'custom' && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Cron Expression
            </label>
            <input
              type="text"
              value={formData.cronExpression}
              onChange={(e) => setFormData({ ...formData, cronExpression: e.target.value })}
              placeholder="0 9 * * 1-5"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent font-mono text-sm"
            />
            <p className="mt-1 text-xs text-gray-500">
              Example: "0 9 * * 1-5" = 9 AM on weekdays
            </p>
          </div>
        )}

        {/* End Condition */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            End Condition
          </label>
          <div className="space-y-3">
            <label className="flex items-center gap-2">
              <input
                type="radio"
                checked={formData.endCondition === 'indefinite'}
                onChange={() => setFormData({ ...formData, endCondition: 'indefinite' })}
                className="w-4 h-4 text-blue-600"
              />
              <span className="text-gray-700">Never (indefinite)</span>
            </label>

            <label className="flex items-center gap-2">
              <input
                type="radio"
                checked={formData.endCondition === 'date'}
                onChange={() => setFormData({ ...formData, endCondition: 'date' })}
                className="w-4 h-4 text-blue-600"
              />
              <span className="text-gray-700">On date:</span>
              {formData.endCondition === 'date' && (
                <input
                  type="date"
                  value={formData.endDate}
                  onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                  className="ml-2 px-3 py-1 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              )}
            </label>

            <label className="flex items-center gap-2">
              <input
                type="radio"
                checked={formData.endCondition === 'count'}
                onChange={() => setFormData({ ...formData, endCondition: 'count' })}
                className="w-4 h-4 text-blue-600"
              />
              <span className="text-gray-700">After:</span>
              {formData.endCondition === 'count' && (
                <input
                  type="number"
                  min="1"
                  value={formData.occurrenceCount || ''}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      occurrenceCount: parseInt(e.target.value) || null,
                    })
                  }
                  className="ml-2 w-20 px-3 py-1 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              )}
              {formData.endCondition === 'count' && (
                <span className="text-gray-700">occurrence(s)</span>
              )}
            </label>
          </div>
        </div>

        {/* Error Message */}
        {error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-md">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex justify-end gap-3 pt-4 border-t">
          <button
            type="button"
            onClick={onCancel}
            disabled={isSubmitting}
            className="px-4 py-2 text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200 transition-colors disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
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
                Creating...
              </>
            ) : (
              'Create Recurring Pattern'
            )}
          </button>
        </div>
      </form>
    </motion.div>
  );
}
