# Implementation Plan: Task Querying & Listing Behavior

**Branch**: `005-task-query-listing` | **Date**: 2025-12-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-task-query-listing/spec.md`

---

## Summary

Extend the existing `/api/v1/tasks` endpoint with search, sorting, and pagination parameters while upgrading the Next.js `/tasks` page to support combined filtering with full URL state synchronization. This enables users to quickly find specific tasks among up to 1000 items using free-text search, flexible sorting, and "Load More" pagination.

## Technical Context

**Language/Version**: Python 3.13+ (backend), TypeScript/Next.js 16+ (frontend)
**Primary Dependencies**: FastAPI 0.115+, SQLModel 0.0.22+, Pydantic v2 (backend); React 19, Next.js App Router (frontend)
**Storage**: Neon PostgreSQL (async via asyncpg)
**Testing**: pytest + httpx (backend integration tests); manual test plan (frontend)
**Target Platform**: Web application (Linux server backend, browser frontend)
**Project Type**: Web application (frontend + backend)
**Performance Goals**: <500ms for filtered/sorted queries with 1000 tasks per user
**Constraints**: User isolation via JWT, no new domain concepts (priorities/tags/due dates)
**Scale/Scope**: ~1000 tasks per user, single authenticated user context

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| Strict SDD | ✅ PASS | Spec created and clarified before planning |
| AI-Native Architecture | ✅ PASS | Extends existing patterns, no AI features in scope |
| Progressive Evolution | ✅ PASS | Builds on Chunks 1-3 without rewrites |
| Documentation First | ✅ PASS | spec.md → plan.md → research.md → data-model.md |
| Tech Stack Adherence | ✅ PASS | Using Phase II stack (FastAPI, SQLModel, Next.js) |
| No Vibe Coding | ✅ PASS | All changes spec-driven |

## Project Structure

### Documentation (this feature)

```text
specs/005-task-query-listing/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file (complete)
├── research.md          # Phase 0 output (complete)
├── data-model.md        # Phase 1 output (complete)
├── quickstart.md        # Phase 1 output (complete)
├── checklists/
│   └── requirements.md  # Spec quality checklist (complete)
└── tasks.md             # Phase 2 output (/sp.tasks command)
```

### Source Code (repository root)

```text
phase2/
├── backend/
│   ├── app/
│   │   ├── api/v1/
│   │   │   └── tasks.py         # Extend list_tasks endpoint
│   │   ├── schemas/
│   │   │   └── task.py          # Add SortField, SortOrder enums
│   │   └── models/
│   │       └── task.py          # No changes needed
│   └── tests/
│       └── integration/
│           └── test_tasks_api.py # Add search/sort test classes
│
└── frontend/
    ├── app/
    │   └── (authenticated)/
    │       └── tasks/
    │           └── page.tsx      # Integrate new controls
    ├── components/
    │   └── tasks/
    │       ├── TaskFilterTabs.tsx    # Wire to query state
    │       ├── TaskSearchInput.tsx   # NEW: Debounced search
    │       └── TaskSortDropdown.tsx  # NEW: Sort selector
    ├── hooks/
    │   ├── useTasks.ts           # Accept query params
    │   └── useTaskQuery.ts       # NEW: URL ↔ state sync
    ├── lib/
    │   └── api/
    │       └── tasks.ts          # Extend listTasks params
    └── types/
        └── task.ts               # Add sort types
```

**Structure Decision**: Web application structure (Option 2) - extends existing `phase2/backend` and `phase2/frontend` directories established in Chunks 1-3.

## Complexity Tracking

No constitution violations requiring justification. This chunk:
- Extends existing endpoint (no new routes)
- Adds 2 new frontend components (search input, sort dropdown)
- Creates 1 new hook (useTaskQuery for URL sync)
- No new database tables or migrations

---

## Architecture Overview

### Backend Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GET /api/v1/tasks                        │
│  ?status=pending&search=report&sort=title&order=asc         │
│  &offset=0&limit=20                                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Query Parameter Layer                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────┐  │
│  │ status   │ │ search   │ │ sort     │ │ offset/limit  │  │
│  │ (enum)   │ │ (str≤100)│ │ (enum)   │ │ (int)         │  │
│  └──────────┘ └──────────┘ └──────────┘ └───────────────┘  │
│                         FastAPI Query() validation          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Query Builder (tasks.py)                  │
│  1. Base: SELECT * FROM task WHERE user_id = :user_id       │
│  2. + status filter (if provided)                           │
│  3. + search filter (ILIKE on title OR description)         │
│  4. + ORDER BY (sort + order)                               │
│  5. + OFFSET/LIMIT                                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Neon PostgreSQL                           │
│  Indices:                                                   │
│  - ix_task_user_status (user_id, status) [existing]         │
│  - ix_task_user_created (user_id, created_at) [new]         │
└─────────────────────────────────────────────────────────────┘
```

### Frontend Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     /tasks Page URL                         │
│  /tasks?status=pending&search=report&sort=title&order=asc   │
└─────────────────────────────────────────────────────────────┘
                              │
                    useSearchParams()
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    useTaskQuery Hook (new)                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ State: { status, search, sort, order }                 │ │
│  │ URL Sync: Read from URL → state; state → update URL    │ │
│  │ Defaults: status=pending, sort=created_at, order=desc  │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│ TaskFilterTabs   │ │ SearchInput  │ │ SortDropdown     │
│ (existing+)      │ │ (new)        │ │ (new)            │
│ Pending/Done/All │ │ Debounced    │ │ 4 options        │
└──────────────────┘ └──────────────┘ └──────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     useTasks Hook (extended)                │
│  - fetchTasks({ status, search, sort, order, offset })      │
│  - Reset offset to 0 when filters change                    │
│  - loadMore() preserves all current filters                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: Backend Query Contract & Tests

**Scope**: Extend `/api/v1/tasks` with `search`, `sort`, `order` parameters.

**Files to Modify:**
- `phase2/backend/app/api/v1/tasks.py`
- `phase2/backend/app/schemas/task.py`
- `phase2/backend/tests/integration/test_tasks_api.py`

**Completion Criteria:**
- [ ] All existing tests pass (no regression)
- [ ] New test: `TestSearchTasks` - search on title, description, case-insensitive
- [ ] New test: `TestSortTasks` - all 4 sort combinations
- [ ] New test: `TestCombinedFilters` - status + search + sort + pagination
- [ ] 422 returned for invalid sort/order values
- [ ] Queries remain user-scoped

### Phase 2: Frontend Data Layer

**Scope**: Extend API client and hooks for new query params.

**Files to Modify:**
- `phase2/frontend/types/task.ts`
- `phase2/frontend/lib/api/tasks.ts`
- `phase2/frontend/hooks/useTasks.ts`

**Completion Criteria:**
- [ ] `listTasks()` correctly builds query string
- [ ] Default values omitted from query string
- [ ] `useTasks` resets pagination when filters change

### Phase 3: UI Controls & URL State

**Scope**: Add search input, sort dropdown, URL synchronization.

**Files to Create:**
- `phase2/frontend/components/tasks/TaskSearchInput.tsx`
- `phase2/frontend/components/tasks/TaskSortDropdown.tsx`
- `phase2/frontend/hooks/useTaskQuery.ts`

**Files to Modify:**
- `phase2/frontend/app/(authenticated)/tasks/page.tsx`
- `phase2/frontend/components/tasks/TaskFilterTabs.tsx`

**Completion Criteria:**
- [ ] Search input debounces at 300ms
- [ ] Sort dropdown updates both sort and order
- [ ] URL updates without page navigation
- [ ] Invalid URL params fall back to defaults

### Phase 4: Integration & Edge Cases

**Scope**: End-to-end testing, edge cases, performance validation.

**Completion Criteria:**
- [ ] All edge cases from spec covered by tests
- [ ] "Load More" never produces duplicates
- [ ] Performance: <500ms for 100-task queries
- [ ] Manual test: URL copy/paste restores view

---

## Dependencies and Sequencing

```
Phase 1 (Backend) → Phase 2 (Data Layer) → Phase 3 (UI) → Phase 4 (Integration)
```

| Blocked | Blocker | Reason |
|---------|---------|--------|
| Phase 2 | Phase 1 | Need API contract for client types |
| Phase 3 | Phase 2 | Need hooks for component integration |
| Phase 4 | All | Need complete feature to test |

---

## Definition of Done

- [ ] All 24 functional requirements (FR-001 to FR-024) implemented
- [ ] All 6 success criteria (SC-001 to SC-006) validated
- [ ] No regressions in existing Chunk 1-3 functionality
- [ ] Code reviewed and merged to feature branch
