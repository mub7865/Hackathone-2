'use client';

import { type Message } from '@/lib/api/chat';

interface ChatMessageProps {
  message: Message;
}

/**
 * ChatMessage component displays a single chat message bubble
 * Feature: 007-ai-chatbot-phase3
 *
 * - User messages: right-aligned, accent color
 * - Assistant messages: left-aligned, surface color
 */
export function ChatMessage({ message }: ChatMessageProps) {
  const isUser = message.role === 'user';

  return (
    <div
      className={`
        flex w-full mb-4
        ${isUser ? 'justify-end' : 'justify-start'}
      `}
    >
      <div
        className={`
          max-w-[80%] sm:max-w-[70%] px-4 py-3 rounded-2xl
          ${isUser
            ? 'bg-accent-primary text-white rounded-br-md'
            : 'bg-background-surface text-text-primary rounded-bl-md'
          }
        `}
      >
        {/* Message content with proper whitespace handling */}
        <div className="whitespace-pre-wrap break-words text-body-sm leading-relaxed">
          {message.content}
        </div>

        {/* Timestamp */}
        <div
          className={`
            text-xs mt-2 opacity-70
            ${isUser ? 'text-white/70' : 'text-text-secondary'}
          `}
        >
          {formatTime(message.created_at)}
        </div>
      </div>
    </div>
  );
}

/**
 * Format timestamp for display
 */
function formatTime(isoString: string): string {
  try {
    const date = new Date(isoString);
    return date.toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return '';
  }
}
