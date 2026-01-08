# API Contract: Todo Chatbot Kubernetes Deployment

**Feature**: 008-k8s-minikube-deployment
**Date**: 2025-12-28
**Status**: Complete

## Overview

This document defines the REST API contract for the Phase III Todo Chatbot application when deployed on Kubernetes. It documents the endpoints exposed by the backend FastAPI application, the expected request/response formats, error codes, and how the frontend Next.js application communicates with the backend via Kubernetes service discovery.

---

## 1. Service Communication

### 1.1 Backend Service Endpoint

**Kubernetes Service**: `backend-service`
**Namespace**: `todo-app`
**Service Type**: `ClusterIP`
**Port**: 8000

**Frontend Access Pattern**:
```typescript
// Frontend API client configuration
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://backend-service:8000';

// Service discovery within Kubernetes cluster
// DNS name: backend-service.todo-app.svc.cluster.local
// URL format: http://<service-name>.<namespace>.svc.cluster.local:<port>
```

### 1.2 Frontend Service Endpoint

**Kubernetes Service**: `frontend-service`
**Namespace**: `todo-app`
**Service Type**: `NodePort`
**Port**: 3000
**NodePort**: 30000

**External Access Pattern**:
```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Access frontend
open http://$MINIKUBE_IP:30000
# OR use minikube service command
minikube service frontend-service -n todo-app --url
```

---

## 2. Backend API Endpoints

### 2.1 Health Check Endpoint

**Purpose**: Kubernetes liveness and readiness probe verification

| Attribute | Value |
|-----------|-------|
| Method | `GET` |
| Path | `/health` |
| Authentication | None |
| Content-Type | `application/json` |

**Request**: None (no request body)

**Success Response** (200 OK):
```json
{
  "status": "ok",
  "timestamp": "2025-12-28T12:00:00Z"
}
```

**Use Case**: Kubernetes health probes verify pod health

---

### 2.2 Agent Chat Endpoint

**Purpose**: Process user natural language requests via OpenAI Agents SDK + MCP

| Attribute | Value |
|-----------|-------|
| Method | `POST` |
| Path | `/api/{user_id}/chat` |
| Authentication | Bearer JWT token (required) |
| Content-Type | `application/json` |

**Request**:
```json
{
  "message": "Create a task to buy groceries tomorrow morning",
  "context": {
    "previous_messages": [
      {
        "role": "assistant",
        "content": "I can help you with that. What would you like to do?"
      }
    ]
  }
}
```

**Success Response** (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "user-123",
  "messages": [
    {
      "role": "user",
      "content": "Create a task to buy groceries tomorrow morning"
    },
    {
      "role": "assistant",
      "content": "I'll create a task for you: Buy groceries tomorrow morning. Is there anything else you'd like to add or modify?"
    }
  ],
  "created_at": "2025-12-28T12:00:00Z",
  "updated_at": "2025-12-28T12:00:05Z"
}
```

**Error Responses**:

| Status | Error Code | Description |
|---------|-------------|-------------|
| 401 Unauthorized | `TOKEN_INVALID` | JWT token expired or invalid |
| 403 Forbidden | `USER_NOT_AUTHORIZED` | User cannot access this conversation |
| 404 Not Found | `CONVERSATION_NOT_FOUND` | Conversation ID does not exist |
| 429 Too Many Requests | `RATE_LIMIT_EXCEEDED` | OpenAI API rate limit exceeded |
| 500 Internal Server Error | `AGENT_ERROR` | Agent processing failed |

**Use Case**: Frontend ChatKit widget sends user messages to backend for AI processing

---

### 2.3 List Tasks Endpoint

**Purpose**: Retrieve all tasks for a user (exposed by Agent SDK via MCP)

| Attribute | Value |
|-----------|-------|
| Method | `GET` |
| Path | `/api/{user_id}/tasks` |
| Authentication | Bearer JWT token (required) |
| Content-Type | `application/json` |

**Request Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|-----------|-------------|
| user_id | string | Yes | User identifier from JWT |
| status | string | No | Filter by task status (`pending`, `in_progress`, `completed`, `cancelled`) |
| limit | integer | No | Maximum number of tasks to return (default: 50) |
| offset | integer | No | Pagination offset (default: 0) |

**Success Response** (200 OK):
```json
{
  "tasks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "user_id": "user-123",
      "title": "Buy groceries",
      "description": "Tomorrow morning",
      "status": "pending",
      "due_date": "2025-12-29T08:00:00Z",
      "created_at": "2025-12-28T12:00:00Z",
      "updated_at": "2025-12-28T12:00:00Z"
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

**Error Responses**:

| Status | Error Code | Description |
|---------|-------------|-------------|
| 401 Unauthorized | `TOKEN_INVALID` | JWT token expired or invalid |
| 403 Forbidden | `USER_NOT_AUTHORIZED` | User cannot access these tasks |
| 500 Internal Server Error | `DATABASE_ERROR` | Failed to query database |

**Use Case**: Frontend displays task list to user

---

### 2.4 Create Task Endpoint

**Purpose**: Create a new task (triggered by Agent SDK via MCP)

| Attribute | Value |
|-----------|-------|
| Method | `POST` |
| Path | `/api/{user_id}/tasks` |
| Authentication | Bearer JWT token (required) |
| Content-Type | `application/json` |

**Request**:
```json
{
  "title": "Buy groceries",
  "description": "Tomorrow morning",
  "status": "pending",
  "due_date": "2025-12-29T08:00:00Z"
}
```

**Request Validation Rules**:
- `title`: Required, string, max length: 200 characters
- `description`: Optional, string, max length: 1000 characters
- `status`: Optional, enum: `["pending", "in_progress", "completed", "cancelled"]`, default: `pending`
- `due_date`: Optional, ISO 8601 datetime string

**Success Response** (201 Created):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "user_id": "user-123",
  "title": "Buy groceries",
  "description": "Tomorrow morning",
  "status": "pending",
  "due_date": "2025-12-29T08:00:00Z",
  "created_at": "2025-12-28T12:05:00Z",
  "updated_at": "2025-12-28T12:05:00Z"
}
```

**Error Responses**:

| Status | Error Code | Description |
|---------|-------------|-------------|
| 400 Bad Request | `VALIDATION_ERROR` | Invalid request data |
| 401 Unauthorized | `TOKEN_INVALID` | JWT token expired or invalid |
| 500 Internal Server Error | `DATABASE_ERROR` | Failed to insert into database |

**Use Case**: Agent SDK creates task based on user natural language intent

---

### 2.5 Update Task Endpoint

**Purpose**: Update an existing task

| Attribute | Value |
|-----------|-------|
| Method | `PUT` | `PATCH` |
| Path | `/api/{user_id}/tasks/{task_id}` |
| Authentication | Bearer JWT token (required) |
| Content-Type | `application/json` |

**Request** (all fields optional except user_id/task_id in path):
```json
{
  "title": "Buy groceries and vegetables",
  "description": "Tomorrow morning, early",
  "status": "in_progress",
  "due_date": "2025-12-29T07:00:00Z"
}
```

**Success Response** (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "user_id": "user-123",
  "title": "Buy groceries and vegetables",
  "description": "Tomorrow morning, early",
  "status": "in_progress",
  "due_date": "2025-12-29T07:00:00Z",
  "created_at": "2025-12-28T12:05:00Z",
  "updated_at": "2025-12-28T12:10:00Z"
}
```

**Error Responses**:

| Status | Error Code | Description |
|---------|-------------|-------------|
| 400 Bad Request | `VALIDATION_ERROR` | Invalid request data |
| 401 Unauthorized | `TOKEN_INVALID` | JWT token expired or invalid |
| 403 Forbidden | `TASK_NOT_OWNED` | User does not own this task |
| 404 Not Found | `TASK_NOT_FOUND` | Task ID does not exist |
| 500 Internal Server Error | `DATABASE_ERROR` | Failed to update database |

**Use Case**: Agent SDK or user updates task details

---

### 2.6 Delete Task Endpoint

**Purpose**: Delete a task

| Attribute | Value |
|-----------|-------|
| Method | `DELETE` |
| Path | `/api/{user_id}/tasks/{task_id}` |
| Authentication | Bearer JWT token (required) |
| Content-Type | `application/json` |

**Request**: None (path parameters only)

**Success Response** (200 OK):
```json
{
  "success": true,
  "message": "Task deleted successfully",
  "task_id": "550e8400-e29b-41d4-a716-446655440002"
}
```

**Error Responses**:

| Status | Error Code | Description |
|---------|-------------|-------------|
| 401 Unauthorized | `TOKEN_INVALID` | JWT token expired or invalid |
| 403 Forbidden | `TASK_NOT_OWNED` | User does not own this task |
| 404 Not Found | `TASK_NOT_FOUND` | Task ID does not exist |
| 500 Internal Server Error | `DATABASE_ERROR` | Failed to delete from database |

**Use Case**: Agent SDK or user deletes a task

---

## 3. Error Response Format

All error responses follow this standard format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      "field": "Additional context (optional)"
    }
  }
}
```

### Error Codes Reference

| Code | Status | Description |
|-------|---------|-------------|
| `TOKEN_INVALID` | 401 | JWT token is invalid or expired |
| `USER_NOT_AUTHORIZED` | 403 | User is not authorized for this resource |
| `TASK_NOT_FOUND` | 404 | Task does not exist |
| `CONVERSATION_NOT_FOUND` | 404 | Conversation does not exist |
| `VALIDATION_ERROR` | 400 | Request validation failed |
| `TASK_NOT_OWNED` | 403 | User does not own this task |
| `RATE_LIMIT_EXCEEDED` | 429 | OpenAI API rate limit exceeded |
| `AGENT_ERROR` | 500 | Agent processing failed |
| `DATABASE_ERROR` | 500 | Database operation failed |

---

## 4. Authentication

### 4.1 JWT Token Format

**Token Type**: Bearer token in Authorization header

```
Authorization: Bearer <JWT_TOKEN>
```

**Token Payload** (decoded):
```json
{
  "sub": "user-123",
  "email": "user@example.com",
  "exp": 1735351200,
  "iat": 1735264800
}
```

**Token Validation**:
- JWT_SECRET from Kubernetes Secret used for signing
- Token expiration: 24 hours (configurable)
- User ID (`sub`) extracted from token for authorization

### 4.2 Authentication Flow

1. **Frontend Login**: User authenticates with Better Auth (Phase II/III)
2. **JWT Reception**: Frontend receives JWT token from Better Auth
3. **Token Storage**: Token stored in frontend (cookie/localStorage)
4. **API Requests**: Frontend includes Bearer token in Authorization header
5. **Backend Validation**: FastAPI validates token signature using JWT_SECRET
6. **Access Granted**: User authorized to access their resources

---

## 5. Rate Limiting

### 5.1 OpenAI API Rate Limits

The backend enforces rate limits to prevent exceeding OpenAI quotas:

| Metric | Limit |
|---------|--------|
| Requests per minute | 60 |
| Requests per day | 1000 |

**Rate Limit Response** (429 Too Many Requests):
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Please try again later.",
    "details": {
      "retry_after": 60,
      "limit_type": "per_minute"
    }
  }
}
```

---

## 6. CORS Configuration

### 6.1 CORS Headers

The backend sets CORS headers for frontend requests:

| Header | Value (from ConfigMap) |
|---------|---------------------------|
| `Access-Control-Allow-Origin` | `CORS_ORIGINS` (e.g., `http://localhost:30000`) |
| `Access-Control-Allow-Methods` | `GET, POST, PUT, DELETE, OPTIONS` |
| `Access-Control-Allow-Headers` | `Authorization, Content-Type` |
| `Access-Control-Allow-Credentials` | `true` |
| `Access-Control-Max-Age` | `86400` (24 hours) |

**Pre-flight Request** (OPTIONS):
- Responds with 204 No Content
- Includes all CORS headers
- No authentication required

---

## 7. Contract Evolution

### 7.1 Versioning

This API contract is version `v1`. Future versions will be:

- Path-based: `/api/v2/...`
- Header-based: `API-Version: v2`

### 7.2 Backward Compatibility

Breaking changes will require new major version. Non-breaking changes:

- Adding optional fields: Compatible with existing clients
- Adding new endpoints: Compatible with existing clients
- Deprecating endpoints: 90-day notice before removal

---

## 8. Testing Endpoints

### 8.1 Local Testing

```bash
# Test health endpoint
curl http://localhost:8000/health

# Test chat endpoint (with JWT)
curl -X POST http://localhost:8000/api/user-123/chat \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello"}'

# Test tasks endpoint
curl http://localhost:8000/api/user-123/tasks \
  -H "Authorization: Bearer $JWT_TOKEN"
```

### 8.2 Kubernetes Testing

```bash
# Test health from another pod
kubectl run debug --image=curlimages/curl --rm -i --restart=Never -- \
  curl http://backend-service:8000/health

# Test connectivity from frontend pod
kubectl exec deployment/frontend -n todo-app -- \
  curl http://backend-service:8000/health
```

---

## Summary

This API contract defines:
- 6 REST endpoints (health, chat, list tasks, create, update, delete)
- Standard request/response formats
- Comprehensive error codes and messages
- JWT authentication flow
- CORS configuration
- Rate limiting strategy
- Testing procedures for both local and Kubernetes environments

All endpoints follow RESTful conventions and are designed for integration with Next.js ChatKit frontend and OpenAI Agents SDK backend.
