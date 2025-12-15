"""
Standard FastAPI dependency for JWT-based authentication.

PURPOSE:
- Read the Authorization: Bearer <token> header.
- Verify the JWT using a shared secret or public key.
- Map the token payload to a CurrentUser model.
- Raise 401/403 when auth fails.

HOW TO USE:
- Place this file under something like `app/auth/jwt_dependency.py`.
- Adjust imports for CurrentUser and config to match your project.
- Use `get_current_user` as a dependency in protected routes:

    @router.get("/me")
    def get_me(current_user: CurrentUser = Depends(get_current_user)):
        return current_user
"""

import os
from typing import Optional

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt  # python-jose recommended for FastAPI

from app.auth.models import CurrentUser  # adjust import
# from app.config import JWT_ISSUER, JWT_AUDIENCE  # optional


JWT_SECRET = os.getenv("JWT_SECRET")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")

if not JWT_SECRET:
    raise RuntimeError("JWT_SECRET environment variable is not set")

security_scheme = HTTPBearer(auto_error=False)


def _extract_token_from_auth_header(
    credentials: Optional[HTTPAuthorizationCredentials],
) -> str:
    """
    Extracts the raw token from Authorization: Bearer header.

    Raises HTTP 401 if the header is missing or malformed.
    """
    if credentials is None or not credentials.scheme or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication scheme",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return credentials.credentials


def _decode_and_verify_jwt(token: str) -> dict:
    """
    Decodes and verifies the JWT using the configured secret and algorithm.

    NOTE:
    - For asymmetric keys or JWKS, replace this logic with the appropriate
      key loading and jwt.decode(...) options.
    """
    try:
        payload = jwt.decode(
            token,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM],
            # options / claims verification hooks can be added here:
            # audience=JWT_AUDIENCE,
            # issuer=JWT_ISSUER,
        )
        return payload
    except JWTError:
        # Do not leak internal error details to the client.
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )


def _payload_to_current_user(payload: dict) -> CurrentUser:
    """
    Maps JWT payload fields to CurrentUser model.

    EXPECTATIONS:
    - The token includes a stable user identifier, such as:
        - 'sub', or
        - 'user_id'
    - Adjust this mapping to match your issuer's claim names.
    """
    user_id = payload.get("sub") or payload.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return CurrentUser(
        id=str(user_id),
        email=payload.get("email"),
        roles=payload.get("roles") or [],
        raw_claims=payload,
    )


async def get_current_user(
    request: Request,
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
) -> CurrentUser:
    """
    FastAPI dependency that returns the authenticated CurrentUser
    or raises HTTP 401 if authentication fails.

    HOW TO USE:
    - Add as a dependency on protected routes:

        @router.get("/protected")
        async def protected_route(current_user: CurrentUser = Depends(get_current_user)):
            ...

    - For role-based checks, add additional decorators or dependencies
      that inspect `current_user.roles`.
    """
    token = _extract_token_from_auth_header(credentials)
    payload = _decode_and_verify_jwt(token)
    current_user = _payload_to_current_user(payload)
    return current_user
