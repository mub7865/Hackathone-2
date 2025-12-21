'use client';

import { useMemo } from 'react';
import { type ConversationSummary } from '@/lib/api/chat';

interface ChatSidebarProps {
  conversations: ConversationSummary[];
  currentConversationId: number | null;
  isOpen: boolean;
  isLoading?: boolean;
  onNewChat: () => void;
  onSelectConversation: (id: number) => void;
  onDeleteConversation: (id: number) => void;
  onClose: () => void;
}

/**
 * ChatSidebar component for conversation history
 * Feature: 007-ai-chatbot-phase3
 *
 * - New Chat button
 * - Grouped conversations (Today, Yesterday, Last 7 days, Older)
 * - Delete functionality
 * - Mobile slide-out drawer
 */
export function ChatSidebar({
  conversations,
  currentConversationId,
  isOpen,
  isLoading = false,
  onNewChat,
  onSelectConversation,
  onDeleteConversation,
  onClose,
}: ChatSidebarProps) {
  // Group conversations by date
  const groupedConversations = useMemo(() => {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const lastWeek = new Date(today);
    lastWeek.setDate(lastWeek.getDate() - 7);

    const groups: Record<string, ConversationSummary[]> = {
      Today: [],
      Yesterday: [],
      'Last 7 days': [],
      Older: [],
    };

    for (const conv of conversations) {
      const convDate = new Date(conv.updated_at);
      const convDay = new Date(convDate.getFullYear(), convDate.getMonth(), convDate.getDate());

      if (convDay.getTime() === today.getTime()) {
        groups['Today'].push(conv);
      } else if (convDay.getTime() === yesterday.getTime()) {
        groups['Yesterday'].push(conv);
      } else if (convDay >= lastWeek) {
        groups['Last 7 days'].push(conv);
      } else {
        groups['Older'].push(conv);
      }
    }

    // Filter out empty groups
    return Object.entries(groups).filter(([, items]) => items.length > 0);
  }, [conversations]);

  return (
    <>
      {/* Sidebar container */}
      <aside
        className={`
          fixed lg:relative inset-y-0 left-0 z-40
          w-72 bg-background-elevated border-r border-border-subtle
          transform transition-transform duration-300 ease-out
          ${isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
          flex flex-col
        `}
      >
        {/* Header */}
        <div className="p-4 border-b border-border-subtle">
          {/* Close button (mobile only) */}
          <div className="flex items-center justify-between lg:hidden mb-4">
            <h2 className="text-lg font-semibold text-text-primary">Conversations</h2>
            <button
              type="button"
              onClick={onClose}
              className="p-2 rounded-lg hover:bg-background-surface transition-colors"
              aria-label="Close sidebar"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
                className="w-5 h-5 text-text-secondary"
              >
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          {/* New Chat button */}
          <button
            type="button"
            onClick={onNewChat}
            className={`
              w-full flex items-center gap-3 px-4 py-3 rounded-xl
              bg-accent-primary text-white
              hover:bg-accent-hover
              transition-colors duration-fast
              font-medium
            `}
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={2}
              stroke="currentColor"
              className="w-5 h-5"
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            New Chat
          </button>
        </div>

        {/* Conversation list */}
        <div className="flex-1 overflow-y-auto p-2">
          {isLoading ? (
            /* Loading skeletons */
            <div className="space-y-2 p-2">
              {[1, 2, 3].map((i) => (
                <div
                  key={i}
                  className="h-12 bg-background-surface rounded-lg animate-pulse"
                />
              ))}
            </div>
          ) : conversations.length === 0 ? (
            /* Empty state */
            <div className="text-center py-8 px-4">
              <p className="text-text-secondary text-body-sm">
                No conversations yet. Start a new chat!
              </p>
            </div>
          ) : (
            /* Grouped conversations */
            <div className="space-y-4">
              {groupedConversations.map(([group, items]) => (
                <div key={group}>
                  <h3 className="px-3 py-2 text-caption font-medium text-text-secondary uppercase tracking-wider">
                    {group}
                  </h3>
                  <div className="space-y-1">
                    {items.map((conv) => (
                      <ConversationItem
                        key={conv.id}
                        conversation={conv}
                        isActive={conv.id === currentConversationId}
                        onSelect={() => onSelectConversation(conv.id)}
                        onDelete={() => onDeleteConversation(conv.id)}
                      />
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </aside>
    </>
  );
}

interface ConversationItemProps {
  conversation: ConversationSummary;
  isActive: boolean;
  onSelect: () => void;
  onDelete: () => void;
}

function ConversationItem({
  conversation,
  isActive,
  onSelect,
  onDelete,
}: ConversationItemProps) {
  return (
    <div
      className={`
        group flex items-center gap-2 px-3 py-2 rounded-lg cursor-pointer
        transition-colors duration-fast
        ${isActive
          ? 'bg-accent-primary/10 text-accent-primary'
          : 'hover:bg-background-surface text-text-primary'
        }
      `}
      onClick={onSelect}
    >
      {/* Chat icon */}
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        strokeWidth={1.5}
        stroke="currentColor"
        className={`w-4 h-4 flex-shrink-0 ${isActive ? 'text-accent-primary' : 'text-text-secondary'}`}
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M8.625 12a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H8.25m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H12m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0h-.375M21 12c0 4.556-4.03 8.25-9 8.25a9.764 9.764 0 01-2.555-.337A5.972 5.972 0 015.41 20.97a5.969 5.969 0 01-.474-.065 4.48 4.48 0 00.978-2.025c.09-.457-.133-.901-.467-1.226C3.93 16.178 3 14.189 3 12c0-4.556 4.03-8.25 9-8.25s9 3.694 9 8.25z"
        />
      </svg>

      {/* Title */}
      <span className="flex-1 truncate text-body-sm">
        {conversation.title || 'New conversation'}
      </span>

      {/* Delete button */}
      <button
        type="button"
        onClick={(e) => {
          e.stopPropagation();
          onDelete();
        }}
        className={`
          p-1 rounded opacity-0 group-hover:opacity-100
          hover:bg-status-error/10 hover:text-status-error
          transition-all duration-fast
        `}
        aria-label="Delete conversation"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          strokeWidth={1.5}
          stroke="currentColor"
          className="w-4 h-4"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0"
          />
        </svg>
      </button>
    </div>
  );
}
