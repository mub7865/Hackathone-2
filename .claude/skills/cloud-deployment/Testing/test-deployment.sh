#!/bin/bash

# Cloud Deployment Testing Script
# Tests deployed applications across Azure, AWS, and GCP

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Function to test HTTP endpoint
test_http_endpoint() {
    local url=$1
    local expected_status=${2:-200}
    local description=$3

    echo "Testing: $description"
    echo "URL: $url"

    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null)

    if [ "$response" -eq "$expected_status" ]; then
        print_result 0 "$description (HTTP $response)"
    else
        print_result 1 "$description (Expected HTTP $expected_status, got $response)"
    fi
}

# Function to test HTTPS endpoint
test_https_endpoint() {
    local url=$1
    local expected_status=${2:-200}
    local description=$3

    echo "Testing: $description"
    echo "URL: $url"

    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null)

    if [ "$response" -eq "$expected_status" ]; then
        print_result 0 "$description (HTTPS $response)"
    else
        print_result 1 "$description (Expected HTTPS $expected_status, got $response)"
    fi
}

# Function to test API endpoint with JSON response
test_api_endpoint() {
    local url=$1
    local description=$2

    echo "Testing: $description"
    echo "URL: $url"

    response=$(curl -s --max-time 10 "$url" 2>/dev/null)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null)

    if [ "$http_code" -eq 200 ] && [ -n "$response" ]; then
        print_result 0 "$description (HTTP $http_code, response received)"
        echo "Response preview: ${response:0:100}..."
    else
        print_result 1 "$description (HTTP $http_code)"
    fi
}

# Function to test database connectivity
test_database() {
    local host=$1
    local port=$2
    local description=$3

    echo "Testing: $description"
    echo "Host: $host:$port"

    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
        print_result 0 "$description (Port $port is open)"
    else
        print_result 1 "$description (Cannot connect to port $port)"
    fi
}

# Function to test SSL certificate
test_ssl_certificate() {
    local domain=$1
    local description=$2

    echo "Testing: $description"
    echo "Domain: $domain"

    if echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates &>/dev/null; then
        expiry=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
        print_result 0 "$description (Valid until: $expiry)"
    else
        print_result 1 "$description (Invalid or missing certificate)"
    fi
}

echo "=========================================="
echo "Cloud Deployment Testing"
echo "=========================================="
echo ""

# Parse command line arguments
CLOUD_PROVIDER=""
APP_URL=""
API_URL=""
DB_HOST=""
DB_PORT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --provider)
            CLOUD_PROVIDER="$2"
            shift 2
            ;;
        --app-url)
            APP_URL="$2"
            shift 2
            ;;
        --api-url)
            API_URL="$2"
            shift 2
            ;;
        --db-host)
            DB_HOST="$2"
            shift 2
            ;;
        --db-port)
            DB_PORT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$CLOUD_PROVIDER" ]; then
    echo -e "${RED}Error: --provider is required (azure, aws, or gcp)${NC}"
    echo "Usage: $0 --provider <azure|aws|gcp> --app-url <url> --api-url <url> [--db-host <host> --db-port <port>]"
    exit 1
fi

if [ -z "$APP_URL" ]; then
    echo -e "${RED}Error: --app-url is required${NC}"
    exit 1
fi

echo -e "${BLUE}Testing $CLOUD_PROVIDER deployment${NC}"
echo ""

# Test 1: Frontend accessibility
echo ""
echo "Test 1: Frontend accessibility..."
test_https_endpoint "$APP_URL" 200 "Frontend is accessible"

# Test 2: Frontend loads without errors
echo ""
echo "Test 2: Frontend content..."
if curl -s --max-time 10 "$APP_URL" | grep -q "<!DOCTYPE html>"; then
    print_result 0 "Frontend returns valid HTML"
else
    print_result 1 "Frontend does not return valid HTML"
fi

# Test 3: API accessibility (if provided)
if [ -n "$API_URL" ]; then
    echo ""
    echo "Test 3: API accessibility..."
    test_https_endpoint "$API_URL/health" 200 "API health endpoint"

    echo ""
    echo "Test 4: API documentation..."
    test_https_endpoint "$API_URL/docs" 200 "API documentation (Swagger/OpenAPI)"

    echo ""
    echo "Test 5: API version endpoint..."
    test_api_endpoint "$API_URL/api/version" "API version endpoint"
fi

# Test 6: Database connectivity (if provided)
if [ -n "$DB_HOST" ] && [ -n "$DB_PORT" ]; then
    echo ""
    echo "Test 6: Database connectivity..."
    test_database "$DB_HOST" "$DB_PORT" "Database connection"
fi

# Test 7: SSL certificate
echo ""
echo "Test 7: SSL certificate..."
DOMAIN=$(echo "$APP_URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
test_ssl_certificate "$DOMAIN" "SSL certificate for $DOMAIN"

# Test 8: Response time
echo ""
echo "Test 8: Response time..."
response_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 "$APP_URL" 2>/dev/null)
response_time_ms=$(echo "$response_time * 1000" | bc)
if (( $(echo "$response_time < 2.0" | bc -l) )); then
    print_result 0 "Response time is acceptable (${response_time_ms}ms)"
else
    print_result 1 "Response time is slow (${response_time_ms}ms)"
fi

# Test 9: CORS headers (if API provided)
if [ -n "$API_URL" ]; then
    echo ""
    echo "Test 9: CORS headers..."
    cors_header=$(curl -s -I -H "Origin: https://example.com" "$API_URL/health" | grep -i "access-control-allow-origin")
    if [ -n "$cors_header" ]; then
        print_result 0 "CORS headers are configured"
    else
        print_result 1 "CORS headers are missing"
    fi
fi

# Test 10: Security headers
echo ""
echo "Test 10: Security headers..."
headers=$(curl -s -I "$APP_URL")

if echo "$headers" | grep -qi "strict-transport-security"; then
    print_result 0 "HSTS header is present"
else
    print_result 1 "HSTS header is missing"
fi

if echo "$headers" | grep -qi "x-content-type-options"; then
    print_result 0 "X-Content-Type-Options header is present"
else
    print_result 1 "X-Content-Type-Options header is missing"
fi

if echo "$headers" | grep -qi "x-frame-options"; then
    print_result 0 "X-Frame-Options header is present"
else
    print_result 1 "X-Frame-Options header is missing"
fi

# Test 11: Compression
echo ""
echo "Test 11: Compression..."
if curl -s -I -H "Accept-Encoding: gzip" "$APP_URL" | grep -qi "content-encoding: gzip"; then
    print_result 0 "Gzip compression is enabled"
else
    print_result 1 "Gzip compression is not enabled"
fi

# Test 12: Caching headers
echo ""
echo "Test 12: Caching headers..."
if curl -s -I "$APP_URL" | grep -qi "cache-control"; then
    print_result 0 "Cache-Control header is present"
else
    print_result 1 "Cache-Control header is missing"
fi

# Cloud-specific tests
case $CLOUD_PROVIDER in
    azure)
        echo ""
        echo "Azure-specific tests..."

        # Test Azure-specific headers
        if curl -s -I "$APP_URL" | grep -qi "x-azure"; then
            print_result 0 "Azure-specific headers detected"
        else
            print_result 1 "Azure-specific headers not found"
        fi
        ;;

    aws)
        echo ""
        echo "AWS-specific tests..."

        # Test AWS-specific headers
        if curl -s -I "$APP_URL" | grep -qi "x-amz"; then
            print_result 0 "AWS-specific headers detected"
        else
            print_result 1 "AWS-specific headers not found"
        fi
        ;;

    gcp)
        echo ""
        echo "GCP-specific tests..."

        # Test GCP-specific headers
        if curl -s -I "$APP_URL" | grep -qi "x-cloud-trace-context"; then
            print_result 0 "GCP-specific headers detected"
        else
            print_result 1 "GCP-specific headers not found"
        fi
        ;;
esac

# Test 13: Load test (simple)
echo ""
echo "Test 13: Simple load test (10 concurrent requests)..."
start_time=$(date +%s)
for i in {1..10}; do
    curl -s -o /dev/null "$APP_URL" &
done
wait
end_time=$(date +%s)
duration=$((end_time - start_time))

if [ $duration -lt 5 ]; then
    print_result 0 "Handled 10 concurrent requests in ${duration}s"
else
    print_result 1 "Slow response to concurrent requests (${duration}s)"
fi

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "Cloud Provider: ${BLUE}$CLOUD_PROVIDER${NC}"
echo -e "Application URL: ${BLUE}$APP_URL${NC}"
if [ -n "$API_URL" ]; then
    echo -e "API URL: ${BLUE}$API_URL${NC}"
fi
echo ""
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! Deployment is healthy.${NC}"
    exit 0
else
    echo -e "${YELLOW}Some tests failed. Please review the output above.${NC}"
    exit 1
fi
