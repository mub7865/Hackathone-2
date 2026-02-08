"""Kafka event producer for publishing task events.

This module provides functionality to publish task-related events to Kafka/Redpanda
topics for consumption by downstream services (audit, notification, websocket, etc.).
"""

import json
import logging
from datetime import datetime
from typing import Any, Dict, Optional
from uuid import UUID, uuid4

from aiokafka import AIOKafkaProducer
from aiokafka.errors import KafkaError

from app.config import get_settings

logger = logging.getLogger(__name__)


class EventProducer:
    """Kafka event producer for task events.

    This class manages the lifecycle of a Kafka producer and provides
    methods to publish events to various topics.

    Attributes:
        producer: AIOKafkaProducer instance.
        settings: Application settings with Kafka configuration.
    """

    def __init__(self) -> None:
        """Initialize the event producer."""
        self.settings = get_settings()
        self.producer: Optional[AIOKafkaProducer] = None

    async def start(self) -> None:
        """Start the Kafka producer.

        Raises:
            KafkaError: If connection to Kafka fails.
        """
        try:
            self.producer = AIOKafkaProducer(
                bootstrap_servers=self.settings.kafka_bootstrap_servers,
                value_serializer=lambda v: json.dumps(v).encode("utf-8"),
                key_serializer=lambda k: k.encode("utf-8") if k else None,
                acks="all",  # Wait for all replicas to acknowledge
                retries=3,  # Retry failed sends up to 3 times
                max_in_flight_requests_per_connection=5,
                compression_type="gzip",  # Compress messages
            )
            await self.producer.start()
            logger.info(
                f"Kafka producer started: {self.settings.kafka_bootstrap_servers}"
            )
        except KafkaError as e:
            logger.error(f"Failed to start Kafka producer: {e}")
            raise

    async def stop(self) -> None:
        """Stop the Kafka producer gracefully."""
        if self.producer:
            await self.producer.stop()
            logger.info("Kafka producer stopped")

    async def publish_event(
        self,
        topic: str,
        event_type: str,
        payload: Dict[str, Any],
        key: Optional[str] = None,
    ) -> str:
        """Publish an event to a Kafka topic.

        Args:
            topic: Kafka topic name.
            event_type: Event type (e.g., 'task.created').
            payload: Event payload data.
            key: Optional partition key (defaults to task_id if present).

        Returns:
            Event ID (UUID string).

        Raises:
            RuntimeError: If producer is not started.
            KafkaError: If event publishing fails.
        """
        if not self.producer:
            raise RuntimeError("Producer not started. Call start() first.")

        # Generate event ID
        event_id = str(uuid4())

        # Build event envelope
        event = {
            "event_id": event_id,
            "event_type": event_type,
            "timestamp": datetime.utcnow().isoformat(),
            "schema_version": "1.0",
            "payload": payload,
        }

        # Use task_id as partition key if available
        if key is None and "task_id" in payload:
            key = str(payload["task_id"])

        try:
            # Send event to Kafka
            await self.producer.send_and_wait(topic, value=event, key=key)
            logger.info(
                f"Published event: {event_type} to {topic} (event_id={event_id})"
            )
            return event_id
        except KafkaError as e:
            logger.error(f"Failed to publish event {event_id}: {e}")
            raise

    async def publish_task_created(
        self,
        task_id: UUID,
        user_id: str,
        title: str,
        description: Optional[str],
        status: str,
        priority: str,
        tags: list[str],
        due_date: Optional[datetime],
        remind_at: Optional[datetime],
        recurring_pattern_id: Optional[UUID],
    ) -> str:
        """Publish a task.created event.

        Args:
            task_id: Task UUID.
            user_id: User ID who created the task.
            title: Task title.
            description: Task description.
            status: Task status.
            priority: Task priority.
            tags: Task tags.
            due_date: Task due date.
            remind_at: Task reminder time.
            recurring_pattern_id: Recurring pattern ID if applicable.

        Returns:
            Event ID.
        """
        payload = {
            "task_id": str(task_id),
            "user_id": user_id,
            "title": title,
            "description": description,
            "status": status,
            "priority": priority,
            "tags": tags,
            "due_date": due_date.isoformat() if due_date else None,
            "remind_at": remind_at.isoformat() if remind_at else None,
            "recurring_pattern_id": str(recurring_pattern_id) if recurring_pattern_id else None,
        }
        return await self.publish_event(
            topic=self.settings.kafka_topic_task_events,
            event_type="task.created",
            payload=payload,
            key=str(task_id),
        )

    async def publish_task_updated(
        self,
        task_id: UUID,
        user_id: str,
        updates: Dict[str, Any],
    ) -> str:
        """Publish a task.updated event.

        Args:
            task_id: Task UUID.
            user_id: User ID who updated the task.
            updates: Dictionary of updated fields.

        Returns:
            Event ID.
        """
        payload = {
            "task_id": str(task_id),
            "user_id": user_id,
            "updates": updates,
        }
        return await self.publish_event(
            topic=self.settings.kafka_topic_task_events,
            event_type="task.updated",
            payload=payload,
            key=str(task_id),
        )

    async def publish_task_deleted(
        self,
        task_id: UUID,
        user_id: str,
    ) -> str:
        """Publish a task.deleted event.

        Args:
            task_id: Task UUID.
            user_id: User ID who deleted the task.

        Returns:
            Event ID.
        """
        payload = {
            "task_id": str(task_id),
            "user_id": user_id,
        }
        return await self.publish_event(
            topic=self.settings.kafka_topic_task_events,
            event_type="task.deleted",
            payload=payload,
            key=str(task_id),
        )

    async def publish_task_completed(
        self,
        task_id: UUID,
        user_id: str,
    ) -> str:
        """Publish a task.completed event.

        Args:
            task_id: Task UUID.
            user_id: User ID who completed the task.

        Returns:
            Event ID.
        """
        payload = {
            "task_id": str(task_id),
            "user_id": user_id,
        }
        return await self.publish_event(
            topic=self.settings.kafka_topic_task_events,
            event_type="task.completed",
            payload=payload,
            key=str(task_id),
        )


# Global producer instance
_producer: Optional[EventProducer] = None


async def get_producer() -> EventProducer:
    """Get or create the global event producer instance.

    Returns:
        EventProducer instance.
    """
    global _producer
    if _producer is None:
        _producer = EventProducer()
        await _producer.start()
    return _producer


async def publish_task_event(
    event_type: str,
    task_id: UUID,
    user_id: str,
    **kwargs: Any,
) -> Optional[str]:
    """Convenience function to publish task events.

    This function checks if event publishing is enabled before publishing.

    Args:
        event_type: Event type ('created', 'updated', 'deleted', 'completed').
        task_id: Task UUID.
        user_id: User ID.
        **kwargs: Additional event-specific parameters.

    Returns:
        Event ID if published, None if event publishing is disabled.
    """
    settings = get_settings()

    # Check if event publishing is enabled
    if not settings.enable_event_publishing:
        logger.debug(f"Event publishing disabled, skipping {event_type} event")
        return None

    try:
        producer = await get_producer()

        if event_type == "created":
            return await producer.publish_task_created(
                task_id=task_id,
                user_id=user_id,
                title=kwargs.get("title", ""),
                description=kwargs.get("description"),
                status=kwargs.get("status", "pending"),
                priority=kwargs.get("priority", "medium"),
                tags=kwargs.get("tags", []),
                due_date=kwargs.get("due_date"),
                remind_at=kwargs.get("remind_at"),
                recurring_pattern_id=kwargs.get("recurring_pattern_id"),
            )
        elif event_type == "updated":
            return await producer.publish_task_updated(
                task_id=task_id,
                user_id=user_id,
                updates=kwargs.get("updates", {}),
            )
        elif event_type == "deleted":
            return await producer.publish_task_deleted(
                task_id=task_id,
                user_id=user_id,
            )
        elif event_type == "completed":
            return await producer.publish_task_completed(
                task_id=task_id,
                user_id=user_id,
            )
        else:
            logger.warning(f"Unknown event type: {event_type}")
            return None
    except Exception as e:
        logger.error(f"Failed to publish {event_type} event: {e}")
        # Don't raise - event publishing failures should not break the main flow
        return None
