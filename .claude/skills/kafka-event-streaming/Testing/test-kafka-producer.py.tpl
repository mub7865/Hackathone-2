"""
Unit Tests for Kafka Producer

This template provides test patterns for Kafka event publishers.
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime
import json


# Assuming the producer template is imported
# from app.events.publisher import EventPublisher, publish_task_event


class TestEventPublisher:
    """Test suite for EventPublisher class."""

    @pytest.fixture
    def mock_kafka_producer(self):
        """Mock KafkaProducer for testing."""
        with patch('kafka.KafkaProducer') as mock:
            producer_instance = MagicMock()
            mock.return_value = producer_instance
            yield producer_instance

    @pytest.fixture
    def event_publisher(self, mock_kafka_producer):
        """Create EventPublisher instance with mocked Kafka."""
        from app.events.publisher import EventPublisher
        return EventPublisher(
            bootstrap_servers=['localhost:9092'],
            topic='test-events'
        )

    def test_publisher_initialization(self, mock_kafka_producer):
        """Test that publisher initializes correctly."""
        from app.events.publisher import EventPublisher

        publisher = EventPublisher(
            bootstrap_servers=['localhost:9092'],
            topic='test-events'
        )

        assert publisher.topic == 'test-events'
        assert publisher.producer is not None

    def test_publish_event_success(self, event_publisher, mock_kafka_producer):
        """Test successful event publishing."""
        # Setup mock
        future = MagicMock()
        record_metadata = MagicMock()
        record_metadata.topic = 'test-events'
        record_metadata.partition = 0
        record_metadata.offset = 123
        future.get.return_value = record_metadata
        mock_kafka_producer.send.return_value = future

        # Test data
        event_data = {
            'event_type': 'created',
            'task_id': 123,
            'user_id': 'user_456'
        }

        # Publish event
        result = event_publisher.publish(event_data)

        # Assertions
        assert result is True
        mock_kafka_producer.send.assert_called_once()
        call_args = mock_kafka_producer.send.call_args
        assert call_args[0][0] == 'test-events'
        assert 'timestamp' in call_args[1]['value']

    def test_publish_event_with_key(self, event_publisher, mock_kafka_producer):
        """Test publishing event with partition key."""
        future = MagicMock()
        future.get.return_value = MagicMock()
        mock_kafka_producer.send.return_value = future

        event_data = {'event_type': 'test'}
        result = event_publisher.publish(event_data, key='task_123')

        assert result is True
        call_args = mock_kafka_producer.send.call_args
        assert call_args[1]['key'] == 'task_123'

    def test_publish_event_failure(self, event_publisher, mock_kafka_producer):
        """Test handling of publish failures."""
        from kafka.errors import KafkaError

        # Setup mock to raise error
        mock_kafka_producer.send.side_effect = KafkaError("Connection failed")

        event_data = {'event_type': 'test'}
        result = event_publisher.publish(event_data)

        assert result is False

    def test_publish_batch(self, event_publisher, mock_kafka_producer):
        """Test batch publishing."""
        future = MagicMock()
        future.get.return_value = MagicMock()
        mock_kafka_producer.send.return_value = future

        events = [
            {'event_type': 'created', 'task_id': 1},
            {'event_type': 'created', 'task_id': 2},
            {'event_type': 'created', 'task_id': 3}
        ]

        success_count = event_publisher.publish_batch(events)

        assert success_count == 3
        assert mock_kafka_producer.send.call_count == 3
        mock_kafka_producer.flush.assert_called_once()

    def test_publish_adds_timestamp(self, event_publisher, mock_kafka_producer):
        """Test that timestamp is automatically added."""
        future = MagicMock()
        future.get.return_value = MagicMock()
        mock_kafka_producer.send.return_value = future

        event_data = {'event_type': 'test'}
        event_publisher.publish(event_data)

        call_args = mock_kafka_producer.send.call_args
        published_data = call_args[1]['value']
        assert 'timestamp' in published_data

    def test_close_publisher(self, event_publisher, mock_kafka_producer):
        """Test closing publisher."""
        event_publisher.close()

        mock_kafka_producer.flush.assert_called_once()
        mock_kafka_producer.close.assert_called_once()


class TestTaskEventPublishing:
    """Test suite for task-specific event publishing."""

    @pytest.fixture
    def mock_publisher(self):
        """Mock EventPublisher."""
        publisher = Mock()
        publisher.publish.return_value = True
        return publisher

    def test_publish_task_created_event(self, mock_publisher):
        """Test publishing task created event."""
        from app.events.publisher import publish_task_event

        result = publish_task_event(
            publisher=mock_publisher,
            event_type='created',
            task_id=123,
            user_id='user_456',
            task_data={'title': 'Test Task'}
        )

        assert result is True
        mock_publisher.publish.assert_called_once()

        # Verify event structure
        call_args = mock_publisher.publish.call_args
        event_data = call_args[1]['event_data']
        assert event_data['event_type'] == 'created'
        assert event_data['task_id'] == 123
        assert event_data['user_id'] == 'user_456'
        assert 'timestamp' in event_data

    def test_publish_task_event_uses_task_id_as_key(self, mock_publisher):
        """Test that task_id is used as partition key."""
        from app.events.publisher import publish_task_event

        publish_task_event(
            publisher=mock_publisher,
            event_type='created',
            task_id=123,
            user_id='user_456',
            task_data={}
        )

        call_args = mock_publisher.publish.call_args
        assert call_args[1]['key'] == '123'


class TestFastAPIDependency:
    """Test FastAPI dependency injection."""

    def test_get_event_publisher_singleton(self):
        """Test that publisher is singleton."""
        from app.events.publisher import get_event_publisher

        with patch('app.events.publisher.EventPublisher') as mock_class:
            mock_instance = Mock()
            mock_class.return_value = mock_instance

            # First call
            publisher1 = get_event_publisher()
            # Second call
            publisher2 = get_event_publisher()

            # Should return same instance
            assert publisher1 is publisher2
            # Should only create once
            mock_class.assert_called_once()


# Integration test (requires running Kafka)
@pytest.mark.integration
class TestKafkaIntegration:
    """Integration tests with real Kafka (optional)."""

    @pytest.fixture
    def kafka_config(self):
        """Kafka configuration for testing."""
        return {
            'bootstrap_servers': ['localhost:9092'],
            'topic': 'test-events-integration'
        }

    @pytest.mark.skipif(
        not pytest.config.getoption("--run-integration"),
        reason="Integration tests disabled"
    )
    def test_publish_and_consume(self, kafka_config):
        """Test publishing and consuming events (requires Kafka)."""
        from kafka import KafkaProducer, KafkaConsumer
        import json
        import time

        # Create producer
        producer = KafkaProducer(
            bootstrap_servers=kafka_config['bootstrap_servers'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )

        # Create consumer
        consumer = KafkaConsumer(
            kafka_config['topic'],
            bootstrap_servers=kafka_config['bootstrap_servers'],
            auto_offset_reset='earliest',
            group_id='test-group',
            value_deserializer=lambda m: json.loads(m.decode('utf-8'))
        )

        # Publish event
        test_event = {
            'event_type': 'test',
            'message': 'Integration test',
            'timestamp': datetime.utcnow().isoformat()
        }
        producer.send(kafka_config['topic'], value=test_event)
        producer.flush()

        # Consume event
        time.sleep(1)  # Wait for message
        messages = consumer.poll(timeout_ms=5000)

        assert len(messages) > 0

        # Verify event
        for topic_partition, records in messages.items():
            for record in records:
                assert record.value['event_type'] == 'test'
                assert record.value['message'] == 'Integration test'

        # Cleanup
        producer.close()
        consumer.close()


# Pytest configuration
def pytest_addoption(parser):
    """Add custom pytest options."""
    parser.addoption(
        "--run-integration",
        action="store_true",
        default=False,
        help="Run integration tests"
    )


# Run tests
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
