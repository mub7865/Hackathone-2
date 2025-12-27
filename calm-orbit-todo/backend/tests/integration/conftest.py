"""Integration test fixtures for Tasks API.

Provides TestClient, mock JWT tokens, and database fixtures.
Uses real Neon database per SC-008.
"""

import os
from datetime import datetime, timedelta, timezone
from typing import AsyncGenerator

import pytest
from httpx import ASGITransport, AsyncClient
from jose import jwt
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool

# Ensure test environment is set before importing app
os.environ["JWT_SECRET"] = "test-secret-key-for-testing-only"
os.environ["ENVIRONMENT"] = "test"

# Test JWT configuration - must match what's in environment
TEST_JWT_SECRET = "test-secret-key-for-testing-only"
TEST_JWT_ALGORITHM = "HS256"

# Test user IDs
TEST_USER_ID = "test-user-001"
OTHER_USER_ID = "test-user-002"


def create_test_token(
    user_id: str,
    expired: bool = False,
    missing_sub: bool = False,
) -> str:
    """Create a JWT token for testing.

    Args:
        user_id: User ID to include in 'sub' claim
        expired: If True, create an expired token
        missing_sub: If True, omit the 'sub' claim

    Returns:
        JWT token string
    """
    now = datetime.now(timezone.utc)
    exp = now - timedelta(hours=1) if expired else now + timedelta(hours=1)

    payload = {
        "iat": now,
        "exp": exp,
    }

    if not missing_sub:
        payload["sub"] = user_id

    return jwt.encode(payload, TEST_JWT_SECRET, algorithm=TEST_JWT_ALGORITHM)


@pytest.fixture
def auth_headers() -> dict[str, str]:
    """Get Authorization headers for test user."""
    token = create_test_token(TEST_USER_ID)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def other_user_headers() -> dict[str, str]:
    """Get Authorization headers for a different test user."""
    token = create_test_token(OTHER_USER_ID)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def expired_token_headers() -> dict[str, str]:
    """Get Authorization headers with expired token."""
    token = create_test_token(TEST_USER_ID, expired=True)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def invalid_token_headers() -> dict[str, str]:
    """Get Authorization headers with invalid token."""
    return {"Authorization": "Bearer invalid-token-format"}


@pytest.fixture
def missing_sub_headers() -> dict[str, str]:
    """Get Authorization headers with token missing 'sub' claim."""
    token = create_test_token(TEST_USER_ID, missing_sub=True)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    """Async HTTP client for testing API endpoints.

    Uses NullPool to avoid connection pooling issues with async tests.
    Each request gets a fresh connection.
    """
    # Import fresh for each test to avoid cached engine issues
    from app.config import get_settings
    from app.database import get_session, reset_engine
    from app.main import app

    # Reset the module-level engine to avoid event loop binding issues
    reset_engine()

    settings = get_settings()

    # Use NullPool for testing - no connection reuse, avoids async conflicts
    test_engine = create_async_engine(
        settings.database_url,
        echo=False,
        poolclass=NullPool,
    )

    TestingSessionLocal = async_sessionmaker(
        test_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )

    async def override_get_session() -> AsyncGenerator[AsyncSession, None]:
        async with TestingSessionLocal() as session:
            yield session

    # Override the dependency for this test
    app.dependency_overrides[get_session] = override_get_session

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac

    # Cleanup
    app.dependency_overrides.clear()
    await test_engine.dispose()
