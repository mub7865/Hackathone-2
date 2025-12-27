# Full-Stack Minikube Deployment Example

Complete step-by-step guide to deploy a full-stack application (Frontend + Backend) on Minikube.

## Prerequisites Checklist

```bash
# Check all tools are installed
docker --version      # Docker Desktop running
minikube version      # Minikube installed
kubectl version       # kubectl installed
helm version          # Helm installed (optional)
```

## Step 1: Start Minikube Cluster

```bash
# Start with Docker driver (recommended)
minikube start --driver=docker --cpus=4 --memory=4096

# Verify cluster is running
minikube status

# Expected output:
# minikube
# type: Control Plane
# host: Running
# kubelet: Running
# apiserver: Running
# kubeconfig: Configured
```

## Step 2: Configure Docker Environment

```bash
# Point terminal to Minikube's Docker daemon
# Linux/macOS:
eval $(minikube docker-env)

# Windows PowerShell:
& minikube docker-env | Invoke-Expression

# Verify (should show minikube containers)
docker ps
```

## Step 3: Build Application Images

### Backend (FastAPI)

```bash
# Navigate to backend directory
cd phase2/backend

# Build backend image
docker build -t todo-backend:v1 .

# Verify image exists
docker images | grep todo-backend
```

### Frontend (Next.js)

```bash
# Navigate to frontend directory
cd phase2/frontend

# Build frontend image
docker build -t todo-frontend:v1 .

# Verify image exists
docker images | grep todo-frontend
```

## Step 4: Create Kubernetes Namespace

```bash
# Create namespace for our app
kubectl create namespace todo-app

# Verify namespace
kubectl get namespaces
```

## Step 5: Create Kubernetes Secrets

```bash
# Create secrets for sensitive data
kubectl create secret generic todo-secrets \
  --from-literal=DATABASE_URL="postgresql://user:pass@host/db" \
  --from-literal=BETTER_AUTH_SECRET="your-secret-key" \
  --from-literal=GEMINI_API_KEY="your-api-key" \
  -n todo-app

# Verify secrets created
kubectl get secrets -n todo-app
```

## Step 6: Deploy Backend

### backend-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-backend
  namespace: todo-app
  labels:
    app: todo-backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: todo-backend
  template:
    metadata:
      labels:
        app: todo-backend
    spec:
      containers:
      - name: backend
        image: todo-backend:v1
        imagePullPolicy: Never  # Use local image
        ports:
        - containerPort: 8000
        envFrom:
        - secretRef:
            name: todo-secrets
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        readinessProbe:
          httpGet:
            path: /docs
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /docs
            port: 8000
          initialDelaySeconds: 15
          periodSeconds: 20
---
apiVersion: v1
kind: Service
metadata:
  name: todo-backend-service
  namespace: todo-app
spec:
  type: ClusterIP
  selector:
    app: todo-backend
  ports:
  - port: 8000
    targetPort: 8000
```

### Apply Backend

```bash
kubectl apply -f backend-deployment.yaml

# Watch pods come up
kubectl get pods -n todo-app -w

# Check deployment status
kubectl rollout status deployment/todo-backend -n todo-app
```

## Step 7: Deploy Frontend

### frontend-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-frontend
  namespace: todo-app
  labels:
    app: todo-frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: todo-frontend
  template:
    metadata:
      labels:
        app: todo-frontend
    spec:
      containers:
      - name: frontend
        image: todo-frontend:v1
        imagePullPolicy: Never  # Use local image
        ports:
        - containerPort: 3000
        env:
        - name: NEXT_PUBLIC_API_URL
          value: "http://todo-backend-service:8000"
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: todo-frontend-service
  namespace: todo-app
spec:
  type: NodePort
  selector:
    app: todo-frontend
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 30000
```

### Apply Frontend

```bash
kubectl apply -f frontend-deployment.yaml

# Watch pods come up
kubectl get pods -n todo-app -w

# Check all resources
kubectl get all -n todo-app
```

## Step 8: Access the Application

### Method 1: minikube service (Easiest)

```bash
# Opens browser automatically
minikube service todo-frontend-service -n todo-app

# Get URL only
minikube service todo-frontend-service -n todo-app --url
```

### Method 2: Port Forward

```bash
# Forward frontend
kubectl port-forward svc/todo-frontend-service 3000:3000 -n todo-app

# In another terminal, forward backend (for API testing)
kubectl port-forward svc/todo-backend-service 8000:8000 -n todo-app
```

### Method 3: Minikube Tunnel

```bash
# Start tunnel (requires admin/sudo)
minikube tunnel

# Now access via localhost
```

## Step 9: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n todo-app

# Expected output:
# NAME                            READY   STATUS    RESTARTS   AGE
# todo-backend-xxx-xxx            1/1     Running   0          2m
# todo-backend-xxx-yyy            1/1     Running   0          2m
# todo-frontend-xxx-xxx           1/1     Running   0          1m
# todo-frontend-xxx-yyy           1/1     Running   0          1m

# Check services
kubectl get svc -n todo-app

# Check endpoints
kubectl get endpoints -n todo-app

# View pod logs
kubectl logs -l app=todo-backend -n todo-app
kubectl logs -l app=todo-frontend -n todo-app
```

## Step 10: Update Application (Development Cycle)

```bash
# 1. Make code changes

# 2. Rebuild image with new tag
docker build -t todo-backend:v2 ./phase2/backend

# 3. Update deployment
kubectl set image deployment/todo-backend \
  backend=todo-backend:v2 -n todo-app

# 4. Watch rollout
kubectl rollout status deployment/todo-backend -n todo-app

# OR: Rollback if issues
kubectl rollout undo deployment/todo-backend -n todo-app
```

## Troubleshooting Commands

```bash
# Pod not starting? Check events
kubectl describe pod <pod-name> -n todo-app

# Check container logs
kubectl logs <pod-name> -n todo-app

# Shell into container
kubectl exec -it <pod-name> -n todo-app -- /bin/sh

# Check if image exists in Minikube
minikube ssh -- docker images | grep todo

# ImagePullBackOff error?
# Solution: Set imagePullPolicy: Never and rebuild in Minikube's Docker
```

## Cleanup

```bash
# Delete all resources in namespace
kubectl delete namespace todo-app

# Stop Minikube (preserves data)
minikube stop

# Delete Minikube cluster (removes everything)
minikube delete
```

## Quick Reference Script

Save as `deploy.sh`:

```bash
#!/bin/bash
set -e

echo "Starting Minikube..."
minikube start --driver=docker

echo "Configuring Docker environment..."
eval $(minikube docker-env)

echo "Building images..."
docker build -t todo-backend:v1 ./phase2/backend
docker build -t todo-frontend:v1 ./phase2/frontend

echo "Creating namespace..."
kubectl create namespace todo-app --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying application..."
kubectl apply -f k8s/ -n todo-app

echo "Waiting for pods..."
kubectl wait --for=condition=ready pod -l app=todo-backend -n todo-app --timeout=120s
kubectl wait --for=condition=ready pod -l app=todo-frontend -n todo-app --timeout=120s

echo "Opening application..."
minikube service todo-frontend-service -n todo-app
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     MINIKUBE CLUSTER                        │
│  ┌────────────────────────────────────────────────────────┐│
│  │                  namespace: todo-app                   ││
│  │                                                        ││
│  │  ┌─────────────────────┐  ┌─────────────────────┐    ││
│  │  │ Deployment:         │  │ Deployment:         │    ││
│  │  │ todo-backend        │  │ todo-frontend       │    ││
│  │  │ (2 replicas)        │  │ (2 replicas)        │    ││
│  │  │                     │  │                     │    ││
│  │  │ ┌─────┐ ┌─────┐    │  │ ┌─────┐ ┌─────┐    │    ││
│  │  │ │Pod 1│ │Pod 2│    │  │ │Pod 1│ │Pod 2│    │    ││
│  │  │ └─────┘ └─────┘    │  │ └─────┘ └─────┘    │    ││
│  │  └─────────┬───────────┘  └─────────┬───────────┘    ││
│  │            │                        │                 ││
│  │  ┌─────────▼───────────┐  ┌─────────▼───────────┐    ││
│  │  │ Service: ClusterIP  │  │ Service: NodePort   │    ││
│  │  │ todo-backend-service│  │ todo-frontend-service│   ││
│  │  │ :8000               │  │ :3000 → :30000      │    ││
│  │  └─────────────────────┘  └──────────┬──────────┘    ││
│  │                                       │               ││
│  └───────────────────────────────────────┼───────────────┘│
│                                          │                │
└──────────────────────────────────────────┼────────────────┘
                                           │
                              minikube service / tunnel
                                           │
                                           ▼
                                    Browser (User)
```
