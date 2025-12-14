# Feature Specification: Tasks API & Endpoints

**Feature Branch**: `003-tasks-crud-api`
**Created**: 2025-12-13
**Completed**: 2025-12-13
**Status**: Complete ✅
**Input**: User description: "REST API endpoints for multi-user Todo app task management with JWT authentication, versioned routes, offset/limit pagination, status filtering, and RFC 7807 error responses"

---

## Implementation Summary

**All 17 functional requirements and 9 success criteria implemented and verified.**

### Deliverables

| Component | Location | Description |
|-----------|----------|-------------|
| Task Endpoints | `phase2/backend/app/api/v1/tasks.py` | 5 CRUD endpoints (GET list, POST, GET single, PATCH, DELETE) |
| JWT Auth | `phase2/backend/app/core/auth.py` | `get_current_user` dependency extracting `sub` claim |
| Pydantic Schemas | `phase2/backend/app/schemas/task.py` | TaskCreate, TaskUpdate, TaskResponse |
| Error Handling | `phase2/backend/app/core/exceptions.py` | RFC 7807 ProblemDetail responses |
| Structured Logging | `phase2/backend/app/core/logging.py` | JSON request logging middleware |
| Unit Tests | `phase2/backend/tests/unit/` | 34 tests (model + isolation) |
| Integration Tests | `phase2/backend/tests/integration/` | 38 tests (all endpoints + auth) |

### Test Results

- **72 total tests passing** (34 unit + 38 integration)
- Tests run against real Neon Postgres database
- User isolation verified across all CRUD operations
- All RFC 7807 error responses validated

---

## Intent

This specification defines the REST API layer for task management in a multi-user Todo application. The API exposes the Task entity (defined in `002-core-data-model`) via secure, authenticated HTTP endpoints that allow users to create, read, update, and delete their own tasks.

**Core Purpose**: Provide a secure, RESTful interface for task CRUD operations with strict user isolation, simple pagination, and machine-readable error responses.

**Key Characteristics**:
- Versioned API routes under `/api/v1/tasks`
- All endpoints require valid JWT authentication from Better Auth
- User isolation enforced at the API layer (users can only access their own tasks)
- Simple offset/limit pagination with 20 items default
- Status filtering via query parameter
- Consistent RFC 7807 Problem Details error format

---

## Constraints

### Technical Constraints
- **Backend Framework**: FastAPI (Python 3.13+)
- **ORM**: SQLModel with existing Task model from `002-core-data-model`
- **Database**: Neon Postgres (async via asyncpg)
- **Authentication**: Better Auth JWT tokens; validate via `Authorization: Bearer <token>` header
- **Code Location**: `phase2/backend/` directory only
- **Response Format**: Raw JSON objects/arrays (no envelope wrapper)
- **Error Format**: RFC 7807 Problem Details (`type`, `title`, `status`, `detail`, `instance`)

### Business Constraints
- **Auth Mandate**: All task endpoints require authentication; no anonymous/guest access
- **User Isolation**: API responses and mutations are scoped to the authenticated user only
- **Pagination**: Offset/limit with default page size of 20
- **Status Filter**: Only `?status=pending` and `?status=completed` supported; advanced filters deferred

### API Versioning Constraints
- All routes prefixed with `/api/v1/`
- Version bump strategy deferred to later specs

---

## User Scenarios & Testing

### User Story 1 - List My Tasks (Priority: P1)

An authenticated user retrieves their task list with optional pagination and status filtering.

**Why this priority**: Viewing tasks is the most frequent API call and the foundation for all UI interactions.

**Independent Test**: Can be fully tested by creating tasks for a user, then calling `GET /api/v1/tasks` and verifying correct results, pagination, and isolation.

**Acceptance Scenarios**:

1. **Given** User A is authenticated and has 5 tasks, **When** they call `GET /api/v1/tasks`, **Then** they receive a JSON array of their 5 tasks with status 200.
2. **Given** User A has 25 tasks, **When** they call `GET /api/v1/tasks` with no params, **Then** they receive the first 20 tasks (default limit).
3. **Given** User A has 25 tasks, **When** they call `GET /api/v1/tasks?offset=20&limit=10`, **Then** they receive tasks 21-25 (5 tasks).
4. **Given** User A has 3 pending and 2 completed tasks, **When** they call `GET /api/v1/tasks?status=pending`, **Then** they receive only the 3 pending tasks.
5. **Given** User A calls `GET /api/v1/tasks` without a valid JWT, **Then** they receive 401 Unauthorized with RFC 7807 error.
6. **Given** User A is authenticated, **When** they call `GET /api/v1/tasks`, **Then** they cannot see User B's tasks (isolation enforced).

---

### User Story 2 - Create a Task (Priority: P1)

An authenticated user creates a new task via the API.

**Why this priority**: Task creation is essential for the app to have any utility.

**Independent Test**: Can be tested by posting a valid task payload and verifying 201 response with created task.

**Acceptance Scenarios**:

1. **Given** User A is authenticated, **When** they `POST /api/v1/tasks` with `{"title": "Buy milk"}`, **Then** they receive 201 Created with the full task object including generated `id`, `user_id` matching their ID, `status: "pending"`, and timestamps.
2. **Given** User A is authenticated, **When** they `POST /api/v1/tasks` with `{"title": "Read book", "description": "Chapter 5"}`, **Then** both title and description are persisted.
3. **Given** User A is authenticated, **When** they `POST /api/v1/tasks` with `{}` (missing title), **Then** they receive 422 Unprocessable Entity with RFC 7807 error detailing validation failure.
4. **Given** User A is authenticated, **When** they `POST /api/v1/tasks` with `{"title": ""}` (empty title), **Then** they receive 422 Unprocessable Entity.
5. **Given** no JWT provided, **When** `POST /api/v1/tasks` is called, **Then** 401 Unauthorized is returned.

---

### User Story 3 - Get a Single Task (Priority: P2)

An authenticated user retrieves a specific task by ID.

**Why this priority**: Single-task fetch is needed for detail views and edit forms.

**Independent Test**: Create a task, then `GET /api/v1/tasks/{id}` and verify correct response.

**Acceptance Scenarios**:

1. **Given** User A owns task with ID `abc-123`, **When** they call `GET /api/v1/tasks/abc-123`, **Then** they receive the task object with status 200.
2. **Given** User A calls `GET /api/v1/tasks/{id}` for a task owned by User B, **Then** they receive 404 Not Found (isolation via 404, not 403).
3. **Given** User A calls `GET /api/v1/tasks/{non-existent-id}`, **Then** they receive 404 Not Found with RFC 7807 error.
4. **Given** User A calls `GET /api/v1/tasks/invalid-uuid-format`, **Then** they receive 422 Unprocessable Entity (invalid path parameter).

---

### User Story 4 - Update a Task (Priority: P2)

An authenticated user updates a task they own.

**Why this priority**: Editing and marking tasks complete is core to task management.

**Independent Test**: Create a task, `PATCH` it, and verify changes persist.

**Acceptance Scenarios**:

1. **Given** User A owns a pending task, **When** they `PATCH /api/v1/tasks/{id}` with `{"status": "completed"}`, **Then** the task status is updated and 200 OK returned with updated task.
2. **Given** User A owns a task, **When** they `PATCH /api/v1/tasks/{id}` with `{"title": "New title", "description": "New desc"}`, **Then** both fields are updated.
3. **Given** User A attempts to `PATCH` a task owned by User B, **Then** they receive 404 Not Found (isolation).
4. **Given** User A sends `PATCH /api/v1/tasks/{id}` with `{"status": "invalid"}`, **Then** they receive 422 Unprocessable Entity.
5. **Given** User A sends `PATCH /api/v1/tasks/{id}` with `{"title": ""}` (empty), **Then** they receive 422 Unprocessable Entity.

---

### User Story 5 - Delete a Task (Priority: P2)

An authenticated user deletes a task they own.

**Why this priority**: Cleanup capability completes the CRUD cycle.

**Independent Test**: Create a task, `DELETE` it, verify 204 response and task no longer exists.

**Acceptance Scenarios**:

1. **Given** User A owns task `abc-123`, **When** they call `DELETE /api/v1/tasks/abc-123`, **Then** they receive 204 No Content and the task is permanently removed.
2. **Given** User A attempts to `DELETE` a task owned by User B, **Then** they receive 404 Not Found.
3. **Given** User A calls `DELETE /api/v1/tasks/{non-existent-id}`, **Then** they receive 404 Not Found.

---

### Edge Cases

- What happens when `limit` exceeds 100? → Clamp to 100 maximum.
- What happens when `offset` is negative? → Return 422 validation error.
- What happens when `status` query param is invalid (e.g., `?status=foo`)? → Return 422 validation error.
- What happens with malformed JSON body? → Return 400 Bad Request with RFC 7807 error.
- What happens when JWT is expired? → Return 401 Unauthorized.
- What happens when JWT is malformed? → Return 401 Unauthorized.

---

## Requirements

### Functional Requirements

- **FR-001**: System MUST expose `GET /api/v1/tasks` to list authenticated user's tasks
- **FR-002**: System MUST expose `POST /api/v1/tasks` to create a task for authenticated user
- **FR-003**: System MUST expose `GET /api/v1/tasks/{id}` to retrieve a single task by ID
- **FR-004**: System MUST expose `PATCH /api/v1/tasks/{id}` to update a task (partial update)
- **FR-005**: System MUST expose `DELETE /api/v1/tasks/{id}` to remove a task
- **FR-006**: All endpoints MUST require valid JWT in `Authorization: Bearer <token>` header
- **FR-007**: All endpoints MUST return 401 Unauthorized for missing/invalid/expired JWT
- **FR-008**: List endpoint MUST support `offset` and `limit` query parameters for pagination
- **FR-009**: List endpoint MUST default to `offset=0` and `limit=20`
- **FR-010**: List endpoint MUST support `status` query parameter with values `pending` or `completed`
- **FR-010a**: List endpoint MUST return tasks sorted by `created_at DESC` (newest first) by default
- **FR-011**: All error responses MUST follow RFC 7807 Problem Details format
- **FR-012**: System MUST return 404 for tasks that don't exist OR belong to another user (isolation via 404)
- **FR-013**: System MUST validate request bodies and return 422 for validation errors
- **FR-014**: Create endpoint MUST return 201 Created with Location header pointing to new resource
- **FR-015**: Delete endpoint MUST return 204 No Content on success
- **FR-016**: System MUST automatically set `user_id` from JWT claims on task creation (client cannot override)
- **FR-017**: System MUST emit structured JSON logs for each request containing: request_id, user_id (if authenticated), endpoint, HTTP status, and response duration

### Key Entities

- **Task**: Existing SQLModel entity from `002-core-data-model` with id, user_id, title, description, status, created_at, updated_at
- **TaskCreate**: Pydantic schema for POST body (title required, description optional)
- **TaskUpdate**: Pydantic schema for PATCH body (all fields optional)
- **TaskResponse**: Pydantic schema for API responses (all Task fields)
- **ProblemDetail**: RFC 7807 error response schema

### API Endpoints Summary

| Method | Path | Request Body | Response | Description |
|--------|------|--------------|----------|-------------|
| GET | `/api/v1/tasks` | - | `Task[]` | List user's tasks |
| POST | `/api/v1/tasks` | `TaskCreate` | `Task` (201) | Create task |
| GET | `/api/v1/tasks/{id}` | - | `Task` | Get single task |
| PATCH | `/api/v1/tasks/{id}` | `TaskUpdate` | `Task` | Update task |
| DELETE | `/api/v1/tasks/{id}` | - | 204 | Delete task |

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: All 5 endpoints (`GET list`, `POST`, `GET single`, `PATCH`, `DELETE`) are functional and return correct status codes
- **SC-002**: 100% of requests without valid JWT return 401 Unauthorized with RFC 7807 body
- **SC-003**: User isolation enforced: User A cannot read, update, or delete User B's tasks (tested with multi-user scenarios)
- **SC-004**: Pagination works correctly: `offset` and `limit` params produce expected subsets of results
- **SC-005**: Status filter works: `?status=pending` and `?status=completed` return only matching tasks
- **SC-006**: All validation errors return 422 with RFC 7807 body including field-level details
- **SC-007**: Test coverage: Every endpoint has at least one success test and one error test (min 10+ integration tests)
- **SC-008**: Tests run against real Neon test database (not SQLite mocks)
- **SC-009**: Response times under 500ms for typical operations (sanity check, not strict SLA)

---

## Non-Goals

The following are explicitly **out of scope** for this specification:

- **Frontend/UI**: No React components, pages, or client-side code
- **Auth flows**: No login, signup, token refresh, or Better Auth configuration (assumed working)
- **Advanced filtering**: No search by title/description, date range filters, or sorting options
- **Bulk operations**: No batch create/update/delete endpoints
- **Soft delete**: Tasks are hard-deleted (no trash/restore)
- **Audit logging**: No history of who changed what
- **Rate limiting**: No request throttling
- **Caching**: No Redis or response caching layer
- **OpenAPI customization**: Auto-generated FastAPI docs are sufficient
- **Reminders/due dates**: No date-based features
- **Task sharing/collaboration**: No multi-user access to same task
- **WebSocket/real-time**: No live updates
- **File attachments**: No media upload

---

## Assumptions

- Better Auth is configured and JWT tokens contain a `sub` claim (RFC 7519 standard) that identifies the authenticated user's ID
- JWT validation middleware/dependency is available or will be implemented as part of this feature
- The existing Task model methods (`get_by_user`, `update_task`, `delete_task`) from `002-core-data-model` will be used
- FastAPI's dependency injection will be used for session management and auth
- Test database credentials are available in environment variables

---

## Dependencies

- **002-core-data-model**: Task SQLModel entity with CRUD methods (completed)
- **Better Auth**: JWT token issuance and validation
- **Neon Postgres**: Database (already configured in `database.py`)
- **FastAPI**: Web framework
- **Pydantic**: Request/response schemas

---

## Clarifications

### Session 2025-12-13

- Q: What is the exact JWT claim name for user ID? → A: `sub` (standard RFC 7519 subject claim)
- Q: What observability/logging approach? → A: Structured JSON logs for requests/errors (request_id, user_id, endpoint, status, duration)
- Q: What is the default sort order for task listings? → A: `created_at DESC` (newest first)

---

## Open Questions

1. ~~**JWT Claims Structure**: What is the exact claim name for user ID in Better Auth tokens (`sub`, `user_id`, `id`)?~~ → **Resolved**: Use `sub` claim (see Clarifications)
2. **CORS Configuration**: Should CORS headers be configured in this spec or separate? → *Deferred to frontend integration spec*
