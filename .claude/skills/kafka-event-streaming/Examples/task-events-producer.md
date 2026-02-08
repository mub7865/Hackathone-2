# Task Events Producer Example

This example shows how to publish task events from a FastAPI application.

## Overview

When tasks are created, updated, completed, or deleted, we publish events to Kafka so other services can react to these changes.

## Implementation

### 1. Setup Event Publisher

```python
# app/events/publisher.py
from kafka import KafkaProducer
import json
import os
from datetime import datetime

class TaskEventPublisher:
    def __init__(self):
        self.producer = KafkaProducer(
            bootstrap_servers=os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092').split(','),
            value_serializer=lambda v: json.dumps(v, default=str).encode('utf-8'),
            acks='all',
            retries=3
        )
        self.topic = 'task-events'

    def publish_task_created(self, task_id: int, user_id: str, task_data: dict):
        """Publish task created event."""
        event = {
            'event_type': 'created',
            'task_id': task_id,
            'user_id': user_id,
            'timestamp': datetime.utcnow().isoformat(),
            'task_data': task_data
        }
        self.producer.send(self.topic, value=event, key=str(task_id).encode())
        self.producer.flush()

    def publish_task_completed(self, task_id: int, user_id: str, task_data: dict):
        """Publish task completed event."""
        event = {
            'event_type': 'completed',
            'task_id': task_id,
            'user_id': user_id,
            'timestamp': datetime.utcnow().isoformat(),
            'task_data': task_data
        }
        self.producer.send(self.topic, value=event, key=str(task_id).encode())
        self.producer.flush()

    def publish_task_updated(self, task_id: int, user_id: str, task_data: dict):
        """Publish task updated event."""
        event = {
            'event_type': 'updated',
            'task_id': task_id,
            'user_id': user_id,
            'timestamp': datetime.utcnow().isoformat(),
            'task_data': task_data
        }
        self.producer.send(self.topic, value=event, key=str(task_id).encode())
        self.producer.flush()

    def publish_task_deleted(self, task_id: int, user_id: str):
        """Publish task deleted event."""
        event = {
            'event_type': 'deleted',
            'task_id': task_id,
            'user_id': user_id,
            'timestamp': datetime.utcnow().isoformat()
        }
        self.producer.send(self.topic, value=event, key=str(task_id).encode())
        self.producer.flush()

# Global publisher instance
_publisher = None

def get_event_publisher() -> TaskEventPublisher:
    """Get or create event publisher singleton."""
    global _publisher
    if _publisher is None:
        _publisher = TaskEventPublisher()
    return _publisher
```

### 2. Integrate with FastAPI Endpoints

```python
# app/api/v1/tasks.py
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session
from app.database import get_session
from app.events.publisher import get_event_publisher, TaskEventPublisher
from app.models.task import Task
from app.schemas.task import TaskCreate, TaskUpdate

router = APIRouter()

@router.post("/tasks", response_model=Task)
async def create_task(
    task: TaskCreate,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_user),
    publisher: TaskEventPublisher = Depends(get_event_publisher)
):
    """Create a new task and publish event."""
    # Create task in database
    db_task = Task(
        title=task.title,
        description=task.description,
        user_id=current_user.id,
        status="pending"
    )
    session.add(db_task)
    session.commit()
    session.refresh(db_task)

    # Publish event
    publisher.publish_task_created(
        task_id=db_task.id,
        user_id=current_user.id,
        task_data={
            'id': db_task.id,
            'title': db_task.title,
            'description': db_task.description,
            'status': db_task.status,
            'priority': db_task.priority,
            'tags': db_task.tags,
            'is_recurring': db_task.is_recurring,
            'recurrence_pattern': db_task.recurrence_pattern,
            'due_date': db_task.due_date.isoformat() if db_task.due_date else None,
            'created_at': db_task.created_at.isoformat(),
            'updated_at': db_task.updated_at.isoformat()
        }
    )

    return db_task

@router.patch("/tasks/{task_id}/complete")
async def complete_task(
    task_id: int,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_user),
    publisher: TaskEventPublisher = Depends(get_event_publisher)
):
    """Mark task as complete and publish event."""
    # Get task
    task = session.get(Task, task_id)
    if not task or task.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Task not found")

    # Update status
    task.status = "completed"
    session.add(task)
    session.commit()
    session.refresh(task)

    # Publish event
    publisher.publish_task_completed(
        task_id=task.id,
        user_id=current_user.id,
        task_data={
            'id': task.id,
            'title': task.title,
            'description': task.description,
            'status': task.status,
            'priority': task.priority,
            'tags': task.tags,
            'is_recurring': task.is_recurring,
            'recurrence_pattern': task.recurrence_pattern,
            'due_date': task.due_date.isoformat() if task.due_date else None,
            'created_at': task.created_at.isoformat(),
            'updated_at': task.updated_at.isoformat()
        }
    )

    return task

@router.put("/tasks/{task_id}")
async def update_task(
    task_id: int,
    task_update: TaskUpdate,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_user),
    publisher: TaskEventPublisher = Depends(get_event_publisher)
):
    """Update task and publish event."""
    # Get task
    task = session.get(Task, task_id)
    if not task or task.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Task not found")

    # Update fields
    if task_update.title is not None:
        task.title = task_update.title
    if task_update.description is not None:
        task.description = task_update.description
    if task_update.priority is not None:
        task.priority = task_update.priority
    if task_update.tags is not None:
        task.tags = task_update.tags
    if task_update.due_date is not None:
        task.due_date = task_update.due_date

    session.add(task)
    session.commit()
    session.refresh(task)

    # Publish event
    publisher.publish_task_updated(
        task_id=task.id,
        user_id=current_user.id,
        task_data={
            'id': task.id,
            'title': task.title,
            'description': task.description,
            'status': task.status,
            'priority': task.priority,
            'tags': task.tags,
            'is_recurring': task.is_recurring,
            'recurrence_pattern': task.recurrence_pattern,
            'due_date': task.due_date.isoformat() if task.due_date else None,
            'created_at': task.created_at.isoformat(),
            'updated_at': task.updated_at.isoformat()
        }
    )

    return task

@router.delete("/tasks/{task_id}")
async def delete_task(
    task_id: int,
    session: Session = Depends(get_session),
    current_user = Depends(get_current_user),
    publisher: TaskEventPublisher = Depends(get_event_publisher)
):
    """Delete task and publish event."""
    # Get task
    task = session.get(Task, task_id)
    if not task or task.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Task not found")

    # Delete from database
    session.delete(task)
    session.commit()

    # Publish event
    publisher.publish_task_deleted(
        task_id=task_id,
        user_id=current_user.id
    )

    return {"message": "Task deleted successfully"}
```

### 3. Environment Configuration

```bash
# .env
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
# For Redpanda Cloud:
# KAFKA_BOOTSTRAP_SERVERS=seed-12345.cloud.redpanda.com:9092
```

### 4. Testing

```bash
# Start Kafka/Redpanda locally
docker run -d --name redpanda \
  -p 9092:9092 \
  docker.redpanda.com/redpandadata/redpanda:latest \
  redpanda start --smp 1

# Run FastAPI app
uvicorn app.main:app --reload

# Create a task (will publish event)
curl -X POST http://localhost:8000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "title": "Test Task",
    "description": "This will publish an event"
  }'

# Verify event was published
docker exec -it redpanda rpk topic consume task-events --num 1
```

## Event Flow

```
1. User creates task via API
   ↓
2. FastAPI endpoint creates task in database
   ↓
3. Publisher sends event to Kafka topic
   ↓
4. Event is stored in Kafka
   ↓
5. Consumers (notification service, recurring task service, etc.) receive event
   ↓
6. Consumers process event asynchronously
```

## Benefits

- **Decoupling**: API doesn't need to know about notification or recurring task logic
- **Scalability**: Multiple consumers can process events independently
- **Reliability**: Events are persisted in Kafka
- **Audit Trail**: All task operations are logged as events
- **Real-time**: Consumers react immediately to changes

## Best Practices

1. **Always flush**: Call `producer.flush()` after sending critical events
2. **Use partition keys**: Use task_id as key for ordering guarantees
3. **Include timestamps**: Always add timestamp to events
4. **Error handling**: Wrap publish calls in try-except
5. **Monitoring**: Track publish success/failure rates
