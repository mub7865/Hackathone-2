#!/bin/bash
# Dapr Setup Verification Script
# This script verifies that Dapr is properly installed and configured

set -e

echo "🔍 Dapr Setup Verification"
echo "=========================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track overall status
ALL_CHECKS_PASSED=true

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
    ALL_CHECKS_PASSED=false
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check 1: Dapr CLI installed
echo "1️⃣  Checking Dapr CLI installation..."
if command -v dapr &> /dev/null; then
    DAPR_VERSION=$(dapr --version | grep "CLI version" | awk '{print $3}')
    print_success "Dapr CLI installed (version: $DAPR_VERSION)"
else
    print_error "Dapr CLI not found. Install with: wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash"
fi
echo ""

# Check 2: Dapr runtime initialized
echo "2️⃣  Checking Dapr runtime initialization..."
if docker ps | grep -q "dapr_redis\|dapr_zipkin\|dapr_placement"; then
    print_success "Dapr runtime containers are running"

    # Check individual containers
    if docker ps | grep -q "dapr_redis"; then
        print_success "  - Redis container running"
    else
        print_warning "  - Redis container not running"
    fi

    if docker ps | grep -q "dapr_zipkin"; then
        print_success "  - Zipkin container running"
    else
        print_warning "  - Zipkin container not running"
    fi

    if docker ps | grep -q "dapr_placement"; then
        print_success "  - Placement service running"
    else
        print_warning "  - Placement service not running"
    fi
else
    print_error "Dapr runtime not initialized. Run: dapr init"
fi
echo ""

# Check 3: Redis connectivity
echo "3️⃣  Checking Redis connectivity..."
if command -v redis-cli &> /dev/null; then
    if redis-cli -h localhost -p 6379 ping &> /dev/null; then
        print_success "Redis is reachable at localhost:6379"
    else
        print_error "Cannot connect to Redis at localhost:6379"
    fi
else
    print_warning "redis-cli not installed. Install with: brew install redis (macOS) or apt-get install redis-tools (Linux)"
fi
echo ""

# Check 4: Dapr components directory
echo "4️⃣  Checking Dapr components..."
if [ -d "./components" ]; then
    print_success "Components directory exists"

    # Check for common components
    if [ -f "./components/pubsub.yaml" ]; then
        print_success "  - pubsub.yaml found"
    else
        print_warning "  - pubsub.yaml not found"
    fi

    if [ -f "./components/statestore.yaml" ]; then
        print_success "  - statestore.yaml found"
    else
        print_warning "  - statestore.yaml not found"
    fi
else
    print_warning "Components directory not found. Create with: mkdir components"
fi
echo ""

# Check 5: Python dependencies
echo "5️⃣  Checking Python dependencies..."
if command -v python3 &> /dev/null; then
    print_success "Python 3 installed"

    # Check for Dapr SDK
    if python3 -c "import dapr" 2>/dev/null; then
        print_success "  - dapr package installed"
    else
        print_warning "  - dapr package not installed. Install with: pip install dapr"
    fi

    # Check for FastAPI extension
    if python3 -c "import dapr.ext.fastapi" 2>/dev/null; then
        print_success "  - dapr-ext-fastapi package installed"
    else
        print_warning "  - dapr-ext-fastapi not installed. Install with: pip install dapr-ext-fastapi"
    fi

    # Check for FastAPI
    if python3 -c "import fastapi" 2>/dev/null; then
        print_success "  - fastapi package installed"
    else
        print_warning "  - fastapi not installed. Install with: pip install fastapi"
    fi
else
    print_error "Python 3 not found"
fi
echo ""

# Check 6: Test Dapr pub/sub
echo "6️⃣  Testing Dapr pub/sub..."
python3 << 'EOF'
import sys
try:
    from dapr.clients import DaprClient
    import json

    # Try to publish a test event
    with DaprClient() as client:
        client.publish_event(
            pubsub_name='pubsub',
            topic_name='test-verification',
            data=json.dumps({'test': 'verification'}),
            data_content_type='application/json'
        )
    print("✅ Pub/sub test successful")
    sys.exit(0)
except Exception as e:
    print(f"❌ Pub/sub test failed: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    print_success "Pub/sub is working"
else
    print_error "Pub/sub test failed"
fi
echo ""

# Check 7: Test Dapr state store
echo "7️⃣  Testing Dapr state store..."
python3 << 'EOF'
import sys
try:
    from dapr.clients import DaprClient

    # Try to save and get state
    with DaprClient() as client:
        # Save state
        client.save_state(
            store_name='statestore',
            key='test-verification',
            value='test-value'
        )

        # Get state
        state = client.get_state(
            store_name='statestore',
            key='test-verification'
        )

        if state.data and state.data.decode('utf-8') == 'test-value':
            print("✅ State store test successful")

            # Cleanup
            client.delete_state(
                store_name='statestore',
                key='test-verification'
            )
            sys.exit(0)
        else:
            print("❌ State store test failed: value mismatch")
            sys.exit(1)
except Exception as e:
    print(f"❌ State store test failed: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    print_success "State store is working"
else
    print_error "State store test failed"
fi
echo ""

# Check 8: Dapr dashboard
echo "8️⃣  Checking Dapr dashboard..."
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    print_success "Dapr dashboard is accessible at http://localhost:8080"
else
    print_warning "Dapr dashboard not running. Start with: dapr dashboard"
fi
echo ""

# Check 9: Zipkin tracing
echo "9️⃣  Checking Zipkin tracing..."
if curl -s http://localhost:9411 > /dev/null 2>&1; then
    print_success "Zipkin is accessible at http://localhost:9411"
else
    print_warning "Zipkin not accessible. Check if dapr_zipkin container is running"
fi
echo ""

# Summary
echo "=========================="
echo "Summary"
echo "=========================="
if [ "$ALL_CHECKS_PASSED" = true ]; then
    echo -e "${GREEN}✅ All critical checks passed!${NC}"
    echo ""
    echo "Your Dapr setup is ready to use! 🎉"
    echo ""
    echo "Next steps:"
    echo "  1. Create your FastAPI app"
    echo "  2. Run with: dapr run --app-id myapp --app-port 8000 --components-path ./components -- uvicorn main:app --port 8000"
    echo "  3. Test your endpoints"
    exit 0
else
    echo -e "${RED}❌ Some checks failed${NC}"
    echo ""
    echo "Please fix the issues above before proceeding."
    echo ""
    echo "Common fixes:"
    echo "  - Install Dapr CLI: wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash"
    echo "  - Initialize Dapr: dapr init"
    echo "  - Install Python packages: pip install dapr dapr-ext-fastapi fastapi"
    echo "  - Create components directory: mkdir components"
    exit 1
fi
