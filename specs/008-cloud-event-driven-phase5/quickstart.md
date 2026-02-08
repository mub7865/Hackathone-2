# Phase 5 Quickstart Guide

**Feature**: Cloud-Native Event-Driven Todo Application
**Branch**: `008-cloud-event-driven-phase5`
**Implementation Directory**: `calm-orbit-todo/phase5-cloud/`
**Date**: 2026-01-11

## Overview

This guide provides step-by-step instructions to set up and deploy Phase 5 of the Calm Orbit Todo application. Phase 5 transforms the local Kubernetes deployment (Phase IV) into a production-ready cloud-native system with event-driven architecture.

**⚠️ IMPORTANT**: Phase 5 **builds on existing work** from Phase 2-3 (backend/frontend) and Phase 4 (Kubernetes/Docker). We will **copy and modify** existing code, not recreate from scratch.

**Implementation Location**: All Phase 5 code is in `calm-orbit-todo/phase5-cloud/` directory.

**Estimated Setup Time**: 2-3 hours (first time)

---

## Step 0: Migration from Phase 2-3-4 (REQUIRED FIRST STEP)

**Purpose**: Copy existing working code from previous phases to Phase 5 directory

### 1. Copy Backend Code (Phase 2-3)

```bash
cd calm-orbit-todo

# Copy entire backend directory
cp -r phase2-3-fullstack/backend/* phase5-cloud/backend/

# Verify copy
ls -la phase5-cloud/backend/app/
# Should see: api/, core/, models/, mcp_tools/, main.py, etc.
```

### 2. Copy Frontend Code (Phase 2-3)

```bash
# Copy entire frontend directory
cp -r phase2-3-fullstack/frontend/* phase5-cloud/frontend/

# Verify copy
ls -la phase5-cloud/frontend/
# Should see: app/, components/, lib/, package.json, etc.
```

### 3. Copy Docker Configuration (Phase 4)

```bash
# Copy Dockerfiles
cp phase4-k8s-deployment/backend.Dockerfile phase5-cloud/backend/Dockerfile
cp phase4-k8s-deployment/frontend.Dockerfile phase5-cloud/frontend/Dockerfile

# Verify copy
ls -la phase5-cloud/backend/Dockerfile
ls -la phase5-cloud/frontend/Dockerfile
```

### 4. Copy Helm Charts (Phase 4)

```bash
# Copy Helm charts
cp -r phase4-k8s-deployment/helm-charts/* phase5-cloud/charts/

# Verify copy
ls -la phase5-cloud/charts/
# Should see Helm chart structure
```

### 5. Create New Microservices Structure

```bash
# Create directory structure for 4 new microservices
cd phase5-cloud
mkdir -p services/{recurring-task-service,notification-service,audit-service,websocket-service}/app

# Verify structure
tree services/ -L 2
```

**✅ Checkpoint**: You should now have all Phase 2-3-4 code in `phase5-cloud/` directory. Phase 5 will **modify and extend** this existing code.

---

## Prerequisites

### Required Accounts (All Free Tier)
- ✅ **DigitalOcean Account**: $200 credit for new accounts (60-day validity)
- ✅ **Redpanda Cloud Account**: Free tier (10 MB/s ingress, 30 MB/s egress)
- ✅ **Neon Postgres Account**: Already configured from Phase III
- ✅ **SendGrid Account**: Free tier (100 emails/day)
- ✅ **GitHub Account**: For CI/CD with GitHub Actions

### Required Tools
- ✅ **kubectl**: Kubernetes CLI (v1.28+)
- ✅ **doctl**: DigitalOcean CLI
- ✅ **helm**: Kubernetes package manager (v3.12+)
- ✅ **dapr**: Dapr CLI (v1.12+)
- ✅ **docker**: Docker CLI (v24.0+)
- ✅ **git**: Version control
- ✅ **python**: Python 3.13+ (for local development)
- ✅ **node**: Node.js 20+ (for frontend)

### Local Development (Optional)
- ✅ **Minikube**: Already configured from Phase IV
- ✅ **Docker Compose**: For local testing

---

## Phase 0: Account Setup

### 1. DigitalOcean Setup

```bash
# Install doctl (DigitalOcean CLI)
# macOS
brew install doctl

# Linux
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz
tar xf doctl-1.104.0-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin

# Authenticate
doctl auth init
# Enter your DigitalOcean API token (create at: https://cloud.digitalocean.com/account/api/tokens)

# Verify authentication
doctl account get
```

### 2. Redpanda Cloud Setup

```bash
# Sign up at: https://redpanda.com/try-redpanda/cloud-trial
# Create a Serverless cluster (free tier)
# Note down:
# - Bootstrap servers (e.g., redpanda-xyz.cloud.redpanda.com:9092)
# - SASL username
# - SASL password

# Create 3 topics
# Via Redpanda Console (https://cloud.redpanda.com):
# 1. task-events (3 partitions, 7-day retention)
# 2. reminders (3 partitions, 7-day retention)
# 3. task-updates (3 partitions, 7-day retention)
```

### 3. SendGrid Setup

```bash
# Sign up at: https://signup.sendgrid.com/
# Create API key at: https://app.sendgrid.com/settings/api_keys
# Permissions: Full Access (for demo) or Mail Send (production)
# Note down the API key (starts with SG.)

# Verify sender identity (required for free tier)
# Go to: https://app.sendgrid.com/settings/sender_auth
# Add and verify your email address
```

### 4. GitHub Repository Setup

```bash
# Fork or clone the repository
git clone https://github.com/your-username/hackathon-2.git
cd hackathon-2

# Checkout Phase 5 branch
git checkout 008-cloud-event-driven-phase5

# Set up GitHub Secrets (for CI/CD)
# Go to: https://github.com/your-username/hackathon-2/settings/secrets/actions
# Add the following secrets:
# - DIGITALOCEAN_ACCESS_TOKEN: Your DigitalOcean API token
# - REDPANDA_BOOTSTRAP_SERVERS: Redpanda bootstrap servers
# - REDPANDA_SASL_USERNAME: Redpanda SASL username
# - REDPANDA_SASL_PASSWORD: Redpanda SASL password
# - SENDGRID_API_KEY: SendGrid API key
# - NEON_DATABASE_URL: Neon Postgres connection string (from Phase III)
```

---

## Phase 1: Infrastructure Setup

### 1. Create DigitalOcean Kubernetes Cluster

```bash
# Create 2-node DOKS cluster (free tier budget)
doctl kubernetes cluster create calm-orbit-todo \
  --region nyc1 \
  --version 1.28.2-do.0 \
  --node-pool "name=worker-pool;size=s-2vcpu-4gb;count=2;auto-scale=true;min-nodes=2;max-nodes=4" \
  --wait

# Configure kubectl
doctl kubernetes cluster kubeconfig save calm-orbit-todo

# Verify cluster
kubectl get nodes
# Expected output:
# NAME                   STATUS   ROLES    AGE   VERSION
# worker-pool-xxxxx      Ready    <none>   2m    v1.28.2
# worker-pool-yyyyy      Ready    <none>   2m    v1.28.2
```

**Cost Estimate**: ~$24/month per node × 2 nodes = $48/month (covered by $200 credit for 4+ months)

### 2. Install Dapr on DOKS

```bash
# Install Dapr CLI (if not already installed)
wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash

# Initialize Dapr on Kubernetes
dapr init --kubernetes --wait

# Verify Dapr installation
dapr status -k
# Expected output:
# NAME                   NAMESPACE    HEALTHY  STATUS   REPLICAS  VERSION  AGE  CREATED
# dapr-sidecar-injector  dapr-system  True     Running  1         1.12.0   1m   2024-01-11 10:30:00
# dapr-sentry            dapr-system  True     Running  1         1.12.0   1m   2024-01-11 10:30:00
# dapr-operator          dapr-system  True     Running  1         1.12.0   1m   2024-01-11 10:30:00
# dapr-placement         dapr-system  True     Running  1         1.12.0   1m   2024-01-11 10:30:00

kubectl get pods -n dapr-system
```

### 3. Create Kubernetes Namespace

```bash
# Create namespace for the application
kubectl create namespace calm-orbit-todo

# Set as default namespace (optional)
kubectl config set-context --current --namespace=calm-orbit-todo
```

### 4. Create Kubernetes Secrets

```bash
# Create secret for Neon Postgres
kubectl create secret generic neon-postgres \
  --from-literal=database-url="postgresql://user:password@host.neon.tech/dbname?sslmode=require" \
  -n calm-orbit-todo

# Create secret for Redpanda
kubectl create secret generic redpanda-kafka \
  --from-literal=bootstrap-servers="redpanda-xyz.cloud.redpanda.com:9092" \
  --from-literal=sasl-username="your-username" \
  --from-literal=sasl-password="your-password" \
  -n calm-orbit-todo

# Create secret for SendGrid
kubectl create secret generic sendgrid \
  --from-literal=api-key="SG.your-api-key" \
  -n calm-orbit-todo

# Create secret for JWT (from Phase II)
kubectl create secret generic jwt-secret \
  --from-literal=secret-key="your-jwt-secret-key" \
  -n calm-orbit-todo

# Verify secrets
kubectl get secrets -n calm-orbit-todo
```

### 5. Deploy Dapr Components

```bash
# Apply Dapr Pub/Sub component (Kafka)
kubectl apply -f k8s/dapr/pubsub-kafka.yaml

# Apply Dapr State component (PostgreSQL)
kubectl apply -f k8s/dapr/state-postgresql.yaml

# Apply Dapr Bindings component (Cron)
kubectl apply -f k8s/dapr/bindings-cron.yaml

# Apply Dapr Secrets component (Kubernetes)
kubectl apply -f k8s/dapr/secrets-kubernetes.yaml

# Verify Dapr components
kubectl get components -n calm-orbit-todo
# Expected output:
# NAME                 AGE
# pubsub-kafka         1m
# state-postgresql     1m
# bindings-cron        1m
# secretstores-k8s     1m
```

---

## Phase 2: Database Migration

### 1. Run Alembic Migration

```bash
# Navigate to Phase 5 backend directory
cd calm-orbit-todo/phase5-cloud/backend

# Install dependencies (if not already installed)
pip install -r requirements.txt

# Set database URL environment variable
export DATABASE_URL="postgresql://user:password@host.neon.tech/dbname?sslmode=require"

# Run migration
alembic upgrade head

# Verify migration
alembic current
# Expected output: 005_phase5_schema (head)

# Check new tables
psql $DATABASE_URL -c "\dt"
# Expected tables:
# - tasks (modified)
# - recurring_patterns (new)
# - audit_log (new)
# - notification_preferences (new)
# - saved_filters (new)
# - processed_events (new)
```

---

## Phase 3: Build and Push Docker Images

### 1. Set Up DigitalOcean Container Registry

```bash
# Create container registry
doctl registry create calm-orbit-todo

# Authenticate Docker with registry
doctl registry login

# Get registry URL
doctl registry get
# Note down the registry URL (e.g., registry.digitalocean.com/calm-orbit-todo)
```

### 2. Build and Push Images

```bash
# Navigate to Phase 5 directory
cd calm-orbit-todo/phase5-cloud

# Set registry URL
export REGISTRY_URL="registry.digitalocean.com/calm-orbit-todo"

# Build and push backend image
cd backend
docker build -t $REGISTRY_URL/backend:v5.0.0 .
docker push $REGISTRY_URL/backend:v5.0.0

# Build and push frontend image
cd ../frontend
docker build -t $REGISTRY_URL/frontend:v5.0.0 .
docker push $REGISTRY_URL/frontend:v5.0.0

# Build and push recurring-task-service image
cd ../services/recurring-task-service
docker build -t $REGISTRY_URL/recurring-task-service:v5.0.0 .
docker push $REGISTRY_URL/recurring-task-service:v5.0.0

# Build and push notification-service image
cd ../notification-service
docker build -t $REGISTRY_URL/notification-service:v5.0.0 .
docker push $REGISTRY_URL/notification-service:v5.0.0

# Build and push audit-service image
cd ../audit-service
docker build -t $REGISTRY_URL/audit-service:v5.0.0 .
docker push $REGISTRY_URL/audit-service:v5.0.0

# Build and push websocket-service image
cd ../websocket-service
docker build -t $REGISTRY_URL/websocket-service:v5.0.0 .
docker push $REGISTRY_URL/websocket-service:v5.0.0

# Verify images
doctl registry repository list-v2
```

---

## Phase 4: Deploy Application

### Option A: Deploy with Kubectl

```bash
# Navigate to Phase 5 directory
cd calm-orbit-todo/phase5-cloud

# Deploy all services
kubectl apply -f k8s/base/

# Verify deployments
kubectl get deployments -n calm-orbit-todo
# Expected output:
# NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
# backend                 2/2     2            2           2m
# frontend                2/2     2            2           2m
# recurring-task-service  1/1     1            1           2m
# notification-service    1/1     1            1           2m
# audit-service           1/1     1            1           2m
# websocket-service       1/1     1            1           2m

# Verify pods
kubectl get pods -n calm-orbit-todo
# All pods should be Running with 2/2 containers (app + dapr sidecar)

# Check Dapr sidecars
kubectl get pods -n calm-orbit-todo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'
```

### Option B: Deploy with Helm

```bash
# Update Helm values
cd charts/todo-chatbot
cp values.yaml values-phase5.yaml

# Edit values-phase5.yaml:
# - Update image.repository to your registry URL
# - Update image.tag to v5.0.0
# - Enable Dapr annotations
# - Configure Kafka, Postgres, SendGrid settings

# Install or upgrade Helm release
helm upgrade --install calm-orbit-todo . \
  -f values-phase5.yaml \
  -n calm-orbit-todo \
  --create-namespace

# Verify release
helm list -n calm-orbit-todo
helm status calm-orbit-todo -n calm-orbit-todo
```

---

## Phase 5: Configure Ingress and DNS

### 1. Install Nginx Ingress Controller

```bash
# Install Nginx Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/do/deploy.yaml

# Wait for LoadBalancer IP
kubectl get svc -n ingress-nginx ingress-nginx-controller --watch
# Note down the EXTERNAL-IP (e.g., 143.198.123.45)
```

### 2. Configure DNS (Optional)

```bash
# Option 1: Use DigitalOcean DNS
# Go to: https://cloud.digitalocean.com/networking/domains
# Add A record: calm-orbit-todo.yourdomain.com -> EXTERNAL-IP

# Option 2: Use /etc/hosts for local testing
echo "143.198.123.45 calm-orbit-todo.local" | sudo tee -a /etc/hosts
```

### 3. Apply Ingress

```bash
# Apply Ingress configuration
kubectl apply -f k8s/base/ingress.yaml

# Verify Ingress
kubectl get ingress -n calm-orbit-todo
# Expected output:
# NAME                CLASS   HOSTS                          ADDRESS          PORTS   AGE
# calm-orbit-ingress  nginx   calm-orbit-todo.yourdomain.com 143.198.123.45   80      1m
```

### 4. Configure TLS/SSL (Optional)

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Create ClusterIssuer for Let's Encrypt
kubectl apply -f k8s/base/cert-issuer.yaml

# Update Ingress with TLS
kubectl apply -f k8s/base/ingress-tls.yaml

# Verify certificate
kubectl get certificate -n calm-orbit-todo
```

---

## Phase 6: Deploy Monitoring Stack

### 1. Deploy Prometheus

```bash
# Deploy Prometheus
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/prometheus-deployment.yaml

# Verify Prometheus
kubectl get pods -n calm-orbit-todo -l app=prometheus
kubectl port-forward -n calm-orbit-todo svc/prometheus 9090:9090

# Access Prometheus UI: http://localhost:9090
```

### 2. Deploy Grafana

```bash
# Deploy Grafana
kubectl apply -f k8s/monitoring/grafana-deployment.yaml
kubectl apply -f k8s/monitoring/grafana-dashboards.yaml

# Get Grafana admin password
kubectl get secret -n calm-orbit-todo grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Port-forward Grafana
kubectl port-forward -n calm-orbit-todo svc/grafana 3000:3000

# Access Grafana UI: http://localhost:3000
# Login: admin / <password-from-above>

# Add Prometheus data source:
# - URL: http://prometheus:9090
# - Access: Server (default)

# Import pre-configured dashboards from k8s/monitoring/grafana-dashboards.yaml
```

---

## Phase 7: Verify Deployment

### 1. Health Checks

```bash
# Check all pods are running
kubectl get pods -n calm-orbit-todo

# Check service health endpoints
kubectl port-forward -n calm-orbit-todo svc/backend 8000:8000
curl http://localhost:8000/health/live
curl http://localhost:8000/health/ready

# Check Dapr components
dapr components -k -n calm-orbit-todo
```

### 2. Test Event Flow

```bash
# Port-forward backend
kubectl port-forward -n calm-orbit-todo svc/backend 8000:8000

# Create a task via Chat API (requires JWT token)
curl -X POST http://localhost:8000/api/v1/chat \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Create a task: Test event flow"}'

# Check audit log
kubectl logs -n calm-orbit-todo -l app=audit-service --tail=50

# Check Kafka topics (via Redpanda Console)
# Go to: https://cloud.redpanda.com
# Navigate to Topics -> task-events
# Verify event was published
```

### 3. Test WebSocket Connection

```bash
# Port-forward WebSocket service
kubectl port-forward -n calm-orbit-todo svc/websocket-service 8004:8004

# Test WebSocket connection (using wscat)
npm install -g wscat
wscat -c "ws://localhost:8004/ws/YOUR_USER_ID?token=YOUR_JWT_TOKEN"

# Create a task in another terminal
# Verify WebSocket receives real-time update
```

---

## Phase 8: CI/CD Pipeline Setup

### 1. Configure GitHub Actions

```bash
# GitHub Actions workflows are already configured in .github/workflows/

# Verify workflows:
# - backend-ci.yaml: Backend tests and build
# - frontend-ci.yaml: Frontend tests and build
# - deploy-doks.yaml: Deploy to DOKS
# - security-scan.yaml: Security scanning

# Push to main branch to trigger deployment
git add .
git commit -m "Phase 5: Cloud deployment"
git push origin 008-cloud-event-driven-phase5

# Create pull request and merge to main
# GitHub Actions will automatically deploy to DOKS
```

### 2. Monitor Deployment

```bash
# Watch GitHub Actions
# Go to: https://github.com/your-username/hackathon-2/actions

# Monitor deployment logs
kubectl logs -n calm-orbit-todo -l app=backend --tail=100 -f

# Verify new version
kubectl get deployments -n calm-orbit-todo -o wide
```

---

## Troubleshooting

### Common Issues

#### 1. Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n calm-orbit-todo

# Check logs
kubectl logs <pod-name> -n calm-orbit-todo -c <container-name>

# Check Dapr sidecar logs
kubectl logs <pod-name> -n calm-orbit-todo -c daprd
```

#### 2. Dapr Components Not Working

```bash
# Check Dapr component status
kubectl get components -n calm-orbit-todo

# Check Dapr logs
kubectl logs -n dapr-system -l app=dapr-operator

# Verify secrets
kubectl get secrets -n calm-orbit-todo
```

#### 3. Database Connection Issues

```bash
# Test database connection
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql "postgresql://user:password@host.neon.tech/dbname?sslmode=require"

# Check database URL in secret
kubectl get secret neon-postgres -n calm-orbit-todo -o jsonpath="{.data.database-url}" | base64 --decode
```

#### 4. Kafka Connection Issues

```bash
# Test Kafka connection (from a pod)
kubectl run -it --rm kafka-test --image=confluentinc/cp-kafka:7.5.0 --restart=Never -- \
  kafka-console-consumer \
  --bootstrap-server redpanda-xyz.cloud.redpanda.com:9092 \
  --topic task-events \
  --from-beginning \
  --consumer-property security.protocol=SASL_SSL \
  --consumer-property sasl.mechanism=SCRAM-SHA-256 \
  --consumer-property sasl.jaas.config="org.apache.kafka.common.security.scram.ScramLoginModule required username='your-username' password='your-password';"
```

---

## Cost Monitoring

### DigitalOcean Costs

```bash
# Check current usage
doctl balance get

# Monitor cluster costs
doctl kubernetes cluster get calm-orbit-todo

# Expected monthly costs (within $200 credit):
# - 2-node cluster: ~$48/month
# - LoadBalancer: ~$12/month
# - Container Registry: Free (500 MB)
# Total: ~$60/month (covered by $200 credit for 3+ months)
```

### Free Tier Limits

- **Redpanda Cloud Serverless**: 10 MB/s ingress, 30 MB/s egress (sufficient for demo)
- **Neon Postgres**: 0.5 GB storage, 1 compute unit (sufficient for demo)
- **SendGrid**: 100 emails/day (sufficient for demo with 10-20 users)
- **DigitalOcean**: $200 credit for 60 days (covers all infrastructure)

---

## Next Steps

1. ✅ Infrastructure deployed and verified
2. ⏭️ Implement Phase 2: Advanced Features (Recurring Tasks, Notifications)
3. ⏭️ Implement Phase 3: Real-Time Updates (WebSocket)
4. ⏭️ Implement Phase 4: Intermediate Features (Priorities, Tags, Search, Filter, Sort)
5. ⏭️ Load testing with 100-200 concurrent users
6. ⏭️ Security hardening and penetration testing
7. ⏭️ Documentation and demo video

---

## Useful Commands

```bash
# View all resources
kubectl get all -n calm-orbit-todo

# View logs for all services
kubectl logs -n calm-orbit-todo -l app=backend --tail=50
kubectl logs -n calm-orbit-todo -l app=recurring-task-service --tail=50
kubectl logs -n calm-orbit-todo -l app=notification-service --tail=50
kubectl logs -n calm-orbit-todo -l app=audit-service --tail=50
kubectl logs -n calm-orbit-todo -l app=websocket-service --tail=50

# Scale deployments
kubectl scale deployment backend --replicas=3 -n calm-orbit-todo

# Restart deployment
kubectl rollout restart deployment backend -n calm-orbit-todo

# View Dapr dashboard
dapr dashboard -k -n calm-orbit-todo

# Delete everything (cleanup)
kubectl delete namespace calm-orbit-todo
doctl kubernetes cluster delete calm-orbit-todo
doctl registry delete calm-orbit-todo
```

---

## Support

For issues or questions:
- GitHub Issues: https://github.com/your-username/hackathon-2/issues
- Documentation: See `specs/008-cloud-event-driven-phase5/`
- Slack: #calm-orbit-todo (if applicable)
