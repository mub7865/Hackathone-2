#!/bin/bash

# GCP CLI Verification Script
# Tests gcloud CLI installation and basic functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((TESTS_FAILED++))
    fi
}

echo "=========================================="
echo "GCP CLI Verification"
echo "=========================================="
echo ""

# Test 1: Check if gcloud CLI is installed
echo "Test 1: Checking gcloud CLI installation..."
if command -v gcloud &> /dev/null; then
    GCLOUD_VERSION=$(gcloud version --format="value(version)")
    print_result 0 "gcloud CLI is installed (version: $GCLOUD_VERSION)"
else
    print_result 1 "gcloud CLI is not installed"
    echo "Install: curl https://sdk.cloud.google.com | bash"
fi

# Test 2: Check if authenticated
echo ""
echo "Test 2: Checking GCP authentication..."
if gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    print_result 0 "Authenticated as: $ACCOUNT"
else
    print_result 1 "Not authenticated to GCP"
    echo "Login: gcloud auth login"
fi

# Test 3: Check active project
echo ""
echo "Test 3: Checking active project..."
if PROJECT=$(gcloud config get-value project 2>/dev/null); then
    if [ -n "$PROJECT" ]; then
        print_result 0 "Active project: $PROJECT"
    else
        print_result 1 "No active project set"
        echo "Set project: gcloud config set project PROJECT_ID"
    fi
else
    print_result 1 "Cannot get active project"
fi

# Test 4: Check default region
echo ""
echo "Test 4: Checking default region..."
if REGION=$(gcloud config get-value compute/region 2>/dev/null); then
    if [ -n "$REGION" ]; then
        print_result 0 "Default region: $REGION"
    else
        print_result 1 "No default region set"
        echo "Set region: gcloud config set compute/region us-central1"
    fi
else
    print_result 1 "Cannot get default region"
fi

# Test 5: Check Cloud Run API
echo ""
echo "Test 5: Checking Cloud Run API..."
if gcloud services list --enabled --filter="name:run.googleapis.com" --format="value(name)" | grep -q "run.googleapis.com"; then
    print_result 0 "Cloud Run API is enabled"
else
    print_result 1 "Cloud Run API is not enabled"
    echo "Enable: gcloud services enable run.googleapis.com"
fi

# Test 6: Check Cloud SQL API
echo ""
echo "Test 6: Checking Cloud SQL API..."
if gcloud services list --enabled --filter="name:sqladmin.googleapis.com" --format="value(name)" | grep -q "sqladmin.googleapis.com"; then
    print_result 0 "Cloud SQL API is enabled"
else
    print_result 1 "Cloud SQL API is not enabled"
    echo "Enable: gcloud services enable sqladmin.googleapis.com"
fi

# Test 7: Check Cloud Run services
echo ""
echo "Test 7: Checking Cloud Run services..."
if gcloud run services list --format="value(name)" &> /dev/null; then
    SERVICE_COUNT=$(gcloud run services list --format="value(name)" | wc -l)
    print_result 0 "Can list Cloud Run services (found: $SERVICE_COUNT)"
else
    print_result 1 "Cannot list Cloud Run services"
fi

# Test 8: Check Cloud SQL instances
echo ""
echo "Test 8: Checking Cloud SQL instances..."
if gcloud sql instances list --format="value(name)" &> /dev/null; then
    DB_COUNT=$(gcloud sql instances list --format="value(name)" | wc -l)
    print_result 0 "Can list Cloud SQL instances (found: $DB_COUNT)"
else
    print_result 1 "Cannot list Cloud SQL instances"
fi

# Test 9: Check Container Registry images
echo ""
echo "Test 9: Checking Container Registry..."
if gcloud container images list --format="value(name)" &> /dev/null; then
    IMAGE_COUNT=$(gcloud container images list --format="value(name)" | wc -l)
    print_result 0 "Can list container images (found: $IMAGE_COUNT)"
else
    print_result 1 "Cannot list container images"
fi

# Test 10: Check Compute Engine instances
echo ""
echo "Test 10: Checking Compute Engine instances..."
if gcloud compute instances list --format="value(name)" &> /dev/null; then
    VM_COUNT=$(gcloud compute instances list --format="value(name)" | wc -l)
    print_result 0 "Can list Compute Engine instances (found: $VM_COUNT)"
else
    print_result 1 "Cannot list Compute Engine instances"
fi

# Test 11: Check VPC networks
echo ""
echo "Test 11: Checking VPC networks..."
if gcloud compute networks list --format="value(name)" &> /dev/null; then
    NET_COUNT=$(gcloud compute networks list --format="value(name)" | wc -l)
    print_result 0 "Can list VPC networks (found: $NET_COUNT)"
else
    print_result 1 "Cannot list VPC networks"
fi

# Test 12: Check Secret Manager
echo ""
echo "Test 12: Checking Secret Manager..."
if gcloud secrets list --format="value(name)" &> /dev/null; then
    SECRET_COUNT=$(gcloud secrets list --format="value(name)" | wc -l)
    print_result 0 "Can list secrets (found: $SECRET_COUNT)"
else
    print_result 1 "Cannot list secrets"
fi

# Test 13: Check Pub/Sub topics
echo ""
echo "Test 13: Checking Pub/Sub topics..."
if gcloud pubsub topics list --format="value(name)" &> /dev/null; then
    TOPIC_COUNT=$(gcloud pubsub topics list --format="value(name)" | wc -l)
    print_result 0 "Can list Pub/Sub topics (found: $TOPIC_COUNT)"
else
    print_result 1 "Cannot list Pub/Sub topics"
fi

# Test 14: Check Cloud Scheduler jobs
echo ""
echo "Test 14: Checking Cloud Scheduler jobs..."
if gcloud scheduler jobs list --format="value(name)" &> /dev/null; then
    JOB_COUNT=$(gcloud scheduler jobs list --format="value(name)" | wc -l)
    print_result 0 "Can list Cloud Scheduler jobs (found: $JOB_COUNT)"
else
    print_result 1 "Cannot list Cloud Scheduler jobs"
fi

# Test 15: Check Docker installation
echo ""
echo "Test 15: Checking Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
    print_result 0 "Docker is installed (version: $DOCKER_VERSION)"
else
    print_result 1 "Docker is not installed"
fi

# Test 16: Check Docker daemon
echo ""
echo "Test 16: Checking Docker daemon..."
if docker info &> /dev/null; then
    print_result 0 "Docker daemon is running"
else
    print_result 1 "Docker daemon is not running"
fi

# Test 17: Check Docker authentication to GCR
echo ""
echo "Test 17: Checking Docker authentication to GCR..."
if gcloud auth configure-docker --quiet &> /dev/null; then
    print_result 0 "Docker is configured for GCR"
else
    print_result 1 "Docker is not configured for GCR"
fi

# Test 18: Check network connectivity to GCP
echo ""
echo "Test 18: Checking network connectivity to GCP..."
if curl -s --max-time 5 https://cloud.google.com &> /dev/null; then
    print_result 0 "Can connect to GCP"
else
    print_result 1 "Cannot connect to GCP"
fi

# Test 19: Check available regions
echo ""
echo "Test 19: Checking available regions..."
if gcloud compute regions list --format="value(name)" &> /dev/null; then
    REGION_COUNT=$(gcloud compute regions list --format="value(name)" | wc -l)
    print_result 0 "Can list available regions (found: $REGION_COUNT)"
else
    print_result 1 "Cannot list available regions"
fi

# Test 20: Check billing account
echo ""
echo "Test 20: Checking billing account..."
if gcloud beta billing accounts list --format="value(name)" &> /dev/null; then
    BILLING_COUNT=$(gcloud beta billing accounts list --format="value(name)" | wc -l)
    if [ $BILLING_COUNT -gt 0 ]; then
        print_result 0 "Billing account is configured"
    else
        print_result 1 "No billing account found"
    fi
else
    print_result 1 "Cannot check billing accounts"
fi

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! GCP environment is ready.${NC}"
    exit 0
else
    echo -e "${YELLOW}Some tests failed. Please review the output above.${NC}"
    exit 1
fi
