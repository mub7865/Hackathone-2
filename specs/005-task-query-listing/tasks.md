# Tasks: Task Querying & Listing Behavior

**Feature Branch**: `005-task-query-listing`
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)
**Created**: 2025-12-14
**Total Tasks**: 24

---

## Overview

This task breakdown implements **Phase II – Chunk 4: Task Querying & Listing Behavior** with:
- 5 User Stories (P1: Search, P2: Sort, P2: Combined Filters, P3: Load More, P3: URL State)
- 4 Implementation Phases (Backend → Data Layer → UI → Integration)
- 24 tasks organized for incremental, testable delivery

---

## Phase 1: Setup & Backend Foundation

**Goal**: Extend backend API with search, sort, order parameters.
**Duration**: ~3 hours
**Blocks**: All frontend work

### Backend Enums & Schema

- [ ] T001 Add SortField enum (created_at, title) in `phase2/backend/app/schemas/task.py`
- [ ] T002 Add SortOrder enum (asc, desc) in `phase2/backend/app/schemas/task.py`

### Backend Endpoint Extension

- [ ] T003 Add `search` query parameter (str, max 100 chars) to list_tasks in `phase2/backend/app/api/v1/tasks.py`
- [ ] T004 Add `sort` query parameter (SortField enum, default created_at) to list_tasks in `phase2/backend/app/api/v1/tasks.py`
- [ ] T005 Add `order` query parameter (SortOrder enum, default desc) to list_tasks in `phase2/backend/app/api/v1/tasks.py`
- [ ] T006 Implement search filter with ILIKE on title OR description in `phase2/backend/app/api/v1/tasks.py`
- [ ] T007 Implement dynamic ORDER BY with case-insensitive title sort using func.lower() in `phase2/backend/app/api/v1/tasks.py`

### Backend Integration Tests

- [ ] T008 [P] Add TestSearchTasks class with tests for title search, description search, case-insensitive in `phase2/backend/tests/integration/test_tasks_api.py`
- [ ] T009 [P] Add TestSortTasks class with tests for all 4 sort combinations in `phase2/backend/tests/integration/test_tasks_api.py`
- [ ] T010 [P] Add TestSearchEdgeCases class for empty search, whitespace, special chars, >100 chars in `phase2/backend/tests/integration/test_tasks_api.py`
- [ ] T011 Add TestCombinedFilters class for status+search+sort+pagination combinations in `phase2/backend/tests/integration/test_tasks_api.py`
- [ ] T012 Run all backend tests and verify no regressions in `phase2/backend/`

**Phase 1 Completion Criteria**:
- All existing tests pass
- Search, sort, order parameters working via curl/API client
- 422 returned for invalid sort/order values

---

## Phase 2: Frontend Data Layer

**Goal**: Extend API client and types for new query parameters.
**Duration**: ~1.5 hours
**Depends on**: Phase 1 complete
**Blocks**: UI components

### Frontend Types

- [ ] T013 Add SortField type ('created_at' | 'title') in `phase2/frontend/types/task.ts`
- [ ] T014 Add SortOrder type ('asc' | 'desc') in `phase2/frontend/types/task.ts`
- [ ] T015 Add TaskQueryParams interface with all query fields in `phase2/frontend/types/task.ts`

### Frontend API Client

- [ ] T016 Update listTasks() to accept TaskQueryParams in `phase2/frontend/lib/api/tasks.ts`
- [ ] T017 Implement query string builder that omits default values in `phase2/frontend/lib/api/tasks.ts`

### Frontend Hooks

- [ ] T018 Update useTasks hook to accept TaskQueryParams and reset pagination on filter change in `phase2/frontend/hooks/useTasks.ts`

**Phase 2 Completion Criteria**:
- listTasks() correctly builds query string with all params
- Default values omitted from query string
- useTasks resets offset to 0 when filters change

---

## Phase 3: UI Controls & URL State

**Goal**: Add search input, sort dropdown, URL synchronization.
**Duration**: ~3 hours
**Depends on**: Phase 2 complete

### Install Dependencies

- [ ] T019 Install use-debounce package in `phase2/frontend/`

### URL State Hook

- [ ] T020 Create useTaskQuery hook with URL read/write and validation in `phase2/frontend/hooks/useTaskQuery.ts`

### UI Components

- [ ] T021 [P] Create TaskSearchInput component with debounce (300ms) and max 100 chars in `phase2/frontend/components/tasks/TaskSearchInput.tsx`
- [ ] T022 [P] Create TaskSortDropdown component with 4 sort options in `phase2/frontend/components/tasks/TaskSortDropdown.tsx`

### Page Integration

- [ ] T023 Integrate useTaskQuery, TaskSearchInput, TaskSortDropdown in tasks page at `phase2/frontend/app/(authenticated)/tasks/page.tsx`
- [ ] T024 Update TaskFilterTabs to use setQuery from useTaskQuery in `phase2/frontend/components/tasks/TaskFilterTabs.tsx`

**Phase 3 Completion Criteria**:
- Search input debounces at 300ms
- Sort dropdown updates both sort and order
- URL updates without page navigation
- Invalid URL params fall back to defaults

---

## Phase 4: Integration & Verification

**Goal**: End-to-end testing and manual verification.
**Duration**: ~1 hour
**Depends on**: Phases 1-3 complete

### Manual Testing Checklist

After completing all tasks, verify:

1. **Search (US1)**:
   - [ ] Type "report" → only matching tasks shown
   - [ ] Search matches description field
   - [ ] "REPORT" and "report" return same results (case-insensitive)
   - [ ] Clear search → all tasks for current status shown

2. **Sort (US2)**:
   - [ ] Default sort is "Newest first"
   - [ ] "Oldest first" works correctly
   - [ ] "Title A-Z" sorts case-insensitively
   - [ ] "Title Z-A" works correctly

3. **Combined Filters (US3)**:
   - [ ] Pending + "report" → only pending tasks with "report"
   - [ ] Empty results show empty state (not error)

4. **Load More (US4)**:
   - [ ] With >20 tasks, "Load More" button appears
   - [ ] Clicking loads 20 more, no duplicates
   - [ ] Button disappears when all loaded
   - [ ] Filters preserved across Load More

5. **URL State (US5)**:
   - [ ] Filters reflected in URL
   - [ ] Copy URL, paste in new tab → same view
   - [ ] Reload resets offset to 0
   - [ ] Default params omitted from URL

---

## Dependencies & Sequencing

```
┌─────────────────────────────────────┐
│  Phase 1: Backend (T001-T012)       │
│  ~3 hours                           │
└─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────┐
│  Phase 2: Data Layer (T013-T018)    │
│  ~1.5 hours                         │
└─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────┐
│  Phase 3: UI Controls (T019-T024)   │
│  ~3 hours                           │
└─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────┐
│  Phase 4: Verification              │
│  ~1 hour                            │
└─────────────────────────────────────┘
```

### Parallel Execution Opportunities

| Phase | Parallelizable Tasks | Reason |
|-------|---------------------|--------|
| 1 | T008, T009, T010 | Independent test classes |
| 3 | T021, T022 | Independent components |

### Task Dependencies

| Task | Depends On | Reason |
|------|------------|--------|
| T003-T007 | T001-T002 | Need enums before endpoint |
| T008-T011 | T003-T007 | Need endpoint before tests |
| T013-T018 | T012 | Need API contract complete |
| T019-T024 | T018 | Need hooks before UI |

---

## User Story Mapping

| User Story | Priority | Tasks | Independent Test |
|------------|----------|-------|------------------|
| US1: Search | P1 | T003, T006, T008, T010, T016, T021 | Type search term, verify results |
| US2: Sort | P2 | T004-T005, T007, T009, T022 | Select sort option, verify order |
| US3: Combined | P2 | T011, T018 | Apply multiple filters, verify intersection |
| US4: Load More | P3 | T018 (pagination reset) | Create >20 tasks, click Load More |
| US5: URL State | P3 | T017, T020, T023-T024 | Apply filters, copy URL, paste in new tab |

---

## MVP Scope

**Minimum Viable Delivery**: Complete Phase 1 + Phase 2 + T021 (Search Input)

This delivers:
- Backend search/sort/order fully working
- Frontend can query with new params
- Search UI component functional

Users can search tasks via input field even without sort dropdown or full URL state.

---

## Success Criteria Validation

| Criterion | How to Verify | Task |
|-----------|---------------|------|
| SC-001: Find task in <5s | Manual test with search | T021 |
| SC-002: <500ms queries | Backend test timing | T011 |
| SC-003: URL state 100% | Manual URL copy/paste | T020, T023 |
| SC-004: No duplicates | Manual Load More test | T018 |
| SC-005: All filter combos | Backend integration tests | T011 |
| SC-006: Title + description search | Backend test | T008 |

---

## Functional Requirements Coverage

| FR | Description | Task |
|----|-------------|------|
| FR-001 | Search on title | T006, T008 |
| FR-002 | Search on description | T006, T008 |
| FR-003 | Case-insensitive | T006, T008 |
| FR-004 | Search + status AND | T006, T011 |
| FR-005 | Empty search = no filter | T006, T010 |
| FR-006 | 100 char max | T003, T010 |
| FR-007 | Debounce 300ms | T021 |
| FR-008 | Sort by created_at | T007, T009 |
| FR-009 | Sort by title (case-insensitive) | T007, T009 |
| FR-010 | Default sort = created_at DESC | T007 |
| FR-011 | Sort after filters | T007, T011 |
| FR-012 | Offset-based pagination | Existing |
| FR-013 | Default limit 20, max 100 | Existing |
| FR-014 | Load More when length=limit | T018 |
| FR-015 | Append without duplicates | T018 |
| FR-016 | URL reflects filters | T020, T023 |
| FR-017 | Restore from URL | T020 |
| FR-018 | Omit defaults from URL | T017, T020 |
| FR-019 | Invalid URL → defaults | T020 |
| FR-020 | API accepts search | T003 |
| FR-021 | API accepts sort enum | T004 |
| FR-022 | API accepts order enum | T005 |
| FR-023 | Invalid sort/order → 422 | T004, T005, T009 |
| FR-024 | User-scoped queries | Existing (T011 verifies) |
