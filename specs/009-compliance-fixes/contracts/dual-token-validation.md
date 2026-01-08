# Contract: Dual Token Validation

**Feature**: 009-compliance-fixes
**Date**: 2026-01-07
**Type**: Backend Authentication Contract

## Overview

This contract defines the dual JWT token validation system that accepts both custom JWT tokens (legacy) and Better Auth JWT tokens during the 7-day transition period.

---

## Validation Strategy

### Try-Catch Fallback Pattern

**Decision**: Attempt legacy token validation first, fall back to Better Auth validation

**Rationale**:
- Simplest implementation
- Clear error handling
- Easy to monitor migration progress
- No token introspection required

---

## Implementation

### Backend Configuration

**File**: `app/config.py`

```python
import os
from datetime import datetime, timezone

class Settings:
    # Legacy JWT configuration
    jwt_secret: str = os.getenv("JWT_SECRET", "")
    jwt_algorithm: str = os.getenv("JWT_ALGORITHM", "HS256")

    # Better Auth JWT configuration
    better_auth_secret: str = os.getenv("BETTER_AUTH_SECRET", "")
    better_auth_algorithm: str = "HS256"
    better_auth_issuer: str = "better-auth"

    # Migration control
    auth_migration_enabled: bool = os.getenv("AUTH_MIGRATION_ENABLED", "true").lower() == "true"
    enable_legacy_tokens: bool = os.getenv("ENABLE_LEGACY_TOKENS", "true").lower() == "true"
    legacy_token_cutoff_date: str = os.getenv("LEGACY_TOKEN_CUTOFF_DATE", "")

    def is_legacy_token_allowed(self) -> bool:
        """Check if legacy tokens are still allowed."""
        if not self.enable_legacy_tokens:
            return False

        if not self.legacy_token_cutoff_date:
            return True

        try:
            cutoff = datetime.fromisoformat(self.legacy_token_cutoff_date.replace('Z', '+00:00'))
            return datetime.now(timezone.utc) < cutoff
        except ValueError:
            return True
```

---

### Dual Token Validation Function

**File**: `app/core/auth.py`

```python
from typing import Annotated
from fastapi import Header, Depends
from jose import jwt, JWTError
import logging

from app.config import Settings, get_settings
from app.core.exceptions import AuthenticationError

logger = logging.getLogger(__name__)

def _extract_token(authorization: str | None) -> str:
    """Extract JWT token from Authorization header."""
    if not authorization:
        raise AuthenticationError("Missing Authorization header")

    if not authorization.startswith("Bearer "):
        raise AuthenticationError("Invalid Authorization header format")

    return authorization[7:]  # Remove "Bearer " prefix

async def get_current_user_dual(
    authorization: Annotated[str | None, Header()] = None,
    settings: Annotated[Settings, Depends(get_settings)] = None,
) -> str:
    """Validate JWT from either custom (legacy) or Better Auth issuer.

    This function implements dual token validation during the migration period.
    It attempts to validate tokens in the following order:
    1. Custom JWT (legacy) - if enabled
    2. Better Auth JWT

    Args:
        authorization: Authorization header containing Bearer token
        settings: Application settings

    Returns:
        str: User ID extracted from token's "sub" claim

    Raises:
        AuthenticationError: If token is invalid or expired
    """
    token = _extract_token(authorization)

    # Try custom JWT first (legacy) - if still allowed
    if settings.is_legacy_token_allowed():
        try:
            payload = jwt.decode(
                token,
                settings.jwt_secret,
                algorithms=[settings.jwt_algorithm]
            )
            user_id = payload.get("sub")
            if user_id:
                logger.warning(
                    f"Legacy token used by user {user_id}",
                    extra={"user_id": user_id, "token_type": "legacy"}
                )
                return user_id
        except JWTError as e:
            # Legacy token validation failed, try Better Auth
            logger.debug(f"Legacy token validation failed: {e}")

    # Try Better Auth JWT
    try:
        payload = jwt.decode(
            token,
            settings.better_auth_secret,
            algorithms=[settings.better_auth_algorithm],
            issuer=settings.better_auth_issuer,
            options={"verify_iss": True}
        )
        user_id = payload.get("sub")
        if user_id:
            logger.info(
                f"Better Auth token validated for user {user_id}",
                extra={"user_id": user_id, "token_type": "better_auth"}
            )
            return user_id
    except JWTError as e:
        logger.error(f"Token validation failed: {e}")
        raise AuthenticationError("Invalid or expired token")

    raise AuthenticationError("Token does not contain valid user ID")

async def get_current_user_legacy(
    authorization: Annotated[str | None, Header()] = None,
    settings: Annotated[Settings, Depends(get_settings)] = None,
) -> str:
    """Validate custom JWT token (legacy only).

    This function is used when feature flag disables dual validation.
    """
    token = _extract_token(authorization)

    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm]
        )
        user_id = payload.get("sub")
        if not user_id:
            raise AuthenticationError("Token does not contain user ID")
        return user_id
    except JWTError as e:
        logger.error(f"Legacy token validation failed: {e}")
        raise AuthenticationError("Invalid or expired token")

# Main authentication dependency with feature flag support
async def get_current_user(
    authorization: Annotated[str | None, Header()] = None,
    settings: Annotated[Settings, Depends(get_settings)] = None,
) -> str:
    """Main authentication dependency with feature flag support.

    Routes to dual validation or legacy validation based on feature flags.
    """
    if settings.auth_migration_enabled:
        return await get_current_user_dual(authorization, settings)
    else:
        return await get_current_user_legacy(authorization, settings)
```

---

### Dependency Injection Update

**File**: `app/api/deps.py`

```python
from typing import Annotated
from fastapi import Depends, Request

from app.core.auth import get_current_user

async def get_current_user_with_state(
    request: Request,
    user_id: Annotated[str, Depends(get_current_user)],
) -> str:
    """Get current user and store in request state for logging.

    This dependency now uses dual token validation via get_current_user.
    """
    request.state.user_id = user_id
    return user_id

# Type alias for route dependencies
CurrentUser = Annotated[str, Depends(get_current_user_with_state)]
```

---

## Environment Variables

### Development Environment

```bash
# .env.development
AUTH_MIGRATION_ENABLED=true
ENABLE_LEGACY_TOKENS=true
LEGACY_TOKEN_CUTOFF_DATE=2026-01-15T00:00:00Z

JWT_SECRET=dev-jwt-secret-min-32-chars
BETTER_AUTH_SECRET=dev-better-auth-secret-min-32-chars
```

### Staging Environment

```bash
# .env.staging
AUTH_MIGRATION_ENABLED=true
ENABLE_LEGACY_TOKENS=true
LEGACY_TOKEN_CUTOFF_DATE=2026-01-15T00:00:00Z

JWT_SECRET=${STAGING_JWT_SECRET}
BETTER_AUTH_SECRET=${STAGING_BETTER_AUTH_SECRET}
```

### Production Environment

```bash
# .env.production
AUTH_MIGRATION_ENABLED=true
ENABLE_LEGACY_TOKENS=true
LEGACY_TOKEN_CUTOFF_DATE=2026-01-15T00:00:00Z

JWT_SECRET=${PROD_JWT_SECRET}
BETTER_AUTH_SECRET=${PROD_BETTER_AUTH_SECRET}
```

---

## Migration Timeline

### Day 0: Deployment

```bash
AUTH_MIGRATION_ENABLED=true
ENABLE_LEGACY_TOKENS=true
LEGACY_TOKEN_CUTOFF_DATE=2026-01-15T00:00:00Z  # 7 days from now
```

**Behavior**:
- Both token types accepted
- New logins issue Better Auth tokens
- Existing sessions continue with legacy tokens

### Day 1-7: Transition Period

```bash
# No changes - both tokens still accepted
AUTH_MIGRATION_ENABLED=true
ENABLE_LEGACY_TOKENS=true
```

**Monitoring**:
- Track token usage by type (legacy vs Better Auth)
- Monitor authentication failure rates
- Alert on unusual patterns

### Day 8+: Legacy Token Deprecation

```bash
AUTH_MIGRATION_ENABLED=true
ENABLE_LEGACY_TOKENS=false  # Disable legacy tokens
```

**Behavior**:
- Only Better Auth tokens accepted
- Legacy tokens rejected with 401 error
- Users with expired tokens must re-login

---

## Monitoring and Logging

### Token Usage Metrics

```python
# app/core/logging.py
import logging
from prometheus_client import Counter

# Metrics
token_validation_counter = Counter(
    'auth_token_validations_total',
    'Total number of token validations',
    ['token_type', 'status']
)

def log_token_validation(user_id: str, token_type: str, success: bool):
    """Log token validation for monitoring."""
    status = 'success' if success else 'failure'
    token_validation_counter.labels(token_type=token_type, status=status).inc()

    logger.info(
        f"Token validation: {status}",
        extra={
            "user_id": user_id,
            "token_type": token_type,
            "status": status
        }
    )
```

### Log Examples

```
# Legacy token used
2026-01-07 10:30:00 WARNING Legacy token used by user 550e8400-e29b-41d4-a716-446655440000 {"user_id": "550e8400-e29b-41d4-a716-446655440000", "token_type": "legacy"}

# Better Auth token validated
2026-01-07 10:31:00 INFO Better Auth token validated for user 550e8400-e29b-41d4-a716-446655440000 {"user_id": "550e8400-e29b-41d4-a716-446655440000", "token_type": "better_auth"}

# Token validation failed
2026-01-07 10:32:00 ERROR Token validation failed: Signature verification failed {"error": "JWTError"}
```

---

## Error Handling

### Authentication Errors

```python
# app/core/exceptions.py
class AuthenticationError(Exception):
    """Raised when authentication fails."""
    pass

# app/main.py - Exception handler
@app.exception_handler(AuthenticationError)
async def authentication_exception_handler(request: Request, exc: AuthenticationError):
    """Handle authentication errors with RFC 7807 format."""
    return JSONResponse(
        status_code=401,
        content={
            "type": "https://calm-orbit-todo.com/errors/authentication-failed",
            "title": "Authentication Failed",
            "status": 401,
            "detail": str(exc),
            "instance": request.url.path
        }
    )
```

### Error Response Examples

```json
// Invalid token
{
  "type": "https://calm-orbit-todo.com/errors/authentication-failed",
  "title": "Authentication Failed",
  "status": 401,
  "detail": "Invalid or expired token",
  "instance": "/api/v1/tasks"
}

// Missing Authorization header
{
  "type": "https://calm-orbit-todo.com/errors/authentication-failed",
  "title": "Authentication Failed",
  "status": 401,
  "detail": "Missing Authorization header",
  "instance": "/api/v1/tasks"
}

// Legacy tokens disabled
{
  "type": "https://calm-orbit-todo.com/errors/authentication-failed",
  "title": "Authentication Failed",
  "status": 401,
  "detail": "Legacy tokens are no longer accepted. Please log in again.",
  "instance": "/api/v1/tasks"
}
```

---

## Testing Contract

### Unit Tests

**File**: `tests/unit/test_dual_token_validation.py`

```python
import pytest
from datetime import datetime, timedelta, timezone
from jose import jwt

from app.core.auth import get_current_user_dual
from app.config import Settings
from app.core.exceptions import AuthenticationError

@pytest.fixture
def settings():
    return Settings(
        jwt_secret="test-legacy-secret",
        better_auth_secret="test-better-auth-secret",
        auth_migration_enabled=True,
        enable_legacy_tokens=True
    )

def create_legacy_token(user_id: str, secret: str) -> str:
    """Create legacy JWT token for testing."""
    payload = {
        "sub": user_id,
        "iat": datetime.now(timezone.utc),
        "exp": datetime.now(timezone.utc) + timedelta(hours=24)
    }
    return jwt.encode(payload, secret, algorithm="HS256")

def create_better_auth_token(user_id: str, secret: str) -> str:
    """Create Better Auth JWT token for testing."""
    payload = {
        "sub": user_id,
        "iss": "better-auth",
        "iat": datetime.now(timezone.utc),
        "exp": datetime.now(timezone.utc) + timedelta(hours=24)
    }
    return jwt.encode(payload, secret, algorithm="HS256")

@pytest.mark.asyncio
async def test_legacy_token_accepted(settings):
    """Test that legacy tokens are accepted during migration."""
    user_id = "test-user-123"
    token = create_legacy_token(user_id, settings.jwt_secret)
    authorization = f"Bearer {token}"

    result = await get_current_user_dual(authorization, settings)
    assert result == user_id

@pytest.mark.asyncio
async def test_better_auth_token_accepted(settings):
    """Test that Better Auth tokens are accepted."""
    user_id = "test-user-456"
    token = create_better_auth_token(user_id, settings.better_auth_secret)
    authorization = f"Bearer {token}"

    result = await get_current_user_dual(authorization, settings)
    assert result == user_id

@pytest.mark.asyncio
async def test_invalid_token_rejected(settings):
    """Test that invalid tokens are rejected."""
    authorization = "Bearer invalid-token"

    with pytest.raises(AuthenticationError):
        await get_current_user_dual(authorization, settings)

@pytest.mark.asyncio
async def test_expired_token_rejected(settings):
    """Test that expired tokens are rejected."""
    user_id = "test-user-789"
    payload = {
        "sub": user_id,
        "iat": datetime.now(timezone.utc) - timedelta(hours=25),
        "exp": datetime.now(timezone.utc) - timedelta(hours=1)
    }
    token = jwt.encode(payload, settings.jwt_secret, algorithm="HS256")
    authorization = f"Bearer {token}"

    with pytest.raises(AuthenticationError):
        await get_current_user_dual(authorization, settings)

@pytest.mark.asyncio
async def test_legacy_tokens_disabled_after_cutoff(settings):
    """Test that legacy tokens are rejected after cutoff date."""
    settings.legacy_token_cutoff_date = "2026-01-01T00:00:00Z"  # Past date

    user_id = "test-user-999"
    token = create_legacy_token(user_id, settings.jwt_secret)
    authorization = f"Bearer {token}"

    # Legacy token should be rejected, Better Auth token should work
    with pytest.raises(AuthenticationError):
        await get_current_user_dual(authorization, settings)
```

---

### Integration Tests

**File**: `tests/integration/test_dual_auth_api.py`

```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_api_accepts_both_token_types(client: AsyncClient, legacy_token: str, better_auth_token: str):
    """Test that API endpoints accept both token types."""

    # Test with legacy token
    response = await client.get(
        "/api/v1/tasks",
        headers={"Authorization": f"Bearer {legacy_token}"}
    )
    assert response.status_code == 200

    # Test with Better Auth token
    response = await client.get(
        "/api/v1/tasks",
        headers={"Authorization": f"Bearer {better_auth_token}"}
    )
    assert response.status_code == 200

@pytest.mark.asyncio
async def test_api_rejects_invalid_token(client: AsyncClient):
    """Test that API rejects invalid tokens."""
    response = await client.get(
        "/api/v1/tasks",
        headers={"Authorization": "Bearer invalid-token"}
    )
    assert response.status_code == 401
    assert "authentication-failed" in response.json()["type"]
```

---

## Rollback Strategy

### Instant Rollback via Feature Flag

```bash
# Disable dual validation, revert to legacy only
kubectl patch configmap app-config -p '{"data":{"AUTH_MIGRATION_ENABLED":"false"}}'

# Or disable legacy tokens immediately
kubectl patch configmap app-config -p '{"data":{"ENABLE_LEGACY_TOKENS":"false"}}'
```

### Gradual Rollback

```bash
# Extend cutoff date by 7 days
kubectl patch configmap app-config -p '{"data":{"LEGACY_TOKEN_CUTOFF_DATE":"2026-01-22T00:00:00Z"}}'
```

---

## Security Considerations

1. **Secret Separation**: Different secrets for legacy and Better Auth tokens
2. **Issuer Verification**: Better Auth tokens verified with issuer claim
3. **Expiration Enforcement**: Both token types must have valid exp claim
4. **Logging**: All validation attempts logged for security monitoring
5. **Rate Limiting**: Apply rate limiting to authentication endpoints
6. **Token Rotation**: Encourage users to re-login during transition period

---

## Performance Considerations

1. **Validation Order**: Legacy tokens tried first (most common during transition)
2. **Caching**: JWT verification results cached in memory (FastAPI dependency cache)
3. **Minimal Overhead**: Try-catch pattern adds <1ms latency
4. **No Database Queries**: Token validation is stateless (no DB lookups)

---

**Contract Status**: ✅ Complete
**Implementation Files**: 2 files (auth.py, deps.py)
**Dependencies**: python-jose[cryptography]
**Migration Duration**: 7 days (configurable)
