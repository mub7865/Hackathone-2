# General Cloud Deployment Issues

Common deployment issues that apply across Azure, AWS, and GCP.

## Table of Contents

1. [Docker and Container Issues](#docker-and-container-issues)
2. [CI/CD Pipeline Issues](#cicd-pipeline-issues)
3. [Environment Configuration Issues](#environment-configuration-issues)
4. [SSL/TLS Certificate Issues](#ssltls-certificate-issues)
5. [Performance and Scaling Issues](#performance-and-scaling-issues)

---

## Docker and Container Issues

### Issue 1: Container Build Fails

**Symptoms:**
- Docker build fails with error
- Dependencies cannot be installed
- Build takes too long

**Common Causes and Solutions:**

#### Cause 1: Network Issues During Build

**Solution:** Configure build-time networking

```dockerfile
# Use build arguments for proxy
ARG HTTP_PROXY
ARG HTTPS_PROXY

# Set environment variables
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Unset proxy for runtime
ENV HTTP_PROXY=
ENV HTTPS_PROXY=
```

#### Cause 2: Large Build Context

**Solution:** Optimize .dockerignore

```
# .dockerignore
node_modules/
.git/
.env
*.log
dist/
build/
coverage/
.pytest_cache/
__pycache__/
*.pyc
.venv/
venv/
```

#### Cause 3: Layer Caching Issues

**Solution:** Optimize Dockerfile layer order

```dockerfile
# Bad: Changes to code invalidate dependency cache
COPY . .
RUN pip install -r requirements.txt

# Good: Install dependencies first
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
```

---

### Issue 2: Container Runs Locally but Fails in Cloud

**Symptoms:**
- Works on local machine
- Fails when deployed to cloud
- Different behavior in production

**Diagnosis:**

```bash
# Test container locally with production-like settings
docker run --rm \
  -e ENVIRONMENT=production \
  -e DATABASE_URL=postgresql://... \
  -p 8000:8000 \
  myapp:latest

# Check environment variables
docker inspect myapp:latest | jq '.[0].Config.Env'

# Test with resource limits
docker run --rm \
  --memory=512m \
  --cpus=0.5 \
  myapp:latest
```

**Solutions:**

#### Solution 1: Environment Variable Differences

```bash
# Ensure all required env vars are set
docker run --rm \
  --env-file .env.production \
  myapp:latest

# Or in cloud deployment
# Azure
az containerapp update --set-env-vars KEY=VALUE

# AWS
aws ecs update-service --environment variables=[{name=KEY,value=VALUE}]

# GCP
gcloud run services update --set-env-vars KEY=VALUE
```

#### Solution 2: Port Binding Issues

```dockerfile
# Ensure app binds to 0.0.0.0, not localhost
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# For Node.js
CMD ["node", "server.js"]
# In server.js: app.listen(8000, '0.0.0.0')
```

#### Solution 3: File System Differences

```dockerfile
# Use absolute paths
WORKDIR /app
COPY . /app

# Set proper permissions
RUN chmod +x /app/entrypoint.sh

# Use non-root user
RUN useradd -m -u 10001 appuser && \
    chown -R appuser:appuser /app
USER appuser
```

---

## CI/CD Pipeline Issues

### Issue 1: Pipeline Fails to Build

**Symptoms:**
- Build step fails
- Tests fail in CI but pass locally
- Deployment step fails

**Common Causes and Solutions:**

#### Cause 1: Missing Dependencies in CI

**Solution:** Ensure CI environment matches local

```yaml
# GitHub Actions example
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.13'
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Run tests
        run: pytest
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test
```

#### Cause 2: Secrets Not Available

**Solution:** Configure secrets properly

```yaml
# GitHub Actions
- name: Deploy to Azure
  env:
    AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
    ACR_USERNAME: ${{ secrets.ACR_USERNAME }}
    ACR_PASSWORD: ${{ secrets.ACR_PASSWORD }}
  run: |
    echo $AZURE_CREDENTIALS | az login --service-principal
    docker login myregistry.azurecr.io -u $ACR_USERNAME -p $ACR_PASSWORD
```

#### Cause 3: Docker Build Fails in CI

**Solution:** Use BuildKit and caching

```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v2

- name: Build and push
  uses: docker/build-push-action@v4
  with:
    context: .
    push: true
    tags: myregistry.azurecr.io/myapp:${{ github.sha }}
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

---

### Issue 2: Deployment Succeeds but Application Doesn't Work

**Symptoms:**
- Deployment completes successfully
- Application not accessible or returns errors
- Health checks fail

**Diagnosis:**

```bash
# Check application logs
# Azure
az containerapp logs show --name myapp --resource-group myapp-rg --follow

# AWS
aws logs tail /ecs/myapp --follow

# GCP
gcloud run services logs read myapp-backend --region us-central1 --limit 100

# Test health endpoint
curl -v https://myapp.example.com/health
```

**Solutions:**

#### Solution 1: Database Migration Not Run

```yaml
# Add migration step to CI/CD
- name: Run database migrations
  run: |
    # For Alembic
    alembic upgrade head

    # For Django
    python manage.py migrate

    # For Prisma
    npx prisma migrate deploy
```

#### Solution 2: Environment Variables Not Set

```bash
# Verify all required env vars are set
# Azure
az containerapp show --name myapp --resource-group myapp-rg \
  --query properties.template.containers[0].env

# AWS
aws ecs describe-task-definition --task-definition myapp \
  --query 'taskDefinition.containerDefinitions[0].environment'

# GCP
gcloud run services describe myapp-backend --region us-central1 \
  --format="value(spec.template.spec.containers[0].env)"
```

---

## Environment Configuration Issues

### Issue 1: Configuration Mismatch Between Environments

**Symptoms:**
- Works in dev but fails in production
- Different behavior across environments
- Hard to reproduce issues

**Solutions:**

#### Solution 1: Use Environment-Specific Configuration Files

```python
# config.py
import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    environment: str = os.getenv("ENVIRONMENT", "development")
    database_url: str
    redis_url: str
    jwt_secret: str

    # Environment-specific settings
    debug: bool = False
    log_level: str = "INFO"

    class Config:
        env_file = f".env.{os.getenv('ENVIRONMENT', 'development')}"
        case_sensitive = False

    @property
    def is_production(self) -> bool:
        return self.environment == "production"

settings = Settings()
```

#### Solution 2: Validate Configuration on Startup

```python
# startup.py
def validate_config():
    """Validate required configuration on startup."""
    required_vars = [
        "DATABASE_URL",
        "JWT_SECRET",
        "REDIS_URL"
    ]

    missing = [var for var in required_vars if not os.getenv(var)]

    if missing:
        raise ValueError(f"Missing required environment variables: {', '.join(missing)}")

    # Validate database connection
    try:
        engine = create_engine(settings.database_url)
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
    except Exception as e:
        raise ValueError(f"Cannot connect to database: {e}")

# Call on startup
validate_config()
```

---

### Issue 2: Secrets Management Issues

**Symptoms:**
- Secrets exposed in logs or code
- Cannot access secrets in production
- Secrets rotation causes downtime

**Solutions:**

#### Solution 1: Use Cloud Secret Managers

```python
# Azure Key Vault
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(vault_url="https://myapp-kv.vault.azure.net/", credential=credential)
database_password = client.get_secret("database-password").value

# AWS Secrets Manager
import boto3
client = boto3.client('secretsmanager')
response = client.get_secret_value(SecretId='myapp/database')
database_password = json.loads(response['SecretString'])['password']

# GCP Secret Manager
from google.cloud import secretmanager
client = secretmanager.SecretManagerServiceClient()
name = "projects/myapp-prod/secrets/database-password/versions/latest"
response = client.access_secret_version(request={"name": name})
database_password = response.payload.data.decode('UTF-8')
```

#### Solution 2: Never Log Secrets

```python
import logging
import re

class SecretFilter(logging.Filter):
    """Filter to redact secrets from logs."""

    SECRET_PATTERNS = [
        r'password["\']?\s*[:=]\s*["\']?([^"\'}\s]+)',
        r'token["\']?\s*[:=]\s*["\']?([^"\'}\s]+)',
        r'api[_-]?key["\']?\s*[:=]\s*["\']?([^"\'}\s]+)',
    ]

    def filter(self, record):
        message = record.getMessage()
        for pattern in self.SECRET_PATTERNS:
            message = re.sub(pattern, r'\1=***REDACTED***', message, flags=re.IGNORECASE)
        record.msg = message
        return True

# Add filter to logger
logger = logging.getLogger()
logger.addFilter(SecretFilter())
```

---

## SSL/TLS Certificate Issues

### Issue 1: Certificate Validation Fails

**Symptoms:**
- "certificate verify failed" errors
- SSL handshake failures
- Mixed content warnings

**Solutions:**

#### Solution 1: Ensure Certificate Chain is Complete

```bash
# Test certificate chain
openssl s_client -connect myapp.example.com:443 -showcerts

# Verify certificate
echo | openssl s_client -servername myapp.example.com -connect myapp.example.com:443 2>/dev/null | openssl x509 -noout -dates

# Check certificate expiration
echo | openssl s_client -servername myapp.example.com -connect myapp.example.com:443 2>/dev/null | openssl x509 -noout -enddate
```

#### Solution 2: Configure Application to Trust Certificates

```python
# For requests library
import requests
import certifi

response = requests.get('https://api.example.com', verify=certifi.where())

# For production, always verify certificates
# For development only, you can disable (NOT RECOMMENDED)
# response = requests.get('https://api.example.com', verify=False)
```

---

### Issue 2: Certificate Renewal Issues

**Symptoms:**
- Certificate expired
- Automatic renewal failed
- Downtime during renewal

**Solutions:**

#### Solution 1: Use Managed Certificates

```bash
# Azure
az containerapp hostname bind \
  --name myapp \
  --resource-group myapp-rg \
  --hostname myapp.example.com \
  --environment myapp-env \
  --validation-method CNAME

# AWS (ACM)
aws acm request-certificate \
  --domain-name myapp.example.com \
  --validation-method DNS

# GCP
gcloud compute ssl-certificates create myapp-cert \
  --domains=myapp.example.com \
  --global
```

#### Solution 2: Monitor Certificate Expiration

```bash
# Set up monitoring alert
# Azure
az monitor metrics alert create \
  --name cert-expiry-alert \
  --resource-group myapp-rg \
  --condition "avg certificateExpiry < 30"

# AWS CloudWatch
aws cloudwatch put-metric-alarm \
  --alarm-name cert-expiry-alert \
  --metric-name DaysToExpiry \
  --threshold 30

# GCP
gcloud monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="Certificate Expiry Alert"
```

---

## Performance and Scaling Issues

### Issue 1: Application Slow Under Load

**Symptoms:**
- High response times
- Timeouts
- Poor user experience

**Diagnosis:**

```bash
# Load testing with Apache Bench
ab -n 1000 -c 10 https://myapp.example.com/

# Load testing with wrk
wrk -t4 -c100 -d30s https://myapp.example.com/

# Monitor during load test
# Check CPU, memory, network, database connections
```

**Solutions:**

#### Solution 1: Implement Caching

```python
# Redis caching
import redis
from functools import wraps

redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)

def cache(ttl=300):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            cache_key = f"{func.__name__}:{str(args)}:{str(kwargs)}"

            # Try to get from cache
            cached = redis_client.get(cache_key)
            if cached:
                return json.loads(cached)

            # Execute function
            result = func(*args, **kwargs)

            # Store in cache
            redis_client.setex(cache_key, ttl, json.dumps(result))

            return result
        return wrapper
    return decorator

@cache(ttl=600)
def get_user_data(user_id):
    # Expensive database query
    return db.query(User).filter(User.id == user_id).first()
```

#### Solution 2: Optimize Database Queries

```python
# Use connection pooling
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20,
    pool_timeout=30,
    pool_recycle=1800
)

# Use indexes
# In migration
op.create_index('idx_user_email', 'users', ['email'])
op.create_index('idx_task_user_id', 'tasks', ['user_id'])

# Use eager loading to avoid N+1 queries
from sqlalchemy.orm import joinedload

users = session.query(User).options(joinedload(User.tasks)).all()
```

#### Solution 3: Implement Rate Limiting

```python
# FastAPI rate limiting
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.get("/api/data")
@limiter.limit("10/minute")
async def get_data(request: Request):
    return {"data": "value"}
```

---

### Issue 2: Auto-Scaling Not Working

**Symptoms:**
- Application doesn't scale up under load
- Too many instances running when idle
- Scaling is too slow

**Solutions:**

#### Solution 1: Configure Proper Scaling Metrics

```bash
# Azure Container Apps
az containerapp update \
  --name myapp \
  --resource-group myapp-rg \
  --min-replicas 2 \
  --max-replicas 10 \
  --scale-rule-name http-rule \
  --scale-rule-type http \
  --scale-rule-http-concurrency 50

# AWS ECS
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --resource-id service/myapp-cluster/myapp-service \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-name cpu-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://scaling-policy.json

# GCP Cloud Run
gcloud run services update myapp-backend \
  --region us-central1 \
  --min-instances 1 \
  --max-instances 10 \
  --concurrency 80
```

#### Solution 2: Optimize Cold Start Time

```python
# Minimize dependencies
# Use lazy loading for heavy imports
def get_ml_model():
    global _model
    if _model is None:
        import tensorflow as tf
        _model = tf.keras.models.load_model('model.h5')
    return _model

# Pre-warm connections
@app.on_event("startup")
async def startup():
    # Initialize database connection pool
    await database.connect()

    # Pre-load cache
    await load_cache()

    # Warm up external services
    await health_check_external_services()
```

---

## Best Practices

1. **Use infrastructure as code** (Terraform, CloudFormation) for reproducibility
2. **Implement comprehensive logging** with structured logs
3. **Set up monitoring and alerting** for all critical metrics
4. **Use health checks** for all services
5. **Implement graceful shutdown** to handle termination signals
6. **Use connection pooling** for databases and external services
7. **Implement retry logic** with exponential backoff
8. **Use circuit breakers** for external service calls
9. **Regular security updates** for base images and dependencies
10. **Document deployment procedures** and runbooks
