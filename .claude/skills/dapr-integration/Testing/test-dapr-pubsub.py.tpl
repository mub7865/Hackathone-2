"""
Unit Tests for Dapr Pub/Sub

This template provides comprehensive test patterns for Dapr pub/sub functionality.
"""

import pytest
from unittest.mock import Mock, patch, MagicMock, call
from datetime import datetime
import json


class TestDaprPublisher:
    """Test suite for Dapr publisher."""

    @pytest.fixture
    def mock_dapr_client(self):
        """Mock DaprClient for testing."""
        with patch('dapr.clients.DaprClient') as mock:
            client_instance = MagicMock()
            mock.return_value.__enter__.return_value = client_instance
            yield client_instance

    @pytest.fixture
    def publisher(self, mock_dapr_client):
        """Create DaprPublisher instance with mocked client."""
        from dapr_pubsub import DaprPublisher
        return DaprPublisher(pubsub_name='test-pubsub')

    def test_publisher_initialization(self):
        """Test that publisher initializes correctly."""
        from dapr_pubsub import DaprPublisher

        publisher = DaprPublisher(pubsub_name='my-pubsub')
        assert publisher.pubsub_name == 'my-pubsub'

    def test_publish_event_success(self, publisher, mock_dapr_client):
        """Test successful event publishing."""
        from dapr_pubsub import BaseEvent

        event = BaseEvent(
            event_id='test-123',
            event_type='created',
            source='test-service',
            data={'key': 'value'}
        )

        result = await publisher.publish('test-topic', event)

        assert result is True
        mock_dapr_client.publish_event.assert_called_once()
        call_args = mock_dapr_client.publish_event.call_args

        assert call_args[1]['pubsub_name'] == 'test-pubsub'
        assert call_args[1]['topic_name'] == 'test-topic'
        assert call_args[1]['data_content_type'] == 'application/json'

    def test_publish_event_with_metadata(self, publisher, mock_dapr_client):
        """Test publishing event with metadata."""
        from dapr_pubsub import BaseEvent

        event = BaseEvent(
            event_id='test-123',
            event_type='created',
            source='test-service',
            data={}
        )

        metadata = {'priority': 'high', 'retry': 'true'}
        result = await publisher.publish('test-topic', event, metadata=metadata)

        assert result is True
        call_args = mock_dapr_client.publish_event.call_args
        assert call_args[1]['publish_metadata'] == metadata

    def test_publish_event_failure(self, publisher, mock_dapr_client):
        """Test handling of publish failures."""
        from dapr_pubsub import BaseEvent

        mock_dapr_client.publish_event.side_effect = Exception("Connection failed")

        event = BaseEvent(
            event_id='test-123',
            event_type='created',
            source='test-service',
            data={}
        )

        result = await publisher.publish('test-topic', event)

        assert result is False

    def test_publish_batch(self, publisher, mock_dapr_client):
        """Test batch publishing."""
        from dapr_pubsub import BaseEvent

        events = [
            BaseEvent(
                event_id=f'test-{i}',
                event_type='created',
                source='test-service',
                data={'index': i}
            )
            for i in range(3)
        ]

        success_count = await publisher.publish_batch('test-topic', events)

        assert success_count == 3
        assert mock_dapr_client.publish_event.call_count == 3


class TestDaprSubscriber:
    """Test suite for Dapr subscriber."""

    @pytest.fixture
    def app(self):
        """Create FastAPI app with Dapr."""
        from fastapi import FastAPI
        from dapr.ext.fastapi import DaprApp

        app = FastAPI()
        dapr_app = DaprApp(app)
        return app

    def test_subscriber_registration(self, app):
        """Test that subscriber is registered correctly."""
        from dapr.ext.fastapi import DaprApp

        dapr_app = DaprApp(app)

        @dapr_app.subscribe(pubsub='test-pubsub', topic='test-topic')
        async def test_subscriber(event_data: dict):
            return {"status": "SUCCESS"}

        # Verify subscription is registered
        assert len(dapr_app._subscriptions) > 0

    def test_event_processing_success(self):
        """Test successful event processing."""
        from dapr_pubsub import event_subscriber

        event_data = {
            'id': 'test-123',
            'type': 'created',
            'data': {'key': 'value'}
        }

        result = await event_subscriber(event_data)

        assert result['status'] == 'SUCCESS'

    def test_event_processing_failure(self):
        """Test event processing failure returns RETRY."""
        from dapr_pubsub import event_subscriber

        # Invalid event data
        event_data = {}

        result = await event_subscriber(event_data)

        assert result['status'] == 'RETRY'

    def test_event_routing(self):
        """Test that events are routed to correct handlers."""
        from dapr_pubsub import process_event

        created_handler = Mock()
        updated_handler = Mock()

        with patch('dapr_pubsub.handle_created_event', created_handler):
            with patch('dapr_pubsub.handle_updated_event', updated_handler):
                # Test created event
                await process_event('created', {'id': 1})
                created_handler.assert_called_once()
                updated_handler.assert_not_called()

                # Reset mocks
                created_handler.reset_mock()
                updated_handler.reset_mock()

                # Test updated event
                await process_event('updated', {'id': 2})
                updated_handler.assert_called_once()
                created_handler.assert_not_called()


class TestFastAPIIntegration:
    """Test FastAPI integration with Dapr pub/sub."""

    @pytest.fixture
    def client(self):
        """Create test client."""
        from fastapi.testclient import TestClient
        from dapr_pubsub import app

        return TestClient(app)

    def test_publish_endpoint(self, client):
        """Test publish endpoint."""
        response = client.post(
            "/publish/test-topic",
            json={
                "event_id": "test-123",
                "event_type": "created",
                "source": "test-service",
                "data": {"key": "value"}
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'published'
        assert data['event_id'] == 'test-123'

    def test_health_endpoint(self, client):
        """Test health check endpoint."""
        response = client.get("/health")

        assert response.status_code == 200
        assert response.json()['status'] == 'healthy'

    def test_dapr_subscribe_endpoint(self, client):
        """Test Dapr subscription endpoint."""
        response = client.get("/dapr/subscribe")

        assert response.status_code == 200
        subscriptions = response.json()
        assert len(subscriptions) > 0
        assert subscriptions[0]['pubsubname'] == 'pubsub'


class TestCloudEventsFormat:
    """Test Cloud Events format compliance."""

    def test_cloud_event_structure(self):
        """Test that events follow Cloud Events v1.0 spec."""
        from dapr_pubsub import CloudEvent

        event = CloudEvent(
            type='com.example.created',
            source='test-service',
            id='test-123',
            data={'key': 'value'}
        )

        assert event.specversion == '1.0'
        assert event.type == 'com.example.created'
        assert event.source == 'test-service'
        assert event.id == 'test-123'
        assert event.datacontenttype == 'application/json'

    def test_cloud_event_serialization(self):
        """Test Cloud Event serialization."""
        from dapr_pubsub import CloudEvent

        event = CloudEvent(
            type='test',
            source='test-service',
            id='test-123',
            data={'key': 'value'}
        )

        event_dict = event.dict()
        assert 'specversion' in event_dict
        assert 'type' in event_dict
        assert 'source' in event_dict
        assert 'id' in event_dict
        assert 'data' in event_dict


# Integration tests (require running Dapr)
@pytest.mark.integration
class TestDaprIntegration:
    """Integration tests with real Dapr."""

    @pytest.mark.skipif(
        not pytest.config.getoption("--run-integration"),
        reason="Integration tests disabled"
    )
    def test_publish_and_consume(self):
        """Test publishing and consuming events with real Dapr."""
        from dapr.clients import DaprClient
        import time

        pubsub_name = 'pubsub'
        topic_name = 'test-integration'

        # Publish event
        with DaprClient() as client:
            event_data = {
                'event_type': 'test',
                'message': 'Integration test',
                'timestamp': datetime.utcnow().isoformat()
            }

            client.publish_event(
                pubsub_name=pubsub_name,
                topic_name=topic_name,
                data=json.dumps(event_data),
                data_content_type='application/json'
            )

        # Wait for event to be processed
        time.sleep(2)

        # Verify event was received (check logs or database)
        # This depends on your subscriber implementation

    @pytest.mark.skipif(
        not pytest.config.getoption("--run-integration"),
        reason="Integration tests disabled"
    )
    def test_event_ordering(self):
        """Test that events maintain order within partition."""
        from dapr.clients import DaprClient

        pubsub_name = 'pubsub'
        topic_name = 'test-ordering'

        with DaprClient() as client:
            # Publish events with same key (same partition)
            for i in range(5):
                client.publish_event(
                    pubsub_name=pubsub_name,
                    topic_name=topic_name,
                    data=json.dumps({'sequence': i}),
                    data_content_type='application/json'
                )

        # Verify events are received in order
        # This depends on your subscriber implementation


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
