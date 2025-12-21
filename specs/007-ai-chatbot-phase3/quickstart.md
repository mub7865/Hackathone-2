# Quickstart: AI-Powered Todo Chatbot (Phase III)

**Feature**: 007-ai-chatbot-phase3
**Date**: 2025-12-18

---

## Prerequisites

Before starting Phase III implementation, ensure:

- [ ] Phase II is complete and working
- [ ] Frontend running at `http://localhost:3000`
- [ ] Backend running at `http://localhost:8000`
- [ ] Authentication (Better Auth) working
- [ ] Tasks CRUD operations working
- [ ] Neon database connected

---

## Environment Setup

### 1. Get Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Click "Create API Key"
3. Copy the key

### 2. Add Environment Variables

**Backend (.env)**
```bash
# Existing Phase II variables...
DATABASE_URL=postgresql://...
BETTER_AUTH_SECRET=...

# NEW for Phase III
GEMINI_API_KEY=your-gemini-api-key-here
```

**Frontend (.env.local)**
```bash
# Existing Phase II variables...
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### 3. Install New Dependencies

**Backend**
```bash
cd backend
uv add openai-agents httpx
```

**Frontend**
```bash
cd frontend
npm install lucide-react  # For icons (if not already installed)
```

---

## Quick Test Commands

### Test Backend Chat Endpoint
```bash
# Get JWT token first (login via frontend)
# Then test chat:
curl -X POST "http://localhost:8000/api/{user_id}/chat" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Add a task to test the chatbot"}'
```

### Test Conversation List
```bash
curl -X GET "http://localhost:8000/api/{user_id}/conversations" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## File Locations

### Backend (New Files)

```
backend/
├── app/
│   ├── models/
│   │   ├── conversation.py    # NEW: Conversation SQLModel
│   │   └── message.py         # NEW: Message SQLModel
│   ├── routers/
│   │   ├── chat.py            # NEW: POST /chat endpoint
│   │   └── conversations.py   # NEW: Conversations CRUD
│   └── services/
│       ├── agent.py           # NEW: Gemini Agent config
│       └── mcp_tools.py       # NEW: 5 MCP tools
├── alembic/
│   └── versions/
│       └── xxx_add_chat_tables.py  # NEW: Migration
```

### Frontend (New Files)

```
frontend/
├── app/
│   └── chatbot/
│       ├── page.tsx           # NEW: Chatbot page
│       └── layout.tsx         # NEW: (optional) Layout
├── components/
│   ├── chat/
│   │   ├── ChatSidebar.tsx    # NEW: Conversation list
│   │   ├── ChatArea.tsx       # NEW: Messages display
│   │   ├── ChatInput.tsx      # NEW: Message input
│   │   ├── ChatMessage.tsx    # NEW: Message bubble
│   │   └── WelcomeMessage.tsx # NEW: First-time welcome
│   └── ui/
│       └── ... (existing)
├── lib/
│   └── chat-api.ts            # NEW: Chat API client
```

---

## Implementation Order

Follow this order for smooth development:

```
1. Database Models & Migration
   └── Test: Run migration, check tables exist

2. Conversation APIs (CRUD)
   └── Test: curl commands for list/get/delete

3. MCP Tools (5 tools)
   └── Test: Python REPL, call each tool directly

4. Gemini Agent Setup
   └── Test: Agent test script with sample messages

5. Chat Endpoint
   └── Test: curl POST /chat with real messages

6. Frontend - Page Layout
   └── Test: Visit /chatbot, see sidebar + chat area

7. Frontend - Chat Components
   └── Test: Send messages, see responses

8. Integration Testing
   └── Test: Full end-to-end flow
```

---

## Common Issues & Solutions

### Issue: "GEMINI_API_KEY not set"
```bash
# Make sure .env file has:
GEMINI_API_KEY=your-key-here

# Restart the backend server
```

### Issue: "Agent returns empty response"
```python
# Check agent is configured with tools:
agent = Agent(
    name="Todo Assistant",
    tools=[add_task, list_tasks, complete_task, delete_task, update_task],
    ...
)
```

### Issue: "Conversation not found"
```python
# Make sure user_id matches JWT user
# Check conversation belongs to authenticated user
```

### Issue: "Mobile sidebar not working"
```tsx
// Ensure hamburger menu state is managed:
const [sidebarOpen, setSidebarOpen] = useState(false)
```

---

## Success Checklist

After implementation, verify:

- [ ] Can create new conversation via "New Chat"
- [ ] Can add tasks via chat ("Add a task to...")
- [ ] Can list tasks via chat ("Show my tasks")
- [ ] Can complete tasks via chat ("Mark task X done")
- [ ] Can delete tasks via chat ("Delete task X")
- [ ] Can update tasks via chat ("Change task X to...")
- [ ] Conversations appear in sidebar
- [ ] Can switch between conversations
- [ ] Can delete conversations
- [ ] Mobile hamburger menu works
- [ ] Error messages display properly
- [ ] Loading states show while waiting

---

## Next Steps

After Phase III is complete:

1. Demo the chatbot with natural language commands
2. Test edge cases (empty messages, invalid task IDs)
3. Proceed to Phase IV: Kubernetes Deployment
