'use client';

import { useState, useCallback, useEffect } from 'react';
import {
  sendChatMessage,
  getConversations,
  getConversation,
  deleteConversation,
  type Message,
  type ConversationSummary,
} from '@/lib/api/chat';
import { ChatArea } from '@/components/chat/ChatArea';
import { ChatSidebar } from '@/components/chat/ChatSidebar';
import { getErrorMessage } from '@/lib/api/client';
import { parseTaskIntent } from '@/lib/chat/taskIntentParser';
import { executeTaskIntent } from '@/lib/chat/taskExecutor';
import { updateTask, deleteTask } from '@/lib/api/tasks';
import type { Task } from '@/types/task';

/**
 * Chatbot page - AI-powered task management via natural language
 * Feature: 007-ai-chatbot-phase3
 *
 * - Sidebar with conversation history
 * - Chat area with messages and input
 * - New Chat functionality
 * - Mobile responsive with hamburger menu
 */
export default function ChatbotPage() {
  // Sidebar state
  const [conversations, setConversations] = useState<ConversationSummary[]>([]);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [isLoadingConversations, setIsLoadingConversations] = useState(true);

  // Current conversation state
  const [currentConversationId, setCurrentConversationId] = useState<number | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [isLoadingMessages, setIsLoadingMessages] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Task management state - maps message IDs to tasks
  const [messageTasks, setMessageTasks] = useState<Map<number, Task[]>>(new Map());

  // Load conversations on mount
  useEffect(() => {
    loadConversations();
  }, []);

  // Load conversations list
  const loadConversations = useCallback(async () => {
    setIsLoadingConversations(true);
    try {
      const response = await getConversations();
      setConversations(response.conversations);
    } catch (err) {
      console.error('Failed to load conversations:', err);
    } finally {
      setIsLoadingConversations(false);
    }
  }, []);

  // Load a specific conversation
  const loadConversation = useCallback(async (conversationId: number) => {
    setIsLoadingMessages(true);
    setError(null);
    try {
      const conversation = await getConversation(conversationId);
      setCurrentConversationId(conversationId);
      setMessages(conversation.messages);
      setIsSidebarOpen(false); // Close sidebar on mobile after selection
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setIsLoadingMessages(false);
    }
  }, []);

  // Start a new conversation
  const handleNewChat = useCallback(() => {
    setCurrentConversationId(null);
    setMessages([]);
    setError(null);
    setIsSidebarOpen(false);
  }, []);

  // Select a conversation from sidebar
  const handleSelectConversation = useCallback(
    (conversationId: number) => {
      loadConversation(conversationId);
    },
    [loadConversation]
  );

  // Delete a conversation
  const handleDeleteConversation = useCallback(
    async (conversationId: number) => {
      try {
        await deleteConversation(conversationId);
        setConversations((prev) => prev.filter((c) => c.id !== conversationId));

        // If deleted current conversation, start new chat
        if (currentConversationId === conversationId) {
          handleNewChat();
        }
      } catch (err) {
        console.error('Failed to delete conversation:', err);
      }
    },
    [currentConversationId, handleNewChat]
  );

  // Task management handlers
  const handleTaskComplete = useCallback(async (task: Task) => {
    try {
      await updateTask(task.id, { status: 'completed' });
      // Update task in messageTasks map
      setMessageTasks((prev) => {
        const newMap = new Map(prev);
        for (const [messageId, tasks] of newMap.entries()) {
          const updatedTasks = tasks.map((t) =>
            t.id === task.id ? { ...t, status: 'completed' as const } : t
          );
          newMap.set(messageId, updatedTasks);
        }
        return newMap;
      });
    } catch (err) {
      console.error('Failed to complete task:', err);
      setError(getErrorMessage(err));
    }
  }, []);

  const handleTaskEdit = useCallback((task: Task) => {
    // TODO: Open edit modal or navigate to tasks page
    console.log('Edit task:', task);
  }, []);

  const handleTaskDelete = useCallback(async (task: Task) => {
    try {
      await deleteTask(task.id);
      // Remove task from messageTasks map
      setMessageTasks((prev) => {
        const newMap = new Map(prev);
        for (const [messageId, tasks] of newMap.entries()) {
          const filteredTasks = tasks.filter((t) => t.id !== task.id);
          if (filteredTasks.length > 0) {
            newMap.set(messageId, filteredTasks);
          } else {
            newMap.delete(messageId);
          }
        }
        return newMap;
      });
    } catch (err) {
      console.error('Failed to delete task:', err);
      setError(getErrorMessage(err));
    }
  }, []);

  // Send a message with task intent parsing
  const handleSendMessage = useCallback(
    async (content: string) => {
      setIsSending(true);
      setError(null);

      // Optimistically add user message
      const tempUserMessage: Message = {
        id: Date.now(),
        role: 'user',
        content,
        created_at: new Date().toISOString(),
      };
      setMessages((prev) => [...prev, tempUserMessage]);

      try {
        // Parse task intent
        const taskIntent = parseTaskIntent(content);

        let responseMessage: string;
        let tasks: Task[] | undefined;

        if (taskIntent && taskIntent.confidence > 0.6) {
          // Execute task operation
          const result = await executeTaskIntent(taskIntent);
          responseMessage = result.message;
          tasks = result.tasks;
        } else {
          // Fall back to regular chat
          const response = await sendChatMessage(content, currentConversationId);

          // Update conversation ID if new conversation was created
          if (!currentConversationId) {
            setCurrentConversationId(response.conversation_id);
            // Refresh conversations list to show new conversation
            loadConversations();
          }

          responseMessage = response.response;
        }

        // Add assistant response
        const assistantMessage: Message = {
          id: Date.now() + 1,
          role: 'assistant',
          content: responseMessage,
          created_at: new Date().toISOString(),
        };
        setMessages((prev) => [...prev, assistantMessage]);

        // Store tasks associated with this message
        if (tasks && tasks.length > 0) {
          setMessageTasks((prev) => {
            const newMap = new Map(prev);
            newMap.set(assistantMessage.id, tasks);
            return newMap;
          });
        }
      } catch (err) {
        setError(getErrorMessage(err));
        // Remove optimistic user message on error
        setMessages((prev) => prev.filter((m) => m.id !== tempUserMessage.id));
      } finally {
        setIsSending(false);
      }
    },
    [currentConversationId, loadConversations]
  );

  // Handle example click from welcome message
  const handleExampleClick = useCallback(
    (example: string) => {
      handleSendMessage(example);
    },
    [handleSendMessage]
  );

  // Toggle sidebar (for mobile)
  const toggleSidebar = useCallback(() => {
    setIsSidebarOpen((prev) => !prev);
  }, []);

  return (
    <div className="flex h-[calc(100vh-4rem)] overflow-hidden">
      {/* Sidebar */}
      <ChatSidebar
        conversations={conversations}
        currentConversationId={currentConversationId}
        isOpen={isSidebarOpen}
        isLoading={isLoadingConversations}
        onNewChat={handleNewChat}
        onSelectConversation={handleSelectConversation}
        onDeleteConversation={handleDeleteConversation}
        onClose={() => setIsSidebarOpen(false)}
      />

      {/* Main chat area */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Mobile header with hamburger */}
        <div className="lg:hidden flex items-center gap-2 sm:gap-3 p-3 sm:p-4 border-b border-border-subtle bg-background-elevated flex-shrink-0">
          <button
            type="button"
            onClick={toggleSidebar}
            className="p-1.5 sm:p-2 rounded-lg hover:bg-background-surface transition-colors flex-shrink-0"
            aria-label="Toggle sidebar"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={1.5}
              stroke="currentColor"
              className="w-5 h-5 sm:w-6 sm:h-6 text-text-primary"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
              />
            </svg>
          </button>
          <h1 className="text-base sm:text-lg font-semibold text-text-primary truncate">
            {currentConversationId ? 'Chat' : 'New Chat'}
          </h1>
        </div>

        {/* Error message */}
        {error && (
          <div className="p-3 sm:p-4 bg-status-error/10 border-b border-status-error/20 flex-shrink-0">
            <p className="text-status-error text-sm sm:text-body-sm">{error}</p>
          </div>
        )}

        {/* Chat area */}
        {isLoadingMessages ? (
          <div className="flex-1 flex items-center justify-center">
            <div className="w-10 h-10 border-4 border-border-subtle border-t-accent-primary rounded-full animate-spin" />
          </div>
        ) : (
          <ChatArea
            messages={messages}
            onSendMessage={handleSendMessage}
            isLoading={isSending}
            showWelcome={!currentConversationId}
            onExampleClick={handleExampleClick}
            messageTasks={messageTasks}
            onTaskComplete={handleTaskComplete}
            onTaskEdit={handleTaskEdit}
            onTaskDelete={handleTaskDelete}
          />
        )}
      </div>

      {/* Mobile sidebar backdrop */}
      {isSidebarOpen && (
        <div
          className="lg:hidden fixed inset-0 bg-black/50 z-30"
          onClick={() => setIsSidebarOpen(false)}
          aria-hidden="true"
        />
      )}
    </div>
  );
}
