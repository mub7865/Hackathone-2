# Research: Kubernetes Minikube Deployment for Todo Chatbot

**Feature**: 008-k8s-minikube-deployment
**Date**: 2025-12-28
**Status**: Complete

## Overview

This research document captures architectural decisions, technical choices, and trade-offs for deploying the Phase III Todo Chatbot application (Next.js frontend + FastAPI backend with OpenAI Agents SDK + MCP) to a local Minikube Kubernetes cluster. The research follows the **research-concurrent approach**, documenting decisions as they are investigated rather than all upfront.

---

## 1. Docker Image Optimization Strategy

### Decision: Multi-Stage Builds with Alpine/Slim Base Images

**Chosen Approach**:
- **Frontend (Next.js)**: Multi-stage build with `node:22-alpine` as base, `nginx:alpine` for runtime
- **Backend (FastAPI)**: Multi-stage build with `python:3.13-slim` as base, minimal runtime stage

### Rationale

**Frontend Next.js**:
- Alpine Linux significantly reduces image size (Alpine ~5MB vs Debian ~100MB base)
- Multi-stage build separates build dependencies from runtime
- Builder stage includes: Node.js, npm, build tools
- Runtime stage includes: Only nginx and compiled Next.js assets
- Target image size: < 250MB

**Backend FastAPI**:
- Python 3.13-slim provides smaller footprint than full Python image (~50MB vs ~900MB)
- Multi-stage build excludes build tools from final image
- Builder stage includes: Python, pip, wheel, dev dependencies
- Runtime stage includes: Only Python runtime and production dependencies
- Target image size: < 250MB

### Alternatives Considered

| Alternative | Pros | Cons | Decision |
|-------------|-------|-------|-----------|
| Full Debian base images | More package compatibility | Image size > 800MB | Rejected (exceeds 500MB limit) |
| Python 3.13-alpine | Smallest base (~40MB) | Many Python packages require C compilation, wheel compatibility issues | Rejected (compatibility risk) |
| Single-stage builds | Simpler Dockerfile | Image size includes build tools (~400MB+) | Rejected (exceeds limit) |
| Multi-stage with distroless | Extremely small runtime | Complex setup, may break package imports | Rejected (too complex) |

### Optimization Techniques Applied

1. **.dockerignore files** to exclude unnecessary files:
   - `node_modules/`, `.next/`, `.git/`, `__pycache__/`
   - Documentation, test files, development configs

2. **Next.js Standalone Mode**:
   ```javascript
   // next.config.ts
   export default {
     output: 'standalone',
   // ... other config
   }
   ```
   - Only includes minimal runtime files
   - Reduces final image size by ~100MB

3. **Dependency Pruning**:
   - Use `--no-cache-dir` in pip install
   - Use `npm ci` for deterministic, smaller installs
   - Remove package manager caches

4. **Non-Root User**:
   - Add user in Dockerfile: `RUN useradd -m -u 1001 appuser`
   - `USER appuser` before building
   - Security best practice

---

## 2. Helm Chart Structure and Component Organization

### Decision: Single Multi-Component Chart with Separated Templates

**Chosen Structure**:
```
charts/todo-chatbot/
├── Chart.yaml
├── values.yaml
├── .helmignore
├── templates/
│   ├── _helpers.tpl         # Template helpers
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml           # Reference only (created via kubectl)
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   └── frontend-service.yaml
└── NOTES.txt               # Post-installation instructions
```

### Rationale

**Single Chart**:
- Single `helm install` command deploys entire stack
- Shared configuration in one `values.yaml`
- Coordinated updates (front + back together)
- Simplifies version management

**Separated Templates**:
- Clear separation between frontend and backend resources
- Easy to understand and modify individually
- Follows Helm best practices for multi-component charts
- Enables independent component scaling via values

**_helpers.tpl**:
- Centralized template functions for labels, names, selectors
- Ensures consistency across all resources
- Reduces duplication in templates

**NOTES.txt**:
- Provides user-friendly post-installation instructions
- Includes commands to access services
- Documents troubleshooting steps

### Alternatives Considered

| Alternative | Pros | Cons | Decision |
|-------------|-------|-------|-----------|
| Two separate charts (frontend, backend) | Independent updates | Two helm installs required, harder coordination | Rejected (coordination complexity) |
| Single monolithic template | Simple file | Difficult to maintain, low reusability | Rejected (maintainability) |
| Chart dependencies (parent chart with subcharts) | More structured | Overkill for 2 components, adds complexity | Rejected (over-engineering) |

---

## 3. Kubernetes Resource Allocation (CPU/Memory Requests/Limits)

### Decision: Development-Scale Resource Allocation

**Chosen Values**:

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------------|--------------|------------|-----------------|----------------|
| Frontend | 100m | 500m | 128Mi | 256Mi |
| Backend | 100m | 500m | 128Mi | 512Mi |

### Rationale

**Requests (Guaranteed Resources)**:
- 100m CPU = 0.1 vCPU (sufficient for dev load)
- 128Mi memory (minimum for Node.js/FastAPI to start)
- Ensures pods can schedule and run reliably
- Prevents resource contention on developer machine

**Limits (Maximum Resources)**:
- 500m CPU = 0.5 vCPU (headroom for bursts)
- 256Mi/512Mi memory (reasonable ceiling for development)
- Prevents runaway containers from consuming all resources
- Minikube typically has 2-4 CPUs available, this is safe

**Why These Specific Values**:
- **CPU 100m**: Node.js/FastAPI are I/O bound, CPU light
- **Memory 128Mi**: Next.js + FastAPI base ~50-80Mi, 128Mi provides buffer
- **CPU Limit 500m**: Allows 5x burst capacity for initialization
- **Memory Limit 256Mi (frontend)**: Next.js runtime ~120Mi with headroom
- **Memory Limit 512Mi (backend)**: Python + OpenAI SDK + MCP ~300Mi with headroom

### Alternatives Considered

| Alternative | Pros | Cons | Decision |
|-------------|-------|-------|-----------|
| No requests/limits | Simplest | Pods can consume all resources, OOM kills | Rejected (unstable) |
| High limits (2 CPU, 4GB) | No throttling | Wastes Minikube resources, may fail to schedule | Rejected (inefficient) |
| Production limits (4 CPU, 8GB) | Production-ready | Overkill for local dev, wastes resources | Rejected (over-engineering) |

---

## 4. Service Type Selection (NodePort vs LoadBalancer vs Ingress)

### Decision: NodePort for Frontend, ClusterIP for Backend

**Chosen Configuration**:
- **Frontend Service**: NodePort (port 30000 in 30000-32767 range)
- **Backend Service**: ClusterIP (internal-only, port 8000)

### Rationale

**Frontend NodePort**:
- Minikube assigns fixed accessible port on host machine
- Simple access: `http://$(minikube ip):<nodePort>`
- No additional tunneling required (unlike LoadBalancer)
- Works reliably on all platforms (Windows, macOS, Linux)
- Standard for local development patterns

**Backend ClusterIP**:
- Frontend communicates via Kubernetes service discovery: `http://backend-service:8000`
- Internal-only access improves security
- No need for external exposure (API not public in dev)
- Follows microservice best practices

### Service Discovery

Frontend connects to backend using:
```typescript
// Frontend environment variable
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://backend-service:8000'
```

Backend service DNS resolution within cluster:
- `backend-service.todo-app.svc.cluster.local`
- Configured via `selector` in Service spec
- Automatically handles pod IP changes

### Alternatives Considered

| Alternative | Pros | Cons | Decision |
|-------------|-------|-------|-----------|
| LoadBalancer (both) | Cloud-native behavior | Minikube requires `minikube tunnel`, slower | Rejected (complex for local dev) |
| Ingress Controller | Single entry point, URL routing | Requires additional setup (nginx-ingress), complexity | Rejected (over-engineering for 2 services) |
| All NodePort | Simpler | Exposes backend externally (security risk) | Rejected (security) |

### Migration Path to Production (Phase V)

For Phase V cloud deployment, values.yaml will support:
- Frontend: LoadBalancer or Ingress
- Backend: LoadBalancer (behind auth gateway)
- Maintain same service discovery patterns

---

## 5. Health Probe Configuration Strategies

### Decision: Conservative Liveness and Readiness Probes

**Chosen Configuration**:

| Probe | Frontend (/) | Backend (/health) | Rationale |
|--------|------------------|---------------------|------------|
| Liveness | 10s initialDelay, 15s period, 5s timeout, 3 failures | 10s initialDelay, 15s period, 5s timeout, 3 failures | Allows startup, detects hangs, avoids flapping |
| Readiness | 5s initialDelay, 10s period, 3s timeout, 3 failures | 5s initialDelay, 10s period, 3s timeout, 3 failures | Faster to ready, ensures traffic only when able |
| HTTP GET | / | /health | Simple, standard endpoint |

### Rationale

**Separate Liveness vs Readiness**:
- **Liveness**: Detects hung containers and restarts them
- **Readiness**: Detects when app can serve traffic, removes from endpoints
- Independent configurations for different use cases

**Frontend (/) Path**:
- Next.js root endpoint is minimal fast response
- Indicates server is running and can serve static assets
- No authentication required (avoids probe auth failures)

**Backend (/health) Path**:
- FastAPI can include simple health endpoint
- Returns `{"status": "ok"}` or HTTP 200
- Can optionally check database connectivity

**Conservative Timing**:
- **initialDelaySeconds**: 10s (liveness), 5s (readiness)
  - FastAPI: ~2-3s startup, 5s buffer sufficient
  - Next.js: ~3-5s startup, 5s buffer sufficient
- **periodSeconds**: 15s (liveness), 10s (readiness)
  - Frequent enough to detect failures quickly
  - Not so frequent to cause unnecessary load
- **failureThreshold**: 3
  - Prevents flapping from transient network issues
  - After 3 consecutive failures, takes action

### Alternatives Considered

| Alternative | Pros | Cons | Decision |
|-------------|-------|-------|-----------|
| TCP probes | Faster | Doesn't test HTTP layer, less diagnostic | Rejected (less informative) |
| Exec probes (command) | Tests internal state | Less portable, requires in-container tools | Rejected (less standard) |
| Startup probe | Separate startup logic | Adds complexity, not needed with reasonable initialDelay | Rejected (unnecessary) |
| Aggressive timing (1s period) | Faster failure detection | Higher risk of flapping pods | Rejected (unstable) |

---

## 6. Secret vs ConfigMap Usage Boundaries

### Decision: Manual kubectl Secrets for Sensitive Data, ConfigMaps for Configuration

**Chosen Separation**:

**Kubernetes Secrets (created via kubectl)**:
- `DATABASE_URL`: Neon PostgreSQL connection string
- `JWT_SECRET`: JWT signing key for Better Auth
- `OPENAI_API_KEY`: OpenAI API key for Agents SDK

**ConfigMaps (from Helm values)**:
- `LOG_LEVEL`: Application logging level (info, debug, error)
- `ENVIRONMENT`: Environment name (production, development)
- `CORS_ORIGINS`: Allowed frontend origins
- `BACKEND_URL`: Backend service URL for frontend
- `FRONTEND_URL`: Frontend service URL for backend
- `PORT`: Application ports

### Rationale

**Secrets (Sensitive Data)**:
- **Security**: Secrets are base64 encoded, stored encrypted at rest (Kubernetes)
- **Separation of Concerns**: Created manually before deployment, not in Git
- **Audit Trail**: kubectl commands logged, track who created secrets
- **Rotation**: Can update secrets via `kubectl patch secret`
- **Prevention**: Impossible to accidentally commit secrets to version control

**ConfigMaps (Non-Sensitive)**:
- **Visibility**: Stored in plain text in Helm chart, easy to debug
- **Configuration Management**: Updated via Helm values or ConfigMap patch
- **Version Control**: Safe to commit to Git (no sensitive data)
- **Flexibility**: Easy to modify without recreating secrets

### Secret Management Workflow

```bash
# Prerequisite: User must create secrets before Helm install
kubectl create secret generic todo-secrets \
  --from-literal=DATABASE_URL="$DATABASE_URL" \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  --from-literal=OPENAI_API_KEY="$OPENAI_API_KEY" \
  -n todo-app

# Helm template references secret (NOT values)
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: todo-secrets
        key: DATABASE_URL
```

### Alternatives Considered

| Alternative | Pros | Cons | Decision |
|-------------|-------|-------|-----------|
| Secrets in values.yaml | Simpler workflow | Secrets committed to Git (security risk) | Rejected (security violation) |
| External secret manager (HashiCorp Vault) | More secure | Overkill for local dev, adds infrastructure | Rejected (over-engineering) |
| Sealed Secrets (Helm secrets) | Versioned secrets | Requires SealedKeys management, complex setup | Rejected (too complex) |
| Environment variables in shell | Easiest | Not portable, requires manual setup each session | Rejected (not reproducible) |

---

## 7. Minikube Performance and Startup Configuration

### Decision: Docker Driver with 4 CPU, 4GB Memory

**Chosen Configuration**:
```bash
minikube start \
  --driver=docker \
  --cpus=4 \
  --memory=4096 \
  --disk-size=50GB
```

### Rationale

**Docker Driver**:
- Most widely supported (works on Docker Desktop)
- Fastest startup (no VM overhead like VirtualBox driver)
- Best performance on Windows with WSL2
- Standard for local Kubernetes development

**Resource Allocation**:
- **4 CPUs**: Sufficient for 2 deployments + Minikube overhead
- **4GB RAM**: Frontend (~200Mi) + Backend (~300Mi) + headroom
- **50GB Disk**: Space for Docker images, Minikube, and applications

**Startup Optimization**:
- Disable unnecessary addons: `--addons=registry` (default), avoid dashboard during startup
- Use pre-pulled base images: `--preload-images=true` (optional)
- Profile-based startup: `minikube profile todo-dev` to persist settings

### Target Startup Time: < 5 minutes

**Startup Breakdown**:
1. Minikube init: 30s
2. Download Docker images (first run): 60-90s
3. Boot Kubernetes: 60s
4. Wait for cluster ready: 30s
5. **Total**: ~3-4 minutes (subsequent runs faster due to cached images)

### Alternatives Considered

| Alternative | Pros | Cons | Decision |
|-------------|-------|-------|-----------|
| VirtualBox driver | Platform independence | Slower, additional VM overhead | Rejected (performance) |
| Hyper-V driver | Windows native | Requires Pro edition, complex setup | Rejected (complexity) |
| Minimal resources (2 CPU, 2GB) | Faster startup | Unstable for our applications | Rejected (unstable) |

---

## 8. Kubernetes Deployment Validation Strategies

### Decision: Multi-Layer Validation Approach

**Chosen Validation Layers**:

1. **Helm Template Validation**:
   ```bash
   helm lint charts/todo-chatbot/
   helm template todo --debug charts/todo-chatbot/
   ```
   - Validates YAML syntax before deployment
   - Renders templates to verify output

2. **Kubernetes Manifest Validation**:
   ```bash
   kubectl apply --dry-run=client -f charts/todo-chatbot/templates/backend-deployment.yaml
   ```
   - Validates against Kubernetes API server
   - Detects API version mismatches

3. **Deployment Success Validation**:
   ```bash
   helm install todo charts/todo-chatbot/ -n todo-app --wait
   kubectl get all -n todo-app
   ```
   - Waits for all resources to be ready
   - Verifies created resources match expected

4. **Pod Health Validation**:
   ```bash
   kubectl wait --for=condition=ready pod -l app=backend -n todo-app --timeout=300s
   kubectl wait --for=condition=ready pod -l app=frontend -n todo-app --timeout=300s
   ```
   - Waits for pods to transition to Ready
   - 5 minute timeout per success criteria

5. **Functional Validation**:
   ```bash
   kubectl exec deployment/frontend -n todo-app -- curl http://backend-service:8000/health
   minikube service list -n todo-app
   ```
   - Verifies inter-pod communication
   - Tests service accessibility

### Rationale

**Layered Validation**:
- **Fast Fail**: Catch issues early (template errors, YAML syntax)
- **Comprehensive**: Tests infrastructure, configuration, and functionality
- **Automated**: Can be scripted for CI/CD (future)
- **Debuggable**: Each layer provides specific error information

### Success Criteria Mapping

| Success Criteria | Validation Method | Test Command |
|-----------------|-------------------|---------------|
| SC-001: Minikube < 5 min | Time measurement | `time minikube start` |
| SC-002: Images < 500MB | Image size check | `docker images --format "{{.Size}}"` |
| SC-003: Helm < 2 min | Time measurement | `time helm install` |
| SC-004: Pods Running in 5 min | Pod status wait | `kubectl wait --for=condition=ready pod` |
| SC-005: Browser accessible | Service list + curl | `minikube service list`, `curl http://...` |
| SC-006: Frontend connects to backend | Pod exec | `kubectl exec frontend -- curl backend` |
| SC-007: Task lifecycle works | Manual testing | Browser automation or manual test |
| SC-008: All features work | Feature checklist | Manual verification |

---

## Summary of Architectural Decisions

| # | Decision | Rationale | Trade-offs |
|---|----------|------------|--------------|
| 1 | Multi-stage Docker builds with Alpine/slim base | Reduces image size under 500MB | More complex Dockerfiles |
| 2 | Single multi-component Helm chart | Coordinated deployment, simple management | Less independent scaling |
| 3 | Dev-scale resources (100m CPU, 128Mi mem) | Reliable on local machines | Not production-ready |
| 4 | NodePort frontend, ClusterIP backend | Simple local access, secure backend | Requires change for cloud |
| 5 | Conservative health probes (10s/5s delay) | Stable, no flapping | Slower failure detection |
| 6 | Manual kubectl secrets for sensitive data | Secure, no secrets in Git | Extra deployment step |
| 7 | Docker driver, 4CPU, 4GB RAM | Fast startup, sufficient resources | Higher machine requirements |
| 8 | Multi-layer validation (Helm, K8s, pods, functional) | Comprehensive error detection | More complex testing |

---

## Recommendations for Implementation

Based on this research, the following recommendations guide implementation:

1. **Create Dockerfiles First**: Start with multi-stage builds, test image sizes locally
2. **Implement Health Endpoints**: Add `/health` endpoint to backend if missing
3. **Build Helm Chart**: Follow the documented structure with templates and values
4. **Document Secret Creation**: Provide clear kubectl commands in quickstart.md
5. **Test Iteratively**: Validate each layer before proceeding to the next
6. **Monitor Resource Usage**: Use `minikube addons enable metrics-server` during development

---

## References

- Docker Best Practices: Docker official documentation
- Helm Chart Guide: Helm documentation on chart structure and best practices
- Kubernetes Patterns: kubernetes-deployment-patterns skill
- Minikube Setup: minikube-local-development skill
- Multi-Stage Builds: docker-containerization skill
- Health Probes: Kubernetes documentation on liveness/readiness probes
