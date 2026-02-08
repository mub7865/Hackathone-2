# Deployment Guide: Cloud-Native Event-Driven Todo Application

**Version**: 1.0
**Last Updated**: 2026-01-12
**Target Audience**: DevOps Engineers, System Administrators

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Docker Deployment](#docker-deployment)
4. [Kubernetes Deployment](#kubernetes-deployment)
5. [Environment Configuration](#environment-configuration)
6. [Database Setup](#database-setup)
7. [Event Streaming Setup](#event-streaming-setup)
8. [Monitoring Setup](#monitoring-setup)
9. [CI/CD Pipeline](#cicd-pipeline)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

- **Docker**: 24.0+ ([Install Docker](https://docs.docker.com/get-docker/))
- **Kubernetes**: 1.28+ (Minikube, Kind, or cloud provider)
- **kubectl**: 1.28+ ([Install kubectl](https://kubernetes.io/docs/tasks/tools/))
- **Helm**: 3.12+ (optional) ([Install Helm](https://helm.sh/docs/intro/install/))
- **Git**: 2.40+
- **Python**: 3.13+ (for local development)
- **Node.js**: 20+ (for local development)

### Cloud Resources

- **PostgreSQL Database**: Neon, AWS RDS, or self-hosted
- **Kafka/Redpanda**: Confluent Cloud, AWS MSK, or self-hosted
- **Container Registry**: GitHub Container Registry (GHCR), Docker Hub, or cloud provider

### Access Requirements

- Kubernetes cluster access (kubeconfig)
- Container registry credentials
- Database connection string
- Kafka bootstrap servers

---

## Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/your-org/todo-app.git
cd todo-app/calm-orbit-todo/phase5-cloud
```

### 2. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Run database migrations
alembic upgrade head

# Start development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Backend Environment Variables** (`.env`):
```env
# Database
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/todo_db

# JWT Authentication
JWT_SECRET=your-secret-key-change-in-production
JWT_ALGORITHM=HS256
JWT_EXPIRATION_MINUTES=15

# Kafka
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
KAFKA_TOPIC_PREFIX=todo-app

# Email (SendGrid)
SENDGRID_API_KEY=your-sendgrid-api-key
SENDGRID_FROM_EMAIL=noreply@example.com

# Environment
ENVIRONMENT=development
LOG_LEVEL=DEBUG
```

### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Set up environment variables
cp .env.local.example .env.local
# Edit .env.local with your configuration

# Start development server
npm run dev
```

**Frontend Environment Variables** (`.env.local`):
```env
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_WS_URL=ws://localhost:8000
```

### 4. Local Infrastructure (Docker Compose)

```bash
# Start PostgreSQL and Kafka
docker-compose up -d

# Check services
docker-compose ps

# View logs
docker-compose logs -f
```

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: todo_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    ports:
      - "9092:9092"
    depends_on:
      - zookeeper

  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"

  redis:
    image: redis:7
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

---

## Docker Deployment

### 1. Build Docker Images

**Backend**:
```bash
cd backend
docker build -t todo-backend:latest -f Dockerfile .
```

**Frontend**:
```bash
cd frontend
docker build -t todo-frontend:latest -f Dockerfile \
  --build-arg NEXT_PUBLIC_API_URL=http://backend:8000 .
```

### 2. Push to Registry

```bash
# Tag images
docker tag todo-backend:latest ghcr.io/your-org/todo-backend:latest
docker tag todo-frontend:latest ghcr.io/your-org/todo-frontend:latest

# Login to registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Push images
docker push ghcr.io/your-org/todo-backend:latest
docker push ghcr.io/your-org/todo-frontend:latest
```

### 3. Run with Docker Compose

```bash
# Full stack deployment
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f backend frontend
```

---

## Kubernetes Deployment

### 1. Prepare Kubernetes Cluster

**Minikube** (Local):
```bash
# Start Minikube
minikube start --cpus=4 --memory=8192 --driver=docker

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

**Cloud Provider** (AWS EKS, GCP GKE, Azure AKS):
```bash
# Configure kubectl
aws eks update-kubeconfig --name todo-app-cluster --region us-east-1
# OR
gcloud container clusters get-credentials todo-app-cluster --region us-central1
# OR
az aks get-credentials --resource-group todo-app-rg --name todo-app-cluster

# Verify access
kubectl get nodes
```

### 2. Create Namespace

```bash
kubectl create namespace todo-app
kubectl config set-context --current --namespace=todo-app
```

### 3. Create Secrets

```bash
# Database credentials
kubectl create secret generic postgres-secret \
  --from-literal=username=postgres \
  --from-literal=password=your-secure-password \
  --from-literal=database=todo_db

# JWT secret
kubectl create secret generic jwt-secret \
  --from-literal=secret-key=your-jwt-secret-key

# SendGrid API key
kubectl create secret generic sendgrid-secret \
  --from-literal=api-key=your-sendgrid-api-key

# Container registry credentials
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=your-username \
  --docker-password=$GITHUB_TOKEN \
  --docker-email=your-email@example.com
```

### 4. Deploy Infrastructure

**PostgreSQL**:
```bash
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s

# Run migrations
kubectl run migrations --rm -it --restart=Never \
  --image=ghcr.io/your-org/todo-backend:latest \
  --env="DATABASE_URL=postgresql+asyncpg://postgres:password@postgres:5432/todo_db" \
  -- alembic upgrade head
```

**Kafka**:
```bash
kubectl apply -f k8s/kafka-deployment.yaml
kubectl apply -f k8s/kafka-service.yaml

# Wait for Kafka to be ready
kubectl wait --for=condition=ready pod -l app=kafka --timeout=300s

# Create topics
kubectl apply -f k8s/kafka-topics.yaml
```

### 5. Deploy Application

**Backend**:
```bash
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml

# Wait for backend to be ready
kubectl wait --for=condition=ready pod -l app=backend --timeout=300s

# Check logs
kubectl logs -l app=backend -f
```

**Frontend**:
```bash
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml

# Wait for frontend to be ready
kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s
```

**Ingress**:
```bash
kubectl apply -f k8s/ingress.yaml

# Get ingress IP
kubectl get ingress
```

### 6. Deploy Dapr

```bash
# Install Dapr CLI
wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash

# Initialize Dapr on Kubernetes
dapr init -k

# Verify Dapr installation
dapr status -k

# Deploy Dapr components
kubectl apply -f k8s/dapr/pubsub-kafka.yaml
kubectl apply -f k8s/dapr/state-store-redis.yaml
```

### 7. Verify Deployment

```bash
# Check all pods
kubectl get pods

# Check services
kubectl get services

# Check ingress
kubectl get ingress

# Test backend health
kubectl port-forward svc/backend 8000:8000
curl http://localhost:8000/health

# Test frontend
kubectl port-forward svc/frontend 3000:3000
# Open http://localhost:3000 in browser
```

---

## Environment Configuration

### Development Environment

**Characteristics**:
- Single replica for all services
- Debug logging enabled
- Hot-reload enabled
- Minimal resource limits
- Local database and Kafka

**Configuration**:
```yaml
# backend-deployment.yaml
replicas: 1
env:
  - name: ENVIRONMENT
    value: "development"
  - name: LOG_LEVEL
    value: "DEBUG"
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Staging Environment

**Characteristics**:
- Production-like setup
- 2 replicas for high availability
- Info logging
- Integration testing
- Shared database and Kafka

**Configuration**:
```yaml
# backend-deployment.yaml
replicas: 2
env:
  - name: ENVIRONMENT
    value: "staging"
  - name: LOG_LEVEL
    value: "INFO"
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### Production Environment

**Characteristics**:
- High availability (3+ replicas)
- Warning/Error logging only
- Auto-scaling enabled
- Monitoring and alerting
- Dedicated database and Kafka cluster

**Configuration**:
```yaml
# backend-deployment.yaml
replicas: 3
env:
  - name: ENVIRONMENT
    value: "production"
  - name: LOG_LEVEL
    value: "WARNING"
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"

# HPA
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

---

## Database Setup

### Neon PostgreSQL (Recommended)

1. **Create Database**:
   - Go to [Neon Console](https://console.neon.tech)
   - Create new project: "todo-app"
   - Create database: "todo_db"
   - Copy connection string

2. **Configure Connection**:
```bash
# Connection string format
postgresql+asyncpg://user:password@host/database?sslmode=require

# Create Kubernetes secret
kubectl create secret generic neon-db-secret \
  --from-literal=connection-string="postgresql+asyncpg://..."
```

3. **Run Migrations**:
```bash
# From local machine
DATABASE_URL="postgresql+asyncpg://..." alembic upgrade head

# OR from Kubernetes
kubectl run migrations --rm -it --restart=Never \
  --image=ghcr.io/your-org/todo-backend:latest \
  --env="DATABASE_URL=$(kubectl get secret neon-db-secret -o jsonpath='{.data.connection-string}' | base64 -d)" \
  -- alembic upgrade head
```

### Self-Hosted PostgreSQL

1. **Deploy PostgreSQL**:
```bash
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
```

2. **Initialize Database**:
```bash
# Connect to PostgreSQL
kubectl exec -it postgres-0 -- psql -U postgres

# Create database
CREATE DATABASE todo_db;
CREATE USER todo_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE todo_db TO todo_user;
\q
```

3. **Backup Strategy**:
```bash
# Create backup
kubectl exec postgres-0 -- pg_dump -U postgres todo_db > backup.sql

# Restore backup
kubectl exec -i postgres-0 -- psql -U postgres todo_db < backup.sql

# Automated backups with CronJob
kubectl apply -f k8s/postgres-backup-cronjob.yaml
```

---

## Event Streaming Setup

### Kafka/Redpanda Deployment

1. **Deploy Kafka**:
```bash
kubectl apply -f k8s/kafka-deployment.yaml
kubectl apply -f k8s/kafka-service.yaml

# Wait for Kafka to be ready
kubectl wait --for=condition=ready pod -l app=kafka --timeout=300s
```

2. **Create Topics**:
```bash
# Apply topic configuration
kubectl apply -f k8s/kafka-topics.yaml

# Verify topics
kubectl exec -it kafka-0 -- kafka-topics --bootstrap-server localhost:9092 --list
```

3. **Configure Dapr Pub/Sub**:
```bash
kubectl apply -f k8s/dapr/pubsub-kafka.yaml
```

### Confluent Cloud (Managed Kafka)

1. **Create Cluster**:
   - Go to [Confluent Cloud](https://confluent.cloud)
   - Create cluster: "todo-app-kafka"
   - Create API key and secret

2. **Create Topics**:
```bash
# Using Confluent CLI
confluent kafka topic create todo-app.task-events --partitions 3
confluent kafka topic create todo-app.reminders --partitions 3
confluent kafka topic create todo-app.recurring-tasks --partitions 3
confluent kafka topic create todo-app.task-updates --partitions 3
```

3. **Configure Application**:
```bash
# Create secret with Confluent Cloud credentials
kubectl create secret generic kafka-secret \
  --from-literal=bootstrap-servers="pkc-xxxxx.us-east-1.aws.confluent.cloud:9092" \
  --from-literal=api-key="your-api-key" \
  --from-literal=api-secret="your-api-secret"
```

---

## Monitoring Setup

### 1. Deploy Prometheus

```bash
# Deploy Prometheus
kubectl apply -f k8s/monitoring/prometheus.yaml

# Verify deployment
kubectl get pods -l app=prometheus

# Access Prometheus UI
kubectl port-forward svc/prometheus 9090:9090
# Open http://localhost:9090
```

### 2. Deploy Grafana

```bash
# Deploy Grafana
kubectl apply -f k8s/monitoring/grafana.yaml

# Verify deployment
kubectl get pods -l app=grafana

# Access Grafana UI
kubectl port-forward svc/grafana 3000:3000
# Open http://localhost:3000
# Login: admin / admin123
```

### 3. Configure Dashboards

```bash
# Deploy dashboard definitions
kubectl apply -f k8s/monitoring/dashboards/dashboards.yaml

# Dashboards will be automatically loaded in Grafana
# Navigate to Dashboards > Browse to see:
# - Todo App Overview
# - Event Streaming Metrics
# - Dapr Metrics
```

### 4. Configure Alerting

```bash
# Deploy alert rules
kubectl apply -f k8s/monitoring/alerts.yaml

# Verify alerts in Prometheus
# Navigate to Alerts tab in Prometheus UI
```

### 5. Configure Dapr Metrics

```bash
# Deploy Dapr monitoring configuration
kubectl apply -f k8s/monitoring/dapr-monitoring.yaml

# Verify Dapr metrics are being collected
# Check Prometheus targets: http://localhost:9090/targets
```

---

## CI/CD Pipeline

### GitHub Actions Setup

1. **Configure Secrets**:
   - Go to GitHub repository settings
   - Navigate to Secrets and variables > Actions
   - Add the following secrets:
     - `KUBECONFIG_DEV`: Base64-encoded kubeconfig for dev
     - `KUBECONFIG_STAGING`: Base64-encoded kubeconfig for staging
     - `KUBECONFIG_PRODUCTION`: Base64-encoded kubeconfig for production
     - `NEXT_PUBLIC_API_URL`: Frontend API URL

2. **Workflows**:
   - **Test Workflow**: Runs on push to main/develop and PRs
   - **Security Workflow**: Runs on push, PRs, and daily at 2 AM UTC
   - **Build Workflow**: Runs on push to main/develop and version tags
   - **Deploy Workflow**: Runs on push to main/develop, version tags, and manual dispatch

3. **Deployment Process**:
```bash
# Automatic deployment on push to main
git push origin main
# Triggers: test → security → build → deploy (production)

# Automatic deployment on push to develop
git push origin develop
# Triggers: test → security → build → deploy (staging)

# Manual deployment
# Go to Actions tab > Deploy workflow > Run workflow
# Select environment and version
```

4. **Release Process**:
```bash
# Create version tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# Triggers: test → security → build → deploy (production)
# Creates GitHub release with Docker image URLs
```

---

## Troubleshooting

### Common Issues

#### 1. Pods Not Starting

**Symptoms**: Pods stuck in `Pending`, `CrashLoopBackOff`, or `ImagePullBackOff`

**Diagnosis**:
```bash
# Check pod status
kubectl get pods

# Describe pod for events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Previous container logs
```

**Solutions**:
- **Pending**: Check resource availability, node capacity
- **CrashLoopBackOff**: Check application logs, environment variables
- **ImagePullBackOff**: Verify image name, registry credentials

#### 2. Database Connection Issues

**Symptoms**: Backend pods failing with database connection errors

**Diagnosis**:
```bash
# Check database pod
kubectl get pods -l app=postgres

# Test database connection
kubectl run psql-test --rm -it --restart=Never \
  --image=postgres:15 \
  --env="PGPASSWORD=password" \
  -- psql -h postgres -U postgres -d todo_db -c "SELECT 1"
```

**Solutions**:
- Verify database credentials in secrets
- Check database service is running
- Verify network policies allow connection
- Check database connection string format

#### 3. Kafka Connection Issues

**Symptoms**: Event producers/consumers failing to connect

**Diagnosis**:
```bash
# Check Kafka pod
kubectl get pods -l app=kafka

# Test Kafka connection
kubectl exec -it kafka-0 -- kafka-broker-api-versions --bootstrap-server localhost:9092
```

**Solutions**:
- Verify Kafka service is running
- Check Kafka bootstrap servers configuration
- Verify Dapr pub/sub component configuration
- Check network connectivity

#### 4. Ingress Not Working

**Symptoms**: Cannot access application via ingress URL

**Diagnosis**:
```bash
# Check ingress
kubectl get ingress
kubectl describe ingress todo-app-ingress

# Check ingress controller
kubectl get pods -n ingress-nginx
```

**Solutions**:
- Verify ingress controller is installed
- Check ingress rules and paths
- Verify DNS configuration
- Check TLS certificates if using HTTPS

#### 5. High Memory Usage

**Symptoms**: Pods being OOMKilled or high memory consumption

**Diagnosis**:
```bash
# Check resource usage
kubectl top pods

# Check pod events
kubectl describe pod <pod-name>
```

**Solutions**:
- Increase memory limits
- Check for memory leaks in application
- Optimize database queries
- Implement caching

### Debugging Commands

```bash
# Get all resources
kubectl get all

# Check pod logs
kubectl logs -f <pod-name>
kubectl logs -f <pod-name> -c <container-name>  # For multi-container pods

# Execute commands in pod
kubectl exec -it <pod-name> -- /bin/bash

# Port forward for local access
kubectl port-forward <pod-name> 8000:8000

# Check resource usage
kubectl top nodes
kubectl top pods

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check secrets
kubectl get secrets
kubectl describe secret <secret-name>

# Check configmaps
kubectl get configmaps
kubectl describe configmap <configmap-name>

# Restart deployment
kubectl rollout restart deployment/<deployment-name>

# Check rollout status
kubectl rollout status deployment/<deployment-name>

# Rollback deployment
kubectl rollout undo deployment/<deployment-name>
```

### Health Checks

```bash
# Backend health check
curl http://<backend-url>/health

# Frontend health check
curl http://<frontend-url>/

# Prometheus health check
curl http://<prometheus-url>/-/healthy

# Grafana health check
curl http://<grafana-url>/api/health
```

### Performance Tuning

```bash
# Increase replicas
kubectl scale deployment backend --replicas=5

# Configure HPA
kubectl autoscale deployment backend --cpu-percent=70 --min=3 --max=10

# Check HPA status
kubectl get hpa

# Optimize database connections
# Edit backend deployment and set:
# - DATABASE_POOL_SIZE=20
# - DATABASE_MAX_OVERFLOW=10
```

---

## Maintenance

### Regular Tasks

1. **Update Dependencies**:
```bash
# Backend
pip list --outdated
pip install --upgrade <package>

# Frontend
npm outdated
npm update
```

2. **Database Maintenance**:
```bash
# Vacuum database
kubectl exec postgres-0 -- psql -U postgres -d todo_db -c "VACUUM ANALYZE"

# Check database size
kubectl exec postgres-0 -- psql -U postgres -d todo_db -c "SELECT pg_size_pretty(pg_database_size('todo_db'))"
```

3. **Log Rotation**:
```bash
# Check log sizes
kubectl exec <pod-name> -- du -sh /var/log

# Configure log rotation in deployment
```

4. **Certificate Renewal**:
```bash
# Check certificate expiration
kubectl get certificate

# Renew certificates (if using cert-manager)
kubectl delete certificate <cert-name>
```

### Backup and Restore

**Database Backup**:
```bash
# Manual backup
kubectl exec postgres-0 -- pg_dump -U postgres todo_db | gzip > backup-$(date +%Y%m%d).sql.gz

# Automated backup with CronJob
kubectl apply -f k8s/postgres-backup-cronjob.yaml
```

**Restore**:
```bash
# Restore from backup
gunzip < backup-20260112.sql.gz | kubectl exec -i postgres-0 -- psql -U postgres todo_db
```

---

## Security Checklist

- [ ] All secrets stored in Kubernetes secrets (not in code)
- [ ] TLS/SSL enabled for all external connections
- [ ] Database encryption at rest enabled
- [ ] Network policies configured
- [ ] RBAC configured for service accounts
- [ ] Container images scanned for vulnerabilities
- [ ] Non-root containers enforced
- [ ] Resource limits configured
- [ ] Audit logging enabled
- [ ] Security scanning in CI/CD pipeline

---

## Support

For issues and questions:
- **Documentation**: [Architecture Overview](architecture.md)
- **API Reference**: [API Documentation](api-reference.md)
- **Monitoring**: [Monitoring Guide](monitoring.md)
- **GitHub Issues**: https://github.com/your-org/todo-app/issues

---

## Appendix

### Useful Links

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Next.js Documentation](https://nextjs.org/docs)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Dapr Documentation](https://docs.dapr.io/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)

### Version History

- **v1.0** (2026-01-12): Initial deployment guide
