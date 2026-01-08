"""JWT authentication for Better Auth integration.

Validates JWT tokens from the Authorization header and extracts user identity.
Uses the 'sub' claim (RFC 7519 standard) for user ID.
Also provides token creation and password hashing utilities.
Supports dual token validation for migration from legacy JWT to Better Auth.
"""

import logging
from datetime import datetime, timedelta
from typing import Annotated

import bcrypt
from fastapi import Depends, Header
from jose import JWTError, jwt

from app.config import Settings, get_settings
from app.core.exceptions import AuthenticationError

logger = logging.getLogger(__name__)

# Token expiration time (24 hours)
ACCESS_TOKEN_EXPIRE_HOURS = 24


def hash_password(password: str) -> str:
    """Hash a password using bcrypt.

    Args:
        password: Plain text password

    Returns:
        Hashed password string
    """
    password_bytes = password.encode("utf-8")
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password_bytes, salt)
    return hashed.decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash.

    Args:
        plain_password: Plain text password to verify
        hashed_password: Stored hashed password

    Returns:
        True if password matches, False otherwise
    """
    password_bytes = plain_password.encode("utf-8")
    hashed_bytes = hashed_password.encode("utf-8")
    return bcrypt.checkpw(password_bytes, hashed_bytes)


def create_access_token(user_id: str, settings: Settings) -> tuple[str, datetime]:
    """Create a JWT access token for a user.

    Args:
        user_id: User ID to encode in the 'sub' claim
        settings: Application settings with JWT_SECRET

    Returns:
        Tuple of (token_string, expiration_datetime)

    Raises:
        ValueError: If JWT_SECRET is not configured
    """
    if not settings.jwt_secret:
        raise ValueError("JWT_SECRET must be configured to create tokens")

    expires_at = datetime.utcnow() + timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS)

    payload = {
        "sub": user_id,
        "exp": expires_at,
        "iat": datetime.utcnow(),
    }

    token = jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    return token, expires_at


def _extract_token(authorization: str | None) -> str:
    """Extract Bearer token from Authorization header.

    Args:
        authorization: Authorization header value

    Returns:
        The JWT token string

    Raises:
        AuthenticationError: If header is missing or malformed
    """
    if not authorization:
        raise AuthenticationError("Missing Authorization header")

    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise AuthenticationError("Invalid Authorization header format")

    return parts[1]


def _decode_token(token: str, settings: Settings) -> dict:
    """Decode and verify JWT token.

    Args:
        token: JWT token string
        settings: Application settings with JWT_SECRET

    Returns:
        Decoded token payload

    Raises:
        AuthenticationError: If token is invalid, expired, or malformed
    """
    if not settings.jwt_secret:
        # Allow empty secret in development/test for flexibility
        if settings.environment == "production":
            raise AuthenticationError("JWT configuration error")
        # In dev/test, accept any token structure for testing
        try:
            # Try to decode without verification for testing
            return jwt.get_unverified_claims(token)
        except JWTError as e:
            raise AuthenticationError(f"Invalid token: {e}") from e

    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
        return payload
    except jwt.ExpiredSignatureError as e:
        raise AuthenticationError("Token has expired") from e
    except JWTError as e:
        raise AuthenticationError(f"Invalid token: {e}") from e


async def get_current_user(
    authorization: Annotated[str | None, Header()] = None,
    settings: Annotated[Settings, Depends(get_settings)] = None,
) -> str:
    """FastAPI dependency to get current authenticated user ID.

    Extracts and validates the JWT from the Authorization header,
    then returns the user ID from the 'sub' claim.

    Args:
        authorization: Authorization header value (injected by FastAPI)
        settings: Application settings (injected by FastAPI)

    Returns:
        User ID string from the 'sub' claim

    Raises:
        AuthenticationError: If authentication fails

    Usage:
        @router.get("/tasks")
        async def list_tasks(user_id: str = Depends(get_current_user)):
            ...
    """
    token = _extract_token(authorization)
    payload = _decode_token(token, settings)

    user_id = payload.get("sub")
    if not user_id:
        raise AuthenticationError("Token missing 'sub' claim")

    return user_id


async def get_current_user_dual(
    authorization: Annotated[str | None, Header()] = None,
    settings: Annotated[Settings, Depends(get_settings)] = None,
) -> str:
    """FastAPI dependency with dual token validation (legacy + Better Auth).

    Implements try-catch fallback pattern:
    1. Try legacy JWT validation first (if enabled)
    2. Fall back to Better Auth JWT validation
    3. Log which token type was used for monitoring

    Args:
        authorization: Authorization header value (injected by FastAPI)
        settings: Application settings (injected by FastAPI)

    Returns:
        User ID string from the 'sub' claim

    Raises:
        AuthenticationError: If both validation attempts fail

    Usage:
        @router.get("/tasks")
        async def list_tasks(user_id: str = Depends(get_current_user_dual)):
            ...
    """
    token = _extract_token(authorization)

    # Try legacy JWT first (if enabled)
    if settings.is_legacy_token_allowed():
        try:
            payload = jwt.decode(
                token,
                settings.jwt_secret,
                algorithms=[settings.jwt_algorithm],
            )
            user_id = payload.get("sub")
            if user_id:
                logger.warning(f"Legacy token used by user {user_id}")
                return user_id
        except JWTError:
            # Legacy validation failed, try Better Auth
            pass

    # Try Better Auth JWT
    try:
        if not settings.better_auth_secret:
            raise AuthenticationError("Better Auth not configured")

        payload = jwt.decode(
            token,
            settings.better_auth_secret,
            algorithms=["HS256"],
            issuer="better-auth",
        )
        user_id = payload.get("sub")
        if user_id:
            logger.info(f"Better Auth token used by user {user_id}")
            return user_id
        else:
            raise AuthenticationError("Token missing 'sub' claim")
    except JWTError as e:
        raise AuthenticationError(f"Invalid or expired token: {e}") from e
