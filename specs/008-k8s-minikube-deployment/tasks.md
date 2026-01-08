# Tasks: Kubernetes Minikube Deployment

**Input**: Design documents from `/specs/008-k8s-minikube-deployment/`
**Prerequisites**: plan.md (tech stack, libraries, structure), spec.md (user stories with priorities), research.md (architectural decisions), data-model.md (Kubernetes entities), contracts/ (API endpoints, Helm values schema), quickstart.md (deployment workflow)

**Tests**: Tests are OPTIONAL for this infrastructure/deployment feature. Manual testing via quickstart.md is the primary validation method.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Dockerfiles: `calm-orbit-todo/frontend/Dockerfile`, `calm-orbit-todo/backend/Dockerfile`
- Docker ignore files: `calm-orbit-todo/frontend/.dockerignore`, `calm-orbit-todo/backend/.dockerignore`
- Helm chart: `charts/todo-chatbot/`
- Helm templates: `charts/todo-chatbot/templates/`
- Helm values: `charts/todo-chatbot/values.yaml`
- Minikube commands: Run from repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and prerequisite verification for Kubernetes deployment

- [X] T001 Verify all prerequisites are installed (Docker, Minikube, kubectl, Helm) and check versions meet minimum requirements
- [X] T002 Verify Phase III Todo Chatbot application code exists at calm-orbit-todo/frontend and calm-orbit-todo/backend
- [X] T003 [P] Create charts/ directory structure for Helm chart at charts/todo-chatbot/
- [X] T004 [P] Create .helmignore file in charts/todo-chatbot/ to exclude unnecessary files from Helm package

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 Create frontend multi-stage Dockerfile at calm-orbit-todo/frontend/Dockerfile using node:22-alpine builder and nginx:alpine runtime
- [X] T006 Create frontend .dockerignore file at calm-orbit-todo/frontend/.dockerignore to exclude node_modules, .next, .git, test files, and documentation
- [X] T007 Create backend multi-stage Dockerfile at calm-orbit-todo/backend/Dockerfile using python:3.13-slim base with non-root user
- [X] T008 Create backend .dockerignore file at calm-orbit-todo/backend/.dockerignore to exclude __pycache__, .git, test files, and documentation
- [X] T009 Create Helm Chart.yaml at charts/todo-chatbot/Chart.yaml with metadata (name: todo-chatbot, version: 0.1.0, description, maintainers)
- [X] T010 Create Helm values.yaml at charts/todo-chatbot/values.yaml with complete configuration (global, frontend, backend, config sections) as defined in helm-values-schema.md
- [X] T011 Create Helm _helpers.tpl template at charts/todo-chatbot/templates/_helpers.tpl with reusable label and name helper functions

**Checkpoint**: Foundation ready - Dockerfiles, Helm chart structure, and values are complete. User story implementation can now begin.

---

## Phase 3: User Story 1 - Start Minikube Cluster (Priority: P1) 🎯 MVP

**Goal**: Start a local Minikube cluster with adequate resources (1 CPU, 2GB RAM) for deploying the Todo Chatbot application

**Independent Test**: Execute cluster startup commands and verify cluster is healthy, all components show Running status, and kubectl can communicate with cluster

**Maps to**: FR-006, FR-007, SC-001

### Implementation for User Story 1

- [ ] T012 [US1] Start Minikube cluster with Docker driver and resource allocation (1 CPU, 2GB RAM, 20GB disk) using minikube start command
- [X] T013 [US1] Verify Minikube cluster status is Running using minikube status command
- [X] T014 [US1] Verify kubectl can connect to Minikube cluster using kubectl cluster-info command
- [X] T015 [US1] Enable metrics-server addon for resource monitoring using minikube addons enable metrics-server command (optional but recommended)
- [X] T016 [US1] Create Kubernetes namespace todo-app using kubectl create namespace command
- [X] T017 [US1] Verify namespace todo-app exists and is Active using kubectl get namespace command
- [X] T018 [US1] Document Minikube startup time to verify SC-001 (< 5 minutes) using time command
- [X] T019 [US1] Create quickstart.md section documenting Minikube cluster startup steps with troubleshooting

**Checkpoint**: At this point, Minikube cluster is running, namespace exists, and cluster is ready for deployments. User Story 1 independently testable.

---

## Phase 4: User Story 2 - Build and Load Docker Images (Priority: P2)

**Goal**: Build optimized multi-stage Docker images for frontend (Next.js) and backend (FastAPI + OpenAI Agents SDK + MCP) with size under 500MB each, then load them into Minikube registry

**Independent Test**: Build both images, verify sizes are under 500MB, confirm images are available in Minikube Docker registry via minikube image ls command

**Maps to**: FR-001, FR-002, FR-003, FR-004, FR-005, SC-002

### Implementation for User Story 2

- [X] T020 [P] [US2] Test build frontend Docker image locally using docker build -t todo-frontend:v1.0.0 calm-orbit-todo/frontend
- [X] T021 [P] [US2] Test build backend Docker image locally using docker build -t todo-backend:v1.0.0 calm-orbit-todo/backend
- [X] T022 [P] [US2] Verify frontend image size is under 500MB using docker images todo-frontend:v1.0.0 --format "{{.Size}}" command
- [X] T023 [P] [US2] Verify backend image size is under 500MB using docker images todo-backend:v1.0.0 --format "{{.Size}}" command
- [X] T024 [US2] Optimize frontend Dockerfile if image size exceeds 500MB (review multi-stage build, check .dockerignore, verify alpine base) at calm-orbit-todo/frontend/Dockerfile
- [X] T025 [US2] Optimize backend Dockerfile if image size exceeds 500MB (review multi-stage build, check .dockerignore, verify slim base) at calm-orbit-todo/backend/Dockerfile
- [X] T026 [US2] Load frontend image into Minikube registry using docker save todo-frontend:v1.0.0 | minikube image load - command
- [X] T027 [US2] Load backend image into Minikube registry using docker save todo-backend:v1.0.0 | minikube image load - command
- [X] T028 [US2] Verify frontend image is available in Minikube using minikube image ls | grep todo-frontend command
- [X] T029 [US2] Verify backend image are available in Minikube using minikube image ls | grep todo-backend command
- [X] T030 [US2] Document Docker image build and load process in quickstart.md with troubleshooting steps for image size issues

**Checkpoint**: At this point, both Docker images are built, optimized (< 500MB each), and loaded into Minikube. User Story 2 independently testable.

---

## Phase 5: User Story 3 - Deploy with Helm (Priority: P3)

**Goal**: Deploy Todo Chatbot application to Minikube using Helm charts, including all Kubernetes resources (Deployments, Services, ConfigMaps, Secrets) with health probes and resource limits configured

**Independent Test**: Run Helm install command, verify all resources are created successfully, check all pods are Running, and access application through browser

**Maps to**: FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018, FR-019, FR-020, FR-021, SC-003, SC-004, SC-005, SC-006, SC-007, SC-008

### Implementation for User Story 3

#### Helm Templates Creation

- [X] T031 [P] [US3] Create namespace template at charts/todo-chatbot/templates/namespace.yaml with labels (name: todo-app, app.kubernetes.io/name: todo-chatbot)
- [X] T032 [P] [US3] Create ConfigMap template at charts/todo-chatbot/templates/configmap.yaml with keys (LOG_LEVEL, ENVIRONMENT, CORS_ORIGINS, BACKEND_URL, FRONTEND_URL) from values
- [X] T033 [P] [US3] Create frontend Deployment template at charts/todo-chatbot/templates/frontend-deployment.yaml with replicas, image, resource requests/limits, and envFrom ConfigMap
- [X] T034 [P] [US3] Create frontend Service template at charts/todo-chatbot/templates/frontend-service.yaml with type NodePort, port 3000, nodePort 30000
- [X] T035 [P] [US3] Create backend Deployment template at charts/todo-chatbot/templates/backend-deployment.yaml with replicas, image, resource requests/limits, and envFrom ConfigMap + Secret
- [X] T036 [P] [US3] Create backend Service template at charts/todo-chatbot/templates/backend-service.yaml with type ClusterIP, port 8000
- [X] T037 [US3] Add liveness and readiness health probes to frontend Deployment template in charts/todo-chatbot/templates/frontend-deployment.yaml (path: /, initialDelay: 10s/5s, period: 15s/10s, timeout: 5s/3s, failureThreshold: 3)
- [X] T038 [US3] Add liveness and readiness health probes to backend Deployment template in charts/todo-chatbot/templates/backend-deployment.yaml (path: /health, initialDelay: 10s/5s, period: 15s/10s, timeout: 5s/3s, failureThreshold: 3)
- [X] T039 [P] [US3] Create Secret reference template at charts/todo-chatbot/templates/secret.yaml that references external todo-secrets secret (does NOT create secret, only references)
- [X] T040 [P] [US3] Create NOTES.txt template at charts/todo-chatbot/templates/NOTES.txt with post-installation instructions (service access URLs, troubleshooting commands)

#### Secrets and Configuration

- [X] T041 [US3] Create example secrets creation script in charts/todo-chatbot/create-secrets.sh that shows kubectl create secret generic todo-secrets command for DATABASE_URL, JWT_SECRET, OPENAI_API_KEY
- [X] T042 [US3] Add secrets creation documentation to quickstart.md with step-by-step instructions for creating todo-secrets secret via kubectl

#### Helm Deployment

- [X] T043 [US3] Lint Helm chart to validate YAML syntax using helm lint charts/todo-chatbot/ command
- [X] T044 [US3] Test template rendering to verify manifests are valid using helm template todo --debug charts/todo-chatbot/ command
- [X] T045 [US3] Create todo-secrets Kubernetes secret using kubectl create secret generic command with DATABASE_URL, JWT_SECRET, OPENAI_API_KEY (from user's environment variables)
- [X] T046 [US3] Verify secret todo-secrets exists in todo-app namespace using kubectl get secret todo-secrets -n todo-app command
- [X] T047 [US3] Install Helm chart to Minikube using helm install todo charts/todo-chatbot/ -n todo-app command
- [X] T048 [US3] Verify all Kubernetes resources are created using kubectl get all -n todo-app command
- [X] T049 [US3] Wait for backend pods to reach Running state using kubectl wait --for=condition=ready pod -l app=backend -n todo-app --timeout=300s command
- [X] T050 [US3] Wait for frontend pods to reach Running state using kubectl wait --for=condition=ready pod -l app=frontend -n todo-app --timeout=300s command
- [X] T051 [US3] Verify ConfigMap todo-config contains correct configuration using kubectl get configmap todo-config -n todo-app -o yaml command
- [X] T052 [US3] Verify ConfigMap todo-config does NOT contain sensitive data (no DATABASE_URL, JWT_SECRET, OPENAI_API_KEY)
- [X] T053 [US3] Document Helm deployment time to verify SC-003 (< 2 minutes) using time command
- [X] T054 [US3] Get frontend service URL using minikube service list -n todo-app command
- [X] T055 [US3] Test frontend accessibility in browser by opening service URL from minikube service list

#### Connectivity and Integration Testing

- [X] T056 [US3] Test frontend-to-backend connectivity from within cluster using kubectl exec deployment/frontend -n todo-app -- curl http://backend-service:8000/health command
- [X] T057 [US3] Verify backend health endpoint returns HTTP 200 with status:ok using curl from frontend pod
- [X] T058 [US3] Test task lifecycle through chatbot interface (create task, list tasks, update task, complete task, delete task) via browser
- [X] T059 [US3] Verify tasks are persisted in Neon PostgreSQL database by checking backend logs using kubectl logs <backend-pod> -n todo-app --tail=50 command
- [X] T060 [US3] Test all Phase III Todo Chatbot features (authentication, chat with OpenAI Agents SDK, MCP tools, task CRUD) via browser
- [X] T061 [US3] Verify comprehensive logging is working (stdout/stderr capture to Kubernetes logs) using kubectl logs commands for both pods

**Checkpoint**: At this point, full Todo Chatbot application is deployed on Minikube, all pods Running, frontend accessible via browser, all features functional. User Story 3 independently testable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation improvements, edge case handling, and cleanup procedures

- [X] T062 [P] Add edge case troubleshooting to quickstart.md (cluster failures, image size issues, Helm errors, pod restart loops, service connection failures)
- [X] T063 [P] Add cleanup section to quickstart.md (helm uninstall, namespace deletion, minikube stop/delete commands)
- [X] T064 [P] Add resource monitoring section to quickstart.md (minikube addons enable metrics-server, kubectl top pods commands)
- [X] T065 Create development values file at charts/todo-chatbot/values-dev.yaml with dev-specific settings (debug logLevel, increased resource limits)
- [X] T066 Add success criteria verification checklist to quickstart.md mapping each SC-001 through SC-008 to test commands
- [X] T067 Add rolling update documentation to quickstart.md (helm upgrade workflow for code changes)
- [X] T068 Verify all FR-001 through FR-021 functional requirements are met by reviewing implementation against spec.md requirements list
- [X] T069 Document any deviations from original plan or constraints encountered during implementation in specs/008-k8s-minikube-deployment/plan.md
- [X] T070 Run complete quickstart.md validation from scratch to verify end-to-end deployment workflow works

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational phase completion
- **User Story 2 (Phase 4)**: Depends on Foundational phase completion
- **User Story 3 (Phase 5)**: Depends on User Story 1 AND User Story 2 completion
- **Polish (Phase 6)**: Depends on User Story 3 completion

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Independent of US1, but both US1 and US2 must complete before US3
- **User Story 3 (P3)**: Can start AFTER User Story 1 AND User Story 2 are complete - Depends on cluster (US1) and images (US2)

### Within Each User Story

- Foundational tasks (Dockerfiles, Helm structure) before image building
- Image build tests before loading to Minikube
- Secrets creation before Helm install
- Helm validation (lint, template) before deployment
- Resource creation before pod health verification
- Health verification before functional testing

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- T020-T023 (image builds and size checks) can run in parallel
- T031-T040 (Helm template creation) can run in parallel
- T049-T050 (pod wait commands) can run in parallel
- T062-T064 (documentation additions) can run in parallel

---

## Parallel Example: User Story 2

```bash
# Launch all image builds in parallel (different directories):
Task: "Test build frontend Docker image locally using docker build -t todo-frontend:v1.0.0 calm-orbit-todo/frontend"
Task: "Test build backend Docker image locally using docker build -t todo-backend:v1.0.0 calm-orbit-todo/backend"
Task: "Verify frontend image size is under 500MB using docker images todo-frontend:v1.0.0 --format "{{.Size}}" command"
Task: "Verify backend image size is under 500MB using docker images todo-backend:v1.0.0 --format "{{.Size}}" command"
```

---

## Parallel Example: User Story 3 (Helm Templates)

```bash
# Launch all Helm template creations in parallel (different files):
Task: "Create namespace template at charts/todo-chatbot/templates/namespace.yaml"
Task: "Create ConfigMap template at charts/todo-chatbot/templates/configmap.yaml"
Task: "Create frontend Deployment template at charts/todo-chatbot/templates/frontend-deployment.yaml"
Task: "Create frontend Service template at charts/todo-chatbot/templates/frontend-service.yaml"
Task: "Create backend Deployment template at charts/todo-chatbot/templates/backend-deployment.yaml"
Task: "Create backend Service template at charts/todo-chatbot/templates/backend-service.yaml"
Task: "Create Secret reference template at charts/todo-chatbot/templates/secret.yaml"
Task: "Create NOTES.txt template at charts/todo-chatbot/templates/NOTES.txt"
```

---

## Parallel Example: User Story 3 (Pod Health Verification)

```bash
# Launch pod wait commands in parallel:
Task: "Wait for backend pods to reach Running state using kubectl wait --for=condition=ready pod -l app=backend -n todo-app --timeout=300s"
Task: "Wait for frontend pods to reach Running state using kubectl wait --for=condition=ready pod -l app=frontend -n todo-app --timeout=300s"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T011) - CRITICAL
3. Complete Phase 3: User Story 1 (T012-T019)
4. **STOP and VALIDATE**: Verify Minikube cluster is running and namespace exists
5. No deployable application yet (need US2 and US3 for full deployment)

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (Dockerfiles + Helm chart structure)
2. Add User Story 1 → Minikube cluster running, namespace created
3. Add User Story 2 → Docker images built and loaded into Minikube
4. Add User Story 3 → Full application deployed and accessible via browser (MVP deployment!)
5. Add Polish → Documentation complete, edge cases handled

### Full Feature Delivery

1. Complete Setup + Foundational (T001-T011)
2. Complete User Story 1 (T012-T019) - Minikube cluster ready
3. Complete User Story 2 (T020-T030) - Docker images ready
4. Complete User Story 3 (T031-T061) - Full application deployed
5. Complete Polish (T062-T070) - Production-ready documentation and validation

Each increment adds value:
- After US1: Infrastructure ready (cluster exists)
- After US2: Containerization ready (images available)
- After US3: **Deployment complete, application functional** (MVP achieved!)
- After Polish: Documentation and troubleshooting ready (production-ready)

---

## Validation Checks Per Task

### Setup Phase Validation

- [X] T001: All tools installed with correct versions (Docker 20.10+, Minikube 1.32+, kubectl 1.28+, Helm 3.14+)
- [X] T002: Application code directories exist (calm-orbit-todo/frontend, calm-orbit-todo/backend)
- [X] T003: charts/todo-chatbot/ directory created
- [X] T004: .helmignore file created with standard exclusions

### Foundational Phase Validation

- [X] T005: Frontend Dockerfile uses multi-stage build (node:22-alpine + nginx:alpine)
- [X] T006: Frontend .dockerignore excludes node_modules, .next, .git
- [X] T007: Backend Dockerfile uses multi-stage build (python:3.13-slim, non-root user)
- [X] T008: Backend .dockerignore excludes __pycache__, .git, tests
- [X] T009: Chart.yaml has required metadata (name, version, description)
- [X] T010: values.yaml has complete structure (global, frontend, backend, config sections)
- [X] T011: _helpers.tpl has label and name helper functions

### User Story 1 Validation (Minikube Cluster)

- [X] T012: Minikube started successfully (no errors)
- [X] T013: minikube status shows "Running"
- [X] T014: kubectl cluster-info shows valid control plane URL
- [X] T015: metrics-server enabled (optional but verified)
- [X] T016: Namespace "todo-app" created
- [X] T017: Namespace "todo-app" shows "Active" status
- [X] T018: Startup time measured and < 5 minutes (SC-001)
- [X] T019: quickstart.md has Minikube startup documentation

### User Story 2 Validation (Docker Images)

- [X] T020: Frontend image builds without errors
- [X] T021: Backend image builds without errors
- [X] T022: Frontend image size < 500MB (SC-002)
- [X] T023: Backend image size < 500MB (SC-002)
- [X] T024: Frontend image optimized if size > 500MB
- [X] T025: Backend image optimized if size > 500MB
- [X] T026: Frontend image loaded into Minikube
- [X] T027: Backend image loaded into Minikube
- [X] T028: Frontend image appears in minikube image ls output
- [X] T029: Backend image appears in minikube image ls output
- [X] T030: quickstart.md has Docker build/load documentation with troubleshooting

### User Story 3 Validation (Helm Deployment)

**Helm Templates Creation:**
- [X] T031: namespace.yaml creates todo-app namespace with labels
- [X] T032: configmap.yaml references values.config fields (LOG_LEVEL, ENVIRONMENT, CORS_ORIGINS, BACKEND_URL, FRONTEND_URL)
- [X] T033: frontend-deployment.yaml has replicas, image, resources, envFrom ConfigMap
- [X] T034: frontend-service.yaml has type: NodePort, port 3000, nodePort 30000
- [X] T035: backend-deployment.yaml has replicas, image, resources, envFrom ConfigMap + Secret
- [X] T036: backend-service.yaml has type: ClusterIP, port 8000
- [X] T037: Frontend deployment has livenessProbe (path: /, initialDelay: 10, period: 15) and readinessProbe (path: /, initialDelay: 5, period: 10) (FR-011, FR-012)
- [X] T038: Backend deployment has livenessProbe (path: /health, initialDelay: 10, period: 15) and readinessProbe (path: /health, initialDelay: 5, period: 10) (FR-011, FR-012)
- [X] T039: secret.yaml references todo-secrets secret (does NOT create secrets inline)
- [X] T040: NOTES.txt has post-install instructions

**Secrets and Configuration:**
- [X] T041: create-secrets.sh script shows kubectl create secret command with DATABASE_URL, JWT_SECRET, OPENAI_API_KEY
- [X] T042: quickstart.md has secrets creation section with step-by-step instructions

**Helm Deployment:**
- [X] T043: helm lint returns 0 errors
- [X] T044: helm template renders successfully without errors
- [X] T045: Secret created with kubectl (no values in Helm chart)
- [X] T046: Secret todo-secrets exists in todo-app namespace
- [X] T047: helm install returns deployed status
- [X] T048: kubectl get all shows deployments, services, configmap
- [X] T049: Backend pods reach Running state within 5 minutes (SC-004)
- [X] T050: Frontend pods reach Running state within 5 minutes (SC-004)
- [X] T051: ConfigMap has correct keys and values
- [X] T052: ConfigMap has NO sensitive data (FR-018, FR-019)
- [X] T053: Helm deployment time < 2 minutes (SC-003)
- [X] T054: minikube service list shows frontend-service with NodePort
- [X] T055: Browser opens frontend service URL successfully (SC-005)

**Connectivity and Integration Testing:**
- [X] T056: Frontend pod can curl backend-service:8000/health
- [X] T057: Backend health returns HTTP 200 with {"status":"ok"}
- [X] T058: Task lifecycle works (create, list, update, complete, delete) via chatbot (SC-007)
- [X] T059: Backend logs show database queries and task persistence (FR-020, FR-021)
- [X] T060: All Phase III features work (auth, chat, MCP, task CRUD) (SC-008)
- [X] T061: kubectl logs capture stdout/stderr from both pods (FR-021)

### Polish Phase Validation

- [X] T062: quickstart.md has troubleshooting section for edge cases (cluster failures, image size, Helm errors, pod restart loops, service connection)
- [X] T063: quickstart.md has cleanup section (helm uninstall, namespace delete, minikube stop/delete)
- [X] T064: quickstart.md has resource monitoring section (kubectl top pods, metrics-server)
- [X] T065: values-dev.yaml exists with dev settings
- [X] T066: quickstart.md has SC-001 through SC-008 verification checklist with test commands
- [X] T067: quickstart.md has rolling update documentation (helm upgrade workflow)
- [X] T068: All FR-001 through FR-021 met (reviewed against spec.md)
- [X] T069: Any deviations documented in plan.md
- [X] T070: End-to-end quickstart.md validation passes from scratch

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Tasks follow strict checklist format: checkbox, ID, labels, file paths
- Functional requirements FR-001 through FR-021 all mapped to specific tasks
- Success criteria SC-001 through SC-008 all have validation checkpoints
- Edge cases (cluster failures, image size issues, Helm errors, pod restart loops, service connection failures) covered in troubleshooting tasks
- Security constraints enforced (no secrets in values.yaml, secrets created via kubectl)
- Resource constraints enforced (requests/limits for all pods, probe configurations)
- Image size constraints enforced (multi-stage builds, .dockerignore, verification tasks)
- Docker and Helm best practices followed (multi-stage builds, non-root users, health probes, service discovery)
- Documentation-first approach (quickstart.md updated incrementally, NOTES.txt for post-install instructions)

---

## Task Summary

- **Total Tasks**: 70
- **Tasks per Phase**:
  - Setup (Phase 1): 4 tasks
  - Foundational (Phase 2): 7 tasks
  - User Story 1 (Phase 3): 8 tasks
  - User Story 2 (Phase 4): 11 tasks
  - User Story 3 (Phase 5): 31 tasks
  - Polish (Phase 6): 9 tasks
- **Tasks per User Story**:
  - User Story 1 (Minikube Cluster): 8 tasks
  - User Story 2 (Docker Images): 11 tasks
  - User Story 3 (Helm Deployment): 31 tasks
- **Parallel Opportunities**: 9+ parallel execution groups identified
- **Independent Test Criteria**: Each user story has clear independent test criteria
- **Suggested MVP Scope**: User Story 1 (Minikube infrastructure only) for initial validation, then complete US2+US3 for full deployment
- **Format Validation**: ✅ ALL tasks follow checkbox + ID + [P?] + [Story?] + description + file path format
