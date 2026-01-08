# Docker Compose Examples

Docker Compose is used to run multiple containers together locally.

## Example 1: Basic Full-Stack (Frontend + Backend)

```yaml
# docker-compose.yml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/todo
      - BETTER_AUTH_SECRET=your-secret-key
    depends_on:
      - db
    restart: unless-stopped

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:8000
    depends_on:
      - backend
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=todo
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped

volumes:
  postgres_data:
```

**Commands:**
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Rebuild and start
docker-compose up -d --build
```

---

## Example 2: Development with Hot Reload

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.dev
    ports:
      - "8000:8000"
    volumes:
      - ./backend/app:/app/app  # Hot reload
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/todo
      - DEBUG=true
    depends_on:
      - db

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules  # Preserve node_modules
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=todo
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

**Run:**
```bash
docker-compose -f docker-compose.dev.yml up
```

---

## Example 3: Production with External Database

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  backend:
    image: myregistry/backend:${TAG:-latest}
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=${DATABASE_URL}  # External (e.g., Neon)
      - BETTER_AUTH_SECRET=${BETTER_AUTH_SECRET}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: always

  frontend:
    image: myregistry/frontend:${TAG:-latest}
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:8000
    depends_on:
      - backend
    restart: always
```

**Run with .env file:**
```bash
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

---

## Example 4: Using Environment File

**.env file:**
```bash
# Database
DATABASE_URL=postgresql://user:pass@db:5432/todo
POSTGRES_USER=user
POSTGRES_PASSWORD=pass
POSTGRES_DB=todo

# Backend
BETTER_AUTH_SECRET=super-secret-key
GEMINI_API_KEY=your-api-key

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:8000

# Version
TAG=v1.0.0
```

**docker-compose.yml with env_file:**
```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    env_file:
      - .env
    depends_on:
      - db

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    env_file:
      - .env
    depends_on:
      - backend

  db:
    image: postgres:16-alpine
    env_file:
      - .env
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

---

## Useful Commands

```bash
# Build images without running
docker-compose build

# Build specific service
docker-compose build backend

# Start specific service
docker-compose up backend

# Scale service (multiple instances)
docker-compose up -d --scale backend=3

# View running containers
docker-compose ps

# Execute command in running container
docker-compose exec backend python manage.py migrate

# Remove containers and volumes
docker-compose down -v

# Remove containers, volumes, and images
docker-compose down -v --rmi all
```

---

## Network Communication

Containers in the same compose file can communicate by service name:

```
frontend → http://backend:8000 ✅
backend → postgres://db:5432 ✅

# NOT localhost!
frontend → http://localhost:8000 ❌ (only works from host machine)
```

---

## Best Practices

1. **Always use `depends_on`** for service dependencies
2. **Use volumes for data persistence** (databases)
3. **Use `.env` files** for configuration (don't commit secrets)
4. **Use `restart: unless-stopped`** for production
5. **Use health checks** for production reliability
6. **Separate dev and prod compose files**
