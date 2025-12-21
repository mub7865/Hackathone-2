# Research: AI-Powered Todo Chatbot (Phase III)

**Feature**: 007-ai-chatbot-phase3
**Date**: 2025-12-18
**Status**: Complete

---

## 1. LLM Provider Selection

### Decision
Use **Google Gemini** (gemini-2.0-flash) via OpenAI Agents SDK

### Rationale
- Free tier with generous limits for hackathon development
- Large context window (1M+ tokens) supports longer conversations
- OpenAI Agents SDK supports Gemini via OpenAI-compatible API
- Lower cost compared to OpenAI GPT-4o during development

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|------------------|
| OpenAI GPT-4o | Higher cost, smaller context window |
| OpenAI GPT-4o-mini | Good option but Gemini free tier is more cost-effective |
| Local LLM | Requires significant compute resources, slower |

### Implementation
```python
from openai import AsyncOpenAI
from agents import Agent, OpenAIChatCompletionsModel, set_tracing_disabled

gemini_client = AsyncOpenAI(
    api_key=os.environ["GEMINI_API_KEY"],
    base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
)
set_tracing_disabled(disabled=True)

agent = Agent(
    name="Todo Assistant",
    model=OpenAIChatCompletionsModel(
        model="gemini-2.0-flash",
        openai_client=gemini_client,
    ),
    tools=[add_task, list_tasks, complete_task, delete_task, update_task],
)
```

---

## 2. MCP Server with Official MCP SDK (HTTP Transport)

### Decision (Updated 2025-12-20)
Use **@mcp.tool() decorator from Official MCP Python SDK** with **HTTP Transport**

**Agent connects via `mcp_servers=[MCPServerStreamableHttp]`** (NOT `tools=[]`)

### Rationale
- **Hackathon Requirement**: Spec explicitly states "Build MCP server with Official MCP SDK"
- **Proper MCP Protocol**: Agent connects via `mcp_servers` parameter, NOT `tools` parameter
- MCP Server mounted at `/mcp` endpoint in FastAPI via `mcp.streamable_http_app()`
- Tools receive `user_id` as parameter and create their own database sessions
- Works seamlessly on Vercel (serverless deployment)

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|------------------|
| @function_tool from agents SDK | Does NOT meet hackathon requirement for MCP Server |
| tools=mcp.get_tools() | Wrong connection method - should use mcp_servers=[] |
| MCPServerStdio (subprocess) | Subprocess can't access FastAPI database session |
| Direct API calls in agent | Loses tool abstraction benefits |

### Architecture
```
┌─────────────────────────────────────────────────────────────────────┐
│                         FastAPI Server                               │
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  POST /api/v1/chat                                            │  │
│  │    1. Extract user_id from JWT                                │  │
│  │    2. Create agent with mcp_servers=[MCPServerStreamableHttp] │  │
│  │    3. Run agent with user context                             │  │
│  └──────────────────────────┬────────────────────────────────────┘  │
│                             │                                        │
│                             ▼                                        │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  OpenAI Agents SDK (Agent + Runner)                           │  │
│  │    mcp_servers=[MCPServerStreamableHttp(url="/mcp")]          │  │
│  └──────────────────────────┬────────────────────────────────────┘  │
│                             │ HTTP Request to /mcp                   │
│                             ▼                                        │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  MCP Server (mounted at /mcp endpoint)                        │  │
│  │    mcp.streamable_http_app() mounted in FastAPI               │  │
│  │                                                                │  │
│  │    @mcp.tool() add_task(user_id, title, description)          │  │
│  │    @mcp.tool() list_tasks(user_id, status)                    │  │
│  │    @mcp.tool() complete_task(user_id, task_id)                │  │
│  │    @mcp.tool() delete_task(user_id, task_id)                  │  │
│  │    @mcp.tool() update_task(user_id, task_id, title, desc)     │  │
│  └──────────────────────────┬────────────────────────────────────┘  │
│                             │                                        │
│                             ▼                                        │
│                       ┌──────────┐                                   │
│                       │ Neon DB  │                                   │
│                       └──────────┘                                   │
└─────────────────────────────────────────────────────────────────────┘
```

### Implementation
```python
# backend/app/services/mcp_server.py
from mcp.server.fastmcp import FastMCP
from sqlmodel import Session, select
from app.core.database import engine
from app.models.task import Task

# Initialize MCP Server
mcp = FastMCP("todo-mcp-server")

@mcp.tool()
async def add_task(user_id: str, title: str, description: str = "") -> dict:
    """Add a new task for the user."""
    # Each tool creates its own database session
    with Session(engine) as session:
        task = Task(user_id=user_id, title=title, description=description)
        session.add(task)
        session.commit()
        session.refresh(task)
        return {"task_id": str(task.id), "status": "created", "title": task.title}

# backend/app/main.py
from fastapi import FastAPI
from app.services.mcp_server import mcp

app = FastAPI()

# Mount MCP Server at /mcp endpoint
app.mount("/mcp", mcp.streamable_http_app())

# backend/app/services/agent.py
from contextlib import asynccontextmanager
from agents import Agent
from agents.mcp import MCPServerStreamableHttp

MCP_SERVER_URL = "http://localhost:8000/mcp"

@asynccontextmanager
async def create_agent(user_id: str):
    """Create agent connected to MCP Server via mcp_servers parameter."""
    async with MCPServerStreamableHttp(
        name="Todo MCP Server",
        params={"url": MCP_SERVER_URL},
    ) as mcp_server:
        agent = Agent(
            name="Todo Assistant",
            instructions=f"You are a helpful assistant. User ID is {user_id}...",
            mcp_servers=[mcp_server],  # ✅ CORRECT: Use mcp_servers parameter!
        )
        yield agent
```

### Key Difference: Correct vs Wrong Approach
| Aspect | ✅ Correct (mcp_servers) | ❌ Wrong (tools) |
|--------|-------------------------|------------------|
| Connection | `mcp_servers=[MCPServerStreamableHttp(...)]` | `tools=[add_task, ...]` |
| Protocol | MCP Standard | Direct function call |
| Tool Discovery | Automatic via MCP | Manual registration |
| Hackathon Spec | ✅ Meets requirement | ❌ Does not meet |
| Reusability | Any MCP client can connect | This agent only |

---

## 3. Conversation History Strategy

### Decision
- Store all messages in database
- Send last **100 messages** to AI for context
- Truncate older messages from AI context (not from storage)

### Rationale
- Gemini 2.0 Flash has 1M token context - 100 messages is well within limits
- Database stores complete history for user reference
- Prevents context overflow while maintaining conversation coherence

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|------------------|
| No limit | Risk of token overflow with very long conversations |
| 20 messages | Too short, loses important context |
| Summarization | Adds complexity and latency |

---

## 4. Chat UI Approach

### Decision
Use **custom React components** (not OpenAI ChatKit hosted)

### Rationale
- ChatKit requires OpenAI-hosted backend for full features
- We have custom Gemini backend - need custom frontend
- More control over UI/UX and styling
- Aligns with existing Tailwind CSS patterns in frontend

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|------------------|
| OpenAI ChatKit (hosted) | Requires OpenAI backend, doesn't work with Gemini |
| Third-party chat library | Additional dependency, less control |

### Implementation
Custom components:
- `ChatSidebar.tsx` - Conversation list with hamburger menu on mobile
- `ChatArea.tsx` - Message display area
- `ChatInput.tsx` - Message input with send button
- `ChatMessage.tsx` - Individual message bubble

---

## 5. Mobile Sidebar Pattern

### Decision
**Hamburger menu** with slide-out drawer

### Rationale
- Most familiar pattern for mobile chat apps (WhatsApp, Telegram)
- Maximizes chat area on small screens
- Easy to implement with Tailwind CSS

### Implementation
```tsx
// Mobile: Hamburger icon in header, sidebar slides from left
// Desktop: Sidebar always visible (w-64 or w-72)
<div className="lg:hidden"> {/* Hamburger button */}
<div className={`fixed inset-y-0 left-0 transform ${isOpen ? 'translate-x-0' : '-translate-x-full'}`}>
```

---

## 6. Conversation Title Generation

### Decision
**Truncate first user message** to 50 characters

### Rationale
- Simple and instant - no additional API call
- First message usually describes conversation purpose
- Predictable behavior for users

### Alternatives Considered
| Alternative | Rejected Because |
|-------------|------------------|
| AI-generated summary | Adds latency and API cost |
| Timestamp only | Not descriptive enough |
| User-editable | Out of scope for Phase III |

---

## 7. Database Schema Design

### Decision
Two new tables: `conversations` and `messages` with cascade delete

### Rationale
- Clean separation of concerns
- Cascade delete ensures no orphaned messages
- Foreign key to existing users table via user_id string

### Schema
```sql
-- conversations table
CREATE TABLE conversations (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR NOT NULL,  -- References Better Auth user
    title VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_conversations_user_id ON conversations(user_id);

-- messages table
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER REFERENCES conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL,  -- 'user' or 'assistant'
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
```

---

## 8. Error Handling Strategy

### Decision
- Backend: Return structured error responses with user-friendly messages
- AI Agent: Include error handling in tool responses
- Frontend: Display toast notifications for errors

### Implementation
```python
# Tool error response (using @mcp.tool())
@mcp.tool()
async def complete_task(user_id: str, task_id: str) -> dict:
    """Mark a task as complete."""
    with Session(engine) as session:
        task = session.get(Task, task_id)
        if not task or task.user_id != user_id:
            return {"error": "Task not found", "task_id": task_id}
        task.completed = True
        session.add(task)
        session.commit()
        return {"task_id": str(task.id), "status": "completed", "title": task.title}
```

---

## 9. Testing Strategy

### Decision
**Run and test after each implementation task**

### Rationale
- Early bug detection
- Ensures incremental progress
- Validates each component before integration
- User requirement for this plan

### Testing Approach
| Layer | Testing Method |
|-------|----------------|
| Database Models | Manual: Alembic migration + DB inspection |
| API Endpoints | Manual: curl/httpie or Swagger UI |
| MCP Server & Tools | Manual: `python -c "from app.services.mcp_server import mcp; print(mcp.get_tools())"` |
| AI Agent | Manual: Direct agent test script |
| Frontend Components | Manual: Browser testing |
| Integration | Manual: End-to-end chat flow |

---

## Summary

All technical decisions have been made based on:
1. Clarifications from spec session
2. Phase III requirements from hackathon document
3. Best practices for the chosen tech stack
4. Simplicity and hackathon timeline constraints

**Key Update (2025-12-20)**: MCP Server implementation uses HTTP Transport:
- MCP Server mounted at `/mcp` via `app.mount("/mcp", mcp.streamable_http_app())`
- Agent connects via `mcp_servers=[MCPServerStreamableHttp(url="/mcp")]`
- Tools receive `user_id` as parameter (passed via agent instructions)
- Each tool creates its own database session

**Important**: Agent uses `mcp_servers=[]` parameter, NOT `tools=[]`. This is the correct MCP protocol integration that meets hackathon requirements.

No NEEDS CLARIFICATION items remain. Ready for implementation with correct MCP architecture.
