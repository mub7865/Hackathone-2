"""Kafka event consumer for processing task events.

This module provides functionality to consume task-related events from Kafka/Redpanda
topics and process them with idempotency guarantees.
"""

import asyncio
import json
import logging
from typing import Any, Callable, Dict, Optional

from aiokafka import AIOKafkaConsumer
from aiokafka.errors import KafkaError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.database import get_session

logger = logging.getLogger(__name__)


class EventConsumer:
    """Kafka event consumer for task events.

    This class manages the lifecycle of a Kafka consumer and provides
    idempotent event processing with database tracking.

    Attributes:
        consumer: AIOKafkaConsumer instance.
        settings: Application settings with Kafka configuration.
        service_name: Name of the consuming service (for idempotency tracking).
        handlers: Dictionary mapping event types to handler functions.
    """

    def __init__(self, service_name: str) -> None:
        """Initialize the event consumer.

        Args:
            service_name: Name of the consuming service (e.g., 'audit-service').
        """
        self.settings = get_settings()
        self.service_name = service_name
        self.consumer: Optional[AIOKafkaConsumer] = None
        self.handlers: Dict[str, Callable] = {}
        self._running = False

    async def start(self, topics: list[str]) -> None:
        """Start the Kafka consumer.

        Args:
            topics: List of Kafka topics to subscribe to.

        Raises:
            KafkaError: If connection to Kafka fails.
        """
        try:
            self.consumer = AIOKafkaConsumer(
                *topics,
                bootstrap_servers=self.settings.kafka_bootstrap_servers,
                group_id=self.settings.kafka_consumer_group,
                value_deserializer=lambda m: json.loads(m.decode("utf-8")),
                auto_offset_reset="earliest",  # Start from beginning if no offset
                enable_auto_commit=False,  # Manual commit for idempotency
                max_poll_records=10,  # Process in small batches
            )
            await self.consumer.start()
            self._running = True
            logger.info(
                f"Kafka consumer started: {self.service_name} on topics {topics}"
            )
        except KafkaError as e:
            logger.error(f"Failed to start Kafka consumer: {e}")
            raise

    async def stop(self) -> None:
        """Stop the Kafka consumer gracefully."""
        self._running = False
        if self.consumer:
            await self.consumer.stop()
            logger.info(f"Kafka consumer stopped: {self.service_name}")

    def register_handler(
        self, event_type: str, handler: Callable[[Dict[str, Any], AsyncSession], None]
    ) -> None:
        """Register an event handler for a specific event type.

        Args:
            event_type: Event type to handle (e.g., 'task.created').
            handler: Async function that processes the event.
                     Signature: async def handler(event: Dict, session: AsyncSession) -> None
        """
        self.handlers[event_type] = handler
        logger.info(f"Registered handler for {event_type}")

    async def is_event_processed(
        self, event_id: str, session: AsyncSession
    ) -> bool:
        """Check if an event has already been processed by this service.

        Args:
            event_id: Event ID to check.
            session: Database session.

        Returns:
            True if event was already processed, False otherwise.
        """
        from sqlalchemy import select, text

        # Check processed_events table
        query = text(
            "SELECT 1 FROM processed_events WHERE event_id = :event_id AND service_name = :service_name"
        )
        result = await session.execute(
            query, {"event_id": event_id, "service_name": self.service_name}
        )
        return result.scalar_one_or_none() is not None

    async def mark_event_processed(
        self, event_id: str, event_type: str, session: AsyncSession
    ) -> None:
        """Mark an event as processed in the database.

        Args:
            event_id: Event ID.
            event_type: Event type.
            session: Database session.
        """
        from sqlalchemy import text

        query = text(
            """
            INSERT INTO processed_events (event_id, service_name, event_type, processed_at)
            VALUES (:event_id, :service_name, :event_type, NOW())
            ON CONFLICT (event_id, service_name) DO NOTHING
            """
        )
        await session.execute(
            query,
            {
                "event_id": event_id,
                "service_name": self.service_name,
                "event_type": event_type,
            },
        )
        await session.commit()

    async def process_event(self, event: Dict[str, Any]) -> None:
        """Process a single event with idempotency check.

        Args:
            event: Event data from Kafka.
        """
        event_id = event.get("event_id")
        event_type = event.get("event_type")

        if not event_id or not event_type:
            logger.warning(f"Invalid event format: {event}")
            return

        # Get database session
        async for session in get_session():
            try:
                # Check if event already processed (idempotency)
                if await self.is_event_processed(event_id, session):
                    logger.debug(
                        f"Event {event_id} already processed by {self.service_name}, skipping"
                    )
                    return

                # Find handler for event type
                handler = self.handlers.get(event_type)
                if not handler:
                    logger.warning(
                        f"No handler registered for event type: {event_type}"
                    )
                    return

                # Process event
                logger.info(
                    f"Processing event {event_id} ({event_type}) in {self.service_name}"
                )
                await handler(event, session)

                # Mark as processed
                await self.mark_event_processed(event_id, event_type, session)
                logger.info(f"Event {event_id} processed successfully")

            except Exception as e:
                logger.error(f"Error processing event {event_id}: {e}", exc_info=True)
                await session.rollback()
                raise

    async def consume_loop(self) -> None:
        """Main consumption loop.

        Continuously polls for messages and processes them.
        """
        if not self.consumer:
            raise RuntimeError("Consumer not started. Call start() first.")

        logger.info(f"Starting consumption loop for {self.service_name}")

        try:
            while self._running:
                # Poll for messages
                result = await self.consumer.getmany(timeout_ms=1000, max_records=10)

                for topic_partition, messages in result.items():
                    for message in messages:
                        try:
                            event = message.value
                            await self.process_event(event)

                            # Commit offset after successful processing
                            await self.consumer.commit()

                        except Exception as e:
                            logger.error(
                                f"Failed to process message from {topic_partition}: {e}"
                            )
                            # Don't commit offset on error - will retry on next poll

                # Small delay to prevent tight loop
                await asyncio.sleep(0.1)

        except asyncio.CancelledError:
            logger.info(f"Consumption loop cancelled for {self.service_name}")
        except Exception as e:
            logger.error(f"Fatal error in consumption loop: {e}", exc_info=True)
            raise


# Example handler functions (to be implemented by consuming services)


async def handle_task_created(event: Dict[str, Any], session: AsyncSession) -> None:
    """Example handler for task.created events.

    Args:
        event: Event data.
        session: Database session.
    """
    payload = event.get("payload", {})
    task_id = payload.get("task_id")
    user_id = payload.get("user_id")
    title = payload.get("title")

    logger.info(f"Task created: {task_id} by user {user_id} - {title}")
    # Implement service-specific logic here


async def handle_task_updated(event: Dict[str, Any], session: AsyncSession) -> None:
    """Example handler for task.updated events.

    Args:
        event: Event data.
        session: Database session.
    """
    payload = event.get("payload", {})
    task_id = payload.get("task_id")
    updates = payload.get("updates", {})

    logger.info(f"Task updated: {task_id} - {updates}")
    # Implement service-specific logic here


async def handle_task_deleted(event: Dict[str, Any], session: AsyncSession) -> None:
    """Example handler for task.deleted events.

    Args:
        event: Event data.
        session: Database session.
    """
    payload = event.get("payload", {})
    task_id = payload.get("task_id")

    logger.info(f"Task deleted: {task_id}")
    # Implement service-specific logic here


async def handle_task_completed(event: Dict[str, Any], session: AsyncSession) -> None:
    """Example handler for task.completed events.

    Args:
        event: Event data.
        session: Database session.
    """
    payload = event.get("payload", {})
    task_id = payload.get("task_id")

    logger.info(f"Task completed: {task_id}")
    # Implement service-specific logic here


async def start_consumer(
    service_name: str,
    topics: list[str],
    handlers: Dict[str, Callable],
) -> EventConsumer:
    """Start an event consumer with registered handlers.

    Args:
        service_name: Name of the consuming service.
        topics: List of Kafka topics to subscribe to.
        handlers: Dictionary mapping event types to handler functions.

    Returns:
        EventConsumer instance.

    Example:
        consumer = await start_consumer(
            service_name="audit-service",
            topics=["task-events"],
            handlers={
                "task.created": handle_task_created,
                "task.updated": handle_task_updated,
                "task.deleted": handle_task_deleted,
                "task.completed": handle_task_completed,
            }
        )
        await consumer.consume_loop()
    """
    consumer = EventConsumer(service_name)

    # Register handlers
    for event_type, handler in handlers.items():
        consumer.register_handler(event_type, handler)

    # Start consumer
    await consumer.start(topics)

    return consumer
