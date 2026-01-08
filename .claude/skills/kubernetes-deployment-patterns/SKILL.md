---
name: kubernetes-deployment-patterns
description: >
  Complete patterns for deploying applications on Kubernetes: Deployments,
  Services, ConfigMaps, Secrets, health probes, resource management, and
  production-ready configurations for any application.
---

# Kubernetes Deployment Patterns Skill

## When to use this Skill

Use this Skill whenever you are:

- Creating Kubernetes manifests (YAML files) for applications.
- Deploying applications to Minikube, GKE, EKS, AKS, or any K8s cluster.
- Setting up Services to expose applications internally or externally.
- Managing configuration with ConfigMaps and Secrets.
- Configuring health checks (liveness, readiness, startup probes).
- Setting resource limits and requests for containers.
- Scaling applications with replicas or autoscaling.

This Skill works for **any** Kubernetes project, not just a single repository.

## Core Goals

- Create **production-ready** Kubernetes manifests.
- Follow **official Kubernetes best practices**.
- Implement proper **health checks** for reliability.
- Use **ConfigMaps and Secrets** for configuration management.
- Set appropriate **resource limits** for stability.
- Provide **consistent patterns** across different applications.

## Kubernetes Resource Basics

### Key Resources Overview

| Resource | Purpose | When to Use |
|----------|---------|-------------|
| **Pod** | Smallest unit, runs containers | Never create directly (use Deployment) |
| **Deployment** | Manages Pod replicas | Stateless applications |
| **Service** | Network access to Pods | Expose apps internally/externally |
| **ConfigMap** | Non-sensitive configuration | Environment variables, config files |
| **Secret** | Sensitive data | Passwords, API keys, certificates |
| **Namespace** | Logical isolation | Separate environments/teams |

### API Versions (Use Latest Stable)

```yaml
# Core resources
apiVersion: v1
kind: Pod/Service/ConfigMap/Secret/Namespace

# Apps resources
apiVersion: apps/v1
kind: Deployment/StatefulSet/DaemonSet

# Networking
apiVersion: networking.k8s.io/v1
kind: Ingress/NetworkPolicy

# Autoscaling
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
```

## Namespace

Always organize resources with namespaces.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: todo-app
  labels:
    app: todo
    environment: production
```

**Best Practices:**
- Use namespaces to separate environments (dev, staging, prod).
- Use namespaces to separate teams or projects.
- Never deploy to `default` namespace in production.

## Deployment

Deployment manages Pods and ensures desired replicas are running.

### Basic Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: todo-app
  labels:
    app: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: my-backend:v1.0.0
        ports:
        - containerPort: 8000
```

### Production Deployment (Complete)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: todo-app
  labels:
    app: backend
    version: v1.0.0
  annotations:
    kubernetes.io/description: "Backend API for Todo application"
spec:
  replicas: 3

  # Update strategy
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max extra pods during update
      maxUnavailable: 0  # Always keep all replicas available

  selector:
    matchLabels:
      app: backend

  template:
    metadata:
      labels:
        app: backend
        version: v1.0.0
    spec:
      # Security context
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001

      containers:
      - name: backend
        image: my-backend:v1.0.0
        imagePullPolicy: IfNotPresent

        ports:
        - containerPort: 8000
          protocol: TCP

        # Environment variables
        env:
        - name: PORT
          value: "8000"
        - name: NODE_ENV
          value: "production"

        # From ConfigMap
        envFrom:
        - configMapRef:
            name: backend-config

        # From Secret
        - secretRef:
            name: backend-secrets

        # Resource management
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"

        # Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 15
          timeoutSeconds: 5
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3

        startupProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 0
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 30  # 30 * 5s = 150s max startup time

      # Restart policy
      restartPolicy: Always

      # Termination grace period
      terminationGracePeriodSeconds: 30
```

### Key Deployment Fields

| Field | Description | Best Practice |
|-------|-------------|---------------|
| `replicas` | Number of Pod copies | Min 2-3 for production |
| `strategy` | How to update Pods | RollingUpdate for zero downtime |
| `selector` | How to find Pods | Must match template labels |
| `template` | Pod specification | Contains container config |

## Services

Services provide stable network access to Pods.

### Service Types Comparison

| Type | Use Case | Accessibility |
|------|----------|---------------|
| **ClusterIP** | Internal communication | Inside cluster only |
| **NodePort** | Development/testing | External via node IP:port |
| **LoadBalancer** | Production (cloud) | External via cloud LB |
| **ExternalName** | External service alias | DNS redirection |

### ClusterIP Service (Default)

For internal communication between services.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: todo-app
spec:
  type: ClusterIP  # Default, can be omitted
  selector:
    app: backend
  ports:
  - name: http
    port: 8000        # Service port
    targetPort: 8000  # Container port
    protocol: TCP
```

**Access**: `http://backend-service:8000` (from within cluster)

### NodePort Service

For external access in development/testing.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: todo-app
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - name: http
    port: 3000
    targetPort: 3000
    nodePort: 30000  # Fixed port (30000-32767)
    protocol: TCP
```

**Access**: `http://<node-ip>:30000`

For Minikube: `minikube service frontend-service -n todo-app`

### LoadBalancer Service

For production external access (cloud providers only).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-lb
  namespace: todo-app
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
  - name: http
    port: 80
    targetPort: 3000
    protocol: TCP
```

**Access**: External IP provided by cloud provider.

## ConfigMaps

Store non-sensitive configuration data.

### ConfigMap Definition

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: todo-app
data:
  # Simple key-value pairs
  APP_ENV: "production"
  LOG_LEVEL: "info"
  API_TIMEOUT: "30"

  # Multi-line config file
  config.json: |
    {
      "debug": false,
      "maxConnections": 100,
      "features": {
        "newUI": true
      }
    }
```

### Using ConfigMap as Environment Variables

**All keys from ConfigMap:**
```yaml
spec:
  containers:
  - name: backend
    envFrom:
    - configMapRef:
        name: backend-config
```

**Specific keys:**
```yaml
spec:
  containers:
  - name: backend
    env:
    - name: ENVIRONMENT
      valueFrom:
        configMapKeyRef:
          name: backend-config
          key: APP_ENV
```

### Using ConfigMap as Volume

```yaml
spec:
  containers:
  - name: backend
    volumeMounts:
    - name: config-volume
      mountPath: /app/config
      readOnly: true

  volumes:
  - name: config-volume
    configMap:
      name: backend-config
```

## Secrets

Store sensitive data (passwords, API keys, certificates).

### Creating Secrets

**Imperative (command line):**
```bash
kubectl create secret generic backend-secrets \
  --from-literal=DATABASE_URL="postgresql://user:pass@host/db" \
  --from-literal=API_KEY="sk-secret-key" \
  -n todo-app
```

**Declarative (YAML with base64):**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: backend-secrets
  namespace: todo-app
type: Opaque
data:
  # Values must be base64 encoded
  # echo -n "postgresql://user:pass@host/db" | base64
  DATABASE_URL: cG9zdGdyZXNxbDovL3VzZXI6cGFzc0Bob3N0L2Ri
  API_KEY: c2stc2VjcmV0LWtleQ==
```

**Declarative (YAML with stringData - plaintext):**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: backend-secrets
  namespace: todo-app
type: Opaque
stringData:
  # Plaintext values (converted to base64 by K8s)
  DATABASE_URL: "postgresql://user:pass@host/db"
  API_KEY: "sk-secret-key"
```

### Using Secrets as Environment Variables

**All keys from Secret:**
```yaml
spec:
  containers:
  - name: backend
    envFrom:
    - secretRef:
        name: backend-secrets
```

**Specific keys:**
```yaml
spec:
  containers:
  - name: backend
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: backend-secrets
          key: DATABASE_URL
```

## Health Probes

Health probes ensure application reliability.

### Three Probe Types

| Probe | Purpose | When It Fails |
|-------|---------|---------------|
| **Liveness** | Is container alive? | Container restarted |
| **Readiness** | Is container ready for traffic? | Removed from Service |
| **Startup** | Has container started? | Liveness/readiness disabled until pass |

### Probe Configuration

```yaml
# HTTP probe (most common)
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 10  # Wait before first check
  periodSeconds: 15        # Check every 15s
  timeoutSeconds: 5        # Timeout per check
  failureThreshold: 3      # Failures before action
  successThreshold: 1      # Successes to be healthy

# TCP probe (for non-HTTP services)
livenessProbe:
  tcpSocket:
    port: 5432
  initialDelaySeconds: 15
  periodSeconds: 20

# Command probe (run a command)
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Probe Best Practices

| Probe | Check | Timing |
|-------|-------|--------|
| **Liveness** | Basic health (app running?) | Less frequent, longer timeout |
| **Readiness** | Dependencies ready? | More frequent, shorter timeout |
| **Startup** | Initial startup complete? | Use for slow-starting apps |

```yaml
# Liveness: Simple, lightweight
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 15
  timeoutSeconds: 5
  failureThreshold: 3

# Readiness: Check dependencies
readinessProbe:
  httpGet:
    path: /ready  # Checks DB, cache, etc.
    port: 8000
  initialDelaySeconds: 5
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3

# Startup: For slow apps (disables liveness/readiness until pass)
startupProbe:
  httpGet:
    path: /health
    port: 8000
  periodSeconds: 5
  failureThreshold: 30  # 30 * 5s = 150s max startup
```

## Resource Management

Set resource requests and limits for stability.

### Understanding Requests vs Limits

| Type | Description | Effect |
|------|-------------|--------|
| **Request** | Guaranteed minimum | Used for scheduling |
| **Limit** | Maximum allowed | Enforced at runtime |

### CPU Resources

- CPU is compressible (throttled if exceeded).
- Measured in cores: `1` = 1 core, `500m` = 0.5 core.

```yaml
resources:
  requests:
    cpu: "100m"   # 0.1 cores guaranteed
  limits:
    cpu: "500m"   # Max 0.5 cores (throttled beyond)
```

**Best Practice**: Set requests, consider not setting CPU limits (allows bursting).

### Memory Resources

- Memory is non-compressible (OOM killed if exceeded).
- Measured in bytes: `256Mi` = 256 mebibytes, `1Gi` = 1 gibibyte.

```yaml
resources:
  requests:
    memory: "256Mi"  # 256Mi guaranteed
  limits:
    memory: "512Mi"  # Max 512Mi (OOM killed beyond)
```

**Best Practice**: Set requests = limits for memory (Guaranteed QoS).

### Recommended Patterns

**Small service (API, microservice):**
```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```

**Medium service (backend with DB connections):**
```yaml
resources:
  requests:
    cpu: "250m"
    memory: "256Mi"
  limits:
    cpu: "1000m"
    memory: "512Mi"
```

**Large service (heavy processing):**
```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "2000m"
    memory: "1Gi"
```

## Complete Application Example

### Full-Stack Application Structure

```
k8s/
├── namespace.yaml
├── configmap.yaml
├── secrets.yaml
├── backend-deployment.yaml
├── backend-service.yaml
├── frontend-deployment.yaml
└── frontend-service.yaml
```

### namespace.yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: todo-app
  labels:
    app: todo
```

### configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: todo-app
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  BACKEND_URL: "http://backend-service:8000"
```

### secrets.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: todo-app
type: Opaque
stringData:
  DATABASE_URL: "postgresql://user:pass@neon.tech/todo"
  BETTER_AUTH_SECRET: "your-secret-key"
  GEMINI_API_KEY: "your-api-key"
```

### backend-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: todo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: todo-backend:v1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8000
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        livenessProbe:
          httpGet:
            path: /docs
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 15
        readinessProbe:
          httpGet:
            path: /docs
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 10
```

### backend-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: todo-app
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 8000
    targetPort: 8000
```

### frontend-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: todo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: todo-frontend:v1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3000
        env:
        - name: NEXT_PUBLIC_API_URL
          value: "http://backend-service:8000"
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 15
        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 10
```

### frontend-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: todo-app
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 30000
```

## kubectl Commands Reference

### Apply Resources

```bash
# Apply single file
kubectl apply -f deployment.yaml

# Apply all files in directory
kubectl apply -f k8s/

# Apply with namespace
kubectl apply -f deployment.yaml -n todo-app
```

### View Resources

```bash
# List pods
kubectl get pods -n todo-app

# List all resources
kubectl get all -n todo-app

# Describe resource (detailed info)
kubectl describe pod backend-xxx -n todo-app

# Get YAML of resource
kubectl get deployment backend -n todo-app -o yaml
```

### Debug

```bash
# View logs
kubectl logs backend-xxx -n todo-app

# Follow logs
kubectl logs -f backend-xxx -n todo-app

# Execute command in pod
kubectl exec -it backend-xxx -n todo-app -- /bin/sh

# Port forward (local access)
kubectl port-forward svc/backend-service 8000:8000 -n todo-app
```

### Scale

```bash
# Scale deployment
kubectl scale deployment backend --replicas=5 -n todo-app

# Autoscale
kubectl autoscale deployment backend --min=2 --max=10 --cpu-percent=80 -n todo-app
```

### Update

```bash
# Update image
kubectl set image deployment/backend backend=my-backend:v2 -n todo-app

# Rollout status
kubectl rollout status deployment/backend -n todo-app

# Rollback
kubectl rollout undo deployment/backend -n todo-app
```

### Delete

```bash
# Delete resource
kubectl delete -f deployment.yaml

# Delete by name
kubectl delete deployment backend -n todo-app

# Delete namespace (and all resources in it)
kubectl delete namespace todo-app
```

## Best Practices Summary

### Do

- Use Deployments (not naked Pods).
- Always set resource requests.
- Use namespaces for organization.
- Add health probes for reliability.
- Use ConfigMaps for configuration.
- Use Secrets for sensitive data.
- Pin image versions (not `latest`).
- Use labels for organization.
- Add annotations for documentation.

### Don't

- Create Pods directly.
- Use `default` namespace in production.
- Hardcode configuration in images.
- Store secrets in ConfigMaps.
- Use `latest` image tag.
- Skip health probes.
- Set memory limits too low (OOM kills).
- Ignore resource requests (poor scheduling).

## References

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Kubernetes Configuration Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Kubernetes Best Practices 2025](https://kodekloud.com/blog/kubernetes-best-practices-2025/)
- [Service Types Explained](https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0)
- [Health Probes Guide](https://cloud.google.com/blog/products/containers-kubernetes/kubernetes-best-practices-setting-up-health-checks-with-readiness-and-liveness-probes)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
