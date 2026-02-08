'use client';

import { useState } from 'react';

/**
 * ChatKit page component - Simplified version
 * Feature: 007-ai-chatbot-phase3 (ChatKit integration)
 *
 * Shows a placeholder UI for ChatKit integration.
 * Backend is ready at /api/v1/chatkit endpoint.
 */
export function ChatKitPage() {
  const [message, setMessage] = useState('');

  const handleSend = () => {
    if (message.trim()) {
      console.log('Sending message:', message);
      // TODO: Integrate with ChatKit backend
      setMessage('');
    }
  };

  return (
    <div className="flex flex-col h-full bg-background-base">
      <div className="flex-1 overflow-hidden p-4">
        <div className="h-full bg-background-elevated rounded-lg border border-border-subtle flex flex-col">
          {/* Header */}
          <div className="p-6 border-b border-border-subtle">
            <h2 className="text-2xl font-semibold text-text-primary mb-2">
              AI Chat Assistant
            </h2>
            <p className="text-text-secondary text-sm">
              Powered by OpenAI ChatKit
            </p>
          </div>

          {/* Chat Area */}
          <div className="flex-1 overflow-y-auto p-6">
            <div className="max-w-3xl mx-auto space-y-4">
              {/* Welcome Message */}
              <div className="bg-background-surface rounded-lg p-4 border border-border-subtle">
                <p className="text-text-primary mb-2">
                  👋 Welcome to ChatKit!
                </p>
                <p className="text-text-secondary text-sm">
                  This is a placeholder UI. The backend ChatKit server is ready at{' '}
                  <code className="bg-background-base px-2 py-1 rounded text-accent-primary">
                    /api/v1/chatkit
                  </code>
                </p>
              </div>

              {/* Status Info */}
              <div className="bg-background-surface rounded-lg p-4 border border-border-subtle">
                <p className="font-semibold text-text-primary mb-3">Backend Status:</p>
                <ul className="space-y-2 text-sm">
                  <li className="flex items-center gap-2">
                    <span className="text-green-500">✓</span>
                    <span className="text-text-secondary">ChatKit Server: Running</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <span className="text-green-500">✓</span>
                    <span className="text-text-secondary">Authentication: JWT Tokens</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <span className="text-green-500">✓</span>
                    <span className="text-text-secondary">Endpoint: /api/v1/chatkit</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <span className="text-blue-500">ℹ</span>
                    <span className="text-text-secondary">Frontend: Placeholder UI</span>
                  </li>
                </ul>
              </div>

              {/* Note */}
              <div className="bg-blue-500/10 border border-blue-500/20 rounded-lg p-4">
                <p className="text-sm text-text-secondary">
                  <strong className="text-text-primary">Note:</strong> The original chatbot at{' '}
                  <a href="/chatbot" className="text-accent-primary hover:underline">
                    /chatbot
                  </a>{' '}
                  is fully functional with all features working.
                </p>
              </div>
            </div>
          </div>

          {/* Input Area */}
          <div className="p-6 border-t border-border-subtle">
            <div className="max-w-3xl mx-auto">
              <div className="flex gap-3">
                <input
                  type="text"
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleSend()}
                  placeholder="Type a message... (placeholder)"
                  className="flex-1 px-4 py-3 bg-background-surface border border-border-subtle rounded-lg text-text-primary placeholder-text-secondary focus:outline-none focus:ring-2 focus:ring-accent-primary"
                />
                <button
                  onClick={handleSend}
                  disabled={!message.trim()}
                  className="px-6 py-3 bg-accent-primary text-white rounded-lg hover:bg-accent-primary/90 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  Send
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
