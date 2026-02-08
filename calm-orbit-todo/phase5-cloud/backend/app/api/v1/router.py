"""API v1 router aggregator.

Combines all v1 endpoint routers under a single router with /api/v1 prefix.
"""

from fastapi import APIRouter

from .auth import router as auth_router
from .chat import router as chat_router
from .chatkit import router as chatkit_router
from .conversations import router as conversations_router
from .tasks import router as tasks_router
from .reminders import router as reminders_router
from .recurring_tasks import router as recurring_tasks_router

router = APIRouter(prefix="/api/v1")

# Include auth endpoints (no additional prefix - uses /auth from auth.py)
router.include_router(auth_router)

# Include task endpoints
router.include_router(tasks_router, prefix="/tasks", tags=["tasks"])

# Phase III: Chat endpoints
router.include_router(chat_router, prefix="/chat", tags=["chat"])
router.include_router(conversations_router, prefix="/conversations", tags=["conversations"])

# Phase III: ChatKit endpoint (OpenAI ChatKit SDK)
router.include_router(chatkit_router, prefix="/chatkit", tags=["chatkit"])

# Phase V: Reminders and Recurring Tasks
router.include_router(reminders_router, prefix="/reminders", tags=["reminders"])
router.include_router(recurring_tasks_router, prefix="/recurring", tags=["recurring-tasks"])
