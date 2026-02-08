"""
Kafka Consumer Template for Event Processing

This template provides a reusable pattern for consuming events from Kafka topics.
"""

from kafka import KafkaConsumer
from kafka.errors import KafkaError
import json
import logging
from typing import Callable, Dict, Any, Optional
from datetime import datetime
import signal
import sys

logger = logging.getLogger(__name__)


class EventConsumer:
    """
    Generic event consumer for Kafka topics.

    Usage:
        def handle_event(event):
            print(f"Processing: {event}")

        consumer = EventConsumer(
            bootstrap_servers=['localhost:9092'],
            topics=['my-events'],
            group_id='my-consumer-group',
            handler=handle_event
        )
        consumer.start()
    """

    def __init__(
        self,
        bootstrap_servers: list[str],
        topics: list[str],
        group_id: str,
        handler: Callable[[Dict[str, Any]], None],
        auto_offset_reset: str = 'earliest',
        **kwargs
    ):
        """
        Initialize Kafka consumer.

        Args:
            bootstrap_servers: List of Kafka broker addresses
            topics: List of topics to subscribe to
            group_id: Consumer group identifier
            handler: Function to process each event
            auto_offset_reset: Where to start reading ('earliest' or 'latest')
            **kwargs: Additional KafkaConsumer configuration
        """
        self.topics = topics
        self.handler = handler
        self.running = False

        # Default configuration
        config = {
            'bootstrap_servers': bootstrap_servers,
            'group_id': group_id,
            'auto_offset_reset': auto_offset_reset,
            'enable_auto_commit': True,
            'auto_commit_interval_ms': 5000,
            'value_deserializer': lambda m: json.loads(m.decode('utf-8')),
            'key_deserializer': lambda k: k.decode('utf-8') if k else None,
        }

        # Override with custom config
        config.update(kwargs)

        try:
            self.consumer = KafkaConsumer(*topics, **config)
            logger.info(f"Kafka consumer initialized for topics: {topics}")
        except Exception as e:
            logger.error(f"Failed to initialize Kafka consumer: {e}")
            raise

        # Setup graceful shutdown
        signal.signal(signal.SIGINT, self._shutdown)
        signal.signal(signal.SIGTERM, self._shutdown)

    def start(self):
        """
        Start consuming events.
        This is a blocking call that runs until stopped.
        """
        self.running = True
        logger.info("Starting event consumer...")

        try:
            for message in self.consumer:
                if not self.running:
                    break

                try:
                    event = message.value
                    logger.debug(
                        f"Received event from {message.topic} "
                        f"partition {message.partition} "
                        f"offset {message.offset}"
                    )

                    # Process event
                    self.handler(event)

                except Exception as e:
                    logger.error(f"Error processing event: {e}")
                    # Continue processing next events
                    continue

        except KafkaError as e:
            logger.error(f"Kafka error: {e}")
        finally:
            self.stop()

    def stop(self):
        """Stop consuming and close consumer."""
        self.running = False
        try:
            self.consumer.close()
            logger.info("Kafka consumer stopped")
        except Exception as e:
            logger.error(f"Error closing consumer: {e}")

    def _shutdown(self, signum, frame):
        """Handle shutdown signals."""
        logger.info(f"Received signal {signum}, shutting down...")
        self.stop()
        sys.exit(0)


# Example: Task Event Handler
def handle_task_event(event: Dict[str, Any]):
    """
    Example handler for task events.

    Args:
        event: Event payload
    """
    event_type = event.get('event_type')
    task_id = event.get('task_id')
    user_id = event.get('user_id')

    logger.info(f"Processing {event_type} event for task {task_id} by user {user_id}")

    if event_type == 'created':
        # Handle task creation
        logger.info(f"Task {task_id} was created")

    elif event_type == 'completed':
        # Handle task completion
        logger.info(f"Task {task_id} was completed")
        # Check if it's a recurring task
        task_data = event.get('task_data', {})
        if task_data.get('is_recurring'):
            logger.info(f"Creating next occurrence for recurring task {task_id}")
            # Logic to create next occurrence

    elif event_type == 'deleted':
        # Handle task deletion
        logger.info(f"Task {task_id} was deleted")

    elif event_type == 'updated':
        # Handle task update
        logger.info(f"Task {task_id} was updated")


# Example: Notification Service Consumer
class NotificationConsumer:
    """
    Specialized consumer for sending notifications.
    """

    def __init__(self, bootstrap_servers: list[str]):
        self.consumer = EventConsumer(
            bootstrap_servers=bootstrap_servers,
            topics=['reminders', 'notifications'],
            group_id='notification-service',
            handler=self.send_notification
        )

    def send_notification(self, event: Dict[str, Any]):
        """
        Send notification based on event.

        Args:
            event: Notification event
        """
        notification_type = event.get('type', 'email')
        user_id = event.get('user_id')
        message = event.get('message')

        logger.info(f"Sending {notification_type} notification to user {user_id}")

        if notification_type == 'email':
            self._send_email(user_id, message)
        elif notification_type == 'push':
            self._send_push_notification(user_id, message)
        elif notification_type == 'sms':
            self._send_sms(user_id, message)

    def _send_email(self, user_id: str, message: str):
        """Send email notification."""
        # Implement email sending logic
        logger.info(f"Email sent to user {user_id}: {message}")

    def _send_push_notification(self, user_id: str, message: str):
        """Send push notification."""
        # Implement push notification logic
        logger.info(f"Push notification sent to user {user_id}: {message}")

    def _send_sms(self, user_id: str, message: str):
        """Send SMS notification."""
        # Implement SMS sending logic
        logger.info(f"SMS sent to user {user_id}: {message}")

    def start(self):
        """Start the notification consumer."""
        self.consumer.start()


# Example: Recurring Task Service Consumer
class RecurringTaskConsumer:
    """
    Specialized consumer for handling recurring tasks.
    """

    def __init__(self, bootstrap_servers: list[str], db_session):
        self.db_session = db_session
        self.consumer = EventConsumer(
            bootstrap_servers=bootstrap_servers,
            topics=['task-events'],
            group_id='recurring-task-service',
            handler=self.handle_recurring_task
        )

    def handle_recurring_task(self, event: Dict[str, Any]):
        """
        Handle recurring task logic.

        Args:
            event: Task event
        """
        if event.get('event_type') != 'completed':
            return

        task_data = event.get('task_data', {})
        if not task_data.get('is_recurring'):
            return

        task_id = event.get('task_id')
        recurrence_pattern = task_data.get('recurrence_pattern')

        logger.info(f"Creating next occurrence for recurring task {task_id}")

        # Calculate next occurrence date
        next_date = self._calculate_next_occurrence(
            task_data.get('due_date'),
            recurrence_pattern
        )

        # Create new task in database
        self._create_next_task(task_data, next_date)

    def _calculate_next_occurrence(self, current_date: str, pattern: str) -> str:
        """Calculate next occurrence date based on pattern."""
        from datetime import datetime, timedelta

        current = datetime.fromisoformat(current_date)

        if pattern == 'daily':
            next_date = current + timedelta(days=1)
        elif pattern == 'weekly':
            next_date = current + timedelta(weeks=1)
        elif pattern == 'monthly':
            next_date = current + timedelta(days=30)
        else:
            next_date = current

        return next_date.isoformat()

    def _create_next_task(self, task_data: dict, next_date: str):
        """Create next task occurrence in database."""
        # Implement database logic to create new task
        logger.info(f"Created next task occurrence for {next_date}")

    def start(self):
        """Start the recurring task consumer."""
        self.consumer.start()


# Main entry point for running consumer as a service
if __name__ == "__main__":
    import os

    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    # Get configuration from environment
    bootstrap_servers = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092').split(',')
    topics = os.getenv('KAFKA_TOPICS', 'task-events').split(',')
    group_id = os.getenv('KAFKA_GROUP_ID', 'default-consumer-group')

    # Create and start consumer
    consumer = EventConsumer(
        bootstrap_servers=bootstrap_servers,
        topics=topics,
        group_id=group_id,
        handler=handle_task_event
    )

    logger.info(f"Starting consumer for topics: {topics}")
    consumer.start()
