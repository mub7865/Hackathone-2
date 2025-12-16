"""FastAPI application entrypoint.

Todo App Backend - Phase II
REST API for task management with JWT authentication.
"""

import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import router as v1_router
from app.core.exceptions import register_exception_handlers

app = FastAPI(
    title="Todo API",
    description="REST API for multi-user task management",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
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


@app.get("/health", tags=["health"])
async def health_check() -> dict:
    """Health check endpoint.

    Returns:
        Simple status object indicating API is running.
    """
    return {"status": "healthy", "version": "1.0.0"}
