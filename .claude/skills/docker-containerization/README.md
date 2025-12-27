# Docker Containerization Skill

## Overview

This skill provides complete patterns and best practices for containerizing applications with Docker. It covers Dockerfiles, multi-stage builds, layer optimization, security practices, and production-ready configurations.

## Supported Technologies

- **Python**: FastAPI, Flask, Django
- **Node.js**: Next.js, React, Express
- **Package Managers**: pip, UV, npm, pnpm

## Key Features

- Multi-stage build patterns for smaller images
- Layer caching optimization for faster builds
- Security best practices (non-root users, minimal images)
- Production-ready Dockerfile templates
- .dockerignore configurations

## Quick Reference

### Python/FastAPI

```dockerfile
FROM python:3.13-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
RUN adduser --disabled-password appuser && chown -R appuser /app
USER appuser
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Node.js/Next.js

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN adduser --disabled-password appuser
USER appuser
EXPOSE 3000
CMD ["npm", "start"]
```

## Files

- `SKILL.md` - Complete skill documentation with all patterns
- `Examples/` - Real-world example Dockerfiles

## Usage

Reference this skill when:
- Creating new Dockerfiles
- Optimizing existing Docker images
- Setting up CI/CD with Docker
- Preparing for Kubernetes deployment

## Sources

- [Docker Official Best Practices](https://docs.docker.com/build/building/best-practices/)
- [FastAPI Docker Best Practices](https://betterstack.com/community/guides/scaling-python/fastapi-docker-best-practices/)
- [Next.js Docker Guide 2025](https://dev.to/codeparrot/nextjs-deployment-with-docker-complete-guide-for-2025-3oe8)
