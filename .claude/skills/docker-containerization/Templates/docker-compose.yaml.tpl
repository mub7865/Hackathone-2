# Docker Compose Templates
# Multi-container application orchestration

---
# Basic Docker Compose (Single Service)
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    restart: unless-stopped

---
# Full-Stack Application (Frontend + Backend + Database)
version: '3.8'

services:
  # PostgreSQL Database
  database:
    image: postgres:16-alpine
    container_name: todo-db
    environment:
      POSTGRES_USER: ${DB_USER:-postgres}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-postgres}
      POSTGRES_DB: ${DB_NAME:-todo}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # Backend API
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: todo-backend
    environment:
      DATABASE_URL: postgresql://${DB_USER:-postgres}:${DB_PASSWORD:-postgres}@database:5432/${DB_NAME:-todo}
      PORT: 8000
      NODE_ENV: production
    ports:
      - "8000:8000"
    depends_on:
      database:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
    restart: unless-stopped

  # Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: todo-frontend
    environment:
      NEXT_PUBLIC_API_URL: http://backend:8000
      PORT: 3000
    ports:
      - "3000:3000"
    depends_on:
      - backend
    restart: unless-stopped

volumes:
  postgres_data:

---
# Full-Stack with Redis and Nginx
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # Redis Cache
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped

  # Backend API
  backend:
    build: ./backend
    environment:
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/${DB_NAME}
      REDIS_URL: redis://redis:6379
      PORT: 8000
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped

  # Frontend
  frontend:
    build: ./frontend
    environment:
      NEXT_PUBLIC_API_URL: http://backend:8000
    depends_on:
      - backend
    restart: unless-stopped

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - frontend
      - backend
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:

---
# Development Environment with Hot Reload
version: '3.8'

services:
  database:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: todo_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.dev
    volumes:
      - ./backend:/app
      - /app/node_modules
    environment:
      DATABASE_URL: postgresql://postgres:postgres@database:5432/todo_dev
      NODE_ENV: development
    ports:
      - "8000:8000"
    depends_on:
      - database
    command: npm run dev

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    volumes:
      - ./frontend:/app
      - /app/node_modules
      - /app/.next
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:8000
    ports:
      - "3000:3000"
    depends_on:
      - backend
    command: npm run dev

volumes:
  postgres_dev_data:

---
# Microservices Architecture
version: '3.8'

services:
  # API Gateway
  gateway:
    build: ./gateway
    ports:
      - "80:80"
    environment:
      AUTH_SERVICE_URL: http://auth:8001
      USER_SERVICE_URL: http://users:8002
      TASK_SERVICE_URL: http://tasks:8003
    depends_on:
      - auth
      - users
      - tasks
    restart: unless-stopped

  # Auth Service
  auth:
    build: ./services/auth
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/auth
      REDIS_URL: redis://redis:6379
      JWT_SECRET: ${JWT_SECRET}
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

  # User Service
  users:
    build: ./services/users
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/users
      REDIS_URL: redis://redis:6379
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

  # Task Service
  tasks:
    build: ./services/tasks
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/tasks
      REDIS_URL: redis://redis:6379
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

  # PostgreSQL
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db.sql:/docker-entrypoint-initdb.d/init.sql
    restart: unless-stopped

  # Redis
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:

---
# With Celery Workers and Beat
version: '3.8'

services:
  # PostgreSQL
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: app
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  # Redis (Celery Broker)
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped

  # Backend API
  backend:
    build: ./backend
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/app
      CELERY_BROKER_URL: redis://redis:6379/0
      CELERY_RESULT_BACKEND: redis://redis:6379/0
    ports:
      - "8000:8000"
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

  # Celery Worker
  celery_worker:
    build: ./backend
    command: celery -A app.celery worker --loglevel=info
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/app
      CELERY_BROKER_URL: redis://redis:6379/0
      CELERY_RESULT_BACKEND: redis://redis:6379/0
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

  # Celery Beat (Scheduler)
  celery_beat:
    build: ./backend
    command: celery -A app.celery beat --loglevel=info
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/app
      CELERY_BROKER_URL: redis://redis:6379/0
      CELERY_RESULT_BACKEND: redis://redis:6379/0
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

  # Flower (Celery Monitoring)
  flower:
    build: ./backend
    command: celery -A app.celery flower --port=5555
    environment:
      CELERY_BROKER_URL: redis://redis:6379/0
      CELERY_RESULT_BACKEND: redis://redis:6379/0
    ports:
      - "5555:5555"
    depends_on:
      - redis
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:

---
# With Monitoring (Prometheus + Grafana)
version: '3.8'

services:
  # Application
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      METRICS_ENABLED: "true"
    restart: unless-stopped

  # Prometheus
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    restart: unless-stopped

  # Grafana
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
    depends_on:
      - prometheus
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:

---
# Docker Compose Best Practices

# 1. Use version 3.8 or later
version: '3.8'

# 2. Use environment variables
environment:
  DATABASE_URL: ${DATABASE_URL}
  # Or use .env file

# 3. Use health checks
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
  interval: 30s
  timeout: 3s
  retries: 3

# 4. Use depends_on with conditions
depends_on:
  database:
    condition: service_healthy

# 5. Use named volumes
volumes:
  postgres_data:
  redis_data:

# 6. Use restart policies
restart: unless-stopped

# 7. Use build context and dockerfile
build:
  context: ./backend
  dockerfile: Dockerfile

# 8. Expose only necessary ports
ports:
  - "8000:8000"  # host:container

# 9. Use networks for isolation
networks:
  frontend:
  backend:

# 10. Use resource limits (optional)
deploy:
  resources:
    limits:
      cpus: '0.5'
      memory: 512M

---
# Docker Compose Commands

# Start services
docker-compose up

# Start in background
docker-compose up -d

# Build and start
docker-compose up --build

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# View logs
docker-compose logs

# Follow logs
docker-compose logs -f

# View logs for specific service
docker-compose logs backend

# Execute command in service
docker-compose exec backend bash

# Scale service
docker-compose up -d --scale worker=3

# Restart service
docker-compose restart backend

# View running services
docker-compose ps

# View resource usage
docker-compose top
