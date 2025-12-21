# API Contract: MCP Tools (Official MCP SDK)

**Feature**: 007-ai-chatbot-phase3
**Type**: MCP Server Tools (via @mcp.tool() decorator from Official MCP Python SDK)
**Updated**: 2025-12-20

---

## Overview

These tools are exposed via an **MCP Server** using the **Official MCP Python SDK** (`mcp[cli]`). The MCP Server is mounted as an HTTP endpoint within the FastAPI application, and the OpenAI Agents SDK connects to it via `mcp_servers` parameter using `MCPServerStreamableHttp`.

**Important**:
- We use `@mcp.tool()` from `mcp.server.fastmcp`, NOT `@function_tool` from `agents`
- Agent connects via `mcp_servers=[MCPServerStreamableHttp(...)]`, NOT `tools=[]`

---

## Architecture

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

---

## Technology Stack

| Component | Technology | Package |
|-----------|------------|---------|
| MCP Server | Official MCP Python SDK | `mcp[cli]>=1.2.0` |
| AI Agent | OpenAI Agents SDK | `openai-agents>=0.6.0` |
| MCP Transport | Streamable HTTP | `mcp.streamable_http_app()` |
| Agent Connection | MCPServerStreamableHttp | `agents.mcp.MCPServerStreamableHttp` |

---

## Installation

```bash
# Install MCP SDK
pip install "mcp[cli]"

# Or with uv
uv add "mcp[cli]"
```

---

## MCP Server Setup

### 1. Create MCP Server with Tools

```python
# backend/app/services/mcp_server.py
from mcp.server.fastmcp import FastMCP
from app.database import get_async_session
from app.models.task import Task, TaskStatus

# Initialize MCP Server
mcp = FastMCP("todo-mcp-server")

@mcp.tool()
async def add_task(user_id: str, title: str, description: str = "") -> dict:
    """Add a new task for the user."""
    async with get_async_session() as session:
        task = Task(user_id=user_id, title=title, description=description)
        session.add(task)
        await session.commit()
        await session.refresh(task)
        return {"task_id": str(task.id), "status": "created", "title": task.title}

# More tools...
```

### 2. Mount MCP Server in FastAPI

```python
# backend/app/main.py
from fastapi import FastAPI
from app.services.mcp_server import mcp

app = FastAPI()

# Mount MCP Server at /mcp endpoint
app.mount("/mcp", mcp.streamable_http_app())
```

### 3. Connect Agent to MCP Server

```python
# backend/app/services/agent.py
from contextlib import asynccontextmanager
from agents import Agent
from agents.mcp import MCPServerStreamableHttp

MCP_SERVER_URL = "http://localhost:8000/mcp"

@asynccontextmanager
async def create_agent(user_id: str):
    """Create agent connected to MCP Server."""
    async with MCPServerStreamableHttp(
        name="Todo MCP Server",
        params={"url": MCP_SERVER_URL},
    ) as mcp_server:
        agent = Agent(
            name="Todo Assistant",
            instructions=AGENT_INSTRUCTIONS,
            mcp_servers=[mcp_server],  # ✅ Correct way to connect!
        )
        yield agent
```

---

## Tools

### 1. add_task

Create a new task for the user.

#### Signature
```python
@mcp.tool()
async def add_task(user_id: str, title: str, description: str = "") -> dict:
    """Add a new task for the user.

    Creates a new task with the given title and optional description.
    The task is associated with the specified user.

    Args:
        user_id: The unique identifier of the user.
        title: The title of the task (1-200 chars).
        description: Optional task description.

    Returns:
        Dictionary with task_id, status, and title.
    """
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_id | string | Yes | The user's unique identifier |
| title | string | Yes | Task title (1-200 chars) |
| description | string | No | Optional task description |

#### Returns

```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "created",
  "title": "Buy groceries"
}
```

#### Error Response
```json
{
  "error": "Failed to create task",
  "details": "Title is required"
}
```

#### When AI Should Use
- User says: "Add a task to...", "Remember to...", "I need to...", "Create a task for..."

---

### 2. list_tasks

Retrieve user's tasks with optional status filter.

#### Signature
```python
@mcp.tool()
async def list_tasks(user_id: str, status: str = "all") -> dict:
    """List tasks for the user.

    Retrieves tasks belonging to the specified user, optionally
    filtered by completion status.

    Args:
        user_id: The unique identifier of the user.
        status: Filter - "all", "pending", or "completed".

    Returns:
        Dictionary with tasks list, count, and filter applied.
    """
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_id | string | Yes | The user's unique identifier |
| status | string | No | Filter: "all", "pending", or "completed" (default: "all") |

#### Returns

```json
{
  "tasks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Buy groceries",
      "description": "Milk, eggs, bread",
      "completed": false,
      "created_at": "2025-12-18T10:00:00Z"
    }
  ],
  "count": 1,
  "filter": "all"
}
```

#### When AI Should Use
- User says: "Show my tasks", "What's pending?", "List completed tasks", "What do I have to do?"

---

### 3. complete_task

Mark a task as completed.

#### Signature
```python
@mcp.tool()
async def complete_task(user_id: str, task_id: str) -> dict:
    """Mark a task as complete.

    Args:
        user_id: The unique identifier of the user.
        task_id: The task ID to complete (UUID string).

    Returns:
        Dictionary with task_id, status, and title.
    """
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_id | string | Yes | The user's unique identifier |
| task_id | string | Yes | The task ID to complete (UUID) |

#### Returns

```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "title": "Call mom"
}
```

#### Error Response
```json
{
  "error": "Task not found",
  "task_id": "invalid-id"
}
```

#### When AI Should Use
- User says: "Mark task X as done", "Complete task X", "I finished...", "Done with..."

---

### 4. delete_task

Remove a task from the list.

#### Signature
```python
@mcp.tool()
async def delete_task(user_id: str, task_id: str) -> dict:
    """Delete a task from the list.

    Args:
        user_id: The unique identifier of the user.
        task_id: The task ID to delete (UUID string).

    Returns:
        Dictionary with task_id, status, and title.
    """
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_id | string | Yes | The user's unique identifier |
| task_id | string | Yes | The task ID to delete (UUID) |

#### Returns

```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "deleted",
  "title": "Old task"
}
```

#### When AI Should Use
- User says: "Delete task X", "Remove task X", "Cancel task X", "Get rid of..."

---

### 5. update_task

Modify an existing task's title or description.

#### Signature
```python
@mcp.tool()
async def update_task(
    user_id: str,
    task_id: str,
    title: str | None = None,
    description: str | None = None
) -> dict:
    """Update a task's title or description.

    Args:
        user_id: The unique identifier of the user.
        task_id: The task ID to update (UUID string).
        title: New title (optional).
        description: New description (optional).

    Returns:
        Dictionary with task_id, status, title, and changes.
    """
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_id | string | Yes | The user's unique identifier |
| task_id | string | Yes | The task ID to update (UUID) |
| title | string | No | New title (if changing) |
| description | string | No | New description (if changing) |

#### Returns

```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "updated",
  "title": "Buy groceries and fruits",
  "changes": ["title"]
}
```

#### When AI Should Use
- User says: "Change task X to...", "Update task X", "Rename task X", "Edit..."

---

## Agent Configuration with MCP Server

```python
# backend/app/services/agent.py
from contextlib import asynccontextmanager
from typing import AsyncGenerator
from agents import Agent, Runner
from agents.mcp import MCPServerStreamableHttp

MCP_SERVER_URL = "http://localhost:8000/mcp"

AGENT_INSTRUCTIONS = """You are a helpful todo assistant.

CAPABILITIES:
- Add new tasks (add_task)
- List tasks with filters (list_tasks)
- Mark tasks complete (complete_task)
- Delete tasks (delete_task)
- Update task details (update_task)

BEHAVIOR:
- Always confirm actions with friendly responses
- Include task IDs when listing tasks
- If task not found, suggest listing tasks first
- Ask for clarification if request is ambiguous
- When user mentions a task by name, find its ID first using list_tasks

IMPORTANT:
- Always pass user_id to every tool call
- The user_id will be provided in the context

EXAMPLES:
- "Add a task to buy milk" → add_task(user_id=context.user_id, title="Buy milk")
- "Show my tasks" → list_tasks(user_id=context.user_id, status="all")
- "What's pending?" → list_tasks(user_id=context.user_id, status="pending")
- "Mark task X done" → complete_task(user_id=context.user_id, task_id="X")
- "Delete task Y" → delete_task(user_id=context.user_id, task_id="Y")
"""

@asynccontextmanager
async def create_agent(user_id: str) -> AsyncGenerator[Agent, None]:
    """Create agent connected to MCP Server via mcp_servers parameter."""
    async with MCPServerStreamableHttp(
        name="Todo MCP Server",
        params={"url": MCP_SERVER_URL},
    ) as mcp_server:
        agent = Agent(
            name="Todo Assistant",
            instructions=AGENT_INSTRUCTIONS.replace("context.user_id", f'"{user_id}"'),
            mcp_servers=[mcp_server],  # ✅ Proper MCP connection!
        )
        yield agent
```

---

## Comparison: Correct vs Wrong Approach

| Aspect | ✅ Correct (mcp_servers) | ❌ Wrong (tools) |
|--------|-------------------------|------------------|
| Connection | `mcp_servers=[MCPServerStreamableHttp(...)]` | `tools=[add_task, ...]` |
| Protocol | MCP Standard | Direct function call |
| Tool Discovery | Automatic via MCP | Manual registration |
| Hackathon Spec | ✅ Meets requirement | ❌ Does not meet |
| Reusability | Any MCP client can connect | This agent only |

---

## Security Notes

1. All tools receive `user_id` to enforce data isolation
2. Tools must verify user owns the task before any operation
3. Never expose tasks from other users
4. Log tool invocations for audit purposes
5. Validate all input parameters

---

## References

- [MCP Protocol Introduction](https://modelcontextprotocol.io/docs/getting-started/intro)
- [Build MCP Server](https://modelcontextprotocol.io/docs/develop/build-server)
- [MCP Python SDK GitHub](https://github.com/modelcontextprotocol/python-sdk)
- [OpenAI Agents SDK - MCP Integration](https://openai.github.io/openai-agents-python/mcp/)
- [FastMCP Streamable HTTP](https://gofastmcp.com/servers/streamable-http)
