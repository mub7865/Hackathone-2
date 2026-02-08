# API Reference: Cloud-Native Event-Driven Todo Application

**Version**: 1.0
**Last Updated**: 2026-01-12
**Base URL**: `http://localhost:8000` (development), `https://api.todo-app.example.com` (production)

---

## Table of Contents

1. [Authentication](#authentication)
2. [Tasks API](#tasks-api)
3. [Recurring Tasks API](#recurring-tasks-api)
4. [Reminders API](#reminders-api)
5. [Tags API](#tags-api)
6. [Saved Filters API](#saved-filters-api)
7. [Audit Trail API](#audit-trail-api)
8. [Notification Preferences API](#notification-preferences-api)
9. [WebSocket API](#websocket-api)
10. [Error Handling](#error-handling)

---

## Authentication

All API endpoints (except `/health` and `/docs`) require JWT authentication.

### Obtain Access Token

**Endpoint**: `POST /api/v1/auth/login`

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "secure_password"
}
```

**Response** (200 OK):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 900
}
```

### Using Access Token

Include the token in the `Authorization` header:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Refresh Token

**Endpoint**: `POST /api/v1/auth/refresh`

**Request Body**:
```json
{
  "refresh_token": "refresh_token_here"
}
```

**Response** (200 OK):
```json
{
  "access_token": "new_access_token",
  "token_type": "bearer",
  "expires_in": 900
}
```

---

## Tasks API

### List Tasks

**Endpoint**: `GET /api/v1/tasks`

**Query Parameters**:
- `status` (optional): Filter by status (`pending`, `in_progress`, `completed`)
- `priority` (optional): Filter by priority (`low`, `medium`, `high`)
- `tags` (optional): Filter by tags (comma-separated)
- `search` (optional): Search in title and description
- `sort` (optional): Sort field (`created_at`, `updated_at`, `due_date`, `priority`)
- `order` (optional): Sort order (`asc`, `desc`)
- `offset` (optional): Pagination offset (default: 0)
- `limit` (optional): Pagination limit (default: 50, max: 100)

**Example Request**:
```bash
GET /api/v1/tasks?status=pending&priority=high&sort=due_date&order=asc&limit=20
```

**Response** (200 OK):
```json
{
  "tasks": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "user_id": "user123",
      "title": "Complete project documentation",
      "description": "Write comprehensive API documentation",
      "status": "pending",
      "priority": "high",
      "tags": ["documentation", "urgent"],
      "due_date": "2026-01-15T17:00:00Z",
      "remind_at": "2026-01-15T09:00:00Z",
      "recurring_pattern_id": null,
      "created_at": "2026-01-12T10:00:00Z",
      "updated_at": "2026-01-12T10:00:00Z"
    }
  ],
  "total": 1,
  "offset": 0,
  "limit": 20
}
```

### Get Task by ID

**Endpoint**: `GET /api/v1/tasks/{task_id}`

**Path Parameters**:
- `task_id` (UUID): Task identifier

**Response** (200 OK):
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "user_id": "user123",
  "title": "Complete project documentation",
  "description": "Write comprehensive API documentation",
  "status": "pending",
  "priority": "high",
  "tags": ["documentation", "urgent"],
  "due_date": "2026-01-15T17:00:00Z",
  "remind_at": "2026-01-15T09:00:00Z",
  "recurring_pattern_id": null,
  "created_at": "2026-01-12T10:00:00Z",
  "updated_at": "2026-01-12T10:00:00Z"
}
```

**Error Responses**:
- `404 Not Found`: Task not found
- `403 Forbidden`: Not authorized to access this task

### Create Task

**Endpoint**: `POST /api/v1/tasks`

**Request Body**:
```json
{
  "title": "Complete project documentation",
  "description": "Write comprehensive API documentation",
  "status": "pending",
  "priority": "high",
  "tags": ["documentation", "urgent"],
  "due_date": "2026-01-15T17:00:00Z",
  "remind_at": "2026-01-15T09:00:00Z"
}
```

**Required Fields**:
- `title` (string, 1-200 characters)

**Optional Fields**:
- `description` (string, max 2000 characters)
- `status` (enum: `pending`, `in_progress`, `completed`, default: `pending`)
- `priority` (enum: `low`, `medium`, `high`)
- `tags` (array of strings, max 10 tags, each max 50 characters)
- `due_date` (ISO 8601 datetime)
- `remind_at` (ISO 8601 datetime, must be before due_date)

**Response** (201 Created):
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "user_id": "user123",
  "title": "Complete project documentation",
  "description": "Write comprehensive API documentation",
  "status": "pending",
  "priority": "high",
  "tags": ["documentation", "urgent"],
  "due_date": "2026-01-15T17:00:00Z",
  "remind_at": "2026-01-15T09:00:00Z",
  "recurring_pattern_id": null,
  "created_at": "2026-01-12T10:00:00Z",
  "updated_at": "2026-01-12T10:00:00Z"
}
```

**Error Responses**:
- `400 Bad Request`: Invalid input data
- `422 Unprocessable Entity`: Validation error

### Update Task

**Endpoint**: `PATCH /api/v1/tasks/{task_id}`

**Path Parameters**:
- `task_id` (UUID): Task identifier

**Request Body** (all fields optional):
```json
{
  "title": "Updated title",
  "description": "Updated description",
  "status": "in_progress",
  "priority": "medium",
  "tags": ["documentation"],
  "due_date": "2026-01-16T17:00:00Z",
  "remind_at": "2026-01-16T09:00:00Z"
}
```

**Response** (200 OK):
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "user_id": "user123",
  "title": "Updated title",
  "description": "Updated description",
  "status": "in_progress",
  "priority": "medium",
  "tags": ["documentation"],
  "due_date": "2026-01-16T17:00:00Z",
  "remind_at": "2026-01-16T09:00:00Z",
  "recurring_pattern_id": null,
  "created_at": "2026-01-12T10:00:00Z",
  "updated_at": "2026-01-12T11:00:00Z"
}
```

**Error Responses**:
- `404 Not Found`: Task not found
- `403 Forbidden`: Not authorized to update this task
- `400 Bad Request`: Invalid input data

### Delete Task

**Endpoint**: `DELETE /api/v1/tasks/{task_id}`

**Path Parameters**:
- `task_id` (UUID): Task identifier

**Response** (204 No Content)

**Error Responses**:
- `404 Not Found`: Task not found
- `403 Forbidden`: Not authorized to delete this task

---

## Recurring Tasks API

### List Recurring Patterns

**Endpoint**: `GET /api/v1/recurring-tasks`

**Query Parameters**:
- `active` (optional): Filter by active status (true/false)
- `offset` (optional): Pagination offset
- `limit` (optional): Pagination limit

**Response** (200 OK):
```json
{
  "patterns": [
    {
      "id": "456e7890-e89b-12d3-a456-426614174001",
      "user_id": "user123",
      "frequency": "weekly",
      "interval": 1,
      "days_of_week": [1, 3, 5],
      "day_of_month": null,
      "start_date": "2026-01-01",
      "end_date": null,
      "next_occurrence": "2026-01-13T09:00:00Z",
      "active": true,
      "created_at": "2026-01-01T10:00:00Z",
      "updated_at": "2026-01-01T10:00:00Z"
    }
  ],
  "total": 1,
  "offset": 0,
  "limit": 50
}
```

### Create Recurring Pattern

**Endpoint**: `POST /api/v1/recurring-tasks`

**Request Body**:
```json
{
  "frequency": "weekly",
  "interval": 1,
  "days_of_week": [1, 3, 5],
  "start_date": "2026-01-01",
  "end_date": null,
  "task_template": {
    "title": "Weekly team meeting",
    "description": "Discuss project progress",
    "priority": "medium",
    "tags": ["meeting"]
  }
}
```

**Frequency Options**:
- `daily`: Every N days
- `weekly`: Every N weeks on specified days
- `monthly`: Every N months on specified day
- `yearly`: Every N years

**Required Fields**:
- `frequency` (enum)
- `interval` (integer, min: 1)
- `start_date` (ISO 8601 date)
- `task_template` (object with task fields)

**Conditional Fields**:
- `days_of_week` (array of integers 0-6, required for weekly)
- `day_of_month` (integer 1-31, required for monthly)

**Response** (201 Created):
```json
{
  "id": "456e7890-e89b-12d3-a456-426614174001",
  "user_id": "user123",
  "frequency": "weekly",
  "interval": 1,
  "days_of_week": [1, 3, 5],
  "day_of_month": null,
  "start_date": "2026-01-01",
  "end_date": null,
  "next_occurrence": "2026-01-13T09:00:00Z",
  "active": true,
  "created_at": "2026-01-12T10:00:00Z",
  "updated_at": "2026-01-12T10:00:00Z"
}
```

### Update Recurring Pattern

**Endpoint**: `PATCH /api/v1/recurring-tasks/{pattern_id}`

**Request Body** (all fields optional):
```json
{
  "interval": 2,
  "days_of_week": [1, 4],
  "active": false
}
```

**Response** (200 OK): Updated pattern object

### Delete Recurring Pattern

**Endpoint**: `DELETE /api/v1/recurring-tasks/{pattern_id}`

**Response** (204 No Content)

---

## Reminders API

### List Reminders

**Endpoint**: `GET /api/v1/reminders`

**Query Parameters**:
- `status` (optional): Filter by status (`pending`, `sent`, `failed`)
- `offset` (optional): Pagination offset
- `limit` (optional): Pagination limit

**Response** (200 OK):
```json
{
  "reminders": [
    {
      "id": "789e0123-e89b-12d3-a456-426614174002",
      "task_id": "123e4567-e89b-12d3-a456-426614174000",
      "user_id": "user123",
      "remind_at": "2026-01-15T09:00:00Z",
      "status": "pending",
      "sent_at": null,
      "created_at": "2026-01-12T10:00:00Z"
    }
  ],
  "total": 1,
  "offset": 0,
  "limit": 50
}
```

### Create Reminder

**Endpoint**: `POST /api/v1/reminders`

**Request Body**:
```json
{
  "task_id": "123e4567-e89b-12d3-a456-426614174000",
  "remind_at": "2026-01-15T09:00:00Z"
}
```

**Response** (201 Created): Reminder object

### Update Reminder

**Endpoint**: `PATCH /api/v1/reminders/{reminder_id}`

**Request Body**:
```json
{
  "remind_at": "2026-01-15T10:00:00Z"
}
```

**Response** (200 OK): Updated reminder object

### Delete Reminder

**Endpoint**: `DELETE /api/v1/reminders/{reminder_id}`

**Response** (204 No Content)

---

## Tags API

### List All Tags

**Endpoint**: `GET /api/v1/tags`

**Response** (200 OK):
```json
{
  "tags": [
    {
      "name": "documentation",
      "count": 5
    },
    {
      "name": "urgent",
      "count": 3
    },
    {
      "name": "meeting",
      "count": 2
    }
  ]
}
```

### Get Tag Statistics

**Endpoint**: `GET /api/v1/tags/stats`

**Response** (200 OK):
```json
{
  "total_tags": 10,
  "most_used": [
    {
      "name": "documentation",
      "count": 5
    },
    {
      "name": "urgent",
      "count": 3
    }
  ],
  "least_used": [
    {
      "name": "archive",
      "count": 1
    }
  ]
}
```

---

## Saved Filters API

### List Saved Filters

**Endpoint**: `GET /api/v1/saved-filters`

**Response** (200 OK):
```json
{
  "filters": [
    {
      "id": "abc12345-e89b-12d3-a456-426614174003",
      "user_id": "user123",
      "name": "High Priority Pending",
      "filter_criteria": {
        "status": "pending",
        "priority": "high"
      },
      "created_at": "2026-01-12T10:00:00Z",
      "updated_at": "2026-01-12T10:00:00Z"
    }
  ],
  "total": 1
}
```

### Create Saved Filter

**Endpoint**: `POST /api/v1/saved-filters`

**Request Body**:
```json
{
  "name": "High Priority Pending",
  "filter_criteria": {
    "status": "pending",
    "priority": "high",
    "tags": ["urgent"]
  }
}
```

**Response** (201 Created): Saved filter object

### Update Saved Filter

**Endpoint**: `PATCH /api/v1/saved-filters/{filter_id}`

**Request Body**:
```json
{
  "name": "Updated Filter Name",
  "filter_criteria": {
    "status": "in_progress"
  }
}
```

**Response** (200 OK): Updated filter object

### Delete Saved Filter

**Endpoint**: `DELETE /api/v1/saved-filters/{filter_id}`

**Response** (204 No Content)

---

## Audit Trail API

### List Audit Logs

**Endpoint**: `GET /api/v1/audit`

**Query Parameters**:
- `action` (optional): Filter by action (`created`, `updated`, `deleted`, `completed`, `viewed`)
- `resource_type` (optional): Filter by resource type (`task`, `recurring_pattern`)
- `resource_id` (optional): Filter by resource ID
- `start_date` (optional): Filter by date range start
- `end_date` (optional): Filter by date range end
- `offset` (optional): Pagination offset
- `limit` (optional): Pagination limit

**Response** (200 OK):
```json
{
  "logs": [
    {
      "id": "def45678-e89b-12d3-a456-426614174004",
      "user_id": "user123",
      "action": "updated",
      "resource_type": "task",
      "resource_id": "123e4567-e89b-12d3-a456-426614174000",
      "changes": {
        "status": {
          "before": "pending",
          "after": "in_progress"
        },
        "priority": {
          "before": "high",
          "after": "medium"
        }
      },
      "ip_address": "192.168.1.100",
      "user_agent": "Mozilla/5.0...",
      "created_at": "2026-01-12T11:00:00Z"
    }
  ],
  "total": 1,
  "offset": 0,
  "limit": 50
}
```

### Get Audit Statistics

**Endpoint**: `GET /api/v1/audit/stats`

**Query Parameters**:
- `start_date` (optional): Statistics start date
- `end_date` (optional): Statistics end date

**Response** (200 OK):
```json
{
  "total_actions": 150,
  "actions_by_type": {
    "created": 50,
    "updated": 75,
    "deleted": 10,
    "completed": 15
  },
  "most_active_days": [
    {
      "date": "2026-01-12",
      "count": 25
    }
  ]
}
```

---

## Notification Preferences API

### Get Notification Preferences

**Endpoint**: `GET /api/v1/notification-preferences`

**Response** (200 OK):
```json
{
  "id": "ghi78901-e89b-12d3-a456-426614174005",
  "user_id": "user123",
  "email_enabled": true,
  "in_app_enabled": true,
  "push_enabled": false,
  "sms_enabled": false,
  "reminder_frequency": "daily",
  "task_updates_enabled": true,
  "recurring_task_enabled": true,
  "quiet_hours_enabled": true,
  "quiet_hours_start": "22:00:00",
  "quiet_hours_end": "08:00:00",
  "timezone": "America/New_York",
  "created_at": "2026-01-01T10:00:00Z",
  "updated_at": "2026-01-12T10:00:00Z"
}
```

### Update Notification Preferences

**Endpoint**: `PATCH /api/v1/notification-preferences`

**Request Body** (all fields optional):
```json
{
  "email_enabled": false,
  "quiet_hours_enabled": true,
  "quiet_hours_start": "23:00:00",
  "quiet_hours_end": "07:00:00",
  "timezone": "America/Los_Angeles"
}
```

**Response** (200 OK): Updated preferences object

---

## WebSocket API

### Connect to WebSocket

**Endpoint**: `WS /api/v1/ws`

**Query Parameters**:
- `token` (required): JWT access token

**Example**:
```javascript
const ws = new WebSocket('ws://localhost:8000/api/v1/ws?token=YOUR_JWT_TOKEN');

ws.onopen = () => {
  console.log('Connected to WebSocket');
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Received:', data);
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};

ws.onclose = () => {
  console.log('Disconnected from WebSocket');
};
```

### WebSocket Message Format

**Task Created**:
```json
{
  "type": "task.created",
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "title": "New task",
    "status": "pending",
    "priority": "high"
  },
  "timestamp": "2026-01-12T10:00:00Z"
}
```

**Task Updated**:
```json
{
  "type": "task.updated",
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "changes": {
      "status": {
        "before": "pending",
        "after": "in_progress"
      }
    }
  },
  "timestamp": "2026-01-12T11:00:00Z"
}
```

**Task Deleted**:
```json
{
  "type": "task.deleted",
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000"
  },
  "timestamp": "2026-01-12T12:00:00Z"
}
```

**Reminder Due**:
```json
{
  "type": "reminder.due",
  "data": {
    "task_id": "123e4567-e89b-12d3-a456-426614174000",
    "title": "Complete project documentation",
    "due_date": "2026-01-15T17:00:00Z"
  },
  "timestamp": "2026-01-15T09:00:00Z"
}
```

---

## Error Handling

### Error Response Format

All error responses follow this format:

```json
{
  "detail": "Error message",
  "error_code": "ERROR_CODE",
  "timestamp": "2026-01-12T10:00:00Z"
}
```

### HTTP Status Codes

- `200 OK`: Successful GET/PATCH request
- `201 Created`: Successful POST request
- `204 No Content`: Successful DELETE request
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Missing or invalid authentication
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `422 Unprocessable Entity`: Validation error
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

### Common Error Codes

- `INVALID_TOKEN`: JWT token is invalid or expired
- `MISSING_TOKEN`: Authorization header is missing
- `RESOURCE_NOT_FOUND`: Requested resource does not exist
- `PERMISSION_DENIED`: User lacks permission for this operation
- `VALIDATION_ERROR`: Request data failed validation
- `DUPLICATE_RESOURCE`: Resource already exists
- `RATE_LIMIT_EXCEEDED`: Too many requests

### Validation Error Format

```json
{
  "detail": [
    {
      "loc": ["body", "title"],
      "msg": "field required",
      "type": "value_error.missing"
    },
    {
      "loc": ["body", "priority"],
      "msg": "value is not a valid enumeration member; permitted: 'low', 'medium', 'high'",
      "type": "type_error.enum"
    }
  ]
}
```

---

## Rate Limiting

**Limits**:
- Authenticated requests: 1000 requests per hour
- Unauthenticated requests: 100 requests per hour

**Headers**:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1673539200
```

**Rate Limit Exceeded Response** (429):
```json
{
  "detail": "Rate limit exceeded. Try again in 3600 seconds.",
  "error_code": "RATE_LIMIT_EXCEEDED",
  "retry_after": 3600
}
```

---

## Pagination

All list endpoints support pagination with `offset` and `limit` parameters.

**Default Values**:
- `offset`: 0
- `limit`: 50 (max: 100)

**Response Format**:
```json
{
  "items": [...],
  "total": 150,
  "offset": 0,
  "limit": 50,
  "has_more": true
}
```

---

## OpenAPI Documentation

Interactive API documentation is available at:

- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **OpenAPI JSON**: `http://localhost:8000/openapi.json`

---

## Code Examples

### Python (requests)

```python
import requests

BASE_URL = "http://localhost:8000"
TOKEN = "your_jwt_token"

headers = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

# List tasks
response = requests.get(f"{BASE_URL}/api/v1/tasks", headers=headers)
tasks = response.json()

# Create task
task_data = {
    "title": "New task",
    "priority": "high",
    "tags": ["urgent"]
}
response = requests.post(f"{BASE_URL}/api/v1/tasks", json=task_data, headers=headers)
new_task = response.json()

# Update task
update_data = {"status": "in_progress"}
response = requests.patch(f"{BASE_URL}/api/v1/tasks/{new_task['id']}", json=update_data, headers=headers)
updated_task = response.json()
```

### JavaScript (fetch)

```javascript
const BASE_URL = 'http://localhost:8000';
const TOKEN = 'your_jwt_token';

const headers = {
  'Authorization': `Bearer ${TOKEN}`,
  'Content-Type': 'application/json'
};

// List tasks
const response = await fetch(`${BASE_URL}/api/v1/tasks`, { headers });
const tasks = await response.json();

// Create task
const taskData = {
  title: 'New task',
  priority: 'high',
  tags: ['urgent']
};
const createResponse = await fetch(`${BASE_URL}/api/v1/tasks`, {
  method: 'POST',
  headers,
  body: JSON.stringify(taskData)
});
const newTask = await createResponse.json();

// Update task
const updateData = { status: 'in_progress' };
const updateResponse = await fetch(`${BASE_URL}/api/v1/tasks/${newTask.id}`, {
  method: 'PATCH',
  headers,
  body: JSON.stringify(updateData)
});
const updatedTask = await updateResponse.json();
```

### cURL

```bash
# List tasks
curl -X GET "http://localhost:8000/api/v1/tasks" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Create task
curl -X POST "http://localhost:8000/api/v1/tasks" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "New task",
    "priority": "high",
    "tags": ["urgent"]
  }'

# Update task
curl -X PATCH "http://localhost:8000/api/v1/tasks/TASK_ID" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "in_progress"}'

# Delete task
curl -X DELETE "http://localhost:8000/api/v1/tasks/TASK_ID" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## Versioning

The API uses URL versioning. The current version is `v1`.

**Base Path**: `/api/v1/`

Future versions will be available at `/api/v2/`, `/api/v3/`, etc.

---

## Support

For API questions and issues:
- **Documentation**: [Architecture Overview](architecture.md)
- **Deployment**: [Deployment Guide](deployment.md)
- **GitHub Issues**: https://github.com/your-org/todo-app/issues

---

## Changelog

### v1.0 (2026-01-12)
- Initial API release
- Tasks CRUD operations
- Recurring tasks support
- Reminders functionality
- Tags management
- Saved filters
- Audit trail
- Notification preferences
- WebSocket real-time updates
