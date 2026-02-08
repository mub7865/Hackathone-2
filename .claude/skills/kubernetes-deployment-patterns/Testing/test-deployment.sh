#!/bin/bash
# Test Deployment Script for Kubernetes
# This script tests a complete application deployment

set -e

# Configuration
NAMESPACE="${NAMESPACE:-test-app}"
APP_NAME="${APP_NAME:-test-deployment}"
IMAGE="${IMAGE:-nginx:latest}"
REPLICAS="${REPLICAS:-2}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Kubernetes Deployment Test"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Namespace: $NAMESPACE"
echo "  App Name: $APP_NAME"
echo "  Image: $IMAGE"
echo "  Replicas: $REPLICAS"
echo ""

# Function to print status
print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to wait for condition
wait_for_condition() {
    local description=$1
    local command=$2
    local timeout=${3:-60}
    local interval=5

    print_status "Waiting for: $description"

    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if eval "$command" &> /dev/null; then
            print_success "$description (${elapsed}s)"
            return 0
        fi
        sleep $interval
        elapsed=$((elapsed + interval))
        echo -n "."
    done

    echo ""
    print_error "$description (timeout after ${timeout}s)"
    return 1
}

# Cleanup function
cleanup() {
    print_status "Cleaning up test resources..."
    kubectl delete namespace $NAMESPACE --ignore-not-found=true --wait=false
    print_success "Cleanup initiated"
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Step 1: Create namespace
print_status "Creating namespace: $NAMESPACE"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
  labels:
    test: "true"
EOF
print_success "Namespace created"

# Step 2: Create ConfigMap
print_status "Creating ConfigMap"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${APP_NAME}-config
  namespace: $NAMESPACE
data:
  APP_ENV: "test"
  LOG_LEVEL: "debug"
EOF
print_success "ConfigMap created"

# Step 3: Create Secret
print_status "Creating Secret"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${APP_NAME}-secret
  namespace: $NAMESPACE
type: Opaque
stringData:
  API_KEY: "test-api-key-12345"
EOF
print_success "Secret created"

# Step 4: Create Deployment
print_status "Creating Deployment"
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
  labels:
    app: $APP_NAME
spec:
  replicas: $REPLICAS
  selector:
    matchLabels:
      app: $APP_NAME
  template:
    metadata:
      labels:
        app: $APP_NAME
    spec:
      containers:
      - name: $APP_NAME
        image: $IMAGE
        ports:
        - containerPort: 80
        envFrom:
        - configMapRef:
            name: ${APP_NAME}-config
        - secretRef:
            name: ${APP_NAME}-secret
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "100m"
            memory: "128Mi"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
print_success "Deployment created"

# Step 5: Wait for deployment to be ready
wait_for_condition \
    "Deployment rollout" \
    "kubectl rollout status deployment/$APP_NAME -n $NAMESPACE" \
    120

# Step 6: Check pods are running
print_status "Checking pods"
RUNNING_PODS=$(kubectl get pods -n $NAMESPACE -l app=$APP_NAME --field-selector=status.phase=Running --no-headers | wc -l)
if [ "$RUNNING_PODS" -eq "$REPLICAS" ]; then
    print_success "All $REPLICAS pods are running"
else
    print_error "Expected $REPLICAS pods, found $RUNNING_PODS running"
    kubectl get pods -n $NAMESPACE -l app=$APP_NAME
    exit 1
fi

# Step 7: Create Service
print_status "Creating Service"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ${APP_NAME}-service
  namespace: $NAMESPACE
spec:
  type: ClusterIP
  selector:
    app: $APP_NAME
  ports:
  - port: 80
    targetPort: 80
EOF
print_success "Service created"

# Step 8: Check service endpoints
wait_for_condition \
    "Service endpoints" \
    "[ \$(kubectl get endpoints ${APP_NAME}-service -n $NAMESPACE -o jsonpath='{.subsets[0].addresses}' | grep -o 'ip' | wc -l) -eq $REPLICAS ]" \
    30

# Step 9: Test service connectivity
print_status "Testing service connectivity"
kubectl run test-pod -n $NAMESPACE --image=busybox:1.36 --rm -it --restart=Never -- \
    wget -q -O- http://${APP_NAME}-service &> /dev/null

if [ $? -eq 0 ]; then
    print_success "Service is accessible"
else
    print_error "Service is not accessible"
    exit 1
fi

# Step 10: Test scaling
print_status "Testing scaling (scale to 3)"
kubectl scale deployment/$APP_NAME -n $NAMESPACE --replicas=3

wait_for_condition \
    "Scale up to 3 replicas" \
    "[ \$(kubectl get deployment/$APP_NAME -n $NAMESPACE -o jsonpath='{.status.readyReplicas}') -eq 3 ]" \
    60

print_status "Testing scaling (scale back to $REPLICAS)"
kubectl scale deployment/$APP_NAME -n $NAMESPACE --replicas=$REPLICAS

wait_for_condition \
    "Scale down to $REPLICAS replicas" \
    "[ \$(kubectl get deployment/$APP_NAME -n $NAMESPACE -o jsonpath='{.status.readyReplicas}') -eq $REPLICAS ]" \
    60

# Step 11: Test rolling update
print_status "Testing rolling update"
kubectl set image deployment/$APP_NAME -n $NAMESPACE $APP_NAME=nginx:alpine

wait_for_condition \
    "Rolling update" \
    "kubectl rollout status deployment/$APP_NAME -n $NAMESPACE" \
    120

# Step 12: Verify update
NEW_IMAGE=$(kubectl get deployment/$APP_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}')
if [ "$NEW_IMAGE" = "nginx:alpine" ]; then
    print_success "Rolling update successful (image: $NEW_IMAGE)"
else
    print_error "Rolling update failed (image: $NEW_IMAGE)"
    exit 1
fi

# Step 13: Test rollback
print_status "Testing rollback"
kubectl rollout undo deployment/$APP_NAME -n $NAMESPACE

wait_for_condition \
    "Rollback" \
    "kubectl rollout status deployment/$APP_NAME -n $NAMESPACE" \
    120

# Step 14: Verify rollback
ROLLED_BACK_IMAGE=$(kubectl get deployment/$APP_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}')
if [ "$ROLLED_BACK_IMAGE" = "$IMAGE" ]; then
    print_success "Rollback successful (image: $ROLLED_BACK_IMAGE)"
else
    print_error "Rollback failed (image: $ROLLED_BACK_IMAGE)"
    exit 1
fi

# Step 15: Test pod restart
print_status "Testing pod restart"
FIRST_POD=$(kubectl get pods -n $NAMESPACE -l app=$APP_NAME -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $FIRST_POD -n $NAMESPACE

wait_for_condition \
    "Pod recreation" \
    "[ \$(kubectl get pods -n $NAMESPACE -l app=$APP_NAME --field-selector=status.phase=Running --no-headers | wc -l) -eq $REPLICAS ]" \
    60

# Step 16: Check logs
print_status "Checking pod logs"
FIRST_POD=$(kubectl get pods -n $NAMESPACE -l app=$APP_NAME -o jsonpath='{.items[0].metadata.name}')
LOG_OUTPUT=$(kubectl logs $FIRST_POD -n $NAMESPACE --tail=10)
if [ -n "$LOG_OUTPUT" ]; then
    print_success "Pod logs are accessible"
else
    print_warning "Pod logs are empty (may be normal for nginx)"
fi

# Step 17: Test resource limits
print_status "Checking resource limits"
CPU_LIMIT=$(kubectl get deployment/$APP_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
MEMORY_LIMIT=$(kubectl get deployment/$APP_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')
print_success "Resource limits: CPU=$CPU_LIMIT, Memory=$MEMORY_LIMIT"

# Step 18: Test health probes
print_status "Checking health probes"
LIVENESS=$(kubectl get deployment/$APP_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}')
READINESS=$(kubectl get deployment/$APP_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}')
if [ -n "$LIVENESS" ] && [ -n "$READINESS" ]; then
    print_success "Health probes are configured"
else
    print_error "Health probes are missing"
    exit 1
fi

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "${GREEN}✓ All tests passed!${NC}"
echo ""
echo "Test Results:"
echo "  ✓ Namespace creation"
echo "  ✓ ConfigMap creation"
echo "  ✓ Secret creation"
echo "  ✓ Deployment creation"
echo "  ✓ Pod startup"
echo "  ✓ Service creation"
echo "  ✓ Service connectivity"
echo "  ✓ Scaling up"
echo "  ✓ Scaling down"
echo "  ✓ Rolling update"
echo "  ✓ Rollback"
echo "  ✓ Pod restart"
echo "  ✓ Logs access"
echo "  ✓ Resource limits"
echo "  ✓ Health probes"
echo ""
echo "Cleanup will run automatically..."
