# GCP Deployment Example

Complete example of deploying a serverless application to Google Cloud Platform using Cloud Run.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Google Cloud Platform                       │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Project: myapp-prod                     │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │              Cloud Load Balancer                     │ │ │
│  │  │              (Global HTTPS)                          │ │ │
│  │  │              myapp.example.com                       │ │ │
│  │  └────────────────┬─────────────────────────────────────┘ │ │
│  │                   │                                        │ │
│  │  ┌────────────────▼─────────────────────────────────────┐ │ │
│  │  │         Cloud Run Services (Serverless)              │ │ │
│  │  │                                                      │ │ │
│  │  │  ┌──────────────┐    ┌──────────────┐              │ │ │
│  │  │  │   Frontend   │    │   Backend    │              │ │ │
│  │  │  │   (Next.js)  │◄───┤   (FastAPI)  │              │ │ │
│  │  │  │   Port: 3000 │    │   Port: 8000 │              │ │ │
│  │  │  └──────────────┘    └──────────────┘              │ │ │
│  │  │                              │                      │ │ │
│  │  └──────────────────────────────┼──────────────────────┘ │ │
│  │                                 │                        │ │
│  │  ┌──────────────────────────────▼──────────────────────┐ │ │
│  │  │         Cloud SQL (PostgreSQL)                      │ │ │
│  │  │         Private IP Connection                       │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │         Memorystore (Redis)                         │ │ │
│  │  │         Private IP Connection                       │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │         Container Registry (GCR)                    │ │ │
│  │  │         gcr.io/myapp-prod                           │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │         Secret Manager                              │ │ │
│  │  │         (Database credentials, API keys)            │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │         Cloud Pub/Sub (Event Bus)                   │ │ │
│  │  │         Background job processing                   │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Initialize gcloud
gcloud init

# Set project
gcloud config set project myapp-prod

# Enable required APIs
gcloud services enable \
  run.googleapis.com \
  sql-component.googleapis.com \
  sqladmin.googleapis.com \
  redis.googleapis.com \
  secretmanager.googleapis.com \
  pubsub.googleapis.com \
  cloudscheduler.googleapis.com \
  containerregistry.googleapis.com
```

## Step 1: Create VPC Network

```bash
# Create VPC network
gcloud compute networks create myapp-network \
  --subnet-mode=auto \
  --bgp-routing-mode=regional

# Create VPC connector for Cloud Run
gcloud compute networks vpc-access connectors create myapp-connector \
  --network myapp-network \
  --region us-central1 \
  --range 10.8.0.0/28
```

## Step 2: Create Cloud SQL PostgreSQL

```bash
# Create Cloud SQL instance
gcloud sql instances create myapp-prod-db \
  --database-version=POSTGRES_16 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --network=projects/myapp-prod/global/networks/myapp-network \
  --no-assign-ip \
  --root-password='SecurePassword123!'

# Create database
gcloud sql databases create myapp \
  --instance=myapp-prod-db

# Create database user
gcloud sql users create dbadmin \
  --instance=myapp-prod-db \
  --password='SecurePassword123!'

# Get connection name
CONNECTION_NAME=$(gcloud sql instances describe myapp-prod-db \
  --format='value(connectionName)')

echo "Connection name: $CONNECTION_NAME"

# Get private IP
DB_IP=$(gcloud sql instances describe myapp-prod-db \
  --format='value(ipAddresses[0].ipAddress)')

echo "Database IP: $DB_IP"
```

## Step 3: Create Memorystore Redis

```bash
# Create Redis instance
gcloud redis instances create myapp-redis \
  --size=1 \
  --region=us-central1 \
  --network=projects/myapp-prod/global/networks/myapp-network \
  --redis-version=redis_7_0

# Get Redis host
REDIS_HOST=$(gcloud redis instances describe myapp-redis \
  --region=us-central1 \
  --format='value(host)')

echo "Redis host: $REDIS_HOST"
```

## Step 4: Store Secrets in Secret Manager

```bash
# Create database URL secret
echo -n "postgresql://dbadmin:SecurePassword123!@$DB_IP:5432/myapp" | \
  gcloud secrets create database-url --data-file=-

# Create JWT secret
echo -n "your-jwt-secret-key" | \
  gcloud secrets create jwt-secret --data-file=-

# Create Redis URL secret
echo -n "redis://$REDIS_HOST:6379" | \
  gcloud secrets create redis-url --data-file=-

# Grant Cloud Run access to secrets
PROJECT_NUMBER=$(gcloud projects describe myapp-prod --format='value(projectNumber)')

gcloud secrets add-iam-policy-binding database-url \
  --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding jwt-secret \
  --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding redis-url \
  --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

## Step 5: Build and Push Docker Images

```bash
# Configure Docker for GCR
gcloud auth configure-docker

# Build images
docker build -t gcr.io/myapp-prod/frontend:v1.0.0 ./frontend
docker build -t gcr.io/myapp-prod/backend:v1.0.0 ./backend

# Push images
docker push gcr.io/myapp-prod/frontend:v1.0.0
docker push gcr.io/myapp-prod/backend:v1.0.0

# Verify images
gcloud container images list --repository=gcr.io/myapp-prod
```

## Step 6: Deploy Backend to Cloud Run

```bash
# Deploy backend service
gcloud run deploy myapp-backend \
  --image gcr.io/myapp-prod/backend:v1.0.0 \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8000 \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --vpc-connector myapp-connector \
  --set-env-vars ENVIRONMENT=production \
  --set-secrets DATABASE_URL=database-url:latest,JWT_SECRET=jwt-secret:latest,REDIS_URL=redis-url:latest

# Get backend URL
BACKEND_URL=$(gcloud run services describe myapp-backend \
  --region us-central1 \
  --format='value(status.url)')

echo "Backend URL: $BACKEND_URL"
```

## Step 7: Deploy Frontend to Cloud Run

```bash
# Deploy frontend service
gcloud run deploy myapp-frontend \
  --image gcr.io/myapp-prod/frontend:v1.0.0 \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 3000 \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --set-env-vars NEXT_PUBLIC_API_URL=$BACKEND_URL,ENVIRONMENT=production

# Get frontend URL
FRONTEND_URL=$(gcloud run services describe myapp-frontend \
  --region us-central1 \
  --format='value(status.url)')

echo "Frontend URL: $FRONTEND_URL"
```

## Step 8: Configure Custom Domain with Load Balancer

```bash
# Reserve static IP
gcloud compute addresses create myapp-ip \
  --global

# Get IP address
STATIC_IP=$(gcloud compute addresses describe myapp-ip \
  --global \
  --format='value(address)')

echo "Static IP: $STATIC_IP"
echo "Add DNS A record: myapp.example.com -> $STATIC_IP"

# Create serverless NEG for backend
gcloud compute network-endpoint-groups create myapp-backend-neg \
  --region=us-central1 \
  --network-endpoint-type=serverless \
  --cloud-run-service=myapp-backend

# Create serverless NEG for frontend
gcloud compute network-endpoint-groups create myapp-frontend-neg \
  --region=us-central1 \
  --network-endpoint-type=serverless \
  --cloud-run-service=myapp-frontend

# Create backend services
gcloud compute backend-services create myapp-backend-service \
  --global

gcloud compute backend-services add-backend myapp-backend-service \
  --global \
  --network-endpoint-group=myapp-backend-neg \
  --network-endpoint-group-region=us-central1

gcloud compute backend-services create myapp-frontend-service \
  --global

gcloud compute backend-services add-backend myapp-frontend-service \
  --global \
  --network-endpoint-group=myapp-frontend-neg \
  --network-endpoint-group-region=us-central1

# Create URL map
gcloud compute url-maps create myapp-lb \
  --default-service myapp-frontend-service

# Add path matcher for API
gcloud compute url-maps add-path-matcher myapp-lb \
  --path-matcher-name=api-matcher \
  --default-service=myapp-frontend-service \
  --path-rules="/api/*=myapp-backend-service"

# Create SSL certificate
gcloud compute ssl-certificates create myapp-cert \
  --domains=myapp.example.com

# Create HTTPS proxy
gcloud compute target-https-proxies create myapp-https-proxy \
  --url-map=myapp-lb \
  --ssl-certificates=myapp-cert

# Create forwarding rule
gcloud compute forwarding-rules create myapp-https-rule \
  --global \
  --target-https-proxy=myapp-https-proxy \
  --address=myapp-ip \
  --ports=443
```

## Step 9: Set Up Cloud Pub/Sub for Background Jobs

```bash
# Create Pub/Sub topic
gcloud pubsub topics create task-events

# Create subscription
gcloud pubsub subscriptions create task-events-sub \
  --topic=task-events \
  --ack-deadline=60

# Deploy worker service
gcloud run deploy myapp-worker \
  --image gcr.io/myapp-prod/backend:v1.0.0 \
  --platform managed \
  --region us-central1 \
  --no-allow-unauthenticated \
  --port 8000 \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 5 \
  --vpc-connector myapp-connector \
  --set-env-vars ENVIRONMENT=production,WORKER_MODE=true \
  --set-secrets DATABASE_URL=database-url:latest,REDIS_URL=redis-url:latest

# Create Pub/Sub push subscription to worker
gcloud pubsub subscriptions create task-events-worker \
  --topic=task-events \
  --push-endpoint=$(gcloud run services describe myapp-worker --region us-central1 --format='value(status.url)')/webhook/pubsub \
  --ack-deadline=60
```

## Step 10: Set Up Cloud Scheduler for Cron Jobs

```bash
# Create scheduler job
gcloud scheduler jobs create http daily-cleanup \
  --schedule="0 2 * * *" \
  --uri="$BACKEND_URL/api/cron/cleanup" \
  --http-method=POST \
  --oidc-service-account-email=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --oidc-token-audience=$BACKEND_URL

# Create another scheduler job
gcloud scheduler jobs create http hourly-sync \
  --schedule="0 * * * *" \
  --uri="$BACKEND_URL/api/cron/sync" \
  --http-method=POST \
  --oidc-service-account-email=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --oidc-token-audience=$BACKEND_URL
```

## Step 11: Configure Monitoring and Logging

```bash
# Create log-based metric
gcloud logging metrics create error_count \
  --description="Count of error logs" \
  --log-filter='severity>=ERROR'

# Create alert policy
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="High Error Rate" \
  --condition-display-name="Error rate > 10/min" \
  --condition-threshold-value=10 \
  --condition-threshold-duration=60s \
  --condition-filter='metric.type="logging.googleapis.com/user/error_count"'
```

## Step 12: Update Application

```bash
# Build new version
docker build -t gcr.io/myapp-prod/backend:v1.1.0 ./backend
docker push gcr.io/myapp-prod/backend:v1.1.0

# Deploy new version (gradual rollout)
gcloud run services update myapp-backend \
  --image gcr.io/myapp-prod/backend:v1.1.0 \
  --region us-central1

# Check revision status
gcloud run revisions list \
  --service myapp-backend \
  --region us-central1

# Split traffic between revisions (canary deployment)
gcloud run services update-traffic myapp-backend \
  --region us-central1 \
  --to-revisions=myapp-backend-v1-1-0=10,myapp-backend-v1-0-0=90

# After validation, route all traffic to new version
gcloud run services update-traffic myapp-backend \
  --region us-central1 \
  --to-latest
```

## Monitoring and Logs

```bash
# View logs
gcloud run services logs read myapp-backend \
  --region us-central1 \
  --limit 100

# Follow logs
gcloud run services logs tail myapp-backend \
  --region us-central1

# View metrics
gcloud monitoring time-series list \
  --filter='resource.type="cloud_run_revision" AND resource.labels.service_name="myapp-backend"'

# View service details
gcloud run services describe myapp-backend \
  --region us-central1
```

## Cleanup

```bash
# Delete Cloud Run services
gcloud run services delete myapp-backend --region us-central1 --quiet
gcloud run services delete myapp-frontend --region us-central1 --quiet
gcloud run services delete myapp-worker --region us-central1 --quiet

# Delete Cloud SQL instance
gcloud sql instances delete myapp-prod-db --quiet

# Delete Redis instance
gcloud redis instances delete myapp-redis --region us-central1 --quiet

# Delete Pub/Sub resources
gcloud pubsub subscriptions delete task-events-sub --quiet
gcloud pubsub subscriptions delete task-events-worker --quiet
gcloud pubsub topics delete task-events --quiet

# Delete scheduler jobs
gcloud scheduler jobs delete daily-cleanup --quiet
gcloud scheduler jobs delete hourly-sync --quiet

# Delete load balancer resources
gcloud compute forwarding-rules delete myapp-https-rule --global --quiet
gcloud compute target-https-proxies delete myapp-https-proxy --quiet
gcloud compute ssl-certificates delete myapp-cert --quiet
gcloud compute url-maps delete myapp-lb --quiet
gcloud compute backend-services delete myapp-backend-service --global --quiet
gcloud compute backend-services delete myapp-frontend-service --global --quiet
gcloud compute network-endpoint-groups delete myapp-backend-neg --region us-central1 --quiet
gcloud compute network-endpoint-groups delete myapp-frontend-neg --region us-central1 --quiet
gcloud compute addresses delete myapp-ip --global --quiet

# Delete VPC connector
gcloud compute networks vpc-access connectors delete myapp-connector --region us-central1 --quiet

# Delete secrets
gcloud secrets delete database-url --quiet
gcloud secrets delete jwt-secret --quiet
gcloud secrets delete redis-url --quiet
```

## Cost Estimation

**Monthly costs (approximate):**
- Cloud Run (2 services, 1-10 instances): $20-80
- Cloud SQL (db-f1-micro): $7
- Memorystore Redis (1GB): $30
- Load Balancer: $18
- Cloud Storage (GCR): $0.026 per GB
- Pub/Sub: $0.40 per million messages
- Cloud Scheduler: $0.10 per job

**Total: ~$75-135/month** (varies with traffic)

## Best Practices

1. **Use Cloud Run** for serverless, auto-scaling containers
2. **Private IP** for Cloud SQL and Redis
3. **Secret Manager** for sensitive data
4. **VPC connector** for private network access
5. **Global load balancer** with SSL for custom domains
6. **Cloud Pub/Sub** for asynchronous processing
7. **Cloud Scheduler** for cron jobs
8. **Gradual rollouts** with traffic splitting
9. **Cloud Monitoring** for observability
10. **IAM service accounts** with least privilege

## Advantages of GCP Cloud Run

- **Fully managed**: No infrastructure to manage
- **Auto-scaling**: Scales to zero when idle
- **Pay per use**: Only pay for actual usage
- **Fast deployments**: Deploy in seconds
- **Built-in traffic splitting**: Easy canary deployments
- **Integrated monitoring**: Cloud Logging and Monitoring
- **Global load balancing**: Low latency worldwide
- **Container-based**: Use any language or framework
