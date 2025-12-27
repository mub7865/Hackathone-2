'use client';

import { useRef, useEffect } from 'react';
import { type Message } from '@/lib/api/chat';
import { ChatMessage } from './ChatMessage';
import { ChatInput } from './ChatInput';
import { WelcomeMessage } from './WelcomeMessage';

interface ChatAreaProps {
  messages: Message[];
  onSendMessage: (message: string) => void;
  isLoading?: boolean;
  showWelcome?: boolean;
  onExampleClick?: (example: string) => void;
}

/**
 * ChatArea component containing messages list and input
 * Feature: 007-ai-chatbot-phase3
 *
 * - Scrollable message area with auto-scroll
 * - Welcome message for new conversations
 * - Loading indicator while AI responds
 */
export function ChatArea({
  messages,
  onSendMessage,
  isLoading = false,
  showWelcome = false,
  onExampleClick,
}: ChatAreaProps) {
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isLoading]);

  return (
    <div className="flex flex-col h-full bg-background-base">
      {/* Messages area */}
      <div className="flex-1 overflow-y-auto px-4 py-6">
        {showWelcome && messages.length === 0 ? (
          /* Welcome message for empty state */
          <WelcomeMessage onExampleClick={onExampleClick} />
        ) : (
          /* Message list */
          <div className="max-w-3xl mx-auto">
            {messages.map((message) => (
              <ChatMessage key={message.id} message={message} />
            ))}

            {/* Loading indicator */}
            {isLoading && (
              <div className="flex justify-start mb-4">
                <div className="bg-background-surface px-4 py-3 rounded-2xl rounded-bl-md">
                  <div className="flex items-center gap-2">
                    <div className="flex space-x-1">
                      <div className="w-2 h-2 bg-text-secondary rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                      <div className="w-2 h-2 bg-text-secondary rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                      <div className="w-2 h-2 bg-text-secondary rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                    </div>
                    <span className="text-text-secondary text-body-sm">Thinking...</span>
                  </div>
                </div>
              </div>
            )}

            {/* Scroll anchor */}
            <div ref={messagesEndRef} />
          </div>
        )}
      </div>

      {/* Input area */}
      <ChatInput
        onSend={onSendMessage}
        disabled={isLoading}
        placeholder={isLoading ? 'Waiting for response...' : 'Type your message...'}
      />
    </div>
  );
}
