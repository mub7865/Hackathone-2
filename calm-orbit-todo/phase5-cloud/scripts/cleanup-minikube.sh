#!/bin/bash

# Calm Orbit Todo - Minikube Cleanup Script
# This script removes all deployed resources from Minikube

set -e

echo "🧹 Cleaning up Calm Orbit Todo from Minikube..."

# Delete all resources in the namespace
kubectl delete namespace calm-orbit --ignore-not-found=true

echo "✅ Cleanup complete!"
echo ""
echo "📝 To redeploy:"
echo "  1. Build images:  ./scripts/build-minikube.sh"
echo "  2. Deploy:        ./scripts/deploy-minikube.sh"
