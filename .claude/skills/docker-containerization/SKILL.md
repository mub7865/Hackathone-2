---
name: docker-containerization
description: >
  Complete patterns for containerizing applications with Docker: Dockerfiles,
  multi-stage builds, layer optimization, security best practices, and
  production-ready configurations for Python/FastAPI and Node.js/Next.js apps.
---

# Docker Containerization Skill

## When to use this Skill

Use this Skill whenever you are:

- Creating Dockerfiles for Python (FastAPI, Flask, Django) applications.
- Creating Dockerfiles for Node.js (Next.js, React, Express) applications.
- Optimizing existing Docker images for smaller size and faster builds.
- Implementing multi-stage builds for production deployments.
- Setting up Docker for local development or CI/CD pipelines.
- Containerizing applications for Kubernetes deployment.

This Skill works for **any** Docker project, not just a single repository.

## Core Goals

- Create **small, secure, and fast** Docker images.
- Use **multi-stage builds** to separate build and runtime.
- Implement **layer caching** for faster rebuilds.
- Follow **security best practices** (non-root users, minimal base images).
- Provide **consistent patterns** across different tech stacks.

## Dockerfile Fundamentals

### Basic Structure

Every Dockerfile follows this general pattern:

```dockerfile
# 1. Base image
FROM base-image:tag

# 2. Set working directory
WORKDIR /app

# 3. Copy dependency files first (layer caching)
COPY package.json .

# 4. Install dependencies
RUN npm install

# 5. Copy source code
COPY . .

# 6. Build (if needed)
RUN npm run build

# 7. Expose port
EXPOSE 3000

# 8. Start command
CMD ["npm", "start"]
```

### Key Instructions

| Instruction | Purpose | Example |
|-------------|---------|---------|
| `FROM` | Base image | `FROM python:3.13-slim` |
| `WORKDIR` | Set working directory | `WORKDIR /app` |
| `COPY` | Copy files into image | `COPY requirements.txt .` |
| `RUN` | Execute commands | `RUN pip install -r requirements.txt` |
| `ENV` | Set environment variables | `ENV NODE_ENV=production` |
| `EXPOSE` | Document exposed port | `EXPOSE 8000` |
| `CMD` | Default run command | `CMD ["uvicorn", "main:app"]` |
| `ENTRYPOINT` | Fixed run command | `ENTRYPOINT ["python"]` |
| `ARG` | Build-time variables | `ARG PYTHON_VERSION=3.13` |
| `USER` | Switch to non-root user | `USER appuser` |

## Layer Caching Strategy

Docker caches each layer. **Order matters for cache efficiency.**

### Bad (Cache invalidated on every code change):

```dockerfile
COPY . .                    # Code changes = cache miss
RUN pip install -r requirements.txt  # Reinstalls every time!
```

### Good (Dependencies cached separately):

```dockerfile
COPY requirements.txt .     # Only changes when deps change
RUN pip install -r requirements.txt  # Cached if requirements same
COPY . .                    # Code changes don't affect deps cache
```

**Rule**: Copy files that change less frequently FIRST.

## Multi-Stage Builds

Multi-stage builds create smaller, more secure images by separating
build-time dependencies from runtime.

### Why Multi-Stage?

| Single Stage | Multi-Stage |
|--------------|-------------|
| Build tools in final image | Build tools discarded |
| Larger image size (500MB+) | Smaller image (100-200MB) |
| More security vulnerabilities | Minimal attack surface |
| Slower deployments | Faster deployments |

### Pattern: Builder + Runtime

```dockerfile
# Stage 1: Builder (has all build tools)
FROM python:3.13-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

# Stage 2: Runtime (minimal, no build tools)
FROM python:3.13-slim AS runtime
WORKDIR /app
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/*
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0"]
```

## Python/FastAPI Dockerfile Patterns

### Simple FastAPI Dockerfile

```dockerfile
FROM python:3.13-slim

WORKDIR /app

# Install dependencies first (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app ./app

# Create non-root user for security
RUN adduser --disabled-password --gecos "" appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Production FastAPI with Multi-Stage

```dockerfile
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
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### FastAPI with UV Package Manager

```dockerfile
# ============================================
# Stage 1: Builder with UV
# ============================================
FROM python:3.13-slim AS builder

WORKDIR /app

# Install UV
RUN pip install uv

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies with UV
RUN uv sync --frozen --no-dev

# ============================================
# Stage 2: Runtime
# ============================================
FROM python:3.13-slim AS runtime

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Copy application
COPY app ./app

# Non-root user
RUN adduser --disabled-password --gecos "" --uid 10001 appuser
USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Node.js/Next.js Dockerfile Patterns

### Simple Next.js Dockerfile

```dockerfile
FROM node:22-alpine

WORKDIR /app

# Install dependencies first (layer caching)
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Copy source and build
COPY . .
RUN npm run build

# Non-root user
RUN adduser --disabled-password --gecos "" appuser
USER appuser

EXPOSE 3000

CMD ["npm", "start"]
```

### Production Next.js with Multi-Stage (Standalone)

```dockerfile
# ============================================
# Stage 1: Dependencies
# ============================================
FROM node:22-alpine AS deps

WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci

# ============================================
# Stage 2: Builder
# ============================================
FROM node:22-alpine AS builder

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Set environment for build
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Build the application
RUN npm run build

# ============================================
# Stage 3: Runner (Production)
# ============================================
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy only necessary files from builder
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Set ownership
RUN chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
```

**Note**: For standalone mode, add to `next.config.js`:

```javascript
module.exports = {
  output: 'standalone',
}
```

## .dockerignore File

Always create `.dockerignore` to exclude unnecessary files:

### Python .dockerignore

```
# Virtual environments
.venv/
venv/
env/

# Cache
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
.docker/

# Environment files (secrets!)
.env
.env.*
*.env

# Tests (optional - exclude from prod)
tests/
test/

# Documentation
*.md
docs/

# Build artifacts
dist/
build/
*.egg-info/
```

### Node.js .dockerignore

```
# Dependencies
node_modules/

# Build output (we build inside Docker)
.next/
out/
dist/
build/

# IDE
.vscode/
.idea/

# Git
.git/
.gitignore

# Docker
Dockerfile*
docker-compose*

# Environment files (secrets!)
.env
.env.*

# Tests
__tests__/
*.test.js
*.spec.js
coverage/

# Documentation
*.md

# Logs
*.log
npm-debug.log*
```

## Security Best Practices

### 1. Use Minimal Base Images

```dockerfile
# Good - Alpine (5MB)
FROM python:3.13-alpine

# Good - Slim (50MB)
FROM python:3.13-slim

# Avoid - Full (900MB+)
FROM python:3.13
```

### 2. Non-Root User

```dockerfile
# Create user with UID > 10000 (security recommendation)
RUN adduser --disabled-password --gecos "" --uid 10001 appuser
USER appuser
```

### 3. Pin Image Versions

```dockerfile
# Good - Pinned version
FROM python:3.13.1-slim

# Avoid - Latest (unpredictable)
FROM python:latest
```

### 4. Don't Store Secrets in Images

```dockerfile
# Bad - Secret in image layer!
ENV API_KEY=sk-secret123

# Good - Pass at runtime
# docker run -e API_KEY=sk-secret123 myapp
```

### 5. Use COPY Instead of ADD

```dockerfile
# Good - Explicit, predictable
COPY requirements.txt .

# Avoid - ADD has extra features (URL download, tar extraction)
ADD requirements.txt .
```

### 6. Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1
```

## Environment Variables

### Build-time vs Runtime

```dockerfile
# ARG = Build time only (not in final image)
ARG PYTHON_VERSION=3.13

# ENV = Available at runtime
ENV NODE_ENV=production
```

### Passing at Runtime

```bash
# Single variable
docker run -e DATABASE_URL="postgres://..." myapp

# From file
docker run --env-file .env myapp
```

## Docker Commands Reference

### Build

```bash
# Basic build
docker build -t myapp:v1 .

# Build with build args
docker build --build-arg PYTHON_VERSION=3.13 -t myapp:v1 .

# Build specific stage
docker build --target builder -t myapp:builder .

# No cache (clean build)
docker build --no-cache -t myapp:v1 .
```

### Run

```bash
# Basic run
docker run myapp:v1

# With port mapping
docker run -p 8000:8000 myapp:v1

# With environment variables
docker run -e DATABASE_URL="..." -e API_KEY="..." myapp:v1

# Detached (background)
docker run -d -p 8000:8000 myapp:v1

# With name
docker run -d --name backend -p 8000:8000 myapp:v1
```

### Management

```bash
# List running containers
docker ps

# List all containers
docker ps -a

# Stop container
docker stop backend

# Remove container
docker rm backend

# List images
docker images

# Remove image
docker rmi myapp:v1

# View logs
docker logs backend

# Execute command in running container
docker exec -it backend /bin/sh
```

## Image Size Comparison

| Approach | Typical Size | Use Case |
|----------|--------------|----------|
| Full base image | 800MB+ | Development only |
| Slim base image | 150-300MB | General use |
| Alpine base image | 50-150MB | Production |
| Multi-stage + Alpine | 30-100MB | Optimized production |

## Things to Avoid

- Using `latest` tag for base images (unpredictable).
- Running containers as root user.
- Storing secrets in Dockerfile or image layers.
- Using `ADD` when `COPY` is sufficient.
- Not using `.dockerignore` (bloated images).
- Installing unnecessary packages in final image.
- Not leveraging layer caching (slow builds).
- Single-stage builds for production (large images).

## References

- [Docker Official Best Practices](https://docs.docker.com/build/building/best-practices/)
- [Dockerfile Reference](https://docs.docker.com/reference/dockerfile/)
- [FastAPI Docker Best Practices](https://betterstack.com/community/guides/scaling-python/fastapi-docker-best-practices/)
- [Next.js Docker Guide 2025](https://dev.to/codeparrot/nextjs-deployment-with-docker-complete-guide-for-2025-3oe8)
- [Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)
