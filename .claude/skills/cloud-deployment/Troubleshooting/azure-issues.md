# Azure Deployment Troubleshooting

Common issues and solutions when deploying to Azure.

## Table of Contents

1. [Container Apps Issues](#container-apps-issues)
2. [App Service Issues](#app-service-issues)
3. [Database Issues](#database-issues)
4. [Networking Issues](#networking-issues)
5. [Authentication Issues](#authentication-issues)

---

## Container Apps Issues

### Issue 1: Container App Fails to Start

**Symptoms:**
- Container app shows "Provisioning" status indefinitely
- Revision fails to activate
- Application not accessible

**Diagnosis:**

```bash
# Check container app status
az containerapp show \
  --name myapp \
  --resource-group myapp-rg \
  --query properties.provisioningState

# Check revision status
az containerapp revision list \
  --name myapp \
  --resource-group myapp-rg \
  --output table

# View logs
az containerapp logs show \
  --name myapp \
  --resource-group myapp-rg \
  --follow
```

**Common Causes and Solutions:**

#### Cause 1: Image Pull Failure

**Solution:** Check ACR credentials and permissions

```bash
# Verify ACR credentials
az acr credential show --name myregistry

# Grant Container App access to ACR
az containerapp registry set \
  --name myapp \
  --resource-group myapp-rg \
  --server myregistry.azurecr.io \
  --username $(az acr credential show --name myregistry --query username -o tsv) \
  --password $(az acr credential show --name myregistry --query passwords[0].value -o tsv)
```

#### Cause 2: Application Crash on Startup

**Solution:** Check application logs and environment variables

```bash
# View detailed logs
az containerapp logs show \
  --name myapp \
  --resource-group myapp-rg \
  --tail 100

# Verify environment variables
az containerapp show \
  --name myapp \
  --resource-group myapp-rg \
  --query properties.template.containers[0].env
```

#### Cause 3: Port Mismatch

**Solution:** Ensure target port matches application port

```bash
# Update target port
az containerapp update \
  --name myapp \
  --resource-group myapp-rg \
  --target-port 8000
```

---

### Issue 2: Container App High Latency

**Symptoms:**
- Slow response times
- Timeouts
- Poor performance

**Diagnosis:**

```bash
# Check replica count
az containerapp show \
  --name myapp \
  --resource-group myapp-rg \
  --query properties.template.scale

# Check resource allocation
az containerapp show \
  --name myapp \
  --resource-group myapp-rg \
  --query properties.template.containers[0].resources
```

**Solutions:**

#### Solution 1: Increase Resources

```bash
# Increase CPU and memory
az containerapp update \
  --name myapp \
  --resource-group myapp-rg \
  --cpu 1.0 \
  --memory 2.0Gi
```

#### Solution 2: Increase Min Replicas

```bash
# Set minimum replicas to avoid cold starts
az containerapp update \
  --name myapp \
  --resource-group myapp-rg \
  --min-replicas 2 \
  --max-replicas 10
```

#### Solution 3: Enable Session Affinity

```bash
# Enable sticky sessions
az containerapp ingress sticky-sessions set \
  --name myapp \
  --resource-group myapp-rg \
  --affinity sticky
```

---

## App Service Issues

### Issue 1: App Service Deployment Fails

**Symptoms:**
- Deployment fails with error
- Application not updating
- Old version still running

**Diagnosis:**

```bash
# Check deployment status
az webapp deployment list-publishing-profiles \
  --name myapp \
  --resource-group myapp-rg

# View deployment logs
az webapp log tail \
  --name myapp \
  --resource-group myapp-rg
```

**Solutions:**

#### Solution 1: Check Deployment Credentials

```bash
# Reset deployment credentials
az webapp deployment user set \
  --user-name myuser \
  --password MyPassword123!

# Get publishing profile
az webapp deployment list-publishing-profiles \
  --name myapp \
  --resource-group myapp-rg \
  --xml
```

#### Solution 2: Restart App Service

```bash
# Restart app
az webapp restart \
  --name myapp \
  --resource-group myapp-rg

# Check status
az webapp show \
  --name myapp \
  --resource-group myapp-rg \
  --query state
```

---

### Issue 2: App Service Out of Memory

**Symptoms:**
- Application crashes
- 502/503 errors
- High memory usage

**Diagnosis:**

```bash
# Check metrics
az monitor metrics list \
  --resource /subscriptions/{subscription-id}/resourceGroups/myapp-rg/providers/Microsoft.Web/sites/myapp \
  --metric MemoryPercentage \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z

# Check current plan
az appservice plan show \
  --name myapp-plan \
  --resource-group myapp-rg \
  --query sku
```

**Solutions:**

#### Solution 1: Scale Up

```bash
# Upgrade to higher tier
az appservice plan update \
  --name myapp-plan \
  --resource-group myapp-rg \
  --sku P1v2
```

#### Solution 2: Scale Out

```bash
# Add more instances
az appservice plan update \
  --name myapp-plan \
  --resource-group myapp-rg \
  --number-of-workers 3
```

---

## Database Issues

### Issue 1: Cannot Connect to PostgreSQL

**Symptoms:**
- Connection timeout
- Authentication failed
- Connection refused

**Diagnosis:**

```bash
# Check firewall rules
az postgres flexible-server firewall-rule list \
  --resource-group myapp-rg \
  --name myapp-db \
  --output table

# Check server status
az postgres flexible-server show \
  --resource-group myapp-rg \
  --name myapp-db \
  --query state
```

**Solutions:**

#### Solution 1: Add Firewall Rule

```bash
# Allow Azure services
az postgres flexible-server firewall-rule create \
  --resource-group myapp-rg \
  --name myapp-db \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Allow specific IP
az postgres flexible-server firewall-rule create \
  --resource-group myapp-rg \
  --name myapp-db \
  --rule-name AllowMyIP \
  --start-ip-address 1.2.3.4 \
  --end-ip-address 1.2.3.4
```

#### Solution 2: Check Connection String

```bash
# Get connection string
az postgres flexible-server show-connection-string \
  --server-name myapp-db \
  --database-name myapp \
  --admin-user dbadmin
```

---

### Issue 2: Database Performance Issues

**Symptoms:**
- Slow queries
- High CPU usage
- Connection pool exhaustion

**Diagnosis:**

```bash
# Check metrics
az monitor metrics list \
  --resource /subscriptions/{subscription-id}/resourceGroups/myapp-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/myapp-db \
  --metric cpu_percent \
  --start-time 2024-01-01T00:00:00Z

# Check server parameters
az postgres flexible-server parameter list \
  --resource-group myapp-rg \
  --server-name myapp-db \
  --output table
```

**Solutions:**

#### Solution 1: Scale Up Database

```bash
# Upgrade to higher tier
az postgres flexible-server update \
  --resource-group myapp-rg \
  --name myapp-db \
  --sku-name Standard_D2s_v3
```

#### Solution 2: Optimize Connection Pool

```bash
# Update max connections
az postgres flexible-server parameter set \
  --resource-group myapp-rg \
  --server-name myapp-db \
  --name max_connections \
  --value 200
```

---

## Networking Issues

### Issue 1: Cannot Access Application

**Symptoms:**
- 404 errors
- DNS resolution fails
- Connection timeout

**Diagnosis:**

```bash
# Check ingress configuration
az containerapp ingress show \
  --name myapp \
  --resource-group myapp-rg

# Test DNS resolution
nslookup myapp.azurecontainerapps.io

# Test connectivity
curl -v https://myapp.azurecontainerapps.io
```

**Solutions:**

#### Solution 1: Enable External Ingress

```bash
# Enable external ingress
az containerapp ingress enable \
  --name myapp \
  --resource-group myapp-rg \
  --type external \
  --target-port 8000 \
  --transport auto
```

#### Solution 2: Check Custom Domain

```bash
# Verify custom domain
az containerapp hostname list \
  --name myapp \
  --resource-group myapp-rg

# Add custom domain
az containerapp hostname add \
  --name myapp \
  --resource-group myapp-rg \
  --hostname myapp.example.com
```

---

### Issue 2: CORS Errors

**Symptoms:**
- Browser console shows CORS errors
- API calls fail from frontend
- Preflight requests fail

**Solutions:**

#### Solution 1: Configure CORS in App Service

```bash
# Enable CORS
az webapp cors add \
  --name myapp \
  --resource-group myapp-rg \
  --allowed-origins https://myapp.example.com

# Allow all origins (development only)
az webapp cors add \
  --name myapp \
  --resource-group myapp-rg \
  --allowed-origins '*'
```

#### Solution 2: Configure CORS in Application

```python
# FastAPI example
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://myapp.example.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## Authentication Issues

### Issue 1: Cannot Access Key Vault Secrets

**Symptoms:**
- Application cannot read secrets
- Access denied errors
- Authentication failures

**Diagnosis:**

```bash
# Check Key Vault access policies
az keyvault show \
  --name myapp-kv \
  --resource-group myapp-rg \
  --query properties.accessPolicies

# Check managed identity
az containerapp identity show \
  --name myapp \
  --resource-group myapp-rg
```

**Solutions:**

#### Solution 1: Enable Managed Identity

```bash
# Enable system-assigned identity
az containerapp identity assign \
  --name myapp \
  --resource-group myapp-rg \
  --system-assigned

# Get principal ID
PRINCIPAL_ID=$(az containerapp identity show \
  --name myapp \
  --resource-group myapp-rg \
  --query principalId -o tsv)
```

#### Solution 2: Grant Key Vault Access

```bash
# Grant secret read permissions
az keyvault set-policy \
  --name myapp-kv \
  --resource-group myapp-rg \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list
```

---

## General Debugging Commands

```bash
# View all resources in resource group
az resource list \
  --resource-group myapp-rg \
  --output table

# Check resource group location
az group show \
  --name myapp-rg \
  --query location

# View activity log
az monitor activity-log list \
  --resource-group myapp-rg \
  --max-events 50

# Check service health
az rest --method get \
  --url "https://management.azure.com/subscriptions/{subscription-id}/providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2020-05-01"

# Export resource group template
az group export \
  --name myapp-rg \
  --output json > template.json
```

---

## Best Practices

1. **Use managed identities** instead of storing credentials
2. **Enable diagnostic logs** for all resources
3. **Set up alerts** for critical metrics
4. **Use private endpoints** for databases
5. **Implement retry logic** in applications
6. **Monitor costs** with budgets and alerts
7. **Use staging slots** for zero-downtime deployments
8. **Regular backups** of databases and configurations
9. **Keep SDKs updated** to latest versions
10. **Document custom configurations** for team reference
