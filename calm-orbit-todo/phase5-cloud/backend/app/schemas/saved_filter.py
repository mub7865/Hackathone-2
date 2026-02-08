"""Pydantic schemas for SavedFilter API request/response validation."""

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class FilterConfig(BaseModel):
    """Schema for filter configuration parameters.

    This represents the actual filter criteria that will be applied
    to task queries.
    """

    status: str | None = Field(default=None, description="Filter by status")
    priority: str | None = Field(default=None, description="Filter by priority")
    tags: list[str] | None = Field(default=None, description="Filter by tags")
    search: str | None = Field(default=None, description="Search term")
    sort: str | None = Field(default=None, description="Sort field")
    order: str | None = Field(default=None, description="Sort order")

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "status": "pending",
                    "priority": "high",
                    "tags": ["urgent", "backend"],
                    "sort": "priority",
                    "order": "desc"
                }
            ]
        }
    }


class SavedFilterCreate(BaseModel):
    """Schema for creating a new saved filter (POST request body)."""

    name: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Filter name (required, 1-100 characters)",
    )
    description: str | None = Field(
        default=None,
        description="Optional filter description",
    )
    filter_config: FilterConfig = Field(
        ...,
        description="Filter configuration parameters",
    )
    is_default: bool = Field(
        default=False,
        description="Whether this should be the default filter",
    )

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "name": "High Priority Pending",
                    "description": "All high priority pending tasks",
                    "filter_config": {
                        "status": "pending",
                        "priority": "high",
                        "sort": "created_at",
                        "order": "desc"
                    },
                    "is_default": False
                }
            ]
        }
    }


class SavedFilterUpdate(BaseModel):
    """Schema for updating an existing saved filter (PATCH request body).

    All fields are optional for partial updates.
    """

    name: str | None = Field(
        default=None,
        min_length=1,
        max_length=100,
        description="Updated filter name",
    )
    description: str | None = Field(
        default=None,
        description="Updated filter description",
    )
    filter_config: FilterConfig | None = Field(
        default=None,
        description="Updated filter configuration",
    )
    is_default: bool | None = Field(
        default=None,
        description="Updated default flag",
    )

    model_config = {
        "json_schema_extra": {
            "examples": [
                {"name": "Updated Filter Name"},
                {"is_default": True},
                {
                    "filter_config": {
                        "status": "completed",
                        "sort": "updated_at"
                    }
                }
            ]
        }
    }


class SavedFilterResponse(BaseModel):
    """Schema for saved filter responses (all endpoints).

    Maps directly from the SavedFilter SQLModel entity.
    """

    id: UUID = Field(description="Unique filter identifier")
    user_id: str = Field(description="Owner's user ID from Better Auth")
    name: str = Field(description="Filter name")
    description: str | None = Field(description="Optional filter description")
    filter_config: FilterConfig = Field(description="Filter configuration parameters")
    is_default: bool = Field(description="Whether this is the default filter")
    created_at: datetime = Field(description="Creation timestamp (UTC)")
    updated_at: datetime = Field(description="Last modification timestamp (UTC)")

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "examples": [
                {
                    "id": "550e8400-e29b-41d4-a716-446655440000",
                    "user_id": "user-123",
                    "name": "High Priority Pending",
                    "description": "All high priority pending tasks",
                    "filter_config": {
                        "status": "pending",
                        "priority": "high",
                        "sort": "created_at",
                        "order": "desc"
                    },
                    "is_default": False,
                    "created_at": "2025-12-13T10:00:00Z",
                    "updated_at": "2025-12-13T10:00:00Z",
                }
            ]
        },
    }
