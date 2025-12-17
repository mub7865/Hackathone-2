/**
 * ChatKit Widget Component Template
 *
 * PURPOSE:
 * - Provide a reusable ChatKit component for Next.js applications.
 * - Handle authentication token fetching from backend.
 * - Manage error states and loading gracefully.
 *
 * HOW TO USE:
 * - Copy this template to your project (e.g. components/ChatWidget.tsx).
 * - Update the session endpoint URL to match your backend.
 * - Integrate with your authentication solution.
 *
 * REFERENCES:
 * - https://platform.openai.com/docs/guides/chatkit
 * - https://openai.github.io/chatkit-js/
 * - https://www.npmjs.com/package/@openai/chatkit-react
 */

'use client';

import { useState, useCallback } from 'react';
import { ChatKit, useChatKit } from '@openai/chatkit-react';

// Import your auth solution - adjust based on your setup
// import { useAuth } from '@/lib/auth-client';
// import { useSession } from 'next-auth/react';

interface ChatWidgetProps {
  /** Additional CSS classes for the ChatKit container */
  className?: string;
  /** User ID for the chat session (optional, can be derived from auth) */
  userId?: string;
  /** Custom session endpoint URL */
  sessionEndpoint?: string;
}

interface ChatError {
  message: string;
  retryable: boolean;
}

export function ChatWidget({
  className = '',
  userId,
  sessionEndpoint = '/api/chatkit/session',
}: ChatWidgetProps) {
  // State for error handling
  const [error, setError] = useState<ChatError | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Get auth token - uncomment and adjust based on your auth solution
  // const { token, session } = useAuth();
  // const { data: session } = useSession();

  // Placeholder for auth token - replace with your actual auth
  const getAuthToken = useCallback(async (): Promise<string | null> => {
    // TODO: Replace with your authentication logic
    // return token;
    // return session?.accessToken;

    // For development/testing without auth:
    return null;
  }, []);

  // Get user ID - from props or auth session
  const getUserId = useCallback((): string => {
    if (userId) return userId;

    // TODO: Get from auth session
    // return session?.user?.id || 'anonymous';

    return 'anonymous';
  }, [userId]);

  // Configure ChatKit
  const { control } = useChatKit({
    api: {
      /**
       * Fetch client secret from your backend.
       * This is called when ChatKit needs to authenticate.
       *
       * @param existingSecret - Previous secret if refreshing
       * @returns New client secret string
       */
      async getClientSecret(existingSecret?: string): Promise<string> {
        setIsLoading(true);
        setError(null);

        try {
          const authToken = await getAuthToken();
          const currentUserId = getUserId();

          // Build request headers
          const headers: HeadersInit = {
            'Content-Type': 'application/json',
          };

          // Add auth header if token available
          if (authToken) {
            headers['Authorization'] = `Bearer ${authToken}`;
          }

          // Request new session from backend
          const response = await fetch(sessionEndpoint, {
            method: 'POST',
            headers,
            body: JSON.stringify({
              user_id: currentUserId,
              // Include existing secret if refreshing
              refresh: existingSecret ? true : false,
            }),
          });

          if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(
              errorData.detail || `HTTP error ${response.status}`
            );
          }

          const data = await response.json();

          if (!data.client_secret) {
            throw new Error('Invalid response: missing client_secret');
          }

          setIsLoading(false);
          return data.client_secret;
        } catch (err) {
          setIsLoading(false);

          const errorMessage =
            err instanceof Error ? err.message : 'Failed to connect to chat';

          setError({
            message: errorMessage,
            retryable: true,
          });

          throw err;
        }
      },
    },
  });

  // Retry handler
  const handleRetry = useCallback(() => {
    setError(null);
    // ChatKit will automatically retry on next interaction
  }, []);

  // Render error state
  if (error) {
    return (
      <div
        className={`
          flex flex-col items-center justify-center
          p-6 bg-red-50 dark:bg-red-900/20
          border border-red-200 dark:border-red-800
          rounded-lg text-center
          ${className}
        `}
        role="alert"
      >
        <svg
          className="w-12 h-12 text-red-500 mb-4"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
          />
        </svg>
        <h3 className="text-lg font-semibold text-red-700 dark:text-red-300 mb-2">
          Connection Error
        </h3>
        <p className="text-red-600 dark:text-red-400 mb-4">{error.message}</p>
        {error.retryable && (
          <button
            onClick={handleRetry}
            className="
              px-4 py-2 bg-red-600 text-white rounded-md
              hover:bg-red-700 transition-colors
              focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2
            "
          >
            Try Again
          </button>
        )}
      </div>
    );
  }

  // Render loading state (optional - ChatKit handles its own loading)
  if (isLoading) {
    return (
      <div
        className={`
          flex items-center justify-center
          bg-gray-50 dark:bg-gray-800
          rounded-lg
          ${className}
        `}
      >
        <div className="flex flex-col items-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mb-2" />
          <p className="text-gray-600 dark:text-gray-400">
            Connecting to assistant...
          </p>
        </div>
      </div>
    );
  }

  // Render ChatKit
  return (
    <ChatKit
      control={control}
      className={`
        rounded-lg shadow-lg
        border border-gray-200 dark:border-gray-700
        ${className}
      `}
    />
  );
}

export default ChatWidget;
