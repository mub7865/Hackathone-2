# Digital Ocean Kubernetes (DOKS) Cluster Deployment Guide

**Time Required**: 30-40 minutes
**Cost**: ~$24/month (covered by $200 free credit)

---

## What is DOKS?

Digital Ocean Kubernetes Service (DOKS) is a managed Kubernetes cluster. Think of it as:
- **Kubernetes**: Container orchestration platform (manages your Docker containers)
- **Managed**: Digital Ocean handles the complex parts (upgrades, security, scaling)
- **Your Job**: Just deploy your application

---

## Prerequisites

✅ Digital Ocean account with $200 credit (from Guide 01)
✅ `doctl` CLI installed and authenticated (from Guide 01)
✅ Redpanda Cloud cluster ready (from Guide 02)

---

## Step 1: Choose Cluster Configuration

Before creating the cluster, let's decide on the configuration.

### 1.1 Cluster Specifications

For our hackathon Todo app, we need:

| Component | Specification | Reason |
|-----------|---------------|--------|
| **Node Count** | 2 nodes | High availability + load distribution |
| **Node Size** | Basic (2 GB RAM, 1 vCPU) | Enough for our app, cost-effective |
| **Region** | NYC3 or SFO3 | Close to Redpanda cluster |
| **Kubernetes Version** | Latest stable | Best features + security |
| **Auto-scaling** | Disabled | Fixed cost, simpler for hackathon |

### 1.2 Cost Calculation

```
2 nodes × $12/month = $24/month
Load Balancer = $12/month
Total = $36/month

Your free credit: $200
Enough for: 5+ months
```

---

## Step 2: Create DOKS Cluster

### Method A: Using doctl CLI (Recommended - Faster)

#### 2.1 Check Available Options

```bash
# Check available Kubernetes versions
doctl kubernetes options versions

# Check available node sizes
doctl kubernetes options sizes

# Check available regions
doctl kubernetes options regions
```

#### 2.2 Create the Cluster

```bash
# Create cluster with 2 nodes
doctl kubernetes cluster create hackathon-todo-cluster \
  --region nyc3 \
  --version 1.28.2-do.0 \
  --node-pool "name=worker-pool;size=s-2vcpu-2gb;count=2;auto-scale=false" \
  --wait
```

**Parameters Explained**:
- `hackathon-todo-cluster`: Your cluster name
- `--region nyc3`: New York datacenter (change to `sfo3` for San Francisco)
- `--version 1.28.2-do.0`: Kubernetes version (use latest from previous command)
- `--node-pool`: Worker nodes configuration
  - `name=worker-pool`: Node pool name
  - `size=s-2vcpu-2gb`: 2 vCPU, 2GB RAM per node
  - `count=2`: 2 nodes
  - `auto-scale=false`: Fixed size (no auto-scaling)
- `--wait`: Wait for cluster to be ready before returning

**Expected Output**:
```
Notice: Cluster is provisioning, waiting for cluster to be running
.................................................
Notice: Cluster created, fetching credentials
Notice: Adding cluster credentials to kubeconfig file found in "/home/user/.kube/config"
Notice: Setting current-context to do-nyc3-hackathon-todo-cluster
ID                                      Name                        Region    Version        Auto Upgrade    Status     Node Pools
abc123-def456-ghi789-jkl012-mno345     hackathon-todo-cluster      nyc3      1.28.2-do.0    false           running    worker-pool
```

**Time**: This will take 5-7 minutes. ☕ Take a break!

### Method B: Using Digital Ocean Web Console (Alternative)

If CLI doesn't work, use the web interface:

1. **Go to Digital Ocean Dashboard**
   - https://cloud.digitalocean.com/
   - Click **"Create"** → **"Kubernetes"**

2. **Choose Kubernetes Version**
   - Select latest stable version (e.g., 1.28.2)

3. **Choose Datacenter Region**
   - Select: **NYC3** (New York) or **SFO3** (San Francisco)
   - Choose same region as Redpanda Cloud for lower latency

4. **Choose Cluster Capacity**
   - Node pool name: `worker-pool`
   - Machine type: **Basic nodes**
   - Node plan: **2 GB RAM / 1 vCPU** ($12/month per node)
   - Node count: **2**
   - Uncheck **"Enable auto-scaling"**

5. **Finalize and Create**
   - Cluster name: `hackathon-todo-cluster`
   - Tags: `hackathon`, `todo-app` (optional)
   - Click **"Create Cluster"**
   - Wait 5-7 minutes

---

## Step 3: Configure kubectl to Access Cluster

### 3.1 Install kubectl (if not already installed)

**For Windows (WSL2/Ubuntu):**
```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make executable
chmod +x kubectl

# Move to PATH
sudo mv kubectl /usr/local/bin/

# Verify
kubectl version --client
```

**For macOS:**
```bash
# Using Homebrew
brew install kubectl

# Verify
kubectl version --client
```

### 3.2 Download Cluster Credentials

If you used `doctl` to create the cluster, credentials are already configured. Verify:

```bash
# Check current context
kubectl config current-context
```

Expected output:
```
do-nyc3-hackathon-todo-cluster
```

If not configured, download credentials manually:

```bash
# List your clusters
doctl kubernetes cluster list

# Download credentials (replace with your cluster ID)
doctl kubernetes cluster kubeconfig save hackathon-todo-cluster
```

Expected output:
```
Notice: Adding cluster credentials to kubeconfig file found in "/home/user/.kube/config"
Notice: Setting current-context to do-nyc3-hackathon-todo-cluster
```

### 3.3 Verify Connection

```bash
# Check cluster info
kubectl cluster-info

# Expected output:
# Kubernetes control plane is running at https://abc123-def456-ghi789.k8s.ondigitalocean.com
# CoreDNS is running at https://abc123-def456-ghi789.k8s.ondigitalocean.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# Check nodes
kubectl get nodes

# Expected output:
# NAME                   STATUS   ROLES    AGE   VERSION
# worker-pool-abc123     Ready    <none>   5m    v1.28.2
# worker-pool-def456     Ready    <none>   5m    v1.28.2
```

If you see 2 nodes with `Ready` status, you're connected! ✅

---

## Step 4: Create Namespace for Our Application

Namespaces help organize resources in Kubernetes.

### 4.1 Create Namespace

```bash
# Create namespace
kubectl create namespace todo-app

# Verify
kubectl get namespaces
```

Expected output:
```
NAME              STATUS   AGE
default           Active   10m
kube-system       Active   10m
kube-public       Active   10m
kube-node-lease   Active   10m
todo-app          Active   5s
```

### 4.2 Set Default Namespace

To avoid typing `-n todo-app` every time:

```bash
# Set default namespace
kubectl config set-context --current --namespace=todo-app

# Verify
kubectl config view --minify | grep namespace:
```

Expected output:
```
namespace: todo-app
```

---

## Step 5: Set Up Container Registry

We need a place to store our Docker images so DOKS can pull them.

### Option A: Digital Ocean Container Registry (Recommended)

#### 5.1 Create Registry

```bash
# Create registry
doctl registry create hackathon-todo-registry

# Expected output:
# Name                          Endpoint
# hackathon-todo-registry       registry.digitalocean.com/hackathon-todo-registry
```

#### 5.2 Authenticate Docker with Registry

```bash
# Login to registry
doctl registry login

# Expected output:
# Logging Docker in to registry.digitalocean.com
```

#### 5.3 Integrate Registry with DOKS

```bash
# Connect registry to cluster
doctl registry kubernetes-manifest | kubectl apply -f -

# Expected output:
# secret/registry-hackathon-todo-registry created
```

This creates a secret in Kubernetes that allows pulling images from your registry.

### Option B: Docker Hub (Alternative)

If you prefer Docker Hub:

#### 5.1 Login to Docker Hub

```bash
# Login
docker login

# Enter your Docker Hub username and password
```

#### 5.2 Create Kubernetes Secret

```bash
# Create secret for Docker Hub
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=YOUR_DOCKERHUB_USERNAME \
  --docker-password=YOUR_DOCKERHUB_PASSWORD \
  --docker-email=YOUR_EMAIL \
  -n todo-app
```

---

## Step 6: Push Docker Images to Registry

Now we need to push our backend and frontend images to the registry.

### 6.1 Tag Images for Registry

**If using Digital Ocean Registry:**

```bash
# Navigate to project directory
cd /mnt/d/Hackathons/hackathon-2/calm-orbit-todo/phase5-cloud

# Tag backend image
docker tag todo-backend:v1.3.2 registry.digitalocean.com/hackathon-todo-registry/todo-backend:v1.3.2

# Tag frontend image
docker tag todo-frontend:latest registry.digitalocean.com/hackathon-todo-registry/todo-frontend:v1.0.0

# Verify tags
docker images | grep registry.digitalocean.com
```

**If using Docker Hub:**

```bash
# Tag backend image
docker tag todo-backend:v1.3.2 YOUR_DOCKERHUB_USERNAME/todo-backend:v1.3.2

# Tag frontend image
docker tag todo-frontend:latest YOUR_DOCKERHUB_USERNAME/todo-frontend:v1.0.0
```

### 6.2 Push Images to Registry

**For Digital Ocean Registry:**

```bash
# Push backend
docker push registry.digitalocean.com/hackathon-todo-registry/todo-backend:v1.3.2

# Push frontend
docker push registry.digitalocean.com/hackathon-todo-registry/todo-frontend:v1.0.0
```

**For Docker Hub:**

```bash
# Push backend
docker push YOUR_DOCKERHUB_USERNAME/todo-backend:v1.3.2

# Push frontend
docker push YOUR_DOCKERHUB_USERNAME/todo-frontend:v1.0.0
```

**Expected Output** (for each push):
```
The push refers to repository [registry.digitalocean.com/hackathon-todo-registry/todo-backend]
abc123: Pushed
def456: Pushed
ghi789: Pushed
v1.3.2: digest: sha256:abc123... size: 1234
```

### 6.3 Verify Images in Registry

**For Digital Ocean Registry:**

```bash
# List repositories
doctl registry repository list

# List tags for backend
doctl registry repository list-tags todo-backend

# List tags for frontend
doctl registry repository list-tags todo-frontend
```

Expected output:
```
REPOSITORY      TAG
todo-backend    v1.3.2
todo-frontend   v1.0.0
```

---

## Step 7: Create Kubernetes Secrets for Configuration

We need to store sensitive configuration (database URL, Kafka credentials) as Kubernetes Secrets.

### 7.1 Create Database Secret

```bash
# Create secret for Neon database
kubectl create secret generic database-secret \
  --from-literal=DATABASE_URL='postgresql+asyncpg://username:password@host/database?sslmode=require' \
  -n todo-app
```

**Replace** with your actual Neon database URL from Phase 3.

### 7.2 Create Kafka Secret

```bash
# Create secret for Redpanda Cloud
kubectl create secret generic kafka-secret \
  --from-literal=KAFKA_BOOTSTRAP_SERVERS='seed-abc123.xyz.cloud.redpanda.com:9092' \
  --from-literal=KAFKA_SECURITY_PROTOCOL='SASL_SSL' \
  --from-literal=KAFKA_SASL_MECHANISM='SCRAM-SHA-256' \
  --from-literal=KAFKA_SASL_USERNAME='rp_abc123...' \
  --from-literal=KAFKA_SASL_PASSWORD='abcdefgh...' \
  -n todo-app
```

**Replace** with your actual Redpanda credentials from Guide 02.

### 7.3 Create Better Auth Secret

```bash
# Create secret for Better Auth
kubectl create secret generic auth-secret \
  --from-literal=BETTER_AUTH_SECRET='your-secret-key-here' \
  -n todo-app
```

**Replace** with a strong random secret (at least 32 characters).

### 7.4 Verify Secrets

```bash
# List secrets
kubectl get secrets -n todo-app

# Expected output:
# NAME                                  TYPE                             DATA   AGE
# database-secret                       Opaque                           1      30s
# kafka-secret                          Opaque                           5      20s
# auth-secret                           Opaque                           1      10s
# registry-hackathon-todo-registry      kubernetes.io/dockerconfigjson   1      5m
```

---

## Step 8: Install Kubernetes Dashboard (Optional but Recommended)

The Kubernetes Dashboard provides a web UI to manage your cluster.

### 8.1 Deploy Dashboard

```bash
# Deploy dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Verify deployment
kubectl get pods -n kubernetes-dashboard
```

Wait until all pods show `Running` status.

### 8.2 Create Admin User

```bash
# Create service account
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

### 8.3 Get Access Token

```bash
# Get token
kubectl -n kubernetes-dashboard create token admin-user
```

**Save this token** - you'll need it to login to the dashboard.

### 8.4 Access Dashboard

```bash
# Start proxy
kubectl proxy
```

Open browser and go to:
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

- Select **"Token"** authentication
- Paste the token from Step 8.3
- Click **"Sign In"**

You should now see the Kubernetes Dashboard! 🎉

---

## Step 9: Verify Cluster is Ready

Let's run a final check to ensure everything is configured correctly.

### 9.1 Check Cluster Health

```bash
# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Check our namespace
kubectl get all -n todo-app
```

### 9.2 Check Resource Quotas

```bash
# Check cluster capacity
kubectl top nodes

# Expected output:
# NAME                   CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# worker-pool-abc123     100m         5%     500Mi           25%
# worker-pool-def456     100m         5%     500Mi           25%
```

### 9.3 Test Deployment (Quick Test)

Let's deploy a simple nginx pod to verify everything works:

```bash
# Create test deployment
kubectl create deployment nginx-test --image=nginx:latest -n todo-app

# Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=nginx-test -n todo-app --timeout=60s

# Check status
kubectl get pods -n todo-app

# Expected output:
# NAME                          READY   STATUS    RESTARTS   AGE
# nginx-test-abc123-def456      1/1     Running   0          30s
```

If pod is running, cluster is working! ✅

Clean up test:
```bash
kubectl delete deployment nginx-test -n todo-app
```

---

## Troubleshooting

### Issue 1: "Cluster creation failed"

**Solution**:
```bash
# Check account limits
doctl account get

# Check if you have enough credit
doctl balance get

# Try a different region
doctl kubernetes cluster create ... --region sfo3
```

### Issue 2: "kubectl: command not found"

**Solution**:
```bash
# Reinstall kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Issue 3: "Unable to connect to cluster"

**Solution**:
```bash
# Re-download credentials
doctl kubernetes cluster kubeconfig save hackathon-todo-cluster

# Verify context
kubectl config current-context

# Test connection
kubectl cluster-info
```

### Issue 4: "Nodes not ready"

**Solution**:
```bash
# Check node status
kubectl describe nodes

# Wait a few more minutes (nodes can take 5-10 minutes to be ready)
kubectl get nodes --watch
```

### Issue 5: "Image pull errors"

**Solution**:
```bash
# Verify registry integration
kubectl get secrets -n todo-app

# Re-integrate registry
doctl registry kubernetes-manifest | kubectl apply -f -

# Verify images exist
doctl registry repository list
```

### Issue 6: "Secret creation failed"

**Solution**:
```bash
# Delete existing secret
kubectl delete secret database-secret -n todo-app

# Recreate with correct values
kubectl create secret generic database-secret --from-literal=DATABASE_URL='...' -n todo-app
```

---

## Cost Monitoring

### Check Current Costs

```bash
# Check balance
doctl balance get

# Expected output:
# Month-to-Date Balance    Month-to-Date Usage    Account Balance    Generated At
# $0.00                    $2.50                  $197.50            2024-01-15T10:30:00Z
```

### Set Up Billing Alerts

1. Go to: https://cloud.digitalocean.com/billing
2. Click **"Settings"** → **"Billing Alerts"**
3. Create alerts:
   - Alert at $50 (25% of credit)
   - Alert at $100 (50% of credit)
   - Alert at $150 (75% of credit)

---

## Cluster Management Commands

### Useful Commands

```bash
# View cluster info
doctl kubernetes cluster get hackathon-todo-cluster

# List all clusters
doctl kubernetes cluster list

# Upgrade cluster (when new version available)
doctl kubernetes cluster upgrade hackathon-todo-cluster --version 1.29.0-do.0

# Scale node pool
doctl kubernetes cluster node-pool update hackathon-todo-cluster worker-pool --count 3

# Delete cluster (when done with hackathon)
doctl kubernetes cluster delete hackathon-todo-cluster
```

### kubectl Cheat Sheet

```bash
# Get resources
kubectl get pods -n todo-app
kubectl get services -n todo-app
kubectl get deployments -n todo-app

# Describe resource (detailed info)
kubectl describe pod POD_NAME -n todo-app

# View logs
kubectl logs POD_NAME -n todo-app
kubectl logs -f POD_NAME -n todo-app  # Follow logs

# Execute command in pod
kubectl exec -it POD_NAME -n todo-app -- /bin/bash

# Port forward (access pod locally)
kubectl port-forward POD_NAME 8000:8000 -n todo-app

# Delete resource
kubectl delete pod POD_NAME -n todo-app
```

---

## Next Steps

✅ **You've completed DOKS cluster setup!**

**What we have now**:
- ✅ DOKS cluster running (2 nodes, NYC3)
- ✅ kubectl configured and connected
- ✅ Namespace created (todo-app)
- ✅ Container registry set up
- ✅ Docker images pushed to registry
- ✅ Kubernetes secrets created (database, Kafka, auth)
- ✅ Kubernetes Dashboard installed (optional)

**Next Guide**: `04-application-deployment.md`
- Deploy backend to DOKS
- Deploy frontend to DOKS
- Configure LoadBalancers
- Set up DNS (optional)
- Test the application

---

## Quick Reference

### Cluster Information
```
Cluster Name: hackathon-todo-cluster
Region: NYC3 (New York)
Nodes: 2 × Basic (2GB RAM, 1 vCPU)
Kubernetes Version: 1.28.2
Namespace: todo-app
```

### Registry Information
```
Registry: registry.digitalocean.com/hackathon-todo-registry
Images:
- todo-backend:v1.3.2
- todo-frontend:v1.0.0
```

### Important Commands
```bash
# Check cluster
kubectl cluster-info
kubectl get nodes

# Check our namespace
kubectl get all -n todo-app

# View secrets
kubectl get secrets -n todo-app

# Check costs
doctl balance get
```

---

**Status**: ✅ Ready for application deployment
**Time Taken**: ~30-40 minutes
**Cost So Far**: ~$2-3 (cluster running for setup time)
**Remaining Credit**: ~$197
