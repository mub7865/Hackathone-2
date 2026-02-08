# Implementation Plan: Cloud-Native Event-Driven Todo Application

**Branch**: `008-cloud-event-driven-phase5` | **Date**: 2026-01-10 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-cloud-event-driven-phase5/spec.md`

**Note**: This plan addresses Phase V of the Hackathon II project, transforming the local Kubernetes deployment (Phase IV) into a production-ready cloud-native system with event-driven architecture, advanced features, and full observability.

## Summary

Phase 5 deploys the todo application to DigitalOcean Kubernetes (DOKS) with event-driven architecture using Redpanda Cloud Serverless (Kafka-compatible) and Dapr. The system implements 4 new microservices (Recurring Task Service, Notification Service, Audit Service, WebSocket Service) that consume events from 3 Kafka topics (task-events, reminders, task-updates). Advanced features include recurring tasks with automatic rescheduling, due dates with email/in-app notifications, and intermediate features (priorities, tags, search, filter, sort). The deployment uses free tier resources (DigitalOcean $200 credit, Redpanda free tier, Neon Postgres free tier) with a 2-node cluster targeting 100-200 concurrent users. CI/CD pipeline via GitHub Actions enables zero-downtime deployments with automated testing and security scanning. Monitoring stack (Prometheus + Grafana) provides real-time observability.

## Technical Context

**Language/Version**: Python 3.13+ (backend microservices), TypeScript/Next.js 16+ (frontend)
**Primary Dependencies**:
- Backend: FastAPI 0.115+, SQLModel 0.0.22+, Dapr Python SDK, aiokafka, SendGrid Python SDK
- Frontend: Next.js 16 (App Router), React 18+, WebSocket client, Tailwind CSS
**Storage**: Neon Postgres (free tier) for all persistent state, Redpanda Cloud Serverless (free tier) for event streaming
**Testing**: pytest (backend unit/integration), Jest (frontend unit), Playwright (E2E)
**Target Platform**: DigitalOcean Kubernetes (DOKS) 2-node cluster, Linux containers (Docker)
**Project Type**: Distributed microservices (web application with event-driven backend)
**Performance Goals**:
- 100-200 concurrent users with <2s response time (95th percentile)
- Event publishing <100ms, event processing <500ms
- Notification delivery within 1 minute of trigger
- Zero-downtime deployments
**Constraints**:
- Free tier only (DigitalOcean $200 credit for 60 days, Redpanda free tier, Neon free tier)
- 2-node cluster (not 3-node for cost optimization)
- Email + in-app notifications only (no SMS/push due to cost)
- All services must be stateless
- Must preserve Phase IV functionality and API contracts
**Scale/Scope**:
- 4 new microservices + 2 modified existing services
- 3 Kafka topics with defined event schemas
- 5 Dapr building blocks configured
- 4 new database tables + extensions to existing tasks table
- CI/CD pipeline with 5 stages (test, scan, build, deploy, monitor)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ Strict Spec-Driven Development (SDD)
- Specification complete in `specs/008-cloud-event-driven-phase5/spec.md`
- Clarifications documented in spec (5 Q&A pairs)
- All requirements testable with acceptance criteria
- Implementation will follow approved spec

### ✅ AI-Native Architecture
- OpenAI Agents SDK with MCP tools (existing from Phase III)
- AIOps tools usage planned: Gordon (Docker), kubectl-ai (K8s), kagent (cluster management)
- Dapr abstracts infrastructure complexity
- Event-driven architecture enables AI-powered automation

### ✅ Progressive Evolution
- Builds on Phase IV (local Kubernetes deployment)
- Preserves all existing functionality and API contracts
- Adds event-driven layer without breaking changes
- Stateless architecture from Phase III maintained

### ✅ Documentation First
- Specification created before implementation
- This plan documents architecture before coding
- research.md will document technology decisions
- data-model.md will document schema changes
- contracts/ will document event schemas and APIs

### ✅ Stateless Architecture (Phase III+)
- All microservices are stateless
- State persisted to Neon Postgres
- Chat endpoint remains stateless (existing from Phase III)
- MCP tools remain stateless (existing from Phase III)
- Enables horizontal scaling with HPA

### ✅ Event-Driven Architecture (Phase V)
- 3 Kafka topics: task-events, reminders, task-updates
- Services communicate via events (loose coupling)
- Dapr Pub/Sub abstracts Kafka complexity
- Event schemas versioned for backward compatibility
- Idempotency handled via event IDs

### ✅ Feature Level Progression
- Basic Level (Phases I-III): Already implemented ✅
- Intermediate Level (Phase V): Priorities, Tags, Search, Filter, Sort - **TO IMPLEMENT**
- Advanced Level (Phase V): Recurring Tasks, Due Dates & Reminders - **TO IMPLEMENT**

### ✅ Tech Stack Adherence (Phase V)
- Event Streaming: Redpanda Cloud Serverless (Kafka-compatible) ✅
- Distributed Runtime: Dapr (all 5 building blocks) ✅
- Cloud Platform: DigitalOcean Kubernetes (DOKS) ✅
- CI/CD: GitHub Actions ✅
- Monitoring: Prometheus + Grafana ✅

### ✅ AIOps Tools Requirements
- Gordon: Docker image optimization and troubleshooting
- kubectl-ai: Kubernetes manifest generation and deployment
- kagent: Cluster health analysis and resource optimization

### ✅ MCP Tools Requirements (Phase III)
- All 5 MCP tools implemented in Phase III ✅
- Will be modified to publish events to Kafka
- Remain stateless with database persistence

### ✅ Dapr Building Blocks (Phase V)
- Pub/Sub (pubsub.kafka): Event streaming abstraction ✅
- State Management (state.postgresql): Conversation state ✅
- Service Invocation: Inter-service communication ✅
- Bindings (bindings.cron): Scheduled reminder checks ✅
- Secrets Management (secretstores.kubernetes): Secure credentials ✅

### ✅ Code Quality Standards
- Type hints (Python), TypeScript (frontend)
- Clean architecture with separation of concerns
- Comprehensive error handling with proper HTTP status codes
- All critical paths testable
- Inline comments for complex logic

### ✅ Deployment Standards
- Multi-stage Dockerfiles with non-root users
- Kubernetes manifests with resource limits, health probes, HPA
- Helm charts for parameterized deployments (existing from Phase IV)
- CI/CD with automated testing and security scanning
- Prometheus metrics and Grafana dashboards

### ✅ Security Requirements
- Better Auth with JWT (existing from Phase II)
- User isolation (users access only their own data)
- JWT validation on all protected endpoints
- Dapr secrets management (no secrets in code)
- Parameterized queries via SQLModel
- Container security scanning (Trivy)

### ⚠️ Bonus Features
- Reusable Intelligence: 7 subagents + 7 skills created ✅ (+200 points)
- Cloud-Native Blueprints: Skills with deployment patterns ✅ (+200 points)
- Multi-language Support: Not implemented (optional)
- Voice Commands: Not implemented (optional)

**GATE STATUS**: ✅ PASS - All required principles satisfied, bonus features partially implemented

## Project Structure

### Documentation (this feature)

```text
specs/008-cloud-event-driven-phase5/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file (/sp.plan output)
├── research.md          # Phase 0 output (technology decisions)
├── data-model.md        # Phase 1 output (database schema)
├── quickstart.md        # Phase 1 output (setup guide)
├── contracts/           # Phase 1 output (event schemas, APIs)
│   ├── events/
│   │   ├── task-event.schema.json
│   │   ├── reminder-event.schema.json
│   │   └── task-update-event.schema.json
│   └── apis/
│       ├── recurring-task-service.yaml
│       ├── notification-service.yaml
│       ├── audit-service.yaml
│       └── websocket-service.yaml
├── checklists/
│   └── requirements.md  # Specification quality checklist (complete)
└── tasks.md             # Phase 2 output (/sp.tasks - NOT created by /sp.plan)
```

### Source Code (repository root)

```text
# Phase V Implementation Directory
calm-orbit-todo/
├── phase1-console/              # Phase I: Console App ✅
├── phase2-3-fullstack/          # Phase II-III: Full-Stack + AI Chatbot ✅
├── phase4-k8s-deployment/       # Phase IV: Kubernetes Deployment ✅
└── phase5-cloud/                # Phase V: Cloud-Native Event-Driven 🚧
    ├── README.md                # ⭐ Beginners guide (setup, architecture, troubleshooting)
    │
    ├── backend/                 # Modified backend from Phase II-III
    │   ├── app/
    │   │   ├── api/
    │   │   │   └── v1/
    │   │   │       ├── chat.py          # MODIFY: Add event publishing
    │   │   │       └── tasks.py         # MODIFY: Add priority, tags, search, filter, sort
    │   │   ├── core/
    │   │   │   ├── auth.py              # Existing JWT validation
    │   │   │   └── config.py            # ADD: Dapr, Kafka config
    │   │   ├── models/
    │   │   │   ├── task.py              # MODIFY: Add priority, tags, due_date, remind_at, recurring_pattern_id
    │   │   │   ├── conversation.py      # Existing
    │   │   │   └── message.py           # Existing
    │   │   ├── mcp_tools/
    │   │   │   └── task_tools.py        # MODIFY: Add event publishing after DB operations
    │   │   └── main.py                  # MODIFY: Add Dapr sidecar integration
    │   ├── alembic/
    │   │   └── versions/
    │   │       └── 005_phase5_schema.py # NEW: Migration for Phase V schema changes
    │   ├── Dockerfile                   # MODIFY: Add Dapr SDK dependencies
    │   └── requirements.txt             # ADD: aiokafka, dapr, sendgrid
    │
    ├── frontend/                # Modified frontend from Phase II-III
    │   ├── app/
    │   │   ├── (authenticated)/
    │   │   │   ├── tasks/
    │   │   │   │   └── page.tsx         # MODIFY: Add priority, tags, search, filter, sort UI
    │   │   │   └── chatbot/
    │   │   │       └── page.tsx         # MODIFY: Add WebSocket connection
    │   │   └── api/
    │   │       └── ws/
    │   │           └── route.ts         # NEW: WebSocket endpoint proxy
    │   ├── components/
    │   │   ├── tasks/
    │   │   │   ├── TaskList.tsx         # MODIFY: Add priority indicators, tag badges
    │   │   │   ├── TaskForm.tsx         # MODIFY: Add priority, tags, due date, reminder, recurring fields
    │   │   │   ├── SearchBar.tsx        # NEW: Real-time search with 300ms debounce
    │   │   │   ├── FilterControls.tsx   # NEW: Status, priority, tags, date range filters
    │   │   │   └── SortControls.tsx     # NEW: Sort by due date, priority, creation date
    │   │   └── notifications/
    │   │       └── NotificationPreferences.tsx  # NEW: Channel, quiet hours, frequency settings
    │   ├── lib/
    │   │   └── websocket.ts             # NEW: WebSocket client with reconnection logic
    │   ├── Dockerfile                   # Existing from Phase IV
    │   └── package.json                 # ADD: WebSocket client library
    │
    ├── services/                # NEW: 4 Microservices for Phase V
    │   ├── recurring-task-service/
    │   │   ├── app/
    │   │   │   ├── main.py              # FastAPI app with Dapr Pub/Sub consumer
    │   │   │   ├── consumer.py          # Consumes task-completed events
    │   │   │   ├── recurrence.py        # Recurrence pattern logic (daily, weekly, monthly, cron)
    │   │   │   └── models.py            # RecurringPattern model
    │   │   ├── Dockerfile
    │   │   └── requirements.txt
    │   │
    │   ├── notification-service/
    │   │   ├── app/
    │   │   │   ├── main.py              # FastAPI app with Dapr Pub/Sub consumer
    │   │   │   ├── consumer.py          # Consumes reminder events
    │   │   │   ├── email_sender.py      # SendGrid integration
    │   │   │   ├── inapp_sender.py      # In-app notification via WebSocket
    │   │   │   └── models.py            # NotificationPreference model
    │   │   ├── Dockerfile
    │   │   └── requirements.txt
    │   │
    │   ├── audit-service/
    │   │   ├── app/
    │   │   │   ├── main.py              # FastAPI app with Dapr Pub/Sub consumer
    │   │   │   ├── consumer.py          # Consumes all task-events
    │   │   │   └── models.py            # AuditLog model
    │   │   ├── Dockerfile
    │   │   └── requirements.txt
    │   │
    │   └── websocket-service/
    │       ├── app/
    │       │   ├── main.py              # FastAPI WebSocket server with Dapr Pub/Sub consumer
    │       │   ├── consumer.py          # Consumes task-update events
    │       │   ├── connection_manager.py # Manages WebSocket connections
    │       │   └── models.py            # Connection state
    │       ├── Dockerfile
    │       └── requirements.txt
    │
    ├── k8s/                     # Kubernetes & Dapr Configuration
    │   ├── base/
    │   │   ├── namespace.yaml
    │   │   ├── backend-deployment.yaml      # MODIFY: Add Dapr annotations
    │   │   ├── frontend-deployment.yaml     # Existing
    │   │   ├── recurring-task-deployment.yaml   # NEW
    │   │   ├── notification-deployment.yaml     # NEW
    │   │   ├── audit-deployment.yaml            # NEW
    │   │   ├── websocket-deployment.yaml        # NEW
    │   │   ├── services.yaml                # MODIFY: Add new services
    │   │   ├── ingress.yaml                 # MODIFY: Add WebSocket route
    │   │   ├── hpa.yaml                     # MODIFY: Add HPA for new services
    │   │   └── configmaps.yaml              # MODIFY: Add Dapr, Kafka config
    │   │
    │   ├── dapr/
    │   │   ├── pubsub-kafka.yaml           # NEW: Dapr Pub/Sub component
    │   │   ├── state-postgresql.yaml       # NEW: Dapr State component
    │   │   ├── bindings-cron.yaml          # NEW: Dapr Bindings component
    │   │   └── secrets-kubernetes.yaml     # NEW: Dapr Secrets component
    │   │
    │   └── monitoring/
    │       ├── prometheus-config.yaml      # NEW: Scrape configs for all services
    │       ├── prometheus-deployment.yaml  # NEW
    │       ├── grafana-deployment.yaml     # NEW
    │       └── grafana-dashboards.yaml     # NEW: Pre-configured dashboards
    │
    ├── .github/                 # CI/CD Workflows
    │   └── workflows/
    │       ├── backend-ci.yaml             # MODIFY: Add new services
    │       ├── frontend-ci.yaml            # Existing
    │       ├── deploy-doks.yaml            # NEW: Deploy to DigitalOcean K8s
    │       └── security-scan.yaml          # NEW: Trivy + Snyk scanning
    │
    ├── charts/                  # Helm Charts (updated from Phase IV)
    │   └── todo-chatbot/
    │       ├── Chart.yaml                  # MODIFY: Version bump, add new services
    │       ├── values.yaml                 # MODIFY: Add Dapr, Kafka, new services config
    │       └── templates/
    │           ├── backend.yaml            # MODIFY: Add Dapr annotations
    │           ├── recurring-task.yaml     # NEW
    │           ├── notification.yaml       # NEW
    │           ├── audit.yaml              # NEW
    │           ├── websocket.yaml          # NEW
    │           ├── dapr-components.yaml    # NEW
    │           └── monitoring.yaml         # NEW
    │
    ├── docs/                    # Additional Documentation
    │   ├── DEPLOYMENT.md        # Cloud deployment guide
    │   ├── ARCHITECTURE.md      # System architecture diagrams
    │   └── TROUBLESHOOTING.md   # Common issues and solutions
    │
    ├── docker-compose.yml       # Local testing with Kafka
    └── .env.example             # Environment variables template
```

**Structure Decision**: Distributed microservices architecture with existing monorepo structure extended to include 4 new services in `services/` directory. Kubernetes manifests organized by concern (base, dapr, monitoring). Helm charts updated to support multi-service deployment with Dapr sidecars. CI/CD workflows extended for new services and cloud deployment.

## Complexity Tracking

> **No violations requiring justification**

All architecture decisions align with constitution requirements:
- Event-driven architecture mandated by Phase V requirements
- 4 new microservices necessary for separation of concerns (recurring tasks, notifications, audit, WebSocket)
- Dapr required by Phase V specification (all 5 building blocks)
- Free tier constraints drive 2-node cluster and notification channel decisions
- Stateless architecture maintained across all services

**Complexity is justified by Phase V requirements and hackathon scoring criteria (300 points).**

---

## Phase 0: Research & Technology Decisions

See [research.md](./research.md) for detailed technology decisions, rationale, and alternatives considered.

## Phase 1: Design & Contracts

See [data-model.md](./data-model.md) for database schema design and migrations.
See [contracts/](./contracts/) for event schemas and API specifications.
See [quickstart.md](./quickstart.md) for setup and deployment guide.

## Implementation Phases

### Phase 0: Foundation (P1 - Week 1)
1. Database schema migration (add priority, tags, due_date, remind_at, recurring_pattern_id to tasks)
2. Create new tables (recurring_patterns, audit_log, notification_preferences, saved_filters)
3. Set up Redpanda Cloud Serverless account and create 3 topics
4. Set up DigitalOcean account and provision 2-node DOKS cluster
5. Install Dapr on DOKS cluster
6. Configure Dapr components (Pub/Sub, State, Bindings, Secrets)

### Phase 1: Event Infrastructure (P1 - Week 1-2)
1. Modify Chat API MCP tools to publish events to task-events topic
2. Implement Audit Service (consumes task-events, logs to audit_log)
3. Deploy Audit Service to DOKS with Dapr sidecar
4. Verify event flow: Chat API → Kafka → Audit Service → Database

### Phase 2: Advanced Features (P2 - Week 2-3)
1. Implement Recurring Task Service (consumes task-completed events)
2. Add recurring task UI (frequency, end condition)
3. Implement Notification Service (consumes reminder events)
4. Add due date and reminder UI
5. Configure SendGrid for email notifications
6. Deploy Recurring Task Service and Notification Service to DOKS

### Phase 3: Real-Time Updates (P2 - Week 3)
1. Implement WebSocket Service (consumes task-update events)
2. Add WebSocket client to frontend
3. Handle connection loss and reconnection
4. Deploy WebSocket Service to DOKS

### Phase 4: Intermediate Features (P3 - Week 3-4)
1. Add priority field to tasks (High/Medium/Low)
2. Add tags field to tasks (array of strings)
3. Implement search with real-time results (300ms debounce)
4. Implement filter controls (status, priority, tags, date range)
5. Implement sort controls (due date, priority, creation date, alphabetically)
6. Add notification preferences UI

### Phase 5: Monitoring & Observability (P1 - Week 4)
1. Deploy Prometheus to DOKS cluster
2. Deploy Grafana to DOKS cluster
3. Configure Prometheus scrape configs for all services
4. Create Grafana dashboards (system health, business metrics)
5. Set up alerts (error rate, latency, service unavailable)

### Phase 6: CI/CD Pipeline (P1 - Week 4-5)
1. Create GitHub Actions workflow for automated testing
2. Add security scanning (Trivy for containers, Snyk for dependencies)
3. Add Docker image build and push to DigitalOcean Container Registry
4. Add deployment to DOKS with rolling updates
5. Add rollback capability
6. Add deployment notifications

### Phase 7: Testing & Validation (Week 5)
1. Unit tests for all new services
2. Integration tests for event flow
3. End-to-end tests for user scenarios
4. Load testing (100-200 concurrent users)
5. Failover testing (kill pods, verify recovery)
6. Security testing (JWT validation, input sanitization)

### Phase 8: Documentation & Demo (Week 5)
1. Update README with Phase V setup instructions
2. Document Dapr component configurations
3. Document event schemas
4. Create demo video (max 90 seconds)
5. Prepare presentation materials

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Free tier limits exceeded | High | Monitor usage daily; implement rate limiting; scale down non-essential services |
| Event ordering issues | High | Use partition keys (task_id) for ordering; implement idempotency checks |
| WebSocket connection drops | Medium | Implement automatic reconnection with exponential backoff; sync missed updates |
| Notification delivery failures | Medium | Retry logic (3 attempts); dead letter queue; manual review after failures |
| Database connection pool exhaustion | High | Configure connection limits; implement connection pooling; monitor active connections |
| Dapr sidecar overhead | Medium | Monitor resource usage; optimize sidecar configuration; use HPA for scaling |
| CI/CD pipeline failures | Medium | Implement rollback automation; maintain previous version; feature flags for instant rollback |
| Monitoring stack resource consumption | Medium | Set resource limits for Prometheus/Grafana; use sampling for high-cardinality metrics |

## Success Metrics

- ✅ All 5 Dapr building blocks operational
- ✅ All 3 Kafka topics processing events
- ✅ 100-200 concurrent users with <2s response time (95th percentile)
- ✅ Event publishing <100ms, processing <500ms
- ✅ Notification delivery within 1 minute
- ✅ Zero-downtime deployments
- ✅ 99.9% uptime over 30-day period
- ✅ CI/CD pipeline completes in <15 minutes
- ✅ All user stories validated with acceptance tests
- ✅ Monitoring dashboards operational with <30s delay
- ✅ Rollback completes within 2 minutes

**Total Points**: 300 (Phase V) + 200 (Reusable Intelligence) + 200 (Cloud-Native Blueprints) = **700 points**
