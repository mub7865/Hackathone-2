# Data Model: Kubernetes Minikube Deployment

**Feature**: 008-k8s-minikube-deployment
**Date**: 2025-12-28
**Status**: Complete

## Overview

This document defines the Kubernetes entities, Docker image specifications, and configuration schemas for deploying the Phase III Todo Chatbot application on Minikube. The data model includes Deployments, Services, ConfigMaps, Secrets, and their relationships, along with Docker image structure requirements.

---

## 1. Kubernetes Entities

### 1.1 Frontend Deployment Entity

**Name**: `frontend-deployment`
**Purpose**: Manages Next.js frontend application pods
**Namespace**: `todo-app`

**Fields**:

| Field | Type | Description | Default Value |
|---------|---------|-------------|----------------|
| replicas | integer | Number of pod replicas | 1 |
| image.repository | string | Docker image name | `todo-frontend` |
| image.tag | string | Docker image version | `v1.0.0` |
| image.pullPolicy | string | Image pull policy | `Never` |
| service.type | string | Kubernetes service type | `NodePort` |
| service.port | integer | Container port | 3000 |
| service.nodePort | integer | Host port (NodePort) | 30000 |
| resources.requests.cpu | string | Guaranteed CPU | `100m` |
| resources.requests.memory | string | Guaranteed memory | `128Mi` |
| resources.limits.cpu | string | Maximum CPU | `500m` |
| resources.limits.memory | string | Maximum memory | `256Mi` |
| livenessProbe.path | string | Health check path | `/` |
| livenessProbe.initialDelaySeconds | integer | Startup grace period | 10 |
| livenessProbe.periodSeconds | integer | Check interval | 15 |
| livenessProbe.timeoutSeconds | integer | Check timeout | 5 |
| livenessProbe.failureThreshold | integer | Failures before restart | 3 |
| readinessProbe.path | string | Readiness check path | `/` |
| readinessProbe.initialDelaySeconds | integer | Startup grace period | 5 |
| readinessProbe.periodSeconds | integer | Check interval | 10 |
| readinessProbe.timeoutSeconds | integer | Check timeout | 3 |
| readinessProbe.failureThreshold | integer | Failures before not-ready | 3 |

**Relationships**:
- References: `frontend-service` (via `spec.selector.matchLabels`)
- Depends on: No Kubernetes dependencies (uses external backend service)

**Pod Template**:
- Container name: `frontend`
- Image: `todo-frontend:v1.0.0`
- Port: 3000
- Environment variables: From ConfigMap `todo-config`

---

### 1.2 Backend Deployment Entity

**Name**: `backend-deployment`
**Purpose**: Manages FastAPI backend application pods
**Namespace**: `todo-app`

**Fields**:

| Field | Type | Description | Default Value |
|---------|---------|-------------|----------------|
| replicas | integer | Number of pod replicas | 1 |
| image.repository | string | Docker image name | `todo-backend` |
| image.tag | string | Docker image version | `v1.0.0` |
| image.pullPolicy | string | Image pull policy | `Never` |
| service.type | string | Kubernetes service type | `ClusterIP` |
| service.port | integer | Container port | 8000 |
| resources.requests.cpu | string | Guaranteed CPU | `100m` |
| resources.requests.memory | string | Guaranteed memory | `128Mi` |
| resources.limits.cpu | string | Maximum CPU | `500m` |
| resources.limits.memory | string | Maximum memory | `512Mi` |
| livenessProbe.path | string | Health check path | `/health` |
| livenessProbe.initialDelaySeconds | integer | Startup grace period | 10 |
| livenessProbe.periodSeconds | integer | Check interval | 15 |
| livenessProbe.timeoutSeconds | integer | Check timeout | 5 |
| livenessProbe.failureThreshold | integer | Failures before restart | 3 |
| readinessProbe.path | string | Readiness check path | `/health` |
| readinessProbe.initialDelaySeconds | integer | Startup grace period | 5 |
| readinessProbe.periodSeconds | integer | Check interval | 10 |
| readinessProbe.timeoutSeconds | integer | Check timeout | 3 |
| readinessProbe.failureThreshold | integer | Failures before not-ready | 3 |

**Relationships**:
- References: `backend-service` (via `spec.selector.matchLabels`)
- Depends on: No Kubernetes dependencies (uses external Neon PostgreSQL)

**Pod Template**:
- Container name: `backend`
- Image: `todo-backend:v1.0.0`
- Port: 8000
- Environment variables: From ConfigMap `todo-config` + Secret `todo-secrets`

---

### 1.3 Frontend Service Entity

**Name**: `frontend-service`
**Purpose**: Provides stable endpoint for accessing frontend application
**Type**: `NodePort`

**Fields**:

| Field | Type | Description | Default Value |
|---------|---------|-------------|----------------|
| selector.app.kubernetes.io/name | string | Matches deployment | `frontend` |
| port | integer | Service port | 3000 |
| targetPort | integer | Container port | 3000 |
| nodePort | integer | Host port | 30000 |
| type | string | Service type | `NodePort` |

**Relationships**:
- Selects: `frontend-deployment` pods (via label `app.kubernetes.io/name: frontend`)
- Accessed by: External users (via NodePort) and `frontend-deployment` pods

---

### 1.4 Backend Service Entity

**Name**: `backend-service`
**Purpose**: Provides stable endpoint for frontend to access backend API
**Type**: `ClusterIP`

**Fields**:

| Field | Type | Description | Default Value |
|---------|---------|-------------|----------------|
| selector.app.kubernetes.io/name | string | Matches deployment | `backend` |
| port | integer | Service port | 8000 |
| targetPort | integer | Container port | 8000 |
| type | string | Service type | `ClusterIP` |

**Relationships**:
- Selects: `backend-deployment` pods (via label `app.kubernetes.io/name: backend`)
- Accessed by: `frontend-deployment` pods (via service DNS) within cluster
- Not exposed: External traffic (internal-only)

---

### 1.5 ConfigMap Entity

**Name**: `todo-config`
**Purpose**: Stores non-sensitive configuration as key-value pairs
**Namespace**: `todo-app`

**Fields**:

| Key | Value | Description |
|-----|---------|-------------|
| LOG_LEVEL | `info` | Application logging level |
| ENVIRONMENT | `production` | Deployment environment |
| CORS_ORIGINS | `[\"http://localhost:3000\", \"http://localhost:30000\"]` | Allowed CORS origins |
| BACKEND_URL | `http://backend-service:8000` | Backend service URL (for frontend) |
| FRONTEND_URL | `http://frontend-service:3000` | Frontend service URL (for backend) |
| PORT | `3000` (frontend) / `8000` (backend) | Application port (via pod-specific ConfigMaps) |

**Relationships**:
- Referenced by: `frontend-deployment` and `backend-deployment` (environment variables)
- No secrets stored (all data is non-sensitive)

---

### 1.6 Secret Entity

**Name**: `todo-secrets`
**Purpose**: Stores sensitive configuration data (base64 encoded)
**Namespace**: `todo-app`

**Fields**:

| Key | Value (Base64) | Description |
|-----|------------------|-------------|
| DATABASE_URL | `<base64-encoded Neon PostgreSQL connection string>` | Database connection with asyncpg driver |
| JWT_SECRET | `<base64-encoded JWT signing key>` | Secret key for Better Auth JWT tokens |
| OPENAI_API_KEY | `<base64-encoded OpenAI API key>` | API key for OpenAI Agents SDK |

**Relationships**:
- Referenced by: `backend-deployment` (environment variables from secret)
- NOT stored in Git: Created manually via `kubectl create secret`
- Managed externally: User provides values before deployment

**Creation Command** (for users):
```bash
kubectl create secret generic todo-secrets \
  --from-literal=DATABASE_URL="$DATABASE_URL" \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  --from-literal=OPENAI_API_KEY="$OPENAI_API_KEY" \
  -n todo-app
```

---

### 1.7 Namespace Entity

**Name**: `todo-app`
**Purpose**: Logical isolation for Todo Chatbot resources

**Fields**:

| Label Key | Label Value |
|------------|---------------|
| name | `todo-app` |
| app.kubernetes.io/name | `todo-chatbot` |

**Contains**:
- `frontend-deployment`
- `backend-deployment`
- `frontend-service`
- `backend-service`
- `todo-config` (ConfigMap)
- `todo-secrets` (Secret)

---

## 2. Docker Image Entities

### 2.1 Frontend Docker Image Entity

**Name**: `todo-frontend`
**Base Image**: `node:22-alpine` (builder), `nginx:alpine` (runtime)
**Target Size**: < 250MB
**Architecture**: Multi-stage build

**Build Stages**:

**Stage 1: Builder**
| Instruction | Purpose |
|-------------|---------|
| FROM node:22-alpine | Base image for building |
| WORKDIR /app | Working directory |
| COPY package*.json ./ | Copy dependency files |
| RUN npm ci | Install production dependencies |
| COPY . . | Copy application code |
| RUN npm run build | Build Next.js application |

**Stage 2: Runtime**
| Instruction | Purpose |
|-------------|---------|
| FROM nginx:alpine | Minimal runtime base |
| WORKDIR /usr/share/nginx/html | Nginx root |
| COPY --from=builder /app/.next/standalone ./ | Copy compiled assets |
| COPY --from=builder /app/public ./public | Copy static files |
| COPY nginx.conf /etc/nginx/nginx.d/default.conf | Nginx configuration |
| EXPOSE 3000 | Expose application port |
| USER 1001 | Non-root user for security |

**Environment Variables**:
- `NODE_ENV`: `production`
- `PORT`: `3000`

**Health Check**:
- **Docker HEALTHCHECK**: `CMD ["wget", "--spider", "-q", "--tries=1", "http://localhost:3000/"]`
- **Interval**: 30s
- **Timeout**: 3s
- **Retries**: 3

---

### 2.2 Backend Docker Image Entity

**Name**: `todo-backend`
**Base Image**: `python:3.13-slim`
**Target Size**: < 250MB
**Architecture**: Multi-stage build

**Build Stages**:

**Stage 1: Builder**
| Instruction | Purpose |
|-------------|---------|
| FROM python:3.13-slim | Base image for building |
| WORKDIR /app | Working directory |
| COPY requirements.txt . | Copy dependencies |
| RUN pip install --no-cache-dir -r requirements.txt | Install Python packages |
| COPY . . | Copy application code |

**Stage 2: Runtime**
| Instruction | Purpose |
|-------------|---------|
| FROM python:3.13-slim | Minimal runtime base |
| WORKDIR /app | Working directory |
| COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages | Copy installed packages |
| COPY --from=builder /app ./ | Copy application code |
| RUN useradd -m -u 1001 appuser | Create non-root user |
| USER appuser | Switch to non-root user |
| EXPOSE 8000 | Expose application port |

**Environment Variables**:
- `PYTHONUNBUFFERED`: `1` (for immediate log output)
- `ENVIRONMENT`: `production`
- `PORT`: `8000`

**Health Check**:
- **Docker HEALTHCHECK**: `CMD ["curl", "-f", "http://localhost:8000/health"]`
- **Interval**: 30s
- **Timeout**: 3s
- **Retries**: 3

---

## 3. Configuration Schema

### 3.1 Helm Values Schema

**File**: `charts/todo-chatbot/values.yaml`

**Schema**:

```yaml
# Global settings
global:
  environment: production  # string: production | development
  namespace: todo-app       # string: Kubernetes namespace

# Backend deployment
backend:
  enabled: true               # boolean: Enable/disable backend
  replicaCount: 1             # integer: Number of replicas
  image:
    repository: todo-backend  # string: Docker image name
    tag: v1.0.0           # string: Image version
    pullPolicy: Never        # string: Never | IfNotPresent | Always
  service:
    type: ClusterIP         # string: Service type
    port: 8000             # integer: Container port
  resources:
    requests:
      cpu: 100m             # string: CPU request
      memory: 128Mi         # string: Memory request
    limits:
      cpu: 500m             # string: CPU limit
      memory: 512Mi         # string: Memory limit
  health:
    liveness:
      path: /health         # string: Health check endpoint
      initialDelaySeconds: 10 # integer: Startup grace period
      periodSeconds: 15      # integer: Check interval
      timeoutSeconds: 5       # integer: Check timeout
      failureThreshold: 3     # integer: Failures before restart
    readiness:
      path: /health         # string: Readiness endpoint
      initialDelaySeconds: 5  # integer: Startup grace period
      periodSeconds: 10      # integer: Check interval
      timeoutSeconds: 3       # integer: Check timeout
      failureThreshold: 3     # integer: Failures before not-ready

# Frontend deployment
frontend:
  enabled: true               # boolean: Enable/disable frontend
  replicaCount: 1             # integer: Number of replicas
  image:
    repository: todo-frontend # string: Docker image name
    tag: v1.0.0           # string: Image version
    pullPolicy: Never        # string: Never | IfNotPresent | Always
  service:
    type: NodePort          # string: Service type
    port: 3000             # integer: Container port
    nodePort: 30000        # integer: Host port (30000-32767)
  resources:
    requests:
      cpu: 100m             # string: CPU request
      memory: 128Mi         # string: Memory request
    limits:
      cpu: 500m             # string: CPU limit
      memory: 256Mi         # string: Memory limit
  health:
    liveness:
      path: /               # string: Health check endpoint
      initialDelaySeconds: 10 # integer: Startup grace period
      periodSeconds: 15      # integer: Check interval
      timeoutSeconds: 5       # integer: Check timeout
      failureThreshold: 3     # integer: Failures before restart
    readiness:
      path: /               # string: Readiness endpoint
      initialDelaySeconds: 5  # integer: Startup grace period
      periodSeconds: 10      # integer: Check interval
      timeoutSeconds: 3       # integer: Check timeout
      failureThreshold: 3     # integer: Failures before not-ready

# Configuration (ConfigMap)
config:
  backendUrl: http://backend-service:8000  # string: Backend service URL
  frontendUrl: http://frontend-service:3000 # string: Frontend service URL
  corsOrigins: '["http://localhost:3000", "http://localhost:30000"]' # array: Allowed CORS origins
  logLevel: info                         # string: Logging level
```

---

### 3.2 Environment Variable Schema

**Frontend Container**:

| Variable | Source | Description |
|----------|---------|-------------|
| NODE_ENV | ConfigMap | Node.js environment (production) |
| NEXT_PUBLIC_API_URL | ConfigMap | Backend API base URL for frontend |
| PORT | ConfigMap | Application port (3000) |

**Backend Container**:

| Variable | Source | Description |
|----------|---------|-------------|
| PYTHONUNBUFFERED | Hardcoded (in Dockerfile) | Immediate log output |
| ENVIRONMENT | ConfigMap | Application environment (production) |
| PORT | ConfigMap | Application port (8000) |
| DATABASE_URL | Secret | Neon PostgreSQL connection string |
| JWT_SECRET | Secret | JWT signing key for Better Auth |
| OPENAI_API_KEY | Secret | OpenAI API key for Agents SDK |
| CORS_ORIGINS | ConfigMap | Allowed frontend origins |

---

## 4. Entity Relationships

```
┌─────────────────────────────────────────────────────────────────┐
│ Namespace: todo-app                                  │
└─────────────────────────────────────────────────────────────────┘
    │
    ├─┐
    │ ┌─────────────────────┐
    │ │ Frontend Service   │ (NodePort: 30000)
    │ └────────┬────────────┘
    │          │ selects
    │ ┌────────▼─────────┐
    │ │ Frontend          │ (1 replica)
    │ │ Deployment        │ (Image: todo-frontend:v1.0.0)
    │ └────────┬─────────┘
    │          │ reads config
    │ ┌────────▼─────────┐
    │ │ ConfigMap          │ (LOG_LEVEL, API_URL, CORS)
    │ └────────────────────┘
    │
    └─→ Communicates via HTTP →
         ┌─────────────────────┐
         │ Backend Service    │ (ClusterIP)
         └────────┬────────────┘
                  │ selects
                  ┌────────▼─────────┐
                  │ Backend            │ (1 replica)
                  │ Deployment        │ (Image: todo-backend:v1.0.0)
                  └────────┬─────────┘
                           │ reads config + secret
                      ┌────────▼───────┐ ┌──────────────────┐
                      │ ConfigMap       │ │ Secret         │
                      │ (PORT, ENV)    │ │ (DATABASE_URL, │
                      └──────────────────┘ │ JWT_SECRET,    │
                                              │ OPENAI_API_KEY) │
                                              └──────────────────┘
                                                   │
                                                   └─→ Connects to External
                                                      Neon PostgreSQL
```

---

## 5. Validation Rules

### 5.1 Kubernetes Entity Validation

**Namespace**:
- Must exist before deploying resources
- Must have label `app.kubernetes.io/name: todo-chatbot`

**Deployments**:
- Must have matching selector labels to Service
- Must have `spec.replicas` >= 1
- Must have resource requests/limits defined
- Must have liveness and readiness probes configured

**Services**:
- Must have `spec.selector` matching Deployment labels
- Must have `spec.ports` matching Deployment container ports
- Frontend Service type must be NodePort (for local access)
- Backend Service type must be ClusterIP (for internal-only access)

**ConfigMaps**:
- Must not contain sensitive data (no credentials, API keys)
- Must be referenced by Deployments via `envFrom`
- Must have all required keys for application startup

**Secrets**:
- Must be created manually (not in Helm chart or Git)
- Must contain all sensitive keys (DATABASE_URL, JWT_SECRET, OPENAI_API_KEY)
- Must be referenced by Deployments via `envFrom`

### 5.2 Docker Image Validation

**Frontend Image**:
- Total size < 250MB
- Must have non-root user (UID >= 1000)
- Must expose port 3000
- Must have HEALTHCHECK instruction

**Backend Image**:
- Total size < 250MB
- Must have non-root user (UID >= 1000)
- Must expose port 8000
- Must have HEALTHCHECK instruction

### 5.3 Configuration Validation

**Helm Values**:
- All required keys must have default values
- Type annotations must match expected types (integer, string, boolean)
- No sensitive data in ConfigMap values
- Secret references must be valid (not hardcoded)

---

## 6. State Transitions

### 6.1 Pod Lifecycle States

**Frontend/Backend Pod**:
```
Pending → Running
    │
    ├─→ Failed (image pull error, config error)
    ├─→ CrashLoopBackOff (health probe failure, app crash)
    └─→ Succeeded (deletion)

Running → Failed
    │
    ├─→ OOMKilled (memory limit exceeded)
    ├─→ Killed (resource eviction)
    └─→ Terminating (deletion request)

Running → Ready
    │
    └─→ Ready (readiness probe passing)
```

### 6.2 Service State Transitions

**Service**:
```
Creating → Active (endpoints available)
    │
    └─→ Terminating (deletion)
```

### 6.3 Deployment State Transitions

**Deployment**:
```
Available (all replicas ready)
    │
    ├─→ Progressing (rolling update)
    ├─→ Unavailable (replicas failing)
    └─→ Terminating (deletion)
```

---

## Summary

This data model defines:
- 7 Kubernetes entities (2 deployments, 2 services, ConfigMap, Secret, Namespace)
- 2 Docker image entities (frontend, backend) with multi-stage build specifications
- 1 Helm values schema with all configurable parameters
- Complete entity relationships showing configuration flow
- Validation rules for all entity types

All entities follow Kubernetes and Helm best practices while maintaining strict separation between sensitive (Secrets) and non-sensitive (ConfigMaps) configuration data.
