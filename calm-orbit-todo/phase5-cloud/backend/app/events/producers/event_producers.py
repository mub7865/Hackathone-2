"""Event producer services for publishing events to Kafka/Redpanda.

This module provides structured event producers for different event types
with validation, serialization, and error handling.
"""

import json
import logging
import os
from datetime import datetime
from typing import Any, Dict, Optional
from uuid import UUID

from aiokafka import AIOKafkaProducer
from aiokafka.errors import KafkaError

logger = logging.getLogger(__name__)


class EventProducer:
    """Base event producer for publishing events to Kafka."""

    def __init__(
        self,
        bootstrap_servers: Optional[str] = None,
        topic_prefix: str = "todo-app",
    ):
        """Initialize the event producer.

        Args:
            bootstrap_servers: Kafka bootstrap servers (reads from env if not provided)
            topic_prefix: Prefix for topic names
        """
        # Read from environment if not provided
        if bootstrap_servers is None:
            bootstrap_servers = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")

        self.bootstrap_servers = bootstrap_servers
        self.topic_prefix = topic_prefix
        self.producer: Optional[AIOKafkaProducer] = None

    async def start(self) -> None:
        """Start the Kafka producer."""
        try:
            self.producer = AIOKafkaProducer(
                bootstrap_servers=self.bootstrap_servers,
                value_serializer=lambda v: json.dumps(v).encode("utf-8"),
                key_serializer=lambda k: k.encode("utf-8") if k else None,
            )
            await self.producer.start()
            logger.info(f"Event producer started: {self.bootstrap_servers}")
        except Exception as e:
            logger.error(f"Failed to start event producer: {e}", exc_info=True)
            raise

    async def stop(self) -> None:
        """Stop the Kafka producer."""
        if self.producer:
            await self.producer.stop()
            logger.info("Event producer stopped")

    async def publish_event(
        self,
        topic: str,
        event_type: str,
        event_data: Dict[str, Any],
        key: Optional[str] = None,
    ) -> bool:
        """Publish an event to Kafka.

        Args:
            topic: Topic name (without prefix)
            event_type: Type of event
            event_data: Event payload
            key: Optional partition key

        Returns:
            True if published successfully, False otherwise
        """
        if not self.producer:
            logger.error("Producer not started")
            return False

        try:
            # Build full topic name
            full_topic = f"{self.topic_prefix}.{topic}"

            # Build event envelope
            event = {
                "event_type": event_type,
                "event_id": str(UUID()),
                "timestamp": datetime.utcnow().isoformat(),
                "data": event_data,
            }

            # Publish to Kafka
            await self.producer.send_and_wait(
                topic=full_topic,
                value=event,
                key=key,
            )

            logger.info(
                f"Published event: topic={full_topic}, type={event_type}, key={key}"
            )
            return True

        except KafkaError as e:
            logger.error(f"Kafka error publishing event: {e}", exc_info=True)
            return False
        except Exception as e:
            logger.error(f"Error publishing event: {e}", exc_info=True)
            return False


class TaskEventProducer(EventProducer):
    """Producer for task-related events."""

    TOPIC = "task-events"

    async def publish_task_created(
        self,
        task_id: UUID,
        user_id: str,
        title: str,
        description: Optional[str] = None,
        priority: Optional[str] = None,
        tags: Optional[list[str]] = None,
    ) -> bool:
        """Publish task created event.

        Args:
            task_id: Task ID
            user_id: User who created the task
            title: Task title
            description: Task description
            priority: Task priority
            tags: Task tags

        Returns:
            True if published successfully
        """
        event_data = {
            "task_id": str(task_id),
            "user_id": user_id,
            "title": title,
            "description": description,
            "priority": priority,
            "tags": tags or [],
        }

        return await self.publish_event(
            topic=self.TOPIC,
            event_type="task.created",
            event_data=event_data,
            key=user_id,
        )

    async def publish_task_updated(
        self,
        task_id: UUID,
        user_id: str,
        updates: Dict[str, Any],
    ) -> bool:
        """Publish task updated event.

        Args:
            task_id: Task ID
            user_id: User who updated the task
            updates: Dictionary of updated fields

        Returns:
            True if published successfully
        """
        event_data = {
            "task_id": str(task_id),
            "user_id": user_id,
            "updates": updates,
        }

        return await self.publish_event(
            topic=self.TOPIC,
            event_type="task.updated",
            event_data=event_data,
            key=user_id,
        )

    async def publish_task_deleted(
        self,
        task_id: UUID,
        user_id: str,
    ) -> bool:
        """Publish task deleted event.

        Args:
            task_id: Task ID
            user_id: User who deleted the task

        Returns:
            True if published successfully
        """
        event_data = {
            "task_id": str(task_id),
            "user_id": user_id,
        }

        return await self.publish_event(
            topic=self.TOPIC,
            event_type="task.deleted",
            event_data=event_data,
            key=user_id,
        )

    async def publish_task_completed(
        self,
        task_id: UUID,
        user_id: str,
    ) -> bool:
        """Publish task completed event.

        Args:
            task_id: Task ID
            user_id: User who completed the task

        Returns:
            True if published successfully
        """
        event_data = {
            "task_id": str(task_id),
            "user_id": user_id,
        }

        return await self.publish_event(
            topic=self.TOPIC,
            event_type="task.completed",
            event_data=event_data,
            key=user_id,
        )


class ReminderEventProducer(EventProducer):
    """Producer for reminder-related events."""

    TOPIC = "reminders"

    async def publish_reminder_due(
        self,
        task_id: UUID,
        user_id: str,
        title: str,
        due_date: str,
    ) -> bool:
        """Publish reminder due event.

        Args:
            task_id: Task ID
            user_id: User to remind
            title: Task title
            due_date: Due date

        Returns:
            True if published successfully
        """
        event_data = {
            "task_id": str(task_id),
            "user_id": user_id,
            "title": title,
            "due_date": due_date,
        }

        return await self.publish_event(
            topic=self.TOPIC,
            event_type="reminder.due",
            event_data=event_data,
            key=user_id,
        )


class RecurringTaskEventProducer(EventProducer):
    """Producer for recurring task events."""

    TOPIC = "recurring-tasks"

    async def publish_recurring_task_generated(
        self,
        pattern_id: UUID,
        task_id: UUID,
        user_id: str,
        title: str,
    ) -> bool:
        """Publish recurring task generated event.

        Args:
            pattern_id: Recurring pattern ID
            task_id: Generated task ID
            user_id: User who owns the task
            title: Task title

        Returns:
            True if published successfully
        """
        event_data = {
            "pattern_id": str(pattern_id),
            "task_id": str(task_id),
            "user_id": user_id,
            "title": title,
        }

        return await self.publish_event(
            topic=self.TOPIC,
            event_type="recurring_task.generated",
            event_data=event_data,
            key=user_id,
        )


# Global producer instances
_task_producer: Optional[TaskEventProducer] = None
_reminder_producer: Optional[ReminderEventProducer] = None
_recurring_task_producer: Optional[RecurringTaskEventProducer] = None


async def get_task_producer(bootstrap_servers: str = "localhost:9092") -> TaskEventProducer:
    """Get or create task event producer.

    Args:
        bootstrap_servers: Kafka bootstrap servers

    Returns:
        TaskEventProducer instance
    """
    global _task_producer
    if _task_producer is None:
        _task_producer = TaskEventProducer(bootstrap_servers=bootstrap_servers)
        await _task_producer.start()
    return _task_producer


async def get_reminder_producer(bootstrap_servers: str = "localhost:9092") -> ReminderEventProducer:
    """Get or create reminder event producer.

    Args:
        bootstrap_servers: Kafka bootstrap servers

    Returns:
        ReminderEventProducer instance
    """
    global _reminder_producer
    if _reminder_producer is None:
        _reminder_producer = ReminderEventProducer(bootstrap_servers=bootstrap_servers)
        await _reminder_producer.start()
    return _reminder_producer


async def get_recurring_task_producer(bootstrap_servers: str = "localhost:9092") -> RecurringTaskEventProducer:
    """Get or create recurring task event producer.

    Args:
        bootstrap_servers: Kafka bootstrap servers

    Returns:
        RecurringTaskEventProducer instance
    """
    global _recurring_task_producer
    if _recurring_task_producer is None:
        _recurring_task_producer = RecurringTaskEventProducer(bootstrap_servers=bootstrap_servers)
        await _recurring_task_producer.start()
    return _recurring_task_producer


async def shutdown_producers() -> None:
    """Shutdown all event producers."""
    global _task_producer, _reminder_producer, _recurring_task_producer

    if _task_producer:
        await _task_producer.stop()
        _task_producer = None

    if _reminder_producer:
        await _reminder_producer.stop()
        _reminder_producer = None

    if _recurring_task_producer:
        await _recurring_task_producer.stop()
        _recurring_task_producer = None

    logger.info("All event producers shut down")
# Force rebuild - Thu Jan 15 00:54:30 PKT 2026
