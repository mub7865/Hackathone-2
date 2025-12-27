# Minikube Quickstart Guide

Complete guide to deploying applications on Minikube (local Kubernetes).

## Prerequisites

1. **Docker Desktop** installed and running
2. **Minikube** installed
3. **kubectl** installed

## Step 1: Start Minikube

```bash
# Start Minikube with Docker driver
minikube start --driver=docker

# Verify it's running
minikube status
```

**Expected output:**
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

## Step 2: Load Docker Images into Minikube

Minikube has its own Docker registry. You need to load your local images into it.

### Option A: Use Minikube's Docker Daemon

```bash
# Point shell to Minikube's Docker
eval $(minikube docker-env)

# Now build images (they'll be in Minikube)
docker build -t todo-backend:v1 ./phase2/backend
docker build -t todo-frontend:v1 ./phase2/frontend

# Verify images are in Minikube
docker images | grep todo
```

### Option B: Load Pre-built Images

```bash
# Build locally first
docker build -t todo-backend:v1 ./phase2/backend
docker build -t todo-frontend:v1 ./phase2/frontend

# Load into Minikube
minikube image load todo-backend:v1
minikube image load todo-frontend:v1

# Verify
minikube image ls | grep todo
```

## Step 3: Create Kubernetes Manifests

### Create k8s directory

```bash
mkdir -p phase2/k8s
```

### namespace.yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: todo-app
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
  DATABASE_URL: "your-neon-database-url"
  BETTER_AUTH_SECRET: "your-auth-secret"
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
        imagePullPolicy: Never  # Use local image
        ports:
        - containerPort: 8000
        envFrom:
        - secretRef:
            name: app-secrets
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
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
        imagePullPolicy: Never  # Use local image
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

## Step 4: Deploy to Minikube

```bash
# Apply all manifests
kubectl apply -f phase2/k8s/

# Or apply one by one
kubectl apply -f phase2/k8s/namespace.yaml
kubectl apply -f phase2/k8s/secrets.yaml
kubectl apply -f phase2/k8s/backend-deployment.yaml
kubectl apply -f phase2/k8s/backend-service.yaml
kubectl apply -f phase2/k8s/frontend-deployment.yaml
kubectl apply -f phase2/k8s/frontend-service.yaml
```

## Step 5: Verify Deployment

```bash
# Check all resources
kubectl get all -n todo-app

# Check pods are running
kubectl get pods -n todo-app -w  # Watch mode

# Expected output:
# NAME                        READY   STATUS    RESTARTS   AGE
# backend-xxx                 1/1     Running   0          1m
# backend-yyy                 1/1     Running   0          1m
# frontend-xxx                1/1     Running   0          1m
# frontend-yyy                1/1     Running   0          1m
```

## Step 6: Access Application

### Method 1: Minikube Service (Recommended)

```bash
# Opens browser automatically
minikube service frontend-service -n todo-app
```

### Method 2: Get URL

```bash
# Get service URL
minikube service frontend-service -n todo-app --url
# Output: http://192.168.49.2:30000
```

### Method 3: Port Forward

```bash
# Forward frontend
kubectl port-forward svc/frontend-service 3000:3000 -n todo-app

# Forward backend (in another terminal)
kubectl port-forward svc/backend-service 8000:8000 -n todo-app
```

## Debugging Commands

### View Logs

```bash
# Backend logs
kubectl logs -l app=backend -n todo-app

# Frontend logs
kubectl logs -l app=frontend -n todo-app

# Follow logs
kubectl logs -f deployment/backend -n todo-app
```

### Check Pod Details

```bash
# Describe pod (shows events, errors)
kubectl describe pod -l app=backend -n todo-app
```

### Execute Commands in Pod

```bash
# Get shell access
kubectl exec -it deployment/backend -n todo-app -- /bin/sh

# Run single command
kubectl exec deployment/backend -n todo-app -- env
```

## Common Issues & Fixes

### Issue: ImagePullBackOff

**Cause**: Image not found in Minikube

**Fix**:
```bash
# Load image into Minikube
minikube image load todo-backend:v1

# Set imagePullPolicy to Never in deployment
imagePullPolicy: Never
```

### Issue: Pods stuck in Pending

**Cause**: Not enough resources

**Fix**:
```bash
# Give Minikube more resources
minikube stop
minikube start --cpus=4 --memory=4096
```

### Issue: CrashLoopBackOff

**Cause**: Application crashing

**Fix**:
```bash
# Check logs
kubectl logs deployment/backend -n todo-app

# Check events
kubectl describe pod -l app=backend -n todo-app
```

### Issue: Service not accessible

**Cause**: Minikube tunnel not running

**Fix**:
```bash
# For LoadBalancer services
minikube tunnel

# Or use NodePort with minikube service
minikube service frontend-service -n todo-app
```

## Cleanup

```bash
# Delete all resources
kubectl delete -f phase2/k8s/

# Or delete namespace
kubectl delete namespace todo-app

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

## Useful Minikube Commands

```bash
# Dashboard (web UI)
minikube dashboard

# SSH into Minikube VM
minikube ssh

# Check Minikube IP
minikube ip

# Addons
minikube addons list
minikube addons enable ingress

# Pause/Unpause (save resources)
minikube pause
minikube unpause
```
