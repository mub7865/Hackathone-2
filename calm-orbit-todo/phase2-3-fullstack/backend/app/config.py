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

        # JWT settings for legacy authentication
        self.jwt_secret: str = os.getenv("JWT_SECRET", "")
        self.jwt_algorithm: str = os.getenv("JWT_ALGORITHM", "HS256")

        # Better Auth settings
        self.better_auth_secret: str = os.getenv("BETTER_AUTH_SECRET", "")

        # Feature flags
        self.use_new_auth: bool = os.getenv("FEATURE_NEW_AUTH", "false").lower() == "true"
        self.use_new_chat: bool = os.getenv("FEATURE_NEW_CHAT", "false").lower() == "true"

        # Rollback flags (highest priority)
        self.rollback_auth: bool = os.getenv("ROLLBACK_AUTH", "false").lower() == "true"
        self.rollback_chat: bool = os.getenv("ROLLBACK_CHAT", "false").lower() == "true"

        # Migration control
        self.auth_migration_enabled: bool = os.getenv("AUTH_MIGRATION_ENABLED", "false").lower() == "true"
        self.enable_legacy_tokens: bool = os.getenv("ENABLE_LEGACY_TOKENS", "false").lower() == "true"
        self.legacy_token_cutoff_date: str = os.getenv("LEGACY_TOKEN_CUTOFF_DATE", "2026-01-15T00:00:00Z")

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

    def is_feature_enabled(self, feature: str) -> bool:
        """Check if feature is enabled with rollback support.

        Args:
            feature: Feature name ("auth" or "chat")

        Returns:
            bool: True if feature is enabled and not rolled back
        """
        rollback_flag = getattr(self, f"rollback_{feature}", False)
        if rollback_flag:
            return False  # Rollback overrides everything

        feature_flag = getattr(self, f"use_new_{feature}", False)
        return feature_flag

    def is_legacy_token_allowed(self) -> bool:
        """Check if legacy tokens are still allowed.

        Returns:
            bool: True if legacy tokens should be accepted
        """
        return self.enable_legacy_tokens


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
