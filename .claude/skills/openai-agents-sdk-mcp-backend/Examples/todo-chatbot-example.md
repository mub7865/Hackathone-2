# Todo Chatbot Example

This example demonstrates a complete AI-powered todo chatbot implementation
using OpenAI Agents SDK with MCP tools.

## Architecture Overview

```
┌─────────────────┐     ┌──────────────────────────────────────────────┐
│                 │     │              FastAPI Backend                  │
│  ChatKit UI     │     │                                              │
│  (Frontend)     │────►│  POST /api/{user_id}/chat                    │
│                 │     │         │                                    │
│                 │     │         ▼                                    │
│                 │     │  ┌─────────────────────┐                     │
│                 │◄────│  │  OpenAI Agent       │                     │
│                 │     │  │  "Todo Assistant"   │                     │
│                 │     │  └─────────┬───────────┘                     │
│                 │     │            │                                 │
│                 │     │            ▼                                 │
│                 │     │  ┌─────────────────────┐     ┌────────────┐  │
│                 │     │  │  MCP Tools          │────►│  Neon DB   │  │
│                 │     │  │  - add_task         │◄────│            │  │
│                 │     │  │  - list_tasks       │     │  - tasks   │  │
│                 │     │  │  - complete_task    │     │  - convos  │  │
│                 │     │  │  - delete_task      │     │  - messages│  │
│                 │     │  │  - update_task      │     └────────────┘  │
│                 │     │  └─────────────────────┘                     │
└─────────────────┘     └──────────────────────────────────────────────┘
```

## GOOD: Structured Implementation

### 1. Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app entry
│   ├── db.py                # Database configuration
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
│       ├── agent.py         # Agent configuration
│       └── tools.py         # MCP tools
├── pyproject.toml
└── .env
```

### 2. MCP Tools Implementation

```python
# app/chat/tools.py
from typing import List, Optional
from agents import function_tool
from sqlmodel import Session, select
from app.db import engine
from app.models.task import Task


@function_tool
async def add_task(
    user_id: str,
    title: str,
    description: str = "",
) -> dict:
    """Add a new task for the user.

    Args:
        user_id: The user's unique identifier.
        title: The title of the task.
        description: Optional description.

    Returns:
        Dictionary with task_id, status, and title.
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
            "task_id": task.id,
            "status": "created",
            "title": task.title,
        }


@function_tool
async def list_tasks(
    user_id: str,
    status: str = "all",
) -> List[dict]:
    """List tasks for the user.

    Args:
        user_id: The user's unique identifier.
        status: Filter - "all", "pending", or "completed".

    Returns:
        List of task dictionaries.
    """
    with Session(engine) as session:
        query = select(Task).where(Task.user_id == user_id)

        if status == "pending":
            query = query.where(Task.completed == False)
        elif status == "completed":
            query = query.where(Task.completed == True)

        tasks = session.exec(query).all()
        return [
            {
                "id": task.id,
                "title": task.title,
                "description": task.description or "",
                "completed": task.completed,
            }
            for task in tasks
        ]


@function_tool
async def complete_task(user_id: str, task_id: int) -> dict:
    """Mark a task as complete.

    Args:
        user_id: The user's unique identifier.
        task_id: The ID of the task to complete.

    Returns:
        Dictionary with task_id, status, and title.
    """
    with Session(engine) as session:
        task = session.get(Task, task_id)

        if not task or task.user_id != user_id:
            return {
                "task_id": task_id,
                "status": "error",
                "error": "Task not found",
            }

        task.completed = True
        session.add(task)
        session.commit()
        return {
            "task_id": task.id,
            "status": "completed",
            "title": task.title,
        }


@function_tool
async def delete_task(user_id: str, task_id: int) -> dict:
    """Delete a task.

    Args:
        user_id: The user's unique identifier.
        task_id: The ID of the task to delete.

    Returns:
        Dictionary with task_id, status, and title.
    """
    with Session(engine) as session:
        task = session.get(Task, task_id)

        if not task or task.user_id != user_id:
            return {
                "task_id": task_id,
                "status": "error",
                "error": "Task not found",
            }

        title = task.title
        session.delete(task)
        session.commit()
        return {
            "task_id": task_id,
            "status": "deleted",
            "title": title,
        }


@function_tool
async def update_task(
    user_id: str,
    task_id: int,
    title: Optional[str] = None,
    description: Optional[str] = None,
) -> dict:
    """Update a task's details.

    Args:
        user_id: The user's unique identifier.
        task_id: The ID of the task to update.
        title: New title (optional).
        description: New description (optional).

    Returns:
        Dictionary with task_id, status, and title.
    """
    with Session(engine) as session:
        task = session.get(Task, task_id)

        if not task or task.user_id != user_id:
            return {
                "task_id": task_id,
                "status": "error",
                "error": "Task not found",
            }

        if title is not None:
            task.title = title
        if description is not None:
            task.description = description

        session.add(task)
        session.commit()
        return {
            "task_id": task.id,
            "status": "updated",
            "title": task.title,
        }
```

### 3. Agent Configuration

```python
# app/chat/agent.py
from agents import Agent
from app.chat.tools import (
    add_task,
    list_tasks,
    complete_task,
    delete_task,
    update_task,
)

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

agent = Agent(
    name="Todo Assistant",
    instructions=INSTRUCTIONS,
    tools=[add_task, list_tasks, complete_task, delete_task, update_task],
)
```

### 4. Chat Endpoint

```python
# app/routers/chat.py
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, List
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

    # Get history
    history = session.exec(
        select(Message)
        .where(Message.conversation_id == conversation.id)
        .order_by(Message.created_at)
    ).all()

    # Store user message
    user_msg = Message(
        conversation_id=conversation.id,
        user_id=user_id,
        role="user",
        content=request.message,
    )
    session.add(user_msg)

    # Run agent
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

## BAD: Anti-Patterns to Avoid

### 1. Hardcoded API Keys

```python
# BAD: Never do this!
from openai import OpenAI
client = OpenAI(api_key="sk-1234567890abcdef")

# GOOD: Use environment variables
import os
from openai import OpenAI
client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
```

### 2. No Error Handling in Tools

```python
# BAD: Crashes on missing task
@function_tool
def complete_task(task_id: int) -> dict:
    task = session.get(Task, task_id)
    task.completed = True  # NoneType error if task doesn't exist!
    return {"status": "done"}

# GOOD: Handle missing resources
@function_tool
def complete_task(user_id: str, task_id: int) -> dict:
    task = session.get(Task, task_id)
    if not task or task.user_id != user_id:
        return {"status": "error", "error": "Task not found"}
    task.completed = True
    return {"status": "completed", "title": task.title}
```

### 3. Vague Agent Instructions

```python
# BAD: Agent doesn't know what to do
agent = Agent(
    name="Assistant",
    instructions="Help with tasks",
    tools=[add_task],
)

# GOOD: Clear, specific instructions
agent = Agent(
    name="Todo Assistant",
    instructions="""You help users manage tasks.

    When user says "add X" → use add_task(title=X)
    When user asks "what do I need to do" → use list_tasks(status="pending")
    Always confirm actions with friendly messages.""",
    tools=[add_task, list_tasks],
)
```

### 4. Missing User Authorization

```python
# BAD: Anyone can access any user's tasks
@function_tool
def list_tasks(user_id: str) -> list:
    return get_all_tasks(user_id)  # No verification!

# GOOD: Verify in endpoint, pass validated user_id
@router.post("/chat")
async def chat(user_id: str, current_user = Depends(get_current_user)):
    if current_user.id != user_id:
        raise HTTPException(status_code=403)
    # Now user_id is verified
```

## Example Conversation Flow

```
User: "I need to remember to buy groceries"

Agent thinks: User wants to add a task
Agent calls: add_task(user_id="user123", title="Buy groceries")
Tool returns: {"task_id": 5, "status": "created", "title": "Buy groceries"}

Agent responds: "Done! I've added 'Buy groceries' to your list (Task #5).
                Would you like to add any details?"

---

User: "Show me what I need to do"

Agent thinks: User wants to see pending tasks
Agent calls: list_tasks(user_id="user123", status="pending")
Tool returns: [
    {"id": 3, "title": "Call mom", "completed": false},
    {"id": 5, "title": "Buy groceries", "completed": false}
]

Agent responds: "Here are your pending tasks:
                • Task #3: Call mom
                • Task #5: Buy groceries

                Would you like to mark any as complete?"

---

User: "I called mom"

Agent thinks: User completed the "Call mom" task
Agent calls: complete_task(user_id="user123", task_id=3)
Tool returns: {"task_id": 3, "status": "completed", "title": "Call mom"}

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
