# Implementation Tasks: Hackathon Compliance Fixes

**Feature**: 009-compliance-fixes
**Branch**: `009-compliance-fixes`
**Spec**: [spec.md](./spec.md)
**Plan**: [plan.md](./plan.md)
**Estimated Time**: 4-5 hours

---

## Task Summary

**Total Tasks**: 62
**User Stories**: 6 (4 P1, 2 P2)
**Parallel Opportunities**: 18 tasks marked [P]
**MVP Scope**: User Stories 1 & 2 (Better Auth integration)

---

## Phase 1: Setup & Dependencies (30 minutes)

**Goal**: Install required dependencies and configure environment variables

### Tasks

- [ ] T001 [P] Install Better Auth dependencies in frontend: `cd calm-orbit-todo/frontend && npm install better-auth bcrypt @types/bcrypt`
- [ ] T002 [P] Install feature flag dependencies in backend: Add `python-decouple>=3.8` to `calm-orbit-todo/backend/requirements.txt` and run `pip install -r requirements.txt`
- [ ] T003 [P] Install ChatKit dependencies in frontend: `cd calm-orbit-todo/frontend && npm install @openai/chatkit-react`
- [ ] T004 Create frontend environment variables file: Copy `calm-orbit-todo/frontend/.env.example` to `.env.local` and add `BETTER_AUTH_SECRET`, `NEXT_PUBLIC_API_URL`, `DATABASE_URL`
- [ ] T005 Create backend environment variables file: Add to `calm-orbit-todo/backend/.env`: `BETTER_AUTH_SECRET`, `JWT_SECRET`, `AUTH_MIGRATION_ENABLED=true`, `ENABLE_LEGACY_TOKENS=true`, `LEGACY_TOKEN_CUTOFF_DATE=2026-01-15T00:00:00Z`
- [ ] T006 Verify Docker is running: `docker --version && docker ps`
- [ ] T007 Verify Minikube is installed: `minikube version`

---

## Phase 2: Foundational - Feature Flags & Dual Token Validation (45 minutes)

**Goal**: Implement feature flag system and dual token validation (blocking for all user stories)

**Why Foundational**: These components are required by all user stories and must be completed before any story-specific work begins.

### Tasks

- [ ] T008 [P] Implement backend feature flag configuration in `calm-orbit-todo/backend/app/config.py`: Add `use_new_auth`, `use_new_chat`, `rollback_auth`, `rollback_chat`, `is_feature_enabled()` method
- [ ] T009 [P] Implement frontend feature flags in `calm-orbit-todo/frontend/lib/features/flags.ts`: Export `featureFlags` object and `isFeatureEnabled()` function
- [ ] T010 Implement dual token validation function in `calm-orbit-todo/backend/app/core/auth.py`: Add `get_current_user_dual()` with try-catch fallback pattern for legacy and Better Auth JWT
- [ ] T011 Update authentication dependency in `calm-orbit-todo/backend/app/api/deps.py`: Modify `get_current_user()` to use `get_current_user_dual()` when `auth_migration_enabled=true`
- [ ] T012 Add logging for token validation in `calm-orbit-todo/backend/app/core/auth.py`: Log token type (legacy vs Better Auth) and user_id for monitoring
- [ ] T013 Create Kubernetes ConfigMap for feature flags: `kubectl create configmap feature-flags --from-literal=FEATURE_NEW_AUTH=false --from-literal=FEATURE_NEW_CHAT=false --from-literal=ROLLBACK_AUTH=false --from-literal=ROLLBACK_CHAT=false -n todo-app --dry-run=client -o yaml > calm-orbit-todo/k8s/feature-flags-configmap.yaml`

---

## Phase 3: User Story 1 - Existing Users Login with Better Auth (P1) (1 hour)

**Goal**: Existing users can log in with Better Auth using their current credentials

**Independent Test**: Create user account before migration, attempt login after Better Auth integration, verify all user data accessible

**Acceptance Criteria**:
- ✅ Existing user accounts can log in with original credentials
- ✅ User sessions remain valid during deployment
- ✅ All user data (tasks, conversations) accessible after login

### Tasks

- [ ] T014 [P] [US1] Create Better Auth configuration file in `calm-orbit-todo/frontend/lib/auth/config.ts`: Configure `betterAuth()` with bcrypt password hash/verify functions, JWT plugin with user_id in "sub" claim
- [ ] T015 [P] [US1] Create custom database adapter in `calm-orbit-todo/frontend/lib/auth/custom-adapter.ts`: Implement user and account operations mapping to existing users table
- [ ] T016 [P] [US1] Create Better Auth client in `calm-orbit-todo/frontend/lib/auth/client.ts`: Export `authClient` with `signIn`, `signUp`, `signOut`, `useSession` methods
- [ ] T017 [US1] Create Better Auth API route handler in `calm-orbit-todo/frontend/app/api/auth/[...all]/route.ts`: Export `POST` and `GET` handlers using `toNextJsHandler(auth)`
- [ ] T018 [US1] Update backend to accept Better Auth JWT tokens in `calm-orbit-todo/backend/app/core/auth.py`: Ensure `get_current_user_dual()` validates Better Auth tokens with issuer="better-auth"
- [ ] T019 [US1] Update login page in `calm-orbit-todo/frontend/app/login/page.tsx`: Replace custom auth client calls with Better Auth `signIn.email()` method
- [ ] T020 [US1] Create test migration script in `calm-orbit-todo/backend/tests/integration/test_auth_migration.py`: Test existing user login with bcrypt passwords via Better Auth
- [ ] T021 [US1] Run test migration script: `cd calm-orbit-todo/backend && pytest tests/integration/test_auth_migration.py -v`
- [ ] T022 [US1] Manual test: Create test user with custom auth, deploy Better Auth, verify login works with same credentials

---

## Phase 4: User Story 2 - New Users Register via Better Auth (P1) (30 minutes)

**Goal**: New users can register accounts using Better Auth

**Independent Test**: Register new account after Better Auth integration, verify account created in database, verify immediate login works

**Acceptance Criteria**:
- ✅ New users can register with email and password
- ✅ Account created in existing users table
- ✅ User can immediately log in and use all features

### Tasks

- [ ] T023 [P] [US2] Update registration page in `calm-orbit-todo/frontend/app/register/page.tsx`: Replace custom auth client calls with Better Auth `signUp.email()` method
- [ ] T024 [US2] Verify Better Auth creates users in existing schema: Test that `signUp.email()` inserts into users table with bcrypt hashed_password
- [ ] T025 [US2] Test duplicate email registration: Verify Better Auth returns appropriate error for existing email
- [ ] T026 [US2] Manual test: Register new user via Better Auth, verify database record, login immediately, create task to verify user_id association

---

## Phase 5: User Story 4 - Backend Endpoints Remain Unchanged (P1) (15 minutes)

**Goal**: Verify all existing backend API endpoints work without modification

**Independent Test**: Run existing integration tests, verify all pass without modification

**Acceptance Criteria**:
- ✅ All existing integration tests pass
- ✅ API contracts preserved
- ✅ Better Auth JWT tokens accepted by backend

### Tasks

- [ ] T027 [US4] Run existing backend integration tests: `cd calm-orbit-todo/backend && pytest tests/integration/ -v`
- [ ] T028 [US4] Verify tasks API accepts Better Auth tokens: Test `POST /api/v1/tasks` with Better Auth JWT token
- [ ] T029 [US4] Verify chat API accepts Better Auth tokens: Test `POST /api/v1/chat` with Better Auth JWT token
- [ ] T030 [US4] Verify conversations API accepts Better Auth tokens: Test `GET /api/v1/conversations` with Better Auth JWT token

---

## Phase 6: User Story 3 - ChatKit Integration (P2) (1-1.5 hours)

**Goal**: Replace custom chat components with OpenAI ChatKit

**Independent Test**: Open /chatbot page, verify ChatKit renders, send message, verify conversation history loads

**Acceptance Criteria**:
- ✅ ChatKit components render on /chatbot page
- ✅ Messages send to existing backend endpoint
- ✅ Conversation history loads correctly
- ✅ New chat creation works

### Tasks

- [ ] T031 [P] [US3] Add ChatKit script to layout in `calm-orbit-todo/frontend/app/layout.tsx`: Add `<Script src="https://cdn.platform.openai.com/deployments/chatkit/chatkit.js" strategy="beforeInteractive" />`
- [ ] T032 [P] [US3] Create ChatKit session endpoint in `calm-orbit-todo/frontend/app/api/chatkit/session/route.ts`: Implement `POST` handler that creates OpenAI ChatKit session with Better Auth JWT authentication
- [ ] T033 [US3] Create ChatKit page component in `calm-orbit-todo/frontend/components/chat/ChatKitPage.tsx`: Implement `useChatKit()` with `getClientSecret()` function
- [ ] T034 [US3] Update chatbot page with feature flag toggle in `calm-orbit-todo/frontend/app/(authenticated)/chatbot/page.tsx`: Conditionally render ChatKitPage or LegacyChatPage based on `isFeatureEnabled('useNewChat')`
- [ ] T035 [US3] Configure ChatKit to use existing backend endpoints: Verify ChatKit calls `POST /api/v1/chat` with Better Auth JWT token
- [ ] T036 [US3] Test ChatKit message sending: Send "Add task to buy groceries" and verify backend processes via MCP tools
- [ ] T037 [US3] Test ChatKit conversation history: Verify existing conversations load in ChatKit sidebar
- [ ] T038 [US3] Test ChatKit new chat creation: Click "New Chat" and verify new conversation saved to database

---

## Phase 7: User Story 5 - Phase 4 Kubernetes Deployment (P1) (45 minutes)

**Goal**: Update Docker images and Helm charts to deploy compliant versions

**Independent Test**: Rebuild Docker images, deploy to Minikube, verify Better Auth and ChatKit work in Kubernetes

**Acceptance Criteria**:
- ✅ Docker images rebuild successfully
- ✅ Helm chart deploys to Minikube
- ✅ Deployed application uses Better Auth and ChatKit

### Tasks

- [ ] T039 [P] [US5] Rebuild backend Docker image: `cd calm-orbit-todo/backend && docker build -t todo-backend:v1.1.0 .`
- [ ] T040 [P] [US5] Rebuild frontend Docker image: `cd calm-orbit-todo/frontend && docker build -t todo-frontend:v1.1.0 .`
- [ ] T041 [US5] Load backend image into Minikube: `minikube image load todo-backend:v1.1.0`
- [ ] T042 [US5] Load frontend image into Minikube: `minikube image load todo-frontend:v1.1.0`
- [ ] T043 [US5] Update Helm chart values in `charts/todo-chatbot/values.yaml`: Set `backend.image.tag=v1.1.0` and `frontend.image.tag=v1.1.0`
- [ ] T044 [US5] Update Helm chart version in `charts/todo-chatbot/Chart.yaml`: Set `version=0.2.0` and `appVersion="1.1.0"`
- [ ] T045 [US5] Apply feature flags ConfigMap: `kubectl apply -f calm-orbit-todo/k8s/feature-flags-configmap.yaml -n todo-app`
- [ ] T046 [US5] Deploy updated Helm chart: `helm upgrade --install todo-chatbot ./charts/todo-chatbot -n todo-app --create-namespace`
- [ ] T047 [US5] Verify pods are running: `kubectl get pods -n todo-app`
- [ ] T048 [US5] Verify Better Auth works in Kubernetes: Access application via NodePort and test login
- [ ] T049 [US5] Verify ChatKit works in Kubernetes: Access /chatbot page and test message sending

---

## Phase 8: User Story 6 - Autonomous Testing (P2) (30 minutes)

**Goal**: Implement autonomous system validation via Claude Code CLI

**Independent Test**: Run Claude Code CLI test scripts, verify 100% pass rate

**Acceptance Criteria**:
- ✅ CLI autonomously registers and logs in
- ✅ CLI performs complete CRUD cycle
- ✅ CLI tests chatbot natural language commands
- ✅ Test report shows 100% pass rate

### Tasks

- [ ] T050 [P] [US6] Create autonomous API test script in `calm-orbit-todo/backend/tests/autonomous/test_api_workflow.py`: Implement register, login, CRUD operations test
- [ ] T051 [P] [US6] Create autonomous chatbot test script in `calm-orbit-todo/backend/tests/autonomous/test_chatbot_autonomous.py`: Implement natural language command testing with response validation
- [ ] T052 [P] [US6] Create test report generator in `calm-orbit-todo/backend/tests/autonomous/generate_report.py`: Generate Markdown and JSON test reports
- [ ] T053 [US6] Run autonomous API tests: `cd calm-orbit-todo/backend && python tests/autonomous/test_api_workflow.py`
- [ ] T054 [US6] Run autonomous chatbot tests: `cd calm-orbit-todo/backend && python tests/autonomous/test_chatbot_autonomous.py`
- [ ] T055 [US6] Generate test report: `cd calm-orbit-todo/backend && python tests/autonomous/generate_report.py`
- [ ] T056 [US6] Verify 100% pass rate: Check test report confirms all scenarios passed

---

## Phase 9: Polish & Cross-Cutting Concerns (30 minutes)

**Goal**: Enable feature flags, verify rollback capability, final validation

### Tasks

- [ ] T057 [P] Enable Better Auth feature flag in development: Set `FEATURE_NEW_AUTH=true` in `.env.local`
- [ ] T058 [P] Enable ChatKit feature flag in development: Set `FEATURE_NEW_CHAT=true` in `.env.local`
- [ ] T059 Test feature flag rollback for auth: Set `ROLLBACK_AUTH=true`, verify application uses legacy auth
- [ ] T060 Test feature flag rollback for chat: Set `ROLLBACK_CHAT=true`, verify application uses legacy chat
- [ ] T061 Run full integration test suite: `cd calm-orbit-todo/backend && pytest tests/integration/ -v && cd ../frontend && npm test`
- [ ] T062 Final manual validation: Test complete user flow (register, login, create task, chat with bot, logout)

---

## Dependencies & Execution Order

### User Story Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational: Feature Flags + Dual Token)
    ↓
    ├─→ Phase 3 (US1: Existing Users Login) ──┐
    ├─→ Phase 4 (US2: New Users Register) ────┤
    └─→ Phase 5 (US4: Backend Unchanged) ─────┤
                                               ↓
                                    Phase 6 (US3: ChatKit)
                                               ↓
                                    Phase 7 (US5: Kubernetes)
                                               ↓
                                    Phase 8 (US6: Autonomous Testing)
                                               ↓
                                    Phase 9 (Polish)
```

**Critical Path**: Setup → Foundational → US1 → US3 → US5 → US6 → Polish

**Parallel Opportunities**:
- Phase 3, 4, 5 can run in parallel (US1, US2, US4 are independent)
- Phase 7 tasks T039-T042 (Docker builds and image loads) can run in parallel
- Phase 8 tasks T050-T052 (test script creation) can run in parallel
- Phase 9 tasks T057-T058 (feature flag enabling) can run in parallel

---

## Parallel Execution Examples

### Phase 2: Foundational (2 parallel tracks)

**Track A (Backend)**:
- T008 → T010 → T011 → T012

**Track B (Frontend)**:
- T009 → T013

### Phase 3-5: User Stories 1, 2, 4 (3 parallel tracks)

**Track A (US1: Existing Users Login)**:
- T014 → T015 → T016 → T017 → T018 → T019 → T020 → T021 → T022

**Track B (US2: New Users Register)**:
- T023 → T024 → T025 → T026

**Track C (US4: Backend Unchanged)**:
- T027 → T028 → T029 → T030

### Phase 7: Kubernetes Deployment (2 parallel tracks)

**Track A (Docker Images)**:
- T039 (backend) || T040 (frontend) → T041 (load backend) || T042 (load frontend)

**Track B (Helm Configuration)**:
- T043 → T044 → T045

Then merge: T046 → T047 → T048 → T049

### Phase 8: Autonomous Testing (parallel test creation)

**Track A**: T050 (API tests)
**Track B**: T051 (Chatbot tests)
**Track C**: T052 (Report generator)

Then sequential: T053 → T054 → T055 → T056

---

## Implementation Strategy

### MVP Scope (Minimum Viable Product)

**Recommended MVP**: User Stories 1 & 2 (Better Auth Integration)

**Rationale**: Authentication is the highest priority for hackathon compliance. Completing US1 and US2 ensures:
- ✅ Existing users can continue using the application
- ✅ New users can register
- ✅ Core compliance requirement (Better Auth) is met
- ✅ Foundation for remaining stories is established

**MVP Tasks**: T001-T026 (26 tasks, ~2.5 hours)

### Incremental Delivery Plan

**Iteration 1 (MVP)**: Setup + Foundational + US1 + US2
- Deliverable: Better Auth integrated, all users can authenticate
- Time: 2.5 hours
- Risk: Low (preserves existing functionality)

**Iteration 2**: US4 + US3
- Deliverable: Backend validated, ChatKit integrated
- Time: 1.5 hours
- Risk: Medium (ChatKit is new UI component)

**Iteration 3**: US5 + US6
- Deliverable: Kubernetes deployment updated, autonomous testing complete
- Time: 1.25 hours
- Risk: Low (deployment and validation)

**Total Time**: 5.25 hours (within 4-5 hour constraint with buffer)

---

## Testing Strategy

### Manual Testing Checkpoints

**After Phase 3 (US1)**:
- [ ] Existing user can log in with original credentials
- [ ] User data (tasks, conversations) accessible after login
- [ ] JWT token contains user_id in "sub" claim

**After Phase 4 (US2)**:
- [ ] New user can register successfully
- [ ] New user account created in users table
- [ ] New user can immediately log in

**After Phase 6 (US3)**:
- [ ] ChatKit components render on /chatbot page
- [ ] Messages send to backend and receive responses
- [ ] Conversation history loads correctly

**After Phase 7 (US5)**:
- [ ] Application accessible via Minikube NodePort
- [ ] Better Auth login works in Kubernetes
- [ ] ChatKit works in Kubernetes

### Automated Testing

**Integration Tests** (Phase 5, US4):
- Run existing backend integration tests
- Verify all tests pass without modification
- Confirms API contracts preserved

**Autonomous Tests** (Phase 8, US6):
- Backend CRUD operations
- Chatbot natural language commands
- Test report generation

---

## Rollback Procedures

### Feature Flag Rollback (Instant)

**Disable Better Auth**:
```bash
kubectl patch configmap feature-flags -n todo-app -p '{"data":{"ROLLBACK_AUTH":"true"}}'
```

**Disable ChatKit**:
```bash
kubectl patch configmap feature-flags -n todo-app -p '{"data":{"ROLLBACK_CHAT":"true"}}'
```

### Helm Rollback (Full)

```bash
helm rollback todo-chatbot -n todo-app
```

Or deploy previous image versions:
```bash
helm upgrade todo-chatbot ./charts/todo-chatbot \
  --set backend.image.tag=v1.0.0 \
  --set frontend.image.tag=v1.0.0 \
  -n todo-app
```

---

## Success Metrics

### Completion Criteria

- [ ] All 62 tasks completed
- [ ] All 6 user stories validated
- [ ] All existing integration tests pass
- [ ] Autonomous testing reports 100% pass rate
- [ ] Application deployed to Minikube successfully
- [ ] Feature flags enable instant rollback
- [ ] Zero data loss confirmed
- [ ] Implementation time within 4-5 hours

### Quality Gates

**Gate 1 (After Phase 2)**: Feature flags and dual token validation working
**Gate 2 (After Phase 4)**: Better Auth fully integrated, all users can authenticate
**Gate 3 (After Phase 6)**: ChatKit integrated, chat functionality working
**Gate 4 (After Phase 7)**: Kubernetes deployment successful
**Gate 5 (After Phase 8)**: Autonomous testing confirms 100% compliance

---

## Task Format Validation

✅ **All tasks follow required format**:
- Checkbox: `- [ ]`
- Task ID: Sequential (T001-T062)
- [P] marker: 18 tasks marked as parallelizable
- [Story] label: 40 tasks labeled with user story (US1-US6)
- Description: Clear action with exact file path

✅ **Task organization**:
- Phase 1: Setup (7 tasks)
- Phase 2: Foundational (6 tasks)
- Phase 3: US1 (9 tasks)
- Phase 4: US2 (4 tasks)
- Phase 5: US4 (4 tasks)
- Phase 6: US3 (8 tasks)
- Phase 7: US5 (11 tasks)
- Phase 8: US6 (7 tasks)
- Phase 9: Polish (6 tasks)

---

**Tasks Status**: ✅ Ready for Implementation
**Next Command**: `/sp.implement` or begin manual implementation following task order
