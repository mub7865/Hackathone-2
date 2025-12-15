---
id: "0003"
title: "Task Query Implementation Plan"
stage: plan
date: 2025-12-14
surface: agent
model: claude-sonnet-4-5-20250929
feature: 005-task-query-listing
branch: 005-task-query-listing
user: architect
command: /sp.plan
labels: ["architecture", "search", "sort", "pagination", "url-state"]
links:
  spec: specs/005-task-query-listing/spec.md
  ticket: null
  adr: null
  pr: null
files:
  - specs/005-task-query-listing/plan.md
tests:
  - N/A (plan phase)
---

## Prompt

Generate the Plan phase for **Phase II – Chunk 4: Task Querying & Listing Behavior** using the existing spec at specs/005-task-query-listing/spec.md.

Goals recap:
- Backend: Extend the existing /api/v1/tasks endpoint with search, sorting, and load-more pagination for the authenticated user.
- Frontend: Upgrade the /tasks page so status filter, free-text search, sort options, and "Load More" work together, with full URL state.

Produce a plan.md with:
1) Architecture overview (backend + frontend structure)
2) Implementation phases (3-5 phases with completion criteria)
3) Component breakdown (backend + frontend files to touch)
4) Dependencies and sequencing
5) Testing & validation strategy

## Response snapshot

Created comprehensive implementation plan with:

**Architecture:**
- Backend: Extend `list_tasks` endpoint with `search`, `sort`, `order` Query params; dynamic query building with ILIKE and ORDER BY
- Frontend: New `useTaskQuery` hook for URL sync; `TaskSearchInput` (debounced) and `TaskSortDropdown` components

**4 Implementation Phases:**
1. **Backend Query Contract & Tests** - Add enums, extend endpoint, comprehensive test coverage
2. **Frontend Data Layer** - Types, API client, useTasks extension
3. **UI Controls & URL State** - useTaskQuery, SearchInput, SortDropdown, page integration
4. **Integration & Edge Cases** - E2E testing, performance validation

**Component Breakdown:**
- Backend: 4 files (tasks.py, schemas, models, tests)
- Frontend: 8 files (types, API client, 2 hooks, 3 components, page)

**Testing Strategy:**
- Backend: TestSearchTasks, TestSortTasks, TestCombinedFilters, TestSearchEdgeCases classes
- Frontend: Manual test plan + component tests
- Performance: <500ms assertion for 100-task queries

**Sequencing:**
- Phase 1 → Phase 2 (API contract) → Phase 3 (hooks) → Phase 4 (complete)
- Parallel opportunities: Component development within Phase 3

## Outcome

- ✅ Impact: Detailed implementation roadmap for 4-phase delivery
- 🧪 Tests: Test strategy defined (backend classes + frontend manual tests)
- 📁 Files: 1 file created (plan.md)
- 🔁 Next prompts: `/sp.tasks` to generate task breakdown
- 🧠 Reflection: Plan aligns with existing codebase patterns discovered in exploration

## Evaluation notes (flywheel)

- Failure modes observed: None
- Graders run and results (PASS/FAIL): Architecture review PASS (builds on existing patterns)
- Prompt variant (if applicable): N/A
- Next experiment (smallest change to try): N/A
