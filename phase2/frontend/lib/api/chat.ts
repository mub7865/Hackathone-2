/**
 * Chat API client for AI Chatbot Phase III
 * Provides functions for chat and conversation management
 */

import { apiRequest } from './client';

// ----- Types -----

export interface ToolCall {
  name: string;
  arguments: Record<string, unknown>;
  result: Record<string, unknown>;
}

export interface ChatRequest {
  message: string;
  conversation_id?: number | null;
}

export interface ChatResponse {
  conversation_id: number;
  response: string;
  tool_calls: ToolCall[];
}

export interface ConversationSummary {
  id: number;
  title: string | null;
  created_at: string;
  updated_at: string;
  message_count: number;
}

export interface ConversationListResponse {
  conversations: ConversationSummary[];
}

export interface Message {
  id: number;
  role: 'user' | 'assistant';
  content: string;
  created_at: string;
}

export interface ConversationDetail {
  id: number;
  title: string | null;
  created_at: string;
  updated_at: string;
  messages: Message[];
}

export interface DeleteConversationResponse {
  success: boolean;
  deleted_conversation_id: number;
  deleted_message_count: number;
}

// ----- API Functions -----

/**
 * Send a message to the AI assistant
 *
 * @param message - The message to send
 * @param conversationId - Optional conversation ID to continue existing chat
 * @returns Chat response with AI reply and tool calls
 */
export async function sendChatMessage(
  message: string,
  conversationId?: number | null
): Promise<ChatResponse> {
  const body: ChatRequest = {
    message,
  };

  if (conversationId !== undefined && conversationId !== null) {
    body.conversation_id = conversationId;
  }

  return apiRequest<ChatResponse>('/api/v1/chat', {
    method: 'POST',
    body,
  });
}

/**
 * Get all conversations for the current user
 *
 * @returns List of conversation summaries sorted by most recent
 */
export async function getConversations(): Promise<ConversationListResponse> {
  return apiRequest<ConversationListResponse>('/api/v1/conversations');
}

/**
 * Get a single conversation with all its messages
 *
 * @param conversationId - The conversation ID to retrieve
 * @returns Conversation with full message history
 */
export async function getConversation(
  conversationId: number
): Promise<ConversationDetail> {
  return apiRequest<ConversationDetail>(`/api/v1/conversations/${conversationId}`);
}

/**
 * Delete a conversation and all its messages
 *
 * @param conversationId - The conversation ID to delete
 * @returns Deletion confirmation with counts
 */
export async function deleteConversation(
  conversationId: number
): Promise<DeleteConversationResponse> {
  return apiRequest<DeleteConversationResponse>(
    `/api/v1/conversations/${conversationId}`,
    {
      method: 'DELETE',
    }
  );
}
