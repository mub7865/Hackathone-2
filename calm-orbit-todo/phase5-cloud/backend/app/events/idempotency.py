"""Idempotency service for preventing duplicate event processing.

This module provides functionality to track processed events and ensure
idempotent event handling.
"""

import logging
from datetime import datetime, timedelta
from typing import Optional

from sqlalchemy import func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import Field, SQLModel, select

logger = logging.getLogger(__name__)


class ProcessedEvent(SQLModel, table=True):
    """Tracks processed events for idempotency.

    Attributes:
        id: Auto-increment primary key.
        event_id: Unique event identifier (from event envelope).
        event_type: Type of event (e.g., "task.created").
        processed_at: Timestamp when event was processed.
        consumer_group: Consumer group that processed the event.
    """

    __tablename__ = "processed_events"

    id: Optional[int] = Field(default=None, primary_key=True)
    event_id: str = Field(..., max_length=100, nullable=False, unique=True, index=True)
    event_type: str = Field(..., max_length=100, nullable=False, index=True)
    processed_at: datetime = Field(
        default_factory=datetime.utcnow,
        nullable=False,
        index=True,
    )
    consumer_group: str = Field(..., max_length=100, nullable=False)


class IdempotencyService:
    """Service for ensuring idempotent event processing."""

    def __init__(self, session: AsyncSession):
        """Initialize the idempotency service.

        Args:
            session: Async database session
        """
        self.session = session

    async def is_processed(
        self,
        event_id: str,
        consumer_group: str,
    ) -> bool:
        """Check if an event has already been processed.

        Args:
            event_id: Unique event identifier
            consumer_group: Consumer group name

        Returns:
            True if event was already processed, False otherwise
        """
        query = select(ProcessedEvent).where(
            ProcessedEvent.event_id == event_id,
            ProcessedEvent.consumer_group == consumer_group,
        )
        result = await self.session.execute(query)
        event = result.scalar_one_or_none()

        return event is not None

    async def mark_processed(
        self,
        event_id: str,
        event_type: str,
        consumer_group: str,
    ) -> bool:
        """Mark an event as processed.

        Args:
            event_id: Unique event identifier
            event_type: Type of event
            consumer_group: Consumer group name

        Returns:
            True if marked successfully, False if already processed
        """
        # Check if already processed
        if await self.is_processed(event_id, consumer_group):
            logger.warning(
                f"Event already processed: id={event_id}, group={consumer_group}"
            )
            return False

        # Mark as processed
        try:
            processed_event = ProcessedEvent(
                event_id=event_id,
                event_type=event_type,
                consumer_group=consumer_group,
            )

            self.session.add(processed_event)
            await self.session.flush()

            logger.info(
                f"Marked event as processed: id={event_id}, type={event_type}, group={consumer_group}"
            )
            return True

        except Exception as e:
            # Handle unique constraint violation (race condition)
            logger.warning(
                f"Failed to mark event as processed (likely race condition): {e}"
            )
            return False

    async def cleanup_old_events(
        self,
        days: int = 30,
        batch_size: int = 1000,
    ) -> int:
        """Delete old processed event records.

        Args:
            days: Delete records older than this many days (default 30)
            batch_size: Number of records to delete per batch

        Returns:
            Number of records deleted
        """
        cutoff_date = datetime.utcnow() - timedelta(days=days)

        # Count records to delete
        count_query = select(func.count(ProcessedEvent.id)).where(
            ProcessedEvent.processed_at < cutoff_date
        )
        result = await self.session.execute(count_query)
        total_to_delete = result.scalar_one()

        if total_to_delete == 0:
            return 0

        # Delete in batches
        deleted_count = 0
        while deleted_count < total_to_delete:
            # Get batch of IDs to delete
            query = select(ProcessedEvent.id).where(
                ProcessedEvent.processed_at < cutoff_date
            ).limit(batch_size)

            result = await self.session.execute(query)
            ids_to_delete = [row[0] for row in result.all()]

            if not ids_to_delete:
                break

            # Delete batch
            for event_id in ids_to_delete:
                query = select(ProcessedEvent).where(ProcessedEvent.id == event_id)
                result = await self.session.execute(query)
                event = result.scalar_one_or_none()
                if event:
                    await self.session.delete(event)

            await self.session.flush()
            deleted_count += len(ids_to_delete)

            logger.info(
                f"Deleted {len(ids_to_delete)} processed events (total: {deleted_count})"
            )

        await self.session.commit()
        logger.info(
            f"Cleanup complete: deleted {deleted_count} processed events older than {days} days"
        )

        return deleted_count

    async def get_processing_stats(
        self,
        consumer_group: Optional[str] = None,
        hours: int = 24,
    ) -> dict:
        """Get event processing statistics.

        Args:
            consumer_group: Optional filter by consumer group
            hours: Number of hours to look back (default 24)

        Returns:
            Dictionary with processing statistics
        """
        since = datetime.utcnow() - timedelta(hours=hours)

        # Total events processed
        query = select(func.count(ProcessedEvent.id)).where(
            ProcessedEvent.processed_at >= since
        )
        if consumer_group:
            query = query.where(ProcessedEvent.consumer_group == consumer_group)

        result = await self.session.execute(query)
        total_events = result.scalar_one()

        # Events by type
        query = select(
            ProcessedEvent.event_type,
            func.count(ProcessedEvent.id).label("count"),
        ).where(
            ProcessedEvent.processed_at >= since
        ).group_by(ProcessedEvent.event_type)

        if consumer_group:
            query = query.where(ProcessedEvent.consumer_group == consumer_group)

        result = await self.session.execute(query)
        events_by_type = {row[0]: row[1] for row in result.all()}

        # Events by consumer group
        query = select(
            ProcessedEvent.consumer_group,
            func.count(ProcessedEvent.id).label("count"),
        ).where(
            ProcessedEvent.processed_at >= since
        ).group_by(ProcessedEvent.consumer_group)

        result = await self.session.execute(query)
        events_by_group = {row[0]: row[1] for row in result.all()}

        return {
            "total_events": total_events,
            "events_by_type": events_by_type,
            "events_by_group": events_by_group,
            "period_hours": hours,
        }


async def ensure_idempotent(
    session: AsyncSession,
    event_id: str,
    event_type: str,
    consumer_group: str,
) -> bool:
    """Decorator-style function to ensure idempotent event processing.

    Args:
        session: Database session
        event_id: Unique event identifier
        event_type: Type of event
        consumer_group: Consumer group name

    Returns:
        True if event should be processed, False if already processed
    """
    service = IdempotencyService(session)

    # Check if already processed
    if await service.is_processed(event_id, consumer_group):
        logger.info(
            f"Skipping duplicate event: id={event_id}, group={consumer_group}"
        )
        return False

    # Mark as processed
    success = await service.mark_processed(event_id, event_type, consumer_group)
    if not success:
        logger.warning(
            f"Failed to mark event as processed: id={event_id}, group={consumer_group}"
        )
        return False

    return True
