# Troubleshooting Kubernetes Deployments

This guide covers common deployment issues and their solutions.

## Table of Contents

1. [Pod Issues](#pod-issues)
2. [Deployment Issues](#deployment-issues)
3. [Service Issues](#service-issues)
4. [Resource Issues](#resource-issues)
5. [Configuration Issues](#configuration-issues)

---

## Pod Issues

### Issue 1: CrashLoopBackOff

**Symptoms:**
- Pod status shows `CrashLoopBackOff`
- Pod keeps restarting
- Application not accessible

**Diagnosis:**

```bash
# Check pod status
kubectl get pods -n <namespace>

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Check previous logs (if pod restarted)
kubectl logs <pod-name> -n <namespace> --previous
```

**Common Causes and Solutions:**

#### Cause 1: Application Error

**Solution:** Fix application code

```bash
# Check logs for error messages
kubectl logs <pod-name> -n <namespace> --tail=100

# Common errors:
# - Missing environment variables
# - Database connection failures
# - Port already in use
# - File not found
```

#### Cause 2: Missing Dependencies

**Solution:** Update Dockerfile or init containers

```yaml
# Add init container to wait for dependencies
initContainers:
- name: wait-for-db
  image: busybox:1.36
  command: ['sh', '-c', 'until nc -z database-service 5432; do echo waiting for db; sleep 2; done']
```

#### Cause 3: Incorrect Command/Args

**Solution:** Fix command in deployment

```yaml
# Wrong
containers:
- name: app
  image: myapp:v1
  command: ["npm"]
  args: ["start"]  # Should be "npm start" or ["npm", "start"]

# Correct
containers:
- name: app
  image: myapp:v1
  command: ["npm", "start"]
```

#### Cause 4: Health Probe Failures

**Solution:** Adjust probe settings or fix health endpoint

```yaml
# Increase initial delay and timeout
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 30  # Increase if app takes time to start
  periodSeconds: 15
  timeoutSeconds: 5
  failureThreshold: 3
```

---

### Issue 2: ImagePullBackOff

**Symptoms:**
- Pod status shows `ImagePullBackOff` or `ErrImagePull`
- Pod cannot start
- Image pull errors in events

**Diagnosis:**

```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Look for:
# - "Failed to pull image"
# - "unauthorized: authentication required"
# - "manifest unknown"
```

**Common Causes and Solutions:**

#### Cause 1: Image Does Not Exist

**Solution:** Verify image name and tag

```bash
# Check image name in deployment
kubectl get deployment <deployment-name> -n <namespace> -o jsonpath='{.spec.template.spec.containers[0].image}'

# Common mistakes:
# - Typo in image name
# - Wrong tag (e.g., v1.0.0 vs 1.0.0)
# - Image not pushed to registry
```

#### Cause 2: Private Registry Authentication

**Solution:** Create and use imagePullSecrets

```bash
# Create docker registry secret
kubectl create secret docker-registry regcred \
  --docker-server=<registry-server> \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  -n <namespace>

# Use in deployment
spec:
  imagePullSecrets:
  - name: regcred
  containers:
  - name: app
    image: <private-registry>/myapp:v1
```

#### Cause 3: Rate Limiting (Docker Hub)

**Solution:** Use authenticated pulls or mirror

```bash
# Docker Hub rate limits unauthenticated pulls
# Solution 1: Authenticate
kubectl create secret docker-registry dockerhub \
  --docker-server=docker.io \
  --docker-username=<username> \
  --docker-password=<password> \
  -n <namespace>

# Solution 2: Use a mirror or private registry
```

#### Cause 4: Network Issues

**Solution:** Check network connectivity

```bash
# Test from a pod
kubectl run test-pod --image=busybox:1.36 --rm -it --restart=Never -- \
  wget -O- https://registry-1.docker.io/v2/

# Check DNS
kubectl run test-pod --image=busybox:1.36 --rm -it --restart=Never -- \
  nslookup registry-1.docker.io
```

---

### Issue 3: Pending Pods

**Symptoms:**
- Pod status shows `Pending`
- Pod not scheduled to any node
- Application not starting

**Diagnosis:**

```bash
# Check pod status
kubectl get pods -n <namespace>

# Describe pod for scheduling events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl top nodes
kubectl describe nodes
```

**Common Causes and Solutions:**

#### Cause 1: Insufficient Resources

**Solution:** Add nodes or reduce resource requests

```bash
# Check node capacity
kubectl describe nodes | grep -A 5 "Allocated resources"

# Reduce resource requests
resources:
  requests:
    cpu: "50m"      # Reduced from 100m
    memory: "64Mi"  # Reduced from 128Mi
```

#### Cause 2: Node Selector Mismatch

**Solution:** Fix node selector or add labels to nodes

```yaml
# Check node selector in deployment
spec:
  template:
    spec:
      nodeSelector:
        disktype: ssd  # No nodes have this label

# Solution 1: Remove node selector
# Solution 2: Add label to node
# kubectl label nodes <node-name> disktype=ssd
```

#### Cause 3: Taints and Tolerations

**Solution:** Add tolerations or remove taints

```bash
# Check node taints
kubectl describe nodes | grep Taints

# Add toleration to deployment
spec:
  template:
    spec:
      tolerations:
      - key: "key1"
        operator: "Equal"
        value: "value1"
        effect: "NoSchedule"
```

#### Cause 4: PersistentVolumeClaim Not Bound

**Solution:** Fix PVC or create PV

```bash
# Check PVC status
kubectl get pvc -n <namespace>

# Describe PVC
kubectl describe pvc <pvc-name> -n <namespace>

# Check if storage class exists
kubectl get storageclass
```

---

### Issue 4: Pod Evicted

**Symptoms:**
- Pod status shows `Evicted`
- Pod was running but got terminated
- New pod created to replace evicted one

**Diagnosis:**

```bash
# Check evicted pods
kubectl get pods -n <namespace> | grep Evicted

# Describe evicted pod
kubectl describe pod <pod-name> -n <namespace>

# Check node pressure
kubectl describe nodes | grep -A 5 "Conditions"
```

**Common Causes and Solutions:**

#### Cause 1: Out of Memory (OOM)

**Solution:** Increase memory limits

```yaml
# Increase memory limit
resources:
  requests:
    memory: "256Mi"
  limits:
    memory: "512Mi"  # Increased from 256Mi
```

#### Cause 2: Disk Pressure

**Solution:** Clean up disk or increase storage

```bash
# Check disk usage on nodes
kubectl get nodes -o custom-columns=NAME:.metadata.name,DISK:.status.conditions[?(@.type=="DiskPressure")].status

# Clean up unused images
# SSH to node and run:
# docker system prune -a
```

#### Cause 3: Node Pressure

**Solution:** Add more nodes or reduce resource usage

```bash
# Check node conditions
kubectl describe nodes | grep -A 10 "Conditions"

# Look for:
# - MemoryPressure
# - DiskPressure
# - PIDPressure
```

---

## Deployment Issues

### Issue 1: Deployment Not Rolling Out

**Symptoms:**
- Deployment stuck in progress
- New pods not created
- Old pods still running

**Diagnosis:**

```bash
# Check deployment status
kubectl get deployment <deployment-name> -n <namespace>

# Check rollout status
kubectl rollout status deployment/<deployment-name> -n <namespace>

# Describe deployment
kubectl describe deployment <deployment-name> -n <namespace>

# Check replica sets
kubectl get rs -n <namespace>
```

**Common Causes and Solutions:**

#### Cause 1: Image Pull Failure

**Solution:** Fix image or credentials (see ImagePullBackOff above)

#### Cause 2: Insufficient Resources

**Solution:** Scale down or add resources (see Pending Pods above)

#### Cause 3: PodDisruptionBudget Too Restrictive

**Solution:** Adjust PDB

```yaml
# Too restrictive (3 replicas, minAvailable: 3)
spec:
  minAvailable: 3  # Cannot terminate any pod

# Better (3 replicas, minAvailable: 2)
spec:
  minAvailable: 2  # Can terminate 1 pod at a time
```

#### Cause 4: Failed Health Probes

**Solution:** Fix health probes or application

```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Look for:
# - "Liveness probe failed"
# - "Readiness probe failed"

# Test health endpoint manually
kubectl exec <pod-name> -n <namespace> -- curl http://localhost:8000/health
```

---

### Issue 2: Deployment Rollback Needed

**Symptoms:**
- New version has bugs
- Need to revert to previous version
- Application not working after update

**Solution:**

```bash
# Check rollout history
kubectl rollout history deployment/<deployment-name> -n <namespace>

# Rollback to previous version
kubectl rollout undo deployment/<deployment-name> -n <namespace>

# Rollback to specific revision
kubectl rollout undo deployment/<deployment-name> -n <namespace> --to-revision=2

# Check rollback status
kubectl rollout status deployment/<deployment-name> -n <namespace>
```

---

### Issue 3: Deployment Scaling Issues

**Symptoms:**
- Replicas not matching desired count
- Pods not scaling up/down
- HPA not working

**Diagnosis:**

```bash
# Check deployment replicas
kubectl get deployment <deployment-name> -n <namespace>

# Check HPA (if using autoscaling)
kubectl get hpa -n <namespace>

# Describe HPA
kubectl describe hpa <hpa-name> -n <namespace>

# Check metrics
kubectl top pods -n <namespace>
```

**Solutions:**

```bash
# Manual scaling
kubectl scale deployment/<deployment-name> --replicas=5 -n <namespace>

# Check HPA metrics
kubectl get hpa <hpa-name> -n <namespace> --watch

# If HPA not working, check Metrics Server
kubectl get deployment metrics-server -n kube-system
```

---

## Service Issues

### Issue 1: Service Not Accessible

**Symptoms:**
- Cannot connect to service
- Connection timeout
- Service endpoints empty

**Diagnosis:**

```bash
# Check service
kubectl get service <service-name> -n <namespace>

# Describe service
kubectl describe service <service-name> -n <namespace>

# Check endpoints
kubectl get endpoints <service-name> -n <namespace>

# Test from within cluster
kubectl run test-pod --image=busybox:1.36 --rm -it --restart=Never -- \
  wget -O- http://<service-name>.<namespace>.svc.cluster.local
```

**Common Causes and Solutions:**

#### Cause 1: Selector Mismatch

**Solution:** Fix service selector

```yaml
# Service selector must match pod labels
# Service
spec:
  selector:
    app: backend  # Must match pod labels

# Deployment
spec:
  template:
    metadata:
      labels:
        app: backend  # Must match service selector
```

#### Cause 2: Wrong Port

**Solution:** Fix port mapping

```yaml
# Service
spec:
  ports:
  - port: 8000        # Service port
    targetPort: 8000  # Must match container port

# Deployment
spec:
  template:
    spec:
      containers:
      - name: app
        ports:
        - containerPort: 8000  # Must match targetPort
```

#### Cause 3: No Ready Pods

**Solution:** Fix pod issues (see Pod Issues above)

```bash
# Check if pods are ready
kubectl get pods -n <namespace> -l app=<app-name>

# All pods must be Running and Ready
```

---

### Issue 2: LoadBalancer Pending

**Symptoms:**
- LoadBalancer service shows `<pending>` for EXTERNAL-IP
- Cannot access service externally

**Diagnosis:**

```bash
# Check service
kubectl get service <service-name> -n <namespace>

# Describe service
kubectl describe service <service-name> -n <namespace>
```

**Common Causes and Solutions:**

#### Cause 1: Cloud Provider Not Configured

**Solution:** Ensure cluster has cloud provider integration

```bash
# LoadBalancer only works on cloud providers (GKE, EKS, AKS)
# For local clusters (Minikube, Kind), use NodePort or Ingress

# Minikube: Use tunnel
minikube tunnel

# Or use NodePort instead
spec:
  type: NodePort
```

#### Cause 2: Quota Exceeded

**Solution:** Check cloud provider quotas

```bash
# Check cloud provider console for:
# - Load balancer quota
# - IP address quota
# - Network quota
```

---

## Resource Issues

### Issue 1: Out of Memory (OOM) Kills

**Symptoms:**
- Pods restarting frequently
- Exit code 137 (OOMKilled)
- Memory limit exceeded

**Diagnosis:**

```bash
# Check pod status
kubectl get pods -n <namespace>

# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# Look for: "Reason: OOMKilled"

# Check memory usage
kubectl top pod <pod-name> -n <namespace>
```

**Solution:**

```yaml
# Increase memory limits
resources:
  requests:
    memory: "256Mi"
  limits:
    memory: "1Gi"  # Increased from 512Mi

# Or optimize application memory usage
```

---

### Issue 2: CPU Throttling

**Symptoms:**
- Application slow
- High CPU usage
- Requests timing out

**Diagnosis:**

```bash
# Check CPU usage
kubectl top pods -n <namespace>

# Check CPU limits
kubectl get deployment <deployment-name> -n <namespace> -o jsonpath='{.spec.template.spec.containers[0].resources}'
```

**Solution:**

```yaml
# Increase CPU limits or remove them
resources:
  requests:
    cpu: "100m"
  limits:
    cpu: "2000m"  # Increased from 500m
    # Or remove limits to allow bursting
```

---

## Configuration Issues

### Issue 1: ConfigMap/Secret Not Found

**Symptoms:**
- Pod fails to start
- Error: "configmap not found" or "secret not found"

**Diagnosis:**

```bash
# Check if ConfigMap exists
kubectl get configmap <configmap-name> -n <namespace>

# Check if Secret exists
kubectl get secret <secret-name> -n <namespace>

# Describe pod
kubectl describe pod <pod-name> -n <namespace>
```

**Solution:**

```bash
# Create missing ConfigMap
kubectl create configmap <configmap-name> \
  --from-literal=KEY=VALUE \
  -n <namespace>

# Create missing Secret
kubectl create secret generic <secret-name> \
  --from-literal=KEY=VALUE \
  -n <namespace>
```

---

### Issue 2: Environment Variables Not Set

**Symptoms:**
- Application errors about missing config
- Environment variables empty

**Diagnosis:**

```bash
# Check environment variables in pod
kubectl exec <pod-name> -n <namespace> -- env

# Check deployment configuration
kubectl get deployment <deployment-name> -n <namespace> -o yaml
```

**Solution:**

```yaml
# Ensure envFrom or env is correctly configured
spec:
  containers:
  - name: app
    envFrom:
    - configMapRef:
        name: app-config  # Must exist
    - secretRef:
        name: app-secrets  # Must exist
```

---

## General Debugging Commands

```bash
# Get all resources in namespace
kubectl get all -n <namespace>

# Describe resource
kubectl describe <resource-type> <resource-name> -n <namespace>

# Get logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
kubectl logs <pod-name> -n <namespace> -f  # Follow

# Execute command in pod
kubectl exec <pod-name> -n <namespace> -- <command>
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Port forward
kubectl port-forward <pod-name> 8080:8000 -n <namespace>

# Get events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Check resource usage
kubectl top nodes
kubectl top pods -n <namespace>

# Get YAML
kubectl get <resource-type> <resource-name> -n <namespace> -o yaml
```

---

## Best Practices for Troubleshooting

1. **Start with events**: `kubectl describe` shows recent events
2. **Check logs**: Application logs often reveal the issue
3. **Verify configuration**: Ensure ConfigMaps, Secrets, and env vars are correct
4. **Check resources**: Ensure sufficient CPU and memory
5. **Test connectivity**: Use test pods to verify network access
6. **Monitor metrics**: Use `kubectl top` to check resource usage
7. **Review recent changes**: What changed before the issue started?
8. **Check dependencies**: Are databases, caches, and external services accessible?
9. **Validate YAML**: Use `kubectl apply --dry-run=client` to validate
10. **Use labels**: Filter resources with `-l app=myapp`
