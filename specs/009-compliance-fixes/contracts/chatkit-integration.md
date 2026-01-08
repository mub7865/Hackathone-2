# Contract: ChatKit Integration

**Feature**: 009-compliance-fixes
**Date**: 2026-01-07
**Type**: Frontend Chat Interface Contract

## Overview

This contract defines the integration of OpenAI ChatKit React library to replace custom chat components while maintaining compatibility with the existing backend API endpoints.

---

## ChatKit Configuration

### Installation

```bash
npm install @openai/chatkit-react
```

### Layout Configuration

**File**: `app/layout.tsx`

```typescript
import Script from 'next/script';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <Script
          src="https://cdn.platform.openai.com/deployments/chatkit/chatkit.js"
          strategy="beforeInteractive"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

---

## ChatKit Component Implementation

### Main Chat Component

**File**: `app/(authenticated)/chatbot/page.tsx`

```typescript
'use client';

import { ChatKit, useChatKit } from '@openai/chatkit-react';
import { useSession } from '@/lib/auth/client';
import { useState } from 'react';

export default function ChatbotPage() {
  const { data: session } = useSession();
  const [conversationId, setConversationId] = useState<number | null>(null);

  const { control } = useChatKit({
    api: {
      async getClientSecret(existingSecret?: string): Promise<string> {
        // Get Better Auth JWT token
        const authToken = session?.accessToken;

        if (!authToken) {
          throw new Error('Not authenticated');
        }

        // Call backend session endpoint
        const response = await fetch('/api/chatkit/session', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${authToken}`
          },
          body: JSON.stringify({
            user_id: session.user.id,
            conversation_id: conversationId,
            refresh: existingSecret ? true : false
          })
        });

        if (!response.ok) {
          throw new Error('Failed to get ChatKit session');
        }

        const data = await response.json();
        return data.client_secret;
      }
    },

    // ChatKit configuration
    config: {
      theme: 'light',
      placeholder: 'Ask me to manage your tasks...',
      welcomeMessage: 'Hi! I can help you manage your tasks. Try saying "Add a task to buy groceries" or "Show me my tasks".'
    }
  });

  return (
    <div className="h-screen flex flex-col">
      <header className="p-4 border-b">
        <h1 className="text-2xl font-bold">AI Task Assistant</h1>
      </header>

      <div className="flex-1 overflow-hidden">
        <ChatKit
          control={control}
          className="h-full"
          onConversationChange={(id) => setConversationId(id)}
        />
      </div>
    </div>
  );
}
```

---

## Backend Session Endpoint

### ChatKit Session Handler

**File**: `app/api/chatkit/session/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { OpenAI } from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

export async function POST(request: NextRequest) {
  try {
    // Extract JWT token from Authorization header
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const token = authHeader.substring(7);

    // Verify token and extract user_id
    // (This will use dual token validation from backend)
    const userId = await verifyToken(token);

    // Get request body
    const body = await request.json();
    const { conversation_id, refresh } = body;

    // Create ChatKit session
    const session = await openai.chatkit.sessions.create({
      user_id: userId,
      conversation_id: conversation_id || undefined,
      metadata: {
        app: 'calm-orbit-todo',
        environment: process.env.NODE_ENV
      }
    });

    return NextResponse.json({
      client_secret: session.client_secret,
      session_id: session.id,
      expires_at: session.expires_at
    });
  } catch (error) {
    console.error('ChatKit session creation failed:', error);
    return NextResponse.json(
      { error: 'Failed to create session' },
      { status: 500 }
    );
  }
}
```

---

## Integration with Existing Backend

### Maintaining Existing API Endpoints

ChatKit will call the existing backend endpoints through its session:

**Existing Endpoints (Preserved)**:
- `POST /api/v1/chat` - Send message to AI agent
- `GET /api/v1/conversations` - List user conversations
- `GET /api/v1/conversations/:id` - Get conversation details
- `DELETE /api/v1/conversations/:id` - Delete conversation

**ChatKit Session Configuration**:
```typescript
// ChatKit internally calls these endpoints via the session
const session = await openai.chatkit.sessions.create({
  user_id: userId,
  backend_url: process.env.BACKEND_URL || 'http://localhost:8000',
  endpoints: {
    chat: '/api/v1/chat',
    conversations: '/api/v1/conversations'
  }
});
```

---

## Component Replacement Mapping

### Before (Custom Components)

```typescript
// Old structure
<ChatArea>
  <ChatSidebar conversations={conversations} />
  <div className="chat-main">
    <ChatMessage messages={messages} />
    <ChatInput onSend={handleSend} />
  </div>
</ChatArea>
```

### After (ChatKit)

```typescript
// New structure - single component
<ChatKit
  control={control}
  className="h-full"
/>
```

**Replaced Components**:
- ❌ `components/chat/ChatArea.tsx` → ✅ ChatKit (built-in)
- ❌ `components/chat/ChatSidebar.tsx` → ✅ ChatKit (built-in)
- ❌ `components/chat/ChatMessage.tsx` → ✅ ChatKit (built-in)
- ❌ `components/chat/ChatInput.tsx` → ✅ ChatKit (built-in)
- ❌ `components/chat/WelcomeMessage.tsx` → ✅ ChatKit config

---

## Feature Flag Integration

### Conditional Rendering

**File**: `app/(authenticated)/chatbot/page.tsx`

```typescript
'use client';

import { featureFlags } from '@/lib/features/flags';
import { LegacyChatPage } from '@/components/chat/LegacyChatPage';
import { ChatKitPage } from '@/components/chat/ChatKitPage';

export default function ChatbotPage() {
  // Check feature flag and rollback flag
  const useNewChat =
    process.env.NEXT_PUBLIC_ROLLBACK_CHAT !== 'true' &&
    featureFlags.useNewChat;

  if (useNewChat) {
    return <ChatKitPage />;
  }

  return <LegacyChatPage />;
}
```

---

## Conversation Management

### New Chat Creation

```typescript
const { control, createConversation } = useChatKit({
  api: { getClientSecret }
});

// Create new conversation
const handleNewChat = async () => {
  const newConversation = await createConversation();
  setConversationId(newConversation.id);
};
```

### Conversation History

```typescript
const { control, conversations } = useChatKit({
  api: { getClientSecret }
});

// List conversations
useEffect(() => {
  const loadConversations = async () => {
    const convos = await conversations.list();
    setConversationList(convos);
  };
  loadConversations();
}, []);
```

---

## Styling and Theming

### ChatKit Theme Configuration

```typescript
const { control } = useChatKit({
  api: { getClientSecret },
  config: {
    theme: {
      primaryColor: '#3b82f6',
      backgroundColor: '#ffffff',
      textColor: '#1f2937',
      borderRadius: '8px',
      fontFamily: 'Inter, sans-serif'
    },
    layout: {
      sidebarWidth: '280px',
      messageSpacing: '16px'
    }
  }
});
```

### Custom CSS Overrides

```css
/* app/globals.css */
.chatkit-container {
  --chatkit-primary: #3b82f6;
  --chatkit-background: #ffffff;
  --chatkit-text: #1f2937;
  --chatkit-border: #e5e7eb;
}

.chatkit-message-user {
  background-color: #3b82f6;
  color: white;
}

.chatkit-message-assistant {
  background-color: #f3f4f6;
  color: #1f2937;
}
```

---

## Error Handling

### Session Creation Errors

```typescript
const { control, error } = useChatKit({
  api: {
    async getClientSecret() {
      try {
        // ... session creation logic
      } catch (error) {
        console.error('Session creation failed:', error);
        throw new Error('Unable to start chat session. Please try again.');
      }
    }
  }
});

// Display error to user
{error && (
  <div className="error-banner">
    <p>{error.message}</p>
    <button onClick={retry}>Retry</button>
  </div>
)}
```

### Network Errors

```typescript
const { control, isLoading, error } = useChatKit({
  api: { getClientSecret },
  config: {
    retryAttempts: 3,
    retryDelay: 1000,
    timeout: 30000
  }
});
```

---

## Testing Contract

### Unit Tests

```typescript
describe('ChatKit Integration', () => {
  it('should create session with Better Auth token', async () => {
    const mockToken = 'mock-jwt-token';
    const mockSession = { client_secret: 'secret', id: 'session-id' };

    fetchMock.mockResponseOnce(JSON.stringify(mockSession));

    const { result } = renderHook(() => useChatKit({
      api: {
        async getClientSecret() {
          const response = await fetch('/api/chatkit/session', {
            headers: { 'Authorization': `Bearer ${mockToken}` }
          });
          const data = await response.json();
          return data.client_secret;
        }
      }
    }));

    await waitFor(() => {
      expect(result.current.control).toBeDefined();
    });
  });
});
```

### Integration Tests

```typescript
describe('ChatKit Backend Integration', () => {
  it('should send messages to existing /api/v1/chat endpoint', async () => {
    const { control } = useChatKit({ api: { getClientSecret } });

    await control.sendMessage('Add a task to buy groceries');

    // Verify backend endpoint was called
    expect(fetchMock).toHaveBeenCalledWith(
      expect.stringContaining('/api/v1/chat'),
      expect.objectContaining({
        method: 'POST',
        body: expect.stringContaining('Add a task to buy groceries')
      })
    );
  });
});
```

---

## Migration Strategy

### Phase 1: Parallel Implementation

1. Keep existing custom chat components
2. Implement ChatKit behind feature flag
3. Test ChatKit with small user group (10%)

### Phase 2: Gradual Rollout

1. Enable ChatKit for 50% of users
2. Monitor error rates and user feedback
3. Compare performance metrics

### Phase 3: Full Migration

1. Enable ChatKit for 100% of users
2. Keep custom components for 7 days (rollback capability)
3. Remove custom components after successful migration

---

## Performance Considerations

### Lazy Loading

```typescript
import dynamic from 'next/dynamic';

const ChatKitPage = dynamic(() => import('@/components/chat/ChatKitPage'), {
  loading: () => <ChatLoadingSkeleton />,
  ssr: false
});
```

### Code Splitting

```typescript
// Separate bundle for ChatKit
const ChatKit = dynamic(() =>
  import('@openai/chatkit-react').then(mod => mod.ChatKit),
  { ssr: false }
);
```

---

## Security Considerations

1. **Token Transmission**: JWT tokens sent over HTTPS only
2. **Session Expiration**: ChatKit sessions expire after 1 hour
3. **User Isolation**: Backend enforces user_id from JWT token
4. **CORS Configuration**: Restrict ChatKit CDN origins
5. **Content Security Policy**: Allow ChatKit script sources

---

## Rollback Strategy

If ChatKit integration fails:

1. Set `ROLLBACK_CHAT=true` in environment
2. Application falls back to custom chat components
3. Existing conversations and messages preserved
4. No data loss or user impact

---

**Contract Status**: ✅ Complete
**Implementation Files**: 3 files (page.tsx, session/route.ts, flags integration)
**Dependencies**: @openai/chatkit-react, openai
**Backend Changes**: New `/api/chatkit/session` endpoint only
