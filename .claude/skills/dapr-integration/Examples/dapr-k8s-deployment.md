# Dapr Kubernetes Deployment

This guide shows how to deploy Dapr-enabled applications to Kubernetes.

## Prerequisites

- Kubernetes cluster (Minikube, AKS, EKS, GKE, etc.)
- kubectl configured
- Helm 3.x installed

## Step 1: Install Dapr on Kubernetes

### Using Dapr CLI

```bash
# Install Dapr on Kubernetes
dapr init --kubernetes --wait

# Verify installation
dapr status -k

# Expected output:
#   NAME                   NAMESPACE    HEALTHY  STATUS   REPLICAS  VERSION  AGE  CREATED
#   dapr-sidecar-injector  dapr-system  True     Running  1         1.12.0   1m   2024-01-09 10:00:00
#   dapr-sentry            dapr-system  True     Running  1         1.12.0   1m   2024-01-09 10:00:00
#   dapr-operator          dapr-system  True     Running  1         1.12.0   1m   2024-01-09 10:00:00
#   dapr-placement         dapr-system  True     Running  1         1.12.0   1m   2024-01-09 10:00:00
```

### Using Helm

```bash
# Add Dapr Helm repo
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update

# Install Dapr
helm upgrade --install dapr dapr/dapr \
  --version=1.12 \
  --namespace dapr-system \
  --create-namespace \
  --wait

# Verify
kubectl get pods -n dapr-system
```

## Step 2: Create Namespace and Components

### Create Namespace

```bash
kubectl create namespace todo-app
```

### Deploy Components

**k8s/components/pubsub.yaml**
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub
  namespace: todo-app
spec:
  type: pubsub.redis
  version: v1
  metadata:
  - name: redisHost
    value: redis-service.todo-app.svc.cluster.local:6379
  - name: redisPassword
    secretKeyRef:
      name: redis-secret
      key: password
  - name: enableTLS
    value: "false"
```

**k8s/components/statestore.yaml**
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
  namespace: todo-app
spec:
  type: state.redis
  version: v1
  metadata:
  - name: redisHost
    value: redis-service.todo-app.svc.cluster.local:6379
  - name: redisPassword
    secretKeyRef:
      name: redis-secret
      key: password
  - name: actorStateStore
    value: "true"
```

**k8s/components/secrets.yaml**
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: kubernetes-secret-store
  namespace: todo-app
spec:
  type: secretstores.kubernetes
  version: v1
  metadata: []
```

### Apply Components

```bash
kubectl apply -f k8s/components/
```

## Step 3: Deploy Redis

**k8s/redis.yaml**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: redis-secret
  namespace: todo-app
type: Opaque
stringData:
  password: ""  # Empty for no password

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: todo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"

---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: todo-app
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
```

```bash
kubectl apply -f k8s/redis.yaml
```

## Step 4: Deploy Task Service

**k8s/task-service.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: task-service
  namespace: todo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: task-service
  template:
    metadata:
      labels:
        app: task-service
      annotations:
        dapr.io/enabled: "true"
        dapr.io/app-id: "task-service"
        dapr.io/app-port: "8000"
        dapr.io/enable-api-logging: "true"
        dapr.io/log-level: "info"
        dapr.io/sidecar-cpu-limit: "200m"
        dapr.io/sidecar-memory-limit: "256Mi"
    spec:
      containers:
      - name: task-service
        image: your-registry/task-service:latest
        ports:
        - containerPort: 8000
        env:
        - name: DAPR_HTTP_PORT
          value: "3500"
        - name: DAPR_GRPC_PORT
          value: "50001"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: task-service
  namespace: todo-app
spec:
  selector:
    app: task-service
  ports:
  - name: http
    port: 80
    targetPort: 8000
  type: ClusterIP
```

### Key Dapr Annotations

- `dapr.io/enabled: "true"` - Enable Dapr sidecar injection
- `dapr.io/app-id: "task-service"` - Unique app ID for service discovery
- `dapr.io/app-port: "8000"` - Port your app listens on
- `dapr.io/enable-api-logging: "true"` - Log Dapr API calls
- `dapr.io/log-level: "info"` - Dapr sidecar log level
- `dapr.io/sidecar-cpu-limit: "200m"` - CPU limit for sidecar
- `dapr.io/sidecar-memory-limit: "256Mi"` - Memory limit for sidecar

```bash
kubectl apply -f k8s/task-service.yaml
```

## Step 5: Deploy Notification Service

**k8s/notification-service.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notification-service
  namespace: todo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: notification-service
  template:
    metadata:
      labels:
        app: notification-service
      annotations:
        dapr.io/enabled: "true"
        dapr.io/app-id: "notification-service"
        dapr.io/app-port: "8001"
        dapr.io/enable-api-logging: "true"
    spec:
      containers:
      - name: notification-service
        image: your-registry/notification-service:latest
        ports:
        - containerPort: 8001
        env:
        - name: DAPR_HTTP_PORT
          value: "3500"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"

---
apiVersion: v1
kind: Service
metadata:
  name: notification-service
  namespace: todo-app
spec:
  selector:
    app: notification-service
  ports:
  - port: 80
    targetPort: 8001
```

```bash
kubectl apply -f k8s/notification-service.yaml
```

## Step 6: Create Ingress (Optional)

**k8s/ingress.yaml**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: task-service-ingress
  namespace: todo-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: tasks.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: task-service
            port:
              number: 80
```

```bash
kubectl apply -f k8s/ingress.yaml
```

## Step 7: Verify Deployment

### Check Pods

```bash
# List all pods
kubectl get pods -n todo-app

# Expected output:
# NAME                                    READY   STATUS    RESTARTS   AGE
# redis-xxx                               1/1     Running   0          5m
# task-service-xxx                        2/2     Running   0          3m
# notification-service-xxx                2/2     Running   0          3m

# Note: 2/2 means app container + Dapr sidecar
```

### Check Dapr Sidecars

```bash
# View Dapr sidecar logs
kubectl logs -n todo-app task-service-xxx -c daprd

# View app logs
kubectl logs -n todo-app task-service-xxx -c task-service
```

### Test Service Invocation

```bash
# Port forward to task service
kubectl port-forward -n todo-app svc/task-service 8000:80

# Test endpoint
curl http://localhost:8000/health
```

### Test Pub/Sub

```bash
# Create a task (publishes event)
curl -X POST http://localhost:8000/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Task",
    "user_id": "user_123"
  }'

# Check notification service logs
kubectl logs -n todo-app -l app=notification-service -c notification-service
```

## Step 8: Service-to-Service Invocation

Services can call each other using Dapr service invocation:

```python
# In task-service, call notification-service
from dapr.clients import DaprClient

with DaprClient() as client:
    response = client.invoke_method(
        app_id='notification-service',
        method_name='send-notification',
        http_verb='POST',
        data={'message': 'Task created'}
    )
```

Dapr handles:
- Service discovery
- Load balancing
- Retries
- Circuit breaking
- mTLS encryption

## Step 9: Monitoring and Observability

### View Dapr Dashboard

```bash
# Port forward Dapr dashboard
kubectl port-forward -n dapr-system svc/dapr-dashboard 8080:8080

# Open http://localhost:8080
```

### View Distributed Traces

If you have Zipkin/Jaeger installed:

```bash
# Port forward Zipkin
kubectl port-forward -n dapr-system svc/zipkin 9411:9411

# Open http://localhost:9411
```

### Prometheus Metrics

Dapr exposes Prometheus metrics on port 9090:

```bash
# Scrape metrics
kubectl port-forward -n todo-app task-service-xxx 9090:9090
curl http://localhost:9090/metrics
```

## Step 10: Scaling

### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: task-service-hpa
  namespace: todo-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: task-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

```bash
kubectl apply -f k8s/hpa.yaml
```

## Complete Project Structure

```
k8s/
├── components/
│   ├── pubsub.yaml
│   ├── statestore.yaml
│   └── secrets.yaml
├── redis.yaml
├── task-service.yaml
├── notification-service.yaml
├── ingress.yaml
└── hpa.yaml
```

## Deployment Script

**deploy.sh**
```bash
#!/bin/bash

# Create namespace
kubectl create namespace todo-app --dry-run=client -o yaml | kubectl apply -f -

# Deploy components
kubectl apply -f k8s/components/

# Deploy Redis
kubectl apply -f k8s/redis.yaml

# Wait for Redis
kubectl wait --for=condition=ready pod -l app=redis -n todo-app --timeout=60s

# Deploy services
kubectl apply -f k8s/task-service.yaml
kubectl apply -f k8s/notification-service.yaml

# Wait for services
kubectl wait --for=condition=ready pod -l app=task-service -n todo-app --timeout=120s
kubectl wait --for=condition=ready pod -l app=notification-service -n todo-app --timeout=120s

# Deploy ingress
kubectl apply -f k8s/ingress.yaml

echo "Deployment complete!"
kubectl get pods -n todo-app
```

## Cleanup

```bash
# Delete namespace (removes everything)
kubectl delete namespace todo-app

# Uninstall Dapr
dapr uninstall --kubernetes
```

## Best Practices

1. **Use namespaces** - Isolate environments (dev, staging, prod)
2. **Set resource limits** - Prevent resource exhaustion
3. **Enable mTLS** - Secure service-to-service communication
4. **Use secrets** - Never hardcode credentials
5. **Monitor sidecars** - Watch Dapr sidecar resource usage
6. **Scale appropriately** - Use HPA for auto-scaling
7. **Enable tracing** - Use Zipkin/Jaeger for debugging
8. **Use health checks** - Implement liveness and readiness probes

## Troubleshooting

See `dapr-sidecar-issues.md` for common Kubernetes deployment issues.
