#!/bin/bash

# ==============================================================================
# Kubernetes Secrets Creation Script for Todo Chatbot
# ==============================================================================
# This script creates the todo-secrets Kubernetes Secret with sensitive data.
# IMPORTANT: Do NOT commit secrets to Git. This file is for reference only.
# ==============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="todo-app"
SECRET_NAME="todo-secrets"

echo -e "${GREEN}=============================================================================${NC}"
echo -e "${GREEN}Kubernetes Secrets Creation for Todo Chatbot${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""

# Check if required environment variables are set
if [[ -z "$DATABASE_URL" ]]; then
    echo -e "${RED}ERROR: DATABASE_URL environment variable is not set${NC}"
    echo "Please set it before running this script:"
    echo -e "${YELLOW}export DATABASE_URL=\"postgresql+asyncpg://user:password@ep-xxx.aws.neon.tech/neondb?sslmode=require\"${NC}"
    exit 1
fi

if [[ -z "$JWT_SECRET" ]]; then
    echo -e "${RED}ERROR: JWT_SECRET environment variable is not set${NC}"
    echo "Please set it before running this script:"
    echo -e "${YELLOW}export JWT_SECRET=\"your-super-secret-jwt-key-min-32-characters\"${NC}"
    exit 1
fi

if [[ -z "$OPENAI_API_KEY" ]]; then
    echo -e "${RED}ERROR: OPENAI_API_KEY environment variable is not set${NC}"
    echo "Please set it before running this script:"
    echo -e "${YELLOW}export OPENAI_API_KEY=\"sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\"${NC}"
    exit 1
fi

# Check if namespace exists
echo -e "${YELLOW}Checking if namespace '${NAMESPACE}' exists...${NC}"
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo -e "${RED}Namespace '${NAMESPACE}' does not exist. Creating...${NC}"
    kubectl create namespace "$NAMESPACE"
    echo -e "${GREEN}Namespace '${NAMESPACE}' created.${NC}"
else
    echo -e "${GREEN}Namespace '${NAMESPACE}' already exists.${NC}"
fi

# Check if secret already exists
echo -e "${YELLOW}Checking if secret '${SECRET_NAME}' exists in namespace '${NAMESPACE}'...${NC}"
if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
    echo -e "${YELLOW}Secret '${SECRET_NAME}' already exists. Do you want to recreate it?${NC}"
    read -p "Recreate secret? (y/N): " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deleting existing secret...${NC}"
        kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE"
    else
        echo -e "${GREEN}Keeping existing secret.${NC}"
        exit 0
    fi
fi

# Create the secret
echo -e "${YELLOW}Creating secret '${SECRET_NAME}'...${NC}"
kubectl create secret generic "$SECRET_NAME" \
  --from-literal=DATABASE_URL="$DATABASE_URL" \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  --from-literal=OPENAI_API_KEY="$OPENAI_API_KEY" \
  -n "$NAMESPACE"

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}Secret '${SECRET_NAME}' created successfully!${NC}"
    echo -e "${GREEN}============================================================================${NC}"
    echo ""
    echo "Verify secret:"
    echo -e "${YELLOW}kubectl get secret ${SECRET_NAME} -n ${NAMESPACE}${NC}"
    echo ""
    echo "View secret data (base64 encoded):"
    echo -e "${YELLOW}kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o yaml${NC}"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Run 'helm install todo charts/todo-chatbot/ -n todo-app'"
    echo "2. Verify pods are running: 'kubectl get pods -n todo-app'"
    echo "3. Access application via: 'minikube service frontend-service -n todo-app --url'"
else
    echo -e "${RED}ERROR: Failed to create secret${NC}"
    exit 1
fi
