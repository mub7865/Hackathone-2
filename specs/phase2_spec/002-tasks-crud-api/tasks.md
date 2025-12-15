# Tasks: Tasks API & Endpoints

**Input**: Design documents from `/specs/003-tasks-crud-api/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅
**Status**: Complete ✅
**Completed**: 2025-12-13

**Tests**: Integration tests are REQUIRED per SC-007 (minimum 10+ tests)
**Result**: 38 integration tests + 34 unit tests = **72 tests passing**

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US5, or INFRA for shared)
- All paths relative to `phase2/backend/`

---

## Phase 1: Setup (Shared Infrastructure) ✅

**Purpose**: Add dependencies and configure project

- [x] T001 [P] [INFRA] Add `python-jose[cryptography]` to `pyproject.toml`
- [x] T002 [P] [INFRA] Add JWT settings to `app/config.py` (JWT_SECRET, JWT_ALGORITHM)
- [x] T003 [P] [INFRA] Create `app/schemas/__init__.py` with exports

**Checkpoint**: ✅ Dependencies installed, configuration ready

---

## Phase 2: Foundational (Blocking Prerequisites) ✅

**Purpose**: Core infrastructure that MUST be complete before ANY endpoint

### Schemas (can run in parallel)

- [x] T004 [P] [INFRA] Create `app/schemas/error.py` with ProblemDetail, ValidationErrorDetail
- [x] T005 [P] [INFRA] Create `app/schemas/task.py` with TaskCreate, TaskUpdate, TaskResponse

### Core Infrastructure (can run in parallel after schemas)

- [x] T006 [P] [INFRA] Create `app/core/__init__.py`
- [x] T007 [P] [INFRA] Create `app/core/auth.py` - JWT validation, get_current_user dependency
- [x] T008 [P] [INFRA] Create `app/core/exceptions.py` - Custom exceptions + RFC 7807 handlers
- [x] T009 [P] [INFRA] Create `app/core/logging.py` - Structured JSON logging middleware

### API Structure (depends on T006-T009)

- [x] T010 [INFRA] Create `app/api/__init__.py`
- [x] T011 [INFRA] Create `app/api/deps.py` - get_db, get_current_user dependencies
- [x] T012 [INFRA] Create `app/api/v1/__init__.py`
- [x] T013 [INFRA] Create `app/api/v1/router.py` - v1 router aggregator

### Application Entrypoint (depends on all above)

- [x] T014 [INFRA] Create `app/main.py` - FastAPI app with routers, exception handlers, middleware

### Test Infrastructure

- [x] T015 [P] [INFRA] Create `tests/integration/__init__.py`
- [x] T016 [P] [INFRA] Create `tests/integration/conftest.py` - TestClient, mock JWT fixtures, auth_headers
- [x] T017 [INFRA] Update `tests/conftest.py` - Add shared auth fixtures

**Checkpoint**: ✅ Foundation ready - FastAPI app starts, auth works, error handling configured

---

## Phase 3: User Story 1 - List My Tasks (Priority: P1) 🎯 MVP ✅

**Goal**: Authenticated user can list their tasks with pagination and status filtering

### Tests for User Story 1

- [x] T018 [US1] Tests in `tests/integration/test_tasks_api.py::TestListTasks`:
  - ✅ List returns 200 with task array
  - ✅ Default pagination (offset=0, limit=20)
  - ✅ Custom offset/limit pagination
  - ✅ Status filter (?status=pending)
  - ✅ Status filter (?status=completed)
  - ✅ Empty list for user with no tasks
  - ✅ Invalid status returns 422
  - ✅ User isolation (User A cannot see User B's tasks)

### Implementation for User Story 1

- [x] T019 [US1] Created `app/api/v1/tasks.py` with `GET /tasks` endpoint
- [x] T020 [US1] Implemented list_tasks handler with pagination, filtering, sorting

**Checkpoint**: ✅ User Story 1 complete

---

## Phase 4: User Story 2 - Create a Task (Priority: P1) 🎯 MVP ✅

**Goal**: Authenticated user can create a new task

### Tests for User Story 2

- [x] T021 [US2] Tests in `tests/integration/test_tasks_api.py::TestCreateTask`:
  - ✅ Create returns 201 with task object
  - ✅ Task has correct user_id from JWT
  - ✅ Task status defaults to "pending"
  - ✅ Location header points to new resource
  - ✅ Missing title returns 422
  - ✅ Empty title returns 422
  - ✅ Title + description both persisted

### Implementation for User Story 2

- [x] T022 [US2] Added `POST /tasks` endpoint to `app/api/v1/tasks.py`

**Checkpoint**: ✅ User Stories 1 & 2 complete

---

## Phase 5: User Story 3 - Get a Single Task (Priority: P2) ✅

**Goal**: Authenticated user can retrieve a specific task by ID

### Tests for User Story 3

- [x] T023 [US3] Tests in `tests/integration/test_tasks_api.py::TestGetTask`:
  - ✅ Get own task returns 200 with task object
  - ✅ Get non-existent task returns 404
  - ✅ Get other user's task returns 404 (not 403)
  - ✅ Invalid UUID format returns 422

### Implementation for User Story 3

- [x] T024 [US3] Added `GET /tasks/{task_id}` endpoint

**Checkpoint**: ✅ User Stories 1-3 complete

---

## Phase 6: User Story 4 - Update a Task (Priority: P2) ✅

**Goal**: Authenticated user can update a task they own

### Tests for User Story 4

- [x] T025 [US4] Tests in `tests/integration/test_tasks_api.py::TestUpdateTask`:
  - ✅ Update status to "completed" returns 200
  - ✅ Update title and description returns 200
  - ✅ Partial update (only status) works
  - ✅ Update other user's task returns 404
  - ✅ Invalid status value returns 422
  - ✅ Empty title returns 422

### Implementation for User Story 4

- [x] T026 [US4] Added `PATCH /tasks/{task_id}` endpoint

**Checkpoint**: ✅ User Stories 1-4 complete

---

## Phase 7: User Story 5 - Delete a Task (Priority: P2) ✅

**Goal**: Authenticated user can delete a task they own

### Tests for User Story 5

- [x] T027 [US5] Tests in `tests/integration/test_tasks_api.py::TestDeleteTask`:
  - ✅ Delete own task returns 204
  - ✅ Task no longer exists after delete
  - ✅ Delete non-existent task returns 404
  - ✅ Delete other user's task returns 404

### Implementation for User Story 5

- [x] T028 [US5] Added `DELETE /tasks/{task_id}` endpoint

**Checkpoint**: ✅ All 5 CRUD endpoints complete

---

## Phase 8: Authentication & Cross-Cutting Tests ✅

**Purpose**: Verify auth enforcement and user isolation across all endpoints

### Authentication Tests

- [x] T029 [AUTH] Tests in `tests/integration/test_tasks_api.py::TestAuthErrors`:
  - ✅ No auth header returns 401 (all endpoints)
  - ✅ Invalid Bearer format returns 401
  - ✅ Expired JWT returns 401
  - ✅ Malformed JWT returns 401
  - ✅ Missing sub claim returns 401
  - ✅ All 401 responses use RFC 7807 format

### User Isolation Tests

- [x] T030 [AUTH] User isolation tests included in each endpoint test class:
  - ✅ User A cannot see User B's tasks in list
  - ✅ User A gets 404 for User B's task (get/update/delete)

**Checkpoint**: ✅ Authentication and isolation fully tested

---

## Phase 9: Polish & Verification ✅

**Purpose**: Final verification against success criteria

- [x] T031 [P] [POLISH] Verified all 9 success criteria (SC-001 to SC-009)
- [x] T032 [P] [POLISH] Full test suite passes: 72 tests (38 integration + 34 unit)
- [x] T033 [P] [POLISH] Structured JSON logging implemented (FR-017)
- [x] T034 [P] [POLISH] Response times verified
- [x] T035 [POLISH] Spec, plan, tasks marked complete
- [x] T036 [POLISH] Phase 9 verification pass completed

**Checkpoint**: ✅ Feature complete and verified

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup) ─────────────────────────────────────────────────┐
                                                                 │
Phase 2 (Foundational) ──────────────────────────────────────────┤
    T004-T005 (Schemas) ───┬── T006-T009 (Core) ──┬── T010-T013 (API) ── T014 (main.py)
                           │                      │
                           └──────────────────────┘
                                                                 │
    T015-T017 (Test Infra) ──────────────────────────────────────┤
                                                                 │
                    ┌────────────────────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────────────────────────────────────────┐
    │                    User Stories (can parallel)                     │
    │  US1 (List) ─── US2 (Create) ─── US3 (Get) ─── US4 (Update) ─── US5 (Delete)  │
    └───────────────────────────────────────────────────────────────────┘
                    │
                    ▼
    Phase 8 (Auth Tests) ── depends on all endpoints
                    │
                    ▼
    Phase 9 (Polish) ── depends on all tests
```

### User Story Dependencies

| Story | Depends On | Can Parallel With |
|-------|------------|-------------------|
| US1 (List) | Phase 2 complete | US2 |
| US2 (Create) | Phase 2 complete | US1 |
| US3 (Get) | Phase 2 complete | US4, US5 |
| US4 (Update) | Phase 2 complete | US3, US5 |
| US5 (Delete) | Phase 2 complete | US3, US4 |

### Parallel Opportunities

```bash
# Phase 1 - all parallel:
T001, T002, T003

# Phase 2 - schemas parallel, then core parallel:
T004, T005  # parallel
T006, T007, T008, T009  # parallel (after schemas)
T015, T016  # parallel (test infra)

# User Stories - can run in pairs:
# MVP: US1 + US2 together
# Then: US3, US4, US5 can parallel
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete US1 (List) + US2 (Create) in parallel
4. **STOP and VALIDATE**: Test listing and creating tasks
5. Deploy/demo MVP

### Full Feature

1. After MVP validated, add US3/US4/US5
2. Complete Phase 8 (Auth tests)
3. Complete Phase 9 (Polish)
4. Mark feature complete

---

## Task Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| 1. Setup | T001-T003 | Dependencies, config |
| 2. Foundational | T004-T017 | Schemas, core, API structure, test infra |
| 3. US1 List | T018-T020 | List endpoint + tests |
| 4. US2 Create | T021-T022 | Create endpoint + tests |
| 5. US3 Get | T023-T024 | Get single endpoint + tests |
| 6. US4 Update | T025-T026 | Update endpoint + tests |
| 7. US5 Delete | T027-T028 | Delete endpoint + tests |
| 8. Auth Tests | T029-T030 | 401 scenarios, user isolation |
| 9. Polish | T031-T036 | Verification, checklist |

**Total**: 36 tasks
**Estimated Integration Tests**: 25+ (exceeds SC-007 requirement of 10+)

---

## Notes

- All code under `phase2/backend/` per plan.md
- JWT uses `sub` claim per clarification
- User isolation via 404 (not 403) to prevent enumeration
- Default sort: `created_at DESC`
- Max pagination limit: 100
- Commit after each task or logical group
- Run `uv run pytest` frequently to catch regressions
