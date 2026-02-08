# Complete Cloud Deployment Guide - Master Index

**Project**: Calm Orbit Todo - Phase 5 Cloud Deployment
**Target Platform**: Digital Ocean Kubernetes (DOKS)
**Total Time**: ~2.5 hours
**Total Cost**: ~$48/month (covered by $200 free credit)

---

## 📋 Overview

This master guide will help you deploy the complete Calm Orbit Todo application (with Phase 5 features) to the cloud. The application includes:

- **Backend**: FastAPI with Phase 5 features (recurring tasks, reminders, priorities, tags, due dates)
- **Frontend**: Next.js 15 with Better Auth
- **Database**: Neon Serverless PostgreSQL (already configured)
- **Event Streaming**: Redpanda Cloud (Kafka-compatible)
- **Orchestration**: Digital Ocean Kubernetes (DOKS)

---

## 🎯 What You'll Achieve

By the end of this deployment, you'll have:

✅ Full-stack application running in Kubernetes
✅ Event-driven architecture with Kafka
✅ High availability (2 replicas per service)
✅ LoadBalancers for internet access
✅ All Phase 5 features working in production
✅ Comprehensive monitoring and logging
✅ Ready for hackathon submission

---

## 📚 Deployment Guides

### Guide 01: Digital Ocean Account Setup
**File**: `01-digital-ocean-setup.md`
**Time**: 15-20 minutes
**Cost**: $0 (free $200 credit)

**What You'll Do**:
- Create Digital Ocean account
- Activate $200 free credit
- Install and configure `doctl` CLI
- Authenticate with API token

**Prerequisites**: Email, credit card (for verification only)

---

### Guide 02: Redpanda Cloud Setup
**File**: `02-redpanda-cloud-setup.md`
**Time**: 15-20 minutes
**Cost**: $0 (free tier)

**What You'll Do**:
- Create Redpanda Cloud account
- Create Kafka cluster
- Create 4 topics (task-events, recurring-task-events, reminder-events, notification-events)
- Set up service account and API keys
- Configure ACLs (permissions)

**Prerequisites**: Email, GitHub account (optional)

---

### Guide 03: DOKS Cluster Deployment
**File**: `03-doks-cluster-deployment.md`
**Time**: 30-40 minutes
**Cost**: ~$24/month (cluster)

**What You'll Do**:
- Create Kubernetes cluster (2 nodes)
- Configure `kubectl`
- Set up container registry
- Push Docker images
- Create Kubernetes secrets
- Install Kubernetes Dashboard (optional)

**Prerequisites**: Guides 01 & 02 completed

---

### Guide 04: Application Deployment
**File**: `04-application-deployment.md`
**Time**: 45-60 minutes
**Cost**: ~$24/month (LoadBalancers)

**What You'll Do**:
- Create Kubernetes manifests
- Deploy backend to DOKS
- Deploy frontend to DOKS
- Configure LoadBalancers
- Update environment variables
- Test complete deployment

**Prerequisites**: Guide 03 completed

---

### Guide 05: Verification and Testing
**File**: `05-verification-and-testing.md`
**Time**: 30-45 minutes
**Cost**: $0 (included)

**What You'll Do**:
- Test all CRUD operations
- Verify Phase 5 features
- Test event-driven architecture
- Performance testing
- Stability testing
- Prepare hackathon submission

**Prerequisites**: Guide 04 completed

---

## 🚀 Quick Start (For Experienced Users)

If you're familiar with Kubernetes and cloud deployments, here's the express path:

### Step 1: Accounts (15 min)
```bash
# Digital Ocean
# 1. Sign up: https://www.digitalocean.com/
# 2. Activate $200 credit
# 3. Install doctl: wget https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz
# 4. Authenticate: doctl auth init

# Redpanda Cloud
# 1. Sign up: https://redpanda.com/try-redpanda
# 2. Create cluster (Serverless, AWS)
# 3. Create topics: task-events, recurring-task-events, reminder-events, notification-events
# 4. Create service account and API key
# 5. Configure ACLs (Write, Read, Create, Describe, Group)
```

### Step 2: DOKS Cluster (10 min)
```bash
# Create cluster
doctl kubernetes cluster create hackathon-todo-cluster \
  --region nyc3 \
  --version 1.28.2-do.0 \
  --node-pool "name=worker-pool;size=s-2vcpu-2gb;count=2;auto-scale=false" \
  --wait

# Create namespace
kubectl create namespace todo-app
kubectl config set-context --current --namespace=todo-app

# Set up registry
doctl registry create hackathon-todo-registry
doctl registry login
doctl registry kubernetes-manifest | kubectl apply -f -
```

### Step 3: Push Images (10 min)
```bash
cd /mnt/d/Hackathons/hackathon-2/calm-orbit-todo/phase5-cloud

# Tag and push backend
docker tag todo-backend:v1.3.2 registry.digitalocean.com/hackathon-todo-registry/todo-backend:v1.3.2
docker push registry.digitalocean.com/hackathon-todo-registry/todo-backend:v1.3.2

# Tag and push frontend
docker tag todo-frontend:latest registry.digitalocean.com/hackathon-todo-registry/todo-frontend:v1.0.0
docker push registry.digitalocean.com/hackathon-todo-registry/todo-frontend:v1.0.0
```

### Step 4: Create Secrets (5 min)
```bash
# Database secret
kubectl create secret generic database-secret \
  --from-literal=DATABASE_URL='postgresql+asyncpg://user:pass@host/db?sslmode=require' \
  -n todo-app

# Kafka secret
kubectl create secret generic kafka-secret \
  --from-literal=KAFKA_BOOTSTRAP_SERVERS='seed-xxx.cloud.redpanda.com:9092' \
  --from-literal=KAFKA_SECURITY_PROTOCOL='SASL_SSL' \
  --from-literal=KAFKA_SASL_MECHANISM='SCRAM-SHA-256' \
  --from-literal=KAFKA_SASL_USERNAME='rp_xxx' \
  --from-literal=KAFKA_SASL_PASSWORD='xxx' \
  -n todo-app

# Auth secret
kubectl create secret generic auth-secret \
  --from-literal=BETTER_AUTH_SECRET='your-secret-key-here' \
  -n todo-app
```

### Step 5: Deploy (15 min)
```bash
cd k8s/cloud

# Deploy backend
kubectl apply -f backend-deployment.yaml

# Wait for LoadBalancer IP
kubectl get service backend-service -n todo-app -w

# Get backend IP
export BACKEND_IP=$(kubectl get service backend-service -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Update frontend manifest with backend IP
sed -i "s|http://BACKEND_LOADBALANCER_IP|http://$BACKEND_IP|g" frontend-deployment.yaml

# Deploy frontend
kubectl apply -f frontend-deployment.yaml

# Get frontend IP
export FRONTEND_IP=$(kubectl get service frontend-service -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Update frontend with its own IP
sed -i "s|http://FRONTEND_LOADBALANCER_IP|http://$FRONTEND_IP|g" frontend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl rollout restart deployment/frontend-deployment -n todo-app
```

### Step 6: Verify (10 min)
```bash
# Check pods
kubectl get pods -n todo-app

# Test backend
curl http://$BACKEND_IP/health

# Open frontend
echo "Frontend: http://$FRONTEND_IP"
```

**Total Time**: ~65 minutes (express path)

---

## 🎓 Step-by-Step Path (For Beginners)

If you're new to Kubernetes or cloud deployments, follow the detailed guides in order:

### Phase 1: Setup Accounts (30-40 min)
1. **Read**: `01-digital-ocean-setup.md`
2. **Complete**: Digital Ocean account, doctl installation
3. **Verify**: `doctl account get` works
4. **Read**: `02-redpanda-cloud-setup.md`
5. **Complete**: Redpanda cluster, topics, credentials
6. **Verify**: `rpk topic list` shows 4 topics

### Phase 2: Infrastructure (30-40 min)
1. **Read**: `03-doks-cluster-deployment.md`
2. **Complete**: DOKS cluster creation
3. **Complete**: Container registry setup
4. **Complete**: Push Docker images
5. **Complete**: Create Kubernetes secrets
6. **Verify**: `kubectl get nodes` shows 2 nodes

### Phase 3: Deployment (45-60 min)
1. **Read**: `04-application-deployment.md`
2. **Complete**: Create Kubernetes manifests
3. **Complete**: Deploy backend
4. **Complete**: Deploy frontend
5. **Verify**: Both services have LoadBalancer IPs
6. **Test**: Open frontend in browser

### Phase 4: Testing (30-45 min)
1. **Read**: `05-verification-and-testing.md`
2. **Complete**: All test scenarios
3. **Verify**: All Phase 5 features working
4. **Document**: Take screenshots, gather info
5. **Prepare**: Hackathon submission materials

**Total Time**: ~2.5-3 hours (detailed path)

---

## 💰 Cost Breakdown

### One-Time Costs
- **Digital Ocean Account**: $0 (free $200 credit)
- **Redpanda Cloud**: $0 (free tier)

### Monthly Recurring Costs
| Service | Cost | Notes |
|---------|------|-------|
| DOKS Cluster (2 nodes) | $24/month | 2 × $12 Basic nodes |
| Backend LoadBalancer | $12/month | Digital Ocean LB |
| Frontend LoadBalancer | $12/month | Digital Ocean LB |
| Container Registry | $0 | First 500MB free |
| Redpanda Cloud | $0 | Free tier (10GB, 10M msgs) |
| Neon Database | $0 | Free tier |
| **Total** | **$48/month** | |

### With $200 Free Credit
- **First month**: $48 used, $152 remaining
- **Can run for**: 4+ months on free credit
- **After credit**: $48/month or delete resources

---

## ⚠️ Prerequisites Checklist

Before starting, ensure you have:

### Required
- [ ] Email address (for account signups)
- [ ] Credit/debit card (for Digital Ocean verification - won't be charged)
- [ ] Computer with terminal access (Linux, macOS, or Windows WSL2)
- [ ] Internet connection (stable, for downloads and deployments)
- [ ] Web browser (Chrome, Firefox, Safari, Edge)

### Technical Knowledge (Helpful but not required)
- [ ] Basic command line usage (cd, ls, cat)
- [ ] Basic understanding of Docker (what containers are)
- [ ] Basic understanding of Kubernetes (what pods/services are)
- [ ] Git basics (clone, commit, push)

### Already Completed (Phase 1-4)
- [ ] Backend code working locally (Phase 3)
- [ ] Frontend code working locally (Phase 3)
- [ ] Neon database configured (Phase 3)
- [ ] Docker images built (Phase 4)
- [ ] Minikube deployment tested (Phase 4)

---

## 🛠️ Tools You'll Install

### Command Line Tools
1. **doctl** - Digital Ocean CLI
   - Purpose: Manage Digital Ocean resources
   - Installation: Covered in Guide 01

2. **kubectl** - Kubernetes CLI
   - Purpose: Manage Kubernetes cluster
   - Installation: Covered in Guide 03

3. **rpk** - Redpanda CLI (optional)
   - Purpose: Manage Kafka topics
   - Installation: Covered in Guide 02

4. **docker** - Already installed (from Phase 4)
   - Purpose: Build and push images

---

## 🎯 Success Criteria

Your deployment is successful when:

### Infrastructure
- [ ] DOKS cluster running with 2 nodes
- [ ] All pods showing `Running` status
- [ ] LoadBalancers have external IPs
- [ ] Container registry has both images

### Application
- [ ] Frontend accessible from internet
- [ ] Backend API accessible from internet
- [ ] Authentication working (sign up, login, logout)
- [ ] CRUD operations working (create, read, update, delete tasks)

### Phase 5 Features
- [ ] Recurring tasks working
- [ ] Reminders working
- [ ] Priorities working (high, medium, low)
- [ ] Tags working
- [ ] Due dates working

### Event-Driven Architecture
- [ ] Kafka events being published
- [ ] Event consumers processing events
- [ ] Schedulers running (recurring, reminder)
- [ ] Audit logs being created

### Performance & Stability
- [ ] Response times < 1 second
- [ ] No frequent pod restarts
- [ ] Resource usage within limits
- [ ] No critical errors in logs

---

## 🚨 Common Issues & Quick Fixes

### Issue: "doctl: command not found"
**Fix**:
```bash
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### Issue: "kubectl: Unable to connect to cluster"
**Fix**:
```bash
doctl kubernetes cluster kubeconfig save hackathon-todo-cluster
kubectl config current-context
```

### Issue: "Pods in CrashLoopBackOff"
**Fix**:
```bash
kubectl logs POD_NAME -n todo-app
# Check logs for error, usually database or Kafka connection issue
# Verify secrets are correct
kubectl get secrets -n todo-app
```

### Issue: "LoadBalancer stuck in Pending"
**Fix**:
```bash
# Wait 5-10 minutes (Digital Ocean provisioning time)
kubectl get service backend-service -n todo-app -w
```

### Issue: "ImagePullBackOff"
**Fix**:
```bash
# Verify image exists
doctl registry repository list-tags todo-backend
# Re-integrate registry
doctl registry kubernetes-manifest | kubectl apply -f -
```

### Issue: "Frontend can't connect to backend"
**Fix**:
```bash
# Verify backend IP in frontend config
kubectl describe deployment frontend-deployment -n todo-app | grep NEXT_PUBLIC_API_URL
# Update if wrong
kubectl edit deployment frontend-deployment -n todo-app
```

**For detailed troubleshooting**, see individual guide troubleshooting sections.

---

## 📊 Deployment Timeline

### Realistic Timeline (First Time)
```
Hour 1: Account Setup
├─ 0:00-0:20  Digital Ocean account + doctl
├─ 0:20-0:40  Redpanda Cloud account + cluster
└─ 0:40-1:00  Create topics, service account, ACLs

Hour 2: Infrastructure
├─ 1:00-1:30  Create DOKS cluster
├─ 1:30-1:45  Set up container registry
└─ 1:45-2:00  Push Docker images, create secrets

Hour 3: Deployment
├─ 2:00-2:30  Deploy backend, wait for LoadBalancer
├─ 2:30-3:00  Deploy frontend, configure URLs
└─ 3:00-3:15  Final configuration, restart pods

Hour 4: Testing
├─ 3:15-3:45  Test all features
├─ 3:45-4:00  Performance testing
└─ 4:00-4:15  Prepare submission materials

Total: ~4 hours (with breaks and troubleshooting)
```

### Optimistic Timeline (Experienced)
```
Total: ~1.5 hours (if everything goes smoothly)
```

---

## 📝 Deployment Checklist

Print this checklist and check off items as you complete them:

### Pre-Deployment
- [ ] Read this master guide completely
- [ ] Verify all prerequisites met
- [ ] Backup local Minikube data (optional)
- [ ] Have all credentials ready (Neon database URL)

### Guide 01: Digital Ocean
- [ ] Account created
- [ ] $200 credit activated
- [ ] doctl installed
- [ ] doctl authenticated
- [ ] `doctl account get` works

### Guide 02: Redpanda Cloud
- [ ] Account created
- [ ] Cluster created (Serverless)
- [ ] 4 topics created
- [ ] Service account created
- [ ] API key generated and saved
- [ ] 5 ACLs configured
- [ ] `rpk topic list` works (optional)

### Guide 03: DOKS Cluster
- [ ] Cluster created (2 nodes)
- [ ] kubectl installed
- [ ] kubectl configured
- [ ] Namespace created (todo-app)
- [ ] Container registry created
- [ ] Registry authenticated
- [ ] Backend image pushed
- [ ] Frontend image pushed
- [ ] Database secret created
- [ ] Kafka secret created
- [ ] Auth secret created

### Guide 04: Application Deployment
- [ ] Backend manifest created
- [ ] Backend deployed
- [ ] Backend LoadBalancer IP obtained
- [ ] Backend health check passes
- [ ] Frontend manifest created
- [ ] Frontend deployed
- [ ] Frontend LoadBalancer IP obtained
- [ ] Frontend accessible in browser

### Guide 05: Verification
- [ ] All pods running
- [ ] Authentication tested
- [ ] CRUD operations tested
- [ ] Recurring tasks tested
- [ ] Reminders tested
- [ ] Priorities tested
- [ ] Tags tested
- [ ] Due dates tested
- [ ] Kafka events verified
- [ ] Performance acceptable
- [ ] Screenshots taken
- [ ] Deployment info documented

---

## 🎓 Learning Resources

### Kubernetes Basics
- Official Docs: https://kubernetes.io/docs/tutorials/
- Interactive Tutorial: https://kubernetes.io/docs/tutorials/kubernetes-basics/

### Digital Ocean Kubernetes
- DOKS Docs: https://docs.digitalocean.com/products/kubernetes/
- Tutorials: https://www.digitalocean.com/community/tags/kubernetes

### Kafka/Redpanda
- Redpanda Docs: https://docs.redpanda.com/
- Kafka Concepts: https://kafka.apache.org/documentation/

### Docker
- Docker Docs: https://docs.docker.com/get-started/
- Best Practices: https://docs.docker.com/develop/dev-best-practices/

---

## 🆘 Getting Help

### During Deployment

1. **Check Logs First**:
   ```bash
   kubectl logs deployment/backend-deployment -n todo-app
   kubectl logs deployment/frontend-deployment -n todo-app
   ```

2. **Check Pod Status**:
   ```bash
   kubectl describe pod POD_NAME -n todo-app
   ```

3. **Check Events**:
   ```bash
   kubectl get events -n todo-app --sort-by='.lastTimestamp'
   ```

4. **Consult Troubleshooting Sections**:
   - Each guide has a detailed troubleshooting section
   - Check the specific guide for your issue

### External Resources

- **Digital Ocean Support**: https://www.digitalocean.com/support
- **Redpanda Community**: https://redpanda.com/slack
- **Kubernetes Slack**: https://kubernetes.slack.com/
- **Stack Overflow**: Tag questions with `kubernetes`, `digital-ocean`, `redpanda`

---

## 🎉 After Successful Deployment

### Immediate Next Steps
1. **Test thoroughly** - Use Guide 05
2. **Take screenshots** - For hackathon submission
3. **Document URLs** - Save LoadBalancer IPs
4. **Create demo account** - For judges to test

### Hackathon Submission
1. **Update README** - Include deployment URLs
2. **Add architecture diagram** - Show cloud infrastructure
3. **List features** - Highlight Phase 5 features
4. **Include credentials** - Demo account for judges
5. **Add screenshots** - Show working application

### Monitoring & Maintenance
1. **Check costs daily**:
   ```bash
   doctl balance get
   ```

2. **Monitor pod health**:
   ```bash
   kubectl get pods -n todo-app
   ```

3. **Check logs for errors**:
   ```bash
   kubectl logs -f deployment/backend-deployment -n todo-app
   ```

### After Hackathon

**If keeping the deployment**:
- Set up billing alerts
- Optimize costs (reduce replicas, use NodePort)
- Set up monitoring (Prometheus, Grafana)
- Configure SSL/TLS
- Set up custom domain

**If shutting down**:
```bash
# Delete cluster (stops all charges)
doctl kubernetes cluster delete hackathon-todo-cluster

# Delete registry
doctl registry delete hackathon-todo-registry

# Delete Redpanda cluster (via web console)
# Keep Neon database (free tier)
```

---

## 📞 Support & Feedback

### Project Repository
- GitHub: [Your GitHub URL]
- Branch: `008-cloud-event-driven-phase5`
- Issues: [GitHub Issues URL]

### Documentation
- All guides: `calm-orbit-todo/phase5-cloud/docs/`
- Architecture: `calm-orbit-todo/phase5-cloud/docs/architecture.md`
- API Docs: `http://YOUR_BACKEND_IP/docs`

---

## ✅ Final Checklist

Before considering deployment complete:

- [ ] All 5 guides completed
- [ ] Application accessible from internet
- [ ] All Phase 5 features tested and working
- [ ] Event-driven architecture verified
- [ ] Performance acceptable
- [ ] Screenshots and documentation ready
- [ ] Demo credentials created
- [ ] Hackathon submission prepared

---

## 🚀 Ready to Deploy?

Choose your path:

### 🎓 **Beginner Path** (Recommended)
Start with **Guide 01: Digital Ocean Account Setup**
- Detailed explanations
- Step-by-step instructions
- Troubleshooting for each step
- Estimated time: 2.5-3 hours

### ⚡ **Express Path** (Experienced Users)
Follow the **Quick Start** section above
- Assumes Kubernetes knowledge
- Minimal explanations
- Fast deployment
- Estimated time: 1-1.5 hours

---

**Good luck with your deployment! 🎉**

**Remember**: Take your time, read carefully, and don't skip verification steps. A successful deployment is better than a fast one!

---

**Last Updated**: 2024-01-15
**Version**: 1.0.0
**Status**: Ready for deployment
