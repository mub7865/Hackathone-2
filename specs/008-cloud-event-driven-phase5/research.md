# Phase 0: Research & Technology Decisions

**Feature**: Cloud-Native Event-Driven Todo Application (Phase 5)
**Branch**: `008-cloud-event-driven-phase5`
**Date**: 2026-01-11

## Overview

This document captures all technology decisions, rationale, and alternatives considered for Phase 5 implementation. All decisions align with free tier constraints and hackathon requirements.

---

## 1. Cloud Platform Selection

### Decision: DigitalOcean Kubernetes (DOKS)

**Rationale**:
- **Free Tier**: $200 credit for new accounts (60-day validity) covers entire hackathon period
- **Managed Kubernetes**: Reduces operational overhead compared to self-managed clusters
- **Simple Pricing**: Predictable costs with no hidden charges
- **Good Documentation**: Comprehensive guides for Kubernetes deployment
- **Container Registry**: Integrated DigitalOcean Container Registry (DOCR)
- **Load Balancer**: Built-in LoadBalancer service support
- **Monitoring Integration**: Native support for Prometheus/Grafana

**Alternatives Considered**:
1. **AWS EKS**: More features but complex pricing; free tier insufficient for Kubernetes
2. **Google GKE**: Excellent Kubernetes support but $300 credit expires in 90 days; more expensive after free tier
3. **Azure AKS**: Good integration but complex setup; free tier limited
4. **Minikube (Local)**: Already implemented in Phase IV; not suitable for production demo

**Trade-offs**:
- ✅ Cost-effective for hackathon with $200 credit
- ✅ Simple setup and management
- ⚠️ Smaller ecosystem compared to AWS/GCP
- ⚠️ Limited to 2-node cluster for free tier budget

---

## 2. Event Streaming Platform

### Decision: Redpanda Cloud Serverless (Kafka-compatible)

**Rationale**:
- **Free Tier**: Generous free tier with sufficient throughput for demo (up to 10 MB/s ingress, 30 MB/s egress)
- **Kafka Compatibility**: Drop-in replacement for Kafka; uses standard Kafka protocol
- **Serverless**: No cluster management; automatic scaling
- **Low Latency**: 10x faster than Apache Kafka for p99 latency
- **Simple Setup**: No ZooKeeper dependency; easier configuration
- **Cost**: Free tier covers hackathon requirements; pay-as-you-go after

**Alternatives Considered**:
1. **Apache Kafka (Self-hosted)**: Full control but requires 3+ ZooKeeper nodes + 3+ Kafka brokers; exceeds free tier budget
2. **Confluent Cloud**: Excellent managed Kafka but free tier very limited (30-day trial only)
3. **AWS MSK**: Managed Kafka but no free tier; minimum cost ~$250/month
4. **RabbitMQ**: Good for messaging but not designed for event streaming; lacks log compaction
5. **Redis Streams**: Lightweight but limited durability and retention; not suitable for audit logs

**Trade-offs**:
- ✅ Zero operational overhead (serverless)
- ✅ Kafka-compatible (standard ecosystem)
- ✅ Excellent free tier for demo
- ⚠️ Newer platform (less mature than Kafka)
- ⚠️ Vendor lock-in to Redpanda

**Configuration**:
- 3 topics: `task-events`, `reminders`, `task-updates`
- Retention: 7 days (sufficient for demo)
- Partitions: 3 per topic (enables parallel processing)
- Replication: 3 (Redpanda default for durability)

---

## 3. Distributed Application Runtime

### Decision: Dapr (Distributed Application Runtime)

**Rationale**:
- **Hackathon Requirement**: Explicitly required by Phase V specification
- **Building Blocks**: Provides 5 required building blocks (Pub/Sub, State, Service Invocation, Bindings, Secrets)
- **Language Agnostic**: Works with Python (backend) and TypeScript (frontend)
- **Sidecar Pattern**: Non-invasive integration; no code changes to existing services
- **Abstraction**: Decouples application code from infrastructure (Kafka, Postgres, K8s secrets)
- **Observability**: Built-in metrics, tracing, and logging
- **Local Development**: Works with Docker Compose and Minikube

**Alternatives Considered**:
1. **Direct Integration**: Use Kafka client libraries directly; more control but tight coupling
2. **Service Mesh (Istio)**: More features but complex setup; overkill for hackathon
3. **Spring Cloud**: Java-specific; not suitable for Python backend

**Trade-offs**:
- ✅ Simplifies infrastructure integration
- ✅ Required by hackathon specification
- ✅ Excellent documentation and community
- ⚠️ Adds sidecar overhead (~50-100MB per pod)
- ⚠️ Learning curve for team

**Dapr Components Configuration**:
- **Pub/Sub**: `pubsub.kafka` → Redpanda Cloud Serverless
- **State Management**: `state.postgresql` → Neon Postgres
- **Service Invocation**: HTTP/gRPC between services
- **Bindings**: `bindings.cron` → Scheduled reminder checks
- **Secrets**: `secretstores.kubernetes` → K8s secrets

---

## 4. Database Strategy

### Decision: Neon Postgres (Existing from Phase III)

**Rationale**:
- **Already Configured**: Existing Neon Postgres from Phase III; no migration needed
- **Free Tier**: 0.5 GB storage, 1 compute unit; sufficient for demo
- **Serverless**: Auto-suspend after inactivity; cost-effective
- **Branching**: Database branching for testing (useful for CI/CD)
- **Connection Pooling**: Built-in PgBouncer
- **Backup**: Automated backups with point-in-time recovery

**Schema Strategy**:
- **Single Database**: All services share one Neon Postgres database
- **Schema Isolation**: Each service has its own schema (e.g., `tasks`, `audit`, `notifications`)
- **Shared Tables**: `tasks` table shared by Chat API and Recurring Task Service
- **Service-Specific Tables**: `audit_log`, `recurring_patterns`, `notification_preferences`

**Alternatives Considered**:
1. **Database per Service**: Better isolation but exceeds free tier (need 4+ databases)
2. **MongoDB**: NoSQL flexibility but team expertise in Postgres; migration overhead
3. **CockroachDB**: Distributed SQL but no free tier; overkill for demo

**Trade-offs**:
- ✅ No migration from existing setup
- ✅ Free tier sufficient for demo
- ✅ Team expertise in Postgres
- ⚠️ Single point of failure (mitigated by Neon's HA)
- ⚠️ Shared database requires careful schema management

---

## 5. Notification Delivery

### Decision: SendGrid (Email) + WebSocket (In-App)

**Rationale**:
- **SendGrid Free Tier**: 100 emails/day; sufficient for demo with 10-20 test users
- **Simple Integration**: Python SDK available; well-documented
- **Reliable Delivery**: 99%+ delivery rate; good reputation
- **WebSocket**: Real-time in-app notifications; no external service needed
- **Cost**: Both channels free for demo requirements

**Alternatives Considered**:
1. **Twilio (SMS)**: $15 credit but SMS costs $0.0075/message; limited to ~2000 messages; deferred to future phase
2. **Firebase Cloud Messaging (Push)**: Free but requires mobile app; out of scope for Phase V
3. **AWS SNS**: No free tier for SMS; complex setup
4. **Mailgun**: 5000 emails/month free but SendGrid more popular

**Trade-offs**:
- ✅ Email + in-app covers most use cases
- ✅ Free tier sufficient for demo
- ✅ Simple integration
- ⚠️ No SMS/push notifications (deferred to future phase)
- ⚠️ SendGrid free tier limited to 100 emails/day

**Configuration**:
- **Email Templates**: Plain text for demo; HTML templates for production
- **Rate Limiting**: Max 10 emails/user/day to stay within free tier
- **Retry Logic**: 3 attempts with exponential backoff
- **Dead Letter Queue**: Failed notifications logged for manual review

---

## 6. CI/CD Pipeline

### Decision: GitHub Actions

**Rationale**:
- **Free Tier**: 2000 minutes/month for public repos; unlimited for public repos
- **Native Integration**: Repository already on GitHub
- **Marketplace**: Pre-built actions for Docker, Kubernetes, security scanning
- **Secrets Management**: GitHub Secrets for API keys and credentials
- **Matrix Builds**: Parallel testing for multiple services

**Pipeline Stages**:
1. **Test**: Run pytest (backend), Jest (frontend), Playwright (E2E)
2. **Scan**: Trivy (container security), Snyk (dependency vulnerabilities)
3. **Build**: Docker multi-stage builds for all services
4. **Push**: Push images to DigitalOcean Container Registry
5. **Deploy**: kubectl apply with rolling updates
6. **Verify**: Health check endpoints, smoke tests

**Alternatives Considered**:
1. **GitLab CI**: Good features but repo on GitHub; migration overhead
2. **CircleCI**: 6000 minutes/month free but GitHub Actions more integrated
3. **Jenkins**: Self-hosted; requires infrastructure; operational overhead

**Trade-offs**:
- ✅ Free for public repos
- ✅ Native GitHub integration
- ✅ Large marketplace of actions
- ⚠️ YAML configuration can be verbose
- ⚠️ Limited to 2000 minutes/month for private repos

---

## 7. Monitoring Stack

### Decision: Prometheus + Grafana (Self-hosted on DOKS)

**Rationale**:
- **Open Source**: No licensing costs; community-driven
- **Kubernetes Native**: Designed for containerized environments
- **Dapr Integration**: Dapr exports Prometheus metrics by default
- **Grafana Dashboards**: Pre-built dashboards for Kubernetes and Dapr
- **Alerting**: Prometheus Alertmanager for threshold-based alerts
- **Cost**: Free; runs on existing DOKS cluster

**Metrics to Collect**:
- **System Metrics**: CPU, memory, disk, network per pod
- **Application Metrics**: Request rate, error rate, latency (p50, p95, p99)
- **Business Metrics**: Tasks created, tasks completed, events published, notifications sent
- **Dapr Metrics**: Sidecar latency, pub/sub throughput, state operations

**Alternatives Considered**:
1. **DigitalOcean Monitoring**: Basic metrics but limited customization; no alerting
2. **Datadog**: Excellent features but expensive ($15/host/month); no free tier
3. **New Relic**: Good APM but complex pricing; free tier very limited
4. **Grafana Cloud**: Managed Grafana but free tier limited (10k series, 14-day retention)

**Trade-offs**:
- ✅ Full control and customization
- ✅ No external costs
- ✅ Kubernetes-native
- ⚠️ Requires cluster resources (~500MB memory)
- ⚠️ Self-managed (no SLA)

**Configuration**:
- **Prometheus**: 7-day retention, 15s scrape interval
- **Grafana**: Pre-configured dashboards for system health and business metrics
- **Alertmanager**: Email alerts for critical issues

---

## 8. Security Scanning

### Decision: Trivy (Containers) + Snyk (Dependencies)

**Rationale**:
- **Trivy**: Open-source container scanner; detects CVEs in OS packages and application dependencies
- **Snyk**: Free tier for open-source projects; 200 tests/month
- **GitHub Integration**: Both integrate with GitHub Actions
- **Fast Scans**: Trivy scans in <30 seconds; Snyk in <1 minute
- **Actionable Results**: Clear remediation advice

**Alternatives Considered**:
1. **Clair**: Open-source but complex setup; requires PostgreSQL
2. **Anchore**: Good features but slow scans; complex configuration
3. **Aqua Security**: Commercial product; no free tier

**Trade-offs**:
- ✅ Free for open-source projects
- ✅ Fast and accurate scans
- ✅ Easy GitHub Actions integration
- ⚠️ Snyk free tier limited to 200 tests/month
- ⚠️ May have false positives

---

## 9. WebSocket Implementation

### Decision: FastAPI WebSocket + Connection Manager

**Rationale**:
- **Native Support**: FastAPI has built-in WebSocket support
- **Python Async**: Leverages asyncio for efficient connection handling
- **Simple Integration**: No external service needed
- **Dapr Consumer**: WebSocket service consumes `task-updates` topic
- **Reconnection Logic**: Client-side reconnection with exponential backoff

**Architecture**:
- **WebSocket Service**: Standalone FastAPI service with Dapr sidecar
- **Connection Manager**: In-memory dict mapping user_id → WebSocket connections
- **Event Consumer**: Dapr Pub/Sub consumer for `task-updates` topic
- **Broadcasting**: When event received, broadcast to all user's connections

**Alternatives Considered**:
1. **Socket.IO**: More features (rooms, namespaces) but adds complexity; requires socket.io client
2. **Server-Sent Events (SSE)**: Simpler than WebSocket but unidirectional; not suitable for future features
3. **Pusher/Ably**: Managed WebSocket services but cost $49+/month; no free tier

**Trade-offs**:
- ✅ No external service costs
- ✅ Native FastAPI support
- ✅ Full control over implementation
- ⚠️ Requires sticky sessions or Redis for multi-instance
- ⚠️ Connection state not persisted (reconnect on pod restart)

**Scaling Strategy**:
- **Phase 5 (Demo)**: Single WebSocket service instance; in-memory connection manager
- **Production**: Redis-backed connection manager; multiple instances with sticky sessions

---

## 10. Recurring Task Pattern Engine

### Decision: Custom Recurrence Logic + Cron Expression Support

**Rationale**:
- **Flexibility**: Support daily, weekly, monthly, yearly, and custom cron patterns
- **Simple Patterns**: Built-in logic for common patterns (daily, weekly, monthly)
- **Advanced Patterns**: Cron expressions for complex schedules (e.g., "every weekday at 9 AM")
- **Python Libraries**: Use `croniter` for cron expression parsing
- **Database Storage**: Store recurrence pattern as JSON in `recurring_patterns` table

**Pattern Types**:
1. **Daily**: Repeat every N days (e.g., every 1 day, every 3 days)
2. **Weekly**: Repeat on specific days (e.g., Monday, Wednesday, Friday)
3. **Monthly**: Repeat on specific date (e.g., 15th of every month) or last day
4. **Yearly**: Repeat on specific date (e.g., January 1st)
5. **Custom**: Cron expression (e.g., `0 9 * * 1-5` for weekdays at 9 AM)

**Alternatives Considered**:
1. **APScheduler**: Python job scheduler but requires persistent job store; overkill for simple rescheduling
2. **Celery Beat**: Distributed task scheduler but adds complexity; requires Redis/RabbitMQ
3. **Kubernetes CronJob**: Not suitable for dynamic user-defined schedules

**Trade-offs**:
- ✅ Flexible and powerful
- ✅ No external dependencies
- ✅ User-friendly for common patterns
- ⚠️ Cron expressions have learning curve
- ⚠️ Edge cases (e.g., Feb 31st) require careful handling

**Implementation**:
```python
# recurring_patterns table schema
{
  "id": "uuid",
  "task_id": "uuid",
  "frequency": "daily|weekly|monthly|yearly|custom",
  "interval": 1,  # for daily: every N days
  "days_of_week": [1, 3, 5],  # for weekly: Monday, Wednesday, Friday
  "day_of_month": 15,  # for monthly: 15th of month
  "cron_expression": "0 9 * * 1-5",  # for custom
  "end_condition": "date|count|indefinite",
  "end_date": "2026-12-31",
  "occurrence_count": 10,
  "current_count": 3
}
```

---

## 11. Event Schema Versioning

### Decision: JSON Schema with Version Field

**Rationale**:
- **Backward Compatibility**: Consumers can handle multiple schema versions
- **Gradual Migration**: Deploy new consumers before producers
- **Validation**: JSON Schema validates event structure
- **Documentation**: Schema serves as API documentation

**Schema Structure**:
```json
{
  "schema_version": "1.0",
  "event_id": "uuid",
  "event_type": "task.created",
  "timestamp": "2026-01-11T10:30:00Z",
  "correlation_id": "uuid",
  "user_id": "uuid",
  "payload": {
    "task_id": "uuid",
    "title": "Task title",
    "description": "Task description",
    ...
  }
}
```

**Versioning Strategy**:
- **Major Version**: Breaking changes (field removed, type changed)
- **Minor Version**: Backward-compatible additions (new optional field)
- **Consumers**: Must handle all supported versions
- **Producers**: Always emit latest version

**Alternatives Considered**:
1. **Avro**: Binary format with schema registry but adds complexity; requires Confluent Schema Registry
2. **Protobuf**: Efficient binary format but requires code generation; learning curve
3. **No Versioning**: Simpler but breaks consumers on schema changes

**Trade-offs**:
- ✅ Human-readable (JSON)
- ✅ Flexible and easy to evolve
- ✅ No external dependencies
- ⚠️ Larger message size than binary formats
- ⚠️ Manual version management

---

## 12. Idempotency Strategy

### Decision: Event ID + Database Unique Constraint

**Rationale**:
- **At-Least-Once Delivery**: Kafka guarantees at-least-once; consumers must handle duplicates
- **Event ID**: Each event has unique UUID
- **Database Check**: Before processing, check if event_id already processed
- **Unique Constraint**: Database enforces uniqueness on event_id column

**Implementation**:
```python
# In each consumer service
async def process_event(event):
    # Check if already processed
    existing = await db.query(ProcessedEvent).filter_by(event_id=event.event_id).first()
    if existing:
        logger.info(f"Event {event.event_id} already processed, skipping")
        return

    # Process event
    await handle_event(event)

    # Mark as processed
    await db.add(ProcessedEvent(event_id=event.event_id, processed_at=datetime.utcnow()))
    await db.commit()
```

**Alternatives Considered**:
1. **Exactly-Once Semantics**: Kafka transactions but complex setup; not needed for demo
2. **Redis Cache**: Fast lookup but adds dependency; database sufficient for demo
3. **No Idempotency**: Simpler but causes duplicate tasks/notifications

**Trade-offs**:
- ✅ Simple and reliable
- ✅ No external dependencies
- ✅ Database enforces uniqueness
- ⚠️ Database query on every event
- ⚠️ Processed events table grows over time (needs cleanup)

---

## Summary of Key Decisions

| Component | Decision | Rationale |
|-----------|----------|-----------|
| Cloud Platform | DigitalOcean Kubernetes (DOKS) | $200 credit, simple setup, managed K8s |
| Event Streaming | Redpanda Cloud Serverless | Free tier, Kafka-compatible, serverless |
| Service Mesh | Dapr | Hackathon requirement, 5 building blocks |
| Database | Neon Postgres (existing) | Already configured, free tier sufficient |
| Notifications | SendGrid (email) + WebSocket (in-app) | Free tiers, simple integration |
| CI/CD | GitHub Actions | Free for public repos, native integration |
| Monitoring | Prometheus + Grafana | Open-source, K8s-native, no cost |
| Security Scanning | Trivy + Snyk | Free for open-source, fast scans |
| WebSocket | FastAPI WebSocket | Native support, no external service |
| Recurring Tasks | Custom logic + croniter | Flexible, no external dependencies |
| Event Schemas | JSON with versioning | Human-readable, flexible evolution |
| Idempotency | Event ID + DB constraint | Simple, reliable, no external deps |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Free tier limits exceeded | Medium | High | Monitor usage daily; implement rate limiting |
| Redpanda free tier insufficient | Low | High | Redpanda free tier very generous (10 MB/s ingress); sufficient for demo |
| DOKS $200 credit expires | Low | High | 60-day validity covers hackathon; monitor spending |
| SendGrid 100 emails/day limit | Medium | Medium | Limit to 10 emails/user/day; prioritize critical notifications |
| Neon Postgres 0.5 GB limit | Low | Medium | Current data <100 MB; sufficient for demo with 10-20 users |
| WebSocket connection drops | Medium | Low | Implement reconnection logic; sync missed updates |
| Dapr sidecar overhead | Low | Medium | Monitor resource usage; optimize sidecar config |
| Event ordering issues | Medium | High | Use partition keys (task_id) for ordering |

---

## Next Steps

1. ✅ Research complete - all technology decisions documented
2. ⏭️ Phase 1: Design data model and API contracts
3. ⏭️ Phase 1: Create quickstart guide for setup
4. ⏭️ Phase 2: Begin implementation with foundation setup
