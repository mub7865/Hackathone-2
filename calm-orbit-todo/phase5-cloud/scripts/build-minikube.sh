#!/bin/bash

# Calm Orbit Todo - Minikube Build Script
# This script builds Docker images in Minikube's Docker environment

set -e

echo "🚀 Building Docker images for Minikube..."

# Use Minikube's Docker daemon
eval $(minikube docker-env)

# Build Backend Image
echo "📦 Building backend image..."
cd backend
docker build -t calm-orbit-backend:latest .
cd ..

# Build Frontend Image
echo "📦 Building frontend image..."
cd frontend
docker build \
  --build-arg NEXT_PUBLIC_API_URL=http://localhost:30800 \
  --build-arg NEXT_PUBLIC_BACKEND_URL=http://calm-orbit-backend:8000 \
  -t calm-orbit-frontend:latest .
cd ..

echo "✅ Docker images built successfully!"
echo ""
echo "Images available in Minikube:"
docker images | grep calm-orbit
