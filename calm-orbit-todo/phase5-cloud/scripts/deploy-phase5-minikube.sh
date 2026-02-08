#!/bin/bash
# Phase V Local Deployment Script for Minikube
# This script deploys the complete Phase V application with Kafka and Dapr

set -e  # Exit on error

echo "🚀 Phase V Local Deployment - Starting..."
echo "================================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# Check if Minikube is running
print_info "Checking Minikube status..."
if ! minikube status &> /dev/null; then
    print_warning "Minikube is not running. Starting Minikube..."
    minikube start --cpus=4 --memory=8192 --disk-size=20g --driver=docker
    print_success "Minikube started"
else
    print_success "Minikube is already running"
fi

# Check if Dapr is installed
print_info "Checking Dapr installation..."
if ! kubectl get namespace dapr-system &> /dev/null; then
    print_warning "Dapr is not installed."
    print_info "Skipping Dapr installation (Phase V will use direct Kafka)"
    print_info "To install Dapr later: kubectl apply -f https://github.com/dapr/dapr/releases/download/v1.14.0/dapr-operator.yaml"
    SKIP_DAPR=true
else
    print_success "Dapr is already installed"
    SKIP_DAPR=false
fi

# Set Docker environment to Minikube
print_info "Setting Docker environment to Minikube..."
eval $(minikube docker-env)
print_success "Docker environment configured"

# Build Docker images
print_info "Building Docker images..."
cd "$(dirname "$0")/.."

print_info "Building backend image..."
docker build -t calm-orbit-backend:latest ./backend
print_success "Backend image built"

print_info "Building frontend image..."
docker build -t calm-orbit-frontend:latest \
    --build-arg NEXT_PUBLIC_API_URL=http://$(minikube ip):30800 \
    --build-arg NEXT_PUBLIC_BACKEND_URL=http://calm-orbit-backend:8000 \
    ./frontend
print_success "Frontend image built"

# Deploy Kubernetes resources
print_info "Deploying Kubernetes resources..."

# Create namespace
print_info "Creating namespace..."
kubectl apply -f k8s/00-namespace.yaml
print_success "Namespace created"

# Create secrets
print_info "Creating secrets..."
kubectl apply -f k8s/01-secrets.yaml
print_success "Secrets created"

# Create configmap
print_info "Creating configmap..."
kubectl apply -f k8s/02-configmap.yaml
print_success "ConfigMap created"

# Deploy PostgreSQL
print_info "Deploying PostgreSQL..."
kubectl apply -f k8s/03-postgres.yaml
print_success "PostgreSQL deployed"

# Wait for PostgreSQL to be ready
print_info "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n calm-orbit --timeout=120s
print_success "PostgreSQL is ready"

# Deploy Redpanda (Kafka)
print_info "Deploying Redpanda (Kafka)..."
kubectl apply -f k8s/redpanda-local.yaml
print_success "Redpanda deployed"

# Wait for Redpanda to be ready
print_info "Waiting for Redpanda to be ready..."
kubectl wait --for=condition=ready pod -l app=redpanda -n calm-orbit --timeout=180s
print_success "Redpanda is ready"

# Wait for Kafka topics to be created
print_info "Waiting for Kafka topics to be created..."
sleep 30
print_success "Kafka topics should be created"

# Deploy Dapr components (if Dapr is installed)
if [ "$SKIP_DAPR" = false ]; then
    print_info "Deploying Dapr components..."
    kubectl apply -f k8s/dapr/
    print_success "Dapr components deployed"
else
    print_warning "Skipping Dapr components (Dapr not installed)"
    print_info "Phase V will use direct Kafka integration"
fi

# Deploy Backend
print_info "Deploying Backend..."
kubectl apply -f k8s/04-backend.yaml
print_success "Backend deployed"

# Wait for Backend to be ready
print_info "Waiting for Backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n calm-orbit --timeout=180s
print_success "Backend is ready"

# Deploy Frontend
print_info "Deploying Frontend..."
kubectl apply -f k8s/05-frontend.yaml
print_success "Frontend deployed"

# Wait for Frontend to be ready
print_info "Waiting for Frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n calm-orbit --timeout=180s
print_success "Frontend is ready"

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

echo ""
echo "================================================"
print_success "Phase V Deployment Complete! 🎉"
echo "================================================"
echo ""
echo "📊 Access URLs:"
echo "   Frontend:  http://${MINIKUBE_IP}:30300"
echo "   Backend:   http://${MINIKUBE_IP}:30800"
echo "   API Docs:  http://${MINIKUBE_IP}:30800/docs"
echo ""
echo "🔍 Useful Commands:"
echo "   View all pods:        kubectl get pods -n calm-orbit"
echo "   View all services:    kubectl get svc -n calm-orbit"
echo "   Backend logs:         kubectl logs -f -l app=backend -n calm-orbit"
echo "   Frontend logs:        kubectl logs -f -l app=frontend -n calm-orbit"
echo "   Kafka logs:           kubectl logs -f -l app=redpanda -n calm-orbit"
echo "   PostgreSQL logs:      kubectl logs -f -l app=postgres -n calm-orbit"
echo ""
echo "🧪 Test Phase V Features:"
echo "   1. Create a recurring task (weekly, daily, etc.)"
echo "   2. Set a task with due date and reminder"
echo "   3. Add priorities (high, medium, low) and tags"
echo "   4. Check backend logs for event publishing"
echo "   5. Verify schedulers are running (check logs)"
echo ""
echo "🗑️  Cleanup:"
echo "   ./scripts/cleanup-minikube.sh"
echo ""
