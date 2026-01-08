# Phase II-III: Full-Stack Web Application with AI Chatbot

## Overview
This phase combines the full-stack web application (Phase II) with AI chatbot capabilities (Phase III) in a unified codebase.

## Structure

```
phase2-3-fullstack/
├── frontend/          # Next.js 16 frontend application
└── backend/           # FastAPI backend with AI chatbot
```

## Phase II Features
- User authentication (Better Auth)
- Task CRUD operations
- Responsive UI with Tailwind CSS
- Real-time updates
- Neon PostgreSQL database

## Phase III Features
- OpenAI ChatKit integration
- OpenAI Agents SDK
- Official MCP SDK server
- Natural language task management
- Conversational interface

## Technology Stack

### Frontend
- Next.js 16 (App Router)
- TypeScript
- Tailwind CSS
- Better Auth
- OpenAI ChatKit

### Backend
- Python 3.13+
- FastAPI
- SQLModel
- OpenAI Agents SDK
- Official MCP SDK
- Neon Serverless PostgreSQL

## Quick Start

### Frontend
```bash
cd frontend
npm install
npm run dev
```
Access: http://localhost:3000

### Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```
Access: http://localhost:8000

## Environment Configuration

### Frontend (.env.local)
```env
NEXT_PUBLIC_API_URL=http://localhost:8000
BETTER_AUTH_SECRET=your-secret-key-here-min-32-chars
DATABASE_URL=postgresql://user:pass@host:5432/db

# Feature Flags
NEXT_PUBLIC_FEATURE_NEW_AUTH=false
NEXT_PUBLIC_FEATURE_NEW_CHAT=false
```

### Backend (.env)
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

## API Documentation

When backend is running:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Features

### Basic Level (Phase II)
- ✅ Add Task
- ✅ Delete Task
- ✅ Update Task
- ✅ View Task List
- ✅ Mark as Complete

### AI Chatbot (Phase III)
- ✅ Natural language task management
- ✅ Conversational interface
- ✅ MCP tools integration
- ✅ Stateless architecture

## Feature Flags

### Enable Better Auth
```env
# Backend
FEATURE_NEW_AUTH=true

# Frontend
NEXT_PUBLIC_FEATURE_NEW_AUTH=true
```

### Enable ChatKit
```env
# Backend
FEATURE_NEW_CHAT=true

# Frontend
NEXT_PUBLIC_FEATURE_NEW_CHAT=true
```

## Testing

### Backend Tests
```bash
cd backend
pytest tests/
```

### Frontend Tests
```bash
cd frontend
npm test
```

## Database Migrations

```bash
cd backend

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

## Documentation

- Frontend README: `frontend/README.md`
- Backend README: `backend/README.md`
- API Documentation: http://localhost:8000/docs

## Architecture

```
┌─────────────────┐     ┌──────────────────────────────────────────────┐     ┌─────────────────┐
│                 │     │              FastAPI Server                   │     │                 │
│                 │     │  ┌────────────────────────────────────────┐  │     │                 │
│  Next.js        │────▶│  │         Chat Endpoint                  │  │     │    Neon DB      │
│  Frontend       │     │  │  POST /api/v1/chat                     │  │     │  (PostgreSQL)   │
│                 │     │  └───────────────┬────────────────────────┘  │     │                 │
│                 │     │                  │                           │     │  - tasks        │
│                 │     │                  ▼                           │     │  - conversations│
│                 │     │  ┌────────────────────────────────────────┐  │     │  - messages     │
│                 │◀────│  │      OpenAI Agents SDK                 │  │     │                 │
│                 │     │  │      (Agent + Runner)                  │  │     │                 │
│                 │     │  └───────────────┬────────────────────────┘  │     │                 │
│                 │     │                  │                           │     │                 │
│                 │     │                  ▼                           │     │                 │
│                 │     │  ┌────────────────────────────────────────┐  │────▶│                 │
│                 │     │  │         MCP Server                     │  │     │                 │
│                 │     │  │  (MCP Tools for Task Operations)       │  │◀────│                 │
│                 │     │  └────────────────────────────────────────┘  │     │                 │
└─────────────────┘     └──────────────────────────────────────────────┘     └─────────────────┘
```

## License

MIT License - Hackathon II Project
