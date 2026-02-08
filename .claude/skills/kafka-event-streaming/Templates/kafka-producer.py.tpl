"""
Kafka Producer Template for Event Publishing

This template provides a reusable pattern for publishing events to Kafka topics.
"""

from kafka import KafkaProducer
from kafka.errors import KafkaError
import json
import logging
from typing import Dict, Any, Optional
from datetime import datetime
from pydantic import BaseModel

logger = logging.getLogger(__name__)


class EventPublisher:
    """
    Generic event publisher for Kafka topics.

    Usage:
        publisher = EventPublisher(
            bootstrap_servers=['localhost:9092'],
            topic='my-events'
        )
        publisher.publish(event_data)
    """

    def __init__(
        self,
        bootstrap_servers: list[str],
        topic: str,
        client_id: Optional[str] = None,
        **kwargs
    ):
        """
        Initialize Kafka producer.

        Args:
            bootstrap_servers: List of Kafka broker addresses
            topic: Default topic to publish to
            client_id: Optional client identifier
            **kwargs: Additional KafkaProducer configuration
        """
        self.topic = topic

        # Default configuration
        config = {
            'bootstrap_servers': bootstrap_servers,
            'value_serializer': lambda v: json.dumps(v, default=str).encode('utf-8'),
            'key_serializer': lambda k: k.encode('utf-8') if k else None,
            'acks': 'all',  # Wait for all replicas
            'retries': 3,
            'max_in_flight_requests_per_connection': 1,  # Ensure ordering
        }

        if client_id:
            config['client_id'] = client_id

        # Override with custom config
        config.update(kwargs)

        try:
            self.producer = KafkaProducer(**config)
            logger.info(f"Kafka producer initialized for topic: {topic}")
        except Exception as e:
            logger.error(f"Failed to initialize Kafka producer: {e}")
            raise

    def publish(
        self,
        event_data: Dict[str, Any],
        key: Optional[str] = None,
        topic: Optional[str] = None,
        headers: Optional[list] = None
    ) -> bool:
        """
        Publish event to Kafka topic.

        Args:
            event_data: Event payload (will be JSON serialized)
            key: Optional partition key
            topic: Optional topic override
            headers: Optional message headers

        Returns:
            bool: True if published successfully
        """
        target_topic = topic or self.topic

        try:
            # Add timestamp if not present
            if 'timestamp' not in event_data:
                event_data['timestamp'] = datetime.utcnow().isoformat()

            # Send message
            future = self.producer.send(
                target_topic,
                value=event_data,
                key=key,
                headers=headers
            )

            # Wait for confirmation (blocking)
            record_metadata = future.get(timeout=10)

            logger.info(
                f"Event published to {record_metadata.topic} "
                f"partition {record_metadata.partition} "
                f"offset {record_metadata.offset}"
            )
            return True

        except KafkaError as e:
            logger.error(f"Failed to publish event: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error publishing event: {e}")
            return False

    def publish_batch(self, events: list[Dict[str, Any]]) -> int:
        """
        Publish multiple events in batch.

        Args:
            events: List of event payloads

        Returns:
            int: Number of successfully published events
        """
        success_count = 0

        for event in events:
            if self.publish(event):
                success_count += 1

        # Flush to ensure all messages are sent
        self.producer.flush()

        logger.info(f"Published {success_count}/{len(events)} events")
        return success_count

    def close(self):
        """Close the producer and flush pending messages."""
        try:
            self.producer.flush()
            self.producer.close()
            logger.info("Kafka producer closed")
        except Exception as e:
            logger.error(f"Error closing producer: {e}")


# Example usage with Pydantic model
class TaskEvent(BaseModel):
    """Example event schema for task operations."""
    event_type: str  # "created", "updated", "completed", "deleted"
    task_id: int
    user_id: str
    timestamp: datetime
    task_data: dict


def publish_task_event(
    publisher: EventPublisher,
    event_type: str,
    task_id: int,
    user_id: str,
    task_data: dict
) -> bool:
    """
    Helper function to publish task events.

    Args:
        publisher: EventPublisher instance
        event_type: Type of event
        task_id: Task identifier
        user_id: User identifier
        task_data: Task details

    Returns:
        bool: True if published successfully
    """
    event = TaskEvent(
        event_type=event_type,
        task_id=task_id,
        user_id=user_id,
        timestamp=datetime.utcnow(),
        task_data=task_data
    )

    # Use task_id as partition key for ordering
    return publisher.publish(
        event_data=event.dict(),
        key=str(task_id)
    )


# FastAPI dependency injection example
from fastapi import Depends

_producer_instance = None

def get_event_publisher() -> EventPublisher:
    """
    FastAPI dependency for event publisher.

    Usage:
        @app.post("/tasks")
        async def create_task(
            publisher: EventPublisher = Depends(get_event_publisher)
        ):
            publisher.publish(event_data)
    """
    global _producer_instance

    if _producer_instance is None:
        _producer_instance = EventPublisher(
            bootstrap_servers=['localhost:9092'],
            topic='task-events'
        )

    return _producer_instance
