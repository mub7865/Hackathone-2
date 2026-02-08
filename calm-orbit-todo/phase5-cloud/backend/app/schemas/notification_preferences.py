"""Pydantic schemas for notification preferences API.

This module defines the request/response schemas for the notification preferences API.
"""

from datetime import time
from typing import Optional

from pydantic import BaseModel, Field, field_validator
import pytz

from app.models.notification_preferences import (
    NotificationChannel,
    NotificationFrequency,
)


class NotificationPreferencesUpdate(BaseModel):
    """Request schema for updating notification preferences.

    All fields are optional to support partial updates.
    """

    email_enabled: Optional[bool] = Field(
        default=None,
        description="Whether email notifications are enabled",
    )

    in_app_enabled: Optional[bool] = Field(
        default=None,
        description="Whether in-app notifications are enabled",
    )

    push_enabled: Optional[bool] = Field(
        default=None,
        description="Whether push notifications are enabled",
    )

    sms_enabled: Optional[bool] = Field(
        default=None,
        description="Whether SMS notifications are enabled",
    )

    reminder_frequency: Optional[NotificationFrequency] = Field(
        default=None,
        description="How often to send reminder notifications",
    )

    task_updates_enabled: Optional[bool] = Field(
        default=None,
        description="Whether to receive task update notifications",
    )

    recurring_task_enabled: Optional[bool] = Field(
        default=None,
        description="Whether to receive recurring task notifications",
    )

    quiet_hours_enabled: Optional[bool] = Field(
        default=None,
        description="Whether quiet hours are enabled",
    )

    quiet_hours_start: Optional[time] = Field(
        default=None,
        description="Start time for quiet hours (HH:MM format)",
    )

    quiet_hours_end: Optional[time] = Field(
        default=None,
        description="End time for quiet hours (HH:MM format)",
    )

    timezone: Optional[str] = Field(
        default=None,
        description="User's timezone (IANA timezone string)",
    )

    @field_validator("timezone")
    @classmethod
    def validate_timezone(cls, v: Optional[str]) -> Optional[str]:
        """Validate timezone is a valid IANA timezone string."""
        if v is not None:
            try:
                pytz.timezone(v)
            except pytz.exceptions.UnknownTimeZoneError:
                raise ValueError(f"Invalid timezone: {v}")
        return v

    model_config = {
        "json_schema_extra": {
            "example": {
                "email_enabled": True,
                "in_app_enabled": True,
                "reminder_frequency": "immediate",
                "quiet_hours_enabled": True,
                "quiet_hours_start": "22:00:00",
                "quiet_hours_end": "08:00:00",
                "timezone": "America/New_York",
            }
        },
    }


class NotificationPreferencesResponse(BaseModel):
    """Response schema for notification preferences."""

    id: str = Field(..., description="Unique preferences identifier")
    user_id: str = Field(..., description="User who owns these preferences")

    # Channel preferences
    email_enabled: bool = Field(..., description="Whether email notifications are enabled")
    in_app_enabled: bool = Field(..., description="Whether in-app notifications are enabled")
    push_enabled: bool = Field(..., description="Whether push notifications are enabled")
    sms_enabled: bool = Field(..., description="Whether SMS notifications are enabled")

    # Frequency preferences
    reminder_frequency: NotificationFrequency = Field(
        ...,
        description="How often to send reminder notifications",
    )

    # Notification type preferences
    task_updates_enabled: bool = Field(
        ...,
        description="Whether to receive task update notifications",
    )
    recurring_task_enabled: bool = Field(
        ...,
        description="Whether to receive recurring task notifications",
    )

    # Quiet hours
    quiet_hours_enabled: bool = Field(..., description="Whether quiet hours are enabled")
    quiet_hours_start: Optional[time] = Field(
        default=None,
        description="Start time for quiet hours",
    )
    quiet_hours_end: Optional[time] = Field(
        default=None,
        description="End time for quiet hours",
    )

    # Timezone
    timezone: str = Field(..., description="User's timezone (IANA timezone string)")

    # Timestamps
    created_at: str = Field(..., description="Timestamp when preferences were created")
    updated_at: str = Field(..., description="Timestamp when preferences were last updated")

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "id": "123e4567-e89b-12d3-a456-426614174000",
                "user_id": "user123",
                "email_enabled": True,
                "in_app_enabled": True,
                "push_enabled": False,
                "sms_enabled": False,
                "reminder_frequency": "immediate",
                "task_updates_enabled": True,
                "recurring_task_enabled": True,
                "quiet_hours_enabled": True,
                "quiet_hours_start": "22:00:00",
                "quiet_hours_end": "08:00:00",
                "timezone": "America/New_York",
                "created_at": "2026-01-12T10:30:00Z",
                "updated_at": "2026-01-12T10:30:00Z",
            }
        },
    }


class TimezoneListResponse(BaseModel):
    """Response schema for timezone list."""

    timezones: list[str] = Field(..., description="List of valid IANA timezone strings")

    model_config = {
        "json_schema_extra": {
            "example": {
                "timezones": [
                    "UTC",
                    "America/New_York",
                    "America/Los_Angeles",
                    "Europe/London",
                    "Asia/Tokyo",
                ]
            }
        },
    }
