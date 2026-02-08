"""
ChatKit API endpoint
Feature: 007-ai-chatbot-phase3 (ChatKit integration)

Provides the /chatkit endpoint that handles all ChatKit requests.
This is the single endpoint pattern required by ChatKit SDK.
"""

from fastapi import APIRouter, Request, HTTPException, status
from fastapi.responses import StreamingResponse

from app.api.deps import CurrentUser, DbSession
from app.chatkit_server import chatkit_server, ChatKitRequestContext

router = APIRouter()


@router.post("")
async def chatkit_endpoint(
    request: Request,
    db: DbSession,
    current_user: CurrentUser,
):
    """
    ChatKit endpoint - handles all ChatKit requests

    This endpoint:
    1. Extracts user context from authentication
    2. Forwards request to ChatKitServer
    3. Returns streaming or JSON response

    The ChatKitServer handles routing internally based on request payload.
    """
    try:
        # Create request context with user ID and database session
        context = ChatKitRequestContext(
            user_id=str(current_user),
            session=db
        )

        # Get request body
        body = await request.body()

        # Process request through ChatKit server
        result = await chatkit_server.process(body, context)

        # Return appropriate response type
        if hasattr(result, 'stream'):
            # Streaming response
            return StreamingResponse(
                result.stream(),
                media_type="text/event-stream"
            )
        else:
            # JSON response
            return result

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"ChatKit request failed: {str(e)}"
        )
