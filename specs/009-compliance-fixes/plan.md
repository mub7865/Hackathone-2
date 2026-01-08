# Implementation Plan: Hackathon Compliance Fixes

**Branch**: `009-compliance-fixes` | **Date**: 2026-01-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/009-compliance-fixes/spec.md`

**Note**: This template is filled in by the `/sp.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Replace custom JWT authentication with Better Auth and custom React chat components with OpenAI ChatKit to meet hackathon Phase II and Phase III technology requirements. Implementation preserves all existing user data, maintains API compatibility, supports gradual migration via dual token validation (7-day transition), and includes Phase IV Kubernetes deployment updates with Docker image rebuilds and Helm chart updates. Autonomous testing via Claude Code CLI validates full compliance across backend API, chatbot interface, and frontend UI.

## Technical Context

**Language/Version**:
- Frontend: TypeScript 5.x, Next.js 16 (App Router), React 19
- Backend: Python 3.13+, FastAPI 0.115+

**Primary Dependencies**:
- Frontend: better-auth (authentication), @openai/chatkit-react (chat UI), TanStack Query (data fetching)
- Backend: SQLModel 0.0.22+ (ORM), python-jose (JWT), bcrypt (password hashing), OpenAI Agents SDK (AI), MCP Python SDK (tools)

**Storage**: Neon PostgreSQL (cloud-hosted, existing schema: users, tasks, conversations, messages tables)

**Testing**:
- Backend: pytest (existing integration tests)
- Frontend: Manual validation + autonomous testing via Claude Code CLI
- E2E: Autonomous validation across backend API, chatbot, and frontend UI

**Target Platform**:
- Development: Local (Next.js dev server, FastAPI uvicorn)
- Deployment: Kubernetes (Minikube local, DigitalOcean K8s production)
- Containerization: Docker (frontend: Node.js + nginx, backend: Python + uvicorn)

**Project Type**: Web application (fullstack monorepo)

**Performance Goals**:
- Authentication: <500ms login/register response time
- Chat interface: <2s initial load, <1s message send/receive
- API endpoints: Maintain existing performance (<200ms p95)

**Constraints**:
- Zero data loss: All existing users, tasks, conversations must remain accessible
- API compatibility: No breaking changes to existing endpoints
- Time constraint: 4-5 hours total implementation (Better Auth: 3h, ChatKit: 1-2h)
- Gradual migration: Dual token support for 7-day transition period
- Rollback capability: Feature flags for instant rollback to custom auth/chat

**Scale/Scope**:
- User base: Existing users + new registrations (small scale, hackathon project)
- Code changes: ~10-15 files modified (frontend auth client, chat components, backend JWT validation)
- Docker images: 2 rebuilds (frontend, backend)
- Kubernetes: 1 Helm chart update with new image tags

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Strict Spec-Driven Development (SDD)
✅ **PASS**: Comprehensive specification created in `specs/009-compliance-fixes/spec.md` with 6 user stories, 40 functional requirements, and 13 success criteria before any implementation.

### AI-Native Architecture
✅ **PASS**: Preserves existing OpenAI Agents SDK and MCP Server backend. ChatKit integration maintains AI-first approach for chat interface. No changes to AI agent logic.

### Progressive Evolution
✅ **PASS**: Implements gradual migration strategy with dual token support (7-day transition) and feature flags for rollback. No breaking changes to existing APIs or database schema. Builds on Phase II/III without rewrites.

### Documentation First
✅ **PASS**: All changes documented in specification before implementation. Includes data model preservation, API contracts, and deployment procedures.

### Tech Stack Adherence
✅ **PASS**: This feature specifically addresses tech stack non-compliance by replacing custom JWT with Better Auth (Phase II requirement) and custom React chat with ChatKit (Phase III requirement) as mandated by hackathon specifications.

### No "Vibe Coding"
✅ **PASS**: All changes follow spec-driven approach. Feature flags and dual token support are explicitly defined in requirements (FR-021 to FR-024).

### Phase Logic
✅ **PASS**: Fixes Phase II and Phase III implementations to match hackathon requirements. Updates Phase IV (Kubernetes) to deploy compliant versions. Does not skip or mix phase boundaries.

### Code Quality & Testing
✅ **PASS**: Existing integration tests must pass without modification (SC-007). Autonomous testing via Claude Code CLI validates all changes (FR-032 to FR-040).

### Security
✅ **PASS**: Maintains JWT security with Better Auth. Preserves bcrypt password hashing. Dual token validation ensures secure transition period.

**GATE STATUS**: ✅ ALL CHECKS PASSED - Proceed to Phase 0 Research

## Project Structure

### Documentation (this feature)

```text
specs/009-compliance-fixes/
├── plan.md              # This file (/sp.plan command output)
├── research.md          # Phase 0 output (/sp.plan command)
├── data-model.md        # Phase 1 output (/sp.plan command)
├── quickstart.md        # Phase 1 output (/sp.plan command)
├── contracts/           # Phase 1 output (/sp.plan command)
│   ├── better-auth-config.md
│   ├── chatkit-integration.md
│   └── dual-token-validation.md
└── tasks.md             # Phase 2 output (/sp.tasks command - NOT created by /sp.plan)
```

### Source Code (repository root)

```text
# Web application structure (existing monorepo)
calm-orbit-todo/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   ├── deps.py              # [MODIFY] Add dual token validation
│   │   │   └── v1/
│   │   │       ├── auth.py          # [MODIFY] Add feature flag support
│   │   │       ├── tasks.py         # [NO CHANGE] Existing endpoints
│   │   │       ├── chat.py          # [NO CHANGE] Existing endpoints
│   │   │       └── conversations.py # [NO CHANGE] Existing endpoints
│   │   ├── core/
│   │   │   ├── auth.py              # [MODIFY] Add dual token validation logic
│   │   │   └── config.py            # [MODIFY] Add feature flags
│   │   ├── models/
│   │   │   └── user.py              # [NO CHANGE] Existing schema
│   │   └── main.py                  # [NO CHANGE] Existing app setup
│   ├── Dockerfile                   # [REBUILD] New image with dual token support
│   └── requirements.txt             # [NO CHANGE] No new backend dependencies
│
├── frontend/
│   ├── app/
│   │   ├── login/
│   │   │   └── page.tsx             # [MODIFY] Use Better Auth
│   │   ├── register/
│   │   │   └── page.tsx             # [MODIFY] Use Better Auth
│   │   └── (authenticated)/
│   │       ├── layout.tsx           # [MODIFY] Better Auth session check
│   │       └── chatbot/
│   │           └── page.tsx         # [MODIFY] Replace with ChatKit
│   ├── lib/
│   │   └── auth/
│   │       ├── client.ts            # [REPLACE] Better Auth client
│   │       └── config.ts            # [NEW] Better Auth configuration
│   ├── components/
│   │   └── chat/
│   │       ├── ChatArea.tsx         # [REMOVE] Replace with ChatKit
│   │       ├── ChatInput.tsx        # [REMOVE] Replace with ChatKit
│   │       ├── ChatSidebar.tsx      # [REMOVE] Replace with ChatKit
│   │       └── ChatKitPage.tsx      # [NEW] ChatKit integration
│   ├── Dockerfile                   # [REBUILD] New image with Better Auth + ChatKit
│   ├── package.json                 # [MODIFY] Add better-auth, @openai/chatkit-react
│   └── middleware.ts                # [MODIFY] Better Auth session middleware
│
└── charts/
    └── todo-chatbot/
        ├── values.yaml              # [MODIFY] Update image tags, feature flags
        └── templates/
            ├── backend-deployment.yaml   # [NO CHANGE] Uses values.yaml
            └── frontend-deployment.yaml  # [NO CHANGE] Uses values.yaml
```

**Structure Decision**: Web application monorepo with existing backend (FastAPI) and frontend (Next.js 16) directories. Changes are surgical: authentication layer (frontend lib/auth/, backend core/auth.py), chat UI (frontend components/chat/), and deployment configuration (Dockerfiles, Helm values). No database schema changes. No new services or microservices.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations detected. All constitution checks passed. This feature maintains existing architecture and implements surgical changes to authentication and chat UI layers only.
