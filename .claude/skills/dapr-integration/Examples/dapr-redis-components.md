# Redis-Based Dapr Components Setup

This guide shows how to configure Dapr components using Redis as the backend for pub/sub, state management, and more.

## Why Redis?

Redis is a popular choice for Dapr components because:
- **Fast**: In-memory data store with microsecond latency
- **Simple**: Easy to set up and configure
- **Versatile**: Supports pub/sub, state, and caching
- **Reliable**: Battle-tested in production
- **Free**: Open source with managed options available

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Your Application                      │
│  ┌──────────────┐         ┌──────────────┐             │
│  │   Service A  │────────▶│ Dapr Sidecar │             │
│  │   (8000)     │◀────────│   (3500)     │             │
│  └──────────────┘         └──────────────┘             │
│                                   │                      │
│                                   │ Dapr API             │
│                                   ▼                      │
│                            ┌──────────────┐             │
│                            │    Redis     │             │
│                            │   (6379)     │             │
│                            └──────────────┘             │
│                                   │                      │
│                            ┌──────┴──────┐              │
│                            │             │              │
│                      ┌─────▼─────┐ ┌────▼─────┐        │
│                      │  Pub/Sub  │ │  State   │        │
│                      │  Channel  │ │  Store   │        │
│                      └───────────┘ └──────────┘        │
└─────────────────────────────────────────────────────────┘
```

## Setup Options

### Option 1: Local Redis (Development)

#### Install Redis

**macOS:**
```bash
brew install redis
brew services start redis
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install redis-server
sudo systemctl start redis-server
```

**Windows:**
```bash
# Use Docker
docker run -d -p 6379:6379 --name redis redis:7-alpine
```

**Docker Compose:**
```yaml
version: '3.8'
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes

volumes:
  redis-data:
```

#### Verify Redis

```bash
# Test connection
redis-cli ping
# Expected: PONG

# Check info
redis-cli info server
```

### Option 2: Dapr Init Redis (Easiest)

When you run `dapr init`, it automatically installs Redis in Docker:

```bash
dapr init

# Redis is now available at localhost:6379
docker ps | grep redis
```

### Option 3: Cloud Redis (Production)

**Redis Cloud (Free Tier):**
- Sign up at https://redis.com/try-free/
- Create database
- Get connection string

**AWS ElastiCache:**
```bash
# Create Redis cluster
aws elasticache create-cache-cluster \
  --cache-cluster-id my-redis \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --num-cache-nodes 1
```

**Azure Cache for Redis:**
```bash
# Create Redis cache
az redis create \
  --name my-redis \
  --resource-group my-rg \
  --location eastus \
  --sku Basic \
  --vm-size c0
```

**GCP Memorystore:**
```bash
# Create Redis instance
gcloud redis instances create my-redis \
  --size=1 \
  --region=us-central1 \
  --tier=basic
```

## Component Configurations

### 1. Pub/Sub Component

**components/pubsub.yaml**
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub
spec:
  type: pubsub.redis
  version: v1
  metadata:
  # Connection
  - name: redisHost
    value: localhost:6379
  - name: redisPassword
    value: ""
  - name: enableTLS
    value: "false"

  # Consumer settings
  - name: consumerID
    value: "{podName}"  # Unique per instance
  - name: redeliverInterval
    value: "60s"  # Retry failed messages after 60s
  - name: processingTimeout
    value: "60s"  # Max time to process message
  - name: queueDepth
    value: "100"  # Max messages in queue
  - name: concurrency
    value: "10"  # Parallel message processing

  # Performance
  - name: maxRetries
    value: "3"
  - name: maxRetryBackoff
    value: "30s"
```

**How it works:**
- Messages published to topics are stored in Redis streams
- Each consumer group gets its own copy of messages
- Redis handles message delivery and acknowledgment
- Failed messages are automatically retried

### 2. State Store Component

**components/statestore.yaml**
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
spec:
  type: state.redis
  version: v1
  metadata:
  # Connection
  - name: redisHost
    value: localhost:6379
  - name: redisPassword
    value: ""
  - name: enableTLS
    value: "false"

  # State settings
  - name: actorStateStore
    value: "true"  # Enable for actor state
  - name: keyPrefix
    value: "myapp"  # Prefix all keys
  - name: ttlInSeconds
    value: ""  # Default TTL (empty = no expiration)

  # Performance
  - name: maxRetries
    value: "3"
  - name: maxRetryBackoff
    value: "2s"
  - name: redisType
    value: "node"  # or "cluster"
  - name: redisDB
    value: "0"  # Redis database number
```

**How it works:**
- State is stored as key-value pairs in Redis
- Supports transactions for atomic operations
- ETags for optimistic concurrency control
- TTL for automatic expiration

### 3. Production Configuration with TLS

**components/pubsub-prod.yaml**
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub
spec:
  type: pubsub.redis
  version: v1
  metadata:
  - name: redisHost
    value: my-redis.redis.cache.windows.net:6380
  - name: redisPassword
    secretKeyRef:
      name: redis-secret
      key: password
  - name: enableTLS
    value: "true"
  - name: consumerID
    value: "{podName}"
  - name: redeliverInterval
    value: "30s"
  - name: processingTimeout
    value: "120s"
  - name: queueDepth
    value: "1000"
  - name: concurrency
    value: "50"
auth:
  secretStore: kubernetes-secret-store
```

### 4. Redis Cluster Configuration

**components/statestore-cluster.yaml**
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
spec:
  type: state.redis
  version: v1
  metadata:
  - name: redisHost
    value: "redis-node1:6379,redis-node2:6379,redis-node3:6379"
  - name: redisPassword
    secretKeyRef:
      name: redis-secret
      key: password
  - name: redisType
    value: "cluster"
  - name: enableTLS
    value: "true"
  - name: actorStateStore
    value: "true"
```

## Testing Components

### Test Pub/Sub

```python
from dapr.clients import DaprClient
import json

# Publish message
with DaprClient() as client:
    client.publish_event(
        pubsub_name='pubsub',
        topic_name='test-topic',
        data=json.dumps({'message': 'Hello Redis!'})
    )
    print("Message published")

# Verify in Redis
# redis-cli
# > XREAD STREAMS test-topic 0
```

### Test State Store

```python
from dapr.clients import DaprClient

# Save state
with DaprClient() as client:
    client.save_state(
        store_name='statestore',
        key='test-key',
        value='test-value'
    )
    print("State saved")

# Get state
with DaprClient() as client:
    state = client.get_state(
        store_name='statestore',
        key='test-key'
    )
    print(f"State: {state.data.decode('utf-8')}")

# Verify in Redis
# redis-cli
# > GET myapp||test-key
```

## Redis CLI Commands

### Monitor Pub/Sub

```bash
# Monitor all Redis commands
redis-cli MONITOR

# List streams (topics)
redis-cli XINFO STREAMS

# Read from stream
redis-cli XREAD STREAMS my-topic 0

# Get stream info
redis-cli XINFO STREAM my-topic
```

### Monitor State

```bash
# List all keys
redis-cli KEYS "*"

# Get specific key
redis-cli GET "myapp||user:123"

# Get key with TTL
redis-cli TTL "myapp||session:abc"

# Delete key
redis-cli DEL "myapp||test-key"
```

### Performance Monitoring

```bash
# Get Redis info
redis-cli INFO

# Monitor memory usage
redis-cli INFO memory

# Monitor connected clients
redis-cli CLIENT LIST

# Get slow queries
redis-cli SLOWLOG GET 10
```

## Performance Tuning

### Redis Configuration

**redis.conf**
```conf
# Memory
maxmemory 2gb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfsync everysec

# Performance
tcp-backlog 511
timeout 0
tcp-keepalive 300
```

### Dapr Component Tuning

```yaml
metadata:
  # Increase concurrency for high throughput
  - name: concurrency
    value: "100"

  # Reduce processing timeout for faster retries
  - name: processingTimeout
    value: "30s"

  # Increase queue depth for burst traffic
  - name: queueDepth
    value: "1000"

  # Faster redelivery for failed messages
  - name: redeliverInterval
    value: "10s"
```

## Monitoring

### Redis Metrics

```bash
# Get stats
redis-cli INFO stats

# Key metrics:
# - total_commands_processed
# - instantaneous_ops_per_sec
# - used_memory_human
# - connected_clients
# - evicted_keys
```

### Dapr Metrics

```bash
# Dapr exposes Prometheus metrics
curl http://localhost:9090/metrics | grep redis

# Key metrics:
# - dapr_component_pubsub_ingress_count
# - dapr_component_pubsub_egress_count
# - dapr_component_state_count
```

## Troubleshooting

### Connection Issues

```bash
# Test Redis connection
redis-cli -h localhost -p 6379 ping

# Check if Redis is running
ps aux | grep redis

# Check Redis logs
tail -f /var/log/redis/redis-server.log
```

### Performance Issues

```bash
# Check slow queries
redis-cli SLOWLOG GET 10

# Monitor commands in real-time
redis-cli MONITOR

# Check memory usage
redis-cli INFO memory
```

### Data Issues

```bash
# Check if key exists
redis-cli EXISTS "myapp||user:123"

# Get key type
redis-cli TYPE "myapp||user:123"

# Check TTL
redis-cli TTL "myapp||session:abc"
```

## Best Practices

1. **Use key prefixes** - Organize keys by app/environment
2. **Set TTLs** - Prevent memory leaks with automatic expiration
3. **Enable persistence** - Use AOF for durability
4. **Monitor memory** - Set maxmemory and eviction policy
5. **Use connection pooling** - Reuse Redis connections
6. **Enable TLS** - Encrypt data in transit for production
7. **Use Redis Cluster** - Scale horizontally for high throughput
8. **Monitor metrics** - Track performance and errors

## Migration from Other Backends

### From Kafka to Redis Pub/Sub

```yaml
# Before (Kafka)
spec:
  type: pubsub.kafka
  metadata:
  - name: brokers
    value: localhost:9092

# After (Redis)
spec:
  type: pubsub.redis
  metadata:
  - name: redisHost
    value: localhost:6379
```

### From PostgreSQL to Redis State

```yaml
# Before (PostgreSQL)
spec:
  type: state.postgresql
  metadata:
  - name: connectionString
    value: "host=localhost user=postgres..."

# After (Redis)
spec:
  type: state.redis
  metadata:
  - name: redisHost
    value: localhost:6379
```

## Resources

- [Redis Documentation](https://redis.io/documentation)
- [Dapr Redis Pub/Sub](https://docs.dapr.io/reference/components-reference/supported-pubsub/setup-redis-pubsub/)
- [Dapr Redis State Store](https://docs.dapr.io/reference/components-reference/supported-state-stores/setup-redis/)
- [Redis Best Practices](https://redis.io/docs/manual/patterns/)
