/**
 * AccountStatsModal Component
 *
 * Modal for displaying user account statistics:
 * - Key metrics (tasks completed, streak, total tasks, completion rate)
 * - Weekly activity chart
 * - Achievement highlights
 */

'use client';

import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import {
  CheckCircleIcon,
  FireIcon,
  ListBulletIcon,
  ChartBarIcon,
} from '@heroicons/react/24/outline';

interface AccountStatsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

// Placeholder data - will be replaced with API calls
const PLACEHOLDER_STATS = {
  tasksCompleted: 127,
  currentStreak: 12,
  totalTasks: 156,
  completionRate: 81,
  weeklyActivity: [
    { day: 'Mon', count: 8 },
    { day: 'Tue', count: 12 },
    { day: 'Wed', count: 6 },
    { day: 'Thu', count: 15 },
    { day: 'Fri', count: 10 },
    { day: 'Sat', count: 4 },
    { day: 'Sun', count: 7 },
  ],
};

export function AccountStatsModal({ isOpen, onClose }: AccountStatsModalProps) {
  const stats = PLACEHOLDER_STATS;
  const maxCount = Math.max(...stats.weeklyActivity.map(d => d.count));

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Your Statistics">
      <div className="space-y-6">
        {/* Key Metrics Grid */}
        <div className="grid grid-cols-2 gap-4">
          <StatCard
            icon={<CheckCircleIcon className="w-6 h-6" />}
            label="Tasks Completed"
            value={stats.tasksCompleted}
            color="green"
          />
          <StatCard
            icon={<FireIcon className="w-6 h-6" />}
            label="Current Streak"
            value={`${stats.currentStreak} days`}
            color="orange"
          />
          <StatCard
            icon={<ListBulletIcon className="w-6 h-6" />}
            label="Total Tasks"
            value={stats.totalTasks}
            color="blue"
          />
          <StatCard
            icon={<ChartBarIcon className="w-6 h-6" />}
            label="Completion Rate"
            value={`${stats.completionRate}%`}
            color="purple"
          />
        </div>

        {/* Weekly Activity Chart */}
        <div className="pt-4 border-t border-border-subtle">
          <h3 className="text-heading-md font-semibold text-text-primary mb-4">
            Weekly Activity
          </h3>
          <div className="space-y-3">
            {stats.weeklyActivity.map((day) => (
              <div key={day.day} className="flex items-center gap-3">
                <span className="text-sm font-medium text-text-secondary w-10">
                  {day.day}
                </span>
                <div className="flex-1 bg-background-surface rounded-full h-8 overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-accent-primary to-accent-hover rounded-full flex items-center justify-end pr-3 transition-all duration-normal"
                    style={{ width: `${(day.count / maxCount) * 100}%` }}
                  >
                    {day.count > 0 && (
                      <span className="text-xs font-semibold text-white">
                        {day.count}
                      </span>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Achievement Highlight */}
        <div className="pt-4 border-t border-border-subtle">
          <div className="p-4 bg-gradient-to-r from-purple-50 to-blue-50 border border-purple-200 rounded-lg dark:from-purple-900/20 dark:to-blue-900/20 dark:border-purple-800">
            <div className="flex items-start gap-3">
              <div className="flex-shrink-0 w-10 h-10 bg-purple-500 rounded-full flex items-center justify-center">
                <FireIcon className="w-6 h-6 text-white" />
              </div>
              <div className="flex-1">
                <h4 className="text-sm font-semibold text-purple-900 dark:text-purple-300 mb-1">
                  🎉 Great Streak!
                </h4>
                <p className="text-xs text-purple-700 dark:text-purple-400">
                  You've completed tasks for {stats.currentStreak} days in a row. Keep up the momentum!
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Info Note */}
        <div className="pt-2">
          <p className="text-xs text-text-muted text-center">
            Statistics are updated in real-time as you complete tasks
          </p>
        </div>

        {/* Close Button */}
        <div className="flex justify-end pt-2">
          <Button onClick={onClose}>
            Close
          </Button>
        </div>
      </div>
    </Modal>
  );
}

interface StatCardProps {
  icon: React.ReactNode;
  label: string;
  value: string | number;
  color: 'green' | 'orange' | 'blue' | 'purple';
}

function StatCard({ icon, label, value, color }: StatCardProps) {
  const colorClasses = {
    green: 'bg-green-50 text-green-700 border-green-200 dark:bg-green-900/20 dark:text-green-400 dark:border-green-800',
    orange: 'bg-orange-50 text-orange-700 border-orange-200 dark:bg-orange-900/20 dark:text-orange-400 dark:border-orange-800',
    blue: 'bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-900/20 dark:text-blue-400 dark:border-blue-800',
    purple: 'bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-900/20 dark:text-purple-400 dark:border-purple-800',
  };

  return (
    <div className={`p-4 rounded-lg border ${colorClasses[color]} transition-all duration-normal hover:shadow-md`}>
      <div className="flex items-center gap-2 mb-2">
        {icon}
      </div>
      <p className="text-2xl font-bold mb-1">{value}</p>
      <p className="text-xs font-medium opacity-80">{label}</p>
    </div>
  );
}
