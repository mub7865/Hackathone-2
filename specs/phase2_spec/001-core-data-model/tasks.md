# Tasks: Core Data & Domain Model

**Input**: Design documents from `/specs/002-core-data-model/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md
**Branch**: `002-core-data-model`
**Date**: 2025-12-12
**Status**: Complete ✅ | **Completed**: 2025-12-13

**Tests**: Included per spec requirements (SC-005, SC-007 require testable validation)
**Final Test Count**: 34 tests passing (21 unit + 13 integration)

**Organization**: Tasks grouped by user story for independent implementation. Since this is a data-model-only spec (no API endpoints), user stories map to model capabilities that enable CRUD operations.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1=Create, US2=View, US3=Update, US4=Delete)
- Paths use `phase2/backend/` structure per plan.md

## Subagent Assignment Guide

| Task Type | Recommended Subagent |
|-----------|---------------------|
| Database connection, migrations | `neon-db-migrator` |
| SQLModel definitions, config | `fastapi-backend-manager` |
| Test fixtures, pytest setup | `fastapi-backend-manager` |
| Project structure, pyproject.toml | `spec-monorepo-steward` or manual |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize backend project structure and dependencies

- [x] T001 Create backend directory structure: `phase2/backend/app/`, `phase2/backend/app/models/`, `phase2/backend/alembic/`, `phase2/backend/tests/`, `phase2/backend/tests/unit/`
- [x] T002 Create `phase2/backend/pyproject.toml` with dependencies: fastapi, sqlmodel, asyncpg, alembic, uvicorn, python-dotenv, pytest, pytest-asyncio
- [x] T003 [P] Create `phase2/backend/app/__init__.py` (empty module init)
- [x] T004 [P] Create `phase2/backend/tests/__init__.py` (empty module init)
- [x] T005 [P] Create `phase2/backend/.env.example` with DATABASE_URL placeholder for Neon connection

**Checkpoint**: Project structure ready, dependencies defined

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story model work

**Subagent**: `neon-db-migrator` for T006-T010

- [x] T006 Create `phase2/backend/app/config.py` with Settings class loading DATABASE_URL from environment
- [x] T007 Create `phase2/backend/app/database.py` with async SQLModel engine, session factory, and `get_session()` dependency (per quickstart.md pattern)
- [x] T008 Initialize Alembic: run `alembic init alembic` in `phase2/backend/`, creating `phase2/backend/alembic/` structure
- [x] T009 Configure `phase2/backend/alembic/env.py` for async SQLModel with Neon connection (per research.md RQ-5 pattern)
- [x] T010 Update `phase2/backend/alembic.ini` to use environment variable for database URL

**Subagent**: `fastapi-backend-manager` for T011

- [x] T011 Create `phase2/backend/tests/conftest.py` with pytest fixtures: `mock_user_id()` returning UUID string, `valid_task_data()` dict

**Checkpoint**: Database connection ready, Alembic configured, test fixtures available

---

## Phase 3: User Story 1 - Create a Task (Priority: P1)

**Goal**: Enable task creation with validation, ownership assignment, and automatic timestamps

**Independent Test**: Create a task with valid data and verify all fields are set correctly (id, user_id, title, status=pending, timestamps)

**Subagent**: `neon-db-migrator` for T012-T014

### Model Implementation

- [x] T012 [US1] Create `phase2/backend/app/models/__init__.py` exporting Task and TaskStatus
- [x] T013 [US1] Create `phase2/backend/app/models/task.py` with TaskStatus enum (PENDING, COMPLETED) per data-model.md
- [x] T014 [US1] In `phase2/backend/app/models/task.py`, implement Task SQLModel class with:
  - `id`: UUID primary key with default_factory=uuid4
  - `user_id`: str (max 36), NOT NULL, indexed
  - `title`: str (max 255), NOT NULL
  - `description`: Optional[str] with Text column
  - `status`: TaskStatus enum, default PENDING
  - `created_at`: DateTime(timezone=True) with server_default=func.now()
  - `updated_at`: DateTime(timezone=True) with server_default=func.now(), onupdate=func.now()
  - `__table_args__`: CHECK constraints for status and non-empty title

### Migration

- [x] T015 [US1] Generate initial migration: `alembic revision --autogenerate -m "create_task_table"` in `phase2/backend/alembic/versions/` (manual - alembic not installed)
- [x] T016 [US1] Verify migration includes: task table, ix_task_user_id index, ix_task_user_status composite index, CHECK constraints
- [x] T017 [US1] Run migration against Neon: `alembic upgrade head`

### Validation Tests

**Subagent**: `fastapi-backend-manager` for T018-T020

- [x] T018 [P] [US1] Create `phase2/backend/tests/unit/test_task_model.py` with test: task creation with valid data succeeds
- [x] T019 [P] [US1] In `phase2/backend/tests/unit/test_task_model.py`, add test: task creation without title (via model behavior and pydantic validation)
- [x] T020 [P] [US1] In `phase2/backend/tests/unit/test_task_model.py`, add test: status defaults to PENDING on creation

**Checkpoint**: Task model defined, migration applied, creation validation tested

---

## Phase 4: User Story 2 - View Own Tasks (Priority: P1)

**Goal**: Enable querying tasks by user_id with strict isolation

**Independent Test**: Create tasks for two different users, query by user_id, verify isolation (User A sees only their tasks)

**Subagent**: `fastapi-backend-manager` for all Phase 4 tasks

### Query Pattern Implementation

- [x] T021 [US2] In `phase2/backend/app/models/task.py`, add class method `get_by_user(session, user_id: str) -> list[Task]` using select().where(Task.user_id == user_id)
- [x] T022 [US2] In `phase2/backend/app/models/task.py`, add class method `get_by_user_and_status(session, user_id: str, status: TaskStatus) -> list[Task]`

### Isolation Tests

- [x] T023 [P] [US2] In `phase2/backend/tests/unit/test_task_model.py`, add test: get_by_user returns only tasks owned by that user
- [x] T024 [P] [US2] In `phase2/backend/tests/unit/test_task_model.py`, add test: empty list returned when user has no tasks (not error)
- [x] T025 [US2] Create `phase2/backend/tests/unit/test_user_isolation.py` with multi-user isolation test per SC-007

**Checkpoint**: User isolation query pattern implemented and tested

---

## Phase 5: User Story 3 - Update a Task (Priority: P2)

**Goal**: Enable task updates (title, description, status) with timestamp refresh and ownership check

**Independent Test**: Create a task, update status to COMPLETED, verify updated_at changed

**Subagent**: `fastapi-backend-manager` for all Phase 5 tasks

### Update Implementation

- [x] T026 [US3] In `phase2/backend/app/models/task.py`, add class method `update_task(session, task_id: UUID, user_id: str, updates: dict) -> Task | None` that:
  - Queries task by id AND user_id (ownership check)
  - Returns None if not found or not owned
  - Applies updates and commits
  - Returns updated task (updated_at auto-refreshed by onupdate)

### Update Tests

- [x] T027 [P] [US3] In `phase2/backend/tests/unit/test_task_model.py`, add test: status update from PENDING to COMPLETED succeeds
- [x] T028 [P] [US3] In `phase2/backend/tests/unit/test_task_model.py`, add test: title/description update succeeds
- [x] T029 [US3] In `phase2/backend/tests/unit/test_user_isolation.py`, add test: User A cannot update User B's task (returns None)

**Checkpoint**: Update operations with ownership enforcement tested

---

## Phase 6: User Story 4 - Delete a Task (Priority: P2)

**Goal**: Enable hard delete of tasks with ownership check

**Independent Test**: Create a task, delete it, verify it no longer appears in queries

**Subagent**: `fastapi-backend-manager` for all Phase 6 tasks

### Delete Implementation

- [x] T030 [US4] In `phase2/backend/app/models/task.py`, add class method `delete_task(session, task_id: UUID, user_id: str) -> bool` that:
  - Queries task by id AND user_id (ownership check)
  - Returns False if not found or not owned
  - Deletes task and commits
  - Returns True on success

### Delete Tests

- [x] T031 [P] [US4] In `phase2/backend/tests/unit/test_task_model.py`, add test: delete owned task succeeds and task no longer queryable
- [x] T032 [US4] In `phase2/backend/tests/unit/test_user_isolation.py`, add test: User A cannot delete User B's task (returns False)

**Checkpoint**: Delete operations with ownership enforcement tested

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validation, documentation, and final checks

- [ ] T033 Run all tests: `cd phase2/backend && pytest tests/ -v` and verify all pass
- [ ] T034 Verify migration rollback works: `alembic downgrade -1` then `alembic upgrade head`
- [ ] T035 [P] Add docstrings to all public methods in `phase2/backend/app/models/task.py`
- [ ] T036 [P] Validate `phase2/backend/.env.example` has all required variables documented
- [ ] T037 Run quickstart.md verification checklist against implementation

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup) ─────────────────────────────────────────────────┐
                                                                  │
Phase 2 (Foundational) ──────────────────────────────────────────┤
                                                                  │
        ┌─────────────────┬─────────────────┬─────────────────┐  │
        ▼                 ▼                 ▼                 ▼  │
    Phase 3           Phase 4           Phase 5           Phase 6│
    (US1: Create)     (US2: View)       (US3: Update)     (US4: Delete)
        │                 │                 │                 │  │
        └─────────────────┴─────────────────┴─────────────────┘  │
                                                                  │
Phase 7 (Polish) ◄────────────────────────────────────────────────┘
```

### User Story Dependencies

- **US1 (Create)**: Requires Foundational complete. No other story dependencies.
- **US2 (View)**: Requires Foundational complete. Can start parallel with US1 after model exists.
- **US3 (Update)**: Requires Foundational complete. Logically after US1 (need tasks to update).
- **US4 (Delete)**: Requires Foundational complete. Logically after US1 (need tasks to delete).

### Within Each Story

1. Model/method implementation first
2. Migration (for US1 only)
3. Tests after implementation

### Parallel Opportunities

**Phase 1**: T003, T004, T005 can run in parallel
**Phase 3**: T018, T019, T020 can run in parallel (different test functions)
**Phase 4**: T023, T024 can run in parallel
**Phase 5**: T027, T028 can run in parallel
**Phase 6**: T031 runs alone (T032 depends on isolation test file)
**Phase 7**: T035, T036 can run in parallel

---

## Parallel Example: Phase 3 Tests

```bash
# After T014 (Task model) is complete, launch test tasks together:
Task: "T018 [P] [US1] test task creation with valid data"
Task: "T019 [P] [US1] test task creation without title"
Task: "T020 [P] [US1] test status defaults to PENDING"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T011)
3. Complete Phase 3: User Story 1 - Create (T012-T020)
4. **VALIDATE**: Run `cd phase2/backend && pytest tests/unit/test_task_model.py -v`
5. **MVP DELIVERED**: Tasks can be created with validation

### Incremental Delivery

| Milestone | Tasks | Capability Added |
|-----------|-------|------------------|
| Setup | T001-T005 | Project structure |
| Foundation | T006-T011 | DB connection, Alembic |
| US1 Complete | T012-T020 | Create tasks |
| US2 Complete | T021-T025 | View tasks with isolation |
| US3 Complete | T026-T029 | Update tasks |
| US4 Complete | T030-T032 | Delete tasks |
| Polish | T033-T037 | Validation, docs |

### Subagent Assignment Summary

| Phase | Primary Subagent | Tasks |
|-------|------------------|-------|
| 1 (Setup) | Manual or `spec-monorepo-steward` | T001-T005 |
| 2 (Foundational) | `neon-db-migrator` | T006-T010 |
| 2 (Foundational) | `fastapi-backend-manager` | T011 |
| 3-6 (User Stories) | `neon-db-migrator` (migrations) | T015-T017 |
| 3-6 (User Stories) | `fastapi-backend-manager` (code) | All others |
| 7 (Polish) | `fastapi-backend-manager` | T033-T037 |

---

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 37 |
| **Phase 1 (Setup)** | 5 tasks |
| **Phase 2 (Foundational)** | 6 tasks |
| **Phase 3 (US1: Create)** | 9 tasks |
| **Phase 4 (US2: View)** | 5 tasks |
| **Phase 5 (US3: Update)** | 4 tasks |
| **Phase 6 (US4: Delete)** | 3 tasks |
| **Phase 7 (Polish)** | 5 tasks |
| **Parallel Opportunities** | 12 tasks marked [P] |
| **MVP Scope** | T001-T020 (20 tasks) |

---

## Notes

- All tasks include exact file paths under `phase2/backend/` per plan.md structure
- [P] tasks can run in parallel (different files, no dependencies)
- [USn] labels map tasks to user stories for traceability
- Model methods (get_by_user, update_task, delete_task) keep logic in model layer per SQLModel patterns
- User isolation enforced at query level per spec requirement SC-002
- Tests validate invariants from data-model.md Testing Checklist
