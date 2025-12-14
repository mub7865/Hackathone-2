"""Application configuration loaded from environment variables."""

import os
from functools import lru_cache

from dotenv import load_dotenv

# Load .env file if present
load_dotenv()


def _convert_database_url(url: str) -> str:
    """Convert standard postgresql:// URL to asyncpg-compatible format.

    - Converts postgresql:// to postgresql+asyncpg://
    - Converts sslmode to ssl for asyncpg compatibility
    - Removes unsupported parameters like channel_binding
    """
    # Convert postgresql:// to postgresql+asyncpg:// for async driver
    if url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
    # asyncpg uses 'ssl' instead of 'sslmode'
    url = url.replace("sslmode=require", "ssl=require")
    # Remove channel_binding parameter (not supported by asyncpg)
    if "&channel_binding=require" in url:
        url = url.replace("&channel_binding=require", "")
    if "?channel_binding=require&" in url:
        url = url.replace("?channel_binding=require&", "?")
    return url


class Settings:
    """Application settings loaded from environment."""

    def __init__(self) -> None:
        raw_url = os.getenv(
            "DATABASE_URL",
            "postgresql+asyncpg://user:password@localhost/todo",
        )
        self.database_url: str = _convert_database_url(raw_url)
        self.environment: str = os.getenv("ENVIRONMENT", "development")

        # JWT settings for Better Auth integration
        self.jwt_secret: str = os.getenv("JWT_SECRET", "")
        self.jwt_algorithm: str = os.getenv("JWT_ALGORITHM", "HS256")

        # Validate JWT_SECRET is set in non-test environments
        if not self.jwt_secret and self.environment == "production":
            raise ValueError("JWT_SECRET must be set in production environment")

    @property
    def is_development(self) -> bool:
        """Check if running in development mode."""
        return self.environment == "development"

    @property
    def is_production(self) -> bool:
        """Check if running in production mode."""
        return self.environment == "production"


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
