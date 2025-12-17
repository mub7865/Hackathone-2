# ChatKit Integration Example

This example demonstrates how to integrate OpenAI ChatKit with a Next.js
Todo application that has a custom FastAPI backend.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Next.js Frontend                            │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────────────────────────┐ │
│  │  Tasks Page     │    │  Chat Page / Toggle                 │ │
│  │  (Phase II UI)  │    │  (Phase III ChatKit)                │ │
│  └────────┬────────┘    └─────────────┬───────────────────────┘ │
│           │                           │                         │
│           │  Task CRUD APIs           │  Chat Session API       │
│           ▼                           ▼                         │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                     FastAPI Backend                             │
│                                                                 │
│  Phase II:                     Phase III:                       │
│  ┌─────────────────┐           ┌─────────────────────────────┐  │
│  │ GET /tasks      │           │ POST /api/{user_id}/chat    │  │
│  │ POST /tasks     │           │         │                   │  │
│  │ PUT /tasks/{id} │           │         ▼                   │  │
│  │ DELETE /tasks   │           │  ┌─────────────────────┐    │  │
│  └────────┬────────┘           │  │  OpenAI Agent       │    │  │
│           │                    │  │  + MCP Tools        │    │  │
│           │                    │  └─────────────────────┘    │  │
│           │                    └─────────────────────────────┘  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Neon PostgreSQL                      │    │
│  │  - tasks table (Phase II)                               │    │
│  │  - conversations table (Phase III)                      │    │
│  │  - messages table (Phase III)                           │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Step-by-Step Integration

### Step 1: Install Dependencies

**Frontend (Next.js):**
```bash
cd frontend
npm install @openai/chatkit-react
```

**Backend (FastAPI):**
```bash
cd backend
pip install openai-agents "mcp[cli]"
```

### Step 2: Add ChatKit Script to Layout

```tsx
// frontend/app/layout.tsx
import Script from 'next/script';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        {/* ChatKit script - load early for best performance */}
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

### Step 3: Create ChatWidget Component

```tsx
// frontend/components/ChatWidget.tsx
'use client';

import { useState } from 'react';
import { ChatKit, useChatKit } from '@openai/chatkit-react';
import { useAuth } from '@/lib/auth-client';

interface ChatWidgetProps {
  className?: string;
}

export function ChatWidget({ className = '' }: ChatWidgetProps) {
  const { session, getToken } = useAuth();
  const [error, setError] = useState<string | null>(null);

  const { control } = useChatKit({
    api: {
      async getClientSecret() {
        try {
          const token = await getToken();

          const response = await fetch(
            `${process.env.NEXT_PUBLIC_API_URL}/api/${session?.user?.id}/chat/session`,
            {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`,
              },
            }
          );

          if (!response.ok) {
            throw new Error('Failed to create chat session');
          }

          const data = await response.json();
          setError(null);
          return data.client_secret;
        } catch (err) {
          setError(err instanceof Error ? err.message : 'Connection failed');
          throw err;
        }
      },
    },
  });

  if (error) {
    return (
      <div className={`p-4 bg-red-50 rounded-lg ${className}`}>
        <p className="text-red-600">{error}</p>
        <button
          onClick={() => setError(null)}
          className="mt-2 text-sm text-red-500 underline"
        >
          Try again
        </button>
      </div>
    );
  }

  if (!session) {
    return (
      <div className={`p-4 bg-gray-50 rounded-lg ${className}`}>
        <p className="text-gray-600">Please log in to use the chat assistant.</p>
      </div>
    );
  }

  return (
    <ChatKit
      control={control}
      className={`rounded-lg shadow-lg ${className}`}
    />
  );
}
```

### Step 4: Add Chat Toggle Button to Dashboard

```tsx
// frontend/components/ChatToggle.tsx
'use client';

import { useState } from 'react';
import { ChatWidget } from './ChatWidget';
import { MessageCircle, X } from 'lucide-react';

export function ChatToggle() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      {/* Floating button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="
          fixed bottom-6 right-6 z-50
          p-4 rounded-full shadow-lg
          bg-blue-600 text-white
          hover:bg-blue-700 transition-all
        "
        aria-label={isOpen ? 'Close chat' : 'Open chat assistant'}
      >
        {isOpen ? <X size={24} /> : <MessageCircle size={24} />}
      </button>

      {/* Chat panel */}
      {isOpen && (
        <div className="fixed bottom-24 right-6 z-40 w-[380px] h-[500px]">
          <div className="h-full flex flex-col bg-white rounded-lg shadow-xl overflow-hidden">
            {/* Header */}
            <div className="flex items-center justify-between px-4 py-3 bg-blue-600 text-white">
              <span className="font-medium">Todo Assistant</span>
              <button
                onClick={() => setIsOpen(false)}
                className="p-1 hover:bg-blue-700 rounded"
              >
                <X size={18} />
              </button>
            </div>

            {/* Chat */}
            <ChatWidget className="flex-1" />
          </div>
        </div>
      )}
    </>
  );
}
```

### Step 5: Update Dashboard Layout

```tsx
// frontend/app/dashboard/layout.tsx
import { ChatToggle } from '@/components/ChatToggle';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen">
      {children}

      {/* Add chat toggle to all dashboard pages */}
      <ChatToggle />
    </div>
  );
}
```

### Step 6: Create Backend Chat Endpoint

```python
# backend/app/routers/chat.py
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from sqlmodel import Session, select
from agents import Runner

from app.db import get_session
from app.chat.agent import agent
from app.models.chat import Conversation, Message
from app.auth.dependencies import get_current_user

router = APIRouter(prefix="/api/{user_id}", tags=["chat"])


class ChatRequest(BaseModel):
    message: str
    conversation_id: Optional[int] = None


class ChatResponse(BaseModel):
    conversation_id: int
    response: str


@router.post("/chat", response_model=ChatResponse)
async def chat(
    user_id: str,
    request: ChatRequest,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_user),
):
    """Process a chat message through the AI agent."""

    # Verify authorization
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    # Get or create conversation
    if request.conversation_id:
        conversation = session.get(Conversation, request.conversation_id)
        if not conversation or conversation.user_id != user_id:
            raise HTTPException(status_code=404, detail="Conversation not found")
    else:
        conversation = Conversation(user_id=user_id)
        session.add(conversation)
        session.commit()
        session.refresh(conversation)

    # Store user message
    user_message = Message(
        conversation_id=conversation.id,
        user_id=user_id,
        role="user",
        content=request.message,
    )
    session.add(user_message)

    # Run AI agent
    result = await Runner.run(
        agent,
        input=request.message,
        context={"user_id": user_id},
    )

    # Store assistant response
    assistant_message = Message(
        conversation_id=conversation.id,
        user_id=user_id,
        role="assistant",
        content=result.final_output,
    )
    session.add(assistant_message)
    session.commit()

    return ChatResponse(
        conversation_id=conversation.id,
        response=result.final_output,
    )
```

### Step 7: Create MCP Tools

```python
# backend/app/chat/tools.py
from typing import List, Optional
from agents import function_tool
from sqlmodel import Session, select
from app.db import engine
from app.models.task import Task


@function_tool
async def add_task(user_id: str, title: str, description: str = "") -> dict:
    """Add a new task for the user.

    Args:
        user_id: The user's unique identifier.
        title: The title of the task.
        description: Optional description.
    """
    with Session(engine) as session:
        task = Task(user_id=user_id, title=title, description=description)
        session.add(task)
        session.commit()
        session.refresh(task)
        return {"task_id": task.id, "status": "created", "title": task.title}


@function_tool
async def list_tasks(user_id: str, status: str = "all") -> List[dict]:
    """List tasks for the user.

    Args:
        user_id: The user's unique identifier.
        status: Filter - "all", "pending", or "completed".
    """
    with Session(engine) as session:
        query = select(Task).where(Task.user_id == user_id)
        if status == "pending":
            query = query.where(Task.completed == False)
        elif status == "completed":
            query = query.where(Task.completed == True)
        tasks = session.exec(query).all()
        return [
            {"id": t.id, "title": t.title, "completed": t.completed}
            for t in tasks
        ]


@function_tool
async def complete_task(user_id: str, task_id: int) -> dict:
    """Mark a task as complete.

    Args:
        user_id: The user's unique identifier.
        task_id: The ID of the task to complete.
    """
    with Session(engine) as session:
        task = session.get(Task, task_id)
        if not task or task.user_id != user_id:
            return {"status": "error", "error": "Task not found"}
        task.completed = True
        session.add(task)
        session.commit()
        return {"task_id": task.id, "status": "completed", "title": task.title}


@function_tool
async def delete_task(user_id: str, task_id: int) -> dict:
    """Delete a task.

    Args:
        user_id: The user's unique identifier.
        task_id: The ID of the task to delete.
    """
    with Session(engine) as session:
        task = session.get(Task, task_id)
        if not task or task.user_id != user_id:
            return {"status": "error", "error": "Task not found"}
        title = task.title
        session.delete(task)
        session.commit()
        return {"task_id": task_id, "status": "deleted", "title": title}
```

### Step 8: Configure Agent

```python
# backend/app/chat/agent.py
from agents import Agent
from app.chat.tools import add_task, list_tasks, complete_task, delete_task

agent = Agent(
    name="Todo Assistant",
    instructions="""You are a helpful todo assistant.

When users want to:
- Add tasks: Use add_task tool
- See tasks: Use list_tasks tool
- Complete tasks: Use complete_task tool
- Delete tasks: Use delete_task tool

Always confirm actions with friendly messages.
Format task lists clearly with IDs.
If something fails, explain what happened.""",
    tools=[add_task, list_tasks, complete_task, delete_task],
)
```

## GOOD vs BAD Patterns

### GOOD: Proper Error Handling

```tsx
// Good: Handle all error cases gracefully
const { control } = useChatKit({
  api: {
    async getClientSecret() {
      try {
        const response = await fetch('/api/chat/session', { method: 'POST' });
        if (!response.ok) {
          const error = await response.json();
          throw new Error(error.detail || 'Session creation failed');
        }
        return (await response.json()).client_secret;
      } catch (err) {
        setError(err.message);
        throw err;
      }
    },
  },
});
```

### BAD: Ignoring Errors

```tsx
// Bad: No error handling
const { control } = useChatKit({
  api: {
    async getClientSecret() {
      const res = await fetch('/api/chat/session');
      return res.json().client_secret; // Crashes on error!
    },
  },
});
```

### GOOD: Authentication Check

```tsx
// Good: Check auth before rendering
export function ChatWidget() {
  const { session } = useAuth();

  if (!session) {
    return <LoginPrompt />;
  }

  return <ChatKit control={control} />;
}
```

### BAD: No Auth Check

```tsx
// Bad: Assumes user is always logged in
export function ChatWidget() {
  // No auth check - will fail for unauthenticated users
  return <ChatKit control={control} />;
}
```

### GOOD: Responsive Design

```tsx
// Good: Adapts to screen size
<ChatWidget className="
  h-[300px] w-full
  sm:h-[400px]
  md:h-[500px]
  lg:h-[600px]
" />
```

### BAD: Fixed Dimensions

```tsx
// Bad: Breaks on mobile
<ChatWidget className="h-[800px] w-[600px]" />
```

## Example User Flow

```
User clicks chat button on dashboard
    │
    ▼
ChatToggle opens → ChatWidget renders
    │
    ▼
useChatKit calls getClientSecret()
    │
    ▼
Frontend fetches token from FastAPI backend
    │
    ▼
ChatKit connects and shows chat interface
    │
    ▼
User types: "Add a task to call mom"
    │
    ▼
Message sent to POST /api/{user_id}/chat
    │
    ▼
OpenAI Agent processes message
    │
    ▼
Agent calls add_task(title="Call mom")
    │
    ▼
Task saved to database
    │
    ▼
Agent responds: "Done! I've added 'Call mom' to your list (Task #5)."
    │
    ▼
Response displayed in ChatKit UI
```

## Testing the Integration

```bash
# 1. Start backend
cd backend
uvicorn app.main:app --reload

# 2. Start frontend
cd frontend
npm run dev

# 3. Open browser
# Navigate to http://localhost:3000/dashboard
# Click the chat button
# Try: "Show my tasks"
# Try: "Add a task to test the chatbot"
```
