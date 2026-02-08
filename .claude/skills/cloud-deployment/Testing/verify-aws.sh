#!/bin/bash

# AWS CLI Verification Script
# Tests AWS CLI installation and basic functionality

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
echo "AWS CLI Verification"
echo "=========================================="
echo ""

# Test 1: Check if AWS CLI is installed
echo "Test 1: Checking AWS CLI installation..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version | cut -d ' ' -f1 | cut -d '/' -f2)
    print_result 0 "AWS CLI is installed (version: $AWS_VERSION)"
else
    print_result 1 "AWS CLI is not installed"
    echo "Install: curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip' && unzip awscliv2.zip && sudo ./aws/install"
fi

# Test 2: Check if AWS credentials are configured
echo ""
echo "Test 2: Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    print_result 0 "AWS credentials are configured (Account: $ACCOUNT_ID)"
else
    print_result 1 "AWS credentials are not configured"
    echo "Configure: aws configure"
fi

# Test 3: Check default region
echo ""
echo "Test 3: Checking default region..."
if REGION=$(aws configure get region 2>/dev/null); then
    print_result 0 "Default region is set: $REGION"
else
    print_result 1 "Default region is not set"
    echo "Set region: aws configure set region us-east-1"
fi

# Test 4: Check VPC access
echo ""
echo "Test 4: Checking VPC access..."
if aws ec2 describe-vpcs --output table &> /dev/null; then
    VPC_COUNT=$(aws ec2 describe-vpcs --query "length(Vpcs)" --output text)
    print_result 0 "Can list VPCs (found: $VPC_COUNT)"
else
    print_result 1 "Cannot list VPCs"
fi

# Test 5: Check ECS clusters
echo ""
echo "Test 5: Checking ECS clusters..."
if aws ecs list-clusters --output table &> /dev/null; then
    CLUSTER_COUNT=$(aws ecs list-clusters --query "length(clusterArns)" --output text)
    print_result 0 "Can list ECS clusters (found: $CLUSTER_COUNT)"
else
    print_result 1 "Cannot list ECS clusters"
fi

# Test 6: Check ECR repositories
echo ""
echo "Test 6: Checking ECR repositories..."
if aws ecr describe-repositories --output table &> /dev/null; then
    REPO_COUNT=$(aws ecr describe-repositories --query "length(repositories)" --output text)
    print_result 0 "Can list ECR repositories (found: $REPO_COUNT)"
else
    print_result 1 "Cannot list ECR repositories"
fi

# Test 7: Check RDS instances
echo ""
echo "Test 7: Checking RDS instances..."
if aws rds describe-db-instances --output table &> /dev/null; then
    DB_COUNT=$(aws rds describe-db-instances --query "length(DBInstances)" --output text)
    print_result 0 "Can list RDS instances (found: $DB_COUNT)"
else
    print_result 1 "Cannot list RDS instances"
fi

# Test 8: Check ElastiCache clusters
echo ""
echo "Test 8: Checking ElastiCache clusters..."
if aws elasticache describe-cache-clusters --output table &> /dev/null; then
    CACHE_COUNT=$(aws elasticache describe-cache-clusters --query "length(CacheClusters)" --output text)
    print_result 0 "Can list ElastiCache clusters (found: $CACHE_COUNT)"
else
    print_result 1 "Cannot list ElastiCache clusters"
fi

# Test 9: Check Lambda functions
echo ""
echo "Test 9: Checking Lambda functions..."
if aws lambda list-functions --output table &> /dev/null; then
    LAMBDA_COUNT=$(aws lambda list-functions --query "length(Functions)" --output text)
    print_result 0 "Can list Lambda functions (found: $LAMBDA_COUNT)"
else
    print_result 1 "Cannot list Lambda functions"
fi

# Test 10: Check Secrets Manager
echo ""
echo "Test 10: Checking Secrets Manager..."
if aws secretsmanager list-secrets --output table &> /dev/null; then
    SECRET_COUNT=$(aws secretsmanager list-secrets --query "length(SecretList)" --output text)
    print_result 0 "Can list secrets (found: $SECRET_COUNT)"
else
    print_result 1 "Cannot list secrets"
fi

# Test 11: Check S3 buckets
echo ""
echo "Test 11: Checking S3 buckets..."
if aws s3 ls &> /dev/null; then
    BUCKET_COUNT=$(aws s3 ls | wc -l)
    print_result 0 "Can list S3 buckets (found: $BUCKET_COUNT)"
else
    print_result 1 "Cannot list S3 buckets"
fi

# Test 12: Check IAM roles
echo ""
echo "Test 12: Checking IAM roles..."
if aws iam list-roles --output table &> /dev/null; then
    ROLE_COUNT=$(aws iam list-roles --query "length(Roles)" --output text)
    print_result 0 "Can list IAM roles (found: $ROLE_COUNT)"
else
    print_result 1 "Cannot list IAM roles"
fi

# Test 13: Check CloudWatch Logs
echo ""
echo "Test 13: Checking CloudWatch Logs..."
if aws logs describe-log-groups --output table &> /dev/null; then
    LOG_COUNT=$(aws logs describe-log-groups --query "length(logGroups)" --output text)
    print_result 0 "Can list CloudWatch log groups (found: $LOG_COUNT)"
else
    print_result 1 "Cannot list CloudWatch log groups"
fi

# Test 14: Check Docker installation
echo ""
echo "Test 14: Checking Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
    print_result 0 "Docker is installed (version: $DOCKER_VERSION)"
else
    print_result 1 "Docker is not installed"
fi

# Test 15: Check Docker daemon
echo ""
echo "Test 15: Checking Docker daemon..."
if docker info &> /dev/null; then
    print_result 0 "Docker daemon is running"
else
    print_result 1 "Docker daemon is not running"
fi

# Test 16: Check network connectivity to AWS
echo ""
echo "Test 16: Checking network connectivity to AWS..."
if curl -s --max-time 5 https://aws.amazon.com &> /dev/null; then
    print_result 0 "Can connect to AWS"
else
    print_result 1 "Cannot connect to AWS"
fi

# Test 17: Check available regions
echo ""
echo "Test 17: Checking available regions..."
if aws ec2 describe-regions --output table &> /dev/null; then
    REGION_COUNT=$(aws ec2 describe-regions --query "length(Regions)" --output text)
    print_result 0 "Can list available regions (found: $REGION_COUNT)"
else
    print_result 1 "Cannot list available regions"
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
    echo -e "${GREEN}All tests passed! AWS environment is ready.${NC}"
    exit 0
else
    echo -e "${YELLOW}Some tests failed. Please review the output above.${NC}"
    exit 1
fi
