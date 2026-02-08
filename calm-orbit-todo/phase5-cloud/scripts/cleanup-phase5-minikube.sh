#!/bin/bash
# Phase V Cleanup Script for Minikube
# This script removes all Phase V resources from Minikube

set -e  # Exit on error

echo "🗑️  Phase V Cleanup - Starting..."
echo "================================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# Delete namespace (this will delete all resources in it)
print_info "Deleting calm-orbit namespace..."
kubectl delete namespace calm-orbit --ignore-not-found=true
print_success "Namespace deleted"

# Wait for namespace to be fully deleted
print_info "Waiting for namespace to be fully deleted..."
kubectl wait --for=delete namespace/calm-orbit --timeout=120s 2>/dev/null || true
print_success "Namespace fully deleted"

# Delete Dapr components (if they exist outside namespace)
print_info "Cleaning up Dapr components..."
kubectl delete component pubsub-kafka -n calm-orbit --ignore-not-found=true
print_success "Dapr components cleaned up"

echo ""
echo "================================================"
print_success "Phase V Cleanup Complete! 🎉"
echo "================================================"
echo ""
print_info "To redeploy, run: ./scripts/deploy-phase5-minikube.sh"
echo ""
