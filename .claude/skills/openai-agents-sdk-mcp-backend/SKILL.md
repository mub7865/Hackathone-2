---
name: openai-agents-sdk-mcp-backend
description: >
  Patterns for building AI-powered chatbot backends using OpenAI Agents SDK
  with MCP (Model Context Protocol) tools integration in FastAPI applications.
version: 1.0.0
---

# OpenAI Agents SDK + MCP Backend Skill

## When to use this Skill

Use this Skill whenever you are:

- Building an AI-powered chatbot backend using **OpenAI Agents SDK**.
- Creating **MCP tools** that expose application functionality to AI agents.
- Implementing a **chat endpoint** that processes natural language requests.
- Integrating AI agents with existing CRUD operations via MCP.
- Building stateless conversation systems with database-backed history.

This Skill works for any FastAPI application that needs AI agent capabilities
with tool-calling functionality.

## Core goals

- Build **production-ready AI chatbot backends** with proper error handling.
- Create **reusable MCP tools** that wrap existing business logic.
- Maintain **stateless architecture** where conversation state is stored in DB.
- Follow **consistent patterns** for agent configuration and tool definition.
- Enable **natural language interfaces** for application functionality.

## Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| AI Framework | OpenAI Agents SDK | `openai-agents>=0.6.0` |
| MCP Server | Official MCP SDK | `mcp[cli]>=1.0.0` |
| Web Framework | FastAPI | `>=0.115.0` |
| Database ORM | SQLModel | `>=0.0.22` |
| Async HTTP | httpx | `>=0.27.0` |

## Installation

```bash
# Using pip
pip install openai-agents "mcp[cli]" fastapi sqlmodel httpx

# Using uv
uv add openai-agents "mcp[cli]" fastapi sqlmodel httpx
```

Required environment variables:
```bash
# For OpenAI (default)
OPENAI_API_KEY=sk-your-api-key-here

# For Gemini (alternative)
GEMINI_API_KEY=your-gemini-api-key-here

DATABASE_URL=postgresql://user:pass@host/db
```

## LLM Provider Configuration

The OpenAI Agents SDK supports multiple LLM providers. You can use OpenAI,
Gemini, or any OpenAI-compatible API.

### Option 1: OpenAI (Default)

```python
from agents import Agent, Runner
import os

# Uses OPENAI_API_KEY environment variable automatically
agent = Agent(
    name="Todo Assistant",
    instructions="Help users manage tasks.",
    tools=[add_task, list_tasks],
)

result = await Runner.run(agent, "Show my tasks")
```

### Option 2: Google Gemini

```python
from openai import AsyncOpenAI
from agents import Agent, OpenAIChatCompletionsModel, Runner, set_tracing_disabled
import os

# Configure Gemini client
# Reference: https://ai.google.dev/gemini-api/docs/openai
gemini_client = AsyncOpenAI(
    api_key=os.environ["GEMINI_API_KEY"],
    base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
)

# Disable tracing for non-OpenAI providers
set_tracing_disabled(disabled=True)

# Create agent with Gemini model
agent = Agent(
    name="Todo Assistant",
    instructions="Help users manage tasks.",
    model=OpenAIChatCompletionsModel(
        model="gemini-2.0-flash",  # or "gemini-1.5-pro", "gemini-1.5-flash"
        openai_client=gemini_client,
    ),
    tools=[add_task, list_tasks],
)

result = await Runner.run(agent, "Show my tasks")
```

### Option 3: Other OpenAI-Compatible Providers

```python
from openai import AsyncOpenAI
from agents import Agent, OpenAIChatCompletionsModel

# Configure any OpenAI-compatible provider
custom_client = AsyncOpenAI(
    api_key=os.environ["CUSTOM_API_KEY"],
    base_url="https://your-provider.com/v1/",
)

agent = Agent(
    name="Todo Assistant",
    instructions="Help users manage tasks.",
    model=OpenAIChatCompletionsModel(
        model="your-model-name",
        openai_client=custom_client,
    ),
    tools=[add_task, list_tasks],
)
```

### Supported Gemini Models

| Model | Context Window | Best For |
|-------|----------------|----------|
| `gemini-2.0-flash` | 1M tokens | Fast responses, general use |
| `gemini-1.5-pro` | 2M tokens | Complex tasks, long context |
| `gemini-1.5-flash` | 1M tokens | Balance of speed and quality |

### Conversation History Recommendations

Based on context window size:

| Provider | Model | Recommended History |
|----------|-------|---------------------|
| OpenAI | GPT-4o | 50-100 messages |
| OpenAI | GPT-4o-mini | 50-100 messages |
| Google | Gemini 2.0 Flash | 100-200 messages |
| Google | Gemini 1.5 Pro | 200+ messages |

## Architecture Overview

```
┌─────────────────┐     ┌──────────────────────────────────────────────┐
│                 │     │              FastAPI Server                   │
│  Client         │     │  ┌────────────────────────────────────────┐  │
│  (ChatKit UI)   │────►│  │  POST /api/{user_id}/chat              │  │
│                 │     │  └───────────────┬────────────────────────┘  │
│                 │     │                  │                           │
│                 │     │                  ▼                           │
│                 │     │  ┌────────────────────────────────────────┐  │
│                 │◄────│  │      OpenAI Agents SDK                 │  │
│                 │     │  │      (Agent + Runner)                  │  │
│                 │     │  └───────────────┬────────────────────────┘  │
│                 │     │                  │                           │
│                 │     │                  ▼                           │
│                 │     │  ┌────────────────────────────────────────┐  │
│                 │     │  │         MCP Tools                      │  │──► Database
│                 │     │  │  (add_task, list_tasks, etc.)          │  │
│                 │     │  └────────────────────────────────────────┘  │
└─────────────────┘     └──────────────────────────────────────────────┘
```

## Core Concepts

### 1. Agent Definition

An Agent is an LLM configured with instructions and tools:

```python
from agents import Agent

agent = Agent(
    name="Todo Assistant",
    instructions="""You are a helpful todo assistant.
    Help users manage their tasks using natural language.
    Always confirm actions with friendly responses.""",
    tools=[add_task, list_tasks, complete_task, delete_task, update_task],
)
```

### 2. Function Tools (@function_tool)

Tools are Python functions that the agent can call:

```python
from agents import function_tool

@function_tool
def add_task(user_id: str, title: str, description: str = "") -> dict:
    """Add a new task for the user.

    Args:
        user_id: The user's unique identifier.
        title: The title of the task.
        description: Optional description of the task.

    Returns:
        Dictionary with task_id, status, and title.
    """
    # Implementation here
    return {"task_id": 1, "status": "created", "title": title}
```

Key points:
- Use `@function_tool` decorator to convert functions to tools.
- Docstrings are parsed for tool descriptions (Google, Sphinx, NumPy formats).
- Type annotations generate JSON schemas automatically.
- Functions can be sync or async.

### 3. Running Agents

Use Runner to execute agents:

```python
from agents import Runner

# Async execution (recommended)
result = await Runner.run(agent, input="Add a task to buy groceries")
print(result.final_output)

# Sync execution (for simple cases)
result = Runner.run_sync(agent, input="Show my tasks")
print(result.final_output)
```

### 4. Session Management

For conversation history across runs:

```python
from agents import SQLiteSession

# Create or resume a session
session = SQLiteSession(f"conversation_{user_id}_{conversation_id}")

# Run agent with session context
result = await Runner.run(
    agent,
    input=user_message,
    session=session,
)
```

## MCP Server Integration

### Option 1: Function Tools (Recommended for Simple Cases)

Use `@function_tool` directly in your FastAPI app:

```python
from agents import Agent, function_tool

@function_tool
async def add_task(user_id: str, title: str) -> dict:
    """Add a new task."""
    async with get_session() as session:
        task = Task(user_id=user_id, title=title)
        session.add(task)
        await session.commit()
        return {"task_id": task.id, "status": "created"}

agent = Agent(name="Assistant", tools=[add_task])
```

### Option 2: MCP Server (For Complex/Shared Tools)

Create a standalone MCP server:

```python
# mcp_server.py
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("Todo MCP Server")

@mcp.tool()
def add_task(user_id: str, title: str, description: str = "") -> dict:
    """Add a new task for the user."""
    # Database operation
    return {"task_id": 1, "status": "created", "title": title}

@mcp.tool()
def list_tasks(user_id: str, status: str = "all") -> list:
    """List tasks for the user."""
    return [{"id": 1, "title": "Example", "completed": False}]

if __name__ == "__main__":
    mcp.run(transport="streamable-http")
```

Connect agent to MCP server:

```python
from agents import Agent, Runner
from agents.mcp import MCPServerStreamableHttp

async with MCPServerStreamableHttp(
    name="Todo MCP",
    params={"url": "http://localhost:8001/mcp"},
) as mcp_server:
    agent = Agent(
        name="Todo Assistant",
        instructions="Help users manage tasks.",
        mcp_servers=[mcp_server],
    )
    result = await Runner.run(agent, "Add task: buy groceries")
```

## Database Models for Chat

### Conversation Model

```python
from sqlmodel import SQLModel, Field
from datetime import datetime
from typing import Optional

class Conversation(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: str = Field(index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
```

### Message Model

```python
class Message(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    conversation_id: int = Field(foreign_key="conversation.id", index=True)
    user_id: str = Field(index=True)
    role: str  # "user" or "assistant"
    content: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
```

## Chat Endpoint Pattern

### Request/Response Schemas

```python
from pydantic import BaseModel
from typing import Optional, List

class ChatRequest(BaseModel):
    message: str
    conversation_id: Optional[int] = None

class ToolCall(BaseModel):
    name: str
    arguments: dict
    result: dict

class ChatResponse(BaseModel):
    conversation_id: int
    response: str
    tool_calls: List[ToolCall] = []
```

### Chat Router Implementation

```python
from fastapi import APIRouter, Depends, HTTPException
from agents import Agent, Runner

router = APIRouter(prefix="/api/{user_id}", tags=["chat"])

@router.post("/chat", response_model=ChatResponse)
async def chat(
    user_id: str,
    request: ChatRequest,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    # 1. Verify user authorization
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    # 2. Get or create conversation
    conversation = await get_or_create_conversation(
        session, user_id, request.conversation_id
    )

    # 3. Fetch conversation history
    history = await get_conversation_history(session, conversation.id)

    # 4. Store user message
    await store_message(session, conversation.id, user_id, "user", request.message)

    # 5. Run agent
    result = await Runner.run(
        agent,
        input=request.message,
        context={"user_id": user_id, "history": history},
    )

    # 6. Store assistant response
    await store_message(
        session, conversation.id, user_id, "assistant", result.final_output
    )

    # 7. Return response
    return ChatResponse(
        conversation_id=conversation.id,
        response=result.final_output,
        tool_calls=extract_tool_calls(result),
    )
```

## Agent Instructions Best Practices

### Good Instructions

```python
instructions = """You are a helpful todo assistant for managing tasks.

CAPABILITIES:
- Add new tasks with titles and descriptions
- List all tasks, pending tasks, or completed tasks
- Mark tasks as complete
- Delete tasks
- Update task details

BEHAVIOR:
- Always confirm actions with a friendly message
- When listing tasks, format them clearly with IDs
- If a task is not found, explain politely
- Ask for clarification if the request is ambiguous

EXAMPLES:
- "Add a task" -> Ask for the task title
- "Show my tasks" -> Use list_tasks with status="all"
- "Mark task 3 done" -> Use complete_task with task_id=3
"""
```

### Bad Instructions

```python
# Too vague
instructions = "Help with tasks"

# No context about tools
instructions = "You are an assistant"

# Missing behavior guidelines
instructions = "Manage todos"
```

## Error Handling

### Tool-Level Errors

```python
@function_tool
def complete_task(user_id: str, task_id: int) -> dict:
    """Mark a task as complete."""
    task = get_task(user_id, task_id)
    if not task:
        return {"error": "Task not found", "task_id": task_id}

    task.completed = True
    save_task(task)
    return {"task_id": task_id, "status": "completed", "title": task.title}
```

### Endpoint-Level Errors

```python
@router.post("/chat")
async def chat(user_id: str, request: ChatRequest):
    try:
        result = await Runner.run(agent, input=request.message)
        return ChatResponse(response=result.final_output)
    except Exception as e:
        logger.error(f"Agent error: {e}")
        raise HTTPException(
            status_code=500,
            detail="Failed to process your request. Please try again."
        )
```

## Testing Patterns

### Unit Testing Tools

```python
import pytest
from your_app.tools import add_task, list_tasks

@pytest.mark.asyncio
async def test_add_task():
    result = await add_task(user_id="test-user", title="Test Task")
    assert result["status"] == "created"
    assert result["title"] == "Test Task"

@pytest.mark.asyncio
async def test_list_tasks():
    result = await list_tasks(user_id="test-user", status="all")
    assert isinstance(result, list)
```

### Integration Testing Chat

```python
from fastapi.testclient import TestClient

def test_chat_endpoint(client: TestClient, auth_headers: dict):
    response = client.post(
        "/api/test-user/chat",
        json={"message": "Add a task to buy groceries"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert "conversation_id" in data
    assert "response" in data
```

## Things to Avoid

- **Hardcoding API keys** - Always use environment variables.
- **Ignoring rate limits** - Implement retry logic with backoff.
- **Unbounded history** - Limit conversation history length.
- **Missing error handling** - Always handle tool and agent failures.
- **Blocking operations** - Use async patterns for database and API calls.
- **Vague agent instructions** - Be specific about capabilities and behavior.

## References

- [OpenAI Agents SDK Documentation](https://openai.github.io/openai-agents-python/)
- [OpenAI Agents SDK GitHub](https://github.com/openai/openai-agents-python)
- [MCP Python SDK GitHub](https://github.com/modelcontextprotocol/python-sdk)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
