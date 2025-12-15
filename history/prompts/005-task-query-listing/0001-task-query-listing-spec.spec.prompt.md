---
id: "0001"
title: "Task Query Listing Spec"
stage: spec
date: 2025-12-14
surface: agent
model: claude-sonnet-4-5-20250929
feature: 005-task-query-listing
branch: 005-task-query-listing
user: architect
command: /sp.specify
labels: ["querying", "search", "sort", "pagination", "url-state"]
links:
  spec: specs/005-task-query-listing/spec.md
  ticket: null
  adr: null
  pr: null
files:
  - specs/005-task-query-listing/spec.md
  - specs/005-task-query-listing/checklists/requirements.md
tests:
  - N/A (spec phase)
---

## Prompt

I'm using Spec-Driven Development in @phase2. Help me start the Specify phase for **Phase II – Chunk 4: Task querying & listing behavior**.

This chunk comes after:
- Chunk 1: Core data & domain model (Task entity, Neon schema, basic CRUD).
- Chunk 2: Auth + per-user isolation (JWT, register/login, user-scoped tasks).
- Chunk 3: Tasks CRUD UX (web app) (Tasks page with basic Pending/Completed/All tabs, create/edit/delete UI).

Now Chunk 4 should focus ONLY on **how tasks are queried and presented**, not on auth or basic CRUD.

User answered pre-spec questions:
- 1-B: Search title + description, case-insensitive contains
- 2-B: Sort by created_at (newest/oldest) + title (A-Z/Z-A)
- 3-A: "Load More" pagination (offset-based)
- 4-A: Full URL state for sharing/bookmarking
- 5-B: Medium scale (~1000 tasks/user, <500ms queries)

Clarifications provided:
- Search combines with filters using AND logic
- Default sort is created_at DESC
- Title sort is case-insensitive
- Load More appends results without duplicates
- URL includes status, search, sort, order params
- Pagination offset is ephemeral (resets on reload)

## Response snapshot

Created formal specification for Phase II – Chunk 4: Task Querying & Listing Behavior with:

**Intent**: Make /tasks page "query-smart" with search, sort, combined filters, and URL state

**Constraints**:
- Extend existing /api/v1/tasks endpoint
- User isolation via JWT auth
- No new domain concepts
- <500ms for 1000 tasks

**User Stories** (5 stories, 16 acceptance scenarios):
- P1: Search tasks by text (title + description)
- P2: Sort tasks (created_at, title)
- P2: Combine filters with search and sort
- P3: Load More pagination
- P3: Shareable/bookmarkable URLs

**Requirements**: 22 functional requirements covering search, sorting, pagination, URL state, and API contract

**Success Criteria**: 6 measurable outcomes

**Non-Goals**: 10 explicit exclusions (no new fields, no full-text search engine, no saved filters, etc.)

## Outcome

- ✅ Impact: Specification complete and validated
- 🧪 Tests: N/A (spec phase - no code yet)
- 📁 Files: 2 files created (spec.md, requirements.md checklist)
- 🔁 Next prompts: `/sp.clarify` or `/sp.plan`
- 🧠 Reflection: Pre-spec questions yielded clear requirements; no clarification markers needed

## Evaluation notes (flywheel)

- Failure modes observed: None
- Graders run and results (PASS/FAIL): Checklist validation PASS (all items checked)
- Prompt variant (if applicable): N/A
- Next experiment (smallest change to try): N/A
