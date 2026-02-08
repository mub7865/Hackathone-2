"""Notification preferences API endpoints.

This module provides REST API endpoints for managing user notification preferences.
"""

import logging
from typing import Any, Dict

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
import pytz

from app.api.deps import get_current_user_id, get_session
from app.schemas.notification_preferences import (
    NotificationPreferencesResponse,
    NotificationPreferencesUpdate,
    TimezoneListResponse,
)
from app.services.notification_preferences_service import (
    NotificationPreferencesService,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/notification-preferences", tags=["notification-preferences"])


@router.get(
    "",
    response_model=NotificationPreferencesResponse,
    summary="Get notification preferences",
    description="Get notification preferences for the current user",
)
async def get_notification_preferences(
    session: AsyncSession = Depends(get_session),
    user_id: str = Depends(get_current_user_id),
) -> NotificationPreferencesResponse:
    """Get notification preferences for the current user.

    Creates default preferences if they don't exist.

    Args:
        session: Database session
        user_id: Current user ID (from JWT)

    Returns:
        NotificationPreferencesResponse

    Raises:
        HTTPException: If query fails
    """
    try:
        service = NotificationPreferencesService(session)
        preferences = await service.get_or_create_preferences(user_id)

        return NotificationPreferencesResponse(
            id=str(preferences.id),
            user_id=preferences.user_id,
            email_enabled=preferences.email_enabled,
            in_app_enabled=preferences.in_app_enabled,
            push_enabled=preferences.push_enabled,
            sms_enabled=preferences.sms_enabled,
            reminder_frequency=preferences.reminder_frequency,
            task_updates_enabled=preferences.task_updates_enabled,
            recurring_task_enabled=preferences.recurring_task_enabled,
            quiet_hours_enabled=preferences.quiet_hours_enabled,
            quiet_hours_start=preferences.quiet_hours_start,
            quiet_hours_end=preferences.quiet_hours_end,
            timezone=preferences.timezone,
            created_at=preferences.created_at.isoformat(),
            updated_at=preferences.updated_at.isoformat(),
        )

    except Exception as e:
        logger.error(f"Failed to get notification preferences: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve notification preferences",
        )


@router.patch(
    "",
    response_model=NotificationPreferencesResponse,
    summary="Update notification preferences",
    description="Update notification preferences for the current user",
)
async def update_notification_preferences(
    preferences_in: NotificationPreferencesUpdate,
    session: AsyncSession = Depends(get_session),
    user_id: str = Depends(get_current_user_id),
) -> NotificationPreferencesResponse:
    """Update notification preferences for the current user.

    Supports partial updates - only provided fields are updated.

    Args:
        preferences_in: Update data (all fields optional)
        session: Database session
        user_id: Current user ID (from JWT)

    Returns:
        Updated NotificationPreferencesResponse

    Raises:
        HTTPException: If validation fails or update fails
    """
    try:
        service = NotificationPreferencesService(session)

        # Get or create preferences first
        await service.get_or_create_preferences(user_id)

        # Build updates dict from non-None fields
        updates: Dict[str, Any] = {}
        for field, value in preferences_in.model_dump(exclude_unset=True).items():
            if value is not None:
                updates[field] = value

        # Update preferences
        try:
            preferences = await service.update_preferences(user_id, updates)
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(e),
            )

        if preferences is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notification preferences not found",
            )

        await session.commit()

        return NotificationPreferencesResponse(
            id=str(preferences.id),
            user_id=preferences.user_id,
            email_enabled=preferences.email_enabled,
            in_app_enabled=preferences.in_app_enabled,
            push_enabled=preferences.push_enabled,
            sms_enabled=preferences.sms_enabled,
            reminder_frequency=preferences.reminder_frequency,
            task_updates_enabled=preferences.task_updates_enabled,
            recurring_task_enabled=preferences.recurring_task_enabled,
            quiet_hours_enabled=preferences.quiet_hours_enabled,
            quiet_hours_start=preferences.quiet_hours_start,
            quiet_hours_end=preferences.quiet_hours_end,
            timezone=preferences.timezone,
            created_at=preferences.created_at.isoformat(),
            updated_at=preferences.updated_at.isoformat(),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update notification preferences: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update notification preferences",
        )


@router.get(
    "/timezones",
    response_model=TimezoneListResponse,
    summary="List available timezones",
    description="Get list of valid IANA timezone strings",
)
async def list_timezones() -> TimezoneListResponse:
    """Get list of valid IANA timezone strings.

    Returns:
        TimezoneListResponse with list of timezone strings
    """
    # Get all available timezones from pytz
    timezones = sorted(pytz.all_timezones)

    return TimezoneListResponse(timezones=timezones)


@router.post(
    "/reset",
    response_model=NotificationPreferencesResponse,
    summary="Reset notification preferences",
    description="Reset notification preferences to default values",
)
async def reset_notification_preferences(
    session: AsyncSession = Depends(get_session),
    user_id: str = Depends(get_current_user_id),
) -> NotificationPreferencesResponse:
    """Reset notification preferences to default values.

    Args:
        session: Database session
        user_id: Current user ID (from JWT)

    Returns:
        Reset NotificationPreferencesResponse

    Raises:
        HTTPException: If reset fails
    """
    try:
        service = NotificationPreferencesService(session)

        # Get or create preferences
        await service.get_or_create_preferences(user_id)

        # Reset to defaults
        updates = {
            "email_enabled": True,
            "in_app_enabled": True,
            "push_enabled": False,
            "sms_enabled": False,
            "reminder_frequency": "immediate",
            "task_updates_enabled": True,
            "recurring_task_enabled": True,
            "quiet_hours_enabled": False,
            "quiet_hours_start": None,
            "quiet_hours_end": None,
            "timezone": "UTC",
        }

        preferences = await service.update_preferences(user_id, updates)

        if preferences is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notification preferences not found",
            )

        await session.commit()

        return NotificationPreferencesResponse(
            id=str(preferences.id),
            user_id=preferences.user_id,
            email_enabled=preferences.email_enabled,
            in_app_enabled=preferences.in_app_enabled,
            push_enabled=preferences.push_enabled,
            sms_enabled=preferences.sms_enabled,
            reminder_frequency=preferences.reminder_frequency,
            task_updates_enabled=preferences.task_updates_enabled,
            recurring_task_enabled=preferences.recurring_task_enabled,
            quiet_hours_enabled=preferences.quiet_hours_enabled,
            quiet_hours_start=preferences.quiet_hours_start,
            quiet_hours_end=preferences.quiet_hours_end,
            timezone=preferences.timezone,
            created_at=preferences.created_at.isoformat(),
            updated_at=preferences.updated_at.isoformat(),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to reset notification preferences: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to reset notification preferences",
        )
