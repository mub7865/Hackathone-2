# Phase IV: Local Kubernetes Deployment

## Overview
This phase contains Kubernetes deployment configurations for the Todo Chatbot application.

## Contents
- `helm-charts/` - Helm chart for deploying to Minikube



- Docker images: todo-backend:v1.1.0, todo-frontend:v1.1.0

## Deployment
```bash
# Build and load images to Minikube
minikube image load todo-backend:v1.1.0
minikube image load todo-frontend:v1.1.0

# Deploy with Helm
helm install todo-chatbot ./helm-charts -n todo-app --create-namespace

# Port-forward for access
kubectl port-forward -n todo-app svc/frontend-service 3000:3000 --address=0.0.0.0 &
kubectl port-forward -n todo-app svc/backend-service 8001:8000 --address=0.0.0.0 &
```

## Access
- Frontend: http://localhost:3000
- Backend API: http://localhost:8001
