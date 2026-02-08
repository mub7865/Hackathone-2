/**
 * ToggleSwitch Component
 *
 * Reusable toggle switch for boolean settings.
 * Used in notification and theme settings.
 */

'use client';

interface ToggleSwitchProps {
  label: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
  disabled?: boolean;
  helperText?: string;
}

export function ToggleSwitch({
  label,
  checked,
  onChange,
  disabled = false,
  helperText,
}: ToggleSwitchProps) {
  return (
    <div className="flex items-center justify-between py-3">
      <div className="flex-1">
        <label className="text-sm font-medium text-text-primary cursor-pointer">
          {label}
        </label>
        {helperText && (
          <p className="text-xs text-text-secondary mt-0.5">{helperText}</p>
        )}
      </div>
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        onClick={() => !disabled && onChange(!checked)}
        disabled={disabled}
        className={`
          relative inline-flex h-6 w-11 items-center rounded-full
          transition-colors duration-fast focus:outline-none focus:ring-2 focus:ring-accent-primary focus:ring-offset-2
          ${checked ? 'bg-accent-primary' : 'bg-gray-300 dark:bg-gray-600'}
          ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
        `.replace(/\s+/g, ' ').trim()}
      >
        <span
          className={`
            inline-block h-4 w-4 transform rounded-full bg-white transition-transform duration-fast
            ${checked ? 'translate-x-6' : 'translate-x-1'}
          `.replace(/\s+/g, ' ').trim()}
        />
      </button>
    </div>
  );
}
