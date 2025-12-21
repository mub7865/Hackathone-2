# Implementation Tasks: AI-Powered Todo Chatbot (Phase III)

**Feature**: 007-ai-chatbot-phase3
**Branch**: `007-ai-chatbot-phase3`
**Created**: 2025-12-18
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

---

## Task Summary

| Phase | Description | Tasks | Priority |
|-------|-------------|-------|----------|
| 1 | Setup & Environment | 2 | Required |
| 2 | Foundational (Database) | 3 | Required |
| 3 | US1+US2: Core Chat (Add & View Tasks) | 8 | P1 |
| 4 | US3+US4+US5: Task Operations | 3 | P2 |
| 5 | US6: New Conversation | 2 | P2 |
| 6 | US7: Conversation History | 3 | P3 |
| 7 | US8: First-Time Experience | 2 | P3 |
| 8 | Polish & Integration | 2 | Required |
| **Total** | | **25** | |

---

## IMPORTANT: Run & Test After Each Task

After completing each task, you MUST:
1. **Run** the code/server to verify no errors
2. **Test** the specific functionality manually
3. **Verify** it works correctly before moving to next task
4. **Document** any issues found and fix them

---

## Phase 1: Setup & Environment

**Goal**: Prepare development environment for Phase III implementation.

- [x] T001 Add GEMINI_API_KEY to backend/.env file (get from Google AI Studio)
- [x] T002 Install new backend dependencies: `cd backend && uv add openai-agents httpx "mcp[cli]"`

**Test Phase 1**:
```bash
# Verify environment
cd backend
python -c "import os; print('OPENAI_API_KEY:', 'SET' if os.getenv('OPENAI_API_KEY') else 'MISSING')"
python -c "from agents import Agent; print('openai-agents installed')"
python -c "from mcp.server.fastmcp import FastMCP; print('MCP SDK installed')"
```

---

## Phase 2: Foundational (Database Layer)

**Goal**: Create database models and migration for conversation persistence.

- [x] T003 Create Conversation SQLModel in `backend/app/models/conversation.py`
- [x] T004 Create Message SQLModel with FK cascade in `backend/app/models/message.py`
- [x] T005 Generate and run Alembic migration for conversations and messages tables

**Test Phase 2**:
```bash
# Test models import
cd backend
python -c "from app.models.conversation import Conversation; print('Conversation model OK')"
python -c "from app.models.message import Message; print('Message model OK')"

# Run migration
alembic upgrade head

# Verify tables in Neon dashboard or:
python -c "from sqlmodel import select; print('Tables created')"
```

---

## Phase 3: User Stories 1 & 2 - Core Chat (Add & View Tasks)

**Goal**: Enable users to add and view tasks through natural language chat.

**User Story 1**: Chat with AI to Add Tasks (P1)
**User Story 2**: Chat with AI to View Tasks (P1)

**Independent Test**: Send "Add a task to buy milk" and "Show my tasks" - verify both work.

### Backend Tasks

- [x] T006 [P] [US1] Create MCP Server with `add_task` tool in `backend/app/services/mcp_server.py` (using @mcp.tool() from Official MCP SDK)
- [x] T007 [P] [US2] Add `list_tasks` MCP tool to MCP Server in `backend/app/services/mcp_server.py`
- [x] T008 [US1] Create AI agent with MCP Server connection in `backend/app/services/agent.py` (using `mcp_servers=[MCPServerStreamableHttp]` NOT `tools=[]`)
- [x] T009 [US1] Create conversations router (GET list, GET single, DELETE) in `backend/app/routers/conversations.py`
- [x] T010 [US1] Create chat router (POST /chat) in `backend/app/routers/chat.py`
- [x] T011 [US1] Mount MCP Server and register routers in `backend/app/main.py` (add `app.mount("/mcp", mcp.streamable_http_app())`)

### Frontend Tasks

- [x] T012 [P] [US1] Create chat API client functions in `frontend/lib/chat-api.ts`
- [x] T013 [US1] Create basic ChatMessage component in `frontend/components/chat/ChatMessage.tsx`
- [x] T014 [US1] Create ChatInput component in `frontend/components/chat/ChatInput.tsx`
- [x] T015 [US1] Create ChatArea component in `frontend/components/chat/ChatArea.tsx`
- [x] T016 [US1] Create basic chatbot page in `frontend/app/chatbot/page.tsx`

**Test Phase 3**:
```bash
# Backend test
curl -X POST "http://localhost:8000/api/{user_id}/chat" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"message": "Add a task to buy groceries"}'

# Expect: Task created, confirmation response

curl -X POST "http://localhost:8000/api/{user_id}/chat" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"message": "Show my tasks", "conversation_id": 1}'

# Expect: List of tasks including "Buy groceries"

# Frontend test
# Visit http://localhost:3000/chatbot
# Type "Add a task to test" → verify response
# Type "Show my tasks" → verify list appears
```

---

## Phase 4: User Stories 3, 4 & 5 - Task Operations

**Goal**: Enable complete, delete, and update task operations via chat.

**User Story 3**: Chat with AI to Complete Tasks (P2)
**User Story 4**: Chat with AI to Delete Tasks (P2)
**User Story 5**: Chat with AI to Update Tasks (P2)

**Independent Test**: Mark a task done, delete a task, update a task title.

- [x] T017 [P] [US3] Add `complete_task` MCP tool (receives user_id as param, creates own DB session)
- [x] T018 [P] [US4] Add `delete_task` MCP tool (receives user_id as param, creates own DB session)
- [x] T019 [P] [US5] Add `update_task` MCP tool (receives user_id as param, creates own DB session)

**Test Phase 4**:
```bash
# Complete task
curl -X POST "http://localhost:8000/api/{user_id}/chat" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"message": "Mark task 1 as done", "conversation_id": 1}'

# Delete task
curl -X POST "http://localhost:8000/api/{user_id}/chat" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"message": "Delete task 2", "conversation_id": 1}'

# Update task
curl -X POST "http://localhost:8000/api/{user_id}/chat" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"message": "Change task 3 to Buy fruits", "conversation_id": 1}'
```

---

## Phase 5: User Story 6 - New Conversation

**Goal**: Allow users to start fresh conversations with "New Chat" button.

**User Story 6**: Start New Conversation (P2)

**Independent Test**: Click "New Chat", send message, verify new conversation created.

- [x] T020 [US6] Create ChatSidebar component with "New Chat" button in `frontend/components/chat/ChatSidebar.tsx`
- [x] T021 [US6] Update chatbot page to include sidebar and conversation switching in `frontend/app/chatbot/page.tsx`

**Test Phase 5**:
```
1. Visit /chatbot with existing conversation
2. Click "New Chat" button
3. Verify welcome message appears
4. Send a message
5. Verify new conversation created (check sidebar)
6. Click on old conversation
7. Verify old messages load
```

---

## Phase 6: User Story 7 - Conversation History

**Goal**: Display conversation list in sidebar with date grouping.

**User Story 7**: Access Conversation History (P3)

**Independent Test**: Create multiple conversations, verify sidebar shows them grouped by date.

- [x] T022 [US7] Add date grouping logic (Today, Yesterday, Last 7 days, Older) in `frontend/components/chat/ChatSidebar.tsx`
- [x] T023 [US7] Add conversation delete button to sidebar in `frontend/components/chat/ChatSidebar.tsx`
- [x] T024 [US7] Add mobile hamburger menu with slide-out drawer in `frontend/components/chat/ChatSidebar.tsx`

**Test Phase 6**:
```
1. Create conversations on different days (if possible) or create 5+ conversations
2. Verify sidebar shows conversations grouped by date
3. Click delete button on a conversation
4. Verify conversation removed from sidebar
5. Test on mobile (resize browser or use dev tools)
6. Verify hamburger menu appears
7. Click hamburger, verify sidebar slides out
8. Select conversation, verify sidebar closes
```

---

## Phase 7: User Story 8 - First-Time Experience

**Goal**: Show welcome message for new users with example commands.

**User Story 8**: First-Time User Experience (P3)

**Independent Test**: Visit /chatbot as new user, verify welcome message with examples.

- [x] T025 [US8] Create WelcomeMessage component with examples in `frontend/components/chat/WelcomeMessage.tsx`
- [x] T026 [US8] Integrate WelcomeMessage into ChatArea when no conversation selected in `frontend/components/chat/ChatArea.tsx`

**Test Phase 7**:
```
1. Clear all conversations (or use new user)
2. Visit /chatbot
3. Verify welcome message appears with example commands
4. Verify examples are clickable or copy-able
5. Send first message
6. Verify welcome message disappears and chat starts
```

---

## Phase 8: Polish & Integration

**Goal**: Final touches and end-to-end testing.

- [x] T027 Add "Chatbot" navigation link to header in `frontend/components/Header.tsx`
- [x] T028 End-to-end integration testing (all user stories)

**Test Phase 8 - Complete E2E Flow**:
```
1. Login to application
2. Click "Chatbot" in navigation
3. Verify welcome message (first time)
4. Send "Add a task to buy groceries"
5. Verify AI confirms task created
6. Send "Show my tasks"
7. Verify task list displayed
8. Send "Mark task X as done"
9. Verify completion confirmed
10. Send "Delete task Y"
11. Verify deletion confirmed
12. Send "Change task Z to Buy fruits"
13. Verify update confirmed
14. Click "New Chat"
15. Verify new conversation starts
16. Check sidebar shows both conversations
17. Click old conversation
18. Verify messages load correctly
19. Delete a conversation
20. Verify removed from sidebar
21. Test on mobile device/emulator
22. Verify hamburger menu works
23. Verify responsive layout
```

---

## Dependency Graph

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (Database)
    │
    ├──────────────────┬──────────────────┐
    ▼                  ▼                  ▼
Phase 3 (US1+US2)  Phase 4 (US3-5)   [Can parallel after DB]
    │                  │
    └────────┬─────────┘
             ▼
      Phase 5 (US6: New Chat)
             │
             ▼
      Phase 6 (US7: History)
             │
             ▼
      Phase 7 (US8: Welcome)
             │
             ▼
      Phase 8 (Polish)
```

---

## Parallel Execution Opportunities

### Within Phase 3:
- T006 (add_task tool) and T007 (list_tasks tool) can run in parallel
- T012 (API client) can run in parallel with backend tasks

### Within Phase 4:
- T017, T018, T019 (complete, delete, update tools) can ALL run in parallel

### Across Phases:
- Phase 4 can start after Phase 2 (doesn't need Phase 3 complete)
- Frontend tasks in Phase 3 can start once T010-T011 are done

---

## MVP Scope (Minimum Viable Product)

For fastest demo-ready version, complete only:
- **Phase 1**: Setup (T001-T002)
- **Phase 2**: Database (T003-T005)
- **Phase 3**: Core Chat (T006-T016)

This gives you:
- Add tasks via chat ✓
- View tasks via chat ✓
- Basic chat interface ✓

Then incrementally add:
- Phase 4: Task operations (complete, delete, update)
- Phase 5: New conversation support
- Phase 6: Conversation history & mobile
- Phase 7: Welcome message
- Phase 8: Polish

---

## MCP HTTP Transport Implementation Notes

**Architecture (Updated 2025-12-20)**:
1. MCP Server mounted at `/mcp` endpoint in FastAPI
2. Agent connects via `mcp_servers=[MCPServerStreamableHttp(url="/mcp")]`
3. Tools receive `user_id` as parameter (injected via agent instructions)
4. Each tool creates its own database session

**Key Implementation Changes**:
- T008: Agent uses `mcp_servers=[]`, NOT `tools=[]`
- T011: Must add `app.mount("/mcp", mcp.streamable_http_app())`
- MCP tools: Accept `user_id` parameter, create own DB session

**Why HTTP Transport**:
- MCPServerStdio (subprocess) can't access FastAPI database session
- HTTP transport allows MCP Server to share database connection
- Agent calls MCP Server via HTTP at `/mcp` endpoint

---

## Task File Reference

| Task | File Path |
|------|-----------|
| T001 | `backend/.env` |
| T002 | `backend/pyproject.toml` |
| T003 | `backend/app/models/conversation.py` |
| T004 | `backend/app/models/message.py` |
| T005 | `backend/alembic/versions/xxx_phase3.py` |
| T006-T007, T017-T019 | `backend/app/services/mcp_server.py` |
| T008 | `backend/app/services/agent.py` (use mcp_servers=[MCPServerStreamableHttp]) |
| T009 | `backend/app/routers/conversations.py` |
| T010 | `backend/app/routers/chat.py` |
| T011 | `backend/app/main.py` (mount MCP at /mcp) |
| T012 | `frontend/lib/chat-api.ts` |
| T013 | `frontend/components/chat/ChatMessage.tsx` |
| T014 | `frontend/components/chat/ChatInput.tsx` |
| T015, T026 | `frontend/components/chat/ChatArea.tsx` |
| T016, T021 | `frontend/app/chatbot/page.tsx` |
| T020, T022-T024 | `frontend/components/chat/ChatSidebar.tsx` |
| T025 | `frontend/components/chat/WelcomeMessage.tsx` |
| T027 | `frontend/components/Header.tsx` |
| T028 | Manual testing |

---

## Implementation Strategy

1. **Start with MVP**: Complete Phases 1-3 first for demo-ready chatbot
2. **Test incrementally**: Run and verify after each task
3. **Parallel when possible**: Use parallel opportunities to speed up
4. **Mobile last**: Test mobile layout after desktop works
5. **Polish at end**: Navigation link and final testing in Phase 8
