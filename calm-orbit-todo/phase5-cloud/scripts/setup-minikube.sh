#!/bin/bash

# Calm Orbit Todo - Complete Minikube Setup
# This script performs the complete setup: start, build, and deploy

set -e

echo "🚀 Complete Minikube Setup for Calm Orbit Todo"
echo "=============================================="
echo ""

# Step 1: Start Minikube
echo "Step 1/3: Starting Minikube..."
./scripts/start-minikube.sh
echo ""

# Step 2: Build Docker images
echo "Step 2/3: Building Docker images..."
./scripts/build-minikube.sh
echo ""

# Step 3: Deploy to Minikube
echo "Step 3/3: Deploying to Minikube..."
./scripts/deploy-minikube.sh
echo ""

echo "=============================================="
echo "✅ Complete setup finished!"
echo ""
echo "🌐 Your application is now running at:"
echo "  Frontend: http://$(minikube ip):30300"
echo "  Backend:  http://$(minikube ip):30800"
echo ""
echo "📝 To access the application:"
echo "  1. Open your browser"
echo "  2. Navigate to: http://$(minikube ip):30300"
echo ""
echo "🔍 To monitor the deployment:"
echo "  kubectl get pods -n calm-orbit -w"
