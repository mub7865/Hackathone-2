#!/bin/bash
# Verification Script for Docker Setup
# This script verifies that Docker is properly installed and configured

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
echo "Docker Setup Verification"
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

# Test 1: Check Docker is installed
echo "Test 1: Checking Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    print_result 0 "Docker installed: $DOCKER_VERSION"
else
    print_result 1 "Docker not installed"
fi

echo ""

# Test 2: Check Docker daemon is running
echo "Test 2: Checking Docker daemon..."
if docker info &> /dev/null; then
    print_result 0 "Docker daemon is running"
else
    print_result 1 "Docker daemon is not running"
fi

echo ""

# Test 3: Check Docker Compose is installed
echo "Test 3: Checking Docker Compose installation..."
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    print_result 0 "Docker Compose installed: $COMPOSE_VERSION"
elif docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    print_result 0 "Docker Compose (plugin) installed: $COMPOSE_VERSION"
else
    print_result 1 "Docker Compose not installed"
fi

echo ""

# Test 4: Check Docker permissions
echo "Test 4: Checking Docker permissions..."
if docker ps &> /dev/null; then
    print_result 0 "Current user can run Docker commands"
else
    print_result 1 "Current user cannot run Docker commands (may need sudo or docker group)"
fi

echo ""

# Test 5: Test Docker build
echo "Test 5: Testing Docker build..."
cat > /tmp/test-dockerfile <<EOF
FROM alpine:latest
RUN echo "Test build successful"
CMD ["echo", "Hello from Docker"]
EOF

if docker build -t test-image -f /tmp/test-dockerfile /tmp &> /dev/null; then
    print_result 0 "Docker build works"
    docker rmi test-image &> /dev/null
else
    print_result 1 "Docker build failed"
fi

rm -f /tmp/test-dockerfile

echo ""

# Test 6: Test Docker run
echo "Test 6: Testing Docker run..."
if docker run --rm alpine:latest echo "Test run successful" &> /dev/null; then
    print_result 0 "Docker run works"
else
    print_result 1 "Docker run failed"
fi

echo ""

# Test 7: Check Docker networks
echo "Test 7: Checking Docker networks..."
NETWORK_COUNT=$(docker network ls --format "{{.Name}}" | wc -l)
if [ "$NETWORK_COUNT" -gt 0 ]; then
    print_result 0 "Docker networks available ($NETWORK_COUNT)"
else
    print_result 1 "No Docker networks found"
fi

echo ""

# Test 8: Check Docker volumes
echo "Test 8: Checking Docker volumes..."
if docker volume ls &> /dev/null; then
    VOLUME_COUNT=$(docker volume ls --format "{{.Name}}" | wc -l)
    print_result 0 "Docker volumes accessible ($VOLUME_COUNT volumes)"
else
    print_result 1 "Cannot access Docker volumes"
fi

echo ""

# Test 9: Test Docker networking
echo "Test 9: Testing Docker networking..."
if docker run --rm alpine:latest ping -c 1 google.com &> /dev/null; then
    print_result 0 "Docker containers can access internet"
else
    print_result 1 "Docker containers cannot access internet"
fi

echo ""

# Test 10: Check Docker storage driver
echo "Test 10: Checking Docker storage driver..."
STORAGE_DRIVER=$(docker info --format '{{.Driver}}' 2>/dev/null)
if [ -n "$STORAGE_DRIVER" ]; then
    print_result 0 "Storage driver: $STORAGE_DRIVER"
else
    print_result 1 "Cannot determine storage driver"
fi

echo ""

# Test 11: Check Docker disk space
echo "Test 11: Checking Docker disk space..."
DISK_USAGE=$(docker system df --format "{{.Type}}\t{{.Size}}" 2>/dev/null)
if [ -n "$DISK_USAGE" ]; then
    print_result 0 "Docker disk usage accessible"
    echo "$DISK_USAGE"
else
    print_result 1 "Cannot check Docker disk usage"
fi

echo ""

# Test 12: Test multi-stage build
echo "Test 12: Testing multi-stage build..."
cat > /tmp/test-multistage <<EOF
FROM alpine:latest AS builder
RUN echo "Build stage"

FROM alpine:latest
COPY --from=builder /etc/os-release /tmp/
CMD ["cat", "/tmp/os-release"]
EOF

if docker build -t test-multistage -f /tmp/test-multistage /tmp &> /dev/null; then
    print_result 0 "Multi-stage builds work"
    docker rmi test-multistage &> /dev/null
else
    print_result 1 "Multi-stage builds failed"
fi

rm -f /tmp/test-multistage

echo ""

# Test 13: Test Docker Compose (if available)
echo "Test 13: Testing Docker Compose..."
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    cat > /tmp/test-compose.yml <<EOF
version: '3.8'
services:
  test:
    image: alpine:latest
    command: echo "Compose test successful"
EOF

    if docker-compose -f /tmp/test-compose.yml config &> /dev/null || docker compose -f /tmp/test-compose.yml config &> /dev/null; then
        print_result 0 "Docker Compose configuration valid"
    else
        print_result 1 "Docker Compose configuration invalid"
    fi

    rm -f /tmp/test-compose.yml
else
    echo -e "${YELLOW}⚠${NC} Docker Compose not available (skipped)"
fi

echo ""

# Test 14: Check Docker BuildKit
echo "Test 14: Checking Docker BuildKit..."
if docker buildx version &> /dev/null; then
    BUILDX_VERSION=$(docker buildx version)
    print_result 0 "Docker BuildKit available: $BUILDX_VERSION"
else
    print_result 1 "Docker BuildKit not available"
fi

echo ""

# Test 15: Check Docker system info
echo "Test 15: Checking Docker system info..."
DOCKER_INFO=$(docker info --format "Containers: {{.Containers}}, Images: {{.Images}}, Server Version: {{.ServerVersion}}" 2>/dev/null)
if [ -n "$DOCKER_INFO" ]; then
    print_result 0 "Docker system info: $DOCKER_INFO"
else
    print_result 1 "Cannot get Docker system info"
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
    echo -e "${GREEN}✓ All tests passed! Docker is ready to use.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please check the output above.${NC}"
    echo ""
    echo "Common fixes:"
    echo "1. Install Docker: https://docs.docker.com/get-docker/"
    echo "2. Start Docker daemon: sudo systemctl start docker"
    echo "3. Add user to docker group: sudo usermod -aG docker \$USER"
    echo "4. Install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi
