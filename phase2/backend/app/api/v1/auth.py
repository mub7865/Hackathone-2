"""Authentication API endpoints.

Provides user registration and login with JWT token issuance.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.api.deps import get_db
from app.config import Settings, get_settings
from app.core.auth import create_access_token, hash_password, verify_password
from app.models.user import User, UserRead
from app.schemas.auth import AuthResponse, LoginRequest, RegisterRequest

router = APIRouter(prefix="/auth", tags=["auth"])


def _build_auth_response(user: User, settings: Settings) -> AuthResponse:
    """Build authentication response with token.

    Args:
        user: Authenticated user
        settings: Application settings

    Returns:
        AuthResponse with user data and access token
    """
    token, expires_at = create_access_token(user.id, settings)

    return AuthResponse(
        user=UserRead(
            id=user.id,
            email=user.email,
            name=user.name,
            created_at=user.created_at,
        ),
        access_token=token,
        token_type="bearer",
        expires_at=expires_at.isoformat(),
    )


@router.post(
    "/register",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
    description="Create a new user account and return authentication tokens.",
)
async def register(
    request: RegisterRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> AuthResponse:
    """Register a new user.

    Args:
        request: Registration data (email, password, optional name)
        db: Database session
        settings: Application settings

    Returns:
        AuthResponse with user data and access token

    Raises:
        HTTPException 409: If email is already registered
        HTTPException 500: If JWT_SECRET is not configured
    """
    # Check if user already exists
    stmt = select(User).where(User.email == request.email)
    result = await db.execute(stmt)
    existing_user = result.scalar_one_or_none()

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    # Validate JWT_SECRET is configured
    if not settings.jwt_secret:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Authentication not configured. Set JWT_SECRET environment variable.",
        )

    # Create new user with hashed password
    user = User(
        email=request.email,
        name=request.name,
        hashed_password=hash_password(request.password),
    )

    db.add(user)
    await db.commit()
    await db.refresh(user)

    return _build_auth_response(user, settings)


@router.post(
    "/login",
    response_model=AuthResponse,
    summary="Login user",
    description="Authenticate with email and password to receive access tokens.",
)
async def login(
    request: LoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> AuthResponse:
    """Login an existing user.

    Args:
        request: Login credentials (email, password)
        db: Database session
        settings: Application settings

    Returns:
        AuthResponse with user data and access token

    Raises:
        HTTPException 401: If credentials are invalid
        HTTPException 500: If JWT_SECRET is not configured
    """
    # Find user by email
    stmt = select(User).where(User.email == request.email)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    # Verify user exists and password is correct
    if not user or not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    # Validate JWT_SECRET is configured
    if not settings.jwt_secret:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Authentication not configured. Set JWT_SECRET environment variable.",
        )

    return _build_auth_response(user, settings)
