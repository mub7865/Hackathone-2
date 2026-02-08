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
import json
import contextlib

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import router as v1_router
from app.core.exceptions import register_exception_handlers
from app.services.mcp_server import mcp
from app.database import init_db, get_engine
from app.migrations import run_migrations
from app.config import get_settings


@contextlib.asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan including MCP session manager and event producers."""
    # Run migrations to add Phase 5 columns to existing tables
    engine = get_engine()
    await run_migrations(engine)

    # Initialize database tables (creates new tables only)
    await init_db()

    # Initialize Phase 5 services if enabled
    settings = get_settings()
    if settings.enable_event_publishing:
        from app.events.producers.event_producers import (
            get_task_producer,
            get_reminder_producer,
            get_recurring_task_producer,
            shutdown_producers,
        )
        from app.events.consumers.event_consumers import (
            start_task_consumer,
            start_reminder_consumer,
            start_recurring_task_consumer,
            shutdown_consumers,
        )
        from app.schedulers.recurring_scheduler import (
            start_recurring_scheduler,
            stop_recurring_scheduler,
        )
        from app.schedulers.reminder_scheduler import (
            start_reminder_scheduler,
            stop_reminder_scheduler,
        )

        try:
            # Start event producers with correct Kafka address
            await get_task_producer(bootstrap_servers=settings.kafka_bootstrap_servers)
            await get_reminder_producer(bootstrap_servers=settings.kafka_bootstrap_servers)
            await get_recurring_task_producer(bootstrap_servers=settings.kafka_bootstrap_servers)
            print(f"✅ Event producers started: {settings.kafka_bootstrap_servers}")

            # Start event consumers
            await start_task_consumer(bootstrap_servers=settings.kafka_bootstrap_servers)
            await start_reminder_consumer(bootstrap_servers=settings.kafka_bootstrap_servers)
            await start_recurring_task_consumer(bootstrap_servers=settings.kafka_bootstrap_servers)
            print(f"✅ Event consumers started: {settings.kafka_bootstrap_servers}")

            # Start schedulers
            await start_recurring_scheduler(check_interval_seconds=60)
            await start_reminder_scheduler(check_interval_seconds=60)
            print("✅ Schedulers started (recurring + reminder)")

        except Exception as e:
            print(f"⚠️ Failed to start Phase 5 services: {e}")

    async with contextlib.AsyncExitStack() as stack:
        await stack.enter_async_context(mcp.session_manager.run())
        yield

        # Shutdown Phase 5 services on app shutdown
        if settings.enable_event_publishing:
            try:
                await stop_reminder_scheduler()
                await stop_recurring_scheduler()
                print("✅ Schedulers shut down")

                await shutdown_consumers()
                print("✅ Event consumers shut down")

                await shutdown_producers()
                print("✅ Event producers shut down")
            except Exception as e:
                print(f"⚠️ Error shutting down Phase 5 services: {e}")


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
# Read CORS origins from environment variable or use defaults
cors_origins_env = os.environ.get("CORS_ORIGINS")
if cors_origins_env:
    try:
        CORS_ORIGINS = json.loads(cors_origins_env)
    except json.JSONDecodeError:
        # Fallback to defaults if JSON parsing fails
        CORS_ORIGINS = [
            "http://localhost:3000",
            "http://127.0.0.1:3000",
            "http://localhost:30000",
            "http://127.0.0.1:30000",
            "https://calm-orbit-todo.vercel.app",
        ]
else:
    CORS_ORIGINS = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:30000",
        "http://127.0.0.1:30000",
        "https://calm-orbit-todo.vercel.app",
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

@app.get("/", tags=["root"])
async def root() -> dict:
    """Root endpoint with welcome message."""
    return {
        "message": "Welcome to Calm Orbit Todo API 🚀",
        "status": "online",
        "version": "1.2.3",
        "docs": "/docs",
        "health": "/health"
    }

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
