"""Audit service for creating and querying audit logs.

This module provides functionality for creating audit log entries
and querying the audit trail.
"""

import json
import logging
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Sequence
from uuid import UUID

from sqlalchemy import func
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.audit_log import AuditLog, AuditAction

logger = logging.getLogger(__name__)


class AuditService:
    """Service for managing audit logs."""

    def __init__(self, session: AsyncSession):
        """Initialize the audit service.

        Args:
            session: Async database session
        """
        self.session = session

    async def log_action(
        self,
        user_id: str,
        action: AuditAction,
        resource_type: str,
        resource_id: UUID,
        changes: Optional[Dict[str, Any]] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
    ) -> AuditLog:
        """Create an audit log entry.

        Args:
            user_id: User who performed the action
            action: The action performed
            resource_type: Type of resource (e.g., "task")
            resource_id: ID of the resource
            changes: Optional dict of before/after values
            ip_address: Optional IP address
            user_agent: Optional user agent string

        Returns:
            Created AuditLog entry
        """
        log_entry = AuditLog(
            user_id=user_id,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            changes=json.dumps(changes) if changes else None,
            ip_address=ip_address,
            user_agent=user_agent,
        )

        self.session.add(log_entry)
        await self.session.flush()
        await self.session.refresh(log_entry)

        logger.info(
            f"Audit log created: user={user_id}, action={action}, "
            f"resource={resource_type}/{resource_id}"
        )

        return log_entry

    async def get_user_audit_trail(
        self,
        user_id: str,
        resource_type: Optional[str] = None,
        resource_id: Optional[UUID] = None,
        action: Optional[AuditAction] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        offset: int = 0,
        limit: int = 50,
    ) -> Sequence[AuditLog]:
        """Get audit trail for a user with optional filters.

        Args:
            user_id: User ID to get audit trail for
            resource_type: Optional filter by resource type
            resource_id: Optional filter by resource ID
            action: Optional filter by action
            start_date: Optional start date filter
            end_date: Optional end date filter
            offset: Number of entries to skip
            limit: Maximum number of entries to return

        Returns:
            List of AuditLog entries
        """
        query = select(AuditLog).where(AuditLog.user_id == user_id)

        # Apply filters
        if resource_type:
            query = query.where(AuditLog.resource_type == resource_type)
        if resource_id:
            query = query.where(AuditLog.resource_id == resource_id)
        if action:
            query = query.where(AuditLog.action == action)
        if start_date:
            query = query.where(AuditLog.created_at >= start_date)
        if end_date:
            query = query.where(AuditLog.created_at <= end_date)

        # Order by most recent first
        query = query.order_by(AuditLog.created_at.desc())

        # Apply pagination
        query = query.offset(offset).limit(limit)

        result = await self.session.execute(query)
        return result.scalars().all()

    async def get_resource_audit_trail(
        self,
        resource_type: str,
        resource_id: UUID,
        user_id: Optional[str] = None,
        offset: int = 0,
        limit: int = 50,
    ) -> Sequence[AuditLog]:
        """Get audit trail for a specific resource.

        Args:
            resource_type: Type of resource
            resource_id: ID of the resource
            user_id: Optional filter by user ID
            offset: Number of entries to skip
            limit: Maximum number of entries to return

        Returns:
            List of AuditLog entries
        """
        query = select(AuditLog).where(
            AuditLog.resource_type == resource_type,
            AuditLog.resource_id == resource_id,
        )

        if user_id:
            query = query.where(AuditLog.user_id == user_id)

        # Order by most recent first
        query = query.order_by(AuditLog.created_at.desc())

        # Apply pagination
        query = query.offset(offset).limit(limit)

        result = await self.session.execute(query)
        return result.scalars().all()

    async def get_audit_statistics(
        self,
        user_id: str,
        days: int = 30,
    ) -> Dict[str, Any]:
        """Get audit statistics for a user.

        Args:
            user_id: User ID to get statistics for
            days: Number of days to look back (default 30)

        Returns:
            Dict with statistics
        """
        start_date = datetime.utcnow() - timedelta(days=days)

        # Count by action type
        query = select(
            AuditLog.action,
            func.count(AuditLog.id).label("count")
        ).where(
            AuditLog.user_id == user_id,
            AuditLog.created_at >= start_date
        ).group_by(AuditLog.action)

        result = await self.session.execute(query)
        action_counts = {row[0]: row[1] for row in result.all()}

        # Count by resource type
        query = select(
            AuditLog.resource_type,
            func.count(AuditLog.id).label("count")
        ).where(
            AuditLog.user_id == user_id,
            AuditLog.created_at >= start_date
        ).group_by(AuditLog.resource_type)

        result = await self.session.execute(query)
        resource_counts = {row[0]: row[1] for row in result.all()}

        # Total count
        query = select(func.count(AuditLog.id)).where(
            AuditLog.user_id == user_id,
            AuditLog.created_at >= start_date
        )
        result = await self.session.execute(query)
        total_count = result.scalar_one()

        return {
            "total_actions": total_count,
            "actions_by_type": action_counts,
            "actions_by_resource": resource_counts,
            "period_days": days,
        }

    async def cleanup_old_logs(
        self,
        days: int = 90,
        batch_size: int = 1000,
    ) -> int:
        """Delete audit logs older than specified days.

        Args:
            days: Number of days to keep (default 90)
            batch_size: Number of logs to delete per batch

        Returns:
            Number of logs deleted
        """
        cutoff_date = datetime.utcnow() - timedelta(days=days)

        # Count logs to delete
        query = select(func.count(AuditLog.id)).where(
            AuditLog.created_at < cutoff_date
        )
        result = await self.session.execute(query)
        total_to_delete = result.scalar_one()

        if total_to_delete == 0:
            return 0

        # Delete in batches
        deleted_count = 0
        while deleted_count < total_to_delete:
            # Get batch of IDs to delete
            query = select(AuditLog.id).where(
                AuditLog.created_at < cutoff_date
            ).limit(batch_size)

            result = await self.session.execute(query)
            ids_to_delete = [row[0] for row in result.all()]

            if not ids_to_delete:
                break

            # Delete batch
            for log_id in ids_to_delete:
                query = select(AuditLog).where(AuditLog.id == log_id)
                result = await self.session.execute(query)
                log = result.scalar_one_or_none()
                if log:
                    await self.session.delete(log)

            await self.session.flush()
            deleted_count += len(ids_to_delete)

            logger.info(f"Deleted {len(ids_to_delete)} audit logs (total: {deleted_count})")

        await self.session.commit()
        logger.info(f"Cleanup complete: deleted {deleted_count} audit logs older than {days} days")

        return deleted_count
