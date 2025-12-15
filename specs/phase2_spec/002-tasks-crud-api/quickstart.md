# Quickstart: Tasks API & Endpoints

**Feature**: 003-tasks-crud-api
**Date**: 2025-12-13

---

## Overview

This guide helps developers get started with the Tasks API implementation for Phase II of the Todo application.

---

## Prerequisites

1. **Python 3.13+** installed
2. **UV** package manager
3. **Neon Postgres** database configured
4. **Better Auth** JWT tokens available (or test tokens)

---

## Setup

### 1. Navigate to Backend Directory

```bash
cd phase2/backend
```

### 2. Install Dependencies

```bash
uv sync
uv add "python-jose[cryptography]"
```

### 3. Configure Environment

Copy `.env.example` to `.env` and set:

```env
DATABASE_URL=postgresql://user:password@host/dbname?sslmode=require
JWT_SECRET=your-better-auth-secret
JWT_ALGORITHM=HS256
ENVIRONMENT=development
```

### 4. Run Migrations (if not already done)

```bash
uv run alembic upgrade head
```

### 5. Start Development Server

```bash
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## API Endpoints

Base URL: `http://localhost:8000/api/v1`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/tasks` | List your tasks |
| POST | `/tasks` | Create a task |
| GET | `/tasks/{id}` | Get a task |
| PATCH | `/tasks/{id}` | Update a task |
| DELETE | `/tasks/{id}` | Delete a task |

---

## Authentication

All endpoints require a JWT token in the `Authorization` header:

```
Authorization: Bearer <your-jwt-token>
```

### Getting a Test Token

For development, you can generate a test token:

```python
from jose import jwt
from datetime import datetime, timedelta

token = jwt.encode(
    {
        "sub": "test-user-123",
        "exp": datetime.utcnow() + timedelta(hours=24)
    },
    "your-jwt-secret",
    algorithm="HS256"
)
print(token)
```

---

## Quick Examples

### List Tasks

```bash
curl -X GET "http://localhost:8000/api/v1/tasks" \
  -H "Authorization: Bearer $TOKEN"
```

**With pagination and filter:**

```bash
curl -X GET "http://localhost:8000/api/v1/tasks?offset=0&limit=10&status=pending" \
  -H "Authorization: Bearer $TOKEN"
```

### Create a Task

```bash
curl -X POST "http://localhost:8000/api/v1/tasks" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Buy groceries", "description": "Milk, eggs, bread"}'
```

**Response (201 Created):**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "test-user-123",
  "title": "Buy groceries",
  "description": "Milk, eggs, bread",
  "status": "pending",
  "created_at": "2025-12-13T10:00:00Z",
  "updated_at": "2025-12-13T10:00:00Z"
}
```

### Get a Task

```bash
curl -X GET "http://localhost:8000/api/v1/tasks/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer $TOKEN"
```

### Update a Task

```bash
curl -X PATCH "http://localhost:8000/api/v1/tasks/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "completed"}'
```

### Delete a Task

```bash
curl -X DELETE "http://localhost:8000/api/v1/tasks/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer $TOKEN"
```

**Response:** `204 No Content`

---

## Error Handling

All errors use RFC 7807 Problem Details format:

```json
{
  "type": "about:blank",
  "title": "Not Found",
  "status": 404,
  "detail": "Task not found",
  "instance": "/api/v1/tasks/invalid-id"
}
```

### Common Error Codes

| Status | Title | When |
|--------|-------|------|
| 401 | Unauthorized | Missing/invalid JWT |
| 404 | Not Found | Task doesn't exist or belongs to another user |
| 422 | Validation Error | Invalid request body or parameters |

---

## Running Tests

### All Tests

```bash
uv run pytest
```

### Integration Tests Only

```bash
uv run pytest tests/integration/ -v
```

### With Coverage

```bash
uv run pytest --cov=app --cov-report=html
```

---

## Interactive API Docs

Once the server is running, visit:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---

## Project Structure

```
phase2/backend/
├── app/
│   ├── main.py              # FastAPI entrypoint
│   ├── config.py            # Settings (DATABASE_URL, JWT_SECRET)
│   ├── database.py          # Async DB session
│   ├── models/              # SQLModel entities
│   │   └── task.py
│   ├── schemas/             # Pydantic request/response
│   │   ├── task.py
│   │   └── error.py
│   ├── api/                 # API routes
│   │   ├── deps.py          # Dependencies (auth, db)
│   │   └── v1/
│   │       └── tasks.py
│   └── core/                # Auth, exceptions, logging
│       ├── auth.py
│       └── exceptions.py
└── tests/
    └── integration/         # API tests
```

---

## Next Steps

1. Implement JWT validation in `core/auth.py`
2. Create Pydantic schemas in `schemas/`
3. Build CRUD endpoints in `api/v1/tasks.py`
4. Write integration tests
5. Verify success criteria

See `plan.md` for detailed implementation tasks.
