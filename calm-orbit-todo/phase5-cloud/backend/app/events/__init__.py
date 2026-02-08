"""Event streaming module for Kafka/Redpanda integration.

This module provides event publishing and consumption capabilities for the
Phase 5 event-driven architecture.
"""

from app.events.producer import EventProducer, publish_task_event
from app.events.consumer import EventConsumer, start_consumer

__all__ = [
    "EventProducer",
    "publish_task_event",
    "EventConsumer",
    "start_consumer",
]
