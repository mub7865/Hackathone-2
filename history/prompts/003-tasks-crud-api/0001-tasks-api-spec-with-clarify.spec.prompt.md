---
id: 0001
title: Tasks API Specification with Clarify Pass
stage: spec
date: 2025-12-13
surface: agent
model: claude-sonnet-4.5
feature: 003-tasks-crud-api
branch: 003-tasks-crud-api
user: architect
command: interactive
labels: ["api", "rest", "tasks", "crud", "jwt", "pagination", "rfc7807"]
links:
  spec: specs/003-tasks-crud-api/spec.md
  ticket: null
  adr: null
  pr: null
files:
  - specs/003-tasks-crud-api/spec.md
tests:
  - null
---

## Prompt

I'm using Spec-Driven Development for Phase II in @phase2. Start the Specify phase for the "Tasks API & endpoints" feature, and also do a short clarify pass inside the same flow.

First, have a brief pre-spec conversation with me to define:
- Intent: what the Tasks REST API should do for a multi-user Todo app
- Constraints: Phase II stack (Next.js frontend, FastAPI backend, SQLModel + Neon Postgres, Better Auth + JWT), only Phase II scope, code under phase2/backend and phase2/frontend
- SMART Success Evals: what must be true for the Tasks API to be considered "done" (endpoints, behavior, error handling, tests, auth boundaries)
- Non-Goals: what is explicitly out of scope for this API chunk (no advanced filters yet, no reminders, no sharing, no UI details)

Ask me focused questions to fill any gaps, then, based on my answers, write the formal specification in four sections (Intent, Constraints, Success Evals, Non-Goals) for the "Tasks API & endpoints" feature. Keep it WHAT-only (no low-level implementation), and make the success criteria SMART so they can drive planning, tasks, and implementation.

**Clarify Answers Provided:**

1. **Endpoint structure & naming**: Versioned routes `/api/v1/tasks`, raw JSON responses (no envelope)
2. **Authentication boundary**: All endpoints require valid JWT, no guest/anonymous access
3. **Pagination**: Offset/limit with default page size 20
4. **Status filter**: Expose `?status=pending|completed` now; advanced filters deferred
5. **Error response format**: RFC 7807 Problem Details
6. **Test coverage target**: All happy paths + key error cases against real Neon test database

## Response snapshot

Created formal specification at `specs/003-tasks-crud-api/spec.md` with:

**Intent**: REST API layer for task CRUD with strict user isolation, JWT auth, versioned routes, pagination, and RFC 7807 errors.

**Constraints**:
- FastAPI backend, SQLModel ORM, Neon Postgres
- All routes under `/api/v1/tasks`
- JWT required on all endpoints
- Raw JSON responses (no envelope)
- RFC 7807 error format

**User Stories** (5 total):
1. P1: List My Tasks (with pagination + status filter)
2. P1: Create a Task
3. P2: Get Single Task
4. P2: Update a Task
5. P2: Delete a Task

**Success Criteria** (9 measurable):
- SC-001: All 5 endpoints functional with correct status codes
- SC-002: 100% of unauthorized requests return 401 with RFC 7807
- SC-003: User isolation enforced (multi-user test scenarios)
- SC-004: Pagination works correctly
- SC-005: Status filter works
- SC-006: Validation errors return 422 with RFC 7807
- SC-007: Min 10+ integration tests
- SC-008: Tests against real Neon (not SQLite)
- SC-009: Response times under 500ms (sanity check)

**Non-Goals**: Frontend, auth flows, advanced filtering, bulk ops, soft delete, rate limiting, caching, real-time updates, file attachments.

## Outcome

- ✅ Impact: Foundation spec for Tasks API feature created
- 🧪 Tests: N/A (spec phase)
- 📁 Files: 1 file created (spec.md)
- 🔁 Next prompts: `/sp.plan` to create architecture plan, then `/sp.tasks` to generate implementation tasks
- 🧠 Reflection: Pre-spec clarify pass successfully gathered all key decisions upfront, avoiding ambiguity in the spec

## Evaluation notes (flywheel)

- Failure modes observed: None
- Graders run and results (PASS/FAIL): N/A
- Prompt variant (if applicable): Combined specify + clarify flow
- Next experiment: Proceed to planning phase
