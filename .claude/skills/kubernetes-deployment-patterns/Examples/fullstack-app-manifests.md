# Full-Stack Application Kubernetes Manifests

Complete example for deploying a full-stack application (Frontend + Backend) on Kubernetes.

## File Structure

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

---

## 1. namespace.yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: todo-app
  labels:
    app: todo
    environment: production
```

---

## 2. configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: todo-app
data:
  # Application settings
  APP_ENV: "production"
  LOG_LEVEL: "info"

  # Internal service URLs
  BACKEND_URL: "http://backend-service:8000"

  # Feature flags
  ENABLE_DEBUG: "false"
```

---

## 3. secrets.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: todo-app
type: Opaque
stringData:
  # Database connection
  DATABASE_URL: "postgresql://user:password@neon.tech:5432/todo?sslmode=require"

  # Authentication
  BETTER_AUTH_SECRET: "your-super-secret-auth-key-here"

  # API Keys
  GEMINI_API_KEY: "your-gemini-api-key"
  OPENAI_API_KEY: "sk-your-openai-key"
```

**Note**: In production, use external secret management (HashiCorp Vault, AWS Secrets Manager, etc.)

---

## 4. backend-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: todo-app
  labels:
    app: backend
spec:
  replicas: 2

  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0

  selector:
    matchLabels:
      app: backend

  template:
    metadata:
      labels:
        app: backend
    spec:
      # Security: Run as non-root
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001

      containers:
      - name: backend
        image: todo-backend:v1
        imagePullPolicy: IfNotPresent

        ports:
        - containerPort: 8000
          protocol: TCP

        # Environment from ConfigMap and Secret
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets

        # Additional environment variables
        env:
        - name: PORT
          value: "8000"

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
            path: /docs
            port: 8000
          initialDelaySeconds: 15
          periodSeconds: 20
          timeoutSeconds: 5
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /docs
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3

        startupProbe:
          httpGet:
            path: /docs
            port: 8000
          periodSeconds: 5
          failureThreshold: 30

      # Graceful shutdown
      terminationGracePeriodSeconds: 30
```

---

## 5. backend-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: todo-app
  labels:
    app: backend
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - name: http
    port: 8000
    targetPort: 8000
    protocol: TCP
```

---

## 6. frontend-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: todo-app
  labels:
    app: frontend
spec:
  replicas: 2

  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0

  selector:
    matchLabels:
      app: frontend

  template:
    metadata:
      labels:
        app: frontend
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001

      containers:
      - name: frontend
        image: todo-frontend:v1
        imagePullPolicy: IfNotPresent

        ports:
        - containerPort: 3000
          protocol: TCP

        # Environment variables
        env:
        - name: NEXT_PUBLIC_API_URL
          value: "http://backend-service:8000"
        - name: NODE_ENV
          value: "production"

        # Resource management
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"

        # Health checks
        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 15
          periodSeconds: 20
          timeoutSeconds: 5
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3

      terminationGracePeriodSeconds: 30
```

---

## 7. frontend-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: todo-app
  labels:
    app: frontend
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - name: http
    port: 3000
    targetPort: 3000
    nodePort: 30000
    protocol: TCP
```

---

## Deployment Commands

### Deploy All

```bash
# Apply all manifests in order
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml

# Or apply entire directory
kubectl apply -f k8s/
```

### Verify Deployment

```bash
# Check all resources
kubectl get all -n todo-app

# Check pods are running
kubectl get pods -n todo-app

# Check services
kubectl get services -n todo-app

# View pod logs
kubectl logs -l app=backend -n todo-app
kubectl logs -l app=frontend -n todo-app
```

### Access Application

```bash
# For Minikube
minikube service frontend-service -n todo-app

# Or port-forward
kubectl port-forward svc/frontend-service 3000:3000 -n todo-app
kubectl port-forward svc/backend-service 8000:8000 -n todo-app
```

### Clean Up

```bash
# Delete all resources
kubectl delete -f k8s/

# Or delete namespace (removes everything in it)
kubectl delete namespace todo-app
```

---

## Architecture Diagram

```
                    Internet
                        │
                        ▼
              ┌─────────────────┐
              │   NodePort      │
              │   (30000)       │
              └────────┬────────┘
                       │
┌──────────────────────┼──────────────────────┐
│  Namespace: todo-app │                      │
│                      ▼                      │
│    ┌─────────────────────────────┐         │
│    │   frontend-service          │         │
│    │   (ClusterIP: 3000)         │         │
│    └───────────┬─────────────────┘         │
│                │                            │
│        ┌───────┴───────┐                   │
│        ▼               ▼                    │
│   ┌─────────┐     ┌─────────┐              │
│   │Frontend │     │Frontend │              │
│   │ Pod 1   │     │ Pod 2   │              │
│   └────┬────┘     └────┬────┘              │
│        │               │                    │
│        └───────┬───────┘                   │
│                ▼                            │
│    ┌─────────────────────────────┐         │
│    │   backend-service           │         │
│    │   (ClusterIP: 8000)         │         │
│    └───────────┬─────────────────┘         │
│                │                            │
│        ┌───────┴───────┐                   │
│        ▼               ▼                    │
│   ┌─────────┐     ┌─────────┐              │
│   │Backend  │     │Backend  │              │
│   │ Pod 1   │     │ Pod 2   │              │
│   └────┬────┘     └────┬────┘              │
│        │               │                    │
└────────┼───────────────┼────────────────────┘
         │               │
         └───────┬───────┘
                 ▼
         ┌─────────────┐
         │  Neon DB    │
         │  (External) │
         └─────────────┘
```
