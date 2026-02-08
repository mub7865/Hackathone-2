"""
Unit Tests for Kafka Consumer

This template provides test patterns for Kafka event consumers.
"""

import pytest
from unittest.mock import Mock, patch, MagicMock, call
from datetime import datetime
import json


class TestEventConsumer:
    """Test suite for EventConsumer class."""

    @pytest.fixture
    def mock_kafka_consumer(self):
        """Mock KafkaConsumer for testing."""
        with patch('kafka.KafkaConsumer') as mock:
            consumer_instance = MagicMock()
            mock.return_value = consumer_instance
            yield consumer_instance

    @pytest.fixture
    def mock_handler(self):
        """Mock event handler function."""
        return Mock()

    @pytest.fixture
    def event_consumer(self, mock_kafka_consumer, mock_handler):
        """Create EventConsumer instance with mocked Kafka."""
        from services.consumer import EventConsumer
        return EventConsumer(
            bootstrap_servers=['localhost:9092'],
            topics=['test-events'],
            group_id='test-group',
            handler=mock_handler
        )

    def test_consumer_initialization(self, mock_kafka_consumer, mock_handler):
        """Test that consumer initializes correctly."""
        from services.consumer import EventConsumer

        consumer = EventConsumer(
            bootstrap_servers=['localhost:9092'],
            topics=['test-events', 'other-events'],
            group_id='test-group',
            handler=mock_handler
        )

        assert consumer.topics == ['test-events', 'other-events']
        assert consumer.handler == mock_handler
        assert consumer.consumer is not None

    def test_consumer_processes_events(self, event_consumer, mock_kafka_consumer, mock_handler):
        """Test that consumer processes events correctly."""
        # Setup mock messages
        mock_message1 = Mock()
        mock_message1.topic = 'test-events'
        mock_message1.partition = 0
        mock_message1.offset = 100
        mock_message1.value = {
            'event_type': 'created',
            'task_id': 123,
            'user_id': 'user_456'
        }

        mock_message2 = Mock()
        mock_message2.topic = 'test-events'
        mock_message2.partition = 0
        mock_message2.offset = 101
        mock_message2.value = {
            'event_type': 'updated',
            'task_id': 124,
            'user_id': 'user_789'
        }

        # Make consumer return messages then stop
        mock_kafka_consumer.__iter__ = Mock(return_value=iter([mock_message1, mock_message2]))
        event_consumer.running = False  # Stop after processing

        # Start consumer (will process 2 messages then stop)
        event_consumer.start()

        # Verify handler was called twice
        assert mock_handler.call_count == 2
        mock_handler.assert_has_calls([
            call(mock_message1.value),
            call(mock_message2.value)
        ])

    def test_consumer_handles_processing_errors(self, event_consumer, mock_kafka_consumer, mock_handler):
        """Test that consumer continues after processing errors."""
        # Setup handler to raise error on first call
        mock_handler.side_effect = [
            Exception("Processing error"),
            None  # Second call succeeds
        ]

        # Setup mock messages
        mock_message1 = Mock()
        mock_message1.value = {'event_type': 'test1'}
        mock_message2 = Mock()
        mock_message2.value = {'event_type': 'test2'}

        mock_kafka_consumer.__iter__ = Mock(return_value=iter([mock_message1, mock_message2]))
        event_consumer.running = False

        # Start consumer
        event_consumer.start()

        # Verify both messages were attempted
        assert mock_handler.call_count == 2

    def test_consumer_stop(self, event_consumer, mock_kafka_consumer):
        """Test stopping consumer."""
        event_consumer.stop()

        assert event_consumer.running is False
        mock_kafka_consumer.close.assert_called_once()


class TestNotificationConsumer:
    """Test suite for NotificationConsumer."""

    @pytest.fixture
    def mock_consumer(self):
        """Mock EventConsumer."""
        with patch('services.notification_service.EventConsumer') as mock:
            yield mock

    @pytest.fixture
    def notification_consumer(self, mock_consumer):
        """Create NotificationConsumer instance."""
        from services.notification_service import NotificationConsumer
        return NotificationConsumer(bootstrap_servers=['localhost:9092'])

    def test_handle_reminder_event(self, notification_consumer):
        """Test handling reminder events."""
        # Mock methods
        notification_consumer.get_user = Mock(return_value={
            'id': 'user_123',
            'email': 'test@example.com',
            'phone': '+1234567890'
        })
        notification_consumer._send_email = Mock()

        # Test event
        event = {
            'event_type': 'reminder',
            'task_id': 123,
            'user_id': 'user_123',
            'title': 'Test Task',
            'due_at': '2026-01-15T10:00:00',
            'notification_type': 'email'
        }

        # Handle event
        notification_consumer.send_notification(event)

        # Verify
        notification_consumer.get_user.assert_called_once_with('user_123')
        notification_consumer._send_email.assert_called_once()
        args = notification_consumer._send_email.call_args[0]
        assert args[0] == 'test@example.com'
        assert 'Test Task' in args[1]

    def test_handle_push_notification(self, notification_consumer):
        """Test handling push notifications."""
        notification_consumer.get_user = Mock(return_value={
            'id': 'user_123',
            'email': 'test@example.com'
        })
        notification_consumer._send_push_notification = Mock()

        event = {
            'event_type': 'notification',
            'user_id': 'user_123',
            'notification_type': 'push',
            'subject': 'Test',
            'message': 'Test message'
        }

        notification_consumer.send_notification(event)

        notification_consumer._send_push_notification.assert_called_once()

    def test_handle_sms_notification(self, notification_consumer):
        """Test handling SMS notifications."""
        notification_consumer.get_user = Mock(return_value={
            'id': 'user_123',
            'phone': '+1234567890'
        })
        notification_consumer._send_sms = Mock()

        event = {
            'event_type': 'notification',
            'user_id': 'user_123',
            'notification_type': 'sms',
            'subject': 'Test',
            'message': 'Test message'
        }

        notification_consumer.send_notification(event)

        notification_consumer._send_sms.assert_called_once()

    def test_user_not_found(self, notification_consumer):
        """Test handling when user is not found."""
        notification_consumer.get_user = Mock(return_value=None)
        notification_consumer._send_email = Mock()

        event = {
            'event_type': 'reminder',
            'user_id': 'nonexistent',
            'notification_type': 'email'
        }

        notification_consumer.send_notification(event)

        # Should not send notification
        notification_consumer._send_email.assert_not_called()


class TestRecurringTaskConsumer:
    """Test suite for RecurringTaskConsumer."""

    @pytest.fixture
    def mock_db_session(self):
        """Mock database session."""
        return Mock()

    @pytest.fixture
    def recurring_consumer(self, mock_db_session):
        """Create RecurringTaskConsumer instance."""
        from services.recurring_task_service import RecurringTaskConsumer
        with patch('services.recurring_task_service.EventConsumer'):
            return RecurringTaskConsumer(
                bootstrap_servers=['localhost:9092'],
                db_session=mock_db_session
            )

    def test_handle_completed_recurring_task(self, recurring_consumer):
        """Test handling completed recurring task."""
        recurring_consumer._calculate_next_occurrence = Mock(
            return_value='2026-01-22T10:00:00'
        )
        recurring_consumer._create_next_task = Mock()

        event = {
            'event_type': 'completed',
            'task_id': 123,
            'task_data': {
                'title': 'Weekly Meeting',
                'is_recurring': True,
                'recurrence_pattern': 'weekly',
                'due_date': '2026-01-15T10:00:00'
            }
        }

        recurring_consumer.handle_recurring_task(event)

        # Verify next occurrence was calculated
        recurring_consumer._calculate_next_occurrence.assert_called_once_with(
            '2026-01-15T10:00:00',
            'weekly'
        )

        # Verify next task was created
        recurring_consumer._create_next_task.assert_called_once()

    def test_ignore_non_completed_events(self, recurring_consumer):
        """Test that non-completed events are ignored."""
        recurring_consumer._create_next_task = Mock()

        event = {
            'event_type': 'created',
            'task_id': 123,
            'task_data': {'is_recurring': True}
        }

        recurring_consumer.handle_recurring_task(event)

        # Should not create next task
        recurring_consumer._create_next_task.assert_not_called()

    def test_ignore_non_recurring_tasks(self, recurring_consumer):
        """Test that non-recurring tasks are ignored."""
        recurring_consumer._create_next_task = Mock()

        event = {
            'event_type': 'completed',
            'task_id': 123,
            'task_data': {'is_recurring': False}
        }

        recurring_consumer.handle_recurring_task(event)

        # Should not create next task
        recurring_consumer._create_next_task.assert_not_called()

    def test_calculate_next_occurrence_daily(self, recurring_consumer):
        """Test calculating next occurrence for daily tasks."""
        from datetime import datetime, timedelta

        current_date = '2026-01-15T10:00:00'
        next_date = recurring_consumer._calculate_next_occurrence(current_date, 'daily')

        expected = datetime.fromisoformat(current_date) + timedelta(days=1)
        assert next_date == expected.isoformat()

    def test_calculate_next_occurrence_weekly(self, recurring_consumer):
        """Test calculating next occurrence for weekly tasks."""
        from datetime import datetime, timedelta

        current_date = '2026-01-15T10:00:00'
        next_date = recurring_consumer._calculate_next_occurrence(current_date, 'weekly')

        expected = datetime.fromisoformat(current_date) + timedelta(weeks=1)
        assert next_date == expected.isoformat()

    def test_calculate_next_occurrence_monthly(self, recurring_consumer):
        """Test calculating next occurrence for monthly tasks."""
        from datetime import datetime, timedelta

        current_date = '2026-01-15T10:00:00'
        next_date = recurring_consumer._calculate_next_occurrence(current_date, 'monthly')

        expected = datetime.fromisoformat(current_date) + timedelta(days=30)
        assert next_date == expected.isoformat()


# Integration test
@pytest.mark.integration
class TestConsumerIntegration:
    """Integration tests with real Kafka."""

    @pytest.mark.skipif(
        not pytest.config.getoption("--run-integration"),
        reason="Integration tests disabled"
    )
    def test_consume_published_events(self):
        """Test consuming events published to Kafka."""
        from kafka import KafkaProducer, KafkaConsumer
        import json
        import time

        topic = 'test-integration-consumer'

        # Publish test event
        producer = KafkaProducer(
            bootstrap_servers=['localhost:9092'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )

        test_event = {
            'event_type': 'test',
            'message': 'Consumer integration test',
            'timestamp': datetime.utcnow().isoformat()
        }

        producer.send(topic, value=test_event)
        producer.flush()
        producer.close()

        # Consume event
        consumer = KafkaConsumer(
            topic,
            bootstrap_servers=['localhost:9092'],
            auto_offset_reset='earliest',
            group_id='test-integration-group',
            value_deserializer=lambda m: json.loads(m.decode('utf-8'))
        )

        time.sleep(1)
        messages = consumer.poll(timeout_ms=5000)

        assert len(messages) > 0

        # Verify event
        for records in messages.values():
            for record in records:
                assert record.value['event_type'] == 'test'
                assert record.value['message'] == 'Consumer integration test'

        consumer.close()


# Run tests
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
