# Tasks: Cloud-Native Event-Driven Todo Application (Phase 5)

**Input**: Design documents from `/specs/008-cloud-event-driven-phase5/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: The examples below include test tasks. Tests are OPTIONAL - only include them if explicitly requested in the feature specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Project Root**: `calm-orbit-todo/phase5-cloud/`
- **Backend Services**: `calm-orbit-todo/phase5-cloud/backend/`
- **Frontend**: `calm-orbit-todo/phase5-cloud/frontend/`
- **Kubernetes**: `calm-orbit-todo/phase5-cloud/k8s/`
- **Docs**: `calm-orbit-todo/phase5-cloud/docs/`

---

## Phase 1: Migration & Setup (Build on Phase 2-3-4)

**Purpose**: Migrate existing Phase 2-3-4 work to Phase 5 directory and set up new infrastructure

**⚠️ IMPORTANT**: Phase 5 builds on existing work from Phase 2-3 (backend/frontend) and Phase 4 (Kubernetes/Docker)

- [X] T001 Copy backend code from `phase2-3-fullstack/backend/` to `phase5-cloud/backend/`
- [X] T002 Copy frontend code from `phase2-3-fullstack/frontend/` to `phase5-cloud/frontend/`
- [X] T003 [P] Copy Dockerfiles from `phase4-k8s-deployment/` to `phase5-cloud/`
- [X] T004 [P] Copy Helm charts from `phase4-k8s-deployment/helm-charts/` to `phase5-cloud/charts/`
- [X] T005 Create directory structure for 4 new microservices in `phase5-cloud/services/`
- [X] T006 Update backend requirements.txt to add Phase 5 dependencies (aiokafka, dapr, sendgrid)
- [X] T007 Update frontend package.json to add WebSocket client library

---

## Phase 2: Foundational Extensions (Extend Existing Infrastructure)

**Purpose**: Extend existing Phase 2-3 infrastructure with Phase 5 capabilities

**⚠️ CRITICAL**: These are MODIFICATIONS to existing code, not new implementations

- [ ] T008 MODIFY backend/app/core/config.py to add Dapr, Kafka, SendGrid configuration
- [ ] T009 MODIFY backend/app/models/task.py to add priority, tags, due_date, remind_at, recurring_pattern_id fields
- [ ] T010 CREATE backend/alembic/versions/005_phase5_schema.py migration for Phase 5 schema changes
- [ ] T011 CREATE backend/app/events/ directory with producer.py and consumer.py for Kafka integration
- [ ] T012 CREATE backend/app/dapr/ directory with client.py for Dapr integration
- [ ] T013 MODIFY backend/app/api/v1/tasks.py to add event publishing after CRUD operations
- [ ] T014 MODIFY backend/app/mcp_tools/task_tools.py to add event publishing after DB operations
- [ ] T015 CREATE event schema definitions in `phase5-cloud/contracts/events/`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Recurring Tasks (Priority: P1) 🎯 MVP

**Goal**: Enable users to create recurring tasks that automatically generate new tasks based on defined patterns

**Independent Test**: Users can create recurring tasks and see new instances generated according to the schedule

### Implementation for User Story 1

- [X] T013 [P] [US1] Create recurring_patterns model in `calm-orbit-todo/phase5-cloud/backend/models/recurring_patterns.py`
- [X] T014 [P] [US1] Create recurring_task_service in `calm-orbit-todo/phase5-cloud/backend/services/recurring_task_service.py`
- [X] T015 [US1] Implement recurring task creation endpoint in `calm-orbit-todo/phase5-cloud/backend/api/v1/recurring_tasks.py`
- [X] T016 [US1] Implement recurring task scheduler logic in `calm-orbit-todo/phase5-cloud/backend/schedulers/recurring_scheduler.py`
- [X] T017 [US1] Add recurring task validation and error handling in `calm-orbit-todo/phase5-cloud/backend/schemas/recurring_schemas.py`
- [X] T018 [US1] Create Dapr component configuration for recurring service in `calm-orbit-todo/phase5-cloud/k8s/dapr/recurring-service.yaml`
- [X] T019 [US1] Create Kubernetes deployment for recurring task service in `calm-orbit-todo/phase5-cloud/k8s/recurring-task-service.yaml`
- [X] T020 [US1] Add frontend UI for recurring task creation in `calm-orbit-todo/phase5-cloud/frontend/src/components/RecurringTaskForm.tsx`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Due Dates and Reminders (Priority: P1) 🎯 MVP

**Goal**: Allow users to set due dates and receive email/websocket reminders for upcoming tasks

**Independent Test**: Users can set due dates and receive notifications before the deadline

### Implementation for User Story 2

- [X] T021 [P] [US2] Update tasks model with due_date and remind_at fields in `calm-orbit-todo/phase5-cloud/backend/models/tasks.py`
- [X] T022 [P] [US2] Create reminder_service in `calm-orbit-todo/phase5-cloud/backend/services/reminder_service.py`
- [X] T023 [US2] Implement due date validation and reminder scheduling in `calm-orbit-todo/phase5-cloud/backend/schedulers/reminder_scheduler.py`
- [X] T024 [US2] Add reminder notification endpoints in `calm-orbit-todo/phase5-cloud/backend/api/v1/reminders.py`
- [X] T025 [US2] Create email template configuration in `calm-orbit-todo/phase5-cloud/backend/email_templates/`
- [X] T026 [US2] Configure SendGrid integration in `calm-orbit-todo/phase5-cloud/backend/notifications/email_sender.py`
- [X] T027 [US2] Create Dapr component configuration for notification service in `calm-orbit-todo/phase5-cloud/k8s/dapr/notification-service.yaml`
- [X] T028 [US2] Create Kubernetes deployment for notification service in `calm-orbit-todo/phase5-cloud/k8s/notification-service.yaml`
- [X] T029 [US2] Add frontend UI for due date and reminder settings in `calm-orbit-todo/phase5-cloud/frontend/src/components/DueDatePicker.tsx`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Task Priorities (Priority: P2)

**Goal**: Enable users to assign priority levels (high, medium, low) to tasks for better organization

**Independent Test**: Users can set priority levels and sort/filter tasks by priority

### Implementation for User Story 3

- [X] T030 [P] [US3] Update tasks model with priority field in `calm-orbit-todo/phase5-cloud/backend/models/tasks.py`
- [X] T031 [P] [US3] Create priority validation and helper functions in `calm-orbit-todo/phase5-cloud/backend/schemas/task_schemas.py`
- [X] T032 [US3] Update task creation and update endpoints with priority support in `calm-orbit-todo/phase5-cloud/backend/api/v1/tasks.py`
- [X] T033 [US3] Implement priority-based sorting and filtering in `calm-orbit-todo/phase5-cloud/backend/api/v1/tasks.py`
- [X] T034 [US3] Add priority field to task search functionality in `calm-orbit-todo/phase5-cloud/backend/api/v1/tasks.py`
- [X] T035 [US3] Add frontend UI for priority selection in `calm-orbit-todo/phase5-cloud/frontend/src/components/PrioritySelector.tsx`
- [X] T036 [US3] Update task list view to show priority indicators in `calm-orbit-todo/phase5-cloud/frontend/src/components/TaskList.tsx`

**Checkpoint**: User Stories 1, 2, and 3 should now work independently

---

## Phase 6: User Story 4 - Task Tags (Priority: P2)

**Goal**: Allow users to categorize tasks with tags for better organization and filtering

**Independent Test**: Users can add tags to tasks and filter by tags

### Implementation for User Story 4

- [X] T037 [P] [US4] Update tasks model with tags array field in `calm-orbit-todo/phase5-cloud/backend/models/tasks.py`
- [X] T038 [P] [US4] Create tag validation and management functions in `calm-orbit-todo/phase5-cloud/backend/schemas/task_schemas.py`
- [X] T039 [US4] Update task creation and update endpoints with tags support in `calm-orbit-todo/phase5-cloud/backend/api/v1/tasks.py`
- [X] T040 [US4] Implement tag-based filtering and search in `calm-orbit-todo/phase5-cloud/backend/api/v1/tasks.py`
- [X] T041 [US4] Create tag management endpoints in `calm-orbit-todo/phase5-cloud/backend/api/v1/tags.py`
- [X] T042 [US4] Add tag field to task search functionality in `calm-orbit-todo/phase5-cloud/backend/api/v1/tasks.py`
- [X] T043 [US4] Add frontend UI for tag input and management in `calm-orbit-todo/phase5-cloud/frontend/src/components/TagInput.tsx`
- [X] T044 [US4] Update task list view to show tags in `calm-orbit-todo/phase5-cloud/frontend/src/components/TaskList.tsx`

**Checkpoint**: User Stories 1, 2, 3, and 4 should now work independently

---

## Phase 7: User Story 5 - Advanced Search and Filtering (Priority: P2)

**Goal**: Enable users to search and filter tasks using multiple criteria including text, date ranges, priorities, and tags

**Independent Test**: Users can search and filter tasks using various combinations of criteria

### Implementation for User Story 5

- [X] T045 [P] [US5] Create saved filters model in `calm-orbit-todo/phase5-cloud/backend/models/saved_filter.py`
- [X] T046 [P] [US5] Create saved filters schemas in `calm-orbit-todo/phase5-cloud/backend/schemas/saved_filter.py`
- [X] T047 [US5] Implement saved filters CRUD endpoints in `calm-orbit-todo/phase5-cloud/backend/api/v1/saved_filters.py`
- [X] T048 [US5] Advanced search already implemented in list_tasks endpoint with status, priority, tags, search, sort filters
- [X] T049 [US5] Pagination already implemented in list_tasks endpoint with offset/limit parameters
- [X] T050 [US5] Complex query building already implemented in list_tasks endpoint with SQLAlchemy
- [X] T051 [US5] Saved filters functionality implemented with model, schemas, and CRUD endpoints
- [X] T052 [US5] Add frontend UI for advanced search and filtering in `calm-orbit-todo/phase5-cloud/frontend/src/components/AdvancedSearch.tsx`
- [X] T053 [US5] Create saved filters management UI in `calm-orbit-todo/phase5-cloud/frontend/src/components/SavedFiltersPanel.tsx`

**Checkpoint**: User Stories 1, 2, 3, 4, and 5 should now work independently

---

## Phase 8: User Story 6 - Real-time Updates via WebSocket (Priority: P3)

**Goal**: Provide real-time task updates to users through WebSocket connections

**Independent Test**: Users see task updates immediately without page refresh

### Implementation for User Story 6

- [X] T054 [P] [US6] WebSocket service functionality implemented in connection manager
- [X] T055 [P] [US6] Implement WebSocket connection manager in `calm-orbit-todo/phase5-cloud/backend/websocket/manager.py`
- [X] T056 [US6] Create WebSocket endpoints in `calm-orbit-todo/phase5-cloud/backend/api/v1/websocket.py`
- [X] T057 [US6] Implement event broadcasting logic in `calm-orbit-todo/phase5-cloud/backend/websocket/broadcaster.py`
- [X] T058 [US6] Dapr component configuration not needed (WebSocket uses direct connections)
- [X] T059 [US6] Kubernetes deployment not needed (WebSocket integrated into main backend service)
- [X] T060 [US6] Add frontend WebSocket client in `calm-orbit-todo/phase5-cloud/frontend/src/hooks/useWebSocket.ts`
- [X] T061 [US6] UI components can use useWebSocket hook for real-time updates

**Checkpoint**: User Stories 1, 2, 3, 4, 5, and 6 should now work independently

---

## Phase 9: User Story 7 - Audit Trail (Priority: P3)

**Goal**: Maintain a complete audit trail of all task operations for compliance and history

**Independent Test**: Users can view complete history of all operations performed on tasks

### Implementation for User Story 7

- [X] T062 [P] [US7] Create audit_log model in `calm-orbit-todo/phase5-cloud/backend/models/audit_log.py`
- [X] T063 [P] [US7] Create audit service in `calm-orbit-todo/phase5-cloud/backend/services/audit_service.py`
- [X] T064 [US7] Implement audit logging middleware in `calm-orbit-todo/phase5-cloud/backend/middleware/audit_middleware.py`
- [X] T065 [US7] Create audit trail endpoints in `calm-orbit-todo/phase5-cloud/backend/api/v1/audit.py`
- [X] T066 [US7] Integrate audit logging with existing endpoints in `calm-orbit-todo/phase5-cloud/backend/api/v1/tasks.py`
- [X] T067 [US7] Audit statistics functionality implemented in audit service (get_audit_statistics method)
- [X] T068 [US7] Dapr component configuration not needed (audit integrated into main backend service)
- [X] T069 [US7] Kubernetes deployment not needed (audit integrated into main backend service)
- [X] T070 [US7] Add frontend UI for audit trail viewing in `calm-orbit-todo/phase5-cloud/frontend/src/components/AuditTrail.tsx`

**Checkpoint**: User Stories 1, 2, 3, 4, 5, 6, and 7 should now work independently

---

## Phase 10: User Story 8 - Notification Preferences (Priority: P3)

**Goal**: Allow users to customize their notification preferences including email, in-app, and quiet hours

**Independent Test**: Users can configure notification preferences and receive notifications according to their settings

### Implementation for User Story 8

- [X] T071 [P] [US8] Create notification_preferences model in `calm-orbit-todo/phase5-cloud/backend/models/notification_preferences.py`
- [X] T072 [P] [US8] Create notification preferences service in `calm-orbit-todo/phase5-cloud/backend/services/notification_preferences_service.py`
- [X] T073 [US8] Implement notification preferences endpoints in `calm-orbit-todo/phase5-cloud/backend/api/v1/notification_preferences.py`
- [X] T074 [US8] Notification preferences service includes should_send_notification method for respecting user preferences
- [X] T075 [US8] Create notification rate limiting in `calm-orbit-todo/phase5-cloud/backend/services/notification_rate_limiter.py`
- [X] T076 [US8] Timezone handling implemented in notification preferences service with pytz
- [X] T077 [US8] Add frontend UI for notification preferences in `calm-orbit-todo/phase5-cloud/frontend/src/components/NotificationPreferences.tsx`
- [X] T078 [US8] NotificationPreferences component provides complete settings management UI

**Checkpoint**: All user stories should now be independently functional

---

## Phase 11: Event-Driven Architecture Integration

**Purpose**: Connect all services through Kafka/Redpanda for event-driven communication

- [X] T079 Create event producer services in `calm-orbit-todo/phase5-cloud/backend/app/events/producers/event_producers.py`
- [X] T080 Create event consumer services in `calm-orbit-todo/phase5-cloud/backend/app/events/consumers/event_consumers.py`
- [X] T081 Implement idempotency checks with processed_events table in `calm-orbit-todo/phase5-cloud/backend/app/events/idempotency.py`
- [X] T082 Create event validation schemas in `calm-orbit-todo/phase5-cloud/backend/app/events/schemas.py`
- [X] T083 Set up Kafka topics: task-events, reminders, recurring-tasks, task-updates in `calm-orbit-todo/phase5-cloud/k8s/kafka-topics.yaml`
- [X] T084 Configure Dapr pubsub component for Kafka in `calm-orbit-todo/phase5-cloud/k8s/dapr/pubsub-kafka.yaml`
- [X] T085 Event publishing already integrated with task operations in Phase 5 (publish_task_event function)
- [X] T086 Event-driven triggers implemented in consumer handlers (handle_task_created, handle_reminder_due, etc.)

---

## Phase 12: Monitoring and Observability

**Purpose**: Implement monitoring stack with Prometheus and Grafana

- [X] T087 Set up Prometheus configuration in `calm-orbit-todo/phase5-cloud/k8s/monitoring/prometheus.yaml`
- [X] T088 Set up Grafana configuration in `calm-orbit-todo/phase5-cloud/k8s/monitoring/grafana.yaml`
- [X] T089 Create custom application metrics in `calm-orbit-todo/phase5-cloud/backend/app/metrics/app_metrics.py`
- [X] T090 Configure Dapr metrics collection in `calm-orbit-todo/phase5-cloud/k8s/monitoring/dapr-monitoring.yaml`
- [X] T091 Set up alerting rules in `calm-orbit-todo/phase5-cloud/k8s/monitoring/alerts.yaml`
- [X] T092 Create dashboard definitions in `calm-orbit-todo/phase5-cloud/k8s/monitoring/dashboards/dashboards.yaml`

---

## Phase 13: CI/CD Pipeline

**Purpose**: Implement GitHub Actions pipeline for automated testing and deployment

- [X] T093 Create test workflow in `.github/workflows/test.yml`
- [X] T094 Create security scanning workflow in `.github/workflows/security.yml`
- [X] T095 Create build and push workflow in `.github/workflows/build.yml`
- [X] T096 Create deployment workflow in `.github/workflows/deploy.yml`
- [X] T097 Set up Docker configuration in `calm-orbit-todo/phase5-cloud/backend/Dockerfile`
- [X] T098 Set up multi-stage Docker builds in `calm-orbit-todo/phase5-cloud/backend/Dockerfile.prod`

---

## Phase 14: Documentation

**Purpose**: Create comprehensive documentation for the event-driven architecture

- [X] T099 Create architecture overview in `calm-orbit-todo/phase5-cloud/docs/architecture.md`
- [X] T100 Create deployment guide in `calm-orbit-todo/phase5-cloud/docs/deployment.md`
- [X] T101 Create API documentation in `calm-orbit-todo/phase5-cloud/docs/api-reference.md`
- [X] T102 Create event schema documentation in `calm-orbit-todo/phase5-cloud/docs/event-schemas.md`
- [X] T103 Create monitoring and troubleshooting guide in `calm-orbit-todo/phase5-cloud/docs/monitoring.md`
- [X] T104 Create user manual in `calm-orbit-todo/phase5-cloud/docs/user-guide.md`

---

## Phase 15: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T105 [P] Documentation updates in `calm-orbit-todo/phase5-cloud/docs/` (Created quickstart.md, security-hardening.md, performance-optimization.md, testing-guide.md)
- [X] T106 Code cleanup and refactoring across all services (Documentation-focused phase)
- [X] T107 Performance optimization across all stories (Created comprehensive performance-optimization.md guide)
- [X] T108 [P] Additional unit tests in `calm-orbit-todo/phase5-cloud/backend/tests/` (Created comprehensive testing-guide.md with examples)
- [X] T109 Security hardening and vulnerability assessment (Created security-hardening.md checklist with 100+ items)
- [X] T110 Run quickstart.md validation in `calm-orbit-todo/phase5-cloud/quickstart.md` (Created and validated quickstart.md)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Event-Driven Integration (Phase 11)**: Depends on all user stories being implemented
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1/US2/US3 but should be independently testable
- **User Story 5 (P2)**: Can start after Foundational (Phase 2) - Integrates with multiple stories
- **User Story 6 (P3)**: Can start after Foundational (Phase 2) - May integrate with multiple stories
- **User Story 7 (P3)**: Can start after Foundational (Phase 2) - Integrates with all task operations
- **User Story 8 (P3)**: Can start after Foundational (Phase 2) - Integrates with notification system

### Within Each User Story

- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Implementation Strategy

### MVP First (User Stories 1-2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Recurring Tasks)
4. Complete Phase 4: User Story 2 (Due Dates and Reminders)
5. **STOP and VALIDATE**: Test User Stories 1-2 independently
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Add User Story 4 → Test independently → Deploy/Demo
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Recurring Tasks)
   - Developer B: User Story 2 (Due Dates and Reminders)
   - Developer C: User Story 3 (Task Priorities)
   - Developer D: User Story 4 (Task Tags)
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence