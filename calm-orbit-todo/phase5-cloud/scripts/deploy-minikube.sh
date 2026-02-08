#!/bin/bash

# Calm Orbit Todo - Minikube Deploy Script
# This script deploys the application to Minikube

set -e

echo "🚀 Deploying Calm Orbit Todo to Minikube..."

# Check if Minikube is running
if ! minikube status > /dev/null 2>&1; then
    echo "❌ Minikube is not running. Please start it with: minikube start"
    exit 1
fi

# Apply Kubernetes manifests in order
echo "📝 Applying Kubernetes manifests..."

kubectl apply -f k8s/00-namespace.yaml
echo "✅ Namespace created"

kubectl apply -f k8s/01-secrets.yaml
echo "✅ Secrets created"

kubectl apply -f k8s/02-configmap.yaml
echo "✅ ConfigMap created"

kubectl apply -f k8s/03-postgres.yaml
echo "✅ PostgreSQL deployed"

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n calm-orbit --timeout=120s

kubectl apply -f k8s/04-backend.yaml
echo "✅ Backend deployed"

# Wait for backend to be ready
echo "⏳ Waiting for backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n calm-orbit --timeout=120s

kubectl apply -f k8s/05-frontend.yaml
echo "✅ Frontend deployed"

# Wait for frontend to be ready
echo "⏳ Waiting for frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n calm-orbit --timeout=120s

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Deployment Status:"
kubectl get pods -n calm-orbit
echo ""
echo "🌐 Access URLs:"
echo "  Frontend: http://$(minikube ip):30300"
echo "  Backend:  http://$(minikube ip):30800"
echo ""
echo "📝 Useful commands:"
echo "  View logs (backend):  kubectl logs -f -l app=backend -n calm-orbit"
echo "  View logs (frontend): kubectl logs -f -l app=frontend -n calm-orbit"
echo "  View all resources:   kubectl get all -n calm-orbit"
echo "  Delete deployment:    ./scripts/cleanup-minikube.sh"
