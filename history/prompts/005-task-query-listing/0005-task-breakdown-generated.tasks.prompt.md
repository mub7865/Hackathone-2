---
id: "0005"
title: "Task Breakdown Generated"
stage: tasks
date: 2025-12-14
surface: agent
model: claude-sonnet-4-5-20250929
feature: 005-task-query-listing
branch: 005-task-query-listing
user: architect
command: /sp.tasks
labels: ["task-breakdown", "implementation", "backend", "frontend"]
links:
  spec: specs/005-task-query-listing/spec.md
  ticket: null
  adr: null
  pr: null
files:
  - specs/005-task-query-listing/tasks.md
tests:
  - N/A (tasks phase)
---

## Prompt

Using the plan at specs/005-task-query-listing/plan.md for **Phase II – Chunk 4: Task Querying & Listing Behavior**, generate tasks.md.

Break the work into small, 30–90 minute tasks following the plan's phases:
- Backend query contract & tests
- Frontend data layer
- UI controls & URL state
- Edge cases & performance checks

## Response snapshot

Generated tasks.md with **24 tasks** across 4 phases:

**Phase 1: Backend (12 tasks, ~3 hours)**
- T001-T002: Add SortField, SortOrder enums
- T003-T007: Extend list_tasks endpoint with search, sort, order params
- T008-T012: Integration tests (TestSearchTasks, TestSortTasks, TestSearchEdgeCases, TestCombinedFilters)

**Phase 2: Frontend Data Layer (6 tasks, ~1.5 hours)**
- T013-T015: Add frontend types (SortField, SortOrder, TaskQueryParams)
- T016-T017: Update listTasks() API client
- T018: Update useTasks hook

**Phase 3: UI Controls (6 tasks, ~3 hours)**
- T019: Install use-debounce
- T020: Create useTaskQuery hook
- T021-T022: Create TaskSearchInput, TaskSortDropdown components
- T023-T024: Integrate in page, update TaskFilterTabs

**Phase 4: Verification**
- Manual testing checklist (5 categories, 16 items)

**Additional Sections:**
- Dependencies & sequencing diagram
- Parallel execution opportunities (T008-T010, T021-T022)
- User story mapping to tasks
- MVP scope definition
- Success criteria validation table
- FR coverage matrix (all 24 FRs mapped)

## Outcome

- ✅ Impact: Complete task breakdown ready for implementation
- 🧪 Tests: Test tasks defined (T008-T012 backend integration tests)
- 📁 Files: 1 file created (tasks.md)
- 🔁 Next prompts: `/sp.implement` to begin execution
- 🧠 Reflection: Tasks organized by phase with clear dependencies; parallel opportunities identified

## Evaluation notes (flywheel)

- Failure modes observed: None
- Graders run and results (PASS/FAIL): Task format validation PASS (all use checkbox + ID format)
- Prompt variant (if applicable): N/A
- Next experiment (smallest change to try): N/A
