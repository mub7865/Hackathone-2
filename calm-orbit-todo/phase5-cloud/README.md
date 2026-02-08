# Phase V: Advanced Cloud Deployment - Todo Application

**Hackathon II - The Evolution of Todo**

**Status**: ✅ Local Implementation Complete | **Version**: 1.0.0

---

## 🎯 Overview

Phase V implements advanced cloud-native features with event-driven architecture. This phase builds on Phases I-IV to create a production-ready, scalable todo application with recurring tasks, reminders, priorities, tags, and event streaming.

### ✨ Phase V Features (Hackathon Requirements)

#### Part A: Advanced Features ✅
- **Recurring Tasks**: Daily, weekly, monthly, yearly, and custom cron patterns
- **Due Dates & Reminders**: Scheduled notifications for upcoming tasks
- **Priorities**: High, medium, and low priority levels (Intermediate Level)
- **Tags/Categories**: Multiple tags per task for organization (Intermediate Level)
- **Search & Filter**: Search by keyword, filter by status/priority/date (Intermediate Level)
- **Sort Tasks**: Reorder by due date, priority, or alphabetically (Intermediate Level)

#### Part B: Event-Driven Architecture ✅
- **Kafka Integration**: Redpanda for event streaming
- **Event Producers**: Publish events for all task operations
- **Event Consumers**: Process events asynchronously
- **Background Schedulers**: Recurring task and reminder schedulers
- **Audit Logging**: Complete audit trail for all operations

#### Part C: Local Deployment ✅
- **Minikube**: Local Kubernetes deployment
- **Dapr**: Distributed application runtime (Pub/Sub, State, Bindings, Secrets)
- **Redpanda Local**: Kafka-compatible event streaming
- **Full Dapr Components**: Pub/Sub, State Management, Bindings (cron), Secrets, Service Invocation

#### Part D: Cloud Deployment (Not Implemented)
- ❌ DigitalOcean DOKS deployment (planned)
- ❌ Redpanda Cloud integration (planned)
- ❌ CI/CD pipeline (planned)

---

## 🚀 Quick Start

### Prerequisites

- **Docker Desktop** (with WSL2 for Windows)
- **Minikube** (v1.30+)
- **kubectl** (v1.27+)
- **Git**

### Local Deployment (Minikube)

**Automated Setup:**
```bash
cd calm-orbit-todo/phase5-cloud

# Complete deployment (builds images, deploys all services)
./scripts/deploy-phase5-minikube.sh
```

**Manual Setup:**
```bash
# 1. Start Minikube
minikube start --cpus=4 --memory=8192 --disk-size=20g

# 2. Set Docker environment
eval $(minikube docker-env)

# 3. Build images
docker build -t calm-orbit-backend:latest ./backend
docker build -t calm-orbit-frontend:latest ./frontend

# 4. Deploy to Kubernetes
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/01-secrets.yaml
kubectl apply -f k8s/02-configmap.yaml
kubectl apply -f k8s/03-postgres.yaml
kubectl apply -f k8s/redpanda-local.yaml
kubectl apply -f k8s/04-backend.yaml
kubectl apply -f k8s/05-frontend.yaml

# 5. Wait for pods to be ready
kubectl wait --for=condition=ready pod --all -n calm-orbit --timeout=300s

# 6. Get access URLs
minikube ip  # Note the IP
# Frontend: http://<minikube-ip>:30300
# Backend:  http://<minikube-ip>:30800
```

**Cleanup:**
```bash
./scripts/cleanup-phase5-minikube.sh
```

---

## 📁 Project Structure

```
phase5-cloud/
├── backend/                    # FastAPI backend service
│   ├── app/
│   │   ├── main.py            # Application entry point with Phase 5 lifespan
│   │   ├── config.py          # Phase 5 configuration (Kafka, Dapr)
│   │   ├── models/            # SQLModel data models
│   │   │   ├── task.py        # Task with priority, tags, due_date, remind_at
│   │   │   ├── recurring_patterns.py  # Recurring task patterns
│   │   │   ├── notification_preferences.py
│   │   │   └── audit_log.py   # Event audit trail
│   │   ├── api/v1/            # API endpoints
│   │   │   ├── tasks.py       # Task CRUD with Phase 5 features
│   │   │   ├── recurring_tasks.py
│   │   │   ├── reminders.py
│   │   │   └── tags.py
│   │   ├── events/            # Kafka event streaming
│   │   │   ├── producer.py    # Event publishers
│   │   │   ├── consumer.py    # Event consumers
│   │   │   └── schemas.py     # Event schemas
│   │   ├── schedulers/        # Background schedulers
│   │   │   ├── recurring_scheduler.py
│   │   │   └── reminder_scheduler.py
│   │   ├── dapr/              # Dapr integration
│   │   │   └── client.py      # Dapr HTTP client
│   │   └── notifications/     # Notification service
│   │       └── email_sender.py
│   ├── Dockerfile             # Multi-stage production build
│   └── requirements.txt       # Python dependencies (aiokafka, dapr)
│
├── frontend/                   # Next.js 15 frontend
│   ├── app/                   # Next.js App Router
│   ├── components/            # React components
│   │   ├── tasks/             # Task components with Phase 5 features
│   │   ├── PrioritySelector.tsx
│   │   ├── TagInput.tsx
│   │   └── DueDatePicker.tsx
│   ├── lib/                   # Utilities and API clients
│   ├── Dockerfile             # Multi-stage production build
│   └── package.json           # Node.js dependencies
│
├── k8s/                       # Kubernetes manifests
│   ├── 00-namespace.yaml      # calm-orbit namespace
│   ├── 01-secrets.yaml        # Database, JWT secrets
│   ├── 02-configmap.yaml      # Configuration
│   ├── 03-postgres.yaml       # PostgreSQL StatefulSet
│   ├── 04-backend.yaml        # Backend Deployment (with Phase 5 env vars)
│   ├── 05-frontend.yaml       # Frontend Deployment
│   ├── redpanda-local.yaml    # Redpanda (Kafka) StatefulSet + Topics Job
│   └── dapr/                  # Dapr components
│       ├── pubsub-kafka.yaml  # Kafka Pub/Sub component
│       └── state-postgresql.yaml (optional)
│
├── scripts/                   # Deployment automation
│   ├── deploy-phase5-minikube.sh   # Complete deployment script
│   └── cleanup-phase5-minikube.sh  # Cleanup script
│
├── docker-compose.yml         # Local development (alternative to Minikube)
├── MINIKUBE-DEPLOYMENT.md     # Detailed Minikube deployment guide
└── README.md                  # This file
```

---

## 🛠️ Technology Stack

### Backend
- **Python 3.13+**: Modern Python with type hints
- **FastAPI 0.115+**: High-performance async web framework
- **SQLModel 0.0.22+**: SQL databases with Python type annotations
- **aiokafka 0.11.0+**: Async Kafka client for Python
- **dapr 1.14.0+**: Dapr SDK for Python
- **asyncpg**: Async PostgreSQL driver
- **python-jose**: JWT token handling
- **sendgrid**: Email notifications (optional)
- **croniter**: Cron expression parsing

### Frontend
- **Next.js 15.5.9**: React framework with App Router
- **React 19.0.0**: UI library
- **TypeScript**: Type-safe JavaScript
- **Tailwind CSS**: Utility-first CSS framework
- **Better Auth 1.4.10**: Authentication library

### Infrastructure
- **Kubernetes**: Container orchestration (Minikube for local)
- **Redpanda**: Kafka-compatible event streaming (local deployment)
- **Dapr**: Distributed application runtime
- **Neon Postgres**: Serverless PostgreSQL database
- **Docker**: Container runtime

### Event Streaming (Phase V)
- **Kafka Topics**:
  - `task-events` - All task CRUD operations
  - `reminders` - Reminder triggers
  - `recurring-tasks` - Recurring task events
  - `task-updates` - Real-time sync
- **Producers**: Task, Reminder, Recurring Task
- **Consumers**: Task, Reminder, Recurring Task
- **Schedulers**: Recurring task generator, Reminder checker

---

## 🗄️ Database Schema

### Phase V Tables
- **task**: Main task table with Phase V columns:
  - `priority` (high/medium/low)
  - `tags` (array of strings)
  - `due_date` (timestamp with timezone)
  - `remind_at` (timestamp with timezone)
  - `recurring_pattern_id` (foreign key)
- **recurring_patterns**: Recurring task patterns and schedules
- **notification_preferences**: User notification settings
- **saved_filter**: User-defined task filters
- **audit_log**: Complete audit trail of all operations

**Indexes**: Optimized for filtering by priority, tags, due dates, and reminders

---

## 🎮 API Endpoints

### Tasks (Phase V Enhanced)
- `GET /api/v1/tasks` - List tasks with filters (priority, tags, due date, status)
- `POST /api/v1/tasks` - Create task with priority, tags, due date, reminder
- `GET /api/v1/tasks/{id}` - Get task details
- `PUT /api/v1/tasks/{id}` - Update task
- `DELETE /api/v1/tasks/{id}` - Delete task
- `PATCH /api/v1/tasks/{id}/complete` - Mark task as complete

### Recurring Tasks (Phase V)
- `POST /api/v1/recurring-tasks` - Create recurring pattern
- `GET /api/v1/recurring-tasks` - List recurring patterns
- `GET /api/v1/recurring-tasks/{id}` - Get recurring pattern
- `PUT /api/v1/recurring-tasks/{id}` - Update recurring pattern
- `DELETE /api/v1/recurring-tasks/{id}` - Delete recurring pattern

### Reminders (Phase V)
- `GET /api/v1/reminders` - List upcoming reminders
- `POST /api/v1/reminders/{task_id}` - Set reminder for task

### Tags (Phase V)
- `GET /api/v1/tags` - List all tags
- `GET /api/v1/tags/{tag}/tasks` - Get tasks by tag

### Health & Monitoring
- `GET /health` - Health check endpoint
- `GET /docs` - Swagger UI (API documentation)

---

## 🔄 Event Flow (Phase V)

### Task Creation Flow
```
1. User creates task via API
2. Backend saves to PostgreSQL
3. Backend publishes event to Kafka (task-events topic)
4. Event Consumer processes event
5. Audit Log records event
6. If recurring: Recurring Scheduler creates next occurrence
7. If reminder: Reminder Scheduler schedules notification
```

### Reminder Flow
```
1. Task created with due_date and remind_at
2. Event published to Kafka (reminders topic)
3. Reminder Scheduler checks every 60 seconds
4. When remind_at <= NOW(), trigger notification
5. Notification Service sends email (if configured)
6. Update task: reminder_sent = true
```

### Recurring Task Flow
```
1. User creates recurring task (e.g., "Weekly standup")
2. Recurring pattern saved to database
3. User completes task
4. Event published to Kafka (task-events topic)
5. Recurring Scheduler detects completion
6. Automatically creates next occurrence
7. Cycle repeats indefinitely (or until end condition)
```

---

## 🧪 Testing Phase V Features

### 1. Recurring Tasks
```bash
# Create a weekly recurring task
curl -X POST http://<minikube-ip>:30800/api/v1/recurring-tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Weekly team meeting",
    "frequency": "weekly",
    "days_of_week": [1],
    "interval": 1
  }'

# Complete the task
curl -X PATCH http://<minikube-ip>:30800/api/v1/tasks/{task_id}/complete

# Check logs - next occurrence should be created
kubectl logs -f -l app=backend -n calm-orbit
```

### 2. Reminders
```bash
# Create task with reminder
curl -X POST http://<minikube-ip>:30800/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Submit report",
    "due_date": "2026-02-10T17:00:00Z",
    "remind_at": "2026-02-10T16:00:00Z"
  }'

# Check scheduler logs
kubectl logs -f -l app=backend -n calm-orbit | grep "Reminder"
```

### 3. Priorities & Tags
```bash
# Create task with priority and tags
curl -X POST http://<minikube-ip>:30800/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Fix critical bug",
    "priority": "high",
    "tags": ["urgent", "backend", "bug"]
  }'

# Filter by priority
curl http://<minikube-ip>:30800/api/v1/tasks?priority=high

# Filter by tag
curl http://<minikube-ip>:30800/api/v1/tasks?tags=urgent
```

### 4. Event Streaming
```bash
# Check Kafka topics
kubectl exec -it redpanda-0 -n calm-orbit -- \
  rpk topic list --brokers kafka.calm-orbit.svc.cluster.local:9092

# Check event logs
kubectl logs -f -l app=backend -n calm-orbit | grep "Event published"
```

---

## 📊 Monitoring

### View Logs
```bash
# Backend logs (includes schedulers and event consumers)
kubectl logs -f -l app=backend -n calm-orbit

# Frontend logs
kubectl logs -f -l app=frontend -n calm-orbit

# Kafka logs
kubectl logs -f -l app=redpanda -n calm-orbit

# PostgreSQL logs
kubectl logs -f -l app=postgres -n calm-orbit
```

### Check Pod Status
```bash
# All pods
kubectl get pods -n calm-orbit

# Detailed pod info
kubectl describe pod <pod-name> -n calm-orbit
```

### Check Services
```bash
# All services
kubectl get svc -n calm-orbit

# Service details
kubectl describe svc calm-orbit-backend -n calm-orbit
```

---

## 🔧 Configuration

### Environment Variables (Backend)

**Phase V Configuration:**
```yaml
# Kafka/Redpanda
KAFKA_BOOTSTRAP_SERVERS: "kafka.calm-orbit.svc.cluster.local:9092"
KAFKA_TOPIC_TASK_EVENTS: "task-events"
KAFKA_TOPIC_REMINDERS: "reminders"
KAFKA_TOPIC_TASK_UPDATES: "task-updates"
KAFKA_CONSUMER_GROUP: "phase5-backend"

# Feature Flags
ENABLE_EVENT_PUBLISHING: "true"
ENABLE_NOTIFICATIONS: "true"
ENABLE_AUDIT_LOGGING: "true"

# Dapr
DAPR_HTTP_PORT: "3500"
DAPR_GRPC_PORT: "50001"
DAPR_PUBSUB_NAME: "pubsub-kafka"
DAPR_STATE_STORE_NAME: "state-postgresql"

# SendGrid (optional - for real emails)
SENDGRID_API_KEY: ""
SENDGRID_FROM_EMAIL: "noreply@calm-orbit-todo.com"
```

---

## 🚨 Troubleshooting

### Pods Not Starting
```bash
# Check pod events
kubectl describe pod <pod-name> -n calm-orbit

# Common issues:
# 1. Image pull errors - Ensure images built in Minikube's Docker
# 2. Resource limits - Increase Minikube memory/CPU
# 3. Database connection - Check PostgreSQL is ready
```

### Kafka Connection Issues
```bash
# Check Redpanda is running
kubectl get pods -l app=redpanda -n calm-orbit

# Check Kafka topics
kubectl exec -it redpanda-0 -n calm-orbit -- \
  rpk topic list --brokers kafka.calm-orbit.svc.cluster.local:9092

# Check backend logs for Kafka errors
kubectl logs -f -l app=backend -n calm-orbit | grep -i kafka
```

### Schedulers Not Running
```bash
# Check backend logs for scheduler startup
kubectl logs -f -l app=backend -n calm-orbit | grep -i scheduler

# Verify ENABLE_EVENT_PUBLISHING is true
kubectl get configmap calm-orbit-config -n calm-orbit -o yaml
```

---

## 📚 Documentation

- **[MINIKUBE-DEPLOYMENT.md](MINIKUBE-DEPLOYMENT.md)** - Detailed Minikube deployment guide
- **[Hackathon Requirements](../../Hackathon%20II%20-%20Todo%20Spec-Driven%20Development.md)** - Original hackathon document
- **API Documentation**: `http://<minikube-ip>:30800/docs`

---

## 🎯 Hackathon Compliance

### Phase V Requirements Met

✅ **Part A: Advanced Features**
- Recurring Tasks (daily, weekly, monthly, yearly, custom)
- Due Dates & Reminders
- Priorities (high, medium, low)
- Tags/Categories
- Search & Filter
- Sort Tasks

✅ **Part B: Event-Driven Architecture**
- Kafka Integration (Redpanda)
- Event Producers
- Event Consumers
- Background Schedulers
- Audit Logging

✅ **Part C: Local Deployment**
- Minikube deployment
- Dapr components (Pub/Sub, State, Bindings, Secrets)
- Redpanda local deployment
- Full Dapr integration

❌ **Part D: Cloud Deployment** (Not Implemented)
- DigitalOcean DOKS
- Redpanda Cloud
- CI/CD pipeline

---

## 📝 Notes

- **Email Notifications**: Reminder scheduler triggers but emails require SendGrid API key configuration
- **Dapr**: Optional - Phase V works with direct Kafka integration if Dapr not installed
- **Cloud Deployment**: Infrastructure ready, deployment scripts prepared, cloud deployment pending

---

**Built with ❤️ for Hackathon II - The Evolution of Todo**
