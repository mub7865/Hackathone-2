# Skill: openai-agents-sdk-mcp-backend

## Purpose

This Skill teaches Claude how to build AI-powered chatbot backends using
**OpenAI Agents SDK** with **MCP (Model Context Protocol)** server integration.

It standardizes:

- How to create **standalone MCP servers** using the Official MCP Python SDK.
- How to configure AI agents to connect to MCP servers.
- How to define MCP tools using `@mcp.tool()` decorator.
- How to implement chat endpoints with conversation history.
- How to integrate agents with existing FastAPI applications.
- How to handle errors and test AI agent functionality.

The goal is to provide a consistent, production-ready pattern for building
conversational AI interfaces that can manage application functionality
through natural language.

## Two Approaches

This skill covers two approaches for providing tools to AI agents:

### 1. Standalone MCP Server (RECOMMENDED)

Create a separate MCP server using the **Official MCP Python SDK** that exposes
tools via the MCP protocol. This is the **hackathon-recommended approach**.

```
┌─────────────────┐     ┌────────────────────┐     ┌─────────────────────┐
│  ChatKit UI     │────►│  FastAPI Backend   │────►│  MCP Server         │
│                 │     │  POST /api/chat    │     │  @mcp.tool()        │
│                 │◄────│  OpenAI Agent      │◄────│  - add_task         │
└─────────────────┘     └────────────────────┘     └─────────────────────┘
```

**Advantages:**
- Follows the official MCP protocol specification
- Tools are reusable by any MCP-compatible client
- Clean separation between server and client
- Industry standard approach

### 2. Function Tools (Simpler but not MCP standard)

Define tools as Python functions decorated with `@function_tool` directly
in your FastAPI application.

```
┌─────────────────┐     ┌────────────────────────────────────────────┐
│  ChatKit UI     │────►│  FastAPI Backend                           │
│                 │     │  OpenAI Agent + Function Tools             │
│                 │◄────│  @function_tool                            │
└─────────────────┘     └────────────────────────────────────────────┘
```

**Advantages:**
- Simpler setup
- Good for quick prototypes

**Disadvantages:**
- Not following official MCP protocol
- Tools are not reusable

## What this Skill defines

- **SKILL.md** - Rules and patterns for:
  - Creating standalone MCP servers with `@mcp.tool()` decorator
  - Setting up OpenAI Agents SDK with MCP server connections
  - Creating agents with clear instructions and tools
  - Building chat endpoints with conversation persistence
  - Error handling and testing strategies

- **Templates/**
  - `mcp-server.py.tpl`
    Standalone MCP server template:
    - Uses Official MCP Python SDK (`mcp[cli]`)
    - Defines tools with `@mcp.tool()` decorator
    - Proper docstrings for automatic schema generation
    - HTTP transport for agent connection

  - `agent-config.py.tpl`
    Agent configuration module:
    - Connects to MCP server using `MCPServerStreamableHttp`
    - Configures agent with instructions
    - Sets up model settings and behavior

  - `mcp-tools.py.tpl` (ALTERNATIVE)
    Function tools definition template:
    - Uses `@function_tool` decorator (not MCP standard)
    - For simpler setups or prototypes

  - `chat-router.fastapi.py.tpl`
    Chat endpoint router:
    - POST /api/{user_id}/chat endpoint
    - MCP server connection in endpoint
    - Conversation history management
    - JWT authentication integration

  - `chat-models.sqlmodel.py.tpl`
    Database models for chat:
    - Conversation model for chat sessions
    - Message model for chat history
    - Proper indexes and relationships

- **Examples/**
  - `todo-chatbot-example.md`
    Complete example showing:
    - MCP server implementation with all 5 tools
    - Agent configuration with MCP server connection
    - Full chat flow from request to response

## When to enable this Skill

Enable this Skill in any backend project where:

- You need to build an **AI chatbot** using OpenAI Agents SDK.
- You want to create a **standalone MCP server** (hackathon requirement).
- You want to expose application functionality via **natural language**.
- You need to implement **MCP tools** for agent tool-calling.
- You want to maintain **conversation history** across chat sessions.
- You're building on top of an existing **FastAPI + SQLModel** application.

## How to integrate in a project

### For Proper MCP Server (Recommended)

1. Install dependencies:
   ```bash
   pip install openai-agents "mcp[cli]" httpx
   # or
   uv add openai-agents "mcp[cli]" httpx
   ```

2. Set environment variables:
   ```bash
   export OPENAI_API_KEY=sk-your-key
   ```

3. Create MCP server (e.g. `app/mcp_server.py`) from
   `mcp-server.py.tpl`:
   - Define tools with `@mcp.tool()` decorator
   - Each tool should have clear docstrings and type hints
   - Configure HTTP transport

4. Create agent configuration (e.g. `app/chat/agent.py`) from
   `agent-config.py.tpl`:
   - Connect to MCP server using `MCPServerStreamableHttp`
   - Configure agent with appropriate instructions

5. Add chat models (e.g. `app/models/chat.py`) from
   `chat-models.sqlmodel.py.tpl`:
   - Conversation and Message models
   - Run database migrations

6. Create chat router (e.g. `app/routers/chat.py`) from
   `chat-router.fastapi.py.tpl`:
   - Implement POST /api/{user_id}/chat endpoint
   - Connect to MCP server in endpoint
   - Handle conversation creation and history

7. Run MCP server separately:
   ```bash
   python app/mcp_server.py  # Runs on port 8001
   ```

8. Register the chat router in your main.py FastAPI app.

### For Function Tools (Simpler but not MCP standard)

Use `mcp-tools.py.tpl` with `@function_tool` decorator instead of
creating a separate MCP server. Not recommended for hackathon.

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `openai-agents` | AI agent framework with MCP support |
| `mcp[cli]` | Official MCP Python SDK |
| `httpx` | Async HTTP client for API calls |
| `fastapi` | Web framework |
| `sqlmodel` | Database ORM |

## Key Differences from Previous Version

| Aspect | v1.0 (Old) | v2.0 (New) |
|--------|------------|------------|
| Tool Definition | `@function_tool` only | `@mcp.tool()` (recommended) |
| Architecture | Single process | Separate MCP server |
| Standard | OpenAI-specific | MCP Protocol |
| Reusability | Agent-specific | Any MCP client |

## Related Skills

- `fastapi-sqlmodel-crud-patterns` - For the underlying CRUD operations.
- `fastapi-auth-jwt-backend-verification` - For JWT authentication.
- `postgres-neon-connection-and-migrations` - For database setup.

## References

- [MCP Protocol Introduction](https://modelcontextprotocol.io/docs/getting-started/intro)
- [Build MCP Server](https://modelcontextprotocol.io/docs/develop/build-server)
- [MCP Python SDK GitHub](https://github.com/modelcontextprotocol/python-sdk)
- [OpenAI Agents SDK - MCP Integration](https://openai.github.io/openai-agents-python/mcp/)
