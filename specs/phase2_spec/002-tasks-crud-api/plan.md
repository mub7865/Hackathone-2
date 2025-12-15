# Implementation Plan: Tasks API & Endpoints

**Branch**: `003-tasks-crud-api` | **Date**: 2025-12-13 | **Spec**: [spec.md](./spec.md)
**Status**: Complete ✅
**Completed**: 2025-12-13

---

## Implementation Summary

All planned deliverables implemented and verified:

- ✅ FastAPI router with 5 CRUD endpoints under `/api/v1/tasks`
- ✅ JWT authentication dependency extracting user ID from `sub` claim
- ✅ Pydantic schemas for request/response validation
- ✅ RFC 7807 Problem Details error handling
- ✅ Structured JSON request logging middleware (disabled in tests due to BaseHTTPMiddleware compatibility)
- ✅ 38 integration tests against Neon Postgres
- ✅ 34 unit tests for model and isolation

**Key Implementation Decisions**:
- Used `NullPool` for test database connections to avoid async event loop issues
- Added `reset_engine()` to database module for test isolation
- Logging middleware conditionally disabled in test environment
- Unique user IDs generated per test for proper isolation against shared database

---

## Summary

Implement a RESTful API layer for task CRUD operations in a multi-user Todo application. The API exposes the existing Task SQLModel entity via authenticated FastAPI endpoints with JWT validation, offset/limit pagination, status filtering, and RFC 7807 error responses. All code lives under `phase2/backend/`.

**Key deliverables**:
1. FastAPI router with 5 CRUD endpoints under `/api/v1/tasks`
2. JWT authentication dependency extracting user ID from `sub` claim
3. Pydantic schemas for request/response validation
4. RFC 7807 Problem Details error handling
5. Structured JSON request logging middleware
6. Integration tests against Neon Postgres

---

## Technical Context

**Language/Version**: Python 3.13+
**Primary Dependencies**: FastAPI 0.115+, SQLModel 0.0.22+, Pydantic v2, python-jose (JWT), uvicorn
**Storage**: Neon Postgres (async via asyncpg) - already configured
**Testing**: pytest + pytest-asyncio + httpx (TestClient)
**Target Platform**: Linux server / containerized backend
**Project Type**: Web application (backend API only for this feature)
**Performance Goals**: <500ms p95 response time for typical operations
**Constraints**: All endpoints require JWT auth; user isolation enforced
**Scale/Scope**: Hundreds to low thousands of users; 20 items default pagination

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| **Strict SDD** | ✅ PASS | Spec created and clarified before this plan |
| **AI-Native Architecture** | ✅ PASS | API layer supports future MCP/AI agent integration |
| **Progressive Evolution** | ✅ PASS | Builds on 002-core-data-model; no rewrites needed |
| **Documentation First** | ✅ PASS | Spec → Plan → Tasks workflow followed |
| **Phase II Tech Stack** | ✅ PASS | FastAPI, SQLModel, Neon DB, Better Auth JWT |
| **Type-safe Python** | ✅ PASS | Pydantic schemas, type hints throughout |
| **Monorepo Structure** | ✅ PASS | All code under `phase2/backend/` |
| **No Vibe Coding** | ✅ PASS | Implementation follows approved spec |

**Gate Result**: PASS - Proceed to Phase 0

---

## Project Structure

### Documentation (this feature)

```text
specs/003-tasks-crud-api/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (API schemas)
├── quickstart.md        # Phase 1 output (developer guide)
├── contracts/           # Phase 1 output (OpenAPI excerpts)
│   └── openapi-tasks.yaml
└── tasks.md             # Phase 2 output (from /sp.tasks)
```

### Source Code (Phase II Backend)

```text
phase2/backend/
├── app/
│   ├── __init__.py              # Existing
│   ├── config.py                # Existing - add JWT settings
│   ├── database.py              # Existing - no changes needed
│   ├── main.py                  # NEW: FastAPI app entrypoint
│   ├── models/
│   │   ├── __init__.py          # Existing - exports Task, TaskStatus
│   │   └── task.py              # Existing - Task SQLModel
│   ├── schemas/                 # NEW: Pydantic schemas
│   │   ├── __init__.py
│   │   ├── task.py              # TaskCreate, TaskUpdate, TaskResponse
│   │   └── error.py             # ProblemDetail (RFC 7807)
│   ├── api/                     # NEW: API layer
│   │   ├── __init__.py
│   │   ├── v1/
│   │   │   ├── __init__.py
│   │   │   ├── router.py        # v1 router aggregator
│   │   │   └── tasks.py         # Task CRUD endpoints
│   │   └── deps.py              # Shared dependencies (auth, db session)
│   ├── core/                    # NEW: Core utilities
│   │   ├── __init__.py
│   │   ├── auth.py              # JWT validation, get_current_user
│   │   ├── exceptions.py        # Custom exceptions + handlers
│   │   └── logging.py           # Structured JSON logging middleware
│   └── services/                # NEW: Business logic layer (optional)
│       ├── __init__.py
│       └── task_service.py      # Task operations (wraps model methods)
├── tests/
│   ├── __init__.py              # Existing
│   ├── conftest.py              # Existing - add auth fixtures
│   ├── unit/                    # Existing
│   │   ├── test_task_model.py   # Existing
│   │   └── test_user_isolation.py # Existing
│   └── integration/             # NEW: API integration tests
│       ├── __init__.py
│       ├── conftest.py          # TestClient, auth helpers
│       ├── test_tasks_list.py   # GET /api/v1/tasks tests
│       ├── test_tasks_create.py # POST /api/v1/tasks tests
│       ├── test_tasks_get.py    # GET /api/v1/tasks/{id} tests
│       ├── test_tasks_update.py # PATCH /api/v1/tasks/{id} tests
│       ├── test_tasks_delete.py # DELETE /api/v1/tasks/{id} tests
│       └── test_auth.py         # Authentication error tests
├── pyproject.toml               # Existing - add python-jose dependency
├── alembic.ini                  # Existing
├── alembic/                     # Existing
└── .env.example                 # Existing - add JWT_SECRET
```

**Structure Decision**: Web application backend structure under `phase2/backend/`. API layer (`api/`), schemas (`schemas/`), and core utilities (`core/`) are new directories. Services layer is optional but recommended for separation of concerns.

---

## Implementation Phases

### Phase 0: Research & Validation

**Objective**: Confirm technical decisions and resolve any remaining unknowns.

| Topic | Decision | Rationale |
|-------|----------|-----------|
| JWT Library | `python-jose[cryptography]` | Industry standard, supports HS256/RS256, Pydantic-friendly |
| JWT Validation | Decode + verify `sub` claim | Better Auth uses `sub` for user ID per RFC 7519 |
| Error Handling | FastAPI exception handlers | Native integration, returns JSON automatically |
| Logging | `structlog` or stdlib + JSON formatter | Structured logs for observability |
| Test Auth | Mock JWT with known `sub` | Isolates API tests from real auth service |

**Output**: `research.md`

---

### Phase 1: Design & Contracts

**Objective**: Define API schemas, error formats, and developer quickstart.

#### 1.1 Pydantic Schemas (data-model.md)

```python
# TaskCreate - POST request body
class TaskCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: str | None = None

# TaskUpdate - PATCH request body
class TaskUpdate(BaseModel):
    title: str | None = Field(None, min_length=1, max_length=255)
    description: str | None = None
    status: TaskStatus | None = None

# TaskResponse - All endpoints return this
class TaskResponse(BaseModel):
    id: UUID
    user_id: str
    title: str
    description: str | None
    status: TaskStatus
    created_at: datetime
    updated_at: datetime

# ProblemDetail - RFC 7807 error response
class ProblemDetail(BaseModel):
    type: str = "about:blank"
    title: str
    status: int
    detail: str | None = None
    instance: str | None = None
```

#### 1.2 API Contract (contracts/openapi-tasks.yaml)

| Endpoint | Method | Request | Response | Errors |
|----------|--------|---------|----------|--------|
| `/api/v1/tasks` | GET | Query: offset, limit, status | `TaskResponse[]` | 401, 422 |
| `/api/v1/tasks` | POST | Body: `TaskCreate` | `TaskResponse` (201) | 401, 422 |
| `/api/v1/tasks/{id}` | GET | Path: UUID | `TaskResponse` | 401, 404, 422 |
| `/api/v1/tasks/{id}` | PATCH | Body: `TaskUpdate` | `TaskResponse` | 401, 404, 422 |
| `/api/v1/tasks/{id}` | DELETE | Path: UUID | 204 No Content | 401, 404 |

#### 1.3 Authentication Flow

```text
Request → Extract Authorization header
       → Decode JWT (verify signature)
       → Extract `sub` claim as user_id
       → Inject user_id into route handler
       → Query/mutate only user's tasks
```

**Output**: `data-model.md`, `contracts/openapi-tasks.yaml`, `quickstart.md`

---

### Phase 2: Implementation Tasks (generated by /sp.tasks)

High-level task breakdown:

| # | Task | Priority | Dependencies |
|---|------|----------|--------------|
| 1 | Add python-jose to pyproject.toml | P0 | None |
| 2 | Create Pydantic schemas (schemas/) | P0 | None |
| 3 | Implement JWT auth dependency (core/auth.py) | P0 | Task 1 |
| 4 | Implement RFC 7807 exception handlers | P0 | Task 2 |
| 5 | Create FastAPI app entrypoint (main.py) | P0 | Tasks 3, 4 |
| 6 | Implement logging middleware | P1 | Task 5 |
| 7 | Implement GET /api/v1/tasks (list) | P1 | Task 5 |
| 8 | Implement POST /api/v1/tasks (create) | P1 | Task 5 |
| 9 | Implement GET /api/v1/tasks/{id} | P1 | Task 5 |
| 10 | Implement PATCH /api/v1/tasks/{id} | P1 | Task 5 |
| 11 | Implement DELETE /api/v1/tasks/{id} | P1 | Task 5 |
| 12 | Write integration tests for all endpoints | P1 | Tasks 7-11 |
| 13 | Add auth error tests (401 scenarios) | P1 | Task 12 |
| 14 | Add user isolation tests | P1 | Task 12 |
| 15 | Verify against success criteria | P2 | All above |

---

## Files to Create/Modify

### New Files (14)

| File | Purpose |
|------|---------|
| `phase2/backend/app/main.py` | FastAPI application entrypoint |
| `phase2/backend/app/schemas/__init__.py` | Schema exports |
| `phase2/backend/app/schemas/task.py` | Task request/response schemas |
| `phase2/backend/app/schemas/error.py` | RFC 7807 ProblemDetail |
| `phase2/backend/app/api/__init__.py` | API package |
| `phase2/backend/app/api/deps.py` | Shared dependencies |
| `phase2/backend/app/api/v1/__init__.py` | v1 package |
| `phase2/backend/app/api/v1/router.py` | v1 router aggregator |
| `phase2/backend/app/api/v1/tasks.py` | Task CRUD endpoints |
| `phase2/backend/app/core/__init__.py` | Core package |
| `phase2/backend/app/core/auth.py` | JWT validation |
| `phase2/backend/app/core/exceptions.py` | Exception handlers |
| `phase2/backend/app/core/logging.py` | Structured logging |
| `phase2/backend/tests/integration/__init__.py` | Integration test package |

### Modified Files (3)

| File | Changes |
|------|---------|
| `phase2/backend/pyproject.toml` | Add python-jose, structlog dependencies |
| `phase2/backend/app/config.py` | Add JWT_SECRET, JWT_ALGORITHM settings |
| `phase2/backend/tests/conftest.py` | Add auth fixtures for testing |

### Test Files (7)

| File | Coverage |
|------|----------|
| `tests/integration/conftest.py` | TestClient, mock JWT fixtures |
| `tests/integration/test_tasks_list.py` | List endpoint + pagination + filtering |
| `tests/integration/test_tasks_create.py` | Create endpoint + validation |
| `tests/integration/test_tasks_get.py` | Get single task + 404 cases |
| `tests/integration/test_tasks_update.py` | Update endpoint + validation |
| `tests/integration/test_tasks_delete.py` | Delete endpoint |
| `tests/integration/test_auth.py` | 401 error scenarios |

---

## Risk Analysis

| Risk | Impact | Mitigation |
|------|--------|------------|
| JWT secret not configured | Auth fails in all environments | Fail fast on startup if JWT_SECRET missing |
| Better Auth token format mismatch | Auth decode fails | Test with real Better Auth token in staging |
| Async session leaks | Connection pool exhaustion | Use FastAPI dependency lifecycle properly |
| Test isolation failures | Flaky tests | Use transaction rollback per test |

---

## Success Criteria Mapping

| Spec Criteria | Plan Coverage |
|---------------|---------------|
| SC-001: 5 endpoints functional | Tasks 7-11 |
| SC-002: 401 for invalid JWT | Task 3, 13 |
| SC-003: User isolation | Task 14, existing model tests |
| SC-004: Pagination works | Task 7, test_tasks_list.py |
| SC-005: Status filter works | Task 7, test_tasks_list.py |
| SC-006: 422 with RFC 7807 | Task 4, all integration tests |
| SC-007: 10+ integration tests | Tasks 12-14 (target: 15+) |
| SC-008: Real Neon database | conftest.py uses DATABASE_URL |
| SC-009: <500ms response | Verify in test assertions |

---

## Next Steps

1. Run `/sp.tasks` to generate detailed, testable implementation tasks
2. Implement in priority order (P0 → P1 → P2)
3. Run tests after each task group
4. Verify all success criteria before marking feature complete

---

## Appendix: Dependency Graph

```text
pyproject.toml (deps)
        ↓
    config.py (JWT settings)
        ↓
    core/auth.py ←──────────────────┐
        ↓                           │
    core/exceptions.py              │
        ↓                           │
    schemas/*.py                    │
        ↓                           │
    api/deps.py ────────────────────┘
        ↓
    api/v1/tasks.py
        ↓
    api/v1/router.py
        ↓
    main.py
        ↓
    tests/integration/*
```
