import { ChatKitPage } from '@/components/chat/ChatKitPage';

/**
 * ChatKit Page Route
 * Feature: 007-ai-chatbot-phase3 (ChatKit integration)
 *
 * Separate route for OpenAI ChatKit implementation.
 * Original /chatbot route remains unchanged with legacy chat.
 *
 * Uses fixed viewport height to ensure ChatKit component renders properly.
 */
export default function ChatKitRoute() {
  return (
    <div className="flex h-[calc(100vh-4rem)] overflow-hidden">
      <ChatKitPage />
    </div>
  );
}
