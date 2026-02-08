#!/bin/bash

# Azure CLI Verification Script
# Tests Azure CLI installation and basic functionality

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
echo "Azure CLI Verification"
echo "=========================================="
echo ""

# Test 1: Check if Azure CLI is installed
echo "Test 1: Checking Azure CLI installation..."
if command -v az &> /dev/null; then
    AZ_VERSION=$(az version --output tsv --query '"azure-cli"')
    print_result 0 "Azure CLI is installed (version: $AZ_VERSION)"
else
    print_result 1 "Azure CLI is not installed"
    echo "Install: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
fi

# Test 2: Check if logged in
echo ""
echo "Test 2: Checking Azure login status..."
if az account show &> /dev/null; then
    ACCOUNT=$(az account show --query name -o tsv)
    print_result 0 "Logged in to Azure (account: $ACCOUNT)"
else
    print_result 1 "Not logged in to Azure"
    echo "Login: az login"
fi

# Test 3: Check subscription
echo ""
echo "Test 3: Checking Azure subscription..."
if SUBSCRIPTION=$(az account show --query name -o tsv 2>/dev/null); then
    print_result 0 "Active subscription: $SUBSCRIPTION"
else
    print_result 1 "No active subscription"
fi

# Test 4: Check resource groups
echo ""
echo "Test 4: Listing resource groups..."
if az group list --output table &> /dev/null; then
    RG_COUNT=$(az group list --query "length([])" -o tsv)
    print_result 0 "Can list resource groups (found: $RG_COUNT)"
else
    print_result 1 "Cannot list resource groups"
fi

# Test 5: Check Container Apps extension
echo ""
echo "Test 5: Checking Container Apps extension..."
if az extension show --name containerapp &> /dev/null; then
    print_result 0 "Container Apps extension is installed"
else
    print_result 1 "Container Apps extension is not installed"
    echo "Install: az extension add --name containerapp --upgrade"
fi

# Test 6: Check Azure Container Registry access
echo ""
echo "Test 6: Checking ACR access..."
if az acr list --output table &> /dev/null; then
    ACR_COUNT=$(az acr list --query "length([])" -o tsv)
    print_result 0 "Can list container registries (found: $ACR_COUNT)"
else
    print_result 1 "Cannot list container registries"
fi

# Test 7: Check App Service plans
echo ""
echo "Test 7: Checking App Service plans..."
if az appservice plan list --output table &> /dev/null; then
    PLAN_COUNT=$(az appservice plan list --query "length([])" -o tsv)
    print_result 0 "Can list App Service plans (found: $PLAN_COUNT)"
else
    print_result 1 "Cannot list App Service plans"
fi

# Test 8: Check PostgreSQL servers
echo ""
echo "Test 8: Checking PostgreSQL servers..."
if az postgres flexible-server list --output table &> /dev/null; then
    DB_COUNT=$(az postgres flexible-server list --query "length([])" -o tsv)
    print_result 0 "Can list PostgreSQL servers (found: $DB_COUNT)"
else
    print_result 1 "Cannot list PostgreSQL servers"
fi

# Test 9: Check Key Vault access
echo ""
echo "Test 9: Checking Key Vault access..."
if az keyvault list --output table &> /dev/null; then
    KV_COUNT=$(az keyvault list --query "length([])" -o tsv)
    print_result 0 "Can list Key Vaults (found: $KV_COUNT)"
else
    print_result 1 "Cannot list Key Vaults"
fi

# Test 10: Check Container Apps environments
echo ""
echo "Test 10: Checking Container Apps environments..."
if az containerapp env list --output table &> /dev/null; then
    ENV_COUNT=$(az containerapp env list --query "length([])" -o tsv)
    print_result 0 "Can list Container Apps environments (found: $ENV_COUNT)"
else
    print_result 1 "Cannot list Container Apps environments"
fi

# Test 11: Check available locations
echo ""
echo "Test 11: Checking available locations..."
if az account list-locations --output table &> /dev/null; then
    print_result 0 "Can list available locations"
else
    print_result 1 "Cannot list available locations"
fi

# Test 12: Check Docker installation (for building images)
echo ""
echo "Test 12: Checking Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
    print_result 0 "Docker is installed (version: $DOCKER_VERSION)"
else
    print_result 1 "Docker is not installed"
fi

# Test 13: Check if Docker daemon is running
echo ""
echo "Test 13: Checking Docker daemon..."
if docker info &> /dev/null; then
    print_result 0 "Docker daemon is running"
else
    print_result 1 "Docker daemon is not running"
fi

# Test 14: Check Azure CLI configuration
echo ""
echo "Test 14: Checking Azure CLI configuration..."
if az configure --list-defaults &> /dev/null; then
    print_result 0 "Azure CLI is configured"
else
    print_result 1 "Azure CLI configuration issue"
fi

# Test 15: Check network connectivity to Azure
echo ""
echo "Test 15: Checking network connectivity to Azure..."
if curl -s --max-time 5 https://management.azure.com &> /dev/null; then
    print_result 0 "Can connect to Azure management endpoint"
else
    print_result 1 "Cannot connect to Azure management endpoint"
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
    echo -e "${GREEN}All tests passed! Azure environment is ready.${NC}"
    exit 0
else
    echo -e "${YELLOW}Some tests failed. Please review the output above.${NC}"
    exit 1
fi
