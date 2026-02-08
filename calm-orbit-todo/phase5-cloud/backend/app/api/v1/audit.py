"""Audit trail API endpoints.

This module provides REST API endpoints for querying audit logs and statistics.
"""

import json
import logging
from datetime import datetime
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user_id, get_session
from app.models.audit_log import AuditAction
from app.schemas.audit_log import (
    AuditLogListResponse,
    AuditLogResponse,
    AuditStatisticsResponse,
)
from app.services.audit_service import AuditService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/audit", tags=["audit"])


@router.get(
    "",
    response_model=AuditLogListResponse,
    summary="List audit logs",
    description="Get paginated list of audit logs with optional filters",
)
async def list_audit_logs(
    resource_type: Optional[str] = Query(
        None,
        description="Filter by resource type (e.g., 'task', 'saved_filter')",
    ),
    resource_id: Optional[UUID] = Query(
        None,
        description="Filter by specific resource ID",
    ),
    action: Optional[AuditAction] = Query(
        None,
        description="Filter by action type",
    ),
    start_date: Optional[datetime] = Query(
        None,
        description="Filter by start date (ISO 8601 format)",
    ),
    end_date: Optional[datetime] = Query(
        None,
        description="Filter by end date (ISO 8601 format)",
    ),
    offset: int = Query(
        0,
        ge=0,
        description="Number of entries to skip",
    ),
    limit: int = Query(
        50,
        ge=1,
        le=100,
        description="Maximum number of entries to return (max 100)",
    ),
    session: AsyncSession = Depends(get_session),
    user_id: str = Depends(get_current_user_id),
) -> AuditLogListResponse:
    """Get audit logs for the current user with optional filters.

    Args:
        resource_type: Optional filter by resource type
        resource_id: Optional filter by resource ID
        action: Optional filter by action type
        start_date: Optional start date filter
        end_date: Optional end date filter
        offset: Number of entries to skip (for pagination)
        limit: Maximum number of entries to return
        session: Database session
        user_id: Current user ID (from JWT)

    Returns:
        Paginated list of audit logs

    Raises:
        HTTPException: If query fails
    """
    try:
        audit_service = AuditService(session)

        # Get audit logs
        logs = await audit_service.get_user_audit_trail(
            user_id=user_id,
            resource_type=resource_type,
            resource_id=resource_id,
            action=action,
            start_date=start_date,
            end_date=end_date,
            offset=offset,
            limit=limit,
        )

        # Get total count (without pagination)
        all_logs = await audit_service.get_user_audit_trail(
            user_id=user_id,
            resource_type=resource_type,
            resource_id=resource_id,
            action=action,
            start_date=start_date,
            end_date=end_date,
            offset=0,
            limit=10000,  # Large limit to get total count
        )
        total = len(all_logs)

        # Convert to response models
        items = []
        for log in logs:
            # Parse changes JSON if present
            changes = None
            if log.changes:
                try:
                    changes = json.loads(log.changes)
                except json.JSONDecodeError:
                    logger.warning(f"Failed to parse changes JSON for log {log.id}")

            items.append(
                AuditLogResponse(
                    id=log.id,
                    user_id=log.user_id,
                    action=log.action,
                    resource_type=log.resource_type,
                    resource_id=log.resource_id,
                    changes=changes,
                    ip_address=log.ip_address,
                    user_agent=log.user_agent,
                    created_at=log.created_at,
                )
            )

        return AuditLogListResponse(
            items=items,
            total=total,
            offset=offset,
            limit=limit,
        )

    except Exception as e:
        logger.error(f"Failed to list audit logs: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve audit logs",
        )


@router.get(
    "/statistics",
    response_model=AuditStatisticsResponse,
    summary="Get audit statistics",
    description="Get audit statistics for the current user",
)
async def get_audit_statistics(
    days: int = Query(
        30,
        ge=1,
        le=365,
        description="Number of days to look back (1-365)",
    ),
    session: AsyncSession = Depends(get_session),
    user_id: str = Depends(get_current_user_id),
) -> AuditStatisticsResponse:
    """Get audit statistics for the current user.

    Args:
        days: Number of days to look back (default 30)
        session: Database session
        user_id: Current user ID (from JWT)

    Returns:
        Audit statistics including action counts by type and resource

    Raises:
        HTTPException: If query fails
    """
    try:
        audit_service = AuditService(session)

        # Get statistics
        stats = await audit_service.get_audit_statistics(
            user_id=user_id,
            days=days,
        )

        return AuditStatisticsResponse(
            total_actions=stats["total_actions"],
            actions_by_type=stats["actions_by_type"],
            actions_by_resource=stats["actions_by_resource"],
            period_days=stats["period_days"],
        )

    except Exception as e:
        logger.error(f"Failed to get audit statistics: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve audit statistics",
        )


@router.get(
    "/resource/{resource_type}/{resource_id}",
    response_model=AuditLogListResponse,
    summary="Get audit trail for a resource",
    description="Get audit trail for a specific resource",
)
async def get_resource_audit_trail(
    resource_type: str,
    resource_id: UUID,
    offset: int = Query(
        0,
        ge=0,
        description="Number of entries to skip",
    ),
    limit: int = Query(
        50,
        ge=1,
        le=100,
        description="Maximum number of entries to return (max 100)",
    ),
    session: AsyncSession = Depends(get_session),
    user_id: str = Depends(get_current_user_id),
) -> AuditLogListResponse:
    """Get audit trail for a specific resource.

    Args:
        resource_type: Type of resource (e.g., "task")
        resource_id: ID of the resource
        offset: Number of entries to skip (for pagination)
        limit: Maximum number of entries to return
        session: Database session
        user_id: Current user ID (from JWT)

    Returns:
        Paginated list of audit logs for the resource

    Raises:
        HTTPException: If query fails
    """
    try:
        audit_service = AuditService(session)

        # Get audit logs for the resource
        logs = await audit_service.get_resource_audit_trail(
            resource_type=resource_type,
            resource_id=resource_id,
            user_id=user_id,  # Only show logs for current user
            offset=offset,
            limit=limit,
        )

        # Get total count
        all_logs = await audit_service.get_resource_audit_trail(
            resource_type=resource_type,
            resource_id=resource_id,
            user_id=user_id,
            offset=0,
            limit=10000,
        )
        total = len(all_logs)

        # Convert to response models
        items = []
        for log in logs:
            # Parse changes JSON if present
            changes = None
            if log.changes:
                try:
                    changes = json.loads(log.changes)
                except json.JSONDecodeError:
                    logger.warning(f"Failed to parse changes JSON for log {log.id}")

            items.append(
                AuditLogResponse(
                    id=log.id,
                    user_id=log.user_id,
                    action=log.action,
                    resource_type=log.resource_type,
                    resource_id=log.resource_id,
                    changes=changes,
                    ip_address=log.ip_address,
                    user_agent=log.user_agent,
                    created_at=log.created_at,
                )
            )

        return AuditLogListResponse(
            items=items,
            total=total,
            offset=offset,
            limit=limit,
        )

    except Exception as e:
        logger.error(
            f"Failed to get resource audit trail: {e}",
            exc_info=True,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve resource audit trail",
        )
