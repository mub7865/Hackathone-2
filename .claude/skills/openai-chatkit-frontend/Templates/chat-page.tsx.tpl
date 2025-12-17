/**
 * Chat Page Template
 *
 * PURPOSE:
 * - Provide a dedicated full-page chat interface.
 * - Handle authentication checks before rendering chat.
 * - Responsive layout for all screen sizes.
 *
 * HOW TO USE:
 * - Copy this template to your app directory (e.g. app/chat/page.tsx).
 * - Update authentication check based on your auth solution.
 * - Customize layout and styling as needed.
 *
 * REFERENCES:
 * - https://platform.openai.com/docs/guides/chatkit
 * - https://nextjs.org/docs/app/building-your-application/routing/pages
 */

import { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { ChatWidget } from '@/components/ChatWidget';

// Import your auth solution - adjust based on your setup
// import { auth } from '@/lib/auth';
// import { getServerSession } from 'next-auth';

export const metadata: Metadata = {
  title: 'Chat Assistant',
  description: 'AI-powered chat assistant to help manage your tasks',
};

export default async function ChatPage() {
  // Check authentication on server side
  // Uncomment and adjust based on your auth solution

  // Option 1: Better Auth
  // const session = await auth();
  // if (!session) {
  //   redirect('/login?callbackUrl=/chat');
  // }

  // Option 2: NextAuth
  // const session = await getServerSession();
  // if (!session) {
  //   redirect('/api/auth/signin?callbackUrl=/chat');
  // }

  // For development without auth:
  const session = { user: { id: 'dev-user', name: 'Developer' } };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <header className="bg-white dark:bg-gray-800 shadow-sm">
        <div className="max-w-4xl mx-auto px-4 py-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                Chat Assistant
              </h1>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Ask me anything about your tasks
              </p>
            </div>

            {/* User info */}
            {session?.user && (
              <div className="flex items-center space-x-3">
                <span className="text-sm text-gray-600 dark:text-gray-300">
                  {session.user.name || session.user.id}
                </span>
                <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center text-white text-sm font-medium">
                  {(session.user.name || session.user.id || 'U')
                    .charAt(0)
                    .toUpperCase()}
                </div>
              </div>
            )}
          </div>
        </div>
      </header>

      {/* Main content */}
      <main className="max-w-4xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        {/* Chat container */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg overflow-hidden">
          <ChatWidget
            className="h-[calc(100vh-220px)] min-h-[400px]"
            userId={session?.user?.id}
          />
        </div>

        {/* Helper text */}
        <div className="mt-6 text-center">
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Try saying: "Add a task to buy groceries" or "Show my pending tasks"
          </p>
        </div>
      </main>

      {/* Footer */}
      <footer className="fixed bottom-0 left-0 right-0 bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700">
        <div className="max-w-4xl mx-auto px-4 py-3 text-center">
          <p className="text-xs text-gray-400 dark:text-gray-500">
            Powered by OpenAI ChatKit
          </p>
        </div>
      </footer>
    </div>
  );
}

/**
 * Alternative: Chat Page with Sidebar Layout
 *
 * If you want a layout with conversation history sidebar:
 */

/*
export default async function ChatPageWithSidebar() {
  const session = await auth();
  if (!session) redirect('/login');

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-gray-900">
      {/* Sidebar - Conversation List *\/}
      <aside className="w-64 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 hidden md:block">
        <div className="p-4 border-b border-gray-200 dark:border-gray-700">
          <button className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
            New Chat
          </button>
        </div>
        <nav className="p-2">
          <p className="px-3 py-2 text-xs font-medium text-gray-500 uppercase">
            Recent Chats
          </p>
          {/* Conversation list would go here *\/}
          <p className="px-3 py-4 text-sm text-gray-400">
            No previous conversations
          </p>
        </nav>
      </aside>

      {/* Main Chat Area *\/}
      <main className="flex-1 flex flex-col">
        <header className="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 px-6 py-4">
          <h1 className="text-xl font-semibold text-gray-900 dark:text-white">
            New Conversation
          </h1>
        </header>
        <div className="flex-1 p-4">
          <ChatWidget
            className="h-full"
            userId={session.user.id}
          />
        </div>
      </main>
    </div>
  );
}
*/
