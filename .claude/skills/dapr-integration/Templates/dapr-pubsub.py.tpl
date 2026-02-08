"""
Dapr Pub/Sub Integration Template

This template provides a complete implementation of Dapr pub/sub messaging
for FastAPI applications with proper error handling and observability.
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from dapr.ext.fastapi import DaprApp
from dapr.clients import DaprClient
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
import logging
import json

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI and Dapr
app = FastAPI(title="Dapr Pub/Sub Service")
dapr_app = DaprApp(app)

# Configuration
PUBSUB_NAME = "pubsub"  # Name of your pub/sub component
TOPIC_NAME = "events"   # Default topic name


# ============================================================================
# Event Models
# ============================================================================

class BaseEvent(BaseModel):
    """Base event model with common fields."""
    event_id: str = Field(..., description="Unique event identifier")
    event_type: str = Field(..., description="Type of event")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    source: str = Field(..., description="Service that generated the event")
    data: Dict[str, Any] = Field(default_factory=dict)
    metadata: Optional[Dict[str, str]] = Field(default_factory=dict)

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class CloudEvent(BaseModel):
    """Cloud Events v1.0 specification format."""
    specversion: str = "1.0"
    type: str
    source: str
    id: str
    time: Optional[datetime] = None
    datacontenttype: str = "application/json"
    data: Dict[str, Any]


# ============================================================================
# Publisher
# ============================================================================

class DaprPublisher:
    """Publisher for Dapr pub/sub messages."""

    def __init__(self, pubsub_name: str = PUBSUB_NAME):
        self.pubsub_name = pubsub_name
        self.client = None

    def __enter__(self):
        self.client = DaprClient()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.client:
            self.client.close()

    async def publish(
        self,
        topic: str,
        event: BaseEvent,
        metadata: Optional[Dict[str, str]] = None
    ) -> bool:
        """
        Publish an event to a Dapr pub/sub topic.

        Args:
            topic: Topic name to publish to
            event: Event data to publish
            metadata: Optional metadata for the message

        Returns:
            True if published successfully, False otherwise
        """
        try:
            with DaprClient() as client:
                # Convert event to dict
                event_data = event.dict()

                # Publish to Dapr
                client.publish_event(
                    pubsub_name=self.pubsub_name,
                    topic_name=topic,
                    data=json.dumps(event_data),
                    data_content_type='application/json',
                    publish_metadata=metadata or {}
                )

                logger.info(
                    f"Published event {event.event_id} to topic {topic}",
                    extra={
                        "event_type": event.event_type,
                        "topic": topic,
                        "event_id": event.event_id
                    }
                )
                return True

        except Exception as e:
            logger.error(
                f"Failed to publish event to topic {topic}: {e}",
                extra={
                    "event_id": event.event_id,
                    "topic": topic,
                    "error": str(e)
                },
                exc_info=True
            )
            return False

    async def publish_batch(
        self,
        topic: str,
        events: List[BaseEvent],
        metadata: Optional[Dict[str, str]] = None
    ) -> int:
        """
        Publish multiple events to a topic.

        Args:
            topic: Topic name
            events: List of events to publish
            metadata: Optional metadata

        Returns:
            Number of successfully published events
        """
        success_count = 0
        for event in events:
            if await self.publish(topic, event, metadata):
                success_count += 1
        return success_count


# ============================================================================
# Subscriber
# ============================================================================

@dapr_app.subscribe(pubsub=PUBSUB_NAME, topic=TOPIC_NAME)
async def event_subscriber(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Subscribe to events from Dapr pub/sub.

    This is the main subscriber endpoint. Dapr will POST events here.

    Args:
        event: Event data from Dapr (Cloud Events format)

    Returns:
        Response indicating success or failure
    """
    try:
        # Extract event data
        event_id = event.get('id', 'unknown')
        event_type = event.get('type', 'unknown')
        event_data = event.get('data', {})

        logger.info(
            f"Received event {event_id} of type {event_type}",
            extra={
                "event_id": event_id,
                "event_type": event_type
            }
        )

        # Process event based on type
        await process_event(event_type, event_data)

        # Return success response
        return {
            "status": "SUCCESS",
            "message": f"Event {event_id} processed successfully"
        }

    except Exception as e:
        logger.error(
            f"Error processing event: {e}",
            extra={"event": event},
            exc_info=True
        )
        # Return retry status for transient errors
        return {
            "status": "RETRY",
            "message": str(e)
        }


async def process_event(event_type: str, event_data: Dict[str, Any]):
    """
    Process event based on its type.

    Args:
        event_type: Type of event
        event_data: Event payload
    """
    # Route to appropriate handler
    handlers = {
        "created": handle_created_event,
        "updated": handle_updated_event,
        "deleted": handle_deleted_event,
        "notification": handle_notification_event,
    }

    handler = handlers.get(event_type)
    if handler:
        await handler(event_data)
    else:
        logger.warning(f"No handler for event type: {event_type}")


async def handle_created_event(data: Dict[str, Any]):
    """Handle created events."""
    logger.info(f"Processing created event: {data}")
    # Implement your business logic here


async def handle_updated_event(data: Dict[str, Any]):
    """Handle updated events."""
    logger.info(f"Processing updated event: {data}")
    # Implement your business logic here


async def handle_deleted_event(data: Dict[str, Any]):
    """Handle deleted events."""
    logger.info(f"Processing deleted event: {data}")
    # Implement your business logic here


async def handle_notification_event(data: Dict[str, Any]):
    """Handle notification events."""
    logger.info(f"Processing notification event: {data}")
    # Implement your business logic here


# ============================================================================
# FastAPI Endpoints
# ============================================================================

@app.post("/publish/{topic}")
async def publish_event_endpoint(
    topic: str,
    event: BaseEvent,
    background_tasks: BackgroundTasks
) -> Dict[str, Any]:
    """
    Publish an event to a specific topic.

    Args:
        topic: Topic name to publish to
        event: Event data
        background_tasks: FastAPI background tasks

    Returns:
        Response with publish status
    """
    publisher = DaprPublisher()

    # Publish in background
    success = await publisher.publish(topic, event)

    if success:
        return {
            "status": "published",
            "event_id": event.event_id,
            "topic": topic
        }
    else:
        raise HTTPException(
            status_code=500,
            detail="Failed to publish event"
        )


@app.get("/health")
async def health_check() -> Dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy"}


@app.get("/dapr/subscribe")
async def dapr_subscribe() -> List[Dict[str, str]]:
    """
    Dapr subscription endpoint.

    This endpoint tells Dapr which topics this service subscribes to.
    """
    return [
        {
            "pubsubname": PUBSUB_NAME,
            "topic": TOPIC_NAME,
            "route": f"/events"
        }
    ]


# ============================================================================
# Dependency Injection
# ============================================================================

def get_publisher() -> DaprPublisher:
    """
    Dependency injection for publisher.

    Usage in FastAPI:
        @app.post("/events")
        async def create_event(publisher: DaprPublisher = Depends(get_publisher)):
            await publisher.publish("my-topic", event)
    """
    return DaprPublisher()


# ============================================================================
# Usage Example
# ============================================================================

if __name__ == "__main__":
    import uvicorn

    # Run with Dapr:
    # dapr run --app-id myapp --app-port 8000 --dapr-http-port 3500 -- python dapr-pubsub.py

    uvicorn.run(app, host="0.0.0.0", port=8000)
