"""Event consumer services for consuming events from Kafka/Redpanda.

This module provides structured event consumers for different event types
with validation, deserialization, and error handling.
"""

import asyncio
import json
import logging
from typing import Any, Callable, Dict, Optional

from aiokafka import AIOKafkaConsumer
from aiokafka.errors import KafkaError

logger = logging.getLogger(__name__)


class EventConsumer:
    """Base event consumer for consuming events from Kafka."""

    def __init__(
        self,
        topic: str,
        group_id: str,
        bootstrap_servers: str = "localhost:9092",
        topic_prefix: str = "todo-app",
    ):
        """Initialize the event consumer.

        Args:
            topic: Topic name (without prefix)
            group_id: Consumer group ID
            bootstrap_servers: Kafka bootstrap servers
            topic_prefix: Prefix for topic names
        """
        self.topic = f"{topic_prefix}.{topic}"
        self.group_id = group_id
        self.bootstrap_servers = bootstrap_servers
        self.consumer: Optional[AIOKafkaConsumer] = None
        self.running = False
        self.handlers: Dict[str, Callable] = {}

    async def start(self) -> None:
        """Start the Kafka consumer."""
        try:
            self.consumer = AIOKafkaConsumer(
                self.topic,
                bootstrap_servers=self.bootstrap_servers,
                group_id=self.group_id,
                value_deserializer=lambda m: json.loads(m.decode("utf-8")),
                auto_offset_reset="earliest",
                enable_auto_commit=True,
            )
            await self.consumer.start()
            logger.info(
                f"Event consumer started: topic={self.topic}, group={self.group_id}"
            )
        except Exception as e:
            logger.error(f"Failed to start event consumer: {e}", exc_info=True)
            raise

    async def stop(self) -> None:
        """Stop the Kafka consumer."""
        self.running = False
        if self.consumer:
            await self.consumer.stop()
            logger.info(f"Event consumer stopped: topic={self.topic}")

    def register_handler(
        self, event_type: str, handler: Callable
    ) -> None:
        """Register an event handler for a specific event type.

        Args:
            event_type: Type of event to handle
            handler: Async function to handle the event
        """
        self.handlers[event_type] = handler
        logger.info(f"Registered handler for event type: {event_type}")

    async def consume(self) -> None:
        """Start consuming events from Kafka.

        This method runs indefinitely until stop() is called.
        """
        if not self.consumer:
            logger.error("Consumer not started")
            return

        self.running = True
        logger.info(f"Starting event consumption: topic={self.topic}")

        try:
            async for message in self.consumer:
                if not self.running:
                    break

                try:
                    # Parse event envelope
                    event = message.value
                    event_type = event.get("event_type")
                    event_id = event.get("event_id")
                    event_data = event.get("data", {})

                    logger.debug(
                        f"Received event: type={event_type}, id={event_id}"
                    )

                    # Find and execute handler
                    handler = self.handlers.get(event_type)
                    if handler:
                        await handler(event_data)
                        logger.info(
                            f"Processed event: type={event_type}, id={event_id}"
                        )
                    else:
                        logger.warning(
                            f"No handler for event type: {event_type}"
                        )

                except Exception as e:
                    logger.error(
                        f"Error processing event: {e}",
                        exc_info=True,
                    )
                    # Continue processing other events

        except KafkaError as e:
            logger.error(f"Kafka error consuming events: {e}", exc_info=True)
        except Exception as e:
            logger.error(f"Error consuming events: {e}", exc_info=True)
        finally:
            self.running = False


class TaskEventConsumer(EventConsumer):
    """Consumer for task-related events."""

    def __init__(
        self,
        group_id: str = "task-event-consumer",
        bootstrap_servers: str = "localhost:9092",
    ):
        """Initialize task event consumer.

        Args:
            group_id: Consumer group ID
            bootstrap_servers: Kafka bootstrap servers
        """
        super().__init__(
            topic="task-events",
            group_id=group_id,
            bootstrap_servers=bootstrap_servers,
        )

    async def handle_task_created(self, event_data: Dict[str, Any]) -> None:
        """Handle task created event.

        Args:
            event_data: Event payload
        """
        task_id = event_data.get("task_id")
        user_id = event_data.get("user_id")
        title = event_data.get("title")

        logger.info(
            f"Task created: id={task_id}, user={user_id}, title={title}"
        )

        # TODO: Implement business logic
        # - Send notification
        # - Update analytics
        # - Trigger webhooks

    async def handle_task_updated(self, event_data: Dict[str, Any]) -> None:
        """Handle task updated event.

        Args:
            event_data: Event payload
        """
        task_id = event_data.get("task_id")
        user_id = event_data.get("user_id")
        updates = event_data.get("updates", {})

        logger.info(
            f"Task updated: id={task_id}, user={user_id}, updates={updates}"
        )

        # TODO: Implement business logic
        # - Send notification
        # - Update search index
        # - Sync to external systems

    async def handle_task_deleted(self, event_data: Dict[str, Any]) -> None:
        """Handle task deleted event.

        Args:
            event_data: Event payload
        """
        task_id = event_data.get("task_id")
        user_id = event_data.get("user_id")

        logger.info(f"Task deleted: id={task_id}, user={user_id}")

        # TODO: Implement business logic
        # - Send notification
        # - Clean up related data
        # - Update analytics

    async def handle_task_completed(self, event_data: Dict[str, Any]) -> None:
        """Handle task completed event.

        Args:
            event_data: Event payload
        """
        task_id = event_data.get("task_id")
        user_id = event_data.get("user_id")

        logger.info(f"Task completed: id={task_id}, user={user_id}")

        # TODO: Implement business logic
        # - Send congratulations notification
        # - Update user statistics
        # - Trigger rewards/gamification

    def setup_handlers(self) -> None:
        """Register all event handlers."""
        self.register_handler("task.created", self.handle_task_created)
        self.register_handler("task.updated", self.handle_task_updated)
        self.register_handler("task.deleted", self.handle_task_deleted)
        self.register_handler("task.completed", self.handle_task_completed)


class ReminderEventConsumer(EventConsumer):
    """Consumer for reminder-related events."""

    def __init__(
        self,
        group_id: str = "reminder-event-consumer",
        bootstrap_servers: str = "localhost:9092",
    ):
        """Initialize reminder event consumer.

        Args:
            group_id: Consumer group ID
            bootstrap_servers: Kafka bootstrap servers
        """
        super().__init__(
            topic="reminders",
            group_id=group_id,
            bootstrap_servers=bootstrap_servers,
        )

    async def handle_reminder_due(self, event_data: Dict[str, Any]) -> None:
        """Handle reminder due event.

        Args:
            event_data: Event payload
        """
        task_id = event_data.get("task_id")
        user_id = event_data.get("user_id")
        title = event_data.get("title")
        due_date = event_data.get("due_date")

        logger.info(
            f"Reminder due: task={task_id}, user={user_id}, due={due_date}"
        )

        # TODO: Implement business logic
        # - Check notification preferences
        # - Check quiet hours
        # - Send email notification
        # - Send in-app notification
        # - Check rate limits

    def setup_handlers(self) -> None:
        """Register all event handlers."""
        self.register_handler("reminder.due", self.handle_reminder_due)


class RecurringTaskEventConsumer(EventConsumer):
    """Consumer for recurring task events."""

    def __init__(
        self,
        group_id: str = "recurring-task-event-consumer",
        bootstrap_servers: str = "localhost:9092",
    ):
        """Initialize recurring task event consumer.

        Args:
            group_id: Consumer group ID
            bootstrap_servers: Kafka bootstrap servers
        """
        super().__init__(
            topic="recurring-tasks",
            group_id=group_id,
            bootstrap_servers=bootstrap_servers,
        )

    async def handle_recurring_task_generated(
        self, event_data: Dict[str, Any]
    ) -> None:
        """Handle recurring task generated event.

        Args:
            event_data: Event payload
        """
        pattern_id = event_data.get("pattern_id")
        task_id = event_data.get("task_id")
        user_id = event_data.get("user_id")
        title = event_data.get("title")

        logger.info(
            f"Recurring task generated: pattern={pattern_id}, task={task_id}, user={user_id}"
        )

        # TODO: Implement business logic
        # - Send notification about new task
        # - Update recurring pattern statistics
        # - Check if pattern should continue

    def setup_handlers(self) -> None:
        """Register all event handlers."""
        self.register_handler(
            "recurring_task.generated",
            self.handle_recurring_task_generated,
        )


# Global consumer instances
_task_consumer: Optional[TaskEventConsumer] = None
_reminder_consumer: Optional[ReminderEventConsumer] = None
_recurring_task_consumer: Optional[RecurringTaskEventConsumer] = None


async def start_task_consumer(bootstrap_servers: str = "localhost:9092") -> TaskEventConsumer:
    """Start task event consumer.

    Args:
        bootstrap_servers: Kafka bootstrap servers

    Returns:
        TaskEventConsumer instance
    """
    global _task_consumer
    if _task_consumer is None:
        _task_consumer = TaskEventConsumer(bootstrap_servers=bootstrap_servers)
        _task_consumer.setup_handlers()
        await _task_consumer.start()
        # Start consuming in background
        asyncio.create_task(_task_consumer.consume())
    return _task_consumer


async def start_reminder_consumer(bootstrap_servers: str = "localhost:9092") -> ReminderEventConsumer:
    """Start reminder event consumer.

    Args:
        bootstrap_servers: Kafka bootstrap servers

    Returns:
        ReminderEventConsumer instance
    """
    global _reminder_consumer
    if _reminder_consumer is None:
        _reminder_consumer = ReminderEventConsumer(bootstrap_servers=bootstrap_servers)
        _reminder_consumer.setup_handlers()
        await _reminder_consumer.start()
        # Start consuming in background
        asyncio.create_task(_reminder_consumer.consume())
    return _reminder_consumer


async def start_recurring_task_consumer(bootstrap_servers: str = "localhost:9092") -> RecurringTaskEventConsumer:
    """Start recurring task event consumer.

    Args:
        bootstrap_servers: Kafka bootstrap servers

    Returns:
        RecurringTaskEventConsumer instance
    """
    global _recurring_task_consumer
    if _recurring_task_consumer is None:
        _recurring_task_consumer = RecurringTaskEventConsumer(bootstrap_servers=bootstrap_servers)
        _recurring_task_consumer.setup_handlers()
        await _recurring_task_consumer.start()
        # Start consuming in background
        asyncio.create_task(_recurring_task_consumer.consume())
    return _recurring_task_consumer


async def shutdown_consumers() -> None:
    """Shutdown all event consumers."""
    global _task_consumer, _reminder_consumer, _recurring_task_consumer

    if _task_consumer:
        await _task_consumer.stop()
        _task_consumer = None

    if _reminder_consumer:
        await _reminder_consumer.stop()
        _reminder_consumer = None

    if _recurring_task_consumer:
        await _recurring_task_consumer.stop()
        _recurring_task_consumer = None

    logger.info("All event consumers shut down")
