# GCP Deployment Troubleshooting

Common issues and solutions when deploying to Google Cloud Platform.

## Table of Contents

1. [Cloud Run Issues](#cloud-run-issues)
2. [Cloud SQL Issues](#cloud-sql-issues)
3. [Networking Issues](#networking-issues)
4. [Container Registry Issues](#container-registry-issues)
5. [Cloud Functions Issues](#cloud-functions-issues)

---

## Cloud Run Issues

### Issue 1: Service Fails to Deploy

**Symptoms:**
- Deployment fails with error
- Service shows "Creating" indefinitely
- Revision not created

**Diagnosis:**

```bash
# Check service status
gcloud run services describe myapp-backend \
  --region us-central1 \
  --format="value(status.conditions)"

# View deployment logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=myapp-backend" \
  --limit 50 \
  --format json

# Check latest revision
gcloud run revisions list \
  --service myapp-backend \
  --region us-central1
```

**Common Causes and Solutions:**

#### Cause 1: Image Pull Error

**Solution:** Check image exists and permissions

```bash
# Verify image exists
gcloud container images describe gcr.io/myapp-prod/backend:v1.0.0

# Check service account permissions
gcloud projects get-iam-policy myapp-prod \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:*"

# Grant Container Registry access
gcloud projects add-iam-policy-binding myapp-prod \
  --member="serviceAccount:PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/storage.objectViewer"
```

#### Cause 2: Application Startup Failure

**Solution:** Check application logs and port configuration

```bash
# View logs
gcloud run services logs read myapp-backend \
  --region us-central1 \
  --limit 100

# Verify port configuration
gcloud run services describe myapp-backend \
  --region us-central1 \
  --format="value(spec.template.spec.containers[0].ports[0].containerPort)"

# Update port if needed
gcloud run services update myapp-backend \
  --region us-central1 \
  --port 8000
```

#### Cause 3: Resource Limits Exceeded

**Solution:** Increase CPU and memory limits

```bash
# Update resource limits
gcloud run services update myapp-backend \
  --region us-central1 \
  --cpu 2 \
  --memory 1Gi

# Check current limits
gcloud run services describe myapp-backend \
  --region us-central1 \
  --format="value(spec.template.spec.containers[0].resources)"
```

---

### Issue 2: Service Returns 503 Errors

**Symptoms:**
- Intermittent 503 Service Unavailable errors
- Cold start issues
- Timeout errors

**Diagnosis:**

```bash
# Check service metrics
gcloud monitoring time-series list \
  --filter='resource.type="cloud_run_revision" AND resource.labels.service_name="myapp-backend"' \
  --format=json

# Check request count
gcloud run services describe myapp-backend \
  --region us-central1 \
  --format="value(status.traffic)"

# View error logs
gcloud logging read "resource.type=cloud_run_revision AND severity>=ERROR" \
  --limit 50
```

**Solutions:**

#### Solution 1: Increase Min Instances

```bash
# Set minimum instances to avoid cold starts
gcloud run services update myapp-backend \
  --region us-central1 \
  --min-instances 1 \
  --max-instances 10
```

#### Solution 2: Increase Timeout

```bash
# Increase request timeout
gcloud run services update myapp-backend \
  --region us-central1 \
  --timeout 300
```

#### Solution 3: Increase Concurrency

```bash
# Increase concurrent requests per instance
gcloud run services update myapp-backend \
  --region us-central1 \
  --concurrency 80
```

---

### Issue 3: Cannot Access Service

**Symptoms:**
- 403 Forbidden errors
- Authentication required
- Service not publicly accessible

**Diagnosis:**

```bash
# Check IAM policy
gcloud run services get-iam-policy myapp-backend \
  --region us-central1

# Test access
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://myapp-backend-xxx-uc.a.run.app/health
```

**Solutions:**

#### Solution 1: Allow Unauthenticated Access

```bash
# Make service public
gcloud run services add-iam-policy-binding myapp-backend \
  --region us-central1 \
  --member="allUsers" \
  --role="roles/run.invoker"
```

#### Solution 2: Grant Specific User Access

```bash
# Grant access to specific user
gcloud run services add-iam-policy-binding myapp-backend \
  --region us-central1 \
  --member="user:user@example.com" \
  --role="roles/run.invoker"

# Grant access to service account
gcloud run services add-iam-policy-binding myapp-backend \
  --region us-central1 \
  --member="serviceAccount:myapp@myapp-prod.iam.gserviceaccount.com" \
  --role="roles/run.invoker"
```

---

## Cloud SQL Issues

### Issue 1: Cannot Connect from Cloud Run

**Symptoms:**
- Connection timeout
- "could not connect to server" error
- Authentication failed

**Diagnosis:**

```bash
# Check Cloud SQL instance status
gcloud sql instances describe myapp-prod-db \
  --format="value(state)"

# Check connection name
gcloud sql instances describe myapp-prod-db \
  --format="value(connectionName)"

# Check if private IP is enabled
gcloud sql instances describe myapp-prod-db \
  --format="value(ipAddresses)"
```

**Solutions:**

#### Solution 1: Use Cloud SQL Proxy

```bash
# Update Cloud Run service to use Cloud SQL
gcloud run services update myapp-backend \
  --region us-central1 \
  --add-cloudsql-instances myapp-prod:us-central1:myapp-prod-db

# Use Unix socket in connection string
# postgresql://user:pass@/dbname?host=/cloudsql/myapp-prod:us-central1:myapp-prod-db
```

#### Solution 2: Configure VPC Connector

```bash
# Create VPC connector
gcloud compute networks vpc-access connectors create myapp-connector \
  --network myapp-network \
  --region us-central1 \
  --range 10.8.0.0/28

# Update Cloud Run to use VPC connector
gcloud run services update myapp-backend \
  --region us-central1 \
  --vpc-connector myapp-connector \
  --vpc-egress all-traffic
```

#### Solution 3: Check Authorized Networks

```bash
# List authorized networks
gcloud sql instances describe myapp-prod-db \
  --format="value(settings.ipConfiguration.authorizedNetworks)"

# Add authorized network (if using public IP)
gcloud sql instances patch myapp-prod-db \
  --authorized-networks=0.0.0.0/0
```

---

### Issue 2: Database Performance Issues

**Symptoms:**
- Slow queries
- High CPU usage
- Connection pool exhaustion

**Diagnosis:**

```bash
# Check CPU utilization
gcloud monitoring time-series list \
  --filter='resource.type="cloudsql_database" AND metric.type="cloudsql.googleapis.com/database/cpu/utilization"' \
  --format=json

# Check active connections
gcloud sql operations list \
  --instance myapp-prod-db \
  --limit 10

# Check instance tier
gcloud sql instances describe myapp-prod-db \
  --format="value(settings.tier)"
```

**Solutions:**

#### Solution 1: Scale Up Instance

```bash
# Upgrade to higher tier
gcloud sql instances patch myapp-prod-db \
  --tier db-n1-standard-2

# Enable automatic storage increase
gcloud sql instances patch myapp-prod-db \
  --storage-auto-increase
```

#### Solution 2: Enable Query Insights

```bash
# Enable Query Insights
gcloud sql instances patch myapp-prod-db \
  --insights-config-query-insights-enabled \
  --insights-config-query-string-length=1024 \
  --insights-config-record-application-tags \
  --insights-config-record-client-address
```

#### Solution 3: Configure Connection Pooling

```python
# Use connection pooling in application
from sqlalchemy import create_engine
from sqlalchemy.pool import NullPool

engine = create_engine(
    DATABASE_URL,
    pool_size=5,
    max_overflow=10,
    pool_timeout=30,
    pool_recycle=1800
)
```

---

## Networking Issues

### Issue 1: VPC Connector Issues

**Symptoms:**
- Cannot connect to private resources
- VPC connector creation fails
- Slow network performance

**Diagnosis:**

```bash
# Check VPC connector status
gcloud compute networks vpc-access connectors describe myapp-connector \
  --region us-central1

# List all connectors
gcloud compute networks vpc-access connectors list

# Check connector usage
gcloud monitoring time-series list \
  --filter='resource.type="vpc_access_connector"' \
  --format=json
```

**Solutions:**

#### Solution 1: Increase Connector Throughput

```bash
# Update connector with more throughput
gcloud compute networks vpc-access connectors update myapp-connector \
  --region us-central1 \
  --min-throughput 300 \
  --max-throughput 1000
```

#### Solution 2: Create New Connector with Different Range

```bash
# Delete old connector
gcloud compute networks vpc-access connectors delete myapp-connector \
  --region us-central1

# Create new connector with different IP range
gcloud compute networks vpc-access connectors create myapp-connector \
  --network myapp-network \
  --region us-central1 \
  --range 10.9.0.0/28
```

---

### Issue 2: Load Balancer Issues

**Symptoms:**
- Custom domain not working
- SSL certificate errors
- 502 Bad Gateway errors

**Diagnosis:**

```bash
# Check backend service health
gcloud compute backend-services get-health myapp-backend-service \
  --global

# Check SSL certificate status
gcloud compute ssl-certificates describe myapp-cert \
  --global

# Check URL map
gcloud compute url-maps describe myapp-lb \
  --global
```

**Solutions:**

#### Solution 1: Fix SSL Certificate

```bash
# Check certificate status
gcloud compute ssl-certificates describe myapp-cert \
  --global \
  --format="value(managed.status)"

# Create new managed certificate
gcloud compute ssl-certificates create myapp-cert-new \
  --domains=myapp.example.com,www.myapp.example.com \
  --global

# Update HTTPS proxy
gcloud compute target-https-proxies update myapp-https-proxy \
  --ssl-certificates=myapp-cert-new \
  --global
```

#### Solution 2: Check Backend Health

```bash
# View backend health
gcloud compute backend-services get-health myapp-backend-service \
  --global

# Update health check
gcloud compute health-checks update http myapp-health-check \
  --port 8000 \
  --request-path /health \
  --check-interval 10s \
  --timeout 5s \
  --unhealthy-threshold 3 \
  --healthy-threshold 2
```

---

## Container Registry Issues

### Issue 1: Cannot Push Images

**Symptoms:**
- "denied: Token exchange failed" error
- "unauthorized: authentication required" error
- Push fails

**Diagnosis:**

```bash
# Check authentication
gcloud auth list

# Check Docker configuration
cat ~/.docker/config.json | grep gcr.io

# Test registry access
gcloud container images list --repository=gcr.io/myapp-prod
```

**Solutions:**

#### Solution 1: Re-authenticate Docker

```bash
# Configure Docker for GCR
gcloud auth configure-docker

# Or use access token
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://gcr.io
```

#### Solution 2: Check IAM Permissions

```bash
# Check current user permissions
gcloud projects get-iam-policy myapp-prod \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:$(gcloud config get-value account)"

# Grant Storage Admin role
gcloud projects add-iam-policy-binding myapp-prod \
  --member="user:$(gcloud config get-value account)" \
  --role="roles/storage.admin"
```

---

### Issue 2: Image Vulnerability Scanning

**Symptoms:**
- Security vulnerabilities detected
- High/critical severity findings
- Deployment concerns

**Diagnosis:**

```bash
# Check vulnerability scan results
gcloud container images describe gcr.io/myapp-prod/backend:v1.0.0 \
  --show-package-vulnerability

# List vulnerabilities
gcloud container images list-tags gcr.io/myapp-prod/backend \
  --format="get(digest)" | head -1 | xargs -I {} \
  gcloud container images describe gcr.io/myapp-prod/backend@{} \
  --show-package-vulnerability
```

**Solutions:**

#### Solution 1: Update Base Image

```dockerfile
# Use latest secure base image
FROM python:3.13-slim

# Update all packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

#### Solution 2: Enable Binary Authorization

```bash
# Enable Binary Authorization API
gcloud services enable binaryauthorization.googleapis.com

# Create policy
gcloud container binauthz policy import policy.yaml
```

---

## Cloud Functions Issues

### Issue 1: Function Deployment Fails

**Symptoms:**
- Deployment fails with error
- Function not created
- Build fails

**Diagnosis:**

```bash
# Check function status
gcloud functions describe myapp-function \
  --region us-central1

# View build logs
gcloud functions logs read myapp-function \
  --region us-central1 \
  --limit 50

# Check function configuration
gcloud functions describe myapp-function \
  --region us-central1 \
  --format=json
```

**Solutions:**

#### Solution 1: Fix Dependencies

```bash
# Ensure requirements.txt is correct
cat requirements.txt

# Deploy with specific runtime
gcloud functions deploy myapp-function \
  --runtime python313 \
  --trigger-http \
  --allow-unauthenticated \
  --region us-central1 \
  --entry-point handler
```

#### Solution 2: Increase Memory and Timeout

```bash
# Update function configuration
gcloud functions deploy myapp-function \
  --memory 512MB \
  --timeout 300s \
  --region us-central1
```

---

### Issue 2: Function Cold Start Issues

**Symptoms:**
- First request is very slow
- Timeout on initial invocation
- Inconsistent performance

**Solutions:**

#### Solution 1: Use Cloud Scheduler for Warm-up

```bash
# Create scheduler job to keep function warm
gcloud scheduler jobs create http warmup-myapp-function \
  --schedule="*/5 * * * *" \
  --uri="https://us-central1-myapp-prod.cloudfunctions.net/myapp-function" \
  --http-method=GET
```

#### Solution 2: Optimize Function Code

```python
# Use global variables for reuse
import os
from google.cloud import storage

# Initialize once (outside handler)
storage_client = storage.Client()
BUCKET_NAME = os.environ.get('BUCKET_NAME')

def handler(request):
    # Use pre-initialized client
    bucket = storage_client.bucket(BUCKET_NAME)
    # ... rest of code
```

---

## General Debugging Commands

```bash
# View all Cloud Run services
gcloud run services list --platform managed

# View all Cloud SQL instances
gcloud sql instances list

# View all VPC connectors
gcloud compute networks vpc-access connectors list

# Check project quotas
gcloud compute project-info describe --project myapp-prod

# View audit logs
gcloud logging read "protoPayload.serviceName=run.googleapis.com" \
  --limit 50 \
  --format json

# Check service health
gcloud monitoring dashboards list

# Export project configuration
gcloud projects describe myapp-prod --format=json > project-config.json
```

---

## Best Practices

1. **Use managed services** (Cloud Run, Cloud SQL) for easier operations
2. **Enable Cloud Monitoring** for all services
3. **Use Secret Manager** for sensitive data
4. **Implement proper health checks** for all services
5. **Use VPC connectors** for private resource access
6. **Enable Cloud Trace** for distributed tracing
7. **Set up alerting policies** for critical metrics
8. **Use Cloud Armor** for DDoS protection
9. **Regular backups** of Cloud SQL databases
10. **Keep container images updated** and scan for vulnerabilities
