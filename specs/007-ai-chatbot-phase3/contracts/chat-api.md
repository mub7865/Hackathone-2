# API Contract: Chat API

**Feature**: 007-ai-chatbot-phase3
**Base Path**: `/api/{user_id}`
**Authentication**: JWT Bearer Token (Better Auth)

---

## Overview

This contract defines the chat endpoint for AI-powered conversation with the Todo Assistant.

---

## Endpoints

### POST `/api/{user_id}/chat`

Send a message to the AI assistant and receive a response.

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_id | string | Yes | The authenticated user's ID |

#### Request Headers

| Header | Value | Required |
|--------|-------|----------|
| Authorization | Bearer {jwt_token} | Yes |
| Content-Type | application/json | Yes |

#### Request Body

```json
{
  "message": "string (required, 1-4000 chars)",
  "conversation_id": "integer (optional)"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| message | string | Yes | User's message (1-4000 characters) |
| conversation_id | integer | No | Existing conversation ID. If omitted, creates new conversation |

#### Response (200 OK)

```json
{
  "conversation_id": 123,
  "response": "I've added 'Buy groceries' to your task list!",
  "tool_calls": [
    {
      "name": "add_task",
      "arguments": {
        "user_id": "user_abc123",
        "title": "Buy groceries"
      },
      "result": {
        "task_id": 45,
        "status": "created",
        "title": "Buy groceries"
      }
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| conversation_id | integer | The conversation ID (new or existing) |
| response | string | AI assistant's response text |
| tool_calls | array | List of MCP tools invoked (may be empty) |

#### Tool Call Object

| Field | Type | Description |
|-------|------|-------------|
| name | string | Tool name (add_task, list_tasks, etc.) |
| arguments | object | Arguments passed to the tool |
| result | object | Tool execution result |

#### Error Responses

##### 400 Bad Request
```json
{
  "detail": "Message cannot be empty"
}
```

##### 401 Unauthorized
```json
{
  "detail": "Not authenticated"
}
```

##### 403 Forbidden
```json
{
  "detail": "Cannot access another user's chat"
}
```

##### 500 Internal Server Error
```json
{
  "detail": "Failed to process message. Please try again."
}
```

---

## Example Requests

### Create New Conversation
```bash
curl -X POST "http://localhost:8000/api/user_abc123/chat" \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{"message": "Add a task to buy groceries"}'
```

### Continue Existing Conversation
```bash
curl -X POST "http://localhost:8000/api/user_abc123/chat" \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{"message": "Show my tasks", "conversation_id": 123}'
```

---

## Sequence Diagram

```
Client                    FastAPI                   Gemini Agent              Database
   │                         │                           │                        │
   │  POST /chat             │                           │                        │
   │  {message, conv_id?}    │                           │                        │
   │────────────────────────▶│                           │                        │
   │                         │                           │                        │
   │                         │  Validate JWT             │                        │
   │                         │──────────────────────────▶│                        │
   │                         │                           │                        │
   │                         │  Get/Create Conversation  │                        │
   │                         │──────────────────────────────────────────────────▶│
   │                         │                           │                        │
   │                         │  Fetch History (last 100) │                        │
   │                         │──────────────────────────────────────────────────▶│
   │                         │                           │                        │
   │                         │  Store User Message       │                        │
   │                         │──────────────────────────────────────────────────▶│
   │                         │                           │                        │
   │                         │  Run Agent                │                        │
   │                         │──────────────────────────▶│                        │
   │                         │                           │                        │
   │                         │        (Tool Calls)       │                        │
   │                         │                           │──────────────────────▶│
   │                         │                           │◀──────────────────────│
   │                         │                           │                        │
   │                         │◀──────────────────────────│                        │
   │                         │                           │                        │
   │                         │  Store Assistant Message  │                        │
   │                         │──────────────────────────────────────────────────▶│
   │                         │                           │                        │
   │◀────────────────────────│                           │                        │
   │  {conv_id, response,    │                           │                        │
   │   tool_calls}           │                           │                        │
```
