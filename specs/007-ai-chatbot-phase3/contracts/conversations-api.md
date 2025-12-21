# API Contract: Conversations API

**Feature**: 007-ai-chatbot-phase3
**Base Path**: `/api/{user_id}/conversations`
**Authentication**: JWT Bearer Token (Better Auth)

---

## Overview

This contract defines endpoints for managing conversation history.

---

## Endpoints

### GET `/api/{user_id}/conversations`

List all conversations for a user, sorted by most recent.

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_id | string | Yes | The authenticated user's ID |

#### Request Headers

| Header | Value | Required |
|--------|-------|----------|
| Authorization | Bearer {jwt_token} | Yes |

#### Response (200 OK)

```json
{
  "conversations": [
    {
      "id": 123,
      "title": "Add a task to buy groceries",
      "created_at": "2025-12-18T10:30:00Z",
      "updated_at": "2025-12-18T11:45:00Z",
      "message_count": 8
    },
    {
      "id": 120,
      "title": "Show me my pending tasks",
      "created_at": "2025-12-17T14:20:00Z",
      "updated_at": "2025-12-17T14:25:00Z",
      "message_count": 4
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| conversations | array | List of conversation summaries |

#### Conversation Summary Object

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Conversation ID |
| title | string | Auto-generated title (first 50 chars of first message) |
| created_at | string (ISO 8601) | When conversation started |
| updated_at | string (ISO 8601) | Last activity timestamp |
| message_count | integer | Number of messages in conversation |

---

### GET `/api/{user_id}/conversations/{conversation_id}`

Get a single conversation with all its messages.

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_id | string | Yes | The authenticated user's ID |
| conversation_id | integer | Yes | The conversation ID |

#### Response (200 OK)

```json
{
  "id": 123,
  "title": "Add a task to buy groceries",
  "created_at": "2025-12-18T10:30:00Z",
  "updated_at": "2025-12-18T11:45:00Z",
  "messages": [
    {
      "id": 456,
      "role": "user",
      "content": "Add a task to buy groceries",
      "created_at": "2025-12-18T10:30:00Z"
    },
    {
      "id": 457,
      "role": "assistant",
      "content": "I've added 'Buy groceries' to your task list!",
      "created_at": "2025-12-18T10:30:05Z"
    }
  ]
}
```

#### Message Object

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Message ID |
| role | string | "user" or "assistant" |
| content | string | Message content |
| created_at | string (ISO 8601) | When message was sent |

#### Error Responses

##### 404 Not Found
```json
{
  "detail": "Conversation not found"
}
```

---

### DELETE `/api/{user_id}/conversations/{conversation_id}`

Delete a conversation and all its messages (cascade delete).

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_id | string | Yes | The authenticated user's ID |
| conversation_id | integer | Yes | The conversation ID |

#### Response (200 OK)

```json
{
  "success": true,
  "deleted_conversation_id": 123,
  "deleted_message_count": 8
}
```

#### Error Responses

##### 404 Not Found
```json
{
  "detail": "Conversation not found"
}
```

---

## Example Requests

### List Conversations
```bash
curl -X GET "http://localhost:8000/api/user_abc123/conversations" \
  -H "Authorization: Bearer eyJhbG..."
```

### Get Single Conversation
```bash
curl -X GET "http://localhost:8000/api/user_abc123/conversations/123" \
  -H "Authorization: Bearer eyJhbG..."
```

### Delete Conversation
```bash
curl -X DELETE "http://localhost:8000/api/user_abc123/conversations/123" \
  -H "Authorization: Bearer eyJhbG..."
```

---

## Common Error Responses

### 401 Unauthorized
```json
{
  "detail": "Not authenticated"
}
```

### 403 Forbidden
```json
{
  "detail": "Cannot access another user's conversations"
}
```
