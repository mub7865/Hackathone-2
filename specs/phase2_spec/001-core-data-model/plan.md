# Implementation Plan: Core Data & Domain Model

**Branch**: `002-core-data-model` | **Date**: 2025-12-12 | **Spec**: [spec.md](./spec.md)
**Status**: Complete ✅ | **Completed**: 2025-12-13
**Input**: Feature specification from `/specs/002-core-data-model/spec.md`

## Summary

Implement the foundational data model for a multi-user Todo application with strict user isolation. This includes defining the Task entity in SQLModel, configuring Neon Postgres connection, creating Alembic migrations, and establishing the user_id foreign key relationship to Better Auth users. The model enforces that every task belongs to exactly one user and provides the data layer for CRUD operations.

## Technical Context

**Language/Version**: Python 3.13+ (as per constitution Phase II)
**Primary Dependencies**: FastAPI, SQLModel, Alembic, asyncpg (Neon driver)
**Storage**: Neon Postgres (cloud-hosted PostgreSQL)
**Testing**: pytest with pytest-asyncio for async database tests
**Target Platform**: Linux server (containerized for Phase IV)
**Project Type**: Web application (backend focus for this spec; frontend separate)
**Performance Goals**: Standard web app latency (<500ms p95 for CRUD operations)
**Constraints**: User isolation must be enforced at query level; no cross-tenant data leakage
**Scale/Scope**: Hundreds to low thousands of users; clean model over premature optimization

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Strict SDD | PASS | Spec exists at `specs/002-core-data-model/spec.md` with clarifications complete |
| AI-Native Architecture | PASS | Model design supports future MCP/agent integration |
| Progressive Evolution | PASS | SQLModel allows schema evolution via Alembic migrations |
| Documentation First | PASS | Spec documented before implementation; plan precedes code |
| Tech Stack Adherence (Phase II) | PASS | Using FastAPI + SQLModel + Neon DB as specified |
| No "Vibe Coding" | PASS | All implementation will follow this plan |
| Type Safety | PASS | SQLModel provides Pydantic-based type safety |

**Gate Result**: PASS - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```text
specs/002-core-data-model/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── checklists/          # Quality validation
│   └── requirements.md
└── tasks.md             # Phase 2 output (created by /sp.tasks)
```

### Source Code (under phase2/)

```text
phase2/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py              # FastAPI app entry point
│   │   ├── config.py            # Settings and environment config
│   │   ├── database.py          # Neon connection and session management
│   │   └── models/
│   │       ├── __init__.py
│   │       └── task.py          # Task SQLModel definition
│   ├── alembic/
│   │   ├── alembic.ini
│   │   ├── env.py               # Alembic environment config
│   │   └── versions/
│   │       └── 001_create_task_table.py  # Initial migration
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── conftest.py          # pytest fixtures (test DB, mock users)
│   │   └── unit/
│   │       └── test_task_model.py  # Model validation tests
│   ├── pyproject.toml           # Python project config
│   └── .env.example             # Environment template
└── frontend/
    └── [separate spec - not modified by this feature]
```

**Structure Decision**: Phase II code lives under `phase2/` directory to separate from Phase I console app. Backend contains FastAPI + SQLModel code. Frontend directory reserved for Next.js (separate spec). Alembic migrations live in `phase2/backend/alembic/`.

## Complexity Tracking

> No violations detected. The plan uses standard SQLModel patterns without unnecessary abstractions.

---

## Phase 0: Research Summary

*See `research.md` for detailed findings.*

### Key Decisions

1. **SQLModel over raw SQLAlchemy**: SQLModel integrates Pydantic validation with SQLAlchemy ORM, reducing boilerplate and ensuring type safety.

2. **UUID for Task ID**: Using Python's `uuid.uuid4()` with SQLModel's `Field(default_factory=uuid4)` for globally unique identifiers.

3. **Enum for Status**: Python `enum.Enum` with SQLModel's `sa_column` for database CHECK constraint.

4. **Alembic for Migrations**: Industry standard for SQLAlchemy/SQLModel schema versioning; supports Neon Postgres.

5. **asyncpg for Neon**: Async PostgreSQL driver recommended by Neon for Python; compatible with SQLModel's async sessions.

---

## Phase 1: Design Artifacts

### 1.1 Data Model Design

*See `data-model.md` for complete entity definitions.*

#### Task Entity (Summary)

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | UUID | PK, NOT NULL, default uuid4() | Globally unique identifier |
| user_id | UUID (string) | FK → Better Auth users, NOT NULL, indexed | Owner reference |
| title | VARCHAR(255) | NOT NULL, non-empty | Required task name |
| description | TEXT | nullable | Optional details |
| status | ENUM('pending', 'completed') | NOT NULL, default 'pending' | Task state |
| created_at | TIMESTAMP WITH TZ | NOT NULL, default now() | Immutable creation time |
| updated_at | TIMESTAMP WITH TZ | NOT NULL, auto-update on modify | Last modification time |

#### Indexes

- `ix_task_user_id`: B-tree index on `user_id` for ownership queries
- `ix_task_user_status`: Composite index on `(user_id, status)` for filtered queries

#### Constraints

- `fk_task_user`: Foreign key to Better Auth user table (if referential integrity enabled)
- `chk_task_status`: CHECK constraint limiting status to allowed values
- `chk_task_title_not_empty`: CHECK constraint ensuring title is non-empty

### 1.2 Better Auth Integration

Better Auth manages the `user` table with its own schema. Our Task model references `user_id` as a string UUID that matches Better Auth's user identifier.

**Integration Pattern**:
- Task.user_id stores the UUID string from Better Auth
- No direct SQLModel relationship to User (Better Auth manages that table)
- Ownership queries filter by `user_id` obtained from authenticated JWT

### 1.3 Migration Strategy

1. **Initial Migration**: Create `task` table with all columns and constraints
2. **Rollback Support**: Each migration has `upgrade()` and `downgrade()` functions
3. **Idempotency**: Migrations check for table existence before creation
4. **Environment Parity**: Same migrations run in dev, test, and production

### 1.4 Invariants Enforcement

| Invariant | Enforcement Layer |
|-----------|-------------------|
| Task belongs to exactly one User | NOT NULL + FK constraint on user_id |
| User isolation in queries | Application layer: always filter by user_id |
| Valid status values | ENUM type + CHECK constraint |
| Title not empty | CHECK constraint + Pydantic validator |
| Title max 255 chars | VARCHAR(255) + Pydantic validator |
| Timestamps auto-managed | Database defaults + SQLModel event hooks |

---

## Implementation Sequence

The following sequence should be followed when implementing (to be expanded in `/sp.tasks`):

1. **Setup Backend Structure**
   - Create `phase2/backend/` directory structure
   - Initialize Python project with pyproject.toml
   - Configure UV for dependency management

2. **Configure Database Connection**
   - Create `phase2/backend/app/database.py` with Neon connection string (from env)
   - Setup async SQLModel engine and session factory
   - Add connection pooling configuration

3. **Define Task Model**
   - Create `phase2/backend/app/models/task.py` with SQLModel class
   - Add Pydantic validators for title and status
   - Configure UUID generation and timestamp defaults

4. **Setup Alembic**
   - Initialize Alembic in `phase2/backend/alembic/`
   - Configure `env.py` for async SQLModel
   - Point to Neon database URL

5. **Create Initial Migration**
   - Generate migration for `task` table
   - Include all indexes and constraints
   - Test upgrade and downgrade

6. **Write Unit Tests**
   - Test model validation (empty title, invalid status)
   - Test timestamp auto-generation
   - Test user_id requirement

7. **Write Integration Tests**
   - Test migration applies cleanly
   - Test CRUD operations with test database
   - Test user isolation (multi-user scenarios)

---

## Post-Design Constitution Re-Check

| Principle | Status | Notes |
|-----------|--------|-------|
| Strict SDD | PASS | Plan follows spec exactly |
| AI-Native Architecture | PASS | Model is simple, well-documented for AI agents |
| Progressive Evolution | PASS | Alembic migrations enable future schema changes |
| Documentation First | PASS | data-model.md and quickstart.md created |
| Type Safety | PASS | SQLModel + Pydantic enforce types |
| Minimal Complexity | PASS | No unnecessary abstractions; direct SQLModel usage |

**Final Gate Result**: PASS - Ready for `/sp.tasks`

---

## Next Steps

1. Run `/sp.tasks` to generate actionable task list from this plan
2. Implement tasks in dependency order
3. Validate against success criteria in spec
