"""User model for authentication.

Stores user credentials with secure password hashing using passlib/bcrypt.
"""

from datetime import datetime
from typing import Optional
import uuid

from sqlmodel import SQLModel, Field


class UserBase(SQLModel):
    """Base user fields shared across schemas."""

    email: str = Field(index=True, unique=True, max_length=255)
    name: Optional[str] = Field(default=None, max_length=255)


class User(UserBase, table=True):
    """User database model.

    Stores user authentication data with hashed passwords.
    The id is a UUID string for consistency with task.user_id.
    """

    __tablename__ = "users"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        max_length=36,
    )
    hashed_password: str = Field(max_length=255)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class UserCreate(UserBase):
    """Schema for user registration."""

    password: str = Field(min_length=8, max_length=128)


class UserRead(UserBase):
    """Schema for user responses (excludes password)."""

    id: str
    created_at: datetime
