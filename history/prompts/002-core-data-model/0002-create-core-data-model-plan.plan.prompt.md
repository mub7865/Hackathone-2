---
id: "0002"
title: "Create Core Data Model Plan"
stage: plan
date: 2025-12-12
surface: agent
model: claude-sonnet-4-5-20250929
feature: 002-core-data-model
branch: 002-core-data-model
user: local
command: /sp.plan
labels: ["planning", "data-model", "sqlmodel", "alembic", "neon"]
links:
  spec: specs/002-core-data-model/spec.md
  ticket: null
  adr: null
  pr: null
files:
  - specs/002-core-data-model/plan.md
  - specs/002-core-data-model/research.md
  - specs/002-core-data-model/data-model.md
  - specs/002-core-data-model/quickstart.md
tests:
  - null
---

## Prompt

Based on the clarified specification for the "Core data & domain model" (including the /spec2 location), generate an implementation plan. Focus only on HOW to realize this domain model: entities, fields, relationships, invariants, migrations, and where these live in the Next.js + FastAPI + SQLModel + Neon + Better Auth stack. The plan should be structured, ordered, and detailed enough that we can later turn it into small tasks, but do not write any code yet.

## Response snapshot

Generated complete implementation plan with 4 Phase 1 artifacts:

**plan.md**: Main implementation plan with:
- Technical Context: Python 3.13+, FastAPI, SQLModel, asyncpg, Alembic
- Constitution Check: All 7 principles PASS
- Project Structure: Web app layout with backend/app/models/, backend/alembic/
- Implementation Sequence: 7 ordered steps from setup to integration tests
- Complexity Tracking: No violations; minimal abstractions

**research.md**: 6 research questions resolved:
- RQ-1: asyncpg driver for Neon (SSL required)
- RQ-2: Python uuid4() for ID generation
- RQ-3: str Enum + CHECK constraint for status
- RQ-4: Soft reference to Better Auth (no FK coupling)
- RQ-5: Alembic async configuration pattern
- RQ-6: Database-managed timestamps with func.now()

**data-model.md**: Complete entity definition:
- Task table with 7 columns (id, user_id, title, description, status, created_at, updated_at)
- 2 indexes (user_id, composite user_id+status)
- 3 constraints (status CHECK, title not empty CHECK, NOT NULL)
- SQLModel class definition with Pydantic validators
- State transition diagram and query patterns

**quickstart.md**: Step-by-step setup guide:
- Project structure and pyproject.toml
- Database configuration with Neon
- Task model implementation
- Alembic migration setup
- Test fixtures and verification checklist

## Outcome

- ✅ Impact: Complete implementation blueprint ready for task generation
- 🧪 Tests: Testing checklist with 15 verification items in data-model.md
- 📁 Files: 4 artifacts created (plan.md, research.md, data-model.md, quickstart.md)
- 🔁 Next prompts: `/sp.tasks` to generate actionable task list
- 🧠 Reflection: Constitution gates passed; no architectural decisions requiring ADR

## Evaluation notes (flywheel)

- Failure modes observed: setup-plan.sh picked wrong spec directory (001-todo-operations); manually corrected
- Graders run and results (PASS/FAIL): Constitution Check PASS (7/7 principles)
- Prompt variant (if applicable): Standard /sp.plan with explicit focus on data model only
- Next experiment (smallest change to try): N/A - proceed to task generation
