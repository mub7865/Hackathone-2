# Kafka Event Streaming Skill

## Overview
This skill provides patterns and templates for implementing event-driven architecture using Apache Kafka or Redpanda. It covers event publishing, consuming, schema design, and integration with FastAPI applications.

## When to Use This Skill
- Building event-driven microservices
- Implementing pub/sub messaging patterns
- Creating asynchronous task processing
- Building real-time data pipelines
- Decoupling services through events

## Technology Stack
- **Kafka/Redpanda**: Event streaming platform
- **kafka-python**: Python client library
- **FastAPI**: For API integration
- **Pydantic**: For event schema validation

## Key Concepts

### Event-Driven Architecture
Events represent state changes or significant occurrences in your system. Services publish events to Kafka topics, and other services consume these events to react accordingly.

### Topics
Topics are categories or feeds to which events are published. Each topic can have multiple producers and consumers.

### Producers
Services that publish events to Kafka topics.

### Consumers
Services that subscribe to topics and process events.

### Event Schema
Structured format for events, typically JSON with Pydantic models for validation.

## Skill Components

### Templates/
- `kafka-producer.py.tpl` - Producer implementation pattern
- `kafka-consumer.py.tpl` - Consumer implementation pattern
- `event-schema.py.tpl` - Event schema definitions
- `redpanda-config.yaml.tpl` - Redpanda configuration

### Examples/
- `task-events-producer.md` - Publishing task events
- `notification-consumer.md` - Consuming notification events
- `redpanda-cloud-setup.md` - Setting up Redpanda Cloud

### Testing/
- `test-kafka-producer.py.tpl` - Producer unit tests
- `test-kafka-consumer.py.tpl` - Consumer unit tests
- `verify-event-flow.sh` - End-to-end event flow verification

### Troubleshooting/
- `common-kafka-errors.md` - Common errors and solutions
- `connection-issues.md` - Connection troubleshooting
- `event-not-received.md` - Debugging event delivery

## Prerequisites
```bash
pip install kafka-python pydantic
```

## Quick Start

### 1. Define Event Schema
```python
from pydantic import BaseModel
from datetime import datetime

class TaskEvent(BaseModel):
    event_type: str  # "created", "updated", "completed", "deleted"
    task_id: int
    user_id: str
    timestamp: datetime
    task_data: dict
```

### 2. Publish Events
```python
from kafka import KafkaProducer
import json

producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

event = TaskEvent(
    event_type="created",
    task_id=123,
    user_id="user-456",
    timestamp=datetime.now(),
    task_data={"title": "New Task"}
)

producer.send('task-events', value=event.dict())
producer.flush()
```

### 3. Consume Events
```python
from kafka import KafkaConsumer
import json

consumer = KafkaConsumer(
    'task-events',
    bootstrap_servers=['localhost:9092'],
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)

for message in consumer:
    event = message.value
    print(f"Received: {event['event_type']} for task {event['task_id']}")
```

## Integration with FastAPI

### Publishing Events from API Endpoints
```python
from fastapi import FastAPI, Depends
from kafka import KafkaProducer

app = FastAPI()

def get_kafka_producer():
    return KafkaProducer(
        bootstrap_servers=['localhost:9092'],
        value_serializer=lambda v: json.dumps(v).encode('utf-8')
    )

@app.post("/tasks")
async def create_task(
    task: TaskCreate,
    producer: KafkaProducer = Depends(get_kafka_producer)
):
    # Create task in database
    new_task = create_task_in_db(task)

    # Publish event
    event = TaskEvent(
        event_type="created",
        task_id=new_task.id,
        user_id=current_user.id,
        timestamp=datetime.now(),
        task_data=new_task.dict()
    )
    producer.send('task-events', value=event.dict())

    return new_task
```

## Best Practices

1. **Event Schema Versioning**: Include version field in events
2. **Idempotency**: Design consumers to handle duplicate events
3. **Error Handling**: Implement retry logic with exponential backoff
4. **Monitoring**: Track event lag and processing time
5. **Testing**: Test producers and consumers independently

## Common Patterns

### 1. Event Sourcing
Store all state changes as events, rebuild state by replaying events.

### 2. CQRS (Command Query Responsibility Segregation)
Separate read and write models, sync via events.

### 3. Saga Pattern
Coordinate distributed transactions using events.

### 4. Event Notification
Notify other services of state changes without tight coupling.

## Performance Considerations

- **Batching**: Send multiple events in batches for better throughput
- **Compression**: Enable compression for large events
- **Partitioning**: Use partition keys for parallel processing
- **Consumer Groups**: Scale consumers horizontally

## Security

- Use SASL/SSL for authentication and encryption
- Implement access control lists (ACLs)
- Validate event schemas
- Sanitize event data

## Related Skills
- `fastapi-sqlmodel-crud-patterns` - For database operations
- `integration-testing` - For testing event flows
- `dapr-distributed-runtime` - For alternative pub/sub

## References
- Apache Kafka Documentation: https://kafka.apache.org/documentation/
- Redpanda Documentation: https://docs.redpanda.com/
- kafka-python: https://kafka-python.readthedocs.io/
