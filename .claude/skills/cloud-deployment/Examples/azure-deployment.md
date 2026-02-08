# Azure Deployment Example

Complete example of deploying a full-stack application to Azure.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Azure Cloud                          │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Resource Group: myapp-prod-rg             │ │
│  │                                                        │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │         Azure Container Apps Environment         │ │ │
│  │  │                                                  │ │ │
│  │  │  ┌────────────────┐    ┌────────────────┐      │ │ │
│  │  │  │   Frontend     │    │    Backend     │      │ │ │
│  │  │  │  (Next.js)     │◄───┤   (FastAPI)    │      │ │ │
│  │  │  │  Port: 3000    │    │   Port: 8000   │      │ │ │
│  │  │  └────────────────┘    └────────────────┘      │ │ │
│  │  │                              │                  │ │ │
│  │  └──────────────────────────────┼──────────────────┘ │ │
│  │                                 │                    │ │
│  │  ┌──────────────────────────────▼──────────────────┐ │ │
│  │  │      Azure Database for PostgreSQL              │ │ │
│  │  │      (Flexible Server)                          │ │ │
│  │  └─────────────────────────────────────────────────┘ │ │
│  │                                                        │ │
│  │  ┌─────────────────────────────────────────────────┐ │ │
│  │  │      Azure Container Registry (ACR)             │ │ │
│  │  │      myappregistry.azurecr.io                   │ │ │
│  │  └─────────────────────────────────────────────────┘ │ │
│  │                                                        │ │
│  │  ┌─────────────────────────────────────────────────┐ │ │
│  │  │      Azure Key Vault                            │ │ │
│  │  │      (Secrets Management)                       │ │ │
│  │  └─────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Set subscription
az account set --subscription "My Subscription"

# Install Azure Container Apps extension
az extension add --name containerapp --upgrade
```

## Step 1: Create Resource Group

```bash
# Create resource group
az group create \
  --name myapp-prod-rg \
  --location eastus

# Verify
az group show --name myapp-prod-rg
```

## Step 2: Create Azure Container Registry

```bash
# Create ACR
az acr create \
  --resource-group myapp-prod-rg \
  --name myappregistry \
  --sku Basic \
  --admin-enabled true

# Get ACR credentials
az acr credential show --name myappregistry

# Login to ACR
az acr login --name myappregistry
```

## Step 3: Build and Push Docker Images

```bash
# Build backend image
docker build -t myappregistry.azurecr.io/backend:v1.0.0 ./backend

# Build frontend image
docker build -t myappregistry.azurecr.io/frontend:v1.0.0 ./frontend

# Push images
docker push myappregistry.azurecr.io/backend:v1.0.0
docker push myappregistry.azurecr.io/frontend:v1.0.0

# Verify images
az acr repository list --name myappregistry --output table
```

## Step 4: Create PostgreSQL Database

```bash
# Create PostgreSQL server
az postgres flexible-server create \
  --resource-group myapp-prod-rg \
  --name myapp-prod-db \
  --location eastus \
  --admin-user dbadmin \
  --admin-password 'SecurePassword123!' \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --version 16 \
  --storage-size 32 \
  --public-access 0.0.0.0

# Create database
az postgres flexible-server db create \
  --resource-group myapp-prod-rg \
  --server-name myapp-prod-db \
  --database-name myapp

# Get connection string
az postgres flexible-server show-connection-string \
  --server-name myapp-prod-db \
  --database-name myapp \
  --admin-user dbadmin \
  --admin-password 'SecurePassword123!'
```

## Step 5: Create Key Vault

```bash
# Create Key Vault
az keyvault create \
  --name myapp-prod-kv \
  --resource-group myapp-prod-rg \
  --location eastus

# Store database password
az keyvault secret set \
  --vault-name myapp-prod-kv \
  --name database-password \
  --value 'SecurePassword123!'

# Store JWT secret
az keyvault secret set \
  --vault-name myapp-prod-kv \
  --name jwt-secret \
  --value 'your-jwt-secret-key'
```

## Step 6: Create Container Apps Environment

```bash
# Create Container Apps environment
az containerapp env create \
  --name myapp-prod-env \
  --resource-group myapp-prod-rg \
  --location eastus

# Verify
az containerapp env show \
  --name myapp-prod-env \
  --resource-group myapp-prod-rg
```

## Step 7: Deploy Backend Container App

```bash
# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name myappregistry --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name myappregistry --query passwords[0].value -o tsv)

# Deploy backend
az containerapp create \
  --name myapp-backend \
  --resource-group myapp-prod-rg \
  --environment myapp-prod-env \
  --image myappregistry.azurecr.io/backend:v1.0.0 \
  --registry-server myappregistry.azurecr.io \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --target-port 8000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 10 \
  --cpu 0.5 \
  --memory 1.0Gi \
  --env-vars \
    DATABASE_URL=secretref:database-url \
    JWT_SECRET=secretref:jwt-secret \
    ENVIRONMENT=production \
  --secrets \
    database-url="postgresql://dbadmin:SecurePassword123!@myapp-prod-db.postgres.database.azure.com:5432/myapp" \
    jwt-secret="your-jwt-secret-key"

# Get backend URL
BACKEND_URL=$(az containerapp show \
  --name myapp-backend \
  --resource-group myapp-prod-rg \
  --query properties.configuration.ingress.fqdn -o tsv)

echo "Backend URL: https://$BACKEND_URL"
```

## Step 8: Deploy Frontend Container App

```bash
# Deploy frontend
az containerapp create \
  --name myapp-frontend \
  --resource-group myapp-prod-rg \
  --environment myapp-prod-env \
  --image myappregistry.azurecr.io/frontend:v1.0.0 \
  --registry-server myappregistry.azurecr.io \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --target-port 3000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 10 \
  --cpu 0.5 \
  --memory 1.0Gi \
  --env-vars \
    NEXT_PUBLIC_API_URL="https://$BACKEND_URL" \
    ENVIRONMENT=production

# Get frontend URL
FRONTEND_URL=$(az containerapp show \
  --name myapp-frontend \
  --resource-group myapp-prod-rg \
  --query properties.configuration.ingress.fqdn -o tsv)

echo "Frontend URL: https://$FRONTEND_URL"
```

## Step 9: Configure Custom Domain (Optional)

```bash
# Add custom domain to frontend
az containerapp hostname add \
  --name myapp-frontend \
  --resource-group myapp-prod-rg \
  --hostname myapp.example.com

# Bind certificate
az containerapp hostname bind \
  --name myapp-frontend \
  --resource-group myapp-prod-rg \
  --hostname myapp.example.com \
  --environment myapp-prod-env \
  --validation-method CNAME
```

## Step 10: Enable Monitoring

```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
  --resource-group myapp-prod-rg \
  --workspace-name myapp-prod-logs

# Get workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group myapp-prod-rg \
  --workspace-name myapp-prod-logs \
  --query customerId -o tsv)

# Enable Container Apps monitoring
az containerapp env update \
  --name myapp-prod-env \
  --resource-group myapp-prod-rg \
  --logs-workspace-id $WORKSPACE_ID
```

## Step 11: Update Application

```bash
# Build new version
docker build -t myappregistry.azurecr.io/backend:v1.1.0 ./backend
docker push myappregistry.azurecr.io/backend:v1.1.0

# Update backend
az containerapp update \
  --name myapp-backend \
  --resource-group myapp-prod-rg \
  --image myappregistry.azurecr.io/backend:v1.1.0

# Check revision status
az containerapp revision list \
  --name myapp-backend \
  --resource-group myapp-prod-rg \
  --output table
```

## Step 12: Scale Application

```bash
# Manual scaling
az containerapp update \
  --name myapp-backend \
  --resource-group myapp-prod-rg \
  --min-replicas 2 \
  --max-replicas 20

# Configure autoscaling rules
az containerapp update \
  --name myapp-backend \
  --resource-group myapp-prod-rg \
  --scale-rule-name http-rule \
  --scale-rule-type http \
  --scale-rule-http-concurrency 100
```

## Monitoring and Logs

```bash
# View logs
az containerapp logs show \
  --name myapp-backend \
  --resource-group myapp-prod-rg \
  --follow

# View metrics
az monitor metrics list \
  --resource /subscriptions/{subscription-id}/resourceGroups/myapp-prod-rg/providers/Microsoft.App/containerApps/myapp-backend \
  --metric Requests

# View revisions
az containerapp revision list \
  --name myapp-backend \
  --resource-group myapp-prod-rg \
  --output table
```

## Cleanup

```bash
# Delete resource group (deletes all resources)
az group delete --name myapp-prod-rg --yes --no-wait
```

## Cost Estimation

**Monthly costs (approximate):**
- Container Apps (2 apps, 1-10 replicas): $50-200
- PostgreSQL Flexible Server (Standard_B1ms): $15
- Container Registry (Basic): $5
- Key Vault: $0.03 per 10,000 operations
- Log Analytics: $2.30 per GB ingested

**Total: ~$75-220/month** (varies with traffic)

## Best Practices

1. **Use managed identities** instead of storing credentials
2. **Enable HTTPS** for all ingress
3. **Use Key Vault** for secrets management
4. **Enable monitoring** with Log Analytics
5. **Configure autoscaling** based on metrics
6. **Use revision management** for zero-downtime deployments
7. **Set up alerts** for critical metrics
8. **Regular backups** of PostgreSQL database
9. **Use private endpoints** for database access
10. **Implement CI/CD** with GitHub Actions or Azure DevOps
