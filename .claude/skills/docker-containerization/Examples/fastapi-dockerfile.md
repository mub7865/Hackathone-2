# FastAPI Dockerfile Examples

## Example 1: Simple Development Dockerfile

Best for: Local development, quick testing

```dockerfile
# Dockerfile.dev
FROM python:3.13-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy code
COPY app ./app

# Development mode with auto-reload
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

**Build & Run:**
```bash
docker build -f Dockerfile.dev -t backend:dev .
docker run -p 8000:8000 -v $(pwd)/app:/app/app backend:dev
```

---

## Example 2: Production Multi-Stage Dockerfile

Best for: Production deployments, Kubernetes

```dockerfile
# Dockerfile
# ============================================
# Stage 1: Builder
# ============================================
FROM python:3.13-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ============================================
# Stage 2: Runtime
# ============================================
FROM python:3.13-slim AS runtime

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application code
COPY app ./app

# Create non-root user (UID > 10000 for security)
RUN adduser --disabled-password --gecos "" --uid 10001 appuser && \
    chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/')" || exit 1

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Build & Run:**
```bash
docker build -t backend:v1 .
docker run -d -p 8000:8000 \
  -e DATABASE_URL="postgresql://..." \
  -e BETTER_AUTH_SECRET="..." \
  --name backend backend:v1
```

---

## Example 3: FastAPI with UV Package Manager

Best for: Projects using UV for faster dependency management

```dockerfile
# Dockerfile.uv
# ============================================
# Stage 1: Builder with UV
# ============================================
FROM python:3.13-slim AS builder

WORKDIR /app

# Install UV
RUN pip install --no-cache-dir uv

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Create venv and install dependencies
RUN uv venv /opt/venv && \
    . /opt/venv/bin/activate && \
    uv sync --frozen --no-dev

# ============================================
# Stage 2: Runtime
# ============================================
FROM python:3.13-slim AS runtime

WORKDIR /app

# Copy virtual environment
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application
COPY app ./app

# Security: Non-root user
RUN adduser --disabled-password --gecos "" --uid 10001 appuser
USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Example 4: FastAPI with Alembic Migrations

Best for: Apps that need database migrations on startup

```dockerfile
# Dockerfile with migrations
FROM python:3.13-slim AS builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ============================================
FROM python:3.13-slim AS runtime

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy app and migrations
COPY app ./app
COPY alembic ./alembic
COPY alembic.ini .

# Startup script
COPY scripts/start.sh .
RUN chmod +x start.sh

RUN adduser --disabled-password --uid 10001 appuser
USER appuser

EXPOSE 8000

# Run migrations then start server
CMD ["./start.sh"]
```

**start.sh:**
```bash
#!/bin/sh
set -e

echo "Running database migrations..."
alembic upgrade head

echo "Starting server..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
```

---

## .dockerignore for FastAPI

```
# Virtual environments
.venv/
venv/
env/
__pycache__/
*.py[cod]
.pytest_cache/

# IDE
.vscode/
.idea/

# Git
.git/
.gitignore

# Docker
Dockerfile*
docker-compose*

# Environment (secrets!)
.env
.env.*

# Tests (optional)
tests/

# Docs
*.md
docs/
```

---

## Image Size Comparison

| Dockerfile Type | Approximate Size |
|-----------------|------------------|
| Simple (python:3.13) | 1.2 GB |
| Simple (python:3.13-slim) | 350 MB |
| Multi-stage (slim) | 180 MB |
| Multi-stage (alpine) | 120 MB |

---

## Common Issues & Fixes

### Issue: "ModuleNotFoundError"

**Cause**: Dependencies not installed correctly

**Fix**: Ensure correct COPY order
```dockerfile
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app ./app  # Code AFTER dependencies
```

### Issue: Container exits immediately

**Cause**: Missing host binding

**Fix**: Add `--host 0.0.0.0`
```dockerfile
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Issue: Permission denied

**Cause**: Running as non-root without proper ownership

**Fix**: Set ownership before switching user
```dockerfile
RUN adduser --disabled-password appuser && \
    chown -R appuser:appuser /app
USER appuser
```
