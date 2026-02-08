# Dapr Integration Skill

## Overview

This skill provides patterns and templates for integrating Dapr (Distributed Application Runtime) into microservices applications. Dapr simplifies building resilient, distributed applications with built-in service mesh capabilities.

## When to Use This Skill

Use this skill when you need to:
- Implement pub/sub messaging between microservices
- Add distributed state management and caching
- Enable service-to-service invocation with retries and circuit breakers
- Manage secrets across environments
- Integrate with external systems via bindings
- Build actor-based systems
- Add observability and distributed tracing

## Technology Stack

- **Dapr Runtime**: v1.12+ (sidecar architecture)
- **Dapr Python SDK**: dapr-ext-fastapi, dapr
- **FastAPI**: 0.115+ (for HTTP endpoints)
- **Component Specs**: YAML configuration for Dapr building blocks
- **Deployment**: Docker Compose, Kubernetes, local development

## Key Concepts

### 1. Dapr Building Blocks

**Pub/Sub**: Publish and subscribe to messages
- Topic-based messaging
- Multiple pub/sub components (Redis, Kafka, RabbitMQ, etc.)
- At-least-once delivery guarantees
- Cloud Events format

**State Management**: Distributed key-value store
- CRUD operations on state
- Bulk operations
- Transactions
- TTL support
- Multiple state store backends (Redis, PostgreSQL, MongoDB, etc.)

**Service Invocation**: Service-to-service calls
- Service discovery
- Automatic retries
- Circuit breakers
- mTLS encryption
- Distributed tracing

**Bindings**: Connect to external systems
- Input bindings (triggers)
- Output bindings (invoke external systems)
- Cron bindings for scheduled tasks

**Secrets Management**: Secure secret storage
- Multiple secret stores (Kubernetes, Azure Key Vault, AWS Secrets Manager, etc.)
- Reference secrets in components

**Actors**: Virtual actors pattern
- Stateful objects
- Single-threaded execution
- Timers and reminders

### 2. Sidecar Architecture

Dapr runs as a sidecar container alongside your application:
```
┌─────────────────┐     ┌─────────────────┐
│   Your App      │────▶│  Dapr Sidecar   │
│   (Port 8000)   │◀────│  (Port 3500)    │
└─────────────────┘     └─────────────────┘
```

Your app communicates with Dapr via HTTP or gRPC on localhost.

### 3. Component Configuration

Dapr uses YAML files to configure building blocks:
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
    value: localhost:6379
```

## Quick Start

### 1. Install Dapr CLI

```bash
# Linux/macOS
wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash

# Windows (PowerShell)
powershell -Command "iwr -useb https://raw.githubusercontent.com/dapr/cli/master/install/install.ps1 | iex"

# Verify installation
dapr --version
```

### 2. Initialize Dapr

```bash
# Initialize Dapr in local mode (installs Redis, Zipkin, Placement service)
dapr init

# Verify
dapr --version
docker ps  # Should see dapr_redis, dapr_zipkin, dapr_placement
```

### 3. Install Python SDK

```bash
pip install dapr dapr-ext-fastapi
```

### 4. Create a Simple Pub/Sub App

```python
from fastapi import FastAPI
from dapr.ext.fastapi import DaprApp

app = FastAPI()
dapr_app = DaprApp(app)

# Subscribe to topic
@dapr_app.subscribe(pubsub='pubsub', topic='orders')
async def order_subscriber(event_data):
    print(f"Received order: {event_data}")
    return {"success": True}

# Publish to topic
@app.post("/orders")
async def create_order(order: dict):
    dapr_app.publish_event(
        pubsub_name='pubsub',
        topic_name='orders',
        data=order
    )
    return {"status": "published"}
```

### 5. Run with Dapr

```bash
# Run your FastAPI app with Dapr sidecar
dapr run --app-id myapp --app-port 8000 --dapr-http-port 3500 -- uvicorn main:app --port 8000
```

## Integration with FastAPI

### Pub/Sub Pattern

```python
from fastapi import FastAPI
from dapr.ext.fastapi import DaprApp
from pydantic import BaseModel

app = FastAPI()
dapr_app = DaprApp(app)

class TaskEvent(BaseModel):
    event_type: str
    task_id: int
    user_id: str

# Subscribe to events
@dapr_app.subscribe(pubsub='pubsub', topic='task-events')
async def handle_task_event(event: TaskEvent):
    print(f"Processing {event.event_type} for task {event.task_id}")
    # Process event
    return {"success": True}

# Publish events
@app.post("/tasks")
async def create_task(task: dict):
    event = TaskEvent(
        event_type="created",
        task_id=task["id"],
        user_id=task["user_id"]
    )

    await dapr_app.publish_event(
        pubsub_name='pubsub',
        topic_name='task-events',
        data=event.dict()
    )

    return {"status": "created"}
```

### State Management Pattern

```python
from dapr.clients import DaprClient

# Save state
def save_user_session(user_id: str, session_data: dict):
    with DaprClient() as client:
        client.save_state(
            store_name='statestore',
            key=f"session:{user_id}",
            value=session_data,
            state_metadata={"ttlInSeconds": "3600"}
        )

# Get state
def get_user_session(user_id: str) -> dict:
    with DaprClient() as client:
        state = client.get_state(
            store_name='statestore',
            key=f"session:{user_id}"
        )
        return state.json() if state.data else None

# Delete state
def delete_user_session(user_id: str):
    with DaprClient() as client:
        client.delete_state(
            store_name='statestore',
            key=f"session:{user_id}"
        )
```

### Service Invocation Pattern

```python
from dapr.clients import DaprClient

# Invoke another service
def get_user_profile(user_id: str) -> dict:
    with DaprClient() as client:
        response = client.invoke_method(
            app_id='user-service',
            method_name=f'users/{user_id}',
            http_verb='GET'
        )
        return response.json()

# Invoke with data
def create_notification(user_id: str, message: str):
    with DaprClient() as client:
        response = client.invoke_method(
            app_id='notification-service',
            method_name='notifications',
            http_verb='POST',
            data={'user_id': user_id, 'message': message}
        )
        return response.json()
```

## Best Practices

### 1. Component Configuration
- Use separate component files for each environment (dev, staging, prod)
- Store sensitive data in secrets, not in component specs
- Use namespaces in Kubernetes to isolate components

### 2. Error Handling
- Implement retry logic for transient failures
- Use dead letter topics for failed messages
- Log all Dapr API errors with context

### 3. Observability
- Enable Dapr tracing (Zipkin, Jaeger, Application Insights)
- Use Dapr metrics for monitoring
- Implement health checks for Dapr sidecar

### 4. Security
- Enable mTLS for service-to-service communication
- Use API tokens for Dapr API access
- Rotate secrets regularly
- Use scoped access for components

### 5. Performance
- Use bulk operations for state management
- Configure appropriate timeouts
- Use connection pooling
- Monitor sidecar resource usage

## Common Patterns

### Event-Driven Microservices
```
Service A → Dapr Pub/Sub → Service B
                         → Service C
                         → Service D
```

### Distributed Caching
```
Service → Dapr State Store (Redis) → Shared Cache
```

### Service Mesh
```
Service A → Dapr Sidecar → Dapr Sidecar → Service B
         (mTLS, retries, circuit breaker)
```

### Scheduled Tasks
```
Dapr Cron Binding → Service → Process Task
```

## Templates Available

1. **dapr-pubsub.py.tpl** - Pub/sub implementation with FastAPI
2. **dapr-state.py.tpl** - State management operations
3. **dapr-service-invocation.py.tpl** - Service-to-service calls
4. **dapr-component-pubsub.yaml.tpl** - Pub/sub component configuration
5. **dapr-component-statestore.yaml.tpl** - State store configuration
6. **dapr-component-secrets.yaml.tpl** - Secrets configuration

## Examples Available

1. **fastapi-dapr-pubsub.md** - Complete FastAPI pub/sub integration
2. **dapr-local-setup.md** - Local development environment setup
3. **dapr-k8s-deployment.md** - Kubernetes deployment with Dapr
4. **dapr-redis-components.md** - Redis-based components setup

## Testing Available

1. **test-dapr-pubsub.py.tpl** - Unit tests for pub/sub
2. **test-dapr-state.py.tpl** - Unit tests for state management
3. **verify-dapr-setup.sh** - End-to-end verification script

## Troubleshooting Available

1. **dapr-common-issues.md** - Common problems and solutions
2. **dapr-sidecar-issues.md** - Sidecar connectivity and startup issues

## Related Skills

- **kafka-event-streaming** - Alternative event streaming approach
- **kubernetes-deployment-patterns** - Deploying Dapr on Kubernetes
- **docker-containerization** - Containerizing Dapr applications

## References

- [Dapr Documentation](https://docs.dapr.io/)
- [Dapr Python SDK](https://github.com/dapr/python-sdk)
- [Dapr Best Practices](https://docs.dapr.io/operations/best-practices/)
- [Dapr Components](https://docs.dapr.io/reference/components-reference/)
