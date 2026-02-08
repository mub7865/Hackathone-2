# Node.js Dockerfile Templates
# Multi-stage builds for production-ready Node.js applications

---
# Basic Node.js Dockerfile
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Run application
CMD ["node", "index.js"]

---
# Production Node.js Dockerfile (Multi-stage)
# Stage 1: Builder
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev)
RUN npm ci

# Copy source code
COPY . .

# Build application (if needed)
RUN npm run build

# Stage 2: Runtime
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy built application from builder
COPY --from=builder /app/dist ./dist

# Create non-root user
RUN addgroup -g 10001 appgroup && \
    adduser -D -u 10001 -G appgroup appuser && \
    chown -R appuser:appgroup /app

USER appuser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node healthcheck.js || exit 1

# Run application
CMD ["node", "dist/index.js"]

---
# Next.js Dockerfile (Production)
# Stage 1: Dependencies
FROM node:20-alpine AS deps

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Stage 2: Builder
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy source code
COPY . .

# Set environment variables for build
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Build Next.js application
RUN npm run build

# Stage 3: Runner
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user
RUN addgroup -g 10001 nodejs && \
    adduser -D -u 10001 -G nodejs nextjs

# Copy necessary files
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

---
# Express.js Dockerfile (Production)
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

# If using TypeScript
RUN npm run build

FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

COPY --from=builder /app/dist ./dist

RUN addgroup -g 10001 appgroup && \
    adduser -D -u 10001 -G appgroup appuser && \
    chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/index.js"]

---
# NestJS Dockerfile (Production)
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

RUN npm run build

FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

COPY --from=builder /app/dist ./dist

RUN addgroup -g 10001 appgroup && \
    adduser -D -u 10001 -G appgroup appuser && \
    chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

CMD ["node", "dist/main.js"]

---
# Node.js with pnpm
FROM node:20-alpine AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build application
RUN pnpm run build

FROM node:20-alpine

WORKDIR /app

RUN npm install -g pnpm

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod

COPY --from=builder /app/dist ./dist

RUN addgroup -g 10001 appgroup && \
    adduser -D -u 10001 -G appgroup appuser && \
    chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

CMD ["node", "dist/index.js"]

---
# Node.js with Yarn
FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json yarn.lock ./

RUN yarn install --frozen-lockfile

COPY . .

RUN yarn build

FROM node:20-alpine

WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --production && \
    yarn cache clean

COPY --from=builder /app/dist ./dist

RUN addgroup -g 10001 appgroup && \
    adduser -D -u 10001 -G appgroup appuser && \
    chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

CMD ["node", "dist/index.js"]

---
# Node.js with Bun
FROM oven/bun:1 AS builder

WORKDIR /app

COPY package.json bun.lockb ./

RUN bun install --frozen-lockfile

COPY . .

RUN bun build ./src/index.ts --outdir ./dist --target bun

FROM oven/bun:1-alpine

WORKDIR /app

COPY package.json bun.lockb ./
RUN bun install --frozen-lockfile --production

COPY --from=builder /app/dist ./dist

RUN addgroup -g 10001 appgroup && \
    adduser -D -u 10001 -G appgroup appuser && \
    chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

CMD ["bun", "run", "dist/index.js"]

---
# Best Practices for Node.js Dockerfiles

# 1. Use specific Node version
FROM node:20-alpine  # Not node:latest

# 2. Use alpine for smaller images
# alpine images are ~5x smaller than regular images

# 3. Use multi-stage builds
# - Separate build and runtime stages
# - Smaller final image
# - Faster builds with layer caching

# 4. Copy package files separately
COPY package*.json ./
RUN npm ci
# This allows Docker to cache the dependency layer

# 5. Use npm ci instead of npm install
# - Faster and more reliable
# - Uses package-lock.json
# - Removes node_modules before installing

# 6. Install only production dependencies in final stage
RUN npm ci --only=production

# 7. Clean npm cache
RUN npm cache clean --force

# 8. Create non-root user
RUN adduser -D -u 10001 appuser
USER appuser

# 9. Add health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget --spider http://localhost:3000/health || exit 1

# 10. Set NODE_ENV
ENV NODE_ENV=production

# 11. Disable telemetry (Next.js)
ENV NEXT_TELEMETRY_DISABLED=1

# 12. Use .dockerignore
# Create .dockerignore file to exclude:
# - node_modules/
# - npm-debug.log
# - .git/
# - .env
# - .next/
# - dist/
# - coverage/

---
# .dockerignore for Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-debug.log*
.npm/
.yarn/
.next/
.nuxt/
dist/
build/
out/
coverage/
.nyc_output/
.cache/
.parcel-cache/
.env
.env.local
.env.*.local
.git/
.gitignore
.dockerignore
Dockerfile
docker-compose.yml
README.md
.vscode/
.idea/
*.log
.DS_Store
