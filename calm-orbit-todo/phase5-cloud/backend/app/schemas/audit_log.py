"""Pydantic schemas for audit log API responses.

This module defines the request/response schemas for the audit trail API.
"""

from datetime import datetime
from typing import Any, Dict, Optional
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.audit_log import AuditAction


class AuditLogResponse(BaseModel):
    """Response schema for a single audit log entry.

    Attributes:
        id: Unique log entry identifier.
        user_id: User who performed the action.
        action: The action performed.
        resource_type: Type of resource (e.g., "task").
        resource_id: ID of the resource affected.
        changes: Parsed JSON object containing before/after values.
        ip_address: IP address of the client.
        user_agent: User agent string.
        created_at: Timestamp when action occurred.
    """

    id: UUID = Field(..., description="Unique log entry identifier")
    user_id: str = Field(..., description="User who performed the action")
    action: AuditAction = Field(..., description="The action performed")
    resource_type: str = Field(..., description="Type of resource")
    resource_id: UUID = Field(..., description="ID of the resource affected")
    changes: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Before/after values for updates",
    )
    ip_address: Optional[str] = Field(
        default=None,
        description="IP address of the client",
    )
    user_agent: Optional[str] = Field(
        default=None,
        description="User agent string",
    )
    created_at: datetime = Field(..., description="Timestamp when action occurred")

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "id": "123e4567-e89b-12d3-a456-426614174000",
                "user_id": "user123",
                "action": "updated",
                "resource_type": "task",
                "resource_id": "123e4567-e89b-12d3-a456-426614174001",
                "changes": {
                    "title": {"before": "Old Title", "after": "New Title"},
                    "status": {"before": "pending", "after": "completed"},
                },
                "ip_address": "192.168.1.1",
                "user_agent": "Mozilla/5.0...",
                "created_at": "2026-01-12T10:30:00Z",
            }
        },
    }


class AuditLogListResponse(BaseModel):
    """Response schema for paginated list of audit logs.

    Attributes:
        items: List of audit log entries.
        total: Total number of audit logs matching the filters.
        offset: Number of entries skipped.
        limit: Maximum number of entries returned.
    """

    items: list[AuditLogResponse] = Field(
        ...,
        description="List of audit log entries",
    )
    total: int = Field(..., description="Total number of audit logs")
    offset: int = Field(..., description="Number of entries skipped")
    limit: int = Field(..., description="Maximum number of entries returned")

    model_config = {
        "json_schema_extra": {
            "example": {
                "items": [
                    {
                        "id": "123e4567-e89b-12d3-a456-426614174000",
                        "user_id": "user123",
                        "action": "created",
                        "resource_type": "task",
                        "resource_id": "123e4567-e89b-12d3-a456-426614174001",
                        "changes": None,
                        "ip_address": "192.168.1.1",
                        "user_agent": "Mozilla/5.0...",
                        "created_at": "2026-01-12T10:30:00Z",
                    }
                ],
                "total": 100,
                "offset": 0,
                "limit": 50,
            }
        },
    }


class AuditStatisticsResponse(BaseModel):
    """Response schema for audit statistics.

    Attributes:
        total_actions: Total number of actions in the period.
        actions_by_type: Count of actions grouped by action type.
        actions_by_resource: Count of actions grouped by resource type.
        period_days: Number of days covered by the statistics.
    """

    total_actions: int = Field(..., description="Total number of actions")
    actions_by_type: Dict[str, int] = Field(
        ...,
        description="Count of actions by type (created, updated, etc.)",
    )
    actions_by_resource: Dict[str, int] = Field(
        ...,
        description="Count of actions by resource type (task, filter, etc.)",
    )
    period_days: int = Field(..., description="Number of days covered")

    model_config = {
        "json_schema_extra": {
            "example": {
                "total_actions": 150,
                "actions_by_type": {
                    "created": 50,
                    "updated": 60,
                    "deleted": 10,
                    "completed": 30,
                },
                "actions_by_resource": {
                    "task": 140,
                    "saved_filter": 10,
                },
                "period_days": 30,
            }
        },
    }
