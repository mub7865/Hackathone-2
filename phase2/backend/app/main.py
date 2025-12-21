"""FastAPI application entrypoint.

Todo App Backend - Phase II + Phase III AI Chatbot
REST API for task management with JWT authentication and AI-powered chat.

Phase III Architecture (Updated 2025-12-21):
- MCP Server mounted at /mcp endpoint via mcp.streamable_http_app()
- Agent connects via MCPServerStreamableHttp(url="/mcp/mcp")
- Tools receive user_id as parameter for data isolation
- Lifespan manages MCP session manager
"""

import os
import contextlib

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import router as v1_router
from app.core.exceptions import register_exception_handlers
from app.services.mcp_server import mcp


@contextlib.asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan including MCP session manager."""
    async with contextlib.AsyncExitStack() as stack:
        await stack.enter_async_context(mcp.session_manager.run())
        yield


app = FastAPI(
    title="Todo API",
    description="REST API for multi-user task management with AI chatbot",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# Register exception handlers for RFC 7807 error responses
register_exception_handlers(app)

# CORS middleware for frontend
# Allow localhost for development and Vercel for production
CORS_ORIGINS = [
    "http://localhost:3000",  # Next.js dev server
    "http://127.0.0.1:3000",
    "https://calm-orbit-todo.vercel.app",  # Vercel production frontend
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

# Add request logging middleware (disabled in test environment due to
# BaseHTTPMiddleware compatibility issues with pytest-asyncio)
if os.environ.get("ENVIRONMENT") != "test":
    from app.core.logging import RequestLoggingMiddleware
    app.add_middleware(RequestLoggingMiddleware)

# Include API v1 router
app.include_router(v1_router)

# Mount MCP Server at /mcp endpoint for AI agent tool access
# Note: streamable_http_app() mounts at /mcp internally, so full path is /mcp/mcp
# Agent connects via MCPServerStreamableHttp(url="http://localhost:8000/mcp/mcp")
app.mount("/mcp", mcp.streamable_http_app())


@app.get("/health", tags=["health"])
async def health_check() -> dict:
    """Health check endpoint.

    Returns:
        Simple status object indicating API is running.
    """
    return {"status": "healthy", "version": "1.0.0"}
