# Calm Orbit Todo - Minikube Deployment Guide

Complete guide for deploying Calm Orbit Todo to Minikube for local testing.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Docker Desktop** (for Windows/Mac) or **Docker Engine** (for Linux)
- **Minikube** (v1.30+)
- **kubectl** (v1.27+)
- **Git**

### Installation Links

- Docker: https://docs.docker.com/get-docker/
- Minikube: https://minikube.sigs.k8s.io/docs/start/
- kubectl: https://kubernetes.io/docs/tasks/tools/

## Quick Start (Automated)

The easiest way to deploy is using the automated setup script:

```bash
cd /mnt/d/Hackathons/hackathon-2/calm-orbit-todo/phase5-cloud

# Run complete setup (starts Minikube, builds images, deploys)
./scripts/setup-minikube.sh
```

This script will:
1. Start Minikube with proper configuration
2. Build Docker images in Minikube's environment
3. Deploy all services (PostgreSQL, Backend, Frontend)
4. Display access URLs

## Manual Deployment (Step-by-Step)

If you prefer manual control or need to troubleshoot:

### Step 1: Start Minikube

```bash
# Start Minikube with recommended settings
./scripts/start-minikube.sh

# Or manually:
minikube start --cpus=4 --memory=4096 --disk-size=20g --driver=docker
```

### Step 2: Build Docker Images

```bash
# Build images in Minikube's Docker environment
./scripts/build-minikube.sh

# Or manually:
eval $(minikube docker-env)
cd backend && docker build -t calm-orbit-backend:latest .
cd ../frontend && docker build -t calm-orbit-frontend:latest .
```

### Step 3: Deploy to Kubernetes

```bash
# Deploy all services
./scripts/deploy-minikube.sh

# Or manually apply manifests:
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/01-secrets.yaml
kubectl apply -f k8s/02-configmap.yaml
kubectl apply -f k8s/03-postgres.yaml
kubectl apply -f k8s/04-backend.yaml
kubectl apply -f k8s/05-frontend.yaml
```

### Step 4: Access the Application

```bash
# Get Minikube IP
minikube ip

# Access URLs:
# Frontend: http://<minikube-ip>:30300
# Backend:  http://<minikube-ip>:30800
```

## Docker Compose (Alternative for Local Development)

For simpler local development without Kubernetes:

```bash
cd /mnt/d/Hackathons/hackathon-2/calm-orbit-todo/phase5-cloud

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

Access URLs:
- Frontend: http://localhost:3000
- Backend: http://localhost:8000
- PostgreSQL: localhost:5432

## Monitoring and Debugging

### View Pod Status

```bash
# Watch pods in real-time
kubectl get pods -n calm-orbit -w

# Get detailed pod information
kubectl describe pod <pod-name> -n calm-orbit
```

### View Logs

```bash
# Backend logs
kubectl logs -f -l app=backend -n calm-orbit

# Frontend logs
kubectl logs -f -l app=frontend -n calm-orbit

# PostgreSQL logs
kubectl logs -f -l app=postgres -n calm-orbit

# All logs from a specific pod
kubectl logs -f <pod-name> -n calm-orbit
```

### Check Services

```bash
# List all services
kubectl get svc -n calm-orbit

# Get service details
kubectl describe svc calm-orbit-backend -n calm-orbit
```

### Access Pod Shell

```bash
# Backend pod
kubectl exec -it <backend-pod-name> -n calm-orbit -- /bin/sh

# PostgreSQL pod
kubectl exec -it <postgres-pod-name> -n calm-orbit -- psql -U postgres -d calm_orbit_todo
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n calm-orbit

# Common issues:
# 1. Image pull errors - Ensure images are built in Minikube's Docker
# 2. Resource limits - Increase Minikube memory/CPU
# 3. Database connection - Check PostgreSQL is ready
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
kubectl get pods -l app=postgres -n calm-orbit

# Test database connection from backend pod
kubectl exec -it <backend-pod-name> -n calm-orbit -- \
  python -c "import asyncpg; print('DB connection test')"
```

### Image Not Found

```bash
# Ensure you're using Minikube's Docker daemon
eval $(minikube docker-env)

# Rebuild images
./scripts/build-minikube.sh

# Verify images exist
docker images | grep calm-orbit
```

### Port Already in Use

```bash
# Check what's using the port
lsof -i :30300  # Frontend
lsof -i :30800  # Backend

# Or change NodePort in k8s manifests
```

## Updating the Deployment

### Update Backend Code

```bash
# Rebuild backend image
eval $(minikube docker-env)
cd backend && docker build -t calm-orbit-backend:latest .

# Restart backend pods
kubectl rollout restart deployment calm-orbit-backend -n calm-orbit

# Watch rollout status
kubectl rollout status deployment calm-orbit-backend -n calm-orbit
```

### Update Frontend Code

```bash
# Rebuild frontend image
eval $(minikube docker-env)
cd frontend && docker build -t calm-orbit-frontend:latest .

# Restart frontend pods
kubectl rollout restart deployment calm-orbit-frontend -n calm-orbit
```

### Update Configuration

```bash
# Edit ConfigMap
kubectl edit configmap calm-orbit-config -n calm-orbit

# Edit Secrets
kubectl edit secret calm-orbit-secrets -n calm-orbit

# Restart affected pods
kubectl rollout restart deployment calm-orbit-backend -n calm-orbit
kubectl rollout restart deployment calm-orbit-frontend -n calm-orbit
```

## Cleanup

### Remove Deployment

```bash
# Remove all resources
./scripts/cleanup-minikube.sh

# Or manually:
kubectl delete namespace calm-orbit
```

### Stop Minikube

```bash
# Stop Minikube
minikube stop

# Delete Minikube cluster (removes all data)
minikube delete
```

## Performance Tuning

### Increase Resources

```bash
# Stop Minikube
minikube stop

# Start with more resources
minikube start --cpus=6 --memory=8192 --disk-size=40g
```

### Scale Deployments

```bash
# Scale backend replicas
kubectl scale deployment calm-orbit-backend --replicas=3 -n calm-orbit

# Scale frontend replicas
kubectl scale deployment calm-orbit-frontend --replicas=3 -n calm-orbit
```

## Database Management

### Backup Database

```bash
# Create backup
kubectl exec -it <postgres-pod-name> -n calm-orbit -- \
  pg_dump -U postgres calm_orbit_todo > backup.sql
```

### Restore Database

```bash
# Restore from backup
kubectl exec -i <postgres-pod-name> -n calm-orbit -- \
  psql -U postgres calm_orbit_todo < backup.sql
```

### Run Migrations

```bash
# Access backend pod
kubectl exec -it <backend-pod-name> -n calm-orbit -- /bin/sh

# Run Alembic migrations
alembic upgrade head
```

## Next Steps

After successful Minikube deployment:

1. **Test all features** - Verify frontend UI, task management, chatbot
2. **Check logs** - Ensure no errors in backend/frontend
3. **Performance testing** - Test with multiple users
4. **Cloud deployment** - Ready to deploy to DigitalOcean/AWS/Azure

## Useful Commands Reference

```bash
# Minikube
minikube status                    # Check Minikube status
minikube dashboard                 # Open Kubernetes dashboard
minikube service list              # List all services
minikube ip                        # Get Minikube IP

# kubectl
kubectl get all -n calm-orbit      # List all resources
kubectl get events -n calm-orbit   # View cluster events
kubectl top pods -n calm-orbit     # View resource usage
kubectl port-forward <pod> 8000:8000 -n calm-orbit  # Port forward

# Docker
docker ps                          # List running containers
docker images                      # List images
docker logs <container>            # View container logs
```

## Support

For issues or questions:
1. Check logs: `kubectl logs -f -l app=backend -n calm-orbit`
2. Check pod status: `kubectl get pods -n calm-orbit`
3. Review troubleshooting section above
4. Check GitHub issues or create a new one

---

**Ready to deploy to cloud?** See `docs/cloud-deployment.md` for production deployment guides.
