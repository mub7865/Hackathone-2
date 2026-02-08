# Dapr Sidecar Issues and Solutions

This guide covers issues specific to Dapr sidecar containers in Kubernetes and Docker environments.

## Sidecar Not Starting

### Issue: Pod stuck in `Init` or `ContainerCreating` state

**Symptoms**:
```bash
kubectl get pods -n todo-app
# NAME                    READY   STATUS              RESTARTS   AGE
# task-service-xxx        0/2     ContainerCreating   0          2m
```

**Diagnosis**:
```bash
# Check pod events
kubectl describe pod task-service-xxx -n todo-app

# Check init container logs
kubectl logs task-service-xxx -n todo-app -c daprd-init
```

**Common Causes & Solutions**:

1. **Dapr not installed on cluster**:
   ```bash
   # Verify Dapr installation
   dapr status -k

   # Install if missing
   dapr init --kubernetes
   ```

2. **Missing Dapr annotations**:
   ```yaml
   # deployment.yaml
   metadata:
     annotations:
       dapr.io/enabled: "true"  # Required!
       dapr.io/app-id: "task-service"
       dapr.io/app-port: "8000"
   ```

3. **Image pull errors**:
   ```bash
   # Check if Dapr images are accessible
   kubectl get pods -n dapr-system

   # If using private registry, add imagePullSecrets
   ```

---

### Issue: Sidecar crashes immediately after starting

**Symptoms**:
```bash
kubectl get pods -n todo-app
# NAME                    READY   STATUS             RESTARTS   AGE
# task-service-xxx        1/2     CrashLoopBackOff   5          5m
```

**Diagnosis**:
```bash
# Check sidecar logs
kubectl logs task-service-xxx -n todo-app -c daprd

# Check previous logs if container restarted
kubectl logs task-service-xxx -n todo-app -c daprd --previous
```

**Common Causes & Solutions**:

1. **Invalid component configuration**:
   ```bash
   # Check component YAML syntax
   kubectl get components -n todo-app
   kubectl describe component pubsub -n todo-app

   # Look for validation errors
   ```

2. **Component backend not reachable**:
   ```yaml
   # Example: Redis not accessible
   # Check if Redis service exists
   kubectl get svc redis-service -n todo-app

   # Test connectivity from pod
   kubectl exec -it task-service-xxx -n todo-app -c task-service -- nc -zv redis-service 6379
   ```

3. **Resource limits too low**:
   ```yaml
   # Increase sidecar resources
   annotations:
     dapr.io/sidecar-cpu-limit: "500m"
     dapr.io/sidecar-memory-limit: "512Mi"
     dapr.io/sidecar-cpu-request: "100m"
     dapr.io/sidecar-memory-request: "128Mi"
   ```

---

## Sidecar Communication Issues

### Issue: App cannot connect to Dapr sidecar

**Symptoms**:
```python
# Error in app logs
ConnectionRefusedError: [Errno 111] Connection refused
```

**Diagnosis**:
```bash
# Check if sidecar is listening
kubectl exec -it task-service-xxx -n todo-app -c task-service -- netstat -tulpn | grep 3500

# Test sidecar health
kubectl exec -it task-service-xxx -n todo-app -c task-service -- curl http://localhost:3500/v1.0/healthz
```

**Solutions**:

1. **Wrong Dapr port**:
   ```python
   # Use correct port (default 3500)
   from dapr.clients import DaprClient

   # Correct
   client = DaprClient(address='localhost:3500')

   # Or use environment variable
   import os
   dapr_port = os.getenv('DAPR_HTTP_PORT', '3500')
   client = DaprClient(address=f'localhost:{dapr_port}')
   ```

2. **Sidecar not ready yet**:
   ```yaml
   # Add startup probe to app container
   spec:
     containers:
     - name: task-service
       startupProbe:
         httpGet:
           path: /health
           port: 8000
         initialDelaySeconds: 10
         periodSeconds: 5
         failureThreshold: 30
   ```

3. **Network policy blocking**:
   ```bash
   # Check network policies
   kubectl get networkpolicies -n todo-app

   # Allow sidecar communication
   kubectl apply -f - <<EOF
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: allow-dapr-sidecar
     namespace: todo-app
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     - Egress
     ingress:
     - from:
       - podSelector: {}
     egress:
     - to:
       - podSelector: {}
   EOF
   ```

---

### Issue: Sidecar cannot connect to app

**Symptoms**:
```bash
# Sidecar logs show:
error invoking app channel: connection refused
```

**Diagnosis**:
```bash
# Check if app is listening on correct port
kubectl exec -it task-service-xxx -n todo-app -c daprd -- curl http://localhost:8000/health
```

**Solutions**:

1. **Wrong app port annotation**:
   ```yaml
   # Fix app-port annotation
   annotations:
     dapr.io/app-port: "8000"  # Must match your app's port
   ```

2. **App not listening on 0.0.0.0**:
   ```python
   # Wrong - only listens on localhost
   uvicorn.run(app, host="127.0.0.1", port=8000)

   # Correct - listens on all interfaces
   uvicorn.run(app, host="0.0.0.0", port=8000)
   ```

3. **App not ready**:
   ```yaml
   # Add readiness probe
   spec:
     containers:
     - name: task-service
       readinessProbe:
         httpGet:
           path: /health
           port: 8000
         initialDelaySeconds: 5
         periodSeconds: 5
   ```

---

## Sidecar Performance Issues

### Issue: High CPU usage by sidecar

**Symptoms**:
```bash
# Sidecar using excessive CPU
kubectl top pods -n todo-app
# NAME                    CPU(cores)   MEMORY(bytes)
# task-service-xxx        500m         256Mi
#   ├─ task-service       50m          128Mi
#   └─ daprd              450m         128Mi  # Too high!
```

**Diagnosis**:
```bash
# Check sidecar metrics
kubectl exec -it task-service-xxx -n todo-app -c daprd -- curl http://localhost:9090/metrics

# Check for high request rate
kubectl logs task-service-xxx -n todo-app -c daprd | grep "invoke"
```

**Solutions**:

1. **Reduce logging level**:
   ```yaml
   annotations:
     dapr.io/log-level: "warn"  # Instead of "debug" or "info"
   ```

2. **Disable unnecessary features**:
   ```yaml
   annotations:
     dapr.io/enable-api-logging: "false"  # Disable API logging
     dapr.io/enable-metrics: "false"  # Disable metrics if not needed
   ```

3. **Optimize component configuration**:
   ```yaml
   # Reduce pub/sub concurrency
   metadata:
   - name: concurrency
     value: "10"  # Reduce from default
   ```

4. **Increase CPU limit**:
   ```yaml
   annotations:
     dapr.io/sidecar-cpu-limit: "1000m"  # Increase if needed
   ```

---

### Issue: High memory usage by sidecar

**Symptoms**:
```bash
kubectl top pods -n todo-app
# daprd container using excessive memory
```

**Solutions**:

1. **Reduce queue depth**:
   ```yaml
   # pubsub component
   metadata:
   - name: queueDepth
     value: "100"  # Reduce from default 1000
   ```

2. **Increase memory limit**:
   ```yaml
   annotations:
     dapr.io/sidecar-memory-limit: "512Mi"  # Increase if needed
   ```

3. **Enable memory profiling**:
   ```bash
   # Get memory profile
   kubectl exec -it task-service-xxx -n todo-app -c daprd -- curl http://localhost:9090/debug/pprof/heap > heap.prof
   ```

---

## Sidecar Injection Issues

### Issue: Sidecar not injected into pod

**Symptoms**:
```bash
kubectl get pods -n todo-app
# NAME                    READY   STATUS    RESTARTS   AGE
# task-service-xxx        1/1     Running   0          2m  # Should be 2/2!
```

**Diagnosis**:
```bash
# Check if Dapr sidecar injector is running
kubectl get pods -n dapr-system
# Should see dapr-sidecar-injector

# Check pod annotations
kubectl get pod task-service-xxx -n todo-app -o yaml | grep dapr.io
```

**Solutions**:

1. **Missing enabled annotation**:
   ```yaml
   # deployment.yaml
   metadata:
     annotations:
       dapr.io/enabled: "true"  # Required for injection!
   ```

2. **Sidecar injector not running**:
   ```bash
   # Check injector status
   kubectl get pods -n dapr-system -l app=dapr-sidecar-injector

   # Restart if needed
   kubectl rollout restart deployment/dapr-sidecar-injector -n dapr-system
   ```

3. **Namespace not labeled**:
   ```bash
   # Some setups require namespace label
   kubectl label namespace todo-app dapr.io/enabled=true
   ```

---

### Issue: Wrong sidecar version injected

**Symptoms**:
```bash
# Sidecar running old version
kubectl describe pod task-service-xxx -n todo-app | grep "Image:"
# Image: daprio/daprd:1.10.0  # But you want 1.12.0
```

**Solutions**:

1. **Upgrade Dapr**:
   ```bash
   # Upgrade Dapr on cluster
   dapr upgrade --kubernetes --runtime-version 1.12.0
   ```

2. **Force pod recreation**:
   ```bash
   # Delete pod to get new sidecar
   kubectl delete pod task-service-xxx -n todo-app

   # Or rollout restart
   kubectl rollout restart deployment/task-service -n todo-app
   ```

3. **Pin sidecar version**:
   ```yaml
   annotations:
     dapr.io/sidecar-image: "daprio/daprd:1.12.0"
   ```

---

## Sidecar Logging Issues

### Issue: Cannot see sidecar logs

**Symptoms**:
```bash
kubectl logs task-service-xxx -n todo-app -c daprd
# Error: container "daprd" not found
```

**Solutions**:

1. **Check container name**:
   ```bash
   # List all containers in pod
   kubectl get pod task-service-xxx -n todo-app -o jsonpath='{.spec.containers[*].name}'

   # Sidecar might be named differently
   kubectl logs task-service-xxx -n todo-app -c daprd
   ```

2. **Check if sidecar is running**:
   ```bash
   kubectl describe pod task-service-xxx -n todo-app
   # Look for daprd container status
   ```

---

### Issue: Too many logs from sidecar

**Symptoms**:
```bash
# Sidecar generating excessive logs
kubectl logs task-service-xxx -n todo-app -c daprd --tail=100
# Thousands of log lines
```

**Solutions**:

1. **Reduce log level**:
   ```yaml
   annotations:
     dapr.io/log-level: "warn"  # or "error"
   ```

2. **Disable API logging**:
   ```yaml
   annotations:
     dapr.io/enable-api-logging: "false"
   ```

3. **Configure log rotation**:
   ```yaml
   # Use log aggregation system (Fluentd, Loki, etc.)
   # to handle high log volume
   ```

---

## Sidecar Health Check Issues

### Issue: Sidecar health check failing

**Symptoms**:
```bash
kubectl describe pod task-service-xxx -n todo-app
# Events:
#   Liveness probe failed: HTTP probe failed with statuscode: 503
```

**Diagnosis**:
```bash
# Check sidecar health endpoint
kubectl exec -it task-service-xxx -n todo-app -c task-service -- curl http://localhost:3500/v1.0/healthz
```

**Solutions**:

1. **Component not ready**:
   ```bash
   # Check if component backends are healthy
   kubectl get pods -n todo-app
   # Ensure Redis, etc. are running
   ```

2. **Increase probe timeouts**:
   ```yaml
   # Custom health check configuration
   annotations:
     dapr.io/sidecar-liveness-probe-delay-seconds: "10"
     dapr.io/sidecar-liveness-probe-timeout-seconds: "5"
     dapr.io/sidecar-readiness-probe-delay-seconds: "5"
     dapr.io/sidecar-readiness-probe-timeout-seconds: "5"
   ```

---

## Debugging Sidecar Issues

### Enable Debug Logging

```yaml
annotations:
  dapr.io/log-level: "debug"
  dapr.io/enable-api-logging: "true"
```

### Access Sidecar Metrics

```bash
# Port forward to sidecar metrics
kubectl port-forward task-service-xxx -n todo-app 9090:9090

# View metrics
curl http://localhost:9090/metrics
```

### Get Sidecar Metadata

```bash
# Get Dapr metadata
kubectl exec -it task-service-xxx -n todo-app -c task-service -- curl http://localhost:3500/v1.0/metadata
```

### Profile Sidecar Performance

```bash
# CPU profile
kubectl exec -it task-service-xxx -n todo-app -c daprd -- curl http://localhost:9090/debug/pprof/profile?seconds=30 > cpu.prof

# Memory profile
kubectl exec -it task-service-xxx -n todo-app -c daprd -- curl http://localhost:9090/debug/pprof/heap > heap.prof

# Analyze with pprof
go tool pprof cpu.prof
```

---

## Best Practices

1. **Always set resource limits**:
   ```yaml
   annotations:
     dapr.io/sidecar-cpu-limit: "500m"
     dapr.io/sidecar-memory-limit: "512Mi"
     dapr.io/sidecar-cpu-request: "100m"
     dapr.io/sidecar-memory-request: "128Mi"
   ```

2. **Use appropriate log level**:
   ```yaml
   # Development
   dapr.io/log-level: "debug"

   # Production
   dapr.io/log-level: "warn"
   ```

3. **Monitor sidecar health**:
   ```yaml
   # Enable metrics
   dapr.io/enable-metrics: "true"
   dapr.io/metrics-port: "9090"
   ```

4. **Configure proper probes**:
   ```yaml
   # App container should have health checks
   livenessProbe:
     httpGet:
       path: /health
       port: 8000
   readinessProbe:
     httpGet:
       path: /health
       port: 8000
   ```

5. **Use namespaces for isolation**:
   ```bash
   # Separate environments
   kubectl create namespace todo-app-dev
   kubectl create namespace todo-app-prod
   ```

---

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `sidecar not injected` | Missing annotation | Add `dapr.io/enabled: "true"` |
| `connection refused` | Wrong port | Check `dapr.io/app-port` |
| `component not found` | Component not loaded | Check component YAML |
| `health check failed` | Backend not ready | Check component backends |
| `OOMKilled` | Memory limit too low | Increase memory limit |
| `CrashLoopBackOff` | Invalid config | Check sidecar logs |

---

## Getting Help

1. **Check sidecar logs**: `kubectl logs pod-name -c daprd`
2. **Check app logs**: `kubectl logs pod-name -c app-name`
3. **Check events**: `kubectl describe pod pod-name`
4. **Check Dapr status**: `dapr status -k`
5. **Search GitHub**: https://github.com/dapr/dapr/issues
6. **Ask on Discord**: https://discord.com/invite/ptHhX6jc34
