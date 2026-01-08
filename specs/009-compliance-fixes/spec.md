# Feature Specification: Hackathon Compliance Fixes

**Feature Branch**: `009-compliance-fixes`
**Created**: 2026-01-07
**Status**: Draft
**Input**: User description: "Fix hackathon compliance issues: Add Better Auth for Phase II authentication and OpenAI ChatKit for Phase III chat interface to meet specification requirements"

## Clarifications

### Session 2026-01-07

This specification addresses two critical deviations from hackathon requirements:

1. **Phase II Authentication**: Hackathon requires Better Auth, but custom JWT authentication was implemented
2. **Phase III Chat Interface**: Hackathon requires OpenAI ChatKit, but custom React components were implemented

Both implementations are functionally correct but do not meet the explicit technology requirements stated in the hackathon specification document.

**Key Constraints:**
- Must preserve all existing user accounts and data (zero data loss)
- Must maintain existing API endpoints and contracts
- Must keep existing backend logic (OpenAI Agents SDK, MCP Server)
- Must complete within 4-5 hours to allow time for Phase V

**Clarification Questions:**

- Q: How should we handle the transition from custom JWT to Better Auth JWT tokens during deployment? → A: Backend accepts both custom JWT and Better Auth JWT for 7 days, then deprecate custom (gradual, safe migration)
- Q: How should ChatKit authenticate API requests and manage conversation context with the existing backend? → A: ChatKit passes Better Auth JWT token in Authorization header (consistent with existing API pattern)
- Q: What is the rollback strategy if Better Auth or ChatKit integration causes critical issues after deployment? → A: Feature flag to toggle between old/new auth and chat systems (instant rollback, zero downtime)
- Q: How should we verify that Better Auth can authenticate users with existing bcrypt-hashed passwords before deploying to production? → A: Create test migration script with sample accounts, verify logins work before production (safe, thorough)
- Q: If time runs short, which integration should be prioritized to ensure hackathon compliance? → A: Prioritize Better Auth (3 hours), then ChatKit (1-2 hours) - ensures auth works first
- Q: Does Phase 4 (Kubernetes/Minikube deployment) need to be updated when Phase 2/3 are fixed? → A: Yes, Phase 4 must be updated with new Docker images and Helm charts to use Better Auth and ChatKit
- Q: How should the updated system be validated after implementation? → A: Claude Code CLI should autonomously test backend (login/register/CRUD), chatbot (natural language CRUD), and frontend (UI CRUD) to ensure full compliance

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Existing Users Can Login with Better Auth (Priority: P1)

Users who have already created accounts with the custom authentication system can continue to log in seamlessly after Better Auth is integrated. Their credentials, tasks, conversations, and all associated data remain intact.

**Why this priority**: Data preservation is critical. If existing users lose access to their accounts or data, the application becomes unusable for current users. This is the highest risk area of the migration.

**Independent Test**: Can be fully tested by creating a user account before the migration, then attempting to log in with the same credentials after Better Auth integration. Verify all user data (tasks, conversations) is accessible.

**Acceptance Scenarios**:

1. **Given** a user account exists in the database with email "user@example.com" and password "password123", **When** Better Auth is integrated and user attempts to login with same credentials, **Then** login succeeds and user accesses their existing tasks and conversations.

2. **Given** 10 existing user accounts in the database, **When** Better Auth integration is complete, **Then** all 10 users can log in successfully with their original credentials.

3. **Given** a user is currently logged in with a JWT token from the old system, **When** Better Auth is deployed, **Then** the user's session remains valid until token expiration, then they can re-login with Better Auth.

---

### User Story 2 - New Users Register via Better Auth (Priority: P1)

New users can create accounts using Better Auth's registration flow. The registration process follows Better Auth's standard patterns while maintaining compatibility with the existing database schema.

**Why this priority**: Registration is essential for user acquisition. Without working registration, no new users can join the application. This is equally critical as login functionality.

**Independent Test**: Can be fully tested by attempting to register a new account after Better Auth integration, then verifying the account is created in the database and the user can immediately log in and use all features.

**Acceptance Scenarios**:

1. **Given** Better Auth is integrated, **When** a new user registers with email "newuser@example.com" and password "securepass456", **Then** account is created in the existing users table and user can immediately log in.

2. **Given** a new user completes registration, **When** they create tasks and start conversations, **Then** all data is properly associated with their user_id.

3. **Given** a user attempts to register with an email that already exists, **When** registration is submitted, **Then** Better Auth returns appropriate error message without exposing security information.

---

### User Story 3 - Chat Interface Uses ChatKit Components (Priority: P2)

Users interact with the AI chatbot through OpenAI's official ChatKit interface components. The chat experience includes professional UI patterns, proper loading states, error handling, and message formatting provided by ChatKit.

**Why this priority**: While the custom chat UI works, ChatKit compliance is required by hackathon specifications. This is lower priority than authentication because it doesn't affect data integrity, but it's essential for full compliance.

**Independent Test**: Can be fully tested by opening the /chatbot page after ChatKit integration and verifying that messages send/receive correctly, conversations load properly, and all existing chat functionality works with the new UI components.

**Acceptance Scenarios**:

1. **Given** ChatKit is integrated, **When** user opens /chatbot page, **Then** chat interface renders using ChatKit components with proper styling and layout.

2. **Given** user is on the chatbot page, **When** user sends a message "Add task to buy groceries", **Then** message is sent to existing backend endpoint, AI agent processes it via MCP tools, and response appears in ChatKit interface.

3. **Given** user has existing conversation history, **When** user opens /chatbot page, **Then** ChatKit loads and displays all previous conversations in the sidebar.

4. **Given** user clicks "New Chat" button, **When** ChatKit creates new conversation, **Then** new conversation is saved to existing database schema (conversations table).

---

### User Story 4 - Backend Endpoints Remain Unchanged (Priority: P1)

All existing backend API endpoints continue to function exactly as before. Better Auth integration only changes the authentication mechanism, not the API contracts. ChatKit integration only changes the frontend UI, not the backend chat logic.

**Why this priority**: API stability is critical. If backend contracts change, it creates cascading failures across the application. This ensures the migration is purely a frontend/auth layer change.

**Independent Test**: Can be fully tested by running existing integration tests against the updated system. All tests should pass without modification, proving API contracts are preserved.

**Acceptance Scenarios**:

1. **Given** Better Auth is integrated, **When** frontend makes request to `POST /api/v1/tasks`, **Then** endpoint accepts JWT token from Better Auth and returns tasks for authenticated user.

2. **Given** ChatKit is integrated, **When** user sends chat message, **Then** frontend calls existing `POST /api/v1/chat` endpoint with same request format.

3. **Given** existing integration tests for auth and chat endpoints, **When** tests run after migration, **Then** all tests pass without modification.

---

### User Story 5 - Phase 4 Kubernetes Deployment Updated (Priority: P1)

Phase 4 (Kubernetes/Minikube deployment) is updated to use the new Better Auth and ChatKit implementations. Docker images are rebuilt with updated frontend and backend code, and Helm charts are updated to deploy the compliant versions.

**Why this priority**: Phase 4 currently uses the old custom auth and chat implementations. For full hackathon compliance, the deployed version must also use Better Auth and ChatKit. This ensures the entire stack is compliant.

**Independent Test**: Can be fully tested by rebuilding Docker images, deploying to Minikube via Helm, and verifying that the deployed application uses Better Auth for login and ChatKit for chat interface.

**Acceptance Scenarios**:

1. **Given** Better Auth and ChatKit are integrated in Phase 2/3 code, **When** Docker images are rebuilt, **Then** new images contain updated authentication and chat code.

2. **Given** updated Docker images exist, **When** Helm chart is deployed to Minikube, **Then** deployed application uses Better Auth for authentication.

3. **Given** application is deployed on Minikube, **When** user accesses chatbot page, **Then** ChatKit components render and function correctly in Kubernetes environment.

---

### User Story 6 - Autonomous System Validation via Claude Code CLI (Priority: P2)

After implementation is complete, Claude Code CLI autonomously validates the entire system by performing end-to-end tests across backend API, chatbot interface, and frontend UI without human intervention.

**Why this priority**: Manual testing is time-consuming and error-prone. Autonomous validation ensures comprehensive testing coverage within the 4-5 hour time constraint and provides confidence that all compliance requirements are met.

**Independent Test**: Can be fully tested by running Claude Code CLI with test prompts and verifying it successfully completes all validation scenarios (backend CRUD, chatbot natural language CRUD, frontend UI CRUD).

**Acceptance Scenarios**:

1. **Given** Better Auth is integrated, **When** Claude Code CLI attempts to register and login via backend API, **Then** CLI successfully creates account and authenticates.

2. **Given** backend is running, **When** Claude Code CLI performs CRUD operations via API endpoints, **Then** all operations (create task, list tasks, update task, delete task, mark complete) succeed.

3. **Given** chatbot is integrated with ChatKit, **When** Claude Code CLI sends natural language prompts ("Add task to buy milk", "Show my tasks", "Mark task 1 complete"), **Then** chatbot correctly interprets commands and performs operations.

4. **Given** frontend is running, **When** Claude Code CLI interacts with UI elements (login form, task list, chatbot interface), **Then** all UI interactions work correctly with Better Auth and ChatKit.

5. **Given** all validation scenarios complete, **When** Claude Code CLI generates test report, **Then** report confirms 100% compliance with hackathon Phase II and Phase III requirements.

---

### Edge Cases

- What happens when Better Auth JWT token format differs from custom JWT format? → Backend accepts both custom JWT and Better Auth JWT tokens for 7-day transition period, then deprecates custom tokens
- How does system handle users with active sessions during deployment? → Dual token support: existing custom JWT tokens remain valid, new logins issue Better Auth tokens; after 7 days, only Better Auth tokens accepted
- What happens if ChatKit fails to load (CDN issue, network error)? → Fallback to error message with retry option; backend functionality unaffected
- How does system handle existing localStorage/cookie data from custom auth? → Better Auth initialization preserves valid tokens during transition period, clears only after expiration
- What happens to conversation history if ChatKit uses different data format? → ChatKit adapts to existing API response format; no database schema changes required

---

## Requirements *(mandatory)*

### Functional Requirements - Better Auth Integration

**FR-001**: System MUST integrate Better Auth library for authentication while preserving all existing user accounts in the database

**FR-002**: System MUST configure Better Auth to use the existing "users" table with column mapping (email → email, name → name, hashed_password → password)

**FR-003**: System MUST enable Better Auth JWT plugin to generate tokens compatible with existing backend verification logic

**FR-004**: System MUST allow existing users to log in with their current credentials after Better Auth integration (zero credential migration required)

**FR-005**: System MUST allow new users to register via Better Auth and have accounts created in the existing users table

**FR-006**: System MUST maintain existing JWT token structure (user_id in "sub" claim) for backend compatibility

**FR-007**: System MUST preserve existing password hashing mechanism (bcrypt) to maintain credential compatibility

**FR-008**: Frontend MUST replace custom auth client (`lib/auth/client.ts`) with Better Auth hooks and utilities

**FR-009**: Frontend MUST update login and registration pages to use Better Auth components while maintaining existing UI design

**FR-010**: System MUST handle authentication errors with user-friendly messages following existing error handling patterns

**FR-021**: Backend MUST support dual token validation: accept both custom JWT and Better Auth JWT tokens for 7-day transition period, then deprecate custom tokens

**FR-022**: System MUST implement feature flag to toggle between custom auth and Better Auth for instant rollback capability (zero downtime)

**FR-023**: System MUST create test migration script with sample accounts to verify Better Auth can authenticate users with existing bcrypt-hashed passwords before production deployment

### Functional Requirements - ChatKit Integration

**FR-011**: System MUST integrate OpenAI ChatKit React library for chat interface components

**FR-012**: System MUST configure ChatKit to connect to existing backend endpoint (`POST /api/v1/chat`) using Better Auth JWT token in Authorization header

**FR-013**: System MUST replace custom chat components (ChatArea, ChatInput, ChatSidebar) with ChatKit equivalents

**FR-014**: System MUST maintain existing /chatbot page route and layout structure

**FR-015**: System MUST preserve conversation history functionality using existing database schema (conversations and messages tables)

**FR-016**: System MUST maintain "New Chat" functionality to create new conversations

**FR-017**: System MUST display conversation list in sidebar using data from existing `GET /api/v1/conversations` endpoint

**FR-018**: ChatKit MUST send messages to existing backend endpoint with current request format (message, conversation_id) and Better Auth JWT token for authentication

**FR-019**: ChatKit MUST display AI responses including tool call information from backend response

**FR-020**: System MUST handle ChatKit loading states, errors, and edge cases gracefully

**FR-024**: System MUST implement feature flag to toggle between custom chat components and ChatKit for instant rollback capability (zero downtime)

### Functional Requirements - Phase 4 Kubernetes Deployment Updates

**FR-025**: System MUST rebuild Docker images for frontend and backend after Better Auth and ChatKit integration is complete

**FR-026**: Frontend Docker image MUST include Better Auth dependencies and configuration

**FR-027**: Backend Docker image MUST include dual token validation logic for 7-day transition period

**FR-028**: Helm chart values MUST be updated to use new Docker image tags after rebuild

**FR-029**: System MUST deploy updated Helm chart to Minikube and verify Better Auth authentication works in Kubernetes environment

**FR-030**: System MUST verify ChatKit components render and function correctly when deployed via Helm to Minikube

**FR-031**: Kubernetes deployment MUST maintain existing ConfigMaps and Secrets while supporting new authentication flow

### Functional Requirements - Autonomous Testing via Claude Code CLI

**FR-032**: Claude Code CLI MUST autonomously register a new test user via backend API using Better Auth

**FR-033**: Claude Code CLI MUST autonomously login with test credentials and obtain valid JWT token

**FR-034**: Claude Code CLI MUST perform complete CRUD cycle via backend API: create task, list tasks, update task, mark complete, delete task

**FR-035**: Claude Code CLI MUST send natural language prompts to chatbot endpoint and verify correct task operations are performed

**FR-036**: Claude Code CLI MUST validate chatbot responses include expected tool call information (add_task, list_tasks, complete_task, delete_task, update_task)

**FR-037**: Claude Code CLI MUST interact with frontend UI elements (if headless browser available) to validate Better Auth login flow

**FR-038**: Claude Code CLI MUST interact with frontend chatbot page to validate ChatKit components render and function

**FR-039**: Claude Code CLI MUST generate comprehensive test report documenting all validation results with pass/fail status for each scenario

**FR-040**: Autonomous testing MUST complete within 15 minutes and report 100% pass rate for compliance validation

### Key Entities

- **User Account**: Existing user record in "users" table with email, hashed_password, name, id (UUID). Better Auth maps to this existing schema.

- **JWT Token**: Authentication token issued by Better Auth containing user_id in "sub" claim, compatible with existing backend verification.

- **Chat Message**: Message in conversation, displayed by ChatKit but stored in existing "messages" table.

- **Conversation**: Chat session stored in existing "conversations" table, managed by ChatKit UI but persisted via existing backend endpoints.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

**SC-001**: All existing user accounts (100%) can log in successfully after Better Auth integration without password reset

**SC-002**: New user registration completes in under 30 seconds and creates account in existing database schema

**SC-003**: Authentication flow (login/logout/session management) functions identically to previous implementation from user perspective

**SC-004**: Chat interface loads and displays messages within 2 seconds after ChatKit integration

**SC-005**: All existing chat functionality (send message, view history, new chat, conversation list) works with ChatKit components

**SC-006**: Zero data loss: All existing tasks, conversations, and messages remain accessible after migration

**SC-007**: All existing backend integration tests pass without modification after frontend changes

**SC-008**: Application meets 100% of hackathon Phase II and Phase III technology requirements (Better Auth + ChatKit)

**SC-009**: Docker images rebuild successfully with Better Auth and ChatKit code, with image sizes remaining under 500MB each

**SC-010**: Updated Helm chart deploys to Minikube without errors and application is accessible via NodePort within 5 minutes

**SC-011**: Deployed application on Minikube uses Better Auth for authentication and ChatKit for chat interface (verified via manual inspection)

**SC-012**: Claude Code CLI autonomously completes all validation scenarios (backend CRUD, chatbot natural language CRUD, frontend UI validation) within 15 minutes

**SC-013**: Autonomous testing reports 100% pass rate across all validation scenarios, confirming full compliance with hackathon requirements

---

## Assumptions

- Existing users table schema is compatible with Better Auth requirements (email, password, name fields exist)
- Current password hashing (bcrypt) is compatible with Better Auth's authentication mechanism
- Better Auth JWT tokens can be configured to match existing backend verification logic
- ChatKit can connect to existing REST API endpoints without requiring GraphQL or WebSocket changes
- Existing backend endpoints (`POST /api/v1/chat`, `GET /api/v1/conversations`) return data in format compatible with ChatKit expectations
- Development environment has access to install npm packages (better-auth, @openai/chatkit-react)
- No breaking changes in Better Auth or ChatKit APIs during implementation window
- Docker is installed and running in development environment
- Minikube is installed and configured for local Kubernetes deployments
- Existing Dockerfiles and Helm charts from Phase 4 can be updated without complete rewrites
- Claude Code CLI has necessary capabilities to interact with REST APIs, send HTTP requests, and validate responses
- Autonomous testing can be performed without requiring headless browser for frontend UI validation (or headless browser is available if needed)

---

## Dependencies

- **Better Auth library**: JavaScript/TypeScript authentication framework for Next.js
- **OpenAI ChatKit React**: Official chat interface components from OpenAI
- **Existing Phase II backend**: FastAPI with JWT verification logic
- **Existing Phase III backend**: OpenAI Agents SDK + MCP Server endpoints
- **Existing database schema**: Users, tasks, conversations, messages tables in Neon PostgreSQL
- **Next.js 15 frontend**: Current frontend framework and routing structure
- **Docker**: Container platform for building frontend and backend images
- **Helm**: Kubernetes package manager for deploying updated charts
- **Minikube**: Local Kubernetes cluster for testing deployments
- **Claude Code CLI**: AI assistant for autonomous system validation and testing

---

## Out of Scope

- Modifying backend API endpoints or request/response formats
- Changing database schema or adding new tables
- Implementing new authentication features (OAuth, SSO, 2FA) beyond Better Auth defaults
- Redesigning chat UI beyond ChatKit's standard components
- Adding new chat features not currently implemented
- Migrating to different database or authentication provider
- Performance optimization beyond maintaining current performance levels
- Adding analytics or monitoring for auth/chat usage
- Creating new Kubernetes infrastructure or cloud deployments (only updating existing Minikube setup)
- Implementing CI/CD pipelines for automated deployments
- Adding comprehensive end-to-end testing framework (only autonomous validation via Claude Code CLI)
- Modifying Phase I, Phase V, or any other phases beyond Phase II, III, and IV

---

## Constraints

- **Zero Data Loss**: All existing user accounts, tasks, conversations, and messages must remain intact and accessible
- **API Compatibility**: Backend endpoints must continue to work without modification
- **Time Constraint**: Implementation must complete within 4-5 hours to preserve time for Phase V (prioritize Better Auth: 3 hours, then ChatKit: 1-2 hours)
- **Technology Mandate**: Must use Better Auth (not alternatives) and ChatKit (not alternatives) per hackathon requirements
- **Schema Preservation**: Cannot modify existing database tables or add new required columns
- **Session Continuity**: Existing logged-in users should experience minimal disruption during deployment (dual token support for 7-day transition period)
- **Testing Requirement**: Must verify existing integration tests still pass after changes, plus test migration script to validate password compatibility
- **Rollback Capability**: Must implement feature flags for instant rollback to custom auth/chat systems (zero downtime)
