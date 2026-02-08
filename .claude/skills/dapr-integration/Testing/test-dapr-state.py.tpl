"""
Unit Tests for Dapr State Management

This template provides comprehensive test patterns for Dapr state store functionality.
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime
import json


class TestDaprStateManager:
    """Test suite for Dapr state manager."""

    @pytest.fixture
    def mock_dapr_client(self):
        """Mock DaprClient for testing."""
        with patch('dapr.clients.DaprClient') as mock:
            client_instance = MagicMock()
            mock.return_value.__enter__.return_value = client_instance
            yield client_instance

    @pytest.fixture
    def state_manager(self, mock_dapr_client):
        """Create DaprStateManager instance with mocked client."""
        from dapr_state import DaprStateManager
        return DaprStateManager(store_name='test-statestore')

    def test_state_manager_initialization(self):
        """Test that state manager initializes correctly."""
        from dapr_state import DaprStateManager

        manager = DaprStateManager(store_name='my-statestore')
        assert manager.store_name == 'my-statestore'

    def test_save_state_success(self, state_manager, mock_dapr_client):
        """Test successful state save."""
        result = state_manager.save(
            key='user:123',
            value={'name': 'John', 'email': 'john@example.com'}
        )

        assert result is True
        mock_dapr_client.save_state.assert_called_once()
        call_args = mock_dapr_client.save_state.call_args

        assert call_args[1]['store_name'] == 'test-statestore'
        assert call_args[1]['key'] == 'user:123'

    def test_save_state_with_ttl(self, state_manager, mock_dapr_client):
        """Test saving state with TTL."""
        result = state_manager.save(
            key='session:abc',
            value={'user_id': '123'},
            ttl_seconds=3600
        )

        assert result is True
        call_args = mock_dapr_client.save_state.call_args
        metadata = call_args[1]['state_metadata']
        assert metadata['ttlInSeconds'] == '3600'

    def test_save_state_with_etag(self, state_manager, mock_dapr_client):
        """Test saving state with ETag for optimistic concurrency."""
        result = state_manager.save(
            key='counter:1',
            value={'count': 10},
            etag='abc123'
        )

        assert result is True
        call_args = mock_dapr_client.save_state.call_args
        assert call_args[1]['etag'] == 'abc123'

    def test_save_state_failure(self, state_manager, mock_dapr_client):
        """Test handling of save failures."""
        mock_dapr_client.save_state.side_effect = Exception("Connection failed")

        result = state_manager.save(
            key='test',
            value={'data': 'test'}
        )

        assert result is False

    def test_get_state_success(self, state_manager, mock_dapr_client):
        """Test successful state retrieval."""
        mock_state = Mock()
        mock_state.data = json.dumps({'name': 'John'}).encode('utf-8')
        mock_dapr_client.get_state.return_value = mock_state

        result = state_manager.get('user:123')

        assert result == {'name': 'John'}
        mock_dapr_client.get_state.assert_called_once_with(
            store_name='test-statestore',
            key='user:123'
        )

    def test_get_state_not_found(self, state_manager, mock_dapr_client):
        """Test getting non-existent state."""
        mock_state = Mock()
        mock_state.data = None
        mock_dapr_client.get_state.return_value = mock_state

        result = state_manager.get('nonexistent')

        assert result is None

    def test_get_state_with_etag(self, state_manager, mock_dapr_client):
        """Test getting state with ETag."""
        mock_state = Mock()
        mock_state.data = json.dumps({'count': 5}).encode('utf-8')
        mock_state.etag = 'etag123'
        mock_dapr_client.get_state.return_value = mock_state

        result = state_manager.get_with_etag('counter:1')

        assert result == ({'count': 5}, 'etag123')

    def test_delete_state_success(self, state_manager, mock_dapr_client):
        """Test successful state deletion."""
        result = state_manager.delete('user:123')

        assert result is True
        mock_dapr_client.delete_state.assert_called_once_with(
            store_name='test-statestore',
            key='user:123',
            etag=None
        )

    def test_delete_state_with_etag(self, state_manager, mock_dapr_client):
        """Test deleting state with ETag."""
        result = state_manager.delete('user:123', etag='abc123')

        assert result is True
        call_args = mock_dapr_client.delete_state.call_args
        assert call_args[1]['etag'] == 'abc123'

    def test_save_bulk(self, state_manager, mock_dapr_client):
        """Test bulk save operation."""
        from dapr_state import StateEntry

        states = [
            StateEntry(key='user:1', value={'name': 'John'}),
            StateEntry(key='user:2', value={'name': 'Jane'}),
            StateEntry(key='user:3', value={'name': 'Bob'})
        ]

        result = state_manager.save_bulk(states)

        assert result is True
        mock_dapr_client.save_bulk_state.assert_called_once()

    def test_get_bulk(self, state_manager, mock_dapr_client):
        """Test bulk get operation."""
        mock_items = [
            Mock(key='user:1', data=json.dumps({'name': 'John'}).encode('utf-8')),
            Mock(key='user:2', data=json.dumps({'name': 'Jane'}).encode('utf-8'))
        ]
        mock_result = Mock()
        mock_result.items = mock_items
        mock_dapr_client.get_bulk_state.return_value = mock_result

        result = state_manager.get_bulk(['user:1', 'user:2'])

        assert len(result) == 2
        assert result['user:1'] == {'name': 'John'}
        assert result['user:2'] == {'name': 'Jane'}

    def test_delete_bulk(self, state_manager, mock_dapr_client):
        """Test bulk delete operation."""
        result = state_manager.delete_bulk(['user:1', 'user:2', 'user:3'])

        assert result is True
        mock_dapr_client.delete_bulk_state.assert_called_once()

    def test_execute_transaction(self, state_manager, mock_dapr_client):
        """Test transaction execution."""
        from dapr.clients.grpc._state import StateItem

        operations = [
            {
                "operation": "upsert",
                "request": StateItem(key="key1", value="value1")
            },
            {
                "operation": "delete",
                "request": StateItem(key="key2")
            }
        ]

        result = state_manager.execute_transaction(operations)

        assert result is True
        mock_dapr_client.execute_state_transaction.assert_called_once()

    def test_increment_counter(self, state_manager, mock_dapr_client):
        """Test atomic counter increment."""
        # Mock get_with_etag to return current value
        mock_state = Mock()
        mock_state.data = json.dumps({'count': 5}).encode('utf-8')
        mock_state.etag = 'etag123'
        mock_dapr_client.get_state.return_value = mock_state

        result = state_manager.increment_counter('page:views', increment=1)

        assert result == 6
        mock_dapr_client.save_state.assert_called_once()

    def test_increment_counter_new(self, state_manager, mock_dapr_client):
        """Test incrementing non-existent counter."""
        # Mock get_with_etag to return None
        mock_state = Mock()
        mock_state.data = None
        mock_dapr_client.get_state.return_value = mock_state

        result = state_manager.increment_counter('new:counter', increment=1)

        assert result == 1

    def test_set_with_ttl(self, state_manager, mock_dapr_client):
        """Test setting state with TTL."""
        result = state_manager.set_with_ttl(
            key='temp:data',
            value={'data': 'temporary'},
            ttl_seconds=60
        )

        assert result is True
        call_args = mock_dapr_client.save_state.call_args
        assert call_args[1]['state_metadata']['ttlInSeconds'] == '60'

    def test_exists(self, state_manager, mock_dapr_client):
        """Test checking if key exists."""
        # Key exists
        mock_state = Mock()
        mock_state.data = json.dumps({'data': 'test'}).encode('utf-8')
        mock_dapr_client.get_state.return_value = mock_state

        assert state_manager.exists('user:123') is True

        # Key doesn't exist
        mock_state.data = None
        assert state_manager.exists('nonexistent') is False


class TestSessionManager:
    """Test suite for SessionManager."""

    @pytest.fixture
    def session_manager(self):
        """Create SessionManager instance."""
        from dapr_state import SessionManager
        with patch('dapr.clients.DaprClient'):
            return SessionManager()

    def test_save_session(self, session_manager):
        """Test saving user session."""
        with patch.object(session_manager, 'save', return_value=True) as mock_save:
            result = session_manager.save_session(
                session_id='abc123',
                user_id='user_456',
                data={'preferences': {'theme': 'dark'}},
                ttl_seconds=3600
            )

            assert result is True
            mock_save.assert_called_once()
            call_args = mock_save.call_args
            assert call_args[1]['key'] == 'session:abc123'
            assert call_args[1]['ttl_seconds'] == 3600

    def test_get_session(self, session_manager):
        """Test getting user session."""
        session_data = {
            'user_id': 'user_456',
            'data': {'preferences': {'theme': 'dark'}}
        }

        with patch.object(session_manager, 'get', return_value=session_data):
            result = session_manager.get_session('abc123')

            assert result == session_data

    def test_delete_session(self, session_manager):
        """Test deleting user session."""
        with patch.object(session_manager, 'delete', return_value=True) as mock_delete:
            result = session_manager.delete_session('abc123')

            assert result is True
            mock_delete.assert_called_once_with(key='session:abc123')


class TestCacheManager:
    """Test suite for CacheManager."""

    @pytest.fixture
    def cache_manager(self):
        """Create CacheManager instance."""
        from dapr_state import CacheManager
        with patch('dapr.clients.DaprClient'):
            return CacheManager()

    def test_cache_set(self, cache_manager):
        """Test setting cache value."""
        with patch.object(cache_manager, 'save', return_value=True) as mock_save:
            result = cache_manager.cache_set(
                key='user:123',
                value={'name': 'John'},
                ttl_seconds=300
            )

            assert result is True
            mock_save.assert_called_once()
            call_args = mock_save.call_args
            assert call_args[1]['key'] == 'cache:user:123'
            assert call_args[1]['ttl_seconds'] == 300

    def test_cache_get(self, cache_manager):
        """Test getting cached value."""
        cache_data = {
            'value': {'name': 'John'},
            'cached_at': datetime.utcnow().isoformat()
        }

        with patch.object(cache_manager, 'get', return_value=cache_data):
            result = cache_manager.cache_get('user:123')

            assert result == {'name': 'John'}

    def test_cache_get_not_found(self, cache_manager):
        """Test getting non-existent cache value."""
        with patch.object(cache_manager, 'get', return_value=None):
            result = cache_manager.cache_get('nonexistent')

            assert result is None

    def test_cache_delete(self, cache_manager):
        """Test deleting cached value."""
        with patch.object(cache_manager, 'delete', return_value=True) as mock_delete:
            result = cache_manager.cache_delete('user:123')

            assert result is True
            mock_delete.assert_called_once_with(key='cache:user:123')


# Integration tests (require running Dapr)
@pytest.mark.integration
class TestDaprStateIntegration:
    """Integration tests with real Dapr."""

    @pytest.mark.skipif(
        not pytest.config.getoption("--run-integration"),
        reason="Integration tests disabled"
    )
    def test_save_and_get(self):
        """Test saving and getting state with real Dapr."""
        from dapr.clients import DaprClient

        store_name = 'statestore'
        key = 'test-integration'
        value = {'message': 'Integration test', 'timestamp': datetime.utcnow().isoformat()}

        # Save state
        with DaprClient() as client:
            client.save_state(
                store_name=store_name,
                key=key,
                value=json.dumps(value)
            )

        # Get state
        with DaprClient() as client:
            state = client.get_state(
                store_name=store_name,
                key=key
            )

            assert state.data is not None
            retrieved_value = json.loads(state.data)
            assert retrieved_value['message'] == 'Integration test'

        # Cleanup
        with DaprClient() as client:
            client.delete_state(store_name=store_name, key=key)

    @pytest.mark.skipif(
        not pytest.config.getoption("--run-integration"),
        reason="Integration tests disabled"
    )
    def test_state_with_ttl(self):
        """Test state with TTL expires correctly."""
        from dapr.clients import DaprClient
        import time

        store_name = 'statestore'
        key = 'test-ttl'
        value = 'temporary'

        # Save with 2 second TTL
        with DaprClient() as client:
            client.save_state(
                store_name=store_name,
                key=key,
                value=value,
                state_metadata={'ttlInSeconds': '2'}
            )

        # Verify it exists
        with DaprClient() as client:
            state = client.get_state(store_name=store_name, key=key)
            assert state.data is not None

        # Wait for expiration
        time.sleep(3)

        # Verify it's gone
        with DaprClient() as client:
            state = client.get_state(store_name=store_name, key=key)
            assert state.data is None


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
