# Application Deployment to DOKS Guide

**Time Required**: 45-60 minutes
**Cost**: Included in cluster cost (~$36/month total)

---

## What We're Deploying

Our Todo application consists of:
1. **Backend**: FastAPI application with Phase 5 features (Kafka consumers, schedulers)
2. **Frontend**: Next.js 15 application with Better Auth
3. **LoadBalancers**: To expose services to the internet

**Architecture**:
```
Internet
   ↓
LoadBalancer (Frontend) → Frontend Pods → Backend Service
   ↓
LoadBalancer (Backend) → Backend Pods → Neon Database
   ↓                                   ↓
   └─────────────────────────────→ Redpanda Cloud
```

---

## Prerequisites

✅ DOKS cluster running (from Guide 03)
✅ Docker images pushed to registry (from Guide 03)
✅ Kubernetes secrets created (from Guide 03)
✅ kubectl configured and connected

---

## Step 1: Prepare Kubernetes Manifests

We need to create Kubernetes configuration files for our application.

### 1.1 Create Manifests Directory

```bash
# Navigate to project
cd /mnt/d/Hackathons/hackathon-2/calm-orbit-todo/phase5-cloud

# Create directory for cloud manifests
mkdir -p k8s/cloud

# We'll create manifests in this directory
cd k8s/cloud
```

### 1.2 Create Backend Deployment Manifest

Create file: `backend-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: todo-app
  labels:
    app: backend
    version: v1.3.2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
        version: v1.3.2
    spec:
      containers:
      - name: backend
        image: registry.digitalocean.com/hackathon-todo-registry/todo-backend:v1.3.2
        ports:
        - containerPort: 8000
          name: http
        env:
        # Database Configuration
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: DATABASE_URL

        # Kafka Configuration
        - name: KAFKA_BOOTSTRAP_SERVERS
          valueFrom:
            secretKeyRef:
              name: kafka-secret
              key: KAFKA_BOOTSTRAP_SERVERS
        - name: KAFKA_SECURITY_PROTOCOL
          valueFrom:
            secretKeyRef:
              name: kafka-secret
              key: KAFKA_SECURITY_PROTOCOL
        - name: KAFKA_SASL_MECHANISM
          valueFrom:
            secretKeyRef:
              name: kafka-secret
              key: KAFKA_SASL_MECHANISM
        - name: KAFKA_SASL_USERNAME
          valueFrom:
            secretKeyRef:
              name: kafka-secret
              key: KAFKA_SASL_USERNAME
        - name: KAFKA_SASL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: kafka-secret
              key: KAFKA_SASL_PASSWORD

        # Application Configuration
        - name: ENVIRONMENT
          value: "production"
        - name: LOG_LEVEL
          value: "info"

        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"

        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3

      imagePullSecrets:
      - name: registry-hackathon-todo-registry
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: todo-app
  labels:
    app: backend
spec:
  type: LoadBalancer
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8000
    protocol: TCP
    name: http
  sessionAffinity: ClientIP
```

**Important Notes**:
- Replace `registry.digitalocean.com/hackathon-todo-registry` with your registry URL
- If using Docker Hub, use: `YOUR_DOCKERHUB_USERNAME/todo-backend:v1.3.2`
- `replicas: 2` means 2 backend pods for high availability
- `LoadBalancer` type will create a Digital Ocean Load Balancer ($12/month)

### 1.3 Create Frontend Deployment Manifest

First, we need to update the frontend environment variables for cloud deployment.

**Update frontend/.env.local**:

```bash
# Navigate to frontend directory
cd /mnt/d/Hackathons/hackathon-2/calm-orbit-todo/phase5-cloud/frontend

# Backup current .env.local
cp .env.local .env.local.backup

# We'll update this after we get the backend LoadBalancer URL
# For now, create a placeholder
```

Create file: `k8s/cloud/frontend-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: todo-app
  labels:
    app: frontend
    version: v1.0.0
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        version: v1.0.0
    spec:
      containers:
      - name: frontend
        image: registry.digitalocean.com/hackathon-todo-registry/todo-frontend:v1.0.0
        ports:
        - containerPort: 3000
          name: http
        env:
        # Feature Flags
        - name: NEXT_PUBLIC_FEATURE_NEW_CHAT
          value: "false"
        - name: NEXT_PUBLIC_FEATURE_NEW_AUTH
          value: "false"

        # Backend API URL (will be updated after backend deployment)
        - name: NEXT_PUBLIC_API_URL
          value: "http://BACKEND_LOADBALANCER_IP"

        # Better Auth Configuration
        - name: BETTER_AUTH_SECRET
          valueFrom:
            secretKeyRef:
              name: auth-secret
              key: BETTER_AUTH_SECRET
        - name: BETTER_AUTH_URL
          value: "http://FRONTEND_LOADBALANCER_IP"

        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "250m"

        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3

      imagePullSecrets:
      - name: registry-hackathon-todo-registry
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: todo-app
  labels:
    app: frontend
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
    name: http
  sessionAffinity: ClientIP
```

**Note**: We'll update `BACKEND_LOADBALANCER_IP` and `FRONTEND_LOADBALANCER_IP` after deployment.

---

## Step 2: Deploy Backend to DOKS

### 2.1 Apply Backend Manifest

```bash
# Navigate to manifests directory
cd /mnt/d/Hackathons/hackathon-2/calm-orbit-todo/phase5-cloud/k8s/cloud

# Apply backend deployment
kubectl apply -f backend-deployment.yaml

# Expected output:
# deployment.apps/backend-deployment created
# service/backend-service created
```

### 2.2 Monitor Backend Deployment

```bash
# Watch pods being created
kubectl get pods -n todo-app -w

# Expected output (after 1-2 minutes):
# NAME                                  READY   STATUS    RESTARTS   AGE
# backend-deployment-abc123-def456      1/1     Running   0          60s
# backend-deployment-abc123-ghi789      1/1     Running   0          60s
```

Press `Ctrl+C` to stop watching.

### 2.3 Check Backend Logs

```bash
# Get pod names
kubectl get pods -n todo-app -l app=backend

# View logs from first pod
kubectl logs -f deployment/backend-deployment -n todo-app --tail=50
```

**Look for these success messages**:
```
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Database connection established
INFO:     Kafka producer initialized
INFO:     Starting event consumers...
INFO:     Starting schedulers...
INFO:     Phase 5 services initialized successfully
```

If you see these messages, backend is working! ✅

### 2.4 Get Backend LoadBalancer IP

```bash
# Get service details
kubectl get service backend-service -n todo-app

# Expected output:
# NAME              TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)        AGE
# backend-service   LoadBalancer   10.245.123.45    143.198.123.45    80:30001/TCP   2m
```

**Wait for EXTERNAL-IP**: It may show `<pending>` for 2-3 minutes while Digital Ocean provisions the LoadBalancer.

Once you see an IP address (e.g., `143.198.123.45`), save it:

```bash
# Save backend IP
export BACKEND_IP=$(kubectl get service backend-service -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Verify
echo "Backend IP: $BACKEND_IP"
```

### 2.5 Test Backend Health

```bash
# Test health endpoint
curl http://$BACKEND_IP/health

# Expected output:
# {"status":"healthy","version":"1.3.2","database":"connected","kafka":"connected"}
```

If you get this response, backend is accessible from internet! ✅

### 2.6 Test Backend API

```bash
# Test API docs
curl http://$BACKEND_IP/docs

# Should return HTML for Swagger UI

# Test tasks endpoint (should return 401 - authentication required)
curl http://$BACKEND_IP/api/tasks

# Expected output:
# {"detail":"Not authenticated"}
```

This is correct - authentication is working! ✅

---

## Step 3: Update Frontend Configuration and Deploy

### 3.1 Rebuild Frontend with Backend URL

Now that we have the backend IP, we need to rebuild the frontend with the correct API URL.

```bash
# Navigate to frontend directory
cd /mnt/d/Hackathons/hackathon-2/calm-orbit-todo/phase5-cloud/frontend

# Update .env.local with backend IP
cat > .env.local << EOF
# Feature Flags
NEXT_PUBLIC_FEATURE_NEW_CHAT=false
NEXT_PUBLIC_FEATURE_NEW_AUTH=false

# Backend API URL (Cloud LoadBalancer)
NEXT_PUBLIC_API_URL=http://$BACKEND_IP

# Better Auth Configuration
BETTER_AUTH_SECRET=your-secret-key-here
BETTER_AUTH_URL=http://FRONTEND_LOADBALANCER_IP
EOF

# Display to verify
cat .env.local
```

### 3.2 Rebuild Frontend Docker Image

```bash
# Build new image with cloud configuration
docker build -t registry.digitalocean.com/hackathon-todo-registry/todo-frontend:v1.0.0 .

# Push to registry
docker push registry.digitalocean.com/hackathon-todo-registry/todo-frontend:v1.0.0
```

**Note**: If you already pushed v1.0.0, you can either:
- Use a new version tag (v1.0.1)
- Or overwrite the existing tag (not recommended in production, but OK for hackathon)

### 3.3 Update Frontend Manifest

Update `k8s/cloud/frontend-deployment.yaml`:

Replace:
```yaml
- name: NEXT_PUBLIC_API_URL
  value: "http://BACKEND_LOADBALANCER_IP"
```

With (use your actual backend IP):
```yaml
- name: NEXT_PUBLIC_API_URL
  value: "http://143.198.123.45"
```

Or use environment variable:
```bash
# Update manifest with backend IP
sed -i "s|http://BACKEND_LOADBALANCER_IP|http://$BACKEND_IP|g" /mnt/d/Hackathons/hackathon-2/calm-orbit-todo/phase5-cloud/k8s/cloud/frontend-deployment.yaml
```

### 3.4 Deploy Frontend

```bash
# Navigate to manifests directory
cd /mnt/d/Hackathons/hackathon-2/calm-orbit-todo/phase5-cloud/k8s/cloud

# Apply frontend deployment
kubectl apply -f frontend-deployment.yaml

# Expected output:
# deployment.apps/frontend-deployment created
# service/frontend-service created
```

### 3.5 Monitor Frontend Deployment

```bash
# Watch pods
kubectl get pods -n todo-app -l app=frontend -w

# Expected output (after 1-2 minutes):
# NAME                                   READY   STATUS    RESTARTS   AGE
# frontend-deployment-abc123-def456      1/1     Running   0          60s
# frontend-deployment-abc123-ghi789      1/1     Running   0          60s
```

### 3.6 Get Frontend LoadBalancer IP

```bash
# Get service details
kubectl get service frontend-service -n todo-app

# Wait for EXTERNAL-IP (2-3 minutes)
# Once available, save it:
export FRONTEND_IP=$(kubectl get service frontend-service -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Verify
echo "Frontend IP: $FRONTEND_IP"
```

### 3.7 Update Frontend with Its Own URL

We need to update the frontend one more time with its own LoadBalancer IP for Better Auth.

```bash
# Update manifest
sed -i "s|http://FRONTEND_LOADBALANCER_IP|http://$FRONTEND_IP|g" /mnt/d/Hackathons/hackathon-2/calm-orbit-todo/phase5-cloud/k8s/cloud/frontend-deployment.yaml

# Reapply
kubectl apply -f frontend-deployment.yaml

# Restart frontend pods to pick up new config
kubectl rollout restart deployment/frontend-deployment -n todo-app

# Wait for rollout to complete
kubectl rollout status deployment/frontend-deployment -n todo-app
```

---

## Step 4: Verify Complete Deployment

### 4.1 Check All Resources

```bash
# Check all pods
kubectl get pods -n todo-app

# Expected output:
# NAME                                   READY   STATUS    RESTARTS   AGE
# backend-deployment-abc123-def456       1/1     Running   0          10m
# backend-deployment-abc123-ghi789       1/1     Running   0          10m
# frontend-deployment-abc123-jkl012     1/1     Running   0          5m
# frontend-deployment-abc123-mno345     1/1     Running   0          5m

# Check services
kubectl get services -n todo-app

# Expected output:
# NAME               TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)        AGE
# backend-service    LoadBalancer   10.245.123.45    143.198.123.45    80:30001/TCP   10m
# frontend-service   LoadBalancer   10.245.67.89     143.198.67.89     80:30000/TCP   5m
```

All pods should show `Running` status and `1/1` ready. ✅

### 4.2 Test Backend from Internet

```bash
# Test health
curl http://$BACKEND_IP/health

# Test API docs (open in browser)
echo "Backend API Docs: http://$BACKEND_IP/docs"
```

Open the URL in your browser - you should see Swagger UI! ✅

### 4.3 Test Frontend from Internet

```bash
# Display frontend URL
echo "Frontend URL: http://$FRONTEND_IP"
```

Open the URL in your browser - you should see the Todo app! ✅

### 4.4 Test Complete Flow

1. **Open Frontend**: `http://$FRONTEND_IP`
2. **Sign Up**: Create a new account
3. **Login**: Login with your account
4. **Create Task**: Add a new task
5. **Verify Backend**: Check backend logs to see Kafka events

```bash
# Watch backend logs for events
kubectl logs -f deployment/backend-deployment -n todo-app --tail=20
```

You should see:
```
INFO: Task created event published to Kafka
INFO: Task event consumed: task_id=...
INFO: Audit log created for task creation
```

If you see these logs, Phase 5 event-driven architecture is working in the cloud! 🎉

---

## Step 5: Set Up Custom Domain (Optional)

If you want to use a custom domain instead of IP addresses:

### 5.1 Prerequisites

- You own a domain (e.g., `yourdomain.com`)
- Access to domain DNS settings

### 5.2 Create DNS Records

Add these A records in your domain DNS:

```
Type    Name        Value               TTL
A       api         143.198.123.45      300
A       app         143.198.67.89       300
```

Replace IPs with your actual LoadBalancer IPs.

### 5.3 Wait for DNS Propagation

```bash
# Check DNS propagation (may take 5-30 minutes)
nslookup api.yourdomain.com
nslookup app.yourdomain.com
```

### 5.4 Update Frontend Configuration

Once DNS is working, update frontend to use domain:

```bash
# Update manifest
kubectl edit deployment frontend-deployment -n todo-app
```

Change:
```yaml
- name: NEXT_PUBLIC_API_URL
  value: "http://api.yourdomain.com"
- name: BETTER_AUTH_URL
  value: "http://app.yourdomain.com"
```

Save and exit. Pods will automatically restart.

### 5.5 Set Up SSL (Recommended)

For HTTPS, you'll need:
1. Install cert-manager in cluster
2. Configure Let's Encrypt
3. Create Ingress resources
4. Update services to use Ingress

This is beyond hackathon scope, but here's a quick guide:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=120s
```

Then create Ingress resources with TLS configuration. (Full guide available if needed)

---

## Step 6: Monitor and Maintain

### 6.1 View Logs

```bash
# Backend logs
kubectl logs -f deployment/backend-deployment -n todo-app

# Frontend logs
kubectl logs -f deployment/frontend-deployment -n todo-app

# Logs from specific pod
kubectl logs POD_NAME -n todo-app

# Previous logs (if pod restarted)
kubectl logs POD_NAME -n todo-app --previous
```

### 6.2 Check Resource Usage

```bash
# Pod resource usage
kubectl top pods -n todo-app

# Node resource usage
kubectl top nodes
```

### 6.3 Scale Deployments

If you need more capacity:

```bash
# Scale backend to 3 replicas
kubectl scale deployment backend-deployment --replicas=3 -n todo-app

# Scale frontend to 3 replicas
kubectl scale deployment frontend-deployment --replicas=3 -n todo-app

# Verify
kubectl get pods -n todo-app
```

### 6.4 Update Application

When you make code changes:

```bash
# 1. Build new image
docker build -t registry.digitalocean.com/hackathon-todo-registry/todo-backend:v1.3.3 .

# 2. Push to registry
docker push registry.digitalocean.com/hackathon-todo-registry/todo-backend:v1.3.3

# 3. Update deployment
kubectl set image deployment/backend-deployment backend=registry.digitalocean.com/hackathon-todo-registry/todo-backend:v1.3.3 -n todo-app

# 4. Watch rollout
kubectl rollout status deployment/backend-deployment -n todo-app
```

### 6.5 Rollback if Needed

If new version has issues:

```bash
# Rollback to previous version
kubectl rollout undo deployment/backend-deployment -n todo-app

# Check rollout history
kubectl rollout history deployment/backend-deployment -n todo-app

# Rollback to specific revision
kubectl rollout undo deployment/backend-deployment --to-revision=2 -n todo-app
```

---

## Troubleshooting

### Issue 1: Pods in CrashLoopBackOff

**Check logs**:
```bash
kubectl logs POD_NAME -n todo-app
kubectl describe pod POD_NAME -n todo-app
```

**Common causes**:
- Database connection failed (check DATABASE_URL secret)
- Kafka connection failed (check Kafka credentials)
- Missing environment variables
- Application error in code

**Solution**:
```bash
# Verify secrets exist
kubectl get secrets -n todo-app

# Check secret values (base64 encoded)
kubectl get secret database-secret -n todo-app -o yaml

# Recreate secret if wrong
kubectl delete secret database-secret -n todo-app
kubectl create secret generic database-secret --from-literal=DATABASE_URL='...' -n todo-app

# Restart deployment
kubectl rollout restart deployment/backend-deployment -n todo-app
```

### Issue 2: LoadBalancer Stuck in Pending

**Check status**:
```bash
kubectl describe service backend-service -n todo-app
```

**Common causes**:
- Digital Ocean provisioning delay (wait 5 minutes)
- Account limit reached
- Region doesn't support LoadBalancers

**Solution**:
```bash
# Wait longer (up to 10 minutes)
kubectl get service backend-service -n todo-app -w

# If still pending after 10 minutes, delete and recreate
kubectl delete service backend-service -n todo-app
kubectl apply -f backend-deployment.yaml
```

### Issue 3: ImagePullBackOff

**Check logs**:
```bash
kubectl describe pod POD_NAME -n todo-app
```

**Common causes**:
- Image doesn't exist in registry
- Wrong image name/tag
- Registry authentication failed

**Solution**:
```bash
# Verify image exists
doctl registry repository list-tags todo-backend

# Verify registry secret
kubectl get secret registry-hackathon-todo-registry -n todo-app

# Recreate registry integration
doctl registry kubernetes-manifest | kubectl apply -f -

# Restart deployment
kubectl rollout restart deployment/backend-deployment -n todo-app
```

### Issue 4: Frontend Can't Connect to Backend

**Check**:
1. Backend LoadBalancer IP is correct in frontend config
2. Backend is actually accessible from internet
3. CORS is configured correctly in backend

**Solution**:
```bash
# Test backend from internet
curl http://$BACKEND_IP/health

# Check frontend environment variables
kubectl describe deployment frontend-deployment -n todo-app | grep NEXT_PUBLIC_API_URL

# Update if wrong
kubectl edit deployment frontend-deployment -n todo-app
# Change NEXT_PUBLIC_API_URL value
# Save and exit (pods will restart automatically)
```

### Issue 5: Database Connection Errors

**Check logs**:
```bash
kubectl logs deployment/backend-deployment -n todo-app | grep -i database
```

**Common causes**:
- Wrong DATABASE_URL
- Neon database not accessible from DOKS
- SSL mode not configured

**Solution**:
```bash
# Verify DATABASE_URL format
# Should be: postgresql+asyncpg://user:pass@host/db?sslmode=require

# Test connection from pod
kubectl exec -it deployment/backend-deployment -n todo-app -- /bin/bash
# Inside pod:
python -c "import asyncpg; import asyncio; asyncio.run(asyncpg.connect('postgresql://...'))"

# If connection fails, check Neon dashboard for allowed IPs
# Neon should allow all IPs by default, but verify
```

### Issue 6: Kafka Connection Errors

**Check logs**:
```bash
kubectl logs deployment/backend-deployment -n todo-app | grep -i kafka
```

**Common causes**:
- Wrong Kafka credentials
- Wrong bootstrap servers
- SASL configuration incorrect

**Solution**:
```bash
# Verify Kafka secret
kubectl get secret kafka-secret -n todo-app -o yaml

# Test Kafka connection from pod
kubectl exec -it deployment/backend-deployment -n todo-app -- /bin/bash
# Inside pod, try to connect with rpk or kafkacat

# Recreate secret with correct values
kubectl delete secret kafka-secret -n todo-app
kubectl create secret generic kafka-secret \
  --from-literal=KAFKA_BOOTSTRAP_SERVERS='...' \
  --from-literal=KAFKA_SECURITY_PROTOCOL='SASL_SSL' \
  --from-literal=KAFKA_SASL_MECHANISM='SCRAM-SHA-256' \
  --from-literal=KAFKA_SASL_USERNAME='...' \
  --from-literal=KAFKA_SASL_PASSWORD='...' \
  -n todo-app

# Restart deployment
kubectl rollout restart deployment/backend-deployment -n todo-app
```

---

## Cost Breakdown

### Current Costs

| Resource | Cost | Notes |
|----------|------|-------|
| DOKS Cluster (2 nodes) | $24/month | Basic nodes (2GB RAM each) |
| Backend LoadBalancer | $12/month | Digital Ocean Load Balancer |
| Frontend LoadBalancer | $12/month | Digital Ocean Load Balancer |
| Container Registry | Free | First 500MB free |
| **Total** | **$48/month** | **Covered by $200 credit** |

### Optimization Tips

**To reduce costs**:

1. **Use NodePort instead of LoadBalancer** (saves $24/month):
   - Change service type from `LoadBalancer` to `NodePort`
   - Access via: `http://NODE_IP:NODE_PORT`
   - Not recommended for production, but OK for hackathon demo

2. **Use single LoadBalancer with Ingress** (saves $12/month):
   - Deploy Ingress controller
   - Use path-based routing (`/api` → backend, `/` → frontend)
   - Only one LoadBalancer needed

3. **Reduce replicas** (saves $12/month):
   - Change replicas from 2 to 1 for both deployments
   - Less high availability, but cheaper

4. **Use smaller nodes** (saves $12/month):
   - Change from 2GB to 1GB nodes
   - May have performance issues

**Recommended for hackathon**: Keep current setup ($48/month) for best reliability.

---

## Next Steps

✅ **You've completed application deployment!**

**What we have now**:
- ✅ Backend deployed to DOKS (2 replicas)
- ✅ Frontend deployed to DOKS (2 replicas)
- ✅ LoadBalancers configured and working
- ✅ Application accessible from internet
- ✅ Phase 5 features working in cloud

**Next Guide**: `05-verification-and-testing.md`
- Comprehensive testing of all features
- Performance testing
- Phase 5 features verification
- Final checklist for hackathon submission

---

## Quick Reference

### Your Application URLs

```bash
# Backend API
echo "Backend: http://$BACKEND_IP"
echo "API Docs: http://$BACKEND_IP/docs"

# Frontend
echo "Frontend: http://$FRONTEND_IP"
```

### Important Commands

```bash
# Check deployment status
kubectl get all -n todo-app

# View logs
kubectl logs -f deployment/backend-deployment -n todo-app
kubectl logs -f deployment/frontend-deployment -n todo-app

# Restart deployments
kubectl rollout restart deployment/backend-deployment -n todo-app
kubectl rollout restart deployment/frontend-deployment -n todo-app

# Scale deployments
kubectl scale deployment backend-deployment --replicas=3 -n todo-app

# Update image
kubectl set image deployment/backend-deployment backend=registry.digitalocean.com/hackathon-todo-registry/todo-backend:NEW_VERSION -n todo-app

# Rollback
kubectl rollout undo deployment/backend-deployment -n todo-app
```

### Monitoring

```bash
# Resource usage
kubectl top pods -n todo-app
kubectl top nodes

# Events
kubectl get events -n todo-app --sort-by='.lastTimestamp'

# Describe resources
kubectl describe deployment backend-deployment -n todo-app
kubectl describe pod POD_NAME -n todo-app
```

---

**Status**: ✅ Application deployed and running in cloud!
**Time Taken**: ~45-60 minutes
**Cost**: $48/month (covered by $200 credit)
**Remaining Credit**: ~$195
