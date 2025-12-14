"""Authentication request/response schemas."""

from pydantic import BaseModel, EmailStr, Field

from app.models.user import UserRead


class LoginRequest(BaseModel):
    """Login request payload."""

    email: EmailStr
    password: str = Field(min_length=1)


class RegisterRequest(BaseModel):
    """Registration request payload."""

    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    name: str | None = Field(default=None, max_length=255)


class AuthResponse(BaseModel):
    """Authentication response with user and token."""

    user: UserRead
    access_token: str
    token_type: str = "bearer"
    expires_at: str  # ISO format datetime
