/**
 * Chat Toggle Button Component Template
 *
 * PURPOSE:
 * - Provide a floating chat button that toggles a chat panel.
 * - Enable adding chat to existing pages without dedicated routes.
 * - Smooth animations for open/close transitions.
 *
 * HOW TO USE:
 * - Copy this template to your project (e.g. components/ChatToggle.tsx).
 * - Import and add to your layout or specific pages.
 * - Customize positioning and styling as needed.
 *
 * REFERENCES:
 * - https://platform.openai.com/docs/guides/chatkit
 */

'use client';

import { useState, useCallback, useEffect } from 'react';
import { ChatWidget } from './ChatWidget';

interface ChatToggleProps {
  /** Position of the toggle button */
  position?: 'bottom-right' | 'bottom-left' | 'top-right' | 'top-left';
  /** Custom button label for accessibility */
  buttonLabel?: string;
  /** Initial open state */
  defaultOpen?: boolean;
  /** Chat panel width */
  panelWidth?: string;
  /** Chat panel height */
  panelHeight?: string;
}

export function ChatToggle({
  position = 'bottom-right',
  buttonLabel = 'Chat Assistant',
  defaultOpen = false,
  panelWidth = '380px',
  panelHeight = '500px',
}: ChatToggleProps) {
  const [isOpen, setIsOpen] = useState(defaultOpen);
  const [isAnimating, setIsAnimating] = useState(false);

  // Position classes based on prop
  const positionClasses = {
    'bottom-right': 'bottom-6 right-6',
    'bottom-left': 'bottom-6 left-6',
    'top-right': 'top-6 right-6',
    'top-left': 'top-6 left-6',
  };

  // Panel position based on button position
  const panelPositionClasses = {
    'bottom-right': 'bottom-24 right-6',
    'bottom-left': 'bottom-24 left-6',
    'top-right': 'top-24 right-6',
    'top-left': 'top-24 left-6',
  };

  // Handle toggle with animation
  const handleToggle = useCallback(() => {
    if (isOpen) {
      // Start closing animation
      setIsAnimating(true);
      setTimeout(() => {
        setIsOpen(false);
        setIsAnimating(false);
      }, 200);
    } else {
      setIsOpen(true);
    }
  }, [isOpen]);

  // Handle escape key to close
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        handleToggle();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen, handleToggle]);

  return (
    <>
      {/* Floating toggle button */}
      <button
        onClick={handleToggle}
        className={`
          fixed ${positionClasses[position]}
          p-4 rounded-full shadow-lg
          bg-blue-600 text-white
          hover:bg-blue-700 hover:scale-105
          focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2
          transition-all duration-200
          z-50
        `}
        aria-label={isOpen ? 'Close chat' : buttonLabel}
        aria-expanded={isOpen}
      >
        {isOpen ? (
          // Close icon (X)
          <svg
            className="w-6 h-6"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        ) : (
          // Chat icon
          <svg
            className="w-6 h-6"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
            />
          </svg>
        )}
      </button>

      {/* Chat panel */}
      {isOpen && (
        <div
          className={`
            fixed ${panelPositionClasses[position]}
            z-40
            ${isAnimating ? 'animate-fade-out' : 'animate-fade-in'}
          `}
          style={{
            width: panelWidth,
            height: panelHeight,
          }}
          role="dialog"
          aria-label="Chat Assistant"
        >
          {/* Panel header with close button */}
          <div className="flex items-center justify-between px-4 py-2 bg-blue-600 text-white rounded-t-lg">
            <span className="font-medium">Chat Assistant</span>
            <button
              onClick={handleToggle}
              className="p-1 hover:bg-blue-700 rounded transition-colors"
              aria-label="Close chat"
            >
              <svg
                className="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>

          {/* Chat widget */}
          <ChatWidget className="h-[calc(100%-44px)] rounded-t-none rounded-b-lg" />
        </div>
      )}

      {/* Backdrop for mobile (optional) */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/20 z-30 md:hidden"
          onClick={handleToggle}
          aria-hidden="true"
        />
      )}

      {/* Animation styles */}
      <style jsx global>{`
        @keyframes fade-in {
          from {
            opacity: 0;
            transform: translateY(10px) scale(0.95);
          }
          to {
            opacity: 1;
            transform: translateY(0) scale(1);
          }
        }

        @keyframes fade-out {
          from {
            opacity: 1;
            transform: translateY(0) scale(1);
          }
          to {
            opacity: 0;
            transform: translateY(10px) scale(0.95);
          }
        }

        .animate-fade-in {
          animation: fade-in 0.2s ease-out forwards;
        }

        .animate-fade-out {
          animation: fade-out 0.2s ease-in forwards;
        }
      `}</style>
    </>
  );
}

export default ChatToggle;
