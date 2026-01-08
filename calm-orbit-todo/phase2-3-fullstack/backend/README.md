# Phase II-III: FastAPI Backend

## Overview
Full-stack web application backend with AI chatbot and MCP server.

## Features

### Phase II Features
- RESTful API with FastAPI
- SQLModel ORM
- Neon PostgreSQL database
- JWT authentication
- User isolation

### Phase III Features
- OpenAI Agents SDK integration
- Official MCP SDK server
- Natural language processing
- Stateless chat endpoint
- Conversation persistence

## Technology Stack
- Python 3.13+
- FastAPI
- SQLModel
- Neon Serverless PostgreSQL
- OpenAI Agents SDK
- Official MCP SDK

## Setup

```bash
cd phase2-3-fullstack-backend
pip install -r requirements.txt
```

## Environment Variables

Create `.env`:
```env
# Database Configuration
DATABASE_URL=postgresql://user:pass@host.neon.tech/db?sslmode=require

# Authentication
BETTER_AUTH_SECRET=your-secret-key-here-min-32-chars
JWT_SECRET=your-legacy-jwt-secret-key

# OpenAI Configuration
OPENAI_API_KEY=sk-proj-...

# Feature Flags
FEATURE_NEW_AUTH=false
FEATURE_NEW_CHAT=false
AUTH_MIGRATION_ENABLED=true
ENABLE_LEGACY_TOKENS=true
```

## Running

```bash
uvicorn app.main:app --reload
```

Access at: http://localhost:8000

## API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Database Migrations

```bash
# Create migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head
```

## MCP Server

The MCP server is mounted at `/mcp` endpoint and provides tools for:
- add_task
- list_tasks
- complete_task
- delete_task
- update_task

## Project Structure

```
phase2-3-fullstack-backend/
├── app/
│   ├── api/               # API routes
│   │   └── v1/           # API version 1
│   ├── core/             # Core functionality
│   ├── models/           # SQLModel database models
│   ├── schemas/          # Pydantic schemas
│   └── services/         # Business logic
│       ├── agent.py      # OpenAI Agents SDK
│       ├── mcp_server.py # MCP server
│       └── mcp_tools.py  # MCP tools
├── alembic/              # Database migrations
└── tests/                # Test suite
```
