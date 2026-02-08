/**
 * TagInput component for managing task tags.
 *
 * This component provides:
 * - Add tags by typing and pressing Enter or comma
 * - Remove tags by clicking X button
 * - Tag validation (max length, no duplicates)
 * - Autocomplete suggestions from existing tags
 * - Visual tag badges with colors
 */

'use client';

import { useState, useRef, KeyboardEvent } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface TagInputProps {
  value: string[];
  onChange: (tags: string[]) => void;
  suggestions?: string[];
  maxTags?: number;
  maxTagLength?: number;
  placeholder?: string;
  disabled?: boolean;
}

const TAG_COLORS = [
  'bg-blue-100 text-blue-700 border-blue-300',
  'bg-green-100 text-green-700 border-green-300',
  'bg-purple-100 text-purple-700 border-purple-300',
  'bg-pink-100 text-pink-700 border-pink-300',
  'bg-yellow-100 text-yellow-700 border-yellow-300',
  'bg-indigo-100 text-indigo-700 border-indigo-300',
  'bg-red-100 text-red-700 border-red-300',
  'bg-orange-100 text-orange-700 border-orange-300',
];

function getTagColor(tag: string): string {
  // Use tag string to consistently assign colors
  const hash = tag.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
  return TAG_COLORS[hash % TAG_COLORS.length];
}

export default function TagInput({
  value,
  onChange,
  suggestions = [],
  maxTags = 10,
  maxTagLength = 50,
  placeholder = 'Add tags...',
  disabled = false,
}: TagInputProps) {
  const [inputValue, setInputValue] = useState('');
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Filter suggestions based on input and exclude already selected tags
  const filteredSuggestions = suggestions
    .filter(
      (tag) =>
        tag.toLowerCase().includes(inputValue.toLowerCase()) &&
        !value.includes(tag)
    )
    .slice(0, 5);

  const addTag = (tag: string) => {
    const trimmedTag = tag.trim().toLowerCase();

    // Validation
    if (!trimmedTag) {
      return;
    }

    if (trimmedTag.length > maxTagLength) {
      setError(`Tag must be ${maxTagLength} characters or less`);
      return;
    }

    if (value.includes(trimmedTag)) {
      setError('Tag already exists');
      return;
    }

    if (value.length >= maxTags) {
      setError(`Maximum ${maxTags} tags allowed`);
      return;
    }

    // Add tag
    onChange([...value, trimmedTag]);
    setInputValue('');
    setError(null);
    setShowSuggestions(false);
  };

  const removeTag = (tagToRemove: string) => {
    onChange(value.filter((tag) => tag !== tagToRemove));
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      addTag(inputValue);
    } else if (e.key === 'Backspace' && !inputValue && value.length > 0) {
      // Remove last tag on backspace if input is empty
      removeTag(value[value.length - 1]);
    } else if (e.key === 'Escape') {
      setShowSuggestions(false);
      setInputValue('');
    }
  };

  const handleInputChange = (newValue: string) => {
    setInputValue(newValue);
    setError(null);
    setShowSuggestions(newValue.length > 0);
  };

  return (
    <div className="space-y-2">
      {/* Tags Display */}
      <div className="flex flex-wrap gap-2 min-h-[40px] p-2 bg-gray-50 rounded-lg border-2 border-gray-200">
        <AnimatePresence>
          {value.map((tag) => (
            <motion.span
              key={tag}
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.8 }}
              className={`
                inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-sm font-medium
                border transition-all duration-200
                ${getTagColor(tag)}
              `}
            >
              <span>{tag}</span>
              {!disabled && (
                <button
                  type="button"
                  onClick={() => removeTag(tag)}
                  className="hover:scale-110 transition-transform"
                  aria-label={`Remove ${tag}`}
                >
                  <svg
                    className="w-3.5 h-3.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M6 18L18 6M6 6l12 12"
                    />
                  </svg>
                </button>
              )}
            </motion.span>
          ))}
        </AnimatePresence>

        {/* Input Field */}
        {!disabled && value.length < maxTags && (
          <input
            ref={inputRef}
            type="text"
            value={inputValue}
            onChange={(e) => handleInputChange(e.target.value)}
            onKeyDown={handleKeyDown}
            onFocus={() => setShowSuggestions(inputValue.length > 0)}
            onBlur={() => setTimeout(() => setShowSuggestions(false), 200)}
            placeholder={value.length === 0 ? placeholder : ''}
            className="flex-1 min-w-[120px] bg-transparent outline-none text-sm"
            disabled={disabled}
          />
        )}
      </div>

      {/* Error Message */}
      {error && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-sm text-red-600"
        >
          {error}
        </motion.div>
      )}

      {/* Suggestions Dropdown */}
      {showSuggestions && filteredSuggestions.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white border-2 border-gray-200 rounded-lg shadow-lg overflow-hidden"
        >
          {filteredSuggestions.map((suggestion) => (
            <button
              key={suggestion}
              type="button"
              onClick={() => addTag(suggestion)}
              className="w-full px-4 py-2 text-left text-sm hover:bg-gray-100 transition-colors"
            >
              <span className={`inline-block px-2 py-0.5 rounded-full text-xs ${getTagColor(suggestion)}`}>
                {suggestion}
              </span>
            </button>
          ))}
        </motion.div>
      )}

      {/* Helper Text */}
      <div className="flex items-center justify-between text-xs text-gray-500">
        <span>
          Press Enter or comma to add tags. {value.length}/{maxTags} tags
        </span>
        {inputValue.length > 0 && (
          <span>
            {inputValue.length}/{maxTagLength} characters
          </span>
        )}
      </div>
    </div>
  );
}

/**
 * TagBadge component for displaying a single tag.
 */
interface TagBadgeProps {
  tag: string;
  onRemove?: () => void;
  size?: 'sm' | 'md' | 'lg';
}

export function TagBadge({ tag, onRemove, size = 'sm' }: TagBadgeProps) {
  const sizeClasses = {
    sm: 'px-2 py-0.5 text-xs',
    md: 'px-3 py-1 text-sm',
    lg: 'px-4 py-1.5 text-base',
  };

  return (
    <span
      className={`
        inline-flex items-center gap-1.5 rounded-full font-medium border
        ${getTagColor(tag)}
        ${sizeClasses[size]}
      `}
    >
      <span>{tag}</span>
      {onRemove && (
        <button
          type="button"
          onClick={onRemove}
          className="hover:scale-110 transition-transform"
          aria-label={`Remove ${tag}`}
        >
          <svg
            className="w-3 h-3"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>
      )}
    </span>
  );
}

/**
 * TagList component for displaying multiple tags.
 */
interface TagListProps {
  tags: string[];
  onRemove?: (tag: string) => void;
  maxDisplay?: number;
  size?: 'sm' | 'md' | 'lg';
}

export function TagList({ tags, onRemove, maxDisplay, size = 'sm' }: TagListProps) {
  const displayTags = maxDisplay ? tags.slice(0, maxDisplay) : tags;
  const remainingCount = maxDisplay && tags.length > maxDisplay ? tags.length - maxDisplay : 0;

  return (
    <div className="flex flex-wrap gap-1.5">
      {displayTags.map((tag) => (
        <TagBadge
          key={tag}
          tag={tag}
          onRemove={onRemove ? () => onRemove(tag) : undefined}
          size={size}
        />
      ))}
      {remainingCount > 0 && (
        <span className="px-2 py-0.5 text-xs text-gray-500 bg-gray-100 rounded-full">
          +{remainingCount} more
        </span>
      )}
    </div>
  );
}
