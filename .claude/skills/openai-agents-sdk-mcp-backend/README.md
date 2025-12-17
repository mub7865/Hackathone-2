# Skill: openai-agents-sdk-mcp-backend

## Purpose

This Skill teaches Claude how to build AI-powered chatbot backends using
**OpenAI Agents SDK** with **MCP (Model Context Protocol)** tools integration.

It standardizes:

- How to create and configure AI agents with tools.
- How to define MCP tools using `@function_tool` decorator.
- How to implement chat endpoints with conversation history.
- How to integrate agents with existing FastAPI applications.
- How to handle errors and test AI agent functionality.

The goal is to provide a consistent, production-ready pattern for building
conversational AI interfaces that can manage application functionality
through natural language.

## What this Skill defines

- **SKILL.md** - Rules and patterns for:
  - Setting up OpenAI Agents SDK with proper configuration.
  - Creating agents with clear instructions and tools.
  - Defining function tools with proper type hints and docstrings.
  - Building chat endpoints with conversation persistence.
  - Integrating MCP servers for complex tool scenarios.
  - Error handling and testing strategies.

- **Templates/**
  - `agent-config.py.tpl`
    Standard agent configuration module:
    - Creates agent with instructions and tools.
    - Configures model settings and behavior.
    - Sets up tool filtering if needed.

  - `mcp-tools.py.tpl`
    MCP tools definition template:
    - Defines function tools for CRUD operations.
    - Proper docstrings for automatic schema generation.
    - Error handling patterns for tool failures.

  - `chat-router.fastapi.py.tpl`
    Chat endpoint router:
    - POST /api/{user_id}/chat endpoint.
    - Conversation history management.
    - Message storage and retrieval.
    - JWT authentication integration.

  - `chat-models.sqlmodel.py.tpl`
    Database models for chat:
    - Conversation model for chat sessions.
    - Message model for chat history.
    - Proper indexes and relationships.

- **Examples/**
  - `todo-chatbot-example.md`
    Complete example showing:
    - Todo-specific MCP tools implementation.
    - Agent instructions for task management.
    - Full chat flow from request to response.

## When to enable this Skill

Enable this Skill in any backend project where:

- You need to build an **AI chatbot** using OpenAI Agents SDK.
- You want to expose application functionality via **natural language**.
- You need to implement **MCP tools** for agent tool-calling.
- You want to maintain **conversation history** across chat sessions.
- You're building on top of an existing **FastAPI + SQLModel** application.

## How to integrate in a project

Typical integration steps:

1. Install dependencies:
   ```bash
   pip install openai-agents "mcp[cli]" httpx
   ```

2. Set environment variables:
   ```bash
   export OPENAI_API_KEY=sk-your-key
   ```

3. Create MCP tools module (e.g. `app/chat/tools.py`) from
   `mcp-tools.py.tpl`:
   - Define tools for your domain (tasks, orders, etc.).
   - Each tool should have clear docstrings and type hints.

4. Create agent configuration (e.g. `app/chat/agent.py`) from
   `agent-config.py.tpl`:
   - Configure agent with appropriate instructions.
   - Register all MCP tools.

5. Add chat models (e.g. `app/models/chat.py`) from
   `chat-models.sqlmodel.py.tpl`:
   - Conversation and Message models.
   - Run database migrations.

6. Create chat router (e.g. `app/routers/chat.py`) from
   `chat-router.fastapi.py.tpl`:
   - Implement POST /api/{user_id}/chat endpoint.
   - Handle conversation creation and history.

7. Register the router in your main.py FastAPI app.

After this, Claude should consistently generate AI chatbot code that matches
the same structure, making your conversational AI features easier to
maintain and extend.

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `openai-agents` | AI agent framework with tool support |
| `mcp[cli]` | Model Context Protocol SDK |
| `httpx` | Async HTTP client for API calls |
| `fastapi` | Web framework |
| `sqlmodel` | Database ORM |

## Related Skills

- `fastapi-sqlmodel-crud-patterns` - For the underlying CRUD operations.
- `fastapi-auth-jwt-backend-verification` - For JWT authentication.
- `postgres-neon-connection-and-migrations` - For database setup.
