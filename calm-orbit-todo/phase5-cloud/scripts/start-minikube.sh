#!/bin/bash

# Calm Orbit Todo - Minikube Start Script
# This script starts Minikube with proper configuration

set -e

echo "🚀 Starting Minikube..."

# Check if Minikube is already running
if minikube status > /dev/null 2>&1; then
    echo "✅ Minikube is already running"
    minikube status
    exit 0
fi

# Start Minikube with recommended settings
minikube start \
  --cpus=4 \
  --memory=4096 \
  --disk-size=20g \
  --driver=docker

echo ""
echo "✅ Minikube started successfully!"
echo ""
echo "📊 Minikube Status:"
minikube status
echo ""
echo "📝 Next steps:"
echo "  1. Build images:  ./scripts/build-minikube.sh"
echo "  2. Deploy:        ./scripts/deploy-minikube.sh"
