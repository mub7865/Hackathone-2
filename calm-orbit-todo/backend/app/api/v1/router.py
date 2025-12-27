"""API v1 router aggregator.

Combines all v1 endpoint routers under a single router with /api/v1 prefix.
"""

from fastapi import APIRouter

from .auth import router as auth_router
from .chat import router as chat_router
from .conversations import router as conversations_router
from .tasks import router as tasks_router

router = APIRouter(prefix="/api/v1")

# Include auth endpoints (no additional prefix - uses /auth from auth.py)
router.include_router(auth_router)

# Include task endpoints
router.include_router(tasks_router, prefix="/tasks", tags=["tasks"])

# Phase III: Chat endpoints
router.include_router(chat_router, prefix="/chat", tags=["chat"])
router.include_router(conversations_router, prefix="/conversations", tags=["conversations"])
