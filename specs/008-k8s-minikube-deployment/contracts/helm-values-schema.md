# Helm Values Schema

**Feature**: 008-k8s-minikube-deployment
**Date**: 2025-12-28
**Status**: Complete

## Overview

This document defines the complete schema for `charts/todo-chatbot/values.yaml`. It specifies all configurable parameters, their types, default values, validation rules, and usage descriptions. This schema serves as the contract between Helm chart users and the chart itself.

---

## 1. Global Configuration

```yaml
global:
  # Environment name (used for labels, configuration)
  # Type: string
  # Default: "production"
  # Validation: Must be one of [production, development, staging]
  environment: production

  # Kubernetes namespace for deployment
  # Type: string
  # Default: "todo-app"
  # Validation: Valid Kubernetes namespace name (lowercase, alphanumeric, hyphens)
  namespace: todo-app
```

---

## 2. Frontend Configuration

```yaml
frontend:
  # Enable/disable frontend deployment
  # Type: boolean
  # Default: true
  enabled: true

  # Number of frontend pod replicas
  # Type: integer
  # Default: 1
  # Validation: Must be >= 0
  # Usage: For scaling frontend horizontally
  replicaCount: 1

  image:
    # Docker image repository name
    # Type: string
    # Default: "todo-frontend"
    # Usage: Change when pushing to a registry
    repository: todo-frontend

    # Docker image tag
    # Type: string
    # Default: "v1.0.0"
    # Usage: Update for new releases
    tag: v1.0.0

    # Kubernetes image pull policy
    # Type: string
    # Default: "Never"
    # Validation: Must be one of [Always, IfNotPresent, Never]
    # Note: "Never" is for local Minikube images; use "IfNotPresent" for registry images
    pullPolicy: Never

  service:
    # Kubernetes service type
    # Type: string
    # Default: "NodePort"
    # Validation: Must be one of [ClusterIP, NodePort, LoadBalancer]
    # Note: NodePort for Minikube local access; LoadBalancer for cloud
    type: NodePort

    # Container port exposed by the application
    # Type: integer
    # Default: 3000
    # Validation: Must be in 1-65535 range
    port: 3000

    # NodePort for external access (NodePort type only)
    # Type: integer
    # Default: 30000
    # Validation: Must be in 30000-32767 range for NodePort
    # Note: Fixed port simplifies access in local development
    nodePort: 30000

  # Kubernetes resource requests and limits
  # Type: object
  resources:
    requests:
      # Guaranteed CPU resources
      # Type: string (Kubernetes format: number followed by unit)
      # Default: "100m" (0.1 CPU cores)
      # Validation: Must match pattern `^[0-9]+(\.[0-9]+)?(m|[u]?)$`
      cpu: 100m

      # Guaranteed memory resources
      # Type: string (Kubernetes format: number followed by unit)
      # Default: "128Mi"
      # Validation: Must match pattern `^[0-9]+(\.[0-9]+)?(Ei|Pi|Ti|Gi|Mi|Ki|E|P|T|G|M|K)$`
      memory: 128Mi

    limits:
      # Maximum CPU resources
      # Type: string (Kubernetes format)
      # Default: "500m" (0.5 CPU cores)
      # Validation: Must match Kubernetes resource format
      cpu: 500m

      # Maximum memory resources
      # Type: string (Kubernetes format)
      # Default: "256Mi"
      # Validation: Must match Kubernetes resource format
      memory: 256Mi

  # Health probe configuration
  # Type: object
  health:
    liveness:
      # HTTP path for liveness probe
      # Type: string
      # Default: "/"
      # Note: Must return HTTP 200-399 for pod to be considered alive
      path: /

      # Delay before starting liveness probe after pod starts
      # Type: integer (seconds)
      # Default: 10
      # Usage: Allow application to initialize before health checks
      initialDelaySeconds: 10

      # Interval between liveness probe checks
      # Type: integer (seconds)
      # Default: 15
      initialPeriodSeconds: 15

      # Timeout for liveness probe response
      # Type: integer (seconds)
      # Default: 5
      timeoutSeconds: 5

      # Number of consecutive failures before considering pod unhealthy
      # Type: integer
      # Default: 3
      # Note: Pod will be restarted if threshold exceeded
      failureThreshold: 3

    readiness:
      # HTTP path for readiness probe
      # Type: string
      # Default: "/"
      # Note: Must return HTTP 200-399 for pod to receive traffic
      path: /

      # Delay before starting readiness probe after pod starts
      # Type: integer (seconds)
      # Default: 5
      # Note: Shorter than liveness delay for faster traffic routing
      initialDelaySeconds: 5

      # Interval between readiness probe checks
      # Type: integer (seconds)
      # Default: 10
      periodSeconds: 10

      # Timeout for readiness probe response
      # Type: integer (seconds)
      # Default: 3
      timeoutSeconds: 3

      # Number of consecutive failures before considering pod not ready
      # Type: integer
      # Default: 3
      # Note: Pod removed from service endpoints if threshold exceeded
      failureThreshold: 3
```

---

## 3. Backend Configuration

```yaml
backend:
  # Enable/disable backend deployment
  # Type: boolean
  # Default: true
  enabled: true

  # Number of backend pod replicas
  # Type: integer
  # Default: 1
  # Validation: Must be >= 0
  # Usage: For scaling backend horizontally
  replicaCount: 1

  image:
    # Docker image repository name
    # Type: string
    # Default: "todo-backend"
    # Usage: Change when pushing to a registry
    repository: todo-backend

    # Docker image tag
    # Type: string
    # Default: "v1.0.0"
    # Usage: Update for new releases
    tag: v1.0.0

    # Kubernetes image pull policy
    # Type: string
    # Default: "Never"
    # Validation: Must be one of [Always, IfNotPresent, Never]
    # Note: "Never" is for local Minikube images; use "IfNotPresent" for registry images
    pullPolicy: Never

  service:
    # Kubernetes service type
    # Type: string
    # Default: "ClusterIP"
    # Validation: Must be one of [ClusterIP, NodePort, LoadBalancer]
    # Note: ClusterIP for internal-only access; NodePort/LoadBalancer for external
    type: ClusterIP

    # Container port exposed by the application
    # Type: integer
    # Default: 8000
    # Validation: Must be in 1-65535 range
    port: 8000

  # Kubernetes resource requests and limits
  # Type: object
  resources:
    requests:
      # Guaranteed CPU resources
      # Type: string (Kubernetes format)
      # Default: "100m"
      cpu: 100m

      # Guaranteed memory resources
      # Type: string (Kubernetes format)
      # Default: "128Mi"
      memory: 128Mi

    limits:
      # Maximum CPU resources
      # Type: string (Kubernetes format)
      # Default: "500m"
      cpu: 500m

      # Maximum memory resources
      # Type: string (Kubernetes format)
      # Default: "512Mi"
      # Note: Higher limit than frontend due to Python + OpenAI SDK + MCP
      memory: 512Mi

  # Health probe configuration
  # Type: object
  health:
    liveness:
      # HTTP path for liveness probe
      # Type: string
      # Default: "/health"
      # Note: FastAPI endpoint that returns {"status": "ok"}
      path: /health

      # Delay before starting liveness probe after pod starts
      # Type: integer (seconds)
      # Default: 10
      initialDelaySeconds: 10

      # Interval between liveness probe checks
      # Type: integer (seconds)
      # Default: 15
      periodSeconds: 15

      # Timeout for liveness probe response
      # Type: integer (seconds)
      # Default: 5
      timeoutSeconds: 5

      # Number of consecutive failures before considering pod unhealthy
      # Type: integer
      # Default: 3
      failureThreshold: 3

    readiness:
      # HTTP path for readiness probe
      # Type: string
      # Default: "/health"
      path: /health

      # Delay before starting readiness probe after pod starts
      # Type: integer (seconds)
      # Default: 5
      initialDelaySeconds: 5

      # Interval between readiness probe checks
      # Type: integer (seconds)
      # Default: 10
      periodSeconds: 10

      # Timeout for readiness probe response
      # Type: integer (seconds)
      # Default: 3
      timeoutSeconds: 3

      # Number of consecutive failures before considering pod not ready
      # Type: integer
      # Default: 3
      failureThreshold: 3
```

---

## 4. Configuration (ConfigMap)

```yaml
config:
  # Backend service URL for frontend to connect to
  # Type: string
  # Default: "http://backend-service:8000"
  # Validation: Valid URL format
  # Note: Uses Kubernetes service discovery for internal cluster communication
  backendUrl: http://backend-service:8000

  # Frontend service URL for backend to reference
  # Type: string
  # Default: "http://frontend-service:3000"
  # Validation: Valid URL format
  # Usage: Used for CORS origins, webhooks, etc.
  frontendUrl: http://frontend-service:3000

  # Allowed CORS origins (JSON array as string)
  # Type: string (JSON array)
  # Default: '["http://localhost:3000", "http://localhost:30000"]'
  # Validation: Must be valid JSON array of URLs
  # Usage: Configure which origins can make requests to backend
  corsOrigins: '["http://localhost:3000", "http://localhost:30000"]'

  # Application logging level
  # Type: string
  # Default: "info"
  # Validation: Must be one of [debug, info, warning, error, critical]
  # Usage: Control verbosity of application logs
  logLevel: info

  # Application environment identifier
  # Type: string
  # Default: "production"
  # Validation: Must be one of [production, development, staging]
  # Usage: Environment-specific behavior (e.g., debug mode)
  environment: production
```

---

## 5. Environment Variable Mapping

### Frontend Container Environment Variables

| Environment Variable | Source (Helm Value) | Purpose |
|---------------------|---------------------|---------|
| `NODE_ENV` | `config.environment` | Node.js runtime mode |
| `NEXT_PUBLIC_API_URL` | `config.backendUrl` | Backend API base URL for frontend |
| `PORT` | `frontend.service.port` | Application port |
| `LOG_LEVEL` | `config.logLevel` | Logging verbosity |

### Backend Container Environment Variables

| Environment Variable | Source (Helm Value) | Purpose |
|---------------------|---------------------|---------|
| `PYTHONUNBUFFERED` | Hardcoded in Dockerfile | Immediate log output |
| `ENVIRONMENT` | `config.environment` | Application environment |
| `PORT` | `backend.service.port` | Application port |
| `CORS_ORIGINS` | `config.corsOrigins` | Allowed CORS origins |
| `LOG_LEVEL` | `config.logLevel` | Logging verbosity |
| `DATABASE_URL` | Secret `todo-secrets` | Neon PostgreSQL connection |
| `JWT_SECRET` | Secret `todo-secrets` | JWT signing key |
| `OPENAI_API_KEY` | Secret `todo-secrets` | OpenAI API key |

---

## 6. Secrets Configuration (Reference Only)

Secrets are **NOT** stored in `values.yaml`. They must be created manually via kubectl:

```bash
# Create secrets before Helm install
kubectl create secret generic todo-secrets \
  --from-literal=DATABASE_URL="$DATABASE_URL" \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  --from-literal=OPENAI_API_KEY="$OPENAI_API_KEY" \
  -n todo-app
```

The Helm chart references these secrets in templates but does not include values.

---

## 7. Validation Patterns

### Kubernetes Resource Format

```regex
# CPU resources: number + optional unit
^[0-9]+(\.[0-9]+)?(m|[u]?)$

# Memory resources: number + unit
^[0-9]+(\.[0-9]+)?(Ei|Pi|Ti|Gi|Mi|Ki|E|P|T|G|M|K)$

# Kubernetes namespace: lowercase, alphanumeric, hyphens
^[a-z0-9]([-a-z0-9]*[a-z0-9])?$

# Docker image tag: v + numbers, or any valid tag
^(v[0-9]+\.[0-9]+\.[0-9]+|.+)$

# Port number: 1-65535
^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$

# NodePort: 30000-32767
^(3[0-9]{4}|3[0-1][0-9]{3}|32[0-6][0-9]{2}|327[0-5][0-9]|3276[0-7])$
```

### URL Format

```regex
# HTTP/HTTPS URL
^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$
```

### JSON Array Format

```regex
# JSON array (for corsOrigins)
^\[.*\]$
```

---

## 8. Example Usage

### Local Development (Minikube)

```yaml
# values-dev.yaml
global:
  environment: development
  namespace: todo-app

frontend:
  replicaCount: 1
  image:
    pullPolicy: Never  # Local images
  service:
    nodePort: 30000

backend:
  replicaCount: 1
  image:
    pullPolicy: Never  # Local images
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi

config:
  logLevel: debug
```

```bash
# Deploy with dev values
helm install todo charts/todo-chatbot/ \
  -n todo-app \
  -f values-dev.yaml
```

### Production (Cloud - Phase V)

```yaml
# values-prod.yaml
global:
  environment: production
  namespace: todo-app-prod

frontend:
  replicaCount: 3
  image:
    repository: registry.example.com/todo-frontend
    tag: v1.0.0
    pullPolicy: IfNotPresent  # From registry
  service:
    type: LoadBalancer  # Cloud LB
  resources:
    limits:
      cpu: 1000m
      memory: 512Mi

backend:
  replicaCount: 2
  image:
    repository: registry.example.com/todo-backend
    tag: v1.0.0
    pullPolicy: IfNotPresent  # From registry
  service:
    type: LoadBalancer  # Cloud LB
  resources:
    limits:
      cpu: 2000m
      memory: 1Gi

config:
  logLevel: info
  environment: production
```

```bash
# Deploy with prod values
helm install todo charts/todo-chatbot/ \
  -n todo-app-prod \
  -f values-prod.yaml
```

---

## Summary

This Helm values schema defines:
- Global configuration (environment, namespace)
- Frontend deployment configuration (image, service, resources, health probes)
- Backend deployment configuration (image, service, resources, health probes)
- ConfigMap configuration (URLs, CORS, logging)
- Secret reference pattern (not stored in values)
- Validation rules for all value types
- Environment variable mapping to Kubernetes containers
- Example usage for local dev and production

All values follow Helm best practices and are designed to be overridable via custom values files or command-line arguments (`--set`).
