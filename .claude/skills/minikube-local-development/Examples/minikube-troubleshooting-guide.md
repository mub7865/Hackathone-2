# Minikube Troubleshooting Guide

Common issues and their solutions when working with Minikube.

## Issue 1: Minikube Won't Start

### Symptoms
```
minikube start
X Exiting due to...
```

### Solutions

#### Check Docker is Running
```bash
# Verify Docker is running
docker info

# If not running, start Docker Desktop
# Windows: Start Docker Desktop from Start Menu
# macOS: Start Docker from Applications
# Linux: sudo systemctl start docker
```

#### Try Different Driver
```bash
# Use Docker driver (most reliable)
minikube start --driver=docker

# Or try Hyper-V (Windows)
minikube start --driver=hyperv

# Or try VirtualBox
minikube start --driver=virtualbox
```

#### Delete and Recreate
```bash
# Clean slate
minikube delete --all --purge
minikube start --driver=docker
```

#### Check Resources
```bash
# Ensure enough resources
minikube start --cpus=2 --memory=2048

# Check system resources
# Windows: Task Manager
# macOS/Linux: htop or top
```

---

## Issue 2: ImagePullBackOff / ErrImagePull

### Symptoms
```bash
kubectl get pods
# NAME            READY   STATUS             RESTARTS   AGE
# my-app-xxx      0/1     ImagePullBackOff   0          1m
```

### Cause
Kubernetes is trying to pull image from remote registry, but image only exists locally.

### Solutions

#### Solution A: Build in Minikube's Docker
```bash
# Point to Minikube's Docker
eval $(minikube docker-env)  # Linux/macOS
& minikube docker-env | Invoke-Expression  # Windows PowerShell

# Build image
docker build -t my-app:v1 .

# Verify image exists in Minikube
docker images | grep my-app
```

#### Solution B: Load Existing Image
```bash
# If image exists locally, load it
minikube image load my-app:v1

# Verify
minikube image ls | grep my-app
```

#### Solution C: Set imagePullPolicy
```yaml
# In your deployment.yaml
spec:
  containers:
  - name: my-app
    image: my-app:v1
    imagePullPolicy: Never  # Don't try to pull from registry
```

#### Solution D: Redeploy After Fix
```bash
# Delete and recreate pod
kubectl delete pod <pod-name>

# Or restart deployment
kubectl rollout restart deployment/<deployment-name>
```

---

## Issue 3: Service Not Accessible

### Symptoms
- Browser shows "Connection refused"
- `curl` times out
- Can't reach NodePort

### Solutions

#### Check Service Exists
```bash
kubectl get svc
kubectl describe svc <service-name>
```

#### Use minikube service
```bash
# This handles networking automatically
minikube service <service-name>

# Get URL
minikube service <service-name> --url
```

#### Check Pod is Ready
```bash
kubectl get pods
# Ensure STATUS is "Running" and READY is "1/1"

# If not ready, check logs
kubectl logs <pod-name>
kubectl describe pod <pod-name>
```

#### Use Port Forward
```bash
# Bypass service, connect directly to pod
kubectl port-forward pod/<pod-name> 8080:8080

# Or to service
kubectl port-forward svc/<service-name> 8080:8080
```

#### Start Tunnel for LoadBalancer
```bash
# Required for LoadBalancer type services
minikube tunnel

# Keep this running in separate terminal
```

---

## Issue 4: kubectl Connection Refused

### Symptoms
```
The connection to the server localhost:8080 was refused
```

### Solutions

#### Check Minikube Status
```bash
minikube status

# If stopped, start it
minikube start
```

#### Update kubeconfig
```bash
# Regenerate kubeconfig
minikube update-context

# Or manually set context
kubectl config use-context minikube

# Verify
kubectl config current-context
```

#### Check kubectl Config
```bash
# View config
kubectl config view

# Ensure server URL is correct
```

---

## Issue 5: Pods Stuck in Pending

### Symptoms
```bash
kubectl get pods
# NAME         READY   STATUS    RESTARTS   AGE
# my-app-xxx   0/1     Pending   0          5m
```

### Solutions

#### Check Events
```bash
kubectl describe pod <pod-name>
# Look at Events section at bottom
```

#### Insufficient Resources
```bash
# Stop and restart with more resources
minikube stop
minikube start --cpus=4 --memory=8192

# Or reduce resource requests in deployment
```

#### No Available Nodes
```bash
# Check nodes
kubectl get nodes

# Ensure node is Ready
kubectl describe node minikube
```

---

## Issue 6: Pods CrashLoopBackOff

### Symptoms
```bash
kubectl get pods
# NAME         READY   STATUS             RESTARTS   AGE
# my-app-xxx   0/1     CrashLoopBackOff   5          3m
```

### Solutions

#### Check Logs
```bash
# Current logs
kubectl logs <pod-name>

# Previous crash logs
kubectl logs <pod-name> --previous
```

#### Common Causes

1. **Application Error**: Fix code bug
2. **Missing Environment Variables**:
   ```bash
   kubectl describe pod <pod-name>
   # Check env vars are set correctly
   ```
3. **Wrong Command/Entrypoint**: Check Dockerfile CMD
4. **Missing Dependencies**: Check all secrets/configmaps exist
5. **Health Check Failing**: Adjust probe settings

#### Debug Interactively
```bash
# Override entrypoint to debug
kubectl run debug --image=my-app:v1 --rm -it -- /bin/sh
```

---

## Issue 7: DNS Resolution Not Working

### Symptoms
- Pods can't reach other services by name
- `nslookup` fails inside pod

### Solutions

#### Check CoreDNS
```bash
kubectl get pods -n kube-system | grep coredns

# If not running, check logs
kubectl logs -l k8s-app=kube-dns -n kube-system
```

#### Restart CoreDNS
```bash
kubectl rollout restart deployment/coredns -n kube-system
```

#### Test DNS Inside Pod
```bash
# Shell into a pod
kubectl exec -it <pod-name> -- /bin/sh

# Test DNS
nslookup kubernetes.default
nslookup <service-name>.<namespace>.svc.cluster.local
```

---

## Issue 8: Persistent Volume Issues

### Symptoms
- PVC stuck in Pending
- Data not persisting

### Solutions

#### Check Storage Provisioner
```bash
kubectl get sc
kubectl get pv
kubectl get pvc
```

#### Enable Storage Addon
```bash
minikube addons enable storage-provisioner
minikube addons enable default-storageclass
```

---

## Issue 9: Slow Performance

### Solutions

#### Allocate More Resources
```bash
minikube stop
minikube start --cpus=4 --memory=8192 --disk-size=50g
```

#### Use Docker Driver
```bash
# Docker driver is fastest
minikube start --driver=docker
```

#### Limit Running Pods
```bash
# Delete unused deployments
kubectl delete deployment <unused-deployment>
```

---

## Issue 10: Minikube Commands Not Working After Restart

### Symptoms
- Commands hang or fail after computer restart

### Solutions

```bash
# Stop and restart
minikube stop
minikube start

# If still failing, delete and recreate
minikube delete
minikube start --driver=docker
```

---

## Diagnostic Commands Reference

```bash
# ===== Cluster Health =====
minikube status
kubectl cluster-info
kubectl get nodes
kubectl get componentstatuses

# ===== Pod Debugging =====
kubectl get pods -A                      # All namespaces
kubectl describe pod <pod-name>          # Detailed info
kubectl logs <pod-name>                  # Current logs
kubectl logs <pod-name> --previous       # Previous crash logs
kubectl logs <pod-name> -f               # Follow logs
kubectl exec -it <pod-name> -- /bin/sh   # Shell access

# ===== Service Debugging =====
kubectl get svc
kubectl describe svc <service-name>
kubectl get endpoints

# ===== Resource Usage =====
minikube ssh -- df -h                    # Disk usage
minikube ssh -- free -m                  # Memory usage
kubectl top nodes                        # Node resources (requires metrics-server)
kubectl top pods                         # Pod resources

# ===== Network Debugging =====
kubectl run debug --image=busybox --rm -it -- /bin/sh
# Inside pod:
wget -qO- http://<service-name>:<port>
nslookup <service-name>

# ===== Minikube Debugging =====
minikube logs                            # Minikube logs
minikube ssh                             # SSH into node
minikube ip                              # Get cluster IP
```

---

## Quick Fixes Summary

| Problem | Quick Fix |
|---------|-----------|
| Won't start | `minikube delete && minikube start --driver=docker` |
| ImagePullBackOff | `eval $(minikube docker-env)` then rebuild |
| Can't access service | `minikube service <name>` |
| kubectl refused | `minikube start` then `kubectl config use-context minikube` |
| Pod pending | `minikube start --cpus=4 --memory=8192` |
| CrashLoopBackOff | `kubectl logs <pod> --previous` |
| DNS not working | `kubectl rollout restart deployment/coredns -n kube-system` |
| Slow | Use Docker driver, allocate more resources |

---

## Reset Everything (Nuclear Option)

When nothing else works:

```bash
# Delete Minikube completely
minikube delete --all --purge

# Remove Minikube data (Linux/macOS)
rm -rf ~/.minikube

# Remove Minikube data (Windows PowerShell)
Remove-Item -Recurse -Force $HOME\.minikube

# Fresh start
minikube start --driver=docker --cpus=4 --memory=4096
```
