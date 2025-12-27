# Kubernetes Deployment Patterns Skill

## Overview

This skill provides complete patterns and best practices for deploying applications on Kubernetes. It covers Deployments, Services, ConfigMaps, Secrets, health probes, resource management, and production-ready configurations.

## Supported Platforms

- **Local**: Minikube, Docker Desktop, Kind
- **Cloud**: GKE (Google), EKS (AWS), AKS (Azure), DigitalOcean

## Key Features

- Production-ready Deployment configurations
- Service types (ClusterIP, NodePort, LoadBalancer)
- ConfigMaps and Secrets management
- Health probes (liveness, readiness, startup)
- Resource requests and limits
- kubectl commands reference

## Quick Reference

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: todo-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: my-backend:v1
        ports:
        - containerPort: 8000
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 8000
    targetPort: 8000
```

## Files

- `SKILL.md` - Complete skill documentation
- `Examples/` - Real-world YAML examples

## Usage

Reference this skill when:
- Creating Kubernetes manifests
- Deploying to Minikube or cloud K8s
- Setting up health checks
- Managing configuration and secrets

## Sources

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Kubernetes Best Practices 2025](https://kodekloud.com/blog/kubernetes-best-practices-2025/)
- [Service Types Explained](https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0)
