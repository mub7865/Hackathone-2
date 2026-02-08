# Performance Optimization Guide

**Version**: 1.0
**Last Updated**: 2026-01-12
**Target**: Production Performance

This guide provides strategies and techniques for optimizing the Todo Application's performance.

---

## Table of Contents

1. [Performance Goals](#performance-goals)
2. [Database Optimization](#database-optimization)
3. [API Optimization](#api-optimization)
4. [Frontend Optimization](#frontend-optimization)
5. [Caching Strategies](#caching-strategies)
6. [Event Streaming Optimization](#event-streaming-optimization)
7. [Infrastructure Optimization](#infrastructure-optimization)
8. [Load Testing](#load-testing)
9. [Performance Monitoring](#performance-monitoring)

---

## Performance Goals

### Target Metrics

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| P50 Response Time | < 200ms | TBD | 🎯 |
| P95 Response Time | < 500ms | TBD | 🎯 |
| P99 Response Time | < 1000ms | TBD | 🎯 |
| Throughput | 1000 req/s | TBD | 🎯 |
| Error Rate | < 1% | TBD | 🎯 |
| Availability | 99.9% | TBD | 🎯 |
| Database Query Time | < 50ms (P95) | TBD | 🎯 |
| Event Processing Time | < 100ms (P95) | TBD | 🎯 |

### Performance Budget

- **Page Load Time**: < 2 seconds (First Contentful Paint)
- **Time to Interactive**: < 3 seconds
- **API Response Time**: < 500ms (P95)
- **Database Query Time**: < 50ms (P95)
- **Event Processing Time**: < 100ms (P95)

---

## Database Optimization

### 1. Query Optimization

**Identify Slow Queries**:
```sql
-- Enable pg_stat_statements
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Find slow queries
SELECT
  query,
  mean_exec_time,
  calls,
  total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

**Analyze Query Plans**:
```sql
-- Explain query
EXPLAIN ANALYZE
SELECT * FROM tasks
WHERE user_id = 'user123'
  AND status = 'pending'
  AND priority = 'high'
ORDER BY due_date ASC;
```

**Optimization Techniques**:
- Use indexes for frequently queried columns
- Avoid SELECT *, specify needed columns
- Use LIMIT for pagination
- Avoid N+1 queries with eager loading
- Use database-level filtering instead of application-level

### 2. Indexing Strategy

**Create Indexes**:
```sql
-- User ID index (most common filter)
CREATE INDEX idx_tasks_user_id ON tasks(user_id);

-- Composite index for common query pattern
CREATE INDEX idx_tasks_user_status_priority
ON tasks(user_id, status, priority);

-- Due date index for sorting
CREATE INDEX idx_tasks_due_date ON tasks(due_date);

-- GIN index for array fields (tags)
CREATE INDEX idx_tasks_tags ON tasks USING GIN(tags);

-- Partial index for pending tasks
CREATE INDEX idx_tasks_pending
ON tasks(user_id, due_date)
WHERE status = 'pending';
```

**Index Maintenance**:
```sql
-- Check index usage
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;

-- Remove unused indexes
DROP INDEX IF EXISTS idx_unused_index;

-- Rebuild indexes
REINDEX TABLE tasks;
```

### 3. Connection Pooling

**Configure Pool Size**:
```python
# app/core/database.py

from sqlalchemy.ext.asyncio import create_async_engine

engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,              # Max connections in pool
    max_overflow=10,           # Additional connections when pool is full
    pool_timeout=30,           # Timeout waiting for connection
    pool_recycle=3600,         # Recycle connections after 1 hour
    pool_pre_ping=True,        # Verify connection before using
    echo=False,                # Disable SQL logging in production
)
```

**Monitor Connection Pool**:
```python
# Add metrics
from prometheus_client import Gauge

db_connections_active = Gauge('db_connections_active', 'Active database connections')
db_connections_idle = Gauge('db_connections_idle', 'Idle database connections')

# Update metrics
db_connections_active.set(engine.pool.size() - engine.pool.overflow())
db_connections_idle.set(engine.pool.overflow())
```

### 4. Query Caching

**Implement Query Result Caching**:
```python
from functools import lru_cache
from datetime import datetime, timedelta

# In-memory cache for frequently accessed data
@lru_cache(maxsize=1000)
def get_user_tasks_cached(user_id: str, cache_key: str):
    # cache_key includes timestamp to invalidate cache
    return get_user_tasks(user_id)

# Use with time-based cache key
cache_key = f"{user_id}_{datetime.now().minute // 5}"  # 5-minute cache
tasks = get_user_tasks_cached(user_id, cache_key)
```

### 5. Batch Operations

**Bulk Insert**:
```python
# Instead of individual inserts
for task_data in tasks_data:
    task = Task(**task_data)
    session.add(task)
    await session.commit()

# Use bulk insert
tasks = [Task(**data) for data in tasks_data]
session.add_all(tasks)
await session.commit()
```

**Bulk Update**:
```python
# Instead of individual updates
for task_id in task_ids:
    task = await session.get(Task, task_id)
    task.status = "completed"
    await session.commit()

# Use bulk update
await session.execute(
    update(Task)
    .where(Task.id.in_(task_ids))
    .values(status="completed")
)
await session.commit()
```

---

## API Optimization

### 1. Response Compression

**Enable Gzip Compression**:
```python
from fastapi.middleware.gzip import GZipMiddleware

app.add_middleware(GZipMiddleware, minimum_size=1000)
```

### 2. Pagination

**Implement Cursor-Based Pagination**:
```python
@router.get("/tasks")
async def list_tasks(
    cursor: Optional[str] = None,
    limit: int = Query(50, le=100),
    db: AsyncSession = Depends(get_db),
):
    query = select(Task).where(Task.user_id == user_id)

    if cursor:
        # Decode cursor (base64 encoded task_id)
        cursor_id = base64.b64decode(cursor).decode()
        query = query.where(Task.id > cursor_id)

    query = query.order_by(Task.id).limit(limit + 1)

    tasks = await db.execute(query)
    tasks = tasks.scalars().all()

    has_more = len(tasks) > limit
    if has_more:
        tasks = tasks[:limit]
        next_cursor = base64.b64encode(str(tasks[-1].id).encode()).decode()
    else:
        next_cursor = None

    return {
        "tasks": tasks,
        "next_cursor": next_cursor,
        "has_more": has_more
    }
```

### 3. Field Selection

**Allow Clients to Select Fields**:
```python
@router.get("/tasks")
async def list_tasks(
    fields: Optional[str] = Query(None, description="Comma-separated fields"),
    db: AsyncSession = Depends(get_db),
):
    if fields:
        field_list = [getattr(Task, f) for f in fields.split(",")]
        query = select(*field_list)
    else:
        query = select(Task)

    # Execute query
    tasks = await db.execute(query)
    return tasks.scalars().all()
```

### 4. Async Processing

**Offload Heavy Operations**:
```python
from fastapi import BackgroundTasks

@router.post("/tasks/{task_id}/complete")
async def complete_task(
    task_id: UUID,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
):
    # Update task immediately
    task = await db.get(Task, task_id)
    task.status = "completed"
    await db.commit()

    # Process side effects in background
    background_tasks.add_task(send_completion_notification, task_id)
    background_tasks.add_task(update_statistics, task.user_id)
    background_tasks.add_task(generate_recurring_task, task_id)

    return task
```

### 5. Request Batching

**Batch Multiple Requests**:
```python
@router.post("/tasks/batch")
async def batch_operations(
    operations: List[BatchOperation],
    db: AsyncSession = Depends(get_db),
):
    results = []
    for op in operations:
        if op.type == "create":
            result = await create_task(op.data, db)
        elif op.type == "update":
            result = await update_task(op.id, op.data, db)
        elif op.type == "delete":
            result = await delete_task(op.id, db)
        results.append(result)

    await db.commit()
    return results
```

---

## Frontend Optimization

### 1. Code Splitting

**Implement Route-Based Code Splitting**:
```typescript
// app/tasks/page.tsx
import dynamic from 'next/dynamic';

// Lazy load heavy components
const TaskList = dynamic(() => import('@/components/TaskList'), {
  loading: () => <TaskListSkeleton />,
  ssr: false
});

const AdvancedSearch = dynamic(() => import('@/components/AdvancedSearch'), {
  loading: () => <SearchSkeleton />
});
```

### 2. Image Optimization

**Use Next.js Image Component**:
```typescript
import Image from 'next/image';

<Image
  src="/avatar.jpg"
  alt="User avatar"
  width={40}
  height={40}
  priority={false}
  loading="lazy"
/>
```

### 3. Data Fetching Optimization

**Implement SWR for Caching**:
```typescript
import useSWR from 'swr';

function TaskList() {
  const { data, error, isLoading } = useSWR(
    '/api/v1/tasks',
    fetcher,
    {
      revalidateOnFocus: false,
      revalidateOnReconnect: false,
      dedupingInterval: 5000,  // 5 seconds
    }
  );

  if (isLoading) return <Skeleton />;
  if (error) return <Error />;

  return <Tasks tasks={data.tasks} />;
}
```

### 4. Virtual Scrolling

**Implement Virtual List for Large Lists**:
```typescript
import { FixedSizeList } from 'react-window';

function TaskList({ tasks }) {
  const Row = ({ index, style }) => (
    <div style={style}>
      <TaskItem task={tasks[index]} />
    </div>
  );

  return (
    <FixedSizeList
      height={600}
      itemCount={tasks.length}
      itemSize={80}
      width="100%"
    >
      {Row}
    </FixedSizeList>
  );
}
```

### 5. Debouncing and Throttling

**Debounce Search Input**:
```typescript
import { useDebouncedCallback } from 'use-debounce';

function SearchBar() {
  const debouncedSearch = useDebouncedCallback(
    (value) => {
      performSearch(value);
    },
    500  // 500ms delay
  );

  return (
    <input
      type="text"
      onChange={(e) => debouncedSearch(e.target.value)}
      placeholder="Search tasks..."
    />
  );
}
```

---

## Caching Strategies

### 1. Redis Caching

**Setup Redis**:
```python
from redis import asyncio as aioredis
import json

redis = await aioredis.from_url("redis://localhost:6379")

# Cache task list
async def get_user_tasks_cached(user_id: str):
    cache_key = f"tasks:{user_id}"

    # Try cache first
    cached = await redis.get(cache_key)
    if cached:
        return json.loads(cached)

    # Fetch from database
    tasks = await get_user_tasks(user_id)

    # Cache for 5 minutes
    await redis.setex(
        cache_key,
        300,
        json.dumps([task.dict() for task in tasks])
    )

    return tasks

# Invalidate cache on update
async def update_task(task_id: UUID, data: dict):
    task = await db.get(Task, task_id)
    # Update task...
    await db.commit()

    # Invalidate cache
    await redis.delete(f"tasks:{task.user_id}")
```

### 2. HTTP Caching

**Set Cache Headers**:
```python
from fastapi import Response

@router.get("/tasks/{task_id}")
async def get_task(task_id: UUID, response: Response):
    task = await db.get(Task, task_id)

    # Set cache headers
    response.headers["Cache-Control"] = "private, max-age=300"  # 5 minutes
    response.headers["ETag"] = f'"{task.updated_at.timestamp()}"'

    return task
```

### 3. CDN Caching

**Configure CDN for Static Assets**:
```typescript
// next.config.js
module.exports = {
  images: {
    domains: ['cdn.todo-app.example.com'],
  },
  assetPrefix: process.env.NODE_ENV === 'production'
    ? 'https://cdn.todo-app.example.com'
    : '',
};
```

---

## Event Streaming Optimization

### 1. Batch Event Processing

**Process Events in Batches**:
```python
async def consume_events_batch():
    batch = []
    batch_size = 100

    async for message in consumer:
        batch.append(message.value)

        if len(batch) >= batch_size:
            await process_batch(batch)
            batch = []

    # Process remaining
    if batch:
        await process_batch(batch)

async def process_batch(events: List[dict]):
    # Process all events in single database transaction
    async with db.begin():
        for event in events:
            await process_event(event)
```

### 2. Parallel Consumer Instances

**Scale Consumers Horizontally**:
```yaml
# k8s/event-consumer-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: event-consumer
spec:
  replicas: 3  # Multiple consumer instances
  template:
    spec:
      containers:
      - name: consumer
        image: todo-backend:latest
        command: ["python", "-m", "app.events.consumers.main"]
```

### 3. Consumer Lag Monitoring

**Monitor and Alert on Lag**:
```python
from prometheus_client import Gauge

consumer_lag = Gauge(
    'kafka_consumer_lag',
    'Consumer lag in messages',
    ['topic', 'partition', 'consumer_group']
)

# Update lag metric
lag = await get_consumer_lag()
consumer_lag.labels(
    topic='task-events',
    partition='0',
    consumer_group='task-consumer-group'
).set(lag)
```

---

## Infrastructure Optimization

### 1. Horizontal Pod Autoscaling

**Configure HPA**:
```yaml
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
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
```

### 2. Resource Limits

**Set Appropriate Limits**:
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### 3. Readiness and Liveness Probes

**Configure Health Checks**:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

---

## Load Testing

### 1. k6 Load Testing

**Create Load Test Script**:
```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 100 },   // Ramp up to 100 users
    { duration: '5m', target: 100 },   // Stay at 100 users
    { duration: '2m', target: 200 },   // Ramp up to 200 users
    { duration: '5m', target: 200 },   // Stay at 200 users
    { duration: '2m', target: 0 },     // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests < 500ms
    http_req_failed: ['rate<0.01'],    // Error rate < 1%
  },
};

export default function () {
  // Login
  let loginRes = http.post('http://localhost:8000/api/v1/auth/login', {
    email: 'test@example.com',
    password: 'password123',
  });

  check(loginRes, {
    'login successful': (r) => r.status === 200,
  });

  let token = loginRes.json('access_token');

  // List tasks
  let tasksRes = http.get('http://localhost:8000/api/v1/tasks', {
    headers: { Authorization: `Bearer ${token}` },
  });

  check(tasksRes, {
    'tasks retrieved': (r) => r.status === 200,
    'response time OK': (r) => r.timings.duration < 500,
  });

  sleep(1);
}
```

**Run Load Test**:
```bash
k6 run load-test.js
```

### 2. Locust Load Testing

**Create Locust Test**:
```python
# locustfile.py
from locust import HttpUser, task, between

class TodoUser(HttpUser):
    wait_time = between(1, 3)

    def on_start(self):
        # Login
        response = self.client.post("/api/v1/auth/login", json={
            "email": "test@example.com",
            "password": "password123"
        })
        self.token = response.json()["access_token"]
        self.headers = {"Authorization": f"Bearer {self.token}"}

    @task(3)
    def list_tasks(self):
        self.client.get("/api/v1/tasks", headers=self.headers)

    @task(1)
    def create_task(self):
        self.client.post("/api/v1/tasks", headers=self.headers, json={
            "title": "Load test task",
            "priority": "medium"
        })

    @task(1)
    def get_task(self):
        # Assume task_id is known
        self.client.get(f"/api/v1/tasks/{task_id}", headers=self.headers)
```

**Run Locust**:
```bash
locust -f locustfile.py --host=http://localhost:8000
```

---

## Performance Monitoring

### 1. Application Performance Monitoring (APM)

**Integrate New Relic** (optional):
```python
import newrelic.agent

newrelic.agent.initialize('newrelic.ini')

@newrelic.agent.background_task()
async def process_event(event):
    # Process event
    pass
```

### 2. Profiling

**Profile Python Code**:
```python
import cProfile
import pstats

# Profile function
profiler = cProfile.Profile()
profiler.enable()

# Run code
await process_tasks()

profiler.disable()
stats = pstats.Stats(profiler)
stats.sort_stats('cumulative')
stats.print_stats(20)
```

### 3. Database Query Profiling

**Enable Query Logging**:
```python
import logging

logging.basicConfig()
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)
```

---

## Performance Checklist

### Backend
- [ ] Database indexes created for common queries
- [ ] Connection pooling configured
- [ ] Query result caching implemented
- [ ] Batch operations used where possible
- [ ] Response compression enabled
- [ ] Pagination implemented
- [ ] Async processing for heavy operations
- [ ] Background tasks for non-critical operations

### Frontend
- [ ] Code splitting implemented
- [ ] Images optimized
- [ ] Data fetching optimized with SWR
- [ ] Virtual scrolling for large lists
- [ ] Debouncing/throttling for user input
- [ ] Lazy loading for components
- [ ] Bundle size optimized

### Infrastructure
- [ ] Horizontal pod autoscaling configured
- [ ] Resource limits set appropriately
- [ ] Health checks configured
- [ ] CDN configured for static assets
- [ ] Load balancer configured
- [ ] Caching layer (Redis) deployed

### Monitoring
- [ ] Performance metrics collected
- [ ] Alerts configured for performance issues
- [ ] Load testing performed
- [ ] Profiling done for bottlenecks
- [ ] APM tool integrated (optional)

---

## Performance Optimization Workflow

1. **Measure**: Establish baseline metrics
2. **Identify**: Find bottlenecks with profiling
3. **Optimize**: Implement optimizations
4. **Test**: Verify improvements with load testing
5. **Monitor**: Track metrics in production
6. **Iterate**: Continuously improve

---

## Resources

- [FastAPI Performance](https://fastapi.tiangolo.com/deployment/concepts/)
- [Next.js Performance](https://nextjs.org/docs/advanced-features/measuring-performance)
- [PostgreSQL Performance](https://www.postgresql.org/docs/current/performance-tips.html)
- [Kubernetes Performance](https://kubernetes.io/docs/concepts/cluster-administration/system-metrics/)
- [k6 Documentation](https://k6.io/docs/)

---

**Remember**: Premature optimization is the root of all evil. Always measure before optimizing!
