# Monitoring and Troubleshooting Guide: Cloud-Native Event-Driven Todo Application

**Version**: 1.0
**Last Updated**: 2026-01-12
**Target Audience**: DevOps Engineers, SREs, System Administrators

---

## Table of Contents

1. [Monitoring Overview](#monitoring-overview)
2. [Prometheus Metrics](#prometheus-metrics)
3. [Grafana Dashboards](#grafana-dashboards)
4. [Alerting Rules](#alerting-rules)
5. [Log Analysis](#log-analysis)
6. [Performance Monitoring](#performance-monitoring)
7. [Troubleshooting Guide](#troubleshooting-guide)
8. [Common Issues](#common-issues)
9. [Runbooks](#runbooks)

---

## Monitoring Overview

The Todo Application uses a comprehensive monitoring stack:

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert routing and notification
- **Structured Logging**: JSON logs for analysis

### Monitoring Architecture

```
Application → Metrics Endpoint (/metrics) → Prometheus → Grafana
                                                ↓
                                          Alertmanager → Notifications
```

### Key Monitoring Areas

1. **Application Health**: Request rate, latency, error rate
2. **Database Performance**: Query latency, connection pool usage
3. **Event Streaming**: Kafka throughput, consumer lag
4. **WebSocket Connections**: Active connections, disconnection rate
5. **Business Metrics**: Active users, tasks completed
6. **Infrastructure**: CPU, memory, disk usage

---

## Prometheus Metrics

### Accessing Prometheus

```bash
# Port forward to Prometheus
kubectl port-forward svc/prometheus 9090:9090

# Open in browser
http://localhost:9090
```

### Application Metrics

#### HTTP Metrics

**http_requests_total**
- Type: Counter
- Labels: method, endpoint, status
- Description: Total HTTP requests
- Query: `rate(http_requests_total[5m])`

**http_request_duration_seconds**
- Type: Histogram
- Labels: method, endpoint
- Description: HTTP request latency
- Query: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`

**http_requests_in_progress**
- Type: Gauge
- Labels: method, endpoint
- Description: In-flight HTTP requests
- Query: `http_requests_in_progress`

#### Task Operation Metrics

**task_operations_total**
- Type: Counter
- Labels: operation, status
- Description: Total task operations
- Query: `rate(task_operations_total[5m])`

**task_operations_duration_seconds**
- Type: Histogram
- Labels: operation
- Description: Task operation latency
- Query: `histogram_quantile(0.95, rate(task_operations_duration_seconds_bucket[5m]))`

**tasks_total**
- Type: Gauge
- Labels: user_id, status
- Description: Total tasks by status
- Query: `sum(tasks_total) by (status)`

**tasks_by_priority**
- Type: Gauge
- Labels: priority
- Description: Tasks by priority
- Query: `sum(tasks_by_priority) by (priority)`

#### Event Streaming Metrics

**events_published_total**
- Type: Counter
- Labels: event_type, topic
- Description: Total events published
- Query: `rate(events_published_total[5m])`

**events_publish_failures_total**
- Type: Counter
- Labels: topic, error
- Description: Event publish failures
- Query: `rate(events_publish_failures_total[5m])`

**events_consumed_total**
- Type: Counter
- Labels: event_type, consumer_group
- Description: Total events consumed
- Query: `rate(events_consumed_total[5m])`

**events_consumption_failures_total**
- Type: Counter
- Labels: consumer_group, error
- Description: Event consumption failures
- Query: `rate(events_consumption_failures_total[5m])`

**events_duplicate_total**
- Type: Counter
- Labels: consumer_group, event_type
- Description: Duplicate events detected
- Query: `rate(events_duplicate_total[5m])`

#### Database Metrics

**db_queries_total**
- Type: Counter
- Labels: operation, table
- Description: Total database queries
- Query: `rate(db_queries_total[5m])`

**db_query_duration_seconds**
- Type: Histogram
- Labels: operation, table
- Description: Database query latency
- Query: `histogram_quantile(0.95, rate(db_query_duration_seconds_bucket[5m]))`

**db_connections_active**
- Type: Gauge
- Description: Active database connections
- Query: `db_connections_active`

**db_connections_idle**
- Type: Gauge
- Description: Idle database connections
- Query: `db_connections_idle`

#### WebSocket Metrics

**websocket_connections_active**
- Type: Gauge
- Description: Active WebSocket connections
- Query: `websocket_connections_active`

**websocket_connections_total**
- Type: Counter
- Labels: status
- Description: Total WebSocket connections
- Query: `rate(websocket_connections_total[5m])`

**websocket_messages_sent_total**
- Type: Counter
- Labels: message_type
- Description: WebSocket messages sent
- Query: `rate(websocket_messages_sent_total[5m])`

#### Notification Metrics

**notifications_sent_total**
- Type: Counter
- Labels: channel, notification_type
- Description: Notifications sent
- Query: `rate(notifications_sent_total[5m])`

**notifications_failed_total**
- Type: Counter
- Labels: channel, error
- Description: Notification failures
- Query: `rate(notifications_failed_total[5m])`

**notifications_rate_limited_total**
- Type: Counter
- Description: Rate-limited notifications
- Query: `rate(notifications_rate_limited_total[5m])`

#### Business Metrics

**users_active_total**
- Type: Gauge
- Description: Active users
- Query: `users_active_total`

**tasks_completed_today**
- Type: Gauge
- Description: Tasks completed today
- Query: `tasks_completed_today`

**recurring_patterns_active**
- Type: Gauge
- Description: Active recurring patterns
- Query: `recurring_patterns_active`

### Useful PromQL Queries

#### Error Rate
```promql
# Overall error rate
sum(rate(http_requests_total{status="error"}[5m])) / sum(rate(http_requests_total[5m]))

# Error rate by endpoint
sum(rate(http_requests_total{status="error"}[5m])) by (endpoint) / sum(rate(http_requests_total[5m])) by (endpoint)
```

#### Latency Percentiles
```promql
# P50 latency
histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))

# P95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# P99 latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

#### Request Rate
```promql
# Requests per second
sum(rate(http_requests_total[5m]))

# Requests per second by endpoint
sum(rate(http_requests_total[5m])) by (endpoint)
```

#### Database Connection Pool Usage
```promql
# Connection pool utilization
db_connections_active / (db_connections_active + db_connections_idle)
```

#### Event Consumer Lag
```promql
# Consumer lag (requires Kafka exporter)
kafka_consumergroup_lag{consumergroup="task-consumer-group"}
```

---

## Grafana Dashboards

### Accessing Grafana

```bash
# Port forward to Grafana
kubectl port-forward svc/grafana 3000:3000

# Open in browser
http://localhost:3000

# Login credentials
Username: admin
Password: admin123
```

### Available Dashboards

#### 1. Todo App Overview

**Purpose**: High-level application health and performance

**Panels**:
- HTTP Request Rate (graph)
- HTTP Request Latency P95 (graph)
- Task Operations (graph)
- Active Tasks by Status (pie chart)
- Event Publishing Rate (graph)
- Event Consumption Rate (graph)
- Database Query Latency P95 (graph)
- Database Connections (graph)
- WebSocket Connections (stat)
- Active Users (stat)
- Tasks Completed Today (stat)
- Notification Success Rate (gauge)

**Key Metrics**:
- Request rate should be steady during business hours
- P95 latency should be < 500ms
- Error rate should be < 1%
- Database connections should be < 80% of pool size

**Alerts**:
- High error rate (> 5%)
- High latency (P95 > 1s)
- Service down

#### 2. Event Streaming Metrics

**Purpose**: Monitor Kafka event processing

**Panels**:
- Event Publishing Rate by Topic (graph)
- Event Publish Failures (graph)
- Event Consumption Rate by Consumer Group (graph)
- Duplicate Events Detected (graph)
- Event Publish Latency P95 (graph)
- Event Consumption Latency P95 (graph)

**Key Metrics**:
- Publish rate should match consumption rate
- Failure rate should be < 1%
- Duplicate rate should be < 10%
- Consumer lag should be < 1000 messages

**Alerts**:
- High publish failure rate (> 1%)
- High consumption failure rate (> 1%)
- Kafka down

#### 3. Dapr Metrics

**Purpose**: Monitor Dapr sidecar performance

**Panels**:
- Dapr HTTP Request Rate (graph)
- Dapr Pub/Sub Messages (graph)
- Dapr Service Invocations (graph)
- Dapr Sidecar Resource Usage (graph)

**Key Metrics**:
- Dapr sidecar should be healthy
- Pub/sub latency should be < 1000ms
- Service invocation failure rate should be < 5%

**Alerts**:
- Dapr sidecar down
- High pub/sub latency
- High service invocation failure rate

### Creating Custom Dashboards

```json
{
  "dashboard": {
    "title": "Custom Dashboard",
    "panels": [
      {
        "title": "Custom Metric",
        "type": "graph",
        "targets": [
          {
            "expr": "your_promql_query_here"
          }
        ]
      }
    ]
  }
}
```

---

## Alerting Rules

### Alert Severity Levels

- **Critical**: Immediate action required (paging)
- **Warning**: Investigation needed (email/Slack)
- **Info**: Informational (logging only)

### Application Health Alerts

#### HighErrorRate
- **Severity**: Warning
- **Condition**: Error rate > 5% for 5 minutes
- **Action**: Check application logs, investigate failing endpoints

#### CriticalErrorRate
- **Severity**: Critical
- **Condition**: Error rate > 10% for 2 minutes
- **Action**: Immediate investigation, consider rollback

#### HighLatency
- **Severity**: Warning
- **Condition**: P95 latency > 1s for 5 minutes
- **Action**: Check database queries, review slow endpoints

#### ServiceDown
- **Severity**: Critical
- **Condition**: Service unreachable for 1 minute
- **Action**: Check pod status, review logs, restart if needed

### Database Health Alerts

#### HighDatabaseLatency
- **Severity**: Warning
- **Condition**: P95 query latency > 0.5s for 5 minutes
- **Action**: Review slow queries, check database load

#### DatabaseConnectionPoolExhausted
- **Severity**: Warning
- **Condition**: > 90% connections in use for 5 minutes
- **Action**: Increase pool size or investigate connection leaks

#### DatabaseDown
- **Severity**: Critical
- **Condition**: Database unreachable for 1 minute
- **Action**: Check database pod, verify connectivity

### Event Streaming Alerts

#### HighEventPublishFailureRate
- **Severity**: Warning
- **Condition**: Publish failure rate > 1% for 5 minutes
- **Action**: Check Kafka connectivity, review producer logs

#### HighEventConsumptionFailureRate
- **Severity**: Warning
- **Condition**: Consumption failure rate > 1% for 5 minutes
- **Action**: Check consumer logs, verify event schemas

#### KafkaDown
- **Severity**: Critical
- **Condition**: Kafka unreachable for 1 minute
- **Action**: Check Kafka pod, verify ZooKeeper

### Configuring Alertmanager

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'severity']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default'
  routes:
  - match:
      severity: critical
    receiver: 'pagerduty'
  - match:
      severity: warning
    receiver: 'slack'

receivers:
- name: 'default'
  email_configs:
  - to: 'team@example.com'

- name: 'pagerduty'
  pagerduty_configs:
  - service_key: 'YOUR_PAGERDUTY_KEY'

- name: 'slack'
  slack_configs:
  - api_url: 'YOUR_SLACK_WEBHOOK'
    channel: '#alerts'
```

---

## Log Analysis

### Log Format

All logs are structured JSON:

```json
{
  "timestamp": "2026-01-12T10:00:00.000Z",
  "level": "INFO",
  "logger": "app.api.v1.tasks",
  "message": "Task created",
  "task_id": "123e4567-e89b-12d3-a456-426614174000",
  "user_id": "user123",
  "correlation_id": "abc12345-e89b-12d3-a456-426614174001"
}
```

### Viewing Logs

```bash
# Backend logs
kubectl logs -l app=backend -f

# Frontend logs
kubectl logs -l app=frontend -f

# Kafka logs
kubectl logs -l app=kafka -f

# Filter by level
kubectl logs -l app=backend | grep '"level":"ERROR"'

# Follow specific pod
kubectl logs backend-deployment-abc123 -f
```

### Log Levels

- **DEBUG**: Detailed debugging information
- **INFO**: General informational messages
- **WARNING**: Warning messages
- **ERROR**: Error messages
- **CRITICAL**: Critical errors requiring immediate attention

### Common Log Patterns

#### Successful Request
```json
{
  "level": "INFO",
  "message": "Request completed",
  "method": "GET",
  "path": "/api/v1/tasks",
  "status_code": 200,
  "duration_ms": 45.2
}
```

#### Error
```json
{
  "level": "ERROR",
  "message": "Database query failed",
  "error": "connection timeout",
  "query": "SELECT * FROM tasks WHERE user_id = $1",
  "correlation_id": "abc12345"
}
```

#### Event Processing
```json
{
  "level": "INFO",
  "message": "Event processed",
  "event_type": "task.created",
  "event_id": "def45678",
  "consumer_group": "task-consumer-group",
  "duration_ms": 123.4
}
```

---

## Performance Monitoring

### Key Performance Indicators (KPIs)

#### Response Time
- **Target**: P95 < 500ms, P99 < 1000ms
- **Measurement**: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`

#### Throughput
- **Target**: 1000 requests/second
- **Measurement**: `sum(rate(http_requests_total[5m]))`

#### Error Rate
- **Target**: < 1%
- **Measurement**: `sum(rate(http_requests_total{status="error"}[5m])) / sum(rate(http_requests_total[5m]))`

#### Availability
- **Target**: 99.9% (SLA)
- **Measurement**: Uptime monitoring

### Performance Optimization

#### Database Optimization
```bash
# Check slow queries
kubectl exec postgres-0 -- psql -U postgres -d todo_db -c "
  SELECT query, mean_exec_time, calls
  FROM pg_stat_statements
  ORDER BY mean_exec_time DESC
  LIMIT 10;
"

# Analyze query plan
kubectl exec postgres-0 -- psql -U postgres -d todo_db -c "
  EXPLAIN ANALYZE SELECT * FROM tasks WHERE user_id = 'user123';
"
```

#### Connection Pool Tuning
```python
# Increase pool size if needed
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=10
```

#### Caching Strategy
```python
# Implement Redis caching for frequently accessed data
from redis import Redis

redis_client = Redis(host='redis', port=6379)

# Cache task list
cache_key = f"tasks:{user_id}"
cached_tasks = redis_client.get(cache_key)
if cached_tasks:
    return json.loads(cached_tasks)

# Fetch from database and cache
tasks = await db.execute(query)
redis_client.setex(cache_key, 300, json.dumps(tasks))  # 5 min TTL
```

---

## Troubleshooting Guide

### Diagnostic Commands

```bash
# Check pod status
kubectl get pods

# Describe pod for events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name> -f
kubectl logs <pod-name> --previous  # Previous container

# Execute commands in pod
kubectl exec -it <pod-name> -- /bin/bash

# Check resource usage
kubectl top pods
kubectl top nodes

# Check services
kubectl get services

# Check ingress
kubectl get ingress
kubectl describe ingress <ingress-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Health Checks

```bash
# Backend health
curl http://backend-url/health

# Frontend health
curl http://frontend-url/

# Database health
kubectl exec postgres-0 -- pg_isready

# Kafka health
kubectl exec kafka-0 -- kafka-broker-api-versions --bootstrap-server localhost:9092
```

---

## Common Issues

### Issue 1: High Error Rate

**Symptoms**:
- Error rate > 5%
- Alert: HighErrorRate

**Diagnosis**:
```bash
# Check error logs
kubectl logs -l app=backend | grep '"level":"ERROR"'

# Check error rate by endpoint
# In Prometheus:
sum(rate(http_requests_total{status="error"}[5m])) by (endpoint)
```

**Solutions**:
1. Identify failing endpoint
2. Check database connectivity
3. Verify external service availability
4. Review recent code changes
5. Consider rollback if issue persists

### Issue 2: High Latency

**Symptoms**:
- P95 latency > 1s
- Alert: HighLatency

**Diagnosis**:
```bash
# Check slow endpoints
# In Prometheus:
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) by (endpoint)

# Check database query latency
histogram_quantile(0.95, rate(db_query_duration_seconds_bucket[5m]))
```

**Solutions**:
1. Identify slow endpoints
2. Review database queries
3. Check for N+1 query problems
4. Add database indexes
5. Implement caching
6. Scale horizontally

### Issue 3: Database Connection Pool Exhausted

**Symptoms**:
- Connection errors in logs
- Alert: DatabaseConnectionPoolExhausted

**Diagnosis**:
```bash
# Check connection pool usage
# In Prometheus:
db_connections_active / (db_connections_active + db_connections_idle)

# Check for connection leaks
kubectl logs -l app=backend | grep "connection"
```

**Solutions**:
1. Increase pool size
2. Check for connection leaks
3. Reduce connection timeout
4. Review long-running queries
5. Implement connection pooling best practices

### Issue 4: Kafka Consumer Lag

**Symptoms**:
- Events not being processed
- High consumer lag

**Diagnosis**:
```bash
# Check consumer lag
kubectl exec kafka-0 -- kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group task-consumer-group

# Check consumer logs
kubectl logs -l app=backend | grep "consumer"
```

**Solutions**:
1. Increase consumer instances
2. Optimize event processing
3. Check for slow database queries in consumers
4. Verify consumer is running
5. Check for errors in consumer logs

### Issue 5: WebSocket Disconnections

**Symptoms**:
- High disconnection rate
- Alert: HighWebSocketDisconnectionRate

**Diagnosis**:
```bash
# Check WebSocket metrics
# In Prometheus:
rate(websocket_connections_total{status="disconnected"}[5m])

# Check logs
kubectl logs -l app=backend | grep "websocket"
```

**Solutions**:
1. Check network stability
2. Implement reconnection logic in frontend
3. Increase WebSocket timeout
4. Review load balancer configuration
5. Check for memory leaks

---

## Runbooks

### Runbook: Service Down

**Alert**: ServiceDown

**Steps**:
1. Check pod status: `kubectl get pods -l app=backend`
2. If pod is not running:
   - Check events: `kubectl describe pod <pod-name>`
   - Check logs: `kubectl logs <pod-name> --previous`
   - Restart pod: `kubectl delete pod <pod-name>`
3. If pod is running but unhealthy:
   - Check health endpoint: `curl http://backend-url/health`
   - Check logs: `kubectl logs <pod-name> -f`
   - Check database connectivity
   - Check Kafka connectivity
4. If issue persists:
   - Rollback deployment: `kubectl rollout undo deployment/backend`
   - Escalate to on-call engineer

### Runbook: Database Down

**Alert**: DatabaseDown

**Steps**:
1. Check database pod: `kubectl get pods -l app=postgres`
2. If pod is not running:
   - Check events: `kubectl describe pod postgres-0`
   - Check persistent volume: `kubectl get pv`
   - Restart pod: `kubectl delete pod postgres-0`
3. If pod is running:
   - Check database logs: `kubectl logs postgres-0`
   - Test connection: `kubectl exec postgres-0 -- pg_isready`
   - Check disk space: `kubectl exec postgres-0 -- df -h`
4. If issue persists:
   - Restore from backup
   - Escalate to database administrator

### Runbook: High CPU Usage

**Alert**: HighCPUUsage

**Steps**:
1. Identify high CPU pods: `kubectl top pods`
2. Check pod logs: `kubectl logs <pod-name>`
3. Profile application:
   - Check for infinite loops
   - Review recent code changes
   - Check for CPU-intensive operations
4. Scale horizontally: `kubectl scale deployment backend --replicas=5`
5. If issue persists:
   - Increase CPU limits
   - Optimize code
   - Consider vertical scaling

---

## Best Practices

### Monitoring

1. **Set up alerts** for critical metrics
2. **Review dashboards** regularly
3. **Monitor trends** over time
4. **Document baselines** for normal behavior
5. **Test alerts** to ensure they fire correctly

### Logging

1. **Use structured logging** (JSON format)
2. **Include correlation IDs** for request tracing
3. **Log at appropriate levels** (avoid excessive DEBUG logs in production)
4. **Centralize logs** for easy searching
5. **Set up log retention** policies

### Performance

1. **Monitor key metrics** continuously
2. **Set performance budgets** for endpoints
3. **Profile regularly** to identify bottlenecks
4. **Load test** before major releases
5. **Optimize proactively** based on metrics

### Incident Response

1. **Follow runbooks** for common issues
2. **Document incidents** for learning
3. **Conduct post-mortems** after major incidents
4. **Update runbooks** based on learnings
5. **Practice incident response** with drills

---

## Support

For monitoring and troubleshooting questions:
- **Documentation**: [Architecture Overview](architecture.md)
- **Deployment**: [Deployment Guide](deployment.md)
- **API Reference**: [API Documentation](api-reference.md)
- **GitHub Issues**: https://github.com/your-org/todo-app/issues

---

## Appendix

### Useful Links

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)

### Version History

- **v1.0** (2026-01-12): Initial monitoring guide
