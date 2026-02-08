# Architecture Overview: Cloud-Native Event-Driven Todo Application

**Version**: 1.0
**Last Updated**: 2026-01-12
**Status**: Production Ready

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Principles](#architecture-principles)
3. [Technology Stack](#technology-stack)
4. [Component Architecture](#component-architecture)
5. [Event-Driven Architecture](#event-driven-architecture)
6. [Data Architecture](#data-architecture)
7. [Security Architecture](#security-architecture)
8. [Deployment Architecture](#deployment-architecture)
9. [Scalability & Performance](#scalability--performance)
10. [Monitoring & Observability](#monitoring--observability)

---

## System Overview

The Cloud-Native Event-Driven Todo Application is a production-grade task management system built with modern cloud-native technologies and event-driven architecture patterns. The system enables users to manage tasks with advanced features including recurring tasks, reminders, priorities, tags, real-time updates, and comprehensive audit trails.

### Key Characteristics

- **Cloud-Native**: Designed for Kubernetes deployment with containerized microservices
- **Event-Driven**: Asynchronous communication via Kafka/Redpanda for loose coupling
- **Real-Time**: WebSocket connections for instant updates
- **Scalable**: Horizontal scaling with stateless services
- **Observable**: Comprehensive monitoring with Prometheus and Grafana
- **Secure**: JWT authentication, RBAC, audit trails, and security scanning
- **Resilient**: Health checks, automatic rollback, and graceful degradation

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Users / Clients                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Ingress Controller                          │
│                    (NGINX / Traefik)                            │
└────────────┬────────────────────────────────────┬───────────────┘
             │                                    │
             ▼                                    ▼
┌────────────────────────┐          ┌────────────────────────────┐
│   Frontend Service     │          │    Backend Service         │
│   (Next.js 16)         │◄────────►│    (FastAPI)              │
│   - React 19           │          │    - SQLModel             │
│   - TypeScript         │          │    - Pydantic             │
│   - Framer Motion      │          │    - JWT Auth             │
└────────────────────────┘          └────────────┬───────────────┘
                                                  │
                    ┌─────────────────────────────┼─────────────────────────┐
                    │                             │                         │
                    ▼                             ▼                         ▼
        ┌───────────────────┐       ┌─────────────────────┐   ┌──────────────────┐
        │  PostgreSQL DB    │       │   Kafka/Redpanda    │   │  WebSocket       │
        │  (Neon)           │       │   Event Streaming   │   │  Connections     │
        │  - Tasks          │       │   - task-events     │   │  - Real-time     │
        │  - Users          │       │   - reminders       │   │  - Broadcast     │
        │  - Audit Logs     │       │   - recurring-tasks │   └──────────────────┘
        └───────────────────┘       └─────────────────────┘
                                                  │
                    ┌─────────────────────────────┼─────────────────────────┐
                    │                             │                         │
                    ▼                             ▼                         ▼
        ┌───────────────────┐       ┌─────────────────────┐   ┌──────────────────┐
        │  Event Consumers  │       │   Dapr Sidecar      │   │  Prometheus      │
        │  - Task Events    │       │   - Pub/Sub         │   │  - Metrics       │
        │  - Reminders      │       │   - State Store     │   │  - Alerts        │
        │  - Recurring      │       │   - Service Mesh    │   └──────────────────┘
        └───────────────────┘       └─────────────────────┘
```

---

## Architecture Principles

### 1. **Separation of Concerns**
- Frontend handles presentation and user interaction
- Backend handles business logic and data management
- Event streaming handles asynchronous communication
- Database handles data persistence

### 2. **Event-Driven Design**
- Loose coupling between components
- Asynchronous processing for non-critical operations
- Event sourcing for audit trails
- Idempotent event processing

### 3. **API-First Development**
- RESTful API design with OpenAPI specification
- Versioned endpoints (v1, v2, etc.)
- Consistent error handling and response formats
- Comprehensive API documentation

### 4. **Security by Design**
- JWT-based authentication
- Role-based access control (RBAC)
- Audit logging for all operations
- Secret management with Kubernetes secrets
- Security scanning in CI/CD pipeline

### 5. **Observability**
- Structured logging with correlation IDs
- Metrics collection with Prometheus
- Distributed tracing (ready for Jaeger/Zipkin)
- Health checks and readiness probes

### 6. **Scalability**
- Stateless services for horizontal scaling
- Database connection pooling
- Event-driven architecture for async processing
- Caching strategies (Redis ready)

---

## Technology Stack

### Frontend
- **Framework**: Next.js 16 (App Router)
- **UI Library**: React 19
- **Language**: TypeScript 5.x
- **Styling**: Tailwind CSS
- **Animation**: Framer Motion
- **State Management**: React Context + Hooks
- **HTTP Client**: Fetch API / Axios
- **WebSocket**: Native WebSocket API
- **Authentication**: Better Auth with JWT

### Backend
- **Framework**: FastAPI 0.115+
- **Language**: Python 3.13+
- **ORM**: SQLModel 0.0.22+
- **Validation**: Pydantic v2
- **Authentication**: python-jose (JWT)
- **Server**: Uvicorn (ASGI)
- **Database Driver**: asyncpg (async PostgreSQL)
- **Event Streaming**: aiokafka
- **Service Mesh**: Dapr

### Database
- **Primary Database**: PostgreSQL 15+ (Neon)
- **Connection**: Async via asyncpg
- **Migrations**: Alembic
- **Pooling**: SQLAlchemy async pool

### Event Streaming
- **Message Broker**: Kafka / Redpanda
- **Client Library**: aiokafka (Python)
- **Topics**: task-events, reminders, recurring-tasks, task-updates
- **Consumer Groups**: task-consumer-group, reminder-consumer-group

### Infrastructure
- **Container Runtime**: Docker
- **Orchestration**: Kubernetes 1.28+
- **Service Mesh**: Dapr 1.12+
- **Ingress**: NGINX / Traefik
- **CI/CD**: GitHub Actions
- **Registry**: GitHub Container Registry (GHCR)

### Monitoring & Observability
- **Metrics**: Prometheus
- **Visualization**: Grafana
- **Alerting**: Prometheus Alertmanager
- **Logging**: Structured JSON logs (ready for ELK/Loki)
- **Tracing**: OpenTelemetry ready

### Development Tools
- **Linting**: Ruff (Python), ESLint (TypeScript)
- **Type Checking**: Mypy (Python), TypeScript compiler
- **Testing**: Pytest (Python), Jest (TypeScript)
- **Security**: Trivy, CodeQL, Semgrep, Gitleaks, Bandit
- **Code Quality**: SonarQube ready

---

## Component Architecture

### Frontend Service

**Purpose**: User interface and client-side logic

**Key Components**:
- **Pages**: Task list, task detail, recurring tasks, settings
- **Components**: TaskList, TaskForm, RecurringTaskForm, PrioritySelector, TagInput, DueDatePicker, AuditTrail, NotificationPreferences
- **Hooks**: useWebSocket, useAuth, useTasks, useFilters
- **API Client**: Centralized API client with JWT token management
- **WebSocket Client**: Real-time update subscription

**Responsibilities**:
- Render user interface
- Handle user interactions
- Manage client-side state
- Communicate with backend API
- Receive real-time updates via WebSocket
- Display notifications and alerts

**Scaling**: Stateless, can scale horizontally behind load balancer

### Backend Service

**Purpose**: Business logic, data management, and API endpoints

**Key Modules**:

1. **API Layer** (`app/api/v1/`):
   - `tasks.py`: Task CRUD operations
   - `recurring_tasks.py`: Recurring task management
   - `reminders.py`: Reminder configuration
   - `tags.py`: Tag management
   - `saved_filters.py`: Saved filter management
   - `audit.py`: Audit trail access
   - `notification_preferences.py`: Notification settings
   - `websocket.py`: WebSocket connections

2. **Models Layer** (`app/models/`):
   - `task.py`: Task model with priority, tags, due_date
   - `recurring_pattern.py`: Recurring task patterns
   - `saved_filter.py`: User-defined filters
   - `audit_log.py`: Audit trail records
   - `notification_preferences.py`: User notification settings
   - `processed_event.py`: Event idempotency tracking

3. **Services Layer** (`app/services/`):
   - `recurring_task_service.py`: Recurring task logic
   - `reminder_service.py`: Reminder scheduling
   - `audit_service.py`: Audit logging
   - `notification_preferences_service.py`: Notification logic
   - `notification_rate_limiter.py`: Rate limiting

4. **Events Layer** (`app/events/`):
   - `producers/event_producers.py`: Event publishing
   - `consumers/event_consumers.py`: Event consumption
   - `idempotency.py`: Duplicate event prevention
   - `schemas.py`: Event validation schemas

5. **WebSocket Layer** (`app/websocket/`):
   - `manager.py`: Connection management
   - `broadcaster.py`: Event broadcasting

6. **Metrics Layer** (`app/metrics/`):
   - `app_metrics.py`: Custom Prometheus metrics

**Responsibilities**:
- Validate and process API requests
- Execute business logic
- Manage database transactions
- Publish events to Kafka
- Consume events from Kafka
- Maintain WebSocket connections
- Collect and expose metrics
- Log audit trails

**Scaling**: Stateless, can scale horizontally with load balancer

### Database (PostgreSQL)

**Purpose**: Persistent data storage

**Schema Design**:

```sql
-- Core Tables
tasks (id, user_id, title, description, status, priority, tags, due_date, remind_at, recurring_pattern_id, created_at, updated_at)
recurring_patterns (id, user_id, frequency, interval, days_of_week, day_of_month, start_date, end_date, next_occurrence, active, created_at, updated_at)
saved_filters (id, user_id, name, filter_criteria, created_at, updated_at)

-- Audit & Compliance
audit_logs (id, user_id, action, resource_type, resource_id, changes, ip_address, user_agent, created_at)

-- Notifications
notification_preferences (id, user_id, email_enabled, in_app_enabled, push_enabled, sms_enabled, reminder_frequency, task_updates_enabled, recurring_task_enabled, quiet_hours_enabled, quiet_hours_start, quiet_hours_end, timezone, created_at, updated_at)

-- Event Processing
processed_events (id, event_id, event_type, consumer_group, processed_at)
```

**Indexes**:
- Primary keys on all tables
- Foreign keys with indexes
- Composite indexes for common queries
- GIN indexes for array fields (tags)
- Unique constraints for idempotency (event_id + consumer_group)

**Scaling**:
- Read replicas for read-heavy workloads
- Connection pooling (max 20 connections)
- Query optimization with EXPLAIN ANALYZE
- Partitioning for large tables (audit_logs)

### Event Streaming (Kafka/Redpanda)

**Purpose**: Asynchronous event-driven communication

**Topics**:

1. **todo-app.task-events**:
   - Events: task.created, task.updated, task.deleted, task.completed
   - Partitions: 3
   - Retention: 7 days
   - Consumers: task-event-consumer

2. **todo-app.reminders**:
   - Events: reminder.due, reminder.scheduled
   - Partitions: 3
   - Retention: 7 days
   - Consumers: reminder-consumer

3. **todo-app.recurring-tasks**:
   - Events: recurring.pattern.created, recurring.task.generated
   - Partitions: 3
   - Retention: 7 days
   - Consumers: recurring-task-consumer

4. **todo-app.task-updates**:
   - Events: task.status.changed, task.priority.changed
   - Partitions: 3
   - Retention: 7 days
   - Consumers: websocket-broadcaster

**Event Schema**:
```json
{
  "event_type": "task.created",
  "event_id": "uuid",
  "timestamp": "ISO8601",
  "data": {
    "task_id": "uuid",
    "user_id": "string",
    "title": "string",
    "status": "string",
    "priority": "string"
  }
}
```

**Guarantees**:
- At-least-once delivery
- Idempotent processing with processed_events table
- Ordered processing within partition
- Consumer group coordination

**Scaling**:
- Increase partitions for higher throughput
- Add consumer instances for parallel processing
- Monitor consumer lag

---

## Event-Driven Architecture

### Event Flow

```
User Action → API Endpoint → Database Write → Event Publish → Kafka Topic
                                                                    ↓
                                                            Event Consumer
                                                                    ↓
                                                    ┌───────────────┴───────────────┐
                                                    ▼                               ▼
                                            Side Effects                    WebSocket Broadcast
                                            (Email, Notifications)          (Real-time Updates)
```

### Event Producers

**Location**: `backend/app/events/producers/event_producers.py`

**Classes**:
- `EventProducer`: Base producer with common functionality
- `TaskEventProducer`: Task-related events
- `ReminderEventProducer`: Reminder events
- `RecurringTaskEventProducer`: Recurring task events

**Publishing Pattern**:
```python
async def publish_task_created(task: Task):
    event_data = {
        "task_id": str(task.id),
        "user_id": task.user_id,
        "title": task.title,
        "status": task.status.value,
        "priority": task.priority.value if task.priority else None,
    }
    await task_producer.publish_event(
        topic="task-events",
        event_type="task.created",
        event_data=event_data,
        key=task.user_id,  # Partition by user_id
    )
```

### Event Consumers

**Location**: `backend/app/events/consumers/event_consumers.py`

**Classes**:
- `EventConsumer`: Base consumer with common functionality
- `TaskEventConsumer`: Consumes task events
- `ReminderEventConsumer`: Consumes reminder events
- `RecurringTaskEventConsumer`: Consumes recurring task events

**Consumption Pattern**:
```python
class TaskEventConsumer(EventConsumer):
    def __init__(self):
        super().__init__(
            topic="todo-app.task-events",
            consumer_group="task-consumer-group",
        )
        self.register_handler("task.created", self.handle_task_created)
        self.register_handler("task.updated", self.handle_task_updated)

    async def handle_task_created(self, data: Dict[str, Any]):
        # Check idempotency
        if await idempotency_service.is_processed(event_id, consumer_group):
            return

        # Process event
        await send_notification(data["user_id"], "Task created")
        await broadcast_to_websocket(data["user_id"], data)

        # Mark as processed
        await idempotency_service.mark_processed(event_id, event_type, consumer_group)
```

### Idempotency

**Purpose**: Prevent duplicate event processing

**Implementation**:
- `processed_events` table with unique constraint on (event_id, consumer_group)
- Check before processing
- Mark after successful processing
- Handle race conditions with database constraints

**Benefits**:
- Exactly-once semantics at application level
- Safe retries
- Duplicate event detection

---

## Data Architecture

### Data Flow

```
User Input → Frontend Validation → API Request → Backend Validation
                                                        ↓
                                                  Business Logic
                                                        ↓
                                            ┌───────────┴───────────┐
                                            ▼                       ▼
                                    Database Write          Event Publish
                                            ↓                       ↓
                                    Response to User        Async Processing
```

### Data Models

**Task Model**:
```python
class Task(SQLModel, table=True):
    id: UUID
    user_id: str
    title: str
    description: Optional[str]
    status: TaskStatus  # pending, in_progress, completed
    priority: Optional[TaskPriority]  # low, medium, high
    tags: List[str]  # Array field
    due_date: Optional[datetime]
    remind_at: Optional[datetime]
    recurring_pattern_id: Optional[UUID]
    created_at: datetime
    updated_at: datetime
```

**Recurring Pattern Model**:
```python
class RecurringPattern(SQLModel, table=True):
    id: UUID
    user_id: str
    frequency: RecurringFrequency  # daily, weekly, monthly, yearly
    interval: int  # Every N days/weeks/months
    days_of_week: Optional[List[int]]  # For weekly
    day_of_month: Optional[int]  # For monthly
    start_date: date
    end_date: Optional[date]
    next_occurrence: datetime
    active: bool
    created_at: datetime
    updated_at: datetime
```

### Data Consistency

**ACID Transactions**:
- Database operations wrapped in transactions
- Rollback on failure
- Isolation level: READ COMMITTED

**Eventual Consistency**:
- Event-driven updates are eventually consistent
- Idempotency ensures correctness
- Retry mechanisms for failed events

---

## Security Architecture

### Authentication

**JWT-Based Authentication**:
- Access tokens with 15-minute expiration
- Refresh tokens with 7-day expiration
- Token stored in httpOnly cookies
- CSRF protection enabled

**Token Structure**:
```json
{
  "sub": "user_id",
  "email": "user@example.com",
  "exp": 1234567890,
  "iat": 1234567890
}
```

### Authorization

**Role-Based Access Control (RBAC)**:
- User can only access their own tasks
- Admin role for system operations
- Resource-level permissions

**Enforcement**:
```python
async def get_current_user(token: str = Depends(oauth2_scheme)) -> str:
    payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    user_id = payload.get("sub")
    return user_id

@router.get("/tasks/{task_id}")
async def get_task(
    task_id: UUID,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    task = await db.get(Task, task_id)
    if task.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    return task
```

### Data Protection

**Encryption**:
- TLS/SSL for data in transit
- Database encryption at rest (Neon)
- Secret management with Kubernetes secrets

**Sensitive Data**:
- Passwords hashed with bcrypt
- JWT secrets in environment variables
- API keys in Kubernetes secrets

### Audit Trail

**Comprehensive Logging**:
- All CRUD operations logged
- User actions tracked
- IP address and user agent captured
- Change history with before/after values

**Compliance**:
- GDPR-ready with data export
- Audit logs for compliance reporting
- Retention policies configurable

---

## Deployment Architecture

### Kubernetes Deployment

**Namespace**: `default` (or custom namespace)

**Deployments**:
1. **Backend Deployment**:
   - Replicas: 3 (production), 1 (dev/staging)
   - Resources: 512Mi-1Gi memory, 500m-1000m CPU
   - Health checks: liveness, readiness
   - Rolling update strategy

2. **Frontend Deployment**:
   - Replicas: 2 (production), 1 (dev/staging)
   - Resources: 256Mi-512Mi memory, 250m-500m CPU
   - Health checks: liveness, readiness
   - Rolling update strategy

3. **PostgreSQL Deployment**:
   - Replicas: 1 (StatefulSet for production)
   - Persistent volume: 10Gi
   - Backup strategy

4. **Kafka Deployment**:
   - Replicas: 3 (production), 1 (dev/staging)
   - Persistent volume: 20Gi
   - ZooKeeper coordination

**Services**:
- Backend Service: ClusterIP on port 8000
- Frontend Service: ClusterIP on port 3000
- PostgreSQL Service: ClusterIP on port 5432
- Kafka Service: ClusterIP on port 9092

**Ingress**:
- NGINX Ingress Controller
- TLS termination
- Path-based routing:
  - `/` → Frontend
  - `/api/` → Backend
  - `/ws/` → WebSocket

### Dapr Integration

**Sidecar Injection**:
```yaml
annotations:
  dapr.io/enabled: "true"
  dapr.io/app-id: "todo-backend"
  dapr.io/app-port: "8000"
  dapr.io/enable-metrics: "true"
  dapr.io/metrics-port: "9090"
```

**Components**:
- Pub/Sub: Kafka component
- State Store: Redis component (optional)
- Service Invocation: HTTP/gRPC

### Multi-Environment Strategy

**Environments**:
1. **Development**:
   - Single replica
   - Minimal resources
   - Fast deployment
   - Debug logging

2. **Staging**:
   - Production-like setup
   - Integration testing
   - Performance testing
   - Smoke tests

3. **Production**:
   - High availability (3+ replicas)
   - Blue-green deployment
   - Monitoring and alerting
   - Automatic rollback

---

## Scalability & Performance

### Horizontal Scaling

**Stateless Services**:
- Backend and frontend can scale horizontally
- Load balancer distributes traffic
- No session affinity required

**Scaling Triggers**:
- CPU utilization > 70%
- Memory utilization > 80%
- Request rate > 1000 req/s
- Response time > 500ms

**Kubernetes HPA**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-deployment
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Performance Optimization

**Database**:
- Connection pooling (max 20 connections)
- Query optimization with indexes
- Prepared statements
- Read replicas for read-heavy workloads

**Caching** (Ready for implementation):
- Redis for session caching
- API response caching
- Database query caching

**Event Processing**:
- Parallel consumer instances
- Batch processing for bulk operations
- Async processing for non-critical operations

### Load Testing

**Tools**: k6, Locust, JMeter

**Targets**:
- 1000 concurrent users
- 10,000 requests per second
- P95 latency < 500ms
- P99 latency < 1000ms

---

## Monitoring & Observability

### Metrics Collection

**Prometheus Metrics**:
- HTTP request rate, latency, errors
- Task operation metrics
- Event publishing/consumption metrics
- Database query metrics
- WebSocket connection metrics
- Notification metrics
- Business metrics (active users, tasks completed)

**Custom Metrics**:
```python
http_requests_total = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)

http_request_duration_seconds = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency",
    ["method", "endpoint"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0),
)
```

### Dashboards

**Grafana Dashboards**:
1. **Todo App Overview**:
   - HTTP request rate
   - Request latency (P95)
   - Task operations
   - Active tasks by status
   - Event publishing/consumption
   - Database metrics
   - WebSocket connections
   - Active users
   - Notification success rate

2. **Event Streaming Metrics**:
   - Event publishing rate by topic
   - Event publish failures
   - Event consumption rate by consumer group
   - Duplicate events detected
   - Event latency (P95)

3. **Dapr Metrics**:
   - Dapr HTTP request rate
   - Dapr pub/sub messages
   - Dapr service invocations
   - Dapr sidecar resource usage

### Alerting

**Alert Rules** (25+ alerts):
- Application health (error rate, latency, service down)
- Database health (latency, connection pool, database down)
- Event streaming (publish failures, consumption failures, Kafka down)
- WebSocket (disconnection rate, too many connections)
- Notifications (failure rate, rate limiting)
- Resources (CPU, memory, disk space)
- Dapr (sidecar down, pub/sub latency, service invocation failures)
- Business metrics (no tasks completed, low user activity)

**Severity Levels**:
- **Critical**: Immediate action required (service down, database down)
- **Warning**: Investigation needed (high error rate, high latency)
- **Info**: Informational (low user activity, high rate limiting)

### Logging

**Structured Logging**:
```python
logger.info(
    "Task created",
    extra={
        "task_id": str(task.id),
        "user_id": task.user_id,
        "correlation_id": correlation_id,
        "timestamp": datetime.utcnow().isoformat(),
    }
)
```

**Log Aggregation** (Ready for):
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Loki + Grafana
- CloudWatch Logs

---

## Conclusion

The Cloud-Native Event-Driven Todo Application demonstrates modern architecture patterns including:

- **Microservices**: Loosely coupled, independently deployable services
- **Event-Driven**: Asynchronous communication for scalability
- **Cloud-Native**: Kubernetes-ready with containerization
- **Observable**: Comprehensive monitoring and alerting
- **Secure**: Authentication, authorization, and audit trails
- **Scalable**: Horizontal scaling with stateless services
- **Resilient**: Health checks, automatic rollback, graceful degradation

The architecture is production-ready and can handle thousands of concurrent users with sub-second response times.

---

## References

- [Deployment Guide](deployment.md)
- [API Reference](api-reference.md)
- [Event Schemas](event-schemas.md)
- [Monitoring Guide](monitoring.md)
- [User Guide](user-guide.md)
