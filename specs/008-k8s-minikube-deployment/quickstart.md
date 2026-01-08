# Quickstart Guide: Kubernetes Minikube Deployment

**Feature**: 008-k8s-minikube-deployment
**Date**: 2025-12-28
**Status**: Complete

## Overview

This guide provides step-by-step instructions for deploying the Phase III Todo Chatbot application to a local Minikube Kubernetes cluster. Follow these steps to get the application running on your machine.

---

## Prerequisites Checklist

Before starting, ensure you have the following installed and configured:

| Requirement | Version Check | Installation Instructions |
|-------------|------------------|------------------------|
| Docker Desktop | v20.10+ | [Download](https://www.docker.com/products/docker-desktop/) |
| Minikube | v1.32+ | `curl -Lo https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64` then install |
| kubectl | v1.28+ | [Install Guide](https://kubernetes.io/docs/tasks/tools/) |
| Helm | v3.14+ | `choco install kubernetes-helm` (Windows) or `brew install helm` (macOS) |
| Neon PostgreSQL | - | Account at [neon.tech](https://neon.tech) |
| OpenAI API Key | - | Account at [platform.openai.com](https://platform.openai.com) |
| Git | v2.30+ | [Install Guide](https://git-scm.com/downloads) |

**Verify Installations**:
```bash
# Docker
docker --version
# Expected: Docker version 20.10.0 or higher

# Minikube
minikube version
# Expected: minikube version: v1.32.0 or higher

# kubectl
kubectl version --client
# Expected: Client Version: v1.28.0 or higher

# Helm
helm version
# Expected: v3.14.0 or higher
```

---

## Step 1: Start Minikube Cluster

### 1.1 Start Minikube

Start a local Kubernetes cluster with Docker driver:

```bash
# Start Minikube with Docker driver and adequate resources for local development
minikube start \
  --driver=docker \
  --cpus=1 \
  --memory=2048 \
  --disk-size=20GB

# Expected output:
# Done! minikube is running (minikube version: v1.32.0)
```

### 1.2 Verify Cluster Status

Ensure the cluster is healthy:

```bash
# Check Minikube status
minikube status

# Expected output:
# minikube: Running
# cluster: Running
# kubectl: Correctly Configured: pointing to minikube-vm at 192.168.X.X

# Verify kubectl can connect
kubectl cluster-info

# Expected output:
# Kubernetes control plane is running at https://192.168.X.X:8443
# CoreDNS is running at https://192.168.X.X:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### 1.3 Enable Useful Addons (Optional)

Enable helpful addons for debugging:

```bash
# Enable metrics server for resource monitoring
minikube addons enable metrics-server

# Enable dashboard (optional, for visual UI)
minikube addons enable dashboard

# Access dashboard
minikube dashboard
```

---

## Step 2: Create Kubernetes Namespace

Create a dedicated namespace for the Todo Chatbot application:

```bash
# Create namespace
kubectl create namespace todo-app

# Verify namespace exists
kubectl get namespace todo-app

# Expected output:
# NAME      STATUS   AGE
# todo-app   Active   5s
```

---

## Step 3: Build Docker Images

### 3.1 Build Backend Docker Image

Navigate to the backend directory and build the image:

```bash
# Navigate to backend directory
cd calm-orbit-todo/backend

# Build multi-stage Docker image
docker build -t todo-backend:v1.0.0 .

# Expected output:
# [+] Building X.XXs (XX/XX) DONE
# => => writing image sha256:XXXX
# => => naming to docker.io/library/todo-backend:v1.0.0

# Verify image size (must be < 500MB)
docker images todo-backend:v1.0.0 --format "{{.Size}}"
```

### 3.2 Build Frontend Docker Image

Navigate to the frontend directory and build the image:

```bash
# Navigate to frontend directory
cd ../frontend

# Build multi-stage Docker image
docker build -t todo-frontend:v1.0.0 .

# Expected output:
# [+] Building X.XXs (XX/XX) DONE
# => => writing image sha256:XXXX
# => => naming to docker.io/library/todo-frontend:v1.0.0

# Verify image size (must be < 500MB)
docker images todo-frontend:v1.0.0 --format "{{.Size}}"
```

### 3.3 Verify Image Sizes

Ensure both images are under the 500MB limit:

```bash
# List all Todo Chatbot images
docker images | grep todo

# Expected output:
# REPOSITORY      TAG       IMAGE ID       CREATED         SIZE
# todo-backend    v1.0.0    XXXXXXXX        X minutes ago    245MB
# todo-frontend   v1.0.0    YYYYYYYYY        X minutes ago    198MB
```

**Success Criteria**: Both images must be < 500MB total (target: < 250MB each)

---

## Step 4: Load Images into Minikube

Minikube has its own Docker registry. Load images to make them available to Kubernetes:

```bash
# Load backend image into Minikube
docker save todo-backend:v1.0.0 | minikube image load -
# Expected output:
# Image "todo-backend:v1.0.0" loaded

# Load frontend image into Minikube
docker save todo-frontend:v1.0.0 | minikube image load -
# Expected output:
# Image "todo-frontend:v1.0.0" loaded
```

**Alternative Method** (if docker save has issues):

```bash
# Use eval to switch to Minikube Docker context
eval $(minikube docker-env)

# Build images directly in Minikube context
cd calm-orbit-todo/backend && docker build -t todo-backend:v1.0.0 .
cd ../frontend && docker build -t todo-frontend:v1.0.0 .

# Exit Minikube Docker context
eval $(minikube docker-env -u)
```

### 4.1 Verify Images in Minikube

```bash
# List images available in Minikube
minikube image ls

# Expected output (should include todo-backend and todo-frontend):
# REPOSITORY       TAG      IMAGE ID       SIZE
# docker.io/library/todo-backend    v1.0.0    XXXXXXXX        245MB
# docker.io/library/todo-frontend   v1.0.0    YYYYYYYYY        198MB
```

---

## Step 5: Create Kubernetes Secrets

Sensitive data (database URL, JWT secret, API keys) must be stored as Kubernetes Secrets, **not** in Helm values.

### 5.1 Set Environment Variables

Export your sensitive values (replace with actual values):

```bash
# Set your actual values
export DATABASE_URL="postgresql+asyncpg://user:password@ep-xxx.aws.neon.tech/neondb?sslmode=require"
export JWT_SECRET="your-super-secret-jwt-key-min-32-chars"
export OPENAI_API_KEY="sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### 5.2 Create Secrets

Create the `todo-secrets` Kubernetes Secret:

```bash
# Create secret with sensitive data
kubectl create secret generic todo-secrets \
  --from-literal=DATABASE_URL="$DATABASE_URL" \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  --from-literal=OPENAI_API_KEY="$OPENAI_API_KEY" \
  -n todo-app

# Expected output:
# secret/todo-secrets created

# Verify secret exists
kubectl get secret todo-secrets -n todo-app

# Expected output:
# NAME          TYPE     DATA   AGE
# todo-secrets  Opaque   3      5s

# View secret data (optional, for debugging)
kubectl get secret todo-secrets -n todo-app -o yaml
```

**Security Note**: Secrets are base64-encoded and stored securely by Kubernetes. Do **not** commit these values to Git.

---

## Step 6: Deploy with Helm

### 6.1 Lint Helm Chart

Validate the Helm chart syntax before deployment:

```bash
# Navigate to charts directory
cd charts/todo-chatbot

# Lint the chart
helm lint .

# Expected output:
# ==> Linting .
# 1 chart(s) linted, 0 chart(s) failed

# Test template rendering
helm template todo --debug .
# Expected output:
# Rendered manifests (truncated for brevity)...
```

### 6.2 Install Helm Release

Deploy the application to the `todo-app` namespace:

```bash
# Install the Helm chart
helm install todo . -n todo-app

# Expected output:
# NAME: todo
# LAST DEPLOYED: Mon Dec 28 12:00:00 2025
# NAMESPACE: todo-app
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# 1. Get the application URL by running these commands in separate terminal:
#    minikube service list -n todo-app
```

### 6.3 Verify Deployment

Check that all resources were created successfully:

```bash
# List all resources in todo-app namespace
kubectl get all -n todo-app

# Expected output (abbreviated):
# NAME                                    TYPE            READY   STATUS    AGE
# pod/backend-xxx-6b7b9c48-kr7s            1/1             Running   Xs
# pod/frontend-xxx-6b7b9c48-kr7s           1/1             Running   Xs
# service/backend-service                ClusterIP       1/1       Running   Xs
# service/frontend-service                NodePort         1/1       Running   Xs
# deployment.apps/backend-deployment         1/1             True      XXs
# deployment.apps/frontend-deployment        1/1             True      XXs
# configmap/todo-config                   1/1             True      XXs

# Check ConfigMap
kubectl get configmap todo-config -n todo-app -o yaml

# Expected output: Should contain logLevel, environment, corsOrigins, etc.

# Check Secrets
kubectl get secret todo-secrets -n todo-app -o yaml

# Expected output: Should contain DATABASE_URL, JWT_SECRET, OPENAI_API_KEY
```

### 6.4 Verify Pod Status

Ensure all pods are in the `Running` state:

```bash
# Watch pods until ready (press Ctrl+C to exit)
kubectl get pods -n todo-app -l app=backend -w
kubectl get pods -n todo-app -l app=frontend -w

# Wait until STATUS shows "Running"
# Expected output (watch):
# NAME                          READY   STATUS    RESTARTS   AGE
# backend-xxx-6b7b9c48-kr7s   1/1     Running   0          30s
# frontend-xxx-6b7b9c48-kr7s   1/1     Running   0          30s
```

---

## Step 7: Access the Application

### 7.1 Get Service URL

Find the URL to access the frontend:

```bash
# Get frontend service details
minikube service list -n todo-app

# Expected output:
# NAME                TYPE           URL                                 PORT
# frontend-service     NodePort       http://192.168.X.X:30000        30000:30000/TCP

# Alternatively, use minikube tunnel (for LoadBalancer)
minikube service frontend-service -n todo-app --url
```

### 7.2 Open in Browser

Navigate to the frontend URL in your browser:

```
http://192.168.X.X:30000
```

You should see the Todo Chatbot login page.

### 7.3 Verify Frontend-Backend Connection

Check that the frontend can communicate with the backend:

```bash
# Get backend pod name
BACKEND_POD=$(kubectl get pods -n todo-app -l app=backend -o jsonpath='{.items[0].metadata.name}')

# Test connectivity from frontend pod
kubectl exec deployment/frontend -n todo-app -- \
  curl -s -o /dev/null -w "%{http_code}" http://backend-service:8000/health

# Expected output:
# 200
```

---

## Step 8: Test Application Functionality

### 8.1 Complete User Task Lifecycle

1. **Login** to the application using Better Auth
2. **Create Task**: Use the chatbot to create a task (e.g., "Buy groceries tomorrow")
3. **List Tasks**: View the task in the list
4. **Update Task**: Change task status (e.g., mark as "in progress")
5. **Complete Task**: Mark task as completed
6. **Delete Task**: Remove the task

### 8.2 Verify Database Persistence

Check that tasks are persisted in the Neon PostgreSQL database:

```bash
# Get backend pod name
BACKEND_POD=$(kubectl get pods -n todo-app -l app=backend -o jsonpath='{.items[0].metadata.name}')

# View backend logs
kubectl logs $BACKEND_POD -n todo-app --tail=50

# Expected output: Should show database queries, task creation/update logs, etc.
```

---

## Troubleshooting

### Issue: Pods stuck in Pending or CrashLoopBackOff

**Symptoms**:
- Pods not starting (Pending)
- Pods restarting repeatedly (CrashLoopBackOff)

**Solutions**:

1. **Check Pod Events**:
   ```bash
   kubectl describe pod <pod-name> -n todo-app

   # Look for:
   # - Image pull errors (if pullPolicy: IfNotPresent, ensure image exists)
   # - OOMKilled (memory limit too low)
   # - CrashLoopBackOff (application error)
   ```

2. **Check Pod Logs**:
   ```bash
   kubectl logs <pod-name> -n todo-app --tail=100

   # Look for application errors, startup issues
   ```

3. **Increase Memory Limits** (if OOMKilled):
   ```bash
   # Edit values.yaml
   # Increase backend.resources.limits.memory: "768Mi"

   # Upgrade Helm release
   helm upgrade todo . -n todo-app
   ```

### Issue: Frontend Cannot Connect to Backend

**Symptoms**:
- CORS errors in browser console
- Connection refused or timeout

**Solutions**:

1. **Verify Backend Service**:
   ```bash
   kubectl get service backend-service -n todo-app

   # Ensure service exists and has endpoints
   kubectl get endpoints backend-service -n todo-app
   ```

2. **Check CORS Configuration**:
   ```bash
   # View ConfigMap
   kubectl get configmap todo-config -n todo-app -o yaml

   # Verify corsOrigins includes frontend URL
   # May need to update:
   kubectl patch configmap todo-config -n todo-app -p '{"data":{"corsOrigins":"[\"http://192.168.X.X:30000\"]"}}'
   ```

3. **Test Service Discovery from Frontend Pod**:
   ```bash
   # Get frontend pod
   FRONTEND_POD=$(kubectl get pods -n todo-app -l app=frontend -o jsonpath='{.items[0].metadata.name}')

   # Test backend connection
   kubectl exec $FRONTEND_POD -n todo-app -- \
     curl http://backend-service:8000/health
   ```

### Issue: Secrets Not Found

**Symptoms**:
- Pod fails to start with `secret "todo-secrets" not found` error

**Solutions**:

1. **Verify Secret Exists**:
   ```bash
   kubectl get secret todo-secrets -n todo-app
   ```

2. **Recreate Secret** (if missing):
   ```bash
   # Delete old secret if needed
   kubectl delete secret todo-secrets -n todo-app

   # Recreate with correct values
   kubectl create secret generic todo-secrets \
     --from-literal=DATABASE_URL="$DATABASE_URL" \
     --from-literal=JWT_SECRET="$JWT_SECRET" \
     --from-literal=OPENAI_API_KEY="$OPENAI_API_KEY" \
     -n todo-app

   # Restart pods
   kubectl rollout restart deployment backend-deployment -n todo-app
   kubectl rollout restart deployment frontend-deployment -n todo-app
   ```

### Issue: Image Too Large (> 500MB)

**Symptoms**:
- Helm deployment succeeds, but image size warning
- Minikube disk fills quickly

**Solutions**:

1. **Check Image Size**:
   ```bash
   docker images todo-backend:v1.0.0 --format "{{.Size}}"
   docker images todo-frontend:v1.0.0 --format "{{.Size}}"
   ```

2. **Optimize Dockerfiles**:
   - Ensure multi-stage builds are used
   - Check .dockerignore excludes unnecessary files
   - Verify slim/alpine base images are used
   - Remove unused dependencies

3. **Rebuild and Reload**:
   ```bash
   # Rebuild optimized images
   docker build -t todo-backend:v1.0.0 calm-orbit-todo/backend
   docker build -t todo-frontend:v1.0.0 calm-orbit-todo/frontend

   # Reload into Minikube
   minikube image load todo-backend:v1.0.0
   minikube image load todo-frontend:v1.0.0

   # Restart deployments
   helm upgrade todo . -n todo-app
   ```

### Issue: Health Probes Failing

**Symptoms**:
- Pods restarting repeatedly
- `Liveness probe failed` or `Readiness probe failed` in events

**Solutions**:

1. **Check Health Endpoint**:
   ```bash
   # Test health endpoint locally
   docker run --rm -p 8000:8000 todo-backend:v1.0.0
   curl http://localhost:8000/health

   # Expected response:
   # {"status":"ok"}

   # If failing, check application code
   ```

2. **Adjust Probe Timing**:
   ```bash
   # View current probe configuration
   kubectl get deployment backend-deployment -n todo-app -o yaml

   # Edit values.yaml to increase initialDelaySeconds
   # liveness.health.initialDelaySeconds: 20  (was 10)
   # readiness.health.initialDelaySeconds: 10  (was 5)

   # Upgrade Helm release
   helm upgrade todo . -n todo-app
   ```

3. **Disable Probes Temporarily** (for debugging):
   ```bash
   # Edit deployment to remove probes
   kubectl edit deployment backend-deployment -n todo-app

   # Comment out livenessProbe and readinessProbe sections

   # Save and watch pod behavior
   ```

---

## Cleanup

### Stop Minikube

When done with development, stop the cluster to free resources:

```bash
# Stop Minikube
minikube stop

# Expected output:
# Stopping "minikube" in docker ...
# * "minikube" stopped

# Delete cluster (optional, to free disk space)
minikube delete
```

### Delete Kubernetes Resources

Remove deployed resources:

```bash
# Uninstall Helm release
helm uninstall todo -n todo-app

# Expected output:
# release "todo" uninstalled

# Delete namespace (optional, removes remaining resources)
kubectl delete namespace todo-app

# Verify all resources deleted
kubectl get all -n todo-app
# Expected output: No resources found
```

---

 ## Resource Monitoring/

- [Docker Documentation](https://docs.docker.com/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Feature Specification](./spec.md)
- [Research Document](./research.md)
- [Data Model](./data-model.md)

## Rolling Update Workflow

When you make changes to the application code, follow this workflow to update deployment seamlessly:

### Update Frontend

```bash
# Navigate to frontend directory
cd calm-orbit-todo/frontend

# Make your code changes...
# ...

# Rebuild Docker image
docker build -t todo-frontend:v1.0.0 .

# Load updated image into Minikube
docker save todo-frontend:v1.0.0 | minikube image load -

# Trigger rolling update
helm upgrade todo charts/todo-chatbot/ -n todo-app \
  --reuse-values \
  --set frontend.image.tag=v1.0.0
```

### Update Backend

```bash
# Navigate to backend directory
cd calm-orbit-todo/backend

# Make your code changes...
# ...

# Rebuild Docker image
docker build -t todo-backend:v1.0.0 .

# Load updated image into Minikube
docker save todo-backend:v1.0.0 | minikube image load -

# Trigger rolling update
helm upgrade todo charts/todo-chatbot/ -n todo-app \
  --reuse-values \
  --set backend.image.tag=v1.0.0
```

### Update Both Components

```bash
# Rebuild both images
docker build -t todo-frontend:v1.0.0 calm-orbit-todo/frontend
docker build -t todo-backend:v1.0.0 calm-orbit-todo/backend

# Load both images into Minikube
docker save todo-frontend:v1.0.0 | minikube image load -
docker save todo-backend:v1.0.0 | minikube image load -

# Upgrade Helm release
helm upgrade todo charts/todo-chatbot/ -n todo-app \
  --reuse-values \
  --set frontend.image.tag=v1.0.0 \
  --set backend.image.tag=v1.0.0

# Watch rollout progress
kubectl rollout status deployment/frontend-deployment -n todo-app
kubectl rollout status deployment/backend-deployment -n todo-app

# Wait for rollout to complete
kubectl wait --for=condition=available deployment/frontend-deployment -n todo-app --timeout=300s
kubectl wait --for=condition=available deployment/backend-deployment -n todo-app --timeout=300s
```

### Rolling Update Behavior

- Helm performs **zero-downtime rolling updates** by default
- New pods are created before old pods are terminated
- Service traffic is gradually shifted to new pods
- Use `kubectl rollout status` to monitor progress
- Use `kubectl rollout undo deployment/<name> -n todo-app` to roll back if needed

---


---

## Success Criteria Verification Checklist

After completing all steps, verify each success criterion:

### SC-001: Minikube Startup Time (< 5 minutes)

```bash
# Time the Minikube startup
time minikube start \
  --driver=docker \
  --cpus=1 \
  --memory=2048 \
  --disk-size=20GB

# Expected: real < 5m 00s
```

- [ ] Startup time under 5 minutes
- [ ] No errors during startup
- [ ] Cluster status shows "Running"

### SC-002: Docker Image Sizes (< 500MB each)

```bash
# Check image sizes
docker images | grep todo

# Expected output:
# REPOSITORY      TAG       IMAGE ID       CREATED         SIZE
# todo-backend    v1.0.0    XXXXXXXX        X minutes ago    245MB
# todo-frontend   v1.0.0    YYYYYYYY        X minutes ago    198MB
```

- [ ] Frontend image < 500MB
- [ ] Backend image < 500MB
- [ ] Both images use multi-stage builds
- [ ] .dockerignore files properly configured

### SC-003: Helm Deployment Time (< 2 minutes)

```bash
# Time the Helm install
time helm install todo charts/todo-chatbot/ -n todo-app

# Expected: real < 2m 00s
```

- [ ] Helm install time under 2 minutes
- [ ] All resources created without errors
- [ ] Helm release status is "deployed"

### SC-004: Pods Running Within 5 Minutes

```bash
# Watch pods startup
kubectl get pods -n todo-app -w

# Or wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=backend -n todo-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n todo-app --timeout=300s

# Expected: STATUS=Running for all pods within 5 minutes
```

- [ ] Backend pods Running within 5 minutes
- [ ] Frontend pods Running within 5 minutes
- [ ] No pods in Pending/CrashLoopBackOff state
- [ ] All pods READY = 1/1

### SC-005: Application Accessible via Browser

```bash
# Get service URL
minikube service frontend-service -n todo-app --url

# Expected output:
# http://192.168.X.X:30000

# Open in browser
# Should see Todo Chatbot login page
```

- [ ] Service URL is accessible
- [ ] Frontend login page loads
- [ ] No browser console errors
- [ ] Page renders correctly

### SC-006: Frontend Connects to Backend

```bash
# Test connectivity from frontend pod
kubectl exec deployment/frontend -n todo-app -- \
  curl -s -o /dev/null -w "%{http_code}" \
  http://backend-service:8000/health

# Expected: 200
```

- [ ] Frontend can reach backend /health endpoint
- [ ] HTTP response code is 200
- [ ] No CORS errors
- [ ] Backend returns {"status":"healthy", "version":"1.0.0"}

### SC-007: Task Lifecycle Works

Test complete task workflow through chatbot:

1. **Create Task**
   - Use chatbot: "Create a task to buy groceries tomorrow"
   - Verify task appears in list
   
2. **List Tasks**
   - View task list
   - Verify created task shows
   
3. **Update Task**
   - Use chatbot: "Mark the grocery task as in progress"
   - Verify task status updates
   
4. **Complete Task**
   - Use chatbot: "Mark the grocery task as completed"
   - Verify task status = completed
   
5. **Delete Task**
   - Use chatbot: "Delete the grocery task"
   - Verify task removed from list

- [ ] Can create task via chatbot
- [ ] Can list tasks
- [ ] Can update task status
- [ ] Can complete task
- [ ] Can delete task
- [ ] Tasks persist across page refresh

### SC-008: All Phase III Features Work

Verify all Phase III Todo Chatbot features:

1. **Authentication (Better Auth)**
   - [ ] Can login with email/password
   - [ ] JWT token issued correctly
   - [ ] Session persists

2. **AI Chat (OpenAI Agents SDK + MCP)**
   - [ ] Chatbot responds to natural language
   - [ ] MCP tools accessible (add_task, list_tasks, etc.)
   - [ ] Context maintained across conversation

3. **Task CRUD Operations**
   - [ ] Create, Read, Update, Delete all working
   - [ ] Tasks stored in Neon PostgreSQL
   - [ ] User isolation (users see only their tasks)

4. **Real-time Updates**
   - [ ] Chat responses appear immediately
   - [ ] Task list updates without page reload

5. **Error Handling**
   - [ ] Graceful error messages for failures
   - [ ] Input validation
   - [ ] Rate limiting feedback

### Overall Verification

- [ ] All 8 success criteria met
- [ ] Application fully functional in Kubernetes
- [ ] No critical errors in logs
- [ ] Deployment ready for production upgrade

---


## Resource Monitoring

Monitor pod resource usage to ensure limits are adequate:

### Enable Metrics Server

```bash
# Enable metrics server addon (if not already enabled)
minikube addons enable metrics-server

# Verify metrics server is running
minikube addons list
```

### View Pod Resource Usage

```bash
# View real-time resource usage
kubectl top pods -n todo-app

# View resource usage with labels
kubectl top pods -n todo-app -l app=backend
kubectl top pods -n todo-app -l app=frontend

# Output example:
# NAME                        CPU(cores)   MEMORY(bytes)
# backend-xxx-6b7b9c48-kr7s   123m          256Mi
# frontend-xxx-6b7b9c48-kr7s   45m           128Mi
```

### View Node Resource Usage

```bash
# View Minikube node resource usage
kubectl top nodes

# Output example:
# NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# minikube   1.52         38%    2048Mi          50%
```

### Check Resource Limits vs Usage

```bash
# Get deployment resource limits
kubectl get deployment frontend-deployment -n todo-app -o yaml

# Get pod resource usage
kubectl top pod <pod-name> -n todo-app

# Compare actual usage vs configured limits
# If pods are frequently hitting limits, consider increasing resources.limits in values.yaml
```

### Common Resource Issues

**Issue: Pods CPU Throttled**
- Symptom: Application slow, CPU usage at limit
- Solution: Increase `resources.limits.cpu` in values.yaml

**Issue: Pods OOMKilled (Out of Memory)**
- Symptom: Pods restart repeatedly, "OOMKilled" in logs
- Solution: Increase `resources.limits.memory` in values.yaml

**Issue: Metrics Server Not Running**
- Symptom: `kubectl top` returns error
- Solution: Run `minikube addons enable metrics-server`

