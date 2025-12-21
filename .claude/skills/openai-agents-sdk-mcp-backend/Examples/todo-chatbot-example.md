# Todo Chatbot Example

This example demonstrates a complete AI-powered todo chatbot implementation
using **OpenAI Agents SDK** with a **standalone MCP server** (recommended approach).

## Architecture Overview

### Recommended: Standalone MCP Server

```
┌─────────────────┐     ┌──────────────────────────────────────────────┐
│                 │     │              FastAPI Backend                  │
│  ChatKit UI     │     │                                              │
│  (Frontend)     │────►│  POST /api/{user_id}/chat                    │
│                 │     │         │                                    │
│                 │     │         ▼                                    │
│                 │     │  ┌─────────────────────┐                     │
│                 │◄────│  │  OpenAI Agent       │                     │
│                 │     │  │  (mcp_servers=[])   │                     │
│                 │     │  └─────────┬───────────┘                     │
│                 │     │            │ MCP Protocol                    │
│                 │     │            ▼                                 │
│                 │     │  ┌─────────────────────────────────────────┐ │
│                 │     │  │  MCP Server (Separate Process)          │ │
│                 │     │  │  @mcp.tool() decorators                 │ │
│                 │     │  │  - add_task                             │ │
│                 │     │  │  - list_tasks                           │ │
│                 │     │  │  - complete_task                        │ │
│                 │     │  │  - delete_task                          │ │
│                 │     │  │  - update_task                          │ │
│                 │     │  └─────────────────────────────────────────┘ │
│                 │     │            │                                 │
│                 │     │            ▼                                 │
│                 │     │     ┌────────────┐                           │
│                 │     │     │  Neon DB   │                           │
│                 │     │     │            │                           │
│                 │     │     │  - tasks   │                           │
│                 │     │     │  - convos  │                           │
│                 │     │     │  - messages│                           │
│                 │     │     └────────────┘                           │
└─────────────────┘     └──────────────────────────────────────────────┘
```

## GOOD: Proper MCP Server Implementation (Recommended)

### 1. Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app entry
│   ├── db.py                # Database configuration
│   ├── mcp_server.py        # Standalone MCP server (NEW!)
│   ├── models/
│   │   ├── __init__.py
│   │   ├── task.py          # Task model (from Phase II)
│   │   └── chat.py          # Conversation, Message models
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── tasks.py         # Task CRUD endpoints (from Phase II)
│   │   └── chat.py          # Chat endpoint
│   └── chat/
│       ├── __init__.py
│       └── agent.py         # Agent configuration
├── pyproject.toml
└── .env
```

### 2. MCP Server Implementation (Using Official MCP SDK)

```python
# app/mcp_server.py
"""
Standalone MCP Server using Official MCP Python SDK.
Run separately: python -m app.mcp_server
"""
import os
from typing import Any

from dotenv import load_dotenv
from mcp.server.fastmcp import FastMCP
from sqlmodel import Session, create_engine, select

from app.models.task import Task

# Load environment variables
load_dotenv()

# Initialize FastMCP server
mcp = FastMCP("todo-mcp-server")

# Database connection
DATABASE_URL = os.environ.get("DATABASE_URL")
engine = create_engine(DATABASE_URL)


@mcp.tool()
async def add_task(
    user_id: str,
    title: str,
    description: str = "",
) -> dict[str, Any]:
    """Add a new task for the user.

    Creates a new task with the given title and optional description.
    The task is associated with the specified user.

    Args:
        user_id: The unique identifier of the user.
        title: The title of the task (required, 1-200 characters).
        description: Optional detailed description of the task.

    Returns:
        Dictionary containing task_id, status, and title.
    """
    with Session(engine) as session:
        task = Task(
            user_id=user_id,
            title=title,
            description=description,
            completed=False,
        )
        session.add(task)
        session.commit()
        session.refresh(task)
        return {
            "task_id": str(task.id),
            "status": "created",
            "title": task.title,
        }


@mcp.tool()
async def list_tasks(
    user_id: str,
    status: str = "all",
) -> dict[str, Any]:
    """List tasks for the user.

    Args:
        user_id: The unique identifier of the user.
        status: Filter - "all", "pending", or "completed".

    Returns:
        Dictionary containing tasks list, count, and filter.
    """
    with Session(engine) as session:
        query = select(Task).where(Task.user_id == user_id)

        if status == "pending":
            query = query.where(Task.completed == False)
        elif status == "completed":
            query = query.where(Task.completed == True)

        tasks = session.exec(query).all()
        task_list = [
            {
                "id": str(task.id),
                "title": task.title,
                "description": task.description or "",
                "completed": task.completed,
            }
            for task in tasks
        ]
        return {
            "tasks": task_list,
            "count": len(task_list),
            "filter": status,
        }


@mcp.tool()
async def complete_task(user_id: str, task_id: str) -> dict[str, Any]:
    """Mark a task as complete.

    Args:
        user_id: The unique identifier of the user.
        task_id: The ID of the task to complete.

    Returns:
        Dictionary with task_id, status, and title.
    """
    with Session(engine) as session:
        task = session.get(Task, task_id)

        if not task or task.user_id != user_id:
            return {"error": "Task not found", "task_id": task_id}

        task.completed = True
        session.add(task)
        session.commit()
        return {
            "task_id": str(task.id),
            "status": "completed",
            "title": task.title,
        }


@mcp.tool()
async def delete_task(user_id: str, task_id: str) -> dict[str, Any]:
    """Delete a task.

    Args:
        user_id: The unique identifier of the user.
        task_id: The ID of the task to delete.

    Returns:
        Dictionary with task_id, status, and title.
    """
    with Session(engine) as session:
        task = session.get(Task, task_id)

        if not task or task.user_id != user_id:
            return {"error": "Task not found", "task_id": task_id}

        title = task.title
        session.delete(task)
        session.commit()
        return {
            "task_id": task_id,
            "status": "deleted",
            "title": title,
        }


@mcp.tool()
async def update_task(
    user_id: str,
    task_id: str,
    title: str | None = None,
    description: str | None = None,
) -> dict[str, Any]:
    """Update a task's details.

    Args:
        user_id: The unique identifier of the user.
        task_id: The ID of the task to update.
        title: New title (optional).
        description: New description (optional).

    Returns:
        Dictionary with task_id, status, and title.
    """
    with Session(engine) as session:
        task = session.get(Task, task_id)

        if not task or task.user_id != user_id:
            return {"error": "Task not found", "task_id": task_id}

        if title is not None:
            task.title = title
        if description is not None:
            task.description = description

        session.add(task)
        session.commit()
        return {
            "task_id": str(task.id),
            "status": "updated",
            "title": task.title,
        }


def main():
    """Run the MCP server."""
    port = int(os.environ.get("MCP_SERVER_PORT", "8001"))
    print(f"Starting MCP Server on port {port}...")
    mcp.run(transport="streamable-http", port=port)


if __name__ == "__main__":
    main()
```

### 3. Agent Configuration (Connects to MCP Server)

```python
# app/chat/agent.py
import os
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from agents import Agent, Runner
from agents.mcp import MCPServerStreamableHttp
from dotenv import load_dotenv

load_dotenv()

MCP_SERVER_URL = os.environ.get("MCP_SERVER_URL", "http://localhost:8001/mcp")

INSTRUCTIONS = """You are a friendly todo assistant that helps users manage their tasks.

## What You Can Do
- Add new tasks with titles and descriptions
- List tasks (all, pending, or completed)
- Mark tasks as complete
- Delete tasks
- Update task details

## How to Respond
1. Be friendly and conversational
2. Always confirm actions: "I've added 'X' to your list"
3. Format task lists clearly with IDs
4. If something fails, explain what happened

## Examples
User: "Add buy milk"
You: [call add_task] → "Done! I've added 'buy milk' to your list (Task #3)."

User: "What do I need to do?"
You: [call list_tasks(status="pending")] → "Here are your pending tasks:
- #1: Buy groceries
- #3: Buy milk
Would you like to add anything else?"

User: "Done with task 1"
You: [call complete_task(task_id=1)] → "Nice work! 'Buy groceries' is complete."
"""


@asynccontextmanager
async def create_agent() -> AsyncGenerator[Agent, None]:
    """Create agent connected to MCP server."""
    async with MCPServerStreamableHttp(
        name="Todo MCP Server",
        params={"url": MCP_SERVER_URL},
        cache_tools_list=True,
    ) as mcp_server:
        agent = Agent(
            name="Todo Assistant",
            instructions=INSTRUCTIONS,
            mcp_servers=[mcp_server],
        )
        yield agent
```

### 4. Chat Endpoint (Uses MCP-Connected Agent)

```python
# app/routers/chat.py
import os
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlmodel import Session, select
from agents import Runner
from agents.mcp import MCPServerStreamableHttp

from app.db import get_session
from app.models.chat import Conversation, Message
from app.auth.dependencies import get_current_user

router = APIRouter(prefix="/api/{user_id}", tags=["chat"])

MCP_SERVER_URL = os.environ.get("MCP_SERVER_URL", "http://localhost:8001/mcp")

AGENT_INSTRUCTIONS = """..."""  # Same as above


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
    user_msg = Message(
        conversation_id=conversation.id,
        user_id=user_id,
        role="user",
        content=request.message,
    )
    session.add(user_msg)

    # Run agent with MCP server connection
    async with MCPServerStreamableHttp(
        name="Todo MCP Server",
        params={"url": MCP_SERVER_URL},
    ) as mcp_server:
        from agents import Agent

        agent = Agent(
            name="Todo Assistant",
            instructions=AGENT_INSTRUCTIONS,
            mcp_servers=[mcp_server],
        )
        result = await Runner.run(
            agent,
            input=request.message,
            context={"user_id": user_id},
        )

    # Store assistant response
    assistant_msg = Message(
        conversation_id=conversation.id,
        user_id=user_id,
        role="assistant",
        content=result.final_output,
    )
    session.add(assistant_msg)
    session.commit()

    return ChatResponse(
        conversation_id=conversation.id,
        response=result.final_output,
    )
```

### 5. Running the Application

```bash
# Terminal 1: Start MCP Server
cd backend
python -m app.mcp_server
# Output: Starting MCP Server on port 8001...

# Terminal 2: Start FastAPI Backend
cd backend
uvicorn app.main:app --reload --port 8000
# Output: Uvicorn running on http://127.0.0.1:8000

# Terminal 3: Start Frontend
cd frontend
npm run dev
# Output: ready on http://localhost:3000
```

## BAD: Anti-Patterns to Avoid

### 1. Using @function_tool Instead of MCP Server

```python
# BAD: Not MCP standard, won't follow hackathon requirements
from agents import function_tool, Agent

@function_tool
async def add_task(user_id: str, title: str) -> dict:
    """Add a task."""
    return {"task_id": 1, "status": "created"}

agent = Agent(
    name="Assistant",
    tools=[add_task],  # Direct function reference, NOT MCP!
)
```

```python
# GOOD: Use @mcp.tool() in separate MCP server
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("todo-server")

@mcp.tool()
async def add_task(user_id: str, title: str) -> dict:
    """Add a task."""
    return {"task_id": 1, "status": "created"}

# Then connect agent to MCP server
agent = Agent(
    name="Assistant",
    mcp_servers=[mcp_server],  # MCP protocol connection
)
```

### 2. Hardcoded MCP Server URL

```python
# BAD: Hardcoded URL
async with MCPServerStreamableHttp(
    name="Server",
    params={"url": "http://localhost:8001/mcp"},  # Hardcoded!
) as server:
    ...

# GOOD: Use environment variable
MCP_SERVER_URL = os.environ.get("MCP_SERVER_URL", "http://localhost:8001/mcp")
async with MCPServerStreamableHttp(
    name="Server",
    params={"url": MCP_SERVER_URL},
) as server:
    ...
```

### 3. No Error Handling in MCP Tools

```python
# BAD: Crashes on missing task
@mcp.tool()
async def complete_task(user_id: str, task_id: str) -> dict:
    task = session.get(Task, task_id)
    task.completed = True  # NoneType error if not found!
    return {"status": "done"}

# GOOD: Handle missing resources
@mcp.tool()
async def complete_task(user_id: str, task_id: str) -> dict:
    task = session.get(Task, task_id)
    if not task or task.user_id != user_id:
        return {"error": "Task not found", "task_id": task_id}
    task.completed = True
    return {"status": "completed", "title": task.title}
```

## Comparison: MCP Server vs Function Tools

| Aspect | MCP Server (@mcp.tool) | Function Tools (@function_tool) |
|--------|------------------------|--------------------------------|
| Protocol | MCP Standard | OpenAI-specific |
| Architecture | Separate process | Same process |
| Reusability | Any MCP client | This agent only |
| Hackathon | **REQUIRED** | Not recommended |
| Setup | Two processes | Single process |

## Example Conversation Flow

```
User: "I need to remember to buy groceries"

Agent thinks: User wants to add a task
Agent calls MCP: add_task(user_id="user123", title="Buy groceries")
MCP returns: {"task_id": "5", "status": "created", "title": "Buy groceries"}

Agent responds: "Done! I've added 'Buy groceries' to your list (Task #5).
                Would you like to add any details?"

---

User: "Show me what I need to do"

Agent thinks: User wants to see pending tasks
Agent calls MCP: list_tasks(user_id="user123", status="pending")
MCP returns: {
    "tasks": [
        {"id": "3", "title": "Call mom", "completed": false},
        {"id": "5", "title": "Buy groceries", "completed": false}
    ],
    "count": 2,
    "filter": "pending"
}

Agent responds: "Here are your pending tasks:
                • Task #3: Call mom
                • Task #5: Buy groceries

                Would you like to mark any as complete?"

---

User: "I called mom"

Agent thinks: User completed the "Call mom" task
Agent calls MCP: complete_task(user_id="user123", task_id="3")
MCP returns: {"task_id": "3", "status": "completed", "title": "Call mom"}

Agent responds: "Great job! 'Call mom' is now marked as complete.
                You still have 'Buy groceries' pending."
```

## Testing the Chatbot

```python
# tests/test_chat.py
import pytest
from fastapi.testclient import TestClient

def test_chat_add_task(client: TestClient, auth_headers: dict):
    response = client.post(
        "/api/test-user/chat",
        json={"message": "Add a task to test the chatbot"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert "conversation_id" in data
    assert "added" in data["response"].lower() or "created" in data["response"].lower()


def test_chat_list_tasks(client: TestClient, auth_headers: dict):
    response = client.post(
        "/api/test-user/chat",
        json={"message": "Show my tasks"},
        headers=auth_headers,
    )
    assert response.status_code == 200


def test_chat_unauthorized(client: TestClient, auth_headers: dict):
    response = client.post(
        "/api/other-user/chat",
        json={"message": "Show tasks"},
        headers=auth_headers,
    )
    assert response.status_code == 403
```

## Key Takeaways

1. **Use @mcp.tool() in a standalone MCP server** (mcp-server.py.tpl)
2. **Connect agent to MCP server** using `MCPServerStreamableHttp`
3. **Run MCP server separately** from FastAPI backend
4. **Don't use @function_tool** for hackathon - it's not MCP standard
5. **Handle errors gracefully** in MCP tools
6. **Use environment variables** for configuration
