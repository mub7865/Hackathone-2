# Next.js Dockerfile Examples

## Example 1: Simple Development Dockerfile

Best for: Local development with hot reload

```dockerfile
# Dockerfile.dev
FROM node:22-alpine

WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Copy source
COPY . .

# Development mode
ENV NODE_ENV=development

EXPOSE 3000

CMD ["npm", "run", "dev"]
```

**Build & Run:**
```bash
docker build -f Dockerfile.dev -t frontend:dev .
docker run -p 3000:3000 -v $(pwd):/app -v /app/node_modules frontend:dev
```

---

## Example 2: Production Multi-Stage Dockerfile (Standalone)

Best for: Production deployments, Kubernetes

**Requires `next.config.js`:**
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
}

module.exports = nextConfig
```

**Dockerfile:**
```dockerfile
# ============================================
# Stage 1: Dependencies
# ============================================
FROM node:22-alpine AS deps

WORKDIR /app

# Install dependencies only
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

# Environment for build
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

# Copy standalone output
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
```

**Build & Run:**
```bash
docker build -t frontend:v1 .
docker run -d -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL="http://backend:8000" \
  --name frontend frontend:v1
```

---

## Example 3: Next.js without Standalone (Standard Build)

Best for: When standalone mode is not suitable

```dockerfile
# ============================================
# Stage 1: Dependencies
# ============================================
FROM node:22-alpine AS deps

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --only=production

# ============================================
# Stage 2: Builder
# ============================================
FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

# ============================================
# Stage 3: Runner
# ============================================
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Copy production dependencies
COPY --from=deps /app/node_modules ./node_modules

# Copy built application
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

# Non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs && \
    chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000

CMD ["npm", "start"]
```

---

## Example 4: Next.js with Environment Variables at Build Time

Best for: When you need to bake environment variables into the build

```dockerfile
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:22-alpine AS builder
WORKDIR /app

# Build-time arguments (passed during docker build)
ARG NEXT_PUBLIC_API_URL
ARG NEXT_PUBLIC_APP_NAME

# Set as environment variables for build
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_APP_NAME=$NEXT_PUBLIC_APP_NAME

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build

FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

RUN adduser --system --uid 1001 nextjs
USER nextjs

EXPOSE 3000
CMD ["node", "server.js"]
```

**Build with args:**
```bash
docker build \
  --build-arg NEXT_PUBLIC_API_URL="https://api.example.com" \
  --build-arg NEXT_PUBLIC_APP_NAME="Todo App" \
  -t frontend:v1 .
```

---

## .dockerignore for Next.js

```
# Dependencies
node_modules/

# Build output (built inside Docker)
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
.docker/

# Environment (secrets!)
.env
.env.*
!.env.example

# Tests
__tests__/
*.test.js
*.test.ts
*.spec.js
*.spec.ts
coverage/
jest.config.*

# Documentation
*.md
docs/

# Misc
*.log
.DS_Store
```

---

## Image Size Comparison

| Dockerfile Type | Approximate Size |
|-----------------|------------------|
| Simple (node:22) | 1.5 GB |
| Simple (node:22-alpine) | 500 MB |
| Multi-stage (no standalone) | 300 MB |
| Multi-stage (standalone) | 150 MB |

---

## Common Issues & Fixes

### Issue: "next: command not found"

**Cause**: node_modules not properly copied

**Fix**: Ensure proper COPY in deps stage
```dockerfile
COPY package.json package-lock.json ./
RUN npm ci  # Not npm install
```

### Issue: Standalone mode not working

**Cause**: Missing config

**Fix**: Add to `next.config.js`
```javascript
module.exports = {
  output: 'standalone',
}
```

### Issue: Environment variables not available

**Cause**: `NEXT_PUBLIC_*` vars must be set at build time

**Fix**: Use build args
```dockerfile
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
RUN npm run build
```

### Issue: Static files not loading

**Cause**: Missing static folder copy

**Fix**: Ensure you copy both standalone and static
```dockerfile
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
```

### Issue: Container can't connect to backend

**Cause**: Using localhost instead of container name

**Fix**: Use Docker network and service names
```bash
# Wrong
NEXT_PUBLIC_API_URL=http://localhost:8000

# Right (when using docker-compose or K8s)
NEXT_PUBLIC_API_URL=http://backend:8000
```
