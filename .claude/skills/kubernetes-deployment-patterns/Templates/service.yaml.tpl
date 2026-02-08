# Kubernetes Service Templates
# Services provide stable network access to Pods

---
# ClusterIP Service (Internal Only)
# Use for internal communication between services
apiVersion: v1
kind: Service
metadata:
  name: {{APP_NAME}}-service
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
  annotations:
    service.kubernetes.io/description: "Internal service for {{APP_NAME}}"
spec:
  type: ClusterIP
  selector:
    app: {{APP_NAME}}
  ports:
  - name: http
    port: {{SERVICE_PORT}}
    targetPort: {{CONTAINER_PORT}}
    protocol: TCP
  sessionAffinity: None

---
# ClusterIP with Session Affinity
# Use when you need sticky sessions
apiVersion: v1
kind: Service
metadata:
  name: {{APP_NAME}}-sticky
  namespace: {{NAMESPACE}}
spec:
  type: ClusterIP
  selector:
    app: {{APP_NAME}}
  ports:
  - port: {{SERVICE_PORT}}
    targetPort: {{CONTAINER_PORT}}
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3 hours

---
# NodePort Service (External Access - Dev/Test)
# Use for development or testing external access
apiVersion: v1
kind: Service
metadata:
  name: {{APP_NAME}}-nodeport
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
spec:
  type: NodePort
  selector:
    app: {{APP_NAME}}
  ports:
  - name: http
    port: {{SERVICE_PORT}}
    targetPort: {{CONTAINER_PORT}}
    nodePort: {{NODE_PORT}}  # 30000-32767
    protocol: TCP

---
# LoadBalancer Service (External Access - Production)
# Use for production external access (cloud providers only)
apiVersion: v1
kind: Service
metadata:
  name: {{APP_NAME}}-lb
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
  annotations:
    # Cloud-specific annotations
    # AWS
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    # GCP
    cloud.google.com/load-balancer-type: "Internal"
    # Azure
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  selector:
    app: {{APP_NAME}}
  ports:
  - name: http
    port: 80
    targetPort: {{CONTAINER_PORT}}
    protocol: TCP
  - name: https
    port: 443
    targetPort: {{CONTAINER_PORT}}
    protocol: TCP
  # Optional: Specify load balancer IP
  # loadBalancerIP: "203.0.113.10"
  # Optional: Restrict source IPs
  # loadBalancerSourceRanges:
  # - "10.0.0.0/8"

---
# Headless Service (StatefulSet)
# Use for StatefulSets or when you need direct Pod IPs
apiVersion: v1
kind: Service
metadata:
  name: {{APP_NAME}}-headless
  namespace: {{NAMESPACE}}
spec:
  clusterIP: None  # Headless service
  selector:
    app: {{APP_NAME}}
  ports:
  - port: {{SERVICE_PORT}}
    targetPort: {{CONTAINER_PORT}}

---
# ExternalName Service (External Service Alias)
# Use to create an alias for an external service
apiVersion: v1
kind: Service
metadata:
  name: {{EXTERNAL_SERVICE_NAME}}
  namespace: {{NAMESPACE}}
spec:
  type: ExternalName
  externalName: {{EXTERNAL_DNS_NAME}}  # e.g., database.example.com
  ports:
  - port: {{SERVICE_PORT}}

---
# Multi-Port Service
# Use when container exposes multiple ports
apiVersion: v1
kind: Service
metadata:
  name: {{APP_NAME}}-multiport
  namespace: {{NAMESPACE}}
spec:
  type: ClusterIP
  selector:
    app: {{APP_NAME}}
  ports:
  - name: http
    port: 8000
    targetPort: 8000
    protocol: TCP
  - name: grpc
    port: 9000
    targetPort: 9000
    protocol: TCP
  - name: metrics
    port: 9090
    targetPort: 9090
    protocol: TCP

---
# Service with Health Check (AWS)
apiVersion: v1
kind: Service
metadata:
  name: {{APP_NAME}}-health
  namespace: {{NAMESPACE}}
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: "/health"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval: "10"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-timeout: "5"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-healthy-threshold: "2"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-unhealthy-threshold: "2"
spec:
  type: LoadBalancer
  selector:
    app: {{APP_NAME}}
  ports:
  - port: 80
    targetPort: 8000

---
# Service for Canary Deployment
# Routes traffic to both stable and canary versions
apiVersion: v1
kind: Service
metadata:
  name: {{APP_NAME}}-canary
  namespace: {{NAMESPACE}}
spec:
  type: ClusterIP
  selector:
    app: {{APP_NAME}}  # Matches both stable and canary
  ports:
  - port: {{SERVICE_PORT}}
    targetPort: {{CONTAINER_PORT}}

---
# Service for Blue-Green Deployment
# Switch traffic by updating selector
apiVersion: v1
kind: Service
metadata:
  name: {{APP_NAME}}-bluegreen
  namespace: {{NAMESPACE}}
spec:
  type: LoadBalancer
  selector:
    app: {{APP_NAME}}
    version: blue  # Change to "green" to switch traffic
  ports:
  - port: 80
    targetPort: {{CONTAINER_PORT}}

---
# Complete Production Service
apiVersion: v1
kind: Service
metadata:
  name: {{APP_NAME}}-prod
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
    tier: {{TIER}}
    environment: production
  annotations:
    service.kubernetes.io/description: "Production service for {{APP_NAME}}"
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
spec:
  type: {{SERVICE_TYPE}}
  selector:
    app: {{APP_NAME}}
  ports:
  - name: http
    port: {{SERVICE_PORT}}
    targetPort: http
    protocol: TCP
  - name: metrics
    port: 9090
    targetPort: metrics
    protocol: TCP
  sessionAffinity: None
  # Optional: IP family policy for dual-stack
  ipFamilyPolicy: PreferDualStack
  ipFamilies:
  - IPv4
  - IPv6

---
# Variable Reference
# Replace these placeholders with actual values:
#
# {{APP_NAME}}              - Application name (e.g., backend, frontend)
# {{NAMESPACE}}             - Kubernetes namespace (e.g., todo-app)
# {{SERVICE_PORT}}          - Service port (e.g., 8000)
# {{CONTAINER_PORT}}        - Container port (e.g., 8000)
# {{NODE_PORT}}             - NodePort (30000-32767)
# {{SERVICE_TYPE}}          - Service type (ClusterIP, NodePort, LoadBalancer)
# {{TIER}}                  - Application tier (frontend, backend)
# {{EXTERNAL_SERVICE_NAME}} - External service name
# {{EXTERNAL_DNS_NAME}}     - External DNS name (e.g., database.example.com)
