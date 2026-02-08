'use client';

import { type Message } from '@/lib/api/chat';
import { type Task } from '@/types/task';
import { TaskCard } from './TaskCard';

interface ChatMessageProps {
  message: Message;
  tasks?: Task[];
  onTaskComplete?: (task: Task) => void;
  onTaskEdit?: (task: Task) => void;
  onTaskDelete?: (task: Task) => void;
}

/**
 * ChatMessage component displays a single chat message bubble
 * Enhanced to support task cards for natural language task management
 *
 * - User messages: right-aligned, accent color
 * - Assistant messages: left-aligned, surface color
 * - Task cards: displayed below assistant messages
 */
export function ChatMessage({
  message,
  tasks,
  onTaskComplete,
  onTaskEdit,
  onTaskDelete
}: ChatMessageProps) {
  const isUser = message.role === 'user';
  const hasTasks = tasks && tasks.length > 0;

  return (
    <div
      className={`
        flex w-full mb-3 sm:mb-4
        ${isUser ? 'justify-end' : 'justify-start'}
      `}
    >
      <div className={`max-w-[90%] sm:max-w-[85%] md:max-w-[80%] lg:max-w-[70%] ${hasTasks ? 'w-full sm:w-auto' : ''}`}>
        {/* Message bubble */}
        <div
          className={`
            px-4 py-3 rounded-2xl
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

        {/* Task cards - only for assistant messages */}
        {!isUser && hasTasks && (
          <div className="mt-3 space-y-2">
            {tasks.map((task) => (
              <TaskCard
                key={task.id}
                task={task}
                onComplete={onTaskComplete}
                onEdit={onTaskEdit}
                onDelete={onTaskDelete}
              />
            ))}
          </div>
        )}
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
