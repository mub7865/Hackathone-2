# Dapr Common Issues and Solutions

This guide covers common problems you might encounter when working with Dapr and how to fix them.

## Installation Issues

### Issue: `dapr: command not found`

**Cause**: Dapr CLI not installed or not in PATH

**Solutions**:

1. **Install Dapr CLI**:
   ```bash
   # Linux/macOS
   wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash

   # Windows (PowerShell)
   powershell -Command "iwr -useb https://raw.githubusercontent.com/dapr/cli/master/install/install.ps1 | iex"
   ```

2. **Add to PATH**:
   ```bash
   # Linux/macOS
   export PATH=$PATH:$HOME/.dapr/bin

   # Add to ~/.bashrc or ~/.zshrc for persistence
   echo 'export PATH=$PATH:$HOME/.dapr/bin' >> ~/.bashrc
   ```

3. **Verify installation**:
   ```bash
   dapr --version
   ```

---

### Issue: `dapr init` fails with Docker errors

**Cause**: Docker not running or insufficient permissions

**Solutions**:

1. **Start Docker**:
   ```bash
   # Check if Docker is running
   docker ps

   # Start Docker Desktop (macOS/Windows)
   # Or start Docker daemon (Linux)
   sudo systemctl start docker
   ```

2. **Fix Docker permissions (Linux)**:
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

3. **Retry initialization**:
   ```bash
   dapr uninstall
   dapr init
   ```

---

## Runtime Issues

### Issue: `Failed to update metadata after 60.0 secs`

**Cause**: Cannot connect to Dapr sidecar

**Solutions**:

1. **Verify sidecar is running**:
   ```bash
   # Check if app is running with Dapr
   dapr list

   # Check sidecar logs
   dapr logs --app-id myapp
   ```

2. **Check Dapr HTTP port**:
   ```bash
   # Default is 3500
   curl http://localhost:3500/v1.0/healthz

   # If using different port
   export DAPR_HTTP_PORT=3501
   ```

3. **Restart with correct ports**:
   ```bash
   dapr run --app-id myapp --dapr-http-port 3500 --app-port 8000 -- python main.py
   ```

---

### Issue: `Component not found`

**Cause**: Component not loaded or incorrect name

**Solutions**:

1. **Verify component file exists**:
   ```bash
   ls -la ./components/
   # Should see pubsub.yaml, statestore.yaml, etc.
   ```

2. **Check component YAML syntax**:
   ```bash
   cat components/pubsub.yaml
   # Verify apiVersion, kind, metadata, spec are correct
   ```

3. **Specify components path**:
   ```bash
   dapr run --components-path ./components --app-id myapp ...
   ```

4. **Check component name matches**:
   ```python
   # In code
   client.publish_event(pubsub_name='pubsub', ...)  # Must match metadata.name in YAML
   ```

---

### Issue: `Port already in use`

**Cause**: Another process using the port

**Solutions**:

1. **Find process using port**:
   ```bash
   # macOS/Linux
   lsof -i :3500

   # Windows
   netstat -ano | findstr :3500
   ```

2. **Kill the process**:
   ```bash
   # macOS/Linux
   kill -9 <PID>

   # Windows
   taskkill /PID <PID> /F
   ```

3. **Use different port**:
   ```bash
   dapr run --dapr-http-port 3501 --dapr-grpc-port 50002 ...
   ```

---

## Pub/Sub Issues

### Issue: Events not being received by subscriber

**Cause**: Subscription not registered or topic mismatch

**Solutions**:

1. **Verify subscription endpoint**:
   ```bash
   # Check /dapr/subscribe endpoint
   curl http://localhost:8000/dapr/subscribe

   # Should return:
   # [{"pubsubname":"pubsub","topic":"my-topic","route":"/events"}]
   ```

2. **Check topic names match**:
   ```python
   # Publisher
   client.publish_event(pubsub_name='pubsub', topic_name='task-events', ...)

   # Subscriber
   @dapr_app.subscribe(pubsub='pubsub', topic='task-events')  # Must match
   ```

3. **Verify component is loaded**:
   ```bash
   # Check Dapr logs
   dapr logs --app-id myapp | grep pubsub
   ```

4. **Test with Dapr API directly**:
   ```bash
   # Publish via Dapr API
   curl -X POST http://localhost:3500/v1.0/publish/pubsub/test-topic \
     -H "Content-Type: application/json" \
     -d '{"message":"test"}'
   ```

---

### Issue: `Subscriber returned non-SUCCESS status`

**Cause**: Subscriber handler threw exception or returned wrong status

**Solutions**:

1. **Check subscriber logs**:
   ```bash
   # View app logs
   dapr logs --app-id myapp
   ```

2. **Return correct status**:
   ```python
   @dapr_app.subscribe(pubsub='pubsub', topic='events')
   async def handler(event_data: dict):
       try:
           # Process event
           return {"status": "SUCCESS"}  # Must return SUCCESS
       except Exception as e:
           logger.error(f"Error: {e}")
           return {"status": "RETRY"}  # Or RETRY for transient errors
   ```

3. **Enable debug logging**:
   ```python
   import logging
   logging.basicConfig(level=logging.DEBUG)
   ```

---

### Issue: Duplicate events received

**Cause**: At-least-once delivery guarantee

**Solutions**:

1. **Implement idempotency**:
   ```python
   processed_events = set()

   @dapr_app.subscribe(pubsub='pubsub', topic='events')
   async def handler(event_data: dict):
       event_id = event_data.get('id')

       if event_id in processed_events:
           return {"status": "SUCCESS"}  # Already processed

       # Process event
       processed_events.add(event_id)
       return {"status": "SUCCESS"}
   ```

2. **Use state store for deduplication**:
   ```python
   @dapr_app.subscribe(pubsub='pubsub', topic='events')
   async def handler(event_data: dict):
       event_id = event_data.get('id')

       with DaprClient() as client:
           # Check if already processed
           state = client.get_state('statestore', f'processed:{event_id}')
           if state.data:
               return {"status": "SUCCESS"}

           # Process event
           # ...

           # Mark as processed
           client.save_state('statestore', f'processed:{event_id}', 'true')

       return {"status": "SUCCESS"}
   ```

---

## State Store Issues

### Issue: `State not persisting`

**Cause**: State store not configured or Redis not running

**Solutions**:

1. **Verify Redis is running**:
   ```bash
   docker ps | grep redis
   redis-cli ping  # Should return PONG
   ```

2. **Check state store component**:
   ```bash
   cat components/statestore.yaml
   # Verify redisHost, type, etc.
   ```

3. **Test state store directly**:
   ```bash
   # Save state via Dapr API
   curl -X POST http://localhost:3500/v1.0/state/statestore \
     -H "Content-Type: application/json" \
     -d '[{"key":"test","value":"hello"}]'

   # Get state
   curl http://localhost:3500/v1.0/state/statestore/test
   ```

4. **Check Redis directly**:
   ```bash
   redis-cli KEYS "*"
   redis-cli GET "myapp||test"
   ```

---

### Issue: `ETag mismatch` errors

**Cause**: Concurrent updates to same state

**Solutions**:

1. **Implement retry logic**:
   ```python
   from tenacity import retry, stop_after_attempt

   @retry(stop=stop_after_attempt(3))
   def update_state(key, value):
       # Get current state with ETag
       result = state_manager.get_with_etag(key)
       if result:
           current_value, etag = result
       else:
           etag = None

       # Update and save with ETag
       new_value = compute_new_value(current_value)
       state_manager.save(key, new_value, etag=etag)
   ```

2. **Use transactions**:
   ```python
   operations = [
       {"operation": "upsert", "request": StateItem(key="key1", value="value1")},
       {"operation": "upsert", "request": StateItem(key="key2", value="value2")}
   ]
   state_manager.execute_transaction(operations)
   ```

---

### Issue: State with TTL not expiring

**Cause**: TTL not supported by state store or incorrect configuration

**Solutions**:

1. **Verify state store supports TTL**:
   - Redis: ✅ Supported
   - PostgreSQL: ❌ Not supported
   - MongoDB: ✅ Supported
   - Cosmos DB: ✅ Supported

2. **Check TTL metadata**:
   ```python
   client.save_state(
       store_name='statestore',
       key='temp',
       value='data',
       state_metadata={'ttlInSeconds': '60'}  # Must be string
   )
   ```

3. **Verify in Redis**:
   ```bash
   redis-cli TTL "myapp||temp"
   # Should show remaining seconds
   ```

---

## Service Invocation Issues

### Issue: `Service not found`

**Cause**: Target service not running or incorrect app-id

**Solutions**:

1. **Verify target service is running**:
   ```bash
   dapr list
   # Should show both services
   ```

2. **Check app-id matches**:
   ```python
   # Invoker
   client.invoke_method(app_id='user-service', ...)

   # Target service must be started with:
   # dapr run --app-id user-service ...
   ```

3. **Test with Dapr API**:
   ```bash
   curl http://localhost:3500/v1.0/invoke/user-service/method/health
   ```

---

### Issue: Service invocation timeout

**Cause**: Target service slow or not responding

**Solutions**:

1. **Check target service logs**:
   ```bash
   dapr logs --app-id user-service
   ```

2. **Increase timeout**:
   ```python
   # Set timeout in Dapr configuration
   # Or implement retry logic
   from tenacity import retry, stop_after_attempt, wait_exponential

   @retry(stop=stop_after_attempt(3), wait=wait_exponential())
   def invoke_service():
       return client.invoke_method(...)
   ```

3. **Check network connectivity**:
   ```bash
   # Kubernetes
   kubectl exec -it pod-a -- curl http://service-b/health
   ```

---

## Performance Issues

### Issue: High latency

**Cause**: Sidecar overhead or network issues

**Solutions**:

1. **Use gRPC instead of HTTP**:
   ```python
   # gRPC is faster than HTTP
   from dapr.clients.grpc import DaprGrpcClient

   with DaprGrpcClient() as client:
       client.publish_event(...)
   ```

2. **Optimize sidecar resources**:
   ```yaml
   # Kubernetes
   annotations:
     dapr.io/sidecar-cpu-limit: "500m"
     dapr.io/sidecar-memory-limit: "512Mi"
   ```

3. **Enable connection pooling**:
   ```python
   # Reuse DaprClient instance
   _client = None

   def get_client():
       global _client
       if _client is None:
           _client = DaprClient()
       return _client
   ```

---

### Issue: High memory usage

**Cause**: Too many messages in queue or large state

**Solutions**:

1. **Reduce queue depth**:
   ```yaml
   # pubsub.yaml
   metadata:
   - name: queueDepth
     value: "100"  # Reduce from default
   ```

2. **Implement batching**:
   ```python
   # Process messages in batches
   batch = []
   for message in messages:
       batch.append(message)
       if len(batch) >= 100:
           process_batch(batch)
           batch = []
   ```

3. **Use TTL for state**:
   ```python
   # Automatically expire old state
   client.save_state(
       store_name='statestore',
       key='temp',
       value='data',
       state_metadata={'ttlInSeconds': '3600'}
   )
   ```

---

## Debugging Tips

### Enable Debug Logging

```python
import logging

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('dapr')
logger.setLevel(logging.DEBUG)
```

### Check Dapr Logs

```bash
# Local
dapr logs --app-id myapp

# Kubernetes
kubectl logs -n todo-app pod-name -c daprd
```

### Monitor Dapr Metrics

```bash
# Prometheus metrics
curl http://localhost:9090/metrics | grep dapr
```

### Use Dapr Dashboard

```bash
dapr dashboard
# Opens http://localhost:8080
```

### Test with Dapr API

```bash
# Health check
curl http://localhost:3500/v1.0/healthz

# Metadata
curl http://localhost:3500/v1.0/metadata
```

---

## Getting Help

If you're still stuck:

1. **Check Dapr logs**: `dapr logs --app-id myapp`
2. **Check app logs**: View your application logs
3. **Check component logs**: `docker logs dapr_redis`
4. **Search GitHub issues**: https://github.com/dapr/dapr/issues
5. **Ask on Discord**: https://discord.com/invite/ptHhX6jc34
6. **Read documentation**: https://docs.dapr.io/

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `component not found` | Component not loaded | Check components-path |
| `port already in use` | Port conflict | Use different port |
| `connection refused` | Service not running | Start service |
| `timeout` | Service slow/down | Check service health |
| `etag mismatch` | Concurrent update | Implement retry |
| `invalid topic` | Topic name mismatch | Check topic names |
| `authentication failed` | Wrong credentials | Check secrets |
