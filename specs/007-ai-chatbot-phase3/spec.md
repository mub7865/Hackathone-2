# Feature Specification: AI-Powered Todo Chatbot (Phase III)

**Feature Branch**: `007-ai-chatbot-phase3`
**Created**: 2025-12-18
**Status**: Draft
**Input**: User description: "Phase III: AI-Powered Todo Chatbot with OpenAI ChatKit, Agents SDK, and MCP tools for natural language task management. Dedicated /chatbot page with conversation sidebar and new chat functionality."

---

## Clarifications

### Session 2025-12-18

- Q: Which LLM provider should be used for the AI agent? → A: Gemini (via OpenAI Agents SDK) - Free tier, large context window
- Q: When a conversation is deleted, what should happen to its messages? → A: Cascade delete - All messages deleted with conversation
- Q: How should the sidebar behave on mobile devices? → A: Hamburger menu - Sidebar hidden by default, opens as slide-out drawer
- Q: How should conversation titles be generated? → A: First message truncate - Use first 50 chars of first user message
- Q: Should Phase 3 code be in new folder or extend existing? → A: Extend existing frontend/ and backend/ folders (avoid duplication)

### Session 2025-12-20 (MCP Server Clarification)

- Q: Should we use @function_tool from OpenAI Agents SDK or @mcp.tool() from Official MCP SDK?
  → A: **@mcp.tool() from Official MCP SDK** - Hackathon spec requires "Build MCP server with Official MCP SDK"
- Q: Should MCP Server be deployed separately or embedded in FastAPI?
  → A: **Embedded in FastAPI** - Same process, no separate deployment needed. Architecture diagram shows MCP Server inside FastAPI Server.
- Q: How does agent connect to MCP tools?
  → A: Use `mcp.get_tools()` to get tool list from FastMCP server, pass to Agent's tools parameter
- Q: What package to install for MCP?
  → A: `mcp[cli]>=1.2.0` - Official MCP Python SDK with FastMCP included

---

## Overview

Phase III transforms the Phase II web application into an AI-powered chatbot that enables users to manage their todo tasks through natural language conversation. Users can add, view, update, delete, and complete tasks by simply chatting with an AI assistant instead of using traditional form-based interfaces.

**Key Value Proposition**: Users can manage their tasks naturally by typing messages like "Add a task to buy groceries" or "What's pending?" instead of clicking buttons and filling forms.

**Chat Interface Design**: A dedicated `/chatbot` page with:
- Left sidebar showing list of past conversations (like ChatGPT)
- "New Chat" button to start fresh conversations
- Main chat area showing current conversation
- Welcome message for first-time users

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Chat with AI to Add Tasks (Priority: P1)

A logged-in user opens the chatbot page and types a natural language message to create a new task. The AI assistant understands the intent, creates the task using MCP tools, and confirms the action with a friendly response.

**Why this priority**: This is the core value proposition - enabling task creation through conversation. Without this, the chatbot has no primary function.

**Independent Test**: Can be fully tested by sending a chat message like "Add a task to buy milk" and verifying the task appears in the database with correct user_id association.

**Acceptance Scenarios**:

1. **Given** a logged-in user on the chatbot page, **When** user types "Add a task to buy groceries", **Then** the AI creates a task with title "Buy groceries" and responds with confirmation including the task details.

2. **Given** a logged-in user on the chatbot page, **When** user types "I need to remember to call mom tomorrow", **Then** the AI creates a task with title "Call mom tomorrow" and confirms the task was added.

3. **Given** a logged-in user on the chatbot page, **When** user types "Add task: Project meeting notes - Prepare slides for Q4 review", **Then** the AI creates a task with both title and description and confirms both were saved.

---

### User Story 2 - Chat with AI to View Tasks (Priority: P1)

A logged-in user asks the AI assistant to show their tasks. The AI retrieves the user's tasks using MCP tools and presents them in a readable format, supporting filters for all, pending, or completed tasks.

**Why this priority**: Viewing tasks is equally critical as adding them - users need to see what they have before managing them.

**Independent Test**: Can be fully tested by having tasks in the database, then asking "Show my tasks" and verifying the response lists all user's tasks correctly.

**Acceptance Scenarios**:

1. **Given** a user with 3 tasks (2 pending, 1 completed), **When** user types "Show me all my tasks", **Then** the AI lists all 3 tasks with their status indicators.

2. **Given** a user with pending tasks, **When** user types "What's pending?", **Then** the AI lists only pending/incomplete tasks.

3. **Given** a user with completed tasks, **When** user types "What have I completed?", **Then** the AI lists only completed tasks.

4. **Given** a user with no tasks, **When** user types "Show my tasks", **Then** the AI responds that there are no tasks and suggests creating one.

---

### User Story 3 - Chat with AI to Complete Tasks (Priority: P2)

A logged-in user tells the AI assistant they have finished a task. The AI marks the specified task as complete using MCP tools and confirms the action.

**Why this priority**: Completing tasks is essential for task management workflow but depends on first being able to add and view tasks.

**Independent Test**: Can be fully tested by having a pending task, then saying "Mark task 1 as done" and verifying the task's completed status changes to true.

**Acceptance Scenarios**:

1. **Given** a user with a pending task (ID: 5, title: "Buy milk"), **When** user types "Mark task 5 as complete", **Then** the AI marks the task complete and confirms with the task title.

2. **Given** a user with a pending task titled "Call mom", **When** user types "I finished calling mom", **Then** the AI finds the task by context, marks it complete, and confirms.

3. **Given** a user references a non-existent task ID, **When** user types "Complete task 999", **Then** the AI responds that the task was not found and suggests listing tasks.

---

### User Story 4 - Chat with AI to Delete Tasks (Priority: P2)

A logged-in user asks the AI assistant to remove a task. The AI deletes the specified task using MCP tools and confirms the deletion.

**Why this priority**: Deletion is important for list management but less frequently used than adding, viewing, or completing.

**Independent Test**: Can be fully tested by having a task, then saying "Delete task 3" and verifying the task is removed from the database.

**Acceptance Scenarios**:

1. **Given** a user with a task (ID: 3, title: "Old task"), **When** user types "Delete task 3", **Then** the AI removes the task and confirms deletion with the task title.

2. **Given** a user references a non-existent task, **When** user types "Remove task 999", **Then** the AI responds that the task was not found.

---

### User Story 5 - Chat with AI to Update Tasks (Priority: P2)

A logged-in user asks the AI assistant to modify an existing task's title or description. The AI updates the task using MCP tools and confirms the changes.

**Why this priority**: Updates are useful but less common than other operations in typical task management workflows.

**Independent Test**: Can be fully tested by having a task, then saying "Change task 1 to Buy fruits" and verifying the task title is updated.

**Acceptance Scenarios**:

1. **Given** a user with a task (ID: 1, title: "Buy groceries"), **When** user types "Change task 1 to 'Buy groceries and fruits'", **Then** the AI updates the title and confirms the change.

2. **Given** a user with a task, **When** user types "Update description of task 2 to 'Need by Friday'", **Then** the AI updates the description and confirms.

---

### User Story 6 - Start New Conversation (Priority: P2)

A logged-in user wants to start a fresh conversation without the context of previous messages. User clicks "New Chat" button in the sidebar to create a new conversation.

**Why this priority**: Essential for conversation management - users need ability to organize their chat history into separate topics.

**Independent Test**: Can be fully tested by clicking "New Chat", sending a message, and verifying a new conversation is created in the database while the old one remains accessible.

**Acceptance Scenarios**:

1. **Given** a user in an active conversation, **When** user clicks "New Chat" button, **Then** a new empty conversation starts with welcome message and the old conversation moves to sidebar history.

2. **Given** a user clicks "New Chat", **When** user sends a message, **Then** the message is saved to the new conversation (not the old one).

3. **Given** a user has multiple conversations, **When** user clicks on a previous conversation in sidebar, **Then** that conversation loads with all its messages.

---

### User Story 7 - Access Conversation History (Priority: P3)

A logged-in user wants to review or continue a previous conversation. The sidebar displays a list of past conversations that can be clicked to load.

**Why this priority**: Conversation persistence enhances user experience but the core chatbot functionality works without it.

**Independent Test**: Can be fully tested by having multiple conversations, clicking one in sidebar, and verifying all messages load correctly.

**Acceptance Scenarios**:

1. **Given** a user with 5 past conversations, **When** user views the chatbot page, **Then** sidebar shows list of conversations with preview/title and timestamps.

2. **Given** a user clicks on a past conversation in sidebar, **When** the conversation loads, **Then** all messages appear in chronological order.

3. **Given** a user is viewing a past conversation, **When** user sends a new message, **Then** the message is added to that conversation and AI responds in context.

4. **Given** a user has never used the chatbot, **When** user visits `/chatbot` page, **Then** they see welcome message and empty sidebar (or "No conversations yet").

---

### User Story 8 - First-Time User Experience (Priority: P3)

A new user visits the chatbot page for the first time and sees a welcoming interface that guides them on how to use the chatbot.

**Why this priority**: Good onboarding improves user adoption but is not critical for core functionality.

**Independent Test**: Can be fully tested by visiting chatbot page as new user and verifying welcome message appears.

**Acceptance Scenarios**:

1. **Given** a user with no conversation history, **When** user visits `/chatbot`, **Then** they see a welcome message explaining what the chatbot can do with example commands.

2. **Given** welcome message is displayed, **When** user sends their first message, **Then** a new conversation is automatically created and message is processed.

---

### Edge Cases

- What happens when user sends an empty message? -> System prevents sending empty messages (button disabled)
- What happens when user asks about tasks belonging to another user? -> System only shows user's own tasks (user isolation enforced)
- What happens when database is temporarily unavailable? -> AI responds with a friendly error message asking to try again
- What happens when user's message is ambiguous (e.g., "delete it")? -> AI asks for clarification about which task
- What happens when AI cannot determine the user's intent? -> AI asks for clarification and provides examples of supported commands
- What happens when conversation history is very long? -> System limits history sent to AI to recent messages (50-100) to prevent context overflow
- What happens when user deletes all messages in a conversation? -> Conversation remains in sidebar but shows as empty
- What happens when sidebar has many conversations? -> Conversations are grouped by date (Today, Yesterday, Last 7 days, Older)

---

## Requirements *(mandatory)*

### Functional Requirements

#### Chatbot Page & Layout (Frontend)

- **FR-001**: System MUST provide a dedicated `/chatbot` route accessible to authenticated users
- **FR-002**: System MUST display a left sidebar showing list of user's conversations
- **FR-003**: System MUST provide a "New Chat" button in the sidebar to start new conversations
- **FR-004**: System MUST display the main chat area with messages from current conversation
- **FR-005**: System MUST show a welcome message when user has no conversations or starts new chat
- **FR-006**: System MUST allow clicking on sidebar conversations to switch between them
- **FR-007**: System MUST group sidebar conversations by date (Today, Yesterday, Last 7 days, Older)

#### Chat Interface (Frontend)

- **FR-008**: System MUST display conversation messages in chronological order with clear user/assistant distinction
- **FR-009**: System MUST provide a text input area for users to type messages
- **FR-010**: System MUST show loading indicators while waiting for AI responses
- **FR-011**: System MUST display error messages in a user-friendly format when operations fail
- **FR-012**: System MUST disable send button when message input is empty
- **FR-013**: System MUST be responsive and functional on both desktop and mobile devices

#### AI Agent (Backend)

- **FR-014**: System MUST process natural language messages and determine user intent
- **FR-015**: System MUST invoke appropriate MCP tools based on user intent
- **FR-016**: System MUST generate friendly, conversational responses confirming actions
- **FR-017**: System MUST handle ambiguous requests by asking for clarification
- **FR-018**: System MUST handle errors gracefully with helpful error messages

#### MCP Tools

- **FR-019**: System MUST provide an `add_task` tool that creates tasks with user_id, title, and optional description
- **FR-020**: System MUST provide a `list_tasks` tool that retrieves tasks filtered by status (all/pending/completed)
- **FR-021**: System MUST provide a `complete_task` tool that marks a task as completed
- **FR-022**: System MUST provide a `delete_task` tool that removes a task
- **FR-023**: System MUST provide an `update_task` tool that modifies task title or description
- **FR-024**: All MCP tools MUST enforce user isolation (users can only access their own tasks)

#### Chat API Endpoint

- **FR-025**: System MUST provide a POST `/api/{user_id}/chat` endpoint accepting message and optional conversation_id
- **FR-026**: System MUST require valid JWT authentication for the chat endpoint
- **FR-027**: System MUST verify the authenticated user matches the user_id in the URL
- **FR-028**: System MUST return conversation_id, response text, and list of tool calls in the response
- **FR-029**: System MUST create a new conversation if conversation_id is not provided

#### Conversation Management API

- **FR-030**: System MUST provide GET `/api/{user_id}/conversations` to list user's conversations
- **FR-031**: System MUST provide GET `/api/{user_id}/conversations/{id}` to get conversation with messages
- **FR-032**: System MUST provide DELETE `/api/{user_id}/conversations/{id}` to delete a conversation (cascade deletes all associated messages)

#### Conversation Persistence

- **FR-033**: System MUST store each conversation with user_id, title, and timestamps
- **FR-034**: System MUST auto-generate conversation title by truncating first user message to 50 characters
- **FR-035**: System MUST store each message with role (user/assistant), content, and timestamp
- **FR-036**: System MUST fetch conversation history when processing new messages
- **FR-037**: System MUST maintain stateless server architecture (no in-memory state)

#### Authentication Integration

- **FR-038**: System MUST integrate with existing Better Auth JWT authentication from Phase II
- **FR-039**: System MUST reject unauthenticated requests with 401 status
- **FR-040**: System MUST reject requests where JWT user doesn't match URL user_id with 403 status
- **FR-041**: System MUST redirect unauthenticated users from `/chatbot` to login page

---

### Key Entities

- **Conversation**: Represents a chat session; contains user_id, title (auto-generated), created_at, updated_at; has many Messages
- **Message**: Represents a single chat message; contains conversation_id, role (user/assistant), content, created_at
- **Task**: (Existing from Phase II) Represents a todo item; contains user_id, title, description, completed status, timestamps

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can manage all 5 basic task operations (add, list, complete, delete, update) through natural language chat
- **SC-002**: Chat responses appear within 5 seconds of user message submission for typical requests
- **SC-003**: 90% of common task management phrases are correctly understood by the AI on first attempt
- **SC-004**: Users can create new conversations and switch between existing ones seamlessly
- **SC-005**: Conversation history persists across browser sessions and server restarts
- **SC-006**: All chat operations enforce user data isolation (users cannot see or modify other users' data)
- **SC-007**: System handles 50 concurrent chat users without response degradation
- **SC-008**: Error states display helpful messages that guide users to successful task completion
- **SC-009**: Chat interface is responsive and functional on both desktop and mobile devices
- **SC-010**: Sidebar correctly groups conversations by date and allows switching between them

---

## Scope & Boundaries

### In Scope

- Phase 3 code extends existing `frontend/` and `backend/` folders (no separate phase3 folder)
- Dedicated `/chatbot` page with sidebar layout
- Conversation list in sidebar with "New Chat" functionality
- AI agent for natural language task management
- MCP tools wrapping existing task CRUD operations
- Conversation and Message database models for persistence
- Chat endpoint with stateless architecture
- Conversation management endpoints (list, get, delete)
- Integration with existing JWT authentication
- Auto-generated conversation titles
- Date-based grouping of conversations in sidebar

### Out of Scope

- Voice input/output (Bonus feature for future)
- Multi-language support beyond English (Bonus feature for future)
- Real-time notifications or push messages
- Renaming conversations manually
- Searching within conversations
- Exporting chat history
- Advanced AI capabilities (scheduling, reminders, priorities - Phase V features)
- Sharing conversations between users

---

## Assumptions

- Phase II authentication (Better Auth with JWT) is fully functional and will be reused
- Phase II task CRUD operations work correctly and will be accessed via MCP tools
- Users have stable internet connections for chat functionality
- OpenAI API is available and responsive for AI processing
- Neon database can handle additional Conversation and Message tables
- A reasonable conversation history limit (50-100 messages) is acceptable for AI context
- Conversation title is auto-generated by truncating first user message to 50 characters
- Mobile users will see a hamburger menu; sidebar opens as slide-out drawer when tapped

---

## Dependencies

- **Phase II Frontend**: Existing Next.js application with authentication
- **Phase II Backend**: Existing FastAPI application with task CRUD endpoints
- **Phase II Database**: Existing Neon PostgreSQL with tasks table
- **Gemini API**: Required for AI agent processing via OpenAI Agents SDK (GEMINI_API_KEY needed)
- **OpenAI ChatKit**: Required for chat UI components

---

## Non-Functional Requirements

### Performance
- Chat responses complete within 5 seconds under normal load
- System supports 50 concurrent chat sessions
- Sidebar loads conversation list within 1 second

### Security
- All chat and conversation endpoints require JWT authentication
- User data isolation is strictly enforced
- No sensitive data logged or exposed in responses

### Reliability
- Stateless architecture enables horizontal scaling
- Conversation state survives server restarts via database persistence

### Usability
- Chat interface follows familiar messaging app patterns (like ChatGPT)
- Clear visual distinction between user messages and AI responses
- Loading states provide feedback during AI processing
- Sidebar provides easy navigation between conversations
- Welcome message guides new users on available commands
