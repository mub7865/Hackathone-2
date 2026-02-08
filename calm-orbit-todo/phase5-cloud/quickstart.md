# Quickstart Guide: Cloud-Native Event-Driven Todo Application

**Get up and running in 15 minutes!**

This guide provides the fastest path to running the Todo Application locally for development.

---

## Prerequisites

- **Docker Desktop**: [Download](https://www.docker.com/products/docker-desktop)
- **Git**: [Download](https://git-scm.com/downloads)
- **Node.js 20+**: [Download](https://nodejs.org/)
- **Python 3.13+**: [Download](https://www.python.org/downloads/)

---

## Quick Start (Local Development)

### 1. Clone Repository

```bash
git clone https://github.com/your-org/todo-app.git
cd todo-app/calm-orbit-todo/phase5-cloud
```

### 2. Start Infrastructure

```bash
# Start PostgreSQL, Kafka, and Redis
docker-compose up -d

# Verify services are running
docker-compose ps
```

### 3. Setup Backend

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cat > .env << EOF
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/todo_db
JWT_SECRET=dev-secret-key-change-in-production
JWT_ALGORITHM=HS256
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
ENVIRONMENT=development
LOG_LEVEL=DEBUG
EOF

# Run migrations
alembic upgrade head

# Start backend server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend is now running at `http://localhost:8000`

### 4. Setup Frontend (New Terminal)

```bash
cd frontend

# Install dependencies
npm install

# Create .env.local file
cat > .env.local << EOF
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_WS_URL=ws://localhost:8000
EOF

# Start frontend server
npm run dev
```

Frontend is now running at `http://localhost:3000`

### 5. Access Application

Open your browser and navigate to:
- **Frontend**: http://localhost:3000
- **Backend API Docs**: http://localhost:8000/docs
- **Backend Health**: http://localhost:8000/health

---

## Quick Start (Docker Compose - Full Stack)

For a complete containerized setup:

```bash
# Clone repository
git clone https://github.com/your-org/todo-app.git
cd todo-app/calm-orbit-todo/phase5-cloud

# Start all services
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

Access:
- **Frontend**: http://localhost:3000
- **Backend**: http://localhost:8000
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3001 (admin/admin123)

---

## Quick Start (Kubernetes - Minikube)

For local Kubernetes deployment:

```bash
# Start Minikube
minikube start --cpus=4 --memory=8192

# Enable addons
minikube addons enable ingress

# Deploy application
kubectl apply -f k8s/

# Wait for pods to be ready
kubectl wait --for=condition=ready pod --all --timeout=300s

# Get Minikube IP
minikube ip

# Access application
# Add to /etc/hosts: <minikube-ip> todo-app.local
# Open http://todo-app.local
```

---

## Verify Installation

### Backend Health Check

```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "healthy",
  "database": "connected",
  "kafka": "connected"
}
```

### Create Test Task

```bash
# Register user (if authentication is enabled)
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Login to get token
TOKEN=$(curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}' \
  | jq -r '.access_token')

# Create task
curl -X POST http://localhost:8000/api/v1/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"My first task","priority":"high"}'

# List tasks
curl http://localhost:8000/api/v1/tasks \
  -H "Authorization: Bearer $TOKEN"
```

---

## Common Issues

### Port Already in Use

```bash
# Check what's using the port
lsof -i :8000  # Backend
lsof -i :3000  # Frontend
lsof -i :5432  # PostgreSQL
lsof -i :9092  # Kafka

# Kill the process
kill -9 <PID>
```

### Database Connection Failed

```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Restart PostgreSQL
docker-compose restart postgres

# Check logs
docker-compose logs postgres
```

### Kafka Connection Failed

```bash
# Check Kafka is running
docker ps | grep kafka

# Restart Kafka
docker-compose restart kafka zookeeper

# Check logs
docker-compose logs kafka
```

### Frontend Can't Connect to Backend

```bash
# Verify backend is running
curl http://localhost:8000/health

# Check CORS settings in backend
# Ensure NEXT_PUBLIC_API_URL is correct in frontend .env.local
```

---

## Next Steps

### Explore Features

1. **Create Tasks**: Add your first tasks with priorities and tags
2. **Set Reminders**: Configure due dates and reminders
3. **Recurring Tasks**: Set up daily/weekly recurring tasks
4. **Search & Filter**: Use advanced search and saved filters
5. **Notifications**: Configure notification preferences

### Development

- **API Documentation**: http://localhost:8000/docs
- **Backend Code**: `backend/app/`
- **Frontend Code**: `frontend/src/`
- **Database Migrations**: `backend/alembic/versions/`

### Testing

```bash
# Backend tests
cd backend
pytest tests/ -v

# Frontend tests
cd frontend
npm test

# Integration tests
cd backend
pytest tests/integration/ -v
```

### Monitoring

```bash
# Start monitoring stack
kubectl apply -f k8s/monitoring/

# Access Prometheus
kubectl port-forward svc/prometheus 9090:9090

# Access Grafana
kubectl port-forward svc/grafana 3000:3000
```

---

## Configuration

### Environment Variables

**Backend** (`.env`):
```env
# Database
DATABASE_URL=postgresql+asyncpg://user:password@host:5432/database

# JWT Authentication
JWT_SECRET=your-secret-key
JWT_ALGORITHM=HS256
JWT_EXPIRATION_MINUTES=15

# Kafka
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
KAFKA_TOPIC_PREFIX=todo-app

# Email (optional)
SENDGRID_API_KEY=your-sendgrid-api-key
SENDGRID_FROM_EMAIL=noreply@example.com

# Environment
ENVIRONMENT=development
LOG_LEVEL=DEBUG
```

**Frontend** (`.env.local`):
```env
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_WS_URL=ws://localhost:8000
```

---

## Stopping Services

### Local Development

```bash
# Stop backend (Ctrl+C in terminal)

# Stop frontend (Ctrl+C in terminal)

# Stop infrastructure
docker-compose down
```

### Docker Compose

```bash
docker-compose -f docker-compose.prod.yml down
```

### Kubernetes

```bash
kubectl delete -f k8s/
minikube stop
```

---

## Clean Up

### Remove All Data

```bash
# Remove Docker volumes
docker-compose down -v

# Remove Minikube cluster
minikube delete

# Remove virtual environment
rm -rf backend/venv

# Remove node modules
rm -rf frontend/node_modules
```

---

## Getting Help

- **Documentation**: See `docs/` directory
  - [Architecture Overview](docs/architecture.md)
  - [Deployment Guide](docs/deployment.md)
  - [API Reference](docs/api-reference.md)
  - [User Guide](docs/user-guide.md)

- **Issues**: https://github.com/your-org/todo-app/issues
- **Support**: support@todo-app.example.com

---

## Production Deployment

For production deployment, see:
- [Deployment Guide](docs/deployment.md)
- [Monitoring Guide](docs/monitoring.md)
- [Security Best Practices](docs/deployment.md#security-checklist)

**Important**: Never use development settings in production!

---

## What's Next?

1. **Read the Documentation**: Explore the comprehensive docs
2. **Try the Features**: Create tasks, set reminders, use filters
3. **Customize**: Modify the code to fit your needs
4. **Deploy**: Deploy to your cloud provider
5. **Monitor**: Set up monitoring and alerting
6. **Contribute**: Submit issues and pull requests

---

## Quick Reference

### Useful Commands

```bash
# Backend
uvicorn app.main:app --reload                    # Start backend
pytest tests/ -v                                  # Run tests
alembic upgrade head                              # Run migrations
alembic revision --autogenerate -m "message"     # Create migration

# Frontend
npm run dev                                       # Start frontend
npm test                                          # Run tests
npm run build                                     # Build for production
npm run lint                                      # Run linter

# Docker
docker-compose up -d                              # Start services
docker-compose down                               # Stop services
docker-compose logs -f                            # View logs
docker-compose ps                                 # Check status

# Kubernetes
kubectl get pods                                  # List pods
kubectl logs <pod-name>                          # View logs
kubectl describe pod <pod-name>                  # Pod details
kubectl port-forward svc/<service> 8000:8000    # Port forward
```

### Default Ports

- **Frontend**: 3000
- **Backend**: 8000
- **PostgreSQL**: 5432
- **Kafka**: 9092
- **Redis**: 6379
- **Prometheus**: 9090
- **Grafana**: 3001

### Default Credentials

- **Grafana**: admin / admin123
- **PostgreSQL**: postgres / postgres

**Remember**: Change all default credentials in production!

---

## Success!

You now have a fully functional Todo Application running locally. Start creating tasks and exploring the features!

For detailed information, see the [complete documentation](docs/).

Happy coding! 🚀
