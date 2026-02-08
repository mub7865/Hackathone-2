# Kubernetes HorizontalPodAutoscaler (HPA) Templates
# HPA automatically scales the number of pods based on metrics

---
# Basic HPA (CPU-based)
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{APP_NAME}}-hpa
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{APP_NAME}}
  minReplicas: {{MIN_REPLICAS}}
  maxReplicas: {{MAX_REPLICAS}}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{CPU_TARGET}}  # e.g., 80

---
# HPA with CPU and Memory
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{APP_NAME}}-hpa-multi
  namespace: {{NAMESPACE}}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{APP_NAME}}
  minReplicas: {{MIN_REPLICAS}}
  maxReplicas: {{MAX_REPLICAS}}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80

---
# HPA with Custom Metrics
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{APP_NAME}}-hpa-custom
  namespace: {{NAMESPACE}}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{APP_NAME}}
  minReplicas: 2
  maxReplicas: 10
  metrics:
  # CPU metric
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80

  # Custom metric (requests per second)
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"

  # External metric (queue length)
  - type: External
    external:
      metric:
        name: queue_messages_ready
        selector:
          matchLabels:
            queue: "{{QUEUE_NAME}}"
      target:
        type: AverageValue
        averageValue: "30"

  # Scaling behavior
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 minutes before scaling down
      policies:
      - type: Percent
        value: 50  # Scale down max 50% of current pods
        periodSeconds: 60
      - type: Pods
        value: 2  # Scale down max 2 pods
        periodSeconds: 60
      selectPolicy: Min  # Use the policy that scales down the least
    scaleUp:
      stabilizationWindowSeconds: 0  # Scale up immediately
      policies:
      - type: Percent
        value: 100  # Scale up max 100% of current pods
        periodSeconds: 15
      - type: Pods
        value: 4  # Scale up max 4 pods
        periodSeconds: 15
      selectPolicy: Max  # Use the policy that scales up the most

---
# HPA with Advanced Scaling Behavior
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{APP_NAME}}-hpa-advanced
  namespace: {{NAMESPACE}}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{APP_NAME}}
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80

  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 25
        periodSeconds: 60
      - type: Pods
        value: 1
        periodSeconds: 60
      selectPolicy: Min
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 50
        periodSeconds: 30
      - type: Pods
        value: 2
        periodSeconds: 30
      selectPolicy: Max

---
# HPA for High Traffic Application
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{APP_NAME}}-hpa-hightraffic
  namespace: {{NAMESPACE}}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{APP_NAME}}
  minReplicas: 5  # Always keep minimum 5 replicas
  maxReplicas: 50  # Can scale up to 50 replicas
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60  # Lower threshold for faster scaling
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70

  behavior:
    scaleDown:
      stabilizationWindowSeconds: 600  # Wait 10 minutes before scaling down
      policies:
      - type: Percent
        value: 10  # Scale down slowly (10% at a time)
        periodSeconds: 120
    scaleUp:
      stabilizationWindowSeconds: 0  # Scale up immediately
      policies:
      - type: Percent
        value: 100  # Double the pods if needed
        periodSeconds: 15

---
# HPA with Container Resource Metrics
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{APP_NAME}}-hpa-container
  namespace: {{NAMESPACE}}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{APP_NAME}}
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: ContainerResource
    containerResource:
      name: cpu
      container: {{CONTAINER_NAME}}
      target:
        type: Utilization
        averageUtilization: 80
  - type: ContainerResource
    containerResource:
      name: memory
      container: {{CONTAINER_NAME}}
      target:
        type: Utilization
        averageUtilization: 80

---
# HPA Best Practices

# 1. Set appropriate min/max replicas
#    - minReplicas: Enough to handle baseline load
#    - maxReplicas: Enough to handle peak load

# 2. Use multiple metrics
#    - CPU and memory together
#    - Add custom metrics for better scaling decisions

# 3. Configure scaling behavior
#    - Slow scale-down to avoid flapping
#    - Fast scale-up to handle traffic spikes

# 4. Set resource requests
#    - HPA requires resource requests to be set
#    - Without requests, CPU/memory metrics won't work

# 5. Monitor and tune
#    - Watch HPA events: kubectl describe hpa {{APP_NAME}}-hpa
#    - Adjust thresholds based on actual usage

# 6. Test scaling
#    - Load test to verify scaling works
#    - Check scale-up and scale-down behavior

---
# kubectl Commands for HPA

# Create HPA
# kubectl apply -f hpa.yaml

# Get HPA status
# kubectl get hpa -n {{NAMESPACE}}

# Describe HPA (see events and current metrics)
# kubectl describe hpa {{APP_NAME}}-hpa -n {{NAMESPACE}}

# Watch HPA in real-time
# kubectl get hpa {{APP_NAME}}-hpa -n {{NAMESPACE}} --watch

# Delete HPA
# kubectl delete hpa {{APP_NAME}}-hpa -n {{NAMESPACE}}

# Create HPA imperatively
# kubectl autoscale deployment {{APP_NAME}} \
#   --min={{MIN_REPLICAS}} \
#   --max={{MAX_REPLICAS}} \
#   --cpu-percent={{CPU_TARGET}} \
#   -n {{NAMESPACE}}

---
# Testing HPA

# 1. Generate load
# kubectl run -it --rm load-generator --image=busybox --restart=Never -- /bin/sh
# while true; do wget -q -O- http://{{SERVICE_NAME}}.{{NAMESPACE}}.svc.cluster.local; done

# 2. Watch pods scale
# kubectl get pods -n {{NAMESPACE}} --watch

# 3. Check HPA metrics
# kubectl get hpa {{APP_NAME}}-hpa -n {{NAMESPACE}} --watch

# 4. View HPA events
# kubectl describe hpa {{APP_NAME}}-hpa -n {{NAMESPACE}}

---
# Metrics Server (Required for HPA)

# HPA requires Metrics Server to be installed
# Check if Metrics Server is running:
# kubectl get deployment metrics-server -n kube-system

# Install Metrics Server (if not present):
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# For Minikube:
# minikube addons enable metrics-server

# Verify metrics are available:
# kubectl top nodes
# kubectl top pods -n {{NAMESPACE}}

---
# Variable Reference
# Replace these placeholders with actual values:
#
# {{APP_NAME}}        - Application name
# {{NAMESPACE}}       - Kubernetes namespace
# {{MIN_REPLICAS}}    - Minimum number of replicas (e.g., 2)
# {{MAX_REPLICAS}}    - Maximum number of replicas (e.g., 10)
# {{CPU_TARGET}}      - Target CPU utilization percentage (e.g., 80)
# {{CONTAINER_NAME}}  - Container name in the pod
# {{QUEUE_NAME}}      - Queue name for external metrics
