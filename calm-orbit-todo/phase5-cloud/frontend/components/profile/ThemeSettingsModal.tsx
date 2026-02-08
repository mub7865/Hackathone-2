/**
 * ThemeSettingsModal Component
 *
 * Modal for managing appearance settings:
 * - Theme mode (Light, Dark, Auto)
 * - Time-of-day theming toggle
 */

'use client';

import { useState, useEffect } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { ToggleSwitch } from '@/components/ui/ToggleSwitch';
import { SunIcon, MoonIcon, ComputerDesktopIcon } from '@heroicons/react/24/outline';

interface ThemeSettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

type ThemeMode = 'light' | 'dark' | 'auto';

const STORAGE_KEY = 'calm-orbit-theme-preferences';

export function ThemeSettingsModal({ isOpen, onClose }: ThemeSettingsModalProps) {
  const [theme, setTheme] = useState<ThemeMode>('dark');
  const [timeOfDayEnabled, setTimeOfDayEnabled] = useState(true);
  const [isLoading, setIsLoading] = useState(false);

  // Load preferences from localStorage when modal opens
  useEffect(() => {
    if (isOpen && typeof window !== 'undefined') {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        try {
          const prefs = JSON.parse(saved);
          setTheme(prefs.theme ?? 'dark');
          setTimeOfDayEnabled(prefs.timeOfDayEnabled ?? true);
        } catch (err) {
          console.error('Failed to load theme preferences:', err);
        }
      } else {
        // Check current theme from document
        const isDark = document.documentElement.classList.contains('dark');
        setTheme(isDark ? 'dark' : 'light');
      }
    }
  }, [isOpen]);

  const applyTheme = (newTheme: ThemeMode) => {
    if (typeof window === 'undefined') return;

    if (newTheme === 'auto') {
      // Use system preference
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      if (prefersDark) {
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
      }
    } else if (newTheme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  };

  const handleThemeChange = (newTheme: ThemeMode) => {
    setTheme(newTheme);
    // Apply theme immediately when user clicks
    applyTheme(newTheme);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      const preferences = { theme, timeOfDayEnabled };

      // Save to localStorage
      if (typeof window !== 'undefined') {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(preferences));
      }

      // Theme already applied by handleThemeChange
      console.log('Saving theme preferences:', preferences);

      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 500));

      // Success - close modal
      onClose();
    } catch (err) {
      console.error('Failed to save theme preferences:', err);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Appearance">
      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Theme Mode Section */}
        <div>
          <h3 className="text-heading-md font-semibold text-text-primary mb-3">
            Theme Mode
          </h3>
          <div className="grid grid-cols-3 gap-3">
            <ThemeOption
              label="Light"
              icon={<SunIcon className="w-6 h-6" />}
              active={theme === 'light'}
              onClick={() => handleThemeChange('light')}
            />
            <ThemeOption
              label="Dark"
              icon={<MoonIcon className="w-6 h-6" />}
              active={theme === 'dark'}
              onClick={() => handleThemeChange('dark')}
            />
            <ThemeOption
              label="Auto"
              icon={<ComputerDesktopIcon className="w-6 h-6" />}
              active={theme === 'auto'}
              onClick={() => handleThemeChange('auto')}
            />
          </div>
          <p className="mt-2 text-sm text-text-secondary">
            {theme === 'auto'
              ? 'Automatically switch between light and dark based on system preferences'
              : `Always use ${theme} mode`
            }
          </p>
        </div>

        {/* Time-of-Day Theming Section */}
        <div className="pt-4 border-t border-border-subtle">
          <h3 className="text-heading-md font-semibold text-text-primary mb-3">
            Time-of-Day Theming
          </h3>
          <ToggleSwitch
            label="Adjust colors based on time of day"
            checked={timeOfDayEnabled}
            onChange={setTimeOfDayEnabled}
            helperText="Subtle color shifts throughout the day for a calmer experience"
          />
          {timeOfDayEnabled && (
            <div className="mt-3 p-3 bg-blue-50 border border-blue-300 rounded-lg text-sm text-blue-700 dark:bg-blue-900/20 dark:border-blue-800 dark:text-blue-400">
              <p className="font-medium mb-1">Time-based color palette:</p>
              <ul className="space-y-0.5 text-xs">
                <li>🌅 Morning (5am-12pm): Soft blue & teal</li>
                <li>☀️ Afternoon (12pm-6pm): Blue & cyan</li>
                <li>🌆 Evening (6pm-10pm): Purple & indigo</li>
                <li>🌙 Night (10pm-5am): Violet & indigo</li>
              </ul>
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

interface ThemeOptionProps {
  label: string;
  icon: React.ReactNode;
  active: boolean;
  onClick: () => void;
}

function ThemeOption({ label, icon, active, onClick }: ThemeOptionProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`
        flex flex-col items-center justify-center gap-2 p-4 rounded-lg border-2 transition-all duration-fast
        ${active
          ? 'border-accent-primary bg-accent-primary/10'
          : 'border-border-subtle hover:border-border-visible hover:bg-background-surface'
        }
      `.replace(/\s+/g, ' ').trim()}
    >
      <span className={active ? 'text-accent-primary' : 'text-text-secondary'}>
        {icon}
      </span>
      <span className={`text-sm font-medium ${active ? 'text-accent-primary' : 'text-text-primary'}`}>
        {label}
      </span>
    </button>
  );
}
