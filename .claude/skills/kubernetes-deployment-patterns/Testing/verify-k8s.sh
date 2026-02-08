#!/bin/bash
# Verification Script for Kubernetes Deployment Setup
# This script verifies that Kubernetes cluster and deployments are properly configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
PASSED=0
FAILED=0

echo "=========================================="
echo "Kubernetes Deployment Verification"
echo "=========================================="
echo ""

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASSED${NC}: $2"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}: $2"
        ((FAILED++))
    fi
}

# Test 1: Check kubectl is installed
echo "Test 1: Checking kubectl installation..."
if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1)
    print_result 0 "kubectl installed: $KUBECTL_VERSION"
else
    print_result 1 "kubectl not installed"
fi

echo ""

# Test 2: Check cluster connectivity
echo "Test 2: Checking cluster connectivity..."
if kubectl cluster-info &> /dev/null; then
    CLUSTER_INFO=$(kubectl cluster-info | head -1)
    print_result 0 "Cluster accessible: $CLUSTER_INFO"
else
    print_result 1 "Cannot connect to cluster"
fi

echo ""

# Test 3: Check cluster nodes
echo "Test 3: Checking cluster nodes..."
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
if [ "$NODE_COUNT" -gt 0 ]; then
    print_result 0 "Cluster has $NODE_COUNT node(s)"
    kubectl get nodes
else
    print_result 1 "No nodes found in cluster"
fi

echo ""

# Test 4: Check node status
echo "Test 4: Checking node status..."
NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -v " Ready" | wc -l)
if [ "$NOT_READY" -eq 0 ]; then
    print_result 0 "All nodes are Ready"
else
    print_result 1 "$NOT_READY node(s) not Ready"
fi

echo ""

# Test 5: Check namespaces
echo "Test 5: Checking namespaces..."
NAMESPACE_COUNT=$(kubectl get namespaces --no-headers 2>/dev/null | wc -l)
if [ "$NAMESPACE_COUNT" -gt 0 ]; then
    print_result 0 "Found $NAMESPACE_COUNT namespace(s)"
else
    print_result 1 "No namespaces found"
fi

echo ""

# Test 6: Check system pods
echo "Test 6: Checking system pods..."
SYSTEM_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | wc -l)
RUNNING_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep "Running" | wc -l)
if [ "$SYSTEM_PODS" -gt 0 ] && [ "$RUNNING_PODS" -eq "$SYSTEM_PODS" ]; then
    print_result 0 "All $SYSTEM_PODS system pods are Running"
else
    print_result 1 "Some system pods are not Running ($RUNNING_PODS/$SYSTEM_PODS)"
fi

echo ""

# Test 7: Check Metrics Server
echo "Test 7: Checking Metrics Server..."
if kubectl get deployment metrics-server -n kube-system &> /dev/null; then
    print_result 0 "Metrics Server is installed"

    # Check if metrics are available
    if kubectl top nodes &> /dev/null; then
        print_result 0 "Metrics Server is working"
    else
        print_result 1 "Metrics Server installed but not working"
    fi
else
    print_result 1 "Metrics Server not installed (required for HPA)"
fi

echo ""

# Test 8: Check DNS
echo "Test 8: Checking DNS..."
DNS_PODS=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | wc -l)
if [ "$DNS_PODS" -gt 0 ]; then
    print_result 0 "DNS pods found ($DNS_PODS)"
else
    # Try CoreDNS
    COREDNS_PODS=$(kubectl get pods -n kube-system -l k8s-app=coredns --no-headers 2>/dev/null | wc -l)
    if [ "$COREDNS_PODS" -gt 0 ]; then
        print_result 0 "CoreDNS pods found ($COREDNS_PODS)"
    else
        print_result 1 "No DNS pods found"
    fi
fi

echo ""

# Test 9: Check storage classes
echo "Test 9: Checking storage classes..."
STORAGE_CLASSES=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l)
if [ "$STORAGE_CLASSES" -gt 0 ]; then
    print_result 0 "Found $STORAGE_CLASSES storage class(es)"
    DEFAULT_SC=$(kubectl get storageclass --no-headers 2>/dev/null | grep "(default)" | wc -l)
    if [ "$DEFAULT_SC" -gt 0 ]; then
        print_result 0 "Default storage class is set"
    else
        print_result 1 "No default storage class"
    fi
else
    print_result 1 "No storage classes found"
fi

echo ""

# Test 10: Check RBAC
echo "Test 10: Checking RBAC..."
if kubectl auth can-i create deployments --all-namespaces &> /dev/null; then
    print_result 0 "Current user can create deployments"
else
    print_result 1 "Current user cannot create deployments"
fi

echo ""

# Test 11: Test deployment creation (dry-run)
echo "Test 11: Testing deployment creation (dry-run)..."
cat <<EOF | kubectl apply --dry-run=client -f - &> /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-deployment
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: test
        image: nginx:latest
EOF

if [ $? -eq 0 ]; then
    print_result 0 "Deployment YAML is valid"
else
    print_result 1 "Deployment YAML validation failed"
fi

echo ""

# Test 12: Test service creation (dry-run)
echo "Test 12: Testing service creation (dry-run)..."
cat <<EOF | kubectl apply --dry-run=client -f - &> /dev/null
apiVersion: v1
kind: Service
metadata:
  name: test-service
  namespace: default
spec:
  selector:
    app: test
  ports:
  - port: 80
    targetPort: 80
EOF

if [ $? -eq 0 ]; then
    print_result 0 "Service YAML is valid"
else
    print_result 1 "Service YAML validation failed"
fi

echo ""

# Test 13: Check Ingress Controller
echo "Test 13: Checking Ingress Controller..."
INGRESS_PODS=$(kubectl get pods -A -l app.kubernetes.io/name=ingress-nginx --no-headers 2>/dev/null | wc -l)
if [ "$INGRESS_PODS" -gt 0 ]; then
    print_result 0 "Ingress controller found (nginx)"
else
    # Try Traefik
    TRAEFIK_PODS=$(kubectl get pods -A -l app.kubernetes.io/name=traefik --no-headers 2>/dev/null | wc -l)
    if [ "$TRAEFIK_PODS" -gt 0 ]; then
        print_result 0 "Ingress controller found (traefik)"
    else
        print_result 1 "No ingress controller found (optional)"
    fi
fi

echo ""

# Test 14: Check cert-manager (optional)
echo "Test 14: Checking cert-manager (optional)..."
if kubectl get namespace cert-manager &> /dev/null; then
    CERT_MANAGER_PODS=$(kubectl get pods -n cert-manager --no-headers 2>/dev/null | wc -l)
    if [ "$CERT_MANAGER_PODS" -gt 0 ]; then
        print_result 0 "cert-manager is installed"
    else
        print_result 1 "cert-manager namespace exists but no pods"
    fi
else
    echo -e "${YELLOW}⚠${NC} cert-manager not installed (optional for TLS)"
fi

echo ""

# Test 15: Check resource usage
echo "Test 15: Checking resource usage..."
if kubectl top nodes &> /dev/null; then
    echo "Node resource usage:"
    kubectl top nodes
    print_result 0 "Resource metrics available"
else
    print_result 1 "Cannot get resource metrics (Metrics Server needed)"
fi

echo ""

# Summary
echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! Kubernetes cluster is ready.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please check the output above.${NC}"
    exit 1
fi
