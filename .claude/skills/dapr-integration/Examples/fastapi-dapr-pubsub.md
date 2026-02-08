# FastAPI with Dapr Pub/Sub Integration

This example demonstrates a complete FastAPI application with Dapr pub/sub messaging for task events.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Task Service                             │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │   FastAPI    │────────▶│ Dapr Sidecar │                 │
│  │   (8000)     │◀────────│   (3500)     │                 │
│  └──────────────┘         └──────────────┘                 │
│         │                         │                          │
│         │                         │ Publish                  │
│         │                         ▼                          │
│         │                  ┌──────────────┐                 │
│         │                  │  Redis Pub/  │                 │
│         │                  │     Sub      │                 │
│         │                  └──────────────┘                 │
│         │                         │                          │
│         │                         │ Subscribe                │
│         │                         ▼                          │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │ Notification │◀────────│ Dapr Sidecar │                 │
│  │   Service    │────────▶│   (3501)     │                 │
│  │   (8001)     │         └──────────────┘                 │
│  └──────────────┘                                           │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
project/
├── components/
│   └── pubsub.yaml          # Dapr pub/sub component
├── task_service/
│   ├── main.py              # Task service with publisher
│   └── models.py            # Task models
├── notification_service/
│   ├── main.py              # Notification service with subscriber
│   └── handlers.py          # Event handlers
└── docker-compose.yml       # Local development setup
```

## Implementation

### 1. Component Configuration

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
  - name: redisHost
    value: localhost:6379
  - name: redisPassword
    value: ""
```

### 2. Task Service (Publisher)

**task_service/models.py**
```python
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

class Task(BaseModel):
    id: int
    title: str
    description: Optional[str] = None
    completed: bool = False
    user_id: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

class TaskEvent(BaseModel):
    event_type: str  # "created", "updated", "completed", "deleted"
    task_id: int
    user_id: str
    task_data: Optional[dict] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
```

**task_service/main.py**
```python
from fastapi import FastAPI, HTTPException
from dapr.ext.fastapi import DaprApp
from dapr.clients import DaprClient
from models import Task, TaskEvent
from typing import List
import json

app = FastAPI(title="Task Service")
dapr_app = DaprApp(app)

# In-memory storage (use database in production)
tasks_db = {}
task_id_counter = 1

@app.post("/tasks", response_model=Task)
async def create_task(task: Task):
    """Create a new task and publish event."""
    global task_id_counter

    task.id = task_id_counter
    task_id_counter += 1
    tasks_db[task.id] = task

    # Publish task created event
    event = TaskEvent(
        event_type="created",
        task_id=task.id,
        user_id=task.user_id,
        task_data=task.dict()
    )

    with DaprClient() as client:
        client.publish_event(
            pubsub_name='pubsub',
            topic_name='task-events',
            data=json.dumps(event.dict(), default=str),
            data_content_type='application/json'
        )

    return task

@app.get("/tasks", response_model=List[Task])
async def get_tasks(user_id: str):
    """Get all tasks for a user."""
    return [t for t in tasks_db.values() if t.user_id == user_id]

@app.get("/tasks/{task_id}", response_model=Task)
async def get_task(task_id: int):
    """Get a specific task."""
    if task_id not in tasks_db:
        raise HTTPException(status_code=404, detail="Task not found")
    return tasks_db[task_id]

@app.put("/tasks/{task_id}", response_model=Task)
async def update_task(task_id: int, task: Task):
    """Update a task and publish event."""
    if task_id not in tasks_db:
        raise HTTPException(status_code=404, detail="Task not found")

    task.id = task_id
    tasks_db[task_id] = task

    # Publish task updated event
    event = TaskEvent(
        event_type="updated",
        task_id=task.id,
        user_id=task.user_id,
        task_data=task.dict()
    )

    with DaprClient() as client:
        client.publish_event(
            pubsub_name='pubsub',
            topic_name='task-events',
            data=json.dumps(event.dict(), default=str),
            data_content_type='application/json'
        )

    return task

@app.post("/tasks/{task_id}/complete", response_model=Task)
async def complete_task(task_id: int):
    """Mark task as completed and publish event."""
    if task_id not in tasks_db:
        raise HTTPException(status_code=404, detail="Task not found")

    task = tasks_db[task_id]
    task.completed = True

    # Publish task completed event
    event = TaskEvent(
        event_type="completed",
        task_id=task.id,
        user_id=task.user_id,
        task_data=task.dict()
    )

    with DaprClient() as client:
        client.publish_event(
            pubsub_name='pubsub',
            topic_name='task-events',
            data=json.dumps(event.dict(), default=str),
            data_content_type='application/json'
        )

    return task

@app.delete("/tasks/{task_id}")
async def delete_task(task_id: int):
    """Delete a task and publish event."""
    if task_id not in tasks_db:
        raise HTTPException(status_code=404, detail="Task not found")

    task = tasks_db[task_id]

    # Publish task deleted event
    event = TaskEvent(
        event_type="deleted",
        task_id=task.id,
        user_id=task.user_id
    )

    with DaprClient() as client:
        client.publish_event(
            pubsub_name='pubsub',
            topic_name='task-events',
            data=json.dumps(event.dict(), default=str),
            data_content_type='application/json'
        )

    del tasks_db[task_id]
    return {"message": "Task deleted"}

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

### 3. Notification Service (Subscriber)

**notification_service/handlers.py**
```python
import logging

logger = logging.getLogger(__name__)

async def handle_task_created(event_data: dict):
    """Handle task created event."""
    task_data = event_data.get('task_data', {})
    user_id = event_data.get('user_id')

    logger.info(f"Task created for user {user_id}: {task_data.get('title')}")

    # Send notification (email, push, etc.)
    # await send_email(user_id, f"Task created: {task_data.get('title')}")

async def handle_task_completed(event_data: dict):
    """Handle task completed event."""
    task_data = event_data.get('task_data', {})
    user_id = event_data.get('user_id')

    logger.info(f"Task completed for user {user_id}: {task_data.get('title')}")

    # Send congratulations notification
    # await send_push_notification(user_id, "Great job! Task completed!")

async def handle_task_deleted(event_data: dict):
    """Handle task deleted event."""
    task_id = event_data.get('task_id')
    user_id = event_data.get('user_id')

    logger.info(f"Task {task_id} deleted for user {user_id}")
```

**notification_service/main.py**
```python
from fastapi import FastAPI
from dapr.ext.fastapi import DaprApp
from handlers import handle_task_created, handle_task_completed, handle_task_deleted
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Notification Service")
dapr_app = DaprApp(app)

@dapr_app.subscribe(pubsub='pubsub', topic='task-events')
async def task_event_subscriber(event_data: dict):
    """Subscribe to task events."""
    try:
        event_type = event_data.get('event_type')

        logger.info(f"Received event: {event_type}")

        # Route to appropriate handler
        if event_type == 'created':
            await handle_task_created(event_data)
        elif event_type == 'completed':
            await handle_task_completed(event_data)
        elif event_type == 'deleted':
            await handle_task_deleted(event_data)
        else:
            logger.warning(f"Unknown event type: {event_type}")

        return {"status": "SUCCESS"}

    except Exception as e:
        logger.error(f"Error processing event: {e}", exc_info=True)
        return {"status": "RETRY"}

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

### 4. Docker Compose Setup

**docker-compose.yml**
```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    networks:
      - dapr-network

  task-service:
    build: ./task_service
    ports:
      - "8000:8000"
    networks:
      - dapr-network
    depends_on:
      - redis

  task-service-dapr:
    image: "daprio/daprd:latest"
    command: [
      "./daprd",
      "-app-id", "task-service",
      "-app-port", "8000",
      "-dapr-http-port", "3500",
      "-components-path", "/components"
    ]
    volumes:
      - "./components:/components"
    depends_on:
      - task-service
    network_mode: "service:task-service"

  notification-service:
    build: ./notification_service
    ports:
      - "8001:8001"
    networks:
      - dapr-network
    depends_on:
      - redis

  notification-service-dapr:
    image: "daprio/daprd:latest"
    command: [
      "./daprd",
      "-app-id", "notification-service",
      "-app-port", "8001",
      "-dapr-http-port", "3501",
      "-components-path", "/components"
    ]
    volumes:
      - "./components:/components"
    depends_on:
      - notification-service
    network_mode: "service:notification-service"

networks:
  dapr-network:
    driver: bridge
```

## Running the Example

### 1. Start Services

```bash
# Using Docker Compose
docker-compose up -d

# Or run locally with Dapr CLI
# Terminal 1: Task Service
dapr run --app-id task-service --app-port 8000 --dapr-http-port 3500 --components-path ./components -- uvicorn task_service.main:app --port 8000

# Terminal 2: Notification Service
dapr run --app-id notification-service --app-port 8001 --dapr-http-port 3501 --components-path ./components -- uvicorn notification_service.main:app --port 8001
```

### 2. Test the Integration

```bash
# Create a task
curl -X POST http://localhost:8000/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Buy groceries",
    "description": "Milk, eggs, bread",
    "user_id": "user_123"
  }'

# Check notification service logs
docker logs notification-service

# Complete the task
curl -X POST http://localhost:8000/tasks/1/complete

# Check notification service logs again
docker logs notification-service
```

### 3. Verify Events

```bash
# Check Dapr logs
dapr logs --app-id task-service
dapr logs --app-id notification-service

# Monitor Redis pub/sub
redis-cli MONITOR
```

## Key Takeaways

1. **Decoupled Services**: Task service doesn't know about notification service
2. **Automatic Retries**: Dapr handles retries if notification service is down
3. **At-Least-Once Delivery**: Events are guaranteed to be delivered
4. **Easy Testing**: Can test services independently
5. **Cloud Events Format**: Standard event format across services

## Next Steps

- Add more subscribers (analytics, audit log, etc.)
- Implement dead letter queue for failed events
- Add event filtering based on user preferences
- Scale notification service horizontally
- Add distributed tracing with Zipkin/Jaeger
