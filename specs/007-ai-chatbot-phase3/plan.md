# Implementation Plan: AI-Powered Todo Chatbot (Phase III)

**Branch**: `007-ai-chatbot-phase3` | **Date**: 2025-12-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-ai-chatbot-phase3/spec.md`

---

## Summary

Transform the Phase II Todo web application into an AI-powered chatbot that enables natural language task management. Users interact with an AI assistant through a dedicated `/chatbot` page with conversation sidebar. The assistant uses MCP tools to perform task operations (add, list, complete, delete, update).

**Key Technical Approach:**
- OpenAI GPT (default) or Gemini via OpenAI Agents SDK
- **@mcp.tool() decorator from Official MCP SDK** (NOT @function_tool)
- **MCP Server mounted at `/mcp` HTTP endpoint in FastAPI**
- **Agent connects via `mcp_servers=[MCPServerStreamableHttp]`** (NOT `tools=[]`)
- Custom React components for chat UI (not ChatKit hosted)
- Stateless server with database-backed conversation history

**Important MCP Architecture (2025-12-20):**
- Hackathon requires: "Build MCP server with Official MCP SDK"
- Use `mcp[cli]` package with `FastMCP` class
- Tools defined with `@mcp.tool()` decorator
- **MCP Server mounted via `app.mount("/mcp", mcp.streamable_http_app())`**
- **Agent connects via `mcp_servers=[MCPServerStreamableHttp(url="/mcp")]`**
- Tools receive `user_id` as parameter (not from context)
- Each tool creates its own database session

---

## Technical Context

**Language/Version**: Python 3.13+ (Backend), TypeScript (Frontend)
**Primary Dependencies**:
- Backend: FastAPI 0.115+, SQLModel 0.0.22+, openai-agents, **mcp[cli]>=1.2.0**, httpx
- Frontend: Next.js 16+ (App Router), Tailwind CSS, lucide-react
**Storage**: Neon PostgreSQL (existing) + new Conversation/Message tables
**Testing**: Manual testing after each task (curl, browser, REPL)
**Target Platform**: Web (Desktop + Mobile responsive)
**Project Type**: Web (frontend + backend monorepo)
**Performance Goals**: Chat responses within 5 seconds, 50 concurrent users
**Constraints**: Gemini API rate limits, 100 message context limit
**Scale/Scope**: 50-100 users, ~50k messages max

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| Strict SDD | ✅ PASS | Spec created first, clarifications documented |
| AI-Native Architecture | ✅ PASS | MCP tools, Gemini agent, natural language interface |
| Progressive Evolution | ✅ PASS | Extends Phase II, no rewrites required |
| Documentation First | ✅ PASS | research.md, data-model.md, contracts/ created |
| Tech Stack Adherence | ✅ PASS | Using specified Phase III stack |
| No Vibe Coding | ✅ PASS | All code from specs via AI |

**Gate Result: PASS** - Proceed with implementation.

---

## Project Structure

### Documentation (this feature)

```text
specs/007-ai-chatbot-phase3/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Technical decisions
├── data-model.md        # Entity definitions
├── quickstart.md        # Setup guide
├── contracts/
│   ├── chat-api.md      # POST /chat endpoint
│   ├── conversations-api.md  # Conversation CRUD
│   └── mcp-tools.md     # 5 MCP tool definitions
├── checklists/
│   └── requirements.md  # Quality checklist
└── tasks.md             # Implementation tasks (created by /sp.tasks)
```

### Source Code (repository root)

```text
backend/
├── app/
│   ├── models/
│   │   ├── task.py           # Existing
│   │   ├── conversation.py   # NEW
│   │   └── message.py        # NEW
│   ├── routers/
│   │   ├── tasks.py          # Existing
│   │   ├── chat.py           # NEW
│   │   └── conversations.py  # NEW
│   ├── services/
│   │   ├── agent.py          # NEW: AI agent config
│   │   └── mcp_server.py     # NEW: MCP Server with 5 @mcp.tool() tools
│   └── core/
│       └── deps.py           # Existing (auth dependencies)
├── alembic/
│   └── versions/
│       └── xxx_add_phase3_tables.py  # NEW
└── tests/
    └── test_chat.py          # NEW

frontend/
├── app/
│   ├── chatbot/
│   │   └── page.tsx          # NEW: Chatbot page
│   ├── dashboard/            # Existing
│   └── tasks/                # Existing
├── components/
│   ├── chat/
│   │   ├── ChatSidebar.tsx   # NEW
│   │   ├── ChatArea.tsx      # NEW
│   │   ├── ChatInput.tsx     # NEW
│   │   ├── ChatMessage.tsx   # NEW
│   │   └── WelcomeMessage.tsx # NEW
│   └── ui/                   # Existing
├── lib/
│   ├── api.ts                # Existing
│   └── chat-api.ts           # NEW
└── styles/                   # Existing
```

**Structure Decision**: Extend existing frontend/ and backend/ folders as decided in clarification session. No separate phase3 folder.

---

## Implementation Phases

### IMPORTANT: Run & Test After Each Task

After completing each task, you MUST:
1. **Run** the code/server to verify no errors
2. **Test** the specific functionality manually
3. **Verify** it works correctly before moving to next task
4. **Document** any issues found and fix them

This ensures incremental progress and early bug detection.

---

### Phase 1: Database Layer

#### Task 1.1: Create Conversation Model
**File**: `backend/app/models/conversation.py`
**Action**: Create SQLModel for Conversation entity
**Test**: Import in Python REPL, verify no errors

#### Task 1.2: Create Message Model
**File**: `backend/app/models/message.py`
**Action**: Create SQLModel for Message entity with FK to Conversation
**Test**: Import in Python REPL, verify no errors

#### Task 1.3: Create Alembic Migration
**File**: `backend/alembic/versions/xxx_add_phase3_tables.py`
**Action**: Generate and run migration for new tables
**Test**:
```bash
alembic upgrade head
# Verify tables exist in Neon dashboard
```

---

### Phase 2: Conversation APIs

#### Task 2.1: Create Conversations Router
**File**: `backend/app/routers/conversations.py`
**Action**: Implement GET /conversations, GET /conversations/{id}, DELETE /conversations/{id}
**Test**:
```bash
# Start server
uvicorn app.main:app --reload

# Test with curl (need valid JWT)
curl -X GET "http://localhost:8000/api/{user_id}/conversations" \
  -H "Authorization: Bearer {token}"
```

#### Task 2.2: Register Router in Main App
**File**: `backend/app/main.py`
**Action**: Add conversations router
**Test**: Swagger UI shows new endpoints at /docs

---

### Phase 3: MCP Server & Tools

#### Task 3.1: Install MCP SDK
**Action**: Add mcp[cli] package to backend dependencies
**Command**: `cd backend && uv add "mcp[cli]"`
**Test**: `python -c "from mcp.server.fastmcp import FastMCP; print('MCP SDK installed')"`

#### Task 3.2: Create MCP Server with Tools
**File**: `backend/app/services/mcp_server.py`
**Action**: Create FastMCP server with 5 tools using @mcp.tool() decorator
- add_task
- list_tasks
- complete_task
- delete_task
- update_task
**Test**:
```python
# Python REPL
from app.services.mcp_server import mcp
print(mcp.get_tools())  # Should list 5 tools
```

---

### Phase 4: AI Agent

#### Task 4.1: Create Agent Configuration
**File**: `backend/app/services/agent.py`
**Action**: Configure agent with MCP tools from mcp_server
**Test**:
```python
# Test script
from app.services.agent import get_agent
from agents import Runner
agent = get_agent()
result = await Runner.run(agent, "Show my tasks")
print(result.final_output)
```

---

### Phase 5: Chat Endpoint

#### Task 5.1: Create Chat Router
**File**: `backend/app/routers/chat.py`
**Action**: Implement POST /api/{user_id}/chat endpoint
- Validate JWT
- Get/create conversation
- Fetch history
- Store user message
- Run agent
- Store assistant response
- Return response
**Test**:
```bash
curl -X POST "http://localhost:8000/api/{user_id}/chat" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"message": "Add a task to test"}'
```

#### Task 5.2: Register Chat Router
**File**: `backend/app/main.py`
**Action**: Add chat router
**Test**: Swagger UI shows /chat endpoint

---

### Phase 6: Frontend - Chat API Client

#### Task 6.1: Create Chat API Client
**File**: `frontend/lib/chat-api.ts`
**Action**: Create functions for chat and conversation APIs
**Test**: Import in component, check TypeScript types

---

### Phase 7: Frontend - Chat Components

#### Task 7.1: Create ChatMessage Component
**File**: `frontend/components/chat/ChatMessage.tsx`
**Action**: Message bubble with user/assistant styling
**Test**: Render in Storybook or test page

#### Task 7.2: Create ChatInput Component
**File**: `frontend/components/chat/ChatInput.tsx`
**Action**: Text input with send button, loading state
**Test**: Render in test page, verify input works

#### Task 7.3: Create WelcomeMessage Component
**File**: `frontend/components/chat/WelcomeMessage.tsx`
**Action**: Welcome screen with example commands
**Test**: Render in test page

#### Task 7.4: Create ChatArea Component
**File**: `frontend/components/chat/ChatArea.tsx`
**Action**: Messages list + input + welcome state
**Test**: Render with mock messages

#### Task 7.5: Create ChatSidebar Component
**File**: `frontend/components/chat/ChatSidebar.tsx`
**Action**: Conversation list with "New Chat" button
- Desktop: Always visible
- Mobile: Hamburger menu + slide-out drawer
**Test**: Render, test mobile/desktop layouts

---

### Phase 8: Frontend - Chatbot Page

#### Task 8.1: Create Chatbot Page
**File**: `frontend/app/chatbot/page.tsx`
**Action**: Combine sidebar + chat area with state management
**Test**:
```bash
# Start frontend
npm run dev
# Visit http://localhost:3000/chatbot
```

#### Task 8.2: Add Navigation Link
**File**: `frontend/components/Header.tsx` (or similar)
**Action**: Add "Chatbot" link to navigation
**Test**: Click link, navigates to /chatbot

---

### Phase 9: Integration Testing

#### Task 9.1: End-to-End Testing
**Action**: Test complete flow:
1. Login
2. Go to /chatbot
3. Send "Add a task to buy groceries"
4. Verify task created
5. Send "Show my tasks"
6. Verify task listed
7. Send "Mark task X done"
8. Verify task completed
9. Click "New Chat"
10. Verify new conversation
11. Switch between conversations
12. Delete a conversation
13. Test on mobile (hamburger menu)

---

## Dependency Graph

```
                    ┌─────────────────┐
                    │ Phase 1: DB     │
                    │ (Models +       │
                    │  Migration)     │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │ Phase 2:    │  │ Phase 3:    │  │ Phase 4:    │
    │ Conv APIs   │  │ MCP Tools   │  │ Agent Setup │
    └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
           │                │                │
           └────────────────┼────────────────┘
                            │
                            ▼
                  ┌─────────────────┐
                  │ Phase 5: Chat   │
                  │ Endpoint        │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ Phase 6: API    │
                  │ Client          │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ Phase 7: Chat   │
                  │ Components      │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ Phase 8: Page   │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ Phase 9: E2E    │
                  │ Testing         │
                  └─────────────────┘
```

---

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Gemini API rate limits | Medium | High | Implement retry logic with backoff |
| Long conversations overflow | Low | Medium | Limit history to 100 messages |
| Mobile UX issues | Medium | Medium | Test on real devices early |
| JWT token expiry during chat | Low | Low | Handle 401 gracefully, prompt re-login |
| Tool execution failures | Medium | Medium | Return user-friendly error messages |

---

## Environment Variables Required

**Backend (.env)**
```bash
DATABASE_URL=postgresql://...
BETTER_AUTH_SECRET=...
GEMINI_API_KEY=...  # NEW
```

**Frontend (.env.local)**
```bash
NEXT_PUBLIC_API_URL=http://localhost:8000
```

---

## Success Metrics

| Metric | Target | How to Verify |
|--------|--------|---------------|
| All 5 task operations via chat | 100% | Manual testing |
| Response time | <5 seconds | Stopwatch during testing |
| Mobile sidebar works | 100% | Test on mobile browser |
| Conversation persistence | 100% | Refresh page, verify history |
| Error handling | Graceful | Test invalid inputs |

---

## Next Steps

After plan approval:
1. Run `/sp.tasks` to generate detailed task list
2. Implement each task following the phases above
3. **Run and test after each task completion**
4. Document any issues in PHRs
5. Submit Phase III when complete

---

## Complexity Tracking

No constitution violations requiring justification. Architecture is straightforward:
- Single database with 2 new tables
- 5 simple function tools
- Standard chat UI pattern
- Extends existing Phase II codebase
