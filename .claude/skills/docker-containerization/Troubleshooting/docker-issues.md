# Troubleshooting Docker Issues

This guide covers common Docker issues and their solutions.

## Table of Contents

1. [Build Issues](#build-issues)
2. [Container Issues](#container-issues)
3. [Network Issues](#network-issues)
4. [Volume Issues](#volume-issues)
5. [Performance Issues](#performance-issues)

---

## Build Issues

### Issue 1: Build Fails with "No Space Left on Device"

**Symptoms:**
- Build fails with disk space error
- Cannot create new layers
- Docker commands slow or failing

**Diagnosis:**

```bash
# Check Docker disk usage
docker system df

# Check detailed usage
docker system df -v

# Check host disk space
df -h
```

**Solutions:**

#### Solution 1: Clean Up Docker Resources

```bash
# Remove unused containers, networks, images
docker system prune -a

# Remove unused volumes
docker volume prune

# Remove specific images
docker rmi $(docker images -f "dangling=true" -q)

# Remove stopped containers
docker container prune
```

#### Solution 2: Increase Docker Storage

```bash
# For Docker Desktop (Mac/Windows)
# Settings → Resources → Disk image size

# For Linux, change storage location
# Edit /etc/docker/daemon.json
{
  "data-root": "/new/path/to/docker"
}

# Restart Docker
sudo systemctl restart docker
```

---

### Issue 2: Build Fails with "Cannot Connect to Docker Daemon"

**Symptoms:**
- Build commands fail immediately
- Error: "Cannot connect to the Docker daemon"
- Docker commands not working

**Diagnosis:**

```bash
# Check if Docker daemon is running
docker info

# Check Docker service status (Linux)
sudo systemctl status docker

# Check Docker Desktop status (Mac/Windows)
# Look for Docker icon in system tray
```

**Solutions:**

#### Solution 1: Start Docker Daemon

```bash
# Linux
sudo systemctl start docker

# Enable on boot
sudo systemctl enable docker

# Mac/Windows
# Start Docker Desktop application
```

#### Solution 2: Fix Permissions

```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER

# Log out and log back in for changes to take effect

# Or use newgrp
newgrp docker
```

---

### Issue 3: Build Fails with "Failed to Fetch" or Network Errors

**Symptoms:**
- Cannot download packages during build
- apt-get or npm install fails
- Timeout errors

**Diagnosis:**

```bash
# Test network from container
docker run --rm alpine ping -c 3 google.com

# Check DNS resolution
docker run --rm alpine nslookup google.com

# Check Docker network settings
docker network inspect bridge
```

**Solutions:**

#### Solution 1: Configure DNS

```bash
# Edit /etc/docker/daemon.json
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}

# Restart Docker
sudo systemctl restart docker
```

#### Solution 2: Use Proxy

```bash
# Set build args for proxy
docker build \
  --build-arg HTTP_PROXY=http://proxy.example.com:8080 \
  --build-arg HTTPS_PROXY=http://proxy.example.com:8080 \
  -t myimage .

# Or configure in daemon.json
{
  "proxies": {
    "default": {
      "httpProxy": "http://proxy.example.com:8080",
      "httpsProxy": "http://proxy.example.com:8080"
    }
  }
}
```

---

### Issue 4: Build is Very Slow

**Symptoms:**
- Build takes much longer than expected
- Each layer takes long time
- Repeated builds don't use cache

**Diagnosis:**

```bash
# Check build cache usage
docker build --progress=plain -t myimage .

# Check Docker storage driver
docker info | grep "Storage Driver"

# Check system resources
docker stats
```

**Solutions:**

#### Solution 1: Optimize Dockerfile

```dockerfile
# Bad: Installs dependencies every time
COPY . .
RUN npm install

# Good: Cache dependencies
COPY package*.json ./
RUN npm install
COPY . .
```

#### Solution 2: Use BuildKit

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Or in daemon.json
{
  "features": {
    "buildkit": true
  }
}

# Build with BuildKit
DOCKER_BUILDKIT=1 docker build -t myimage .
```

#### Solution 3: Use .dockerignore

```
# .dockerignore
node_modules/
.git/
*.log
.env
dist/
build/
```

---

## Container Issues

### Issue 1: Container Exits Immediately

**Symptoms:**
- Container starts but exits right away
- Status shows "Exited (0)" or "Exited (1)"
- Application not running

**Diagnosis:**

```bash
# Check container status
docker ps -a

# Check container logs
docker logs <container-id>

# Check exit code
docker inspect <container-id> --format='{{.State.ExitCode}}'

# Run container interactively
docker run -it <image> /bin/sh
```

**Common Causes and Solutions:**

#### Cause 1: No Foreground Process

**Solution:** Ensure CMD runs in foreground

```dockerfile
# Bad: Background process
CMD ["npm", "start", "&"]

# Good: Foreground process
CMD ["npm", "start"]

# Bad: Shell exits immediately
CMD ["echo", "Hello"]

# Good: Long-running process
CMD ["node", "server.js"]
```

#### Cause 2: Application Error

**Solution:** Check logs and fix application

```bash
# View logs
docker logs <container-id>

# View logs with timestamps
docker logs -t <container-id>

# Follow logs
docker logs -f <container-id>
```

#### Cause 3: Missing Dependencies

**Solution:** Install all dependencies in Dockerfile

```dockerfile
# Ensure all dependencies are installed
RUN apt-get update && apt-get install -y \
    dependency1 \
    dependency2 \
    && rm -rf /var/lib/apt/lists/*
```

---

### Issue 2: Container Keeps Restarting

**Symptoms:**
- Container status shows "Restarting"
- Application crashes repeatedly
- High CPU usage

**Diagnosis:**

```bash
# Check container status
docker ps -a

# Check logs
docker logs <container-id> --tail 100

# Check restart count
docker inspect <container-id> --format='{{.RestartCount}}'

# Check events
docker events --filter container=<container-id>
```

**Solutions:**

#### Solution 1: Fix Application Error

```bash
# Check logs for error messages
docker logs <container-id>

# Common errors:
# - Port already in use
# - Database connection failed
# - Missing environment variables
# - File not found
```

#### Solution 2: Adjust Restart Policy

```bash
# Remove restart policy temporarily
docker update --restart=no <container-id>

# Or in docker-compose.yml
services:
  app:
    restart: "no"  # or "on-failure" or "unless-stopped"
```

---

### Issue 3: Cannot Access Container

**Symptoms:**
- Cannot connect to container port
- Connection refused or timeout
- Application not accessible

**Diagnosis:**

```bash
# Check if container is running
docker ps

# Check port mapping
docker port <container-id>

# Check if port is listening inside container
docker exec <container-id> netstat -tuln

# Test from host
curl http://localhost:8000

# Test from another container
docker run --rm curlimages/curl curl http://<container-ip>:8000
```

**Solutions:**

#### Solution 1: Fix Port Mapping

```bash
# Ensure port is exposed and mapped
docker run -p 8000:8000 myimage

# In Dockerfile
EXPOSE 8000

# In docker-compose.yml
ports:
  - "8000:8000"
```

#### Solution 2: Check Application Binding

```dockerfile
# Bad: Binds to localhost only
CMD ["node", "server.js"]  # Defaults to 127.0.0.1

# Good: Binds to all interfaces
CMD ["node", "server.js", "--host", "0.0.0.0"]

# Or set in application
# app.listen(8000, '0.0.0.0')
```

---

### Issue 4: Container Out of Memory

**Symptoms:**
- Container killed with exit code 137
- OOMKilled in container status
- Application crashes randomly

**Diagnosis:**

```bash
# Check container memory usage
docker stats <container-id>

# Check if OOMKilled
docker inspect <container-id> --format='{{.State.OOMKilled}}'

# Check memory limit
docker inspect <container-id> --format='{{.HostConfig.Memory}}'
```

**Solutions:**

#### Solution 1: Increase Memory Limit

```bash
# Run with more memory
docker run -m 512m myimage

# In docker-compose.yml
services:
  app:
    mem_limit: 512m
```

#### Solution 2: Optimize Application

```bash
# For Node.js, increase heap size
CMD ["node", "--max-old-space-size=512", "server.js"]

# For Python, optimize memory usage
# Use generators, close connections, etc.
```

---

## Network Issues

### Issue 1: Containers Cannot Communicate

**Symptoms:**
- Container cannot reach another container
- Connection timeout between containers
- DNS resolution fails

**Diagnosis:**

```bash
# Check container networks
docker network ls

# Inspect network
docker network inspect bridge

# Check container IP
docker inspect <container-id> --format='{{.NetworkSettings.IPAddress}}'

# Test connectivity
docker exec <container-1> ping <container-2-ip>
```

**Solutions:**

#### Solution 1: Use Same Network

```bash
# Create custom network
docker network create mynetwork

# Run containers on same network
docker run --network mynetwork --name container1 image1
docker run --network mynetwork --name container2 image2

# In docker-compose.yml (automatic)
services:
  app1:
    networks:
      - mynetwork
  app2:
    networks:
      - mynetwork

networks:
  mynetwork:
```

#### Solution 2: Use Container Names

```bash
# Use container name instead of IP
docker exec container1 ping container2

# In application
# Use http://container2:8000 instead of http://172.17.0.3:8000
```

---

### Issue 2: Cannot Access External Network

**Symptoms:**
- Container cannot reach internet
- Cannot download packages
- DNS resolution fails

**Diagnosis:**

```bash
# Test internet connectivity
docker run --rm alpine ping -c 3 google.com

# Test DNS
docker run --rm alpine nslookup google.com

# Check Docker network settings
docker network inspect bridge
```

**Solutions:**

#### Solution 1: Configure DNS

```bash
# Edit /etc/docker/daemon.json
{
  "dns": ["8.8.8.8", "1.1.1.1"]
}

# Restart Docker
sudo systemctl restart docker
```

#### Solution 2: Check Firewall

```bash
# Check iptables rules
sudo iptables -L -n

# Allow Docker traffic
sudo iptables -A FORWARD -i docker0 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o docker0 -j ACCEPT
```

---

## Volume Issues

### Issue 1: Volume Data Not Persisting

**Symptoms:**
- Data lost after container restart
- Volume appears empty
- Changes not saved

**Diagnosis:**

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect <volume-name>

# Check volume mount
docker inspect <container-id> --format='{{.Mounts}}'
```

**Solutions:**

#### Solution 1: Use Named Volumes

```bash
# Create named volume
docker volume create mydata

# Use named volume
docker run -v mydata:/app/data myimage

# In docker-compose.yml
services:
  app:
    volumes:
      - mydata:/app/data

volumes:
  mydata:
```

#### Solution 2: Check Mount Path

```bash
# Ensure mount path is correct
docker run -v /host/path:/container/path myimage

# Check if path exists in container
docker exec <container-id> ls -la /container/path
```

---

### Issue 2: Permission Denied on Volume

**Symptoms:**
- Cannot write to volume
- Permission denied errors
- Application fails to save files

**Diagnosis:**

```bash
# Check volume permissions
docker exec <container-id> ls -la /app/data

# Check user running in container
docker exec <container-id> whoami

# Check file ownership
docker exec <container-id> stat /app/data
```

**Solutions:**

#### Solution 1: Fix Permissions in Dockerfile

```dockerfile
# Create directory with correct permissions
RUN mkdir -p /app/data && \
    chown -R appuser:appuser /app/data

USER appuser
```

#### Solution 2: Use Volume Permissions

```bash
# Run as specific user
docker run --user 1000:1000 -v mydata:/app/data myimage

# In docker-compose.yml
services:
  app:
    user: "1000:1000"
    volumes:
      - mydata:/app/data
```

---

## Performance Issues

### Issue 1: Slow Container Performance

**Symptoms:**
- Container runs slower than expected
- High CPU or memory usage
- Application timeouts

**Diagnosis:**

```bash
# Check resource usage
docker stats

# Check container processes
docker top <container-id>

# Check logs for errors
docker logs <container-id>
```

**Solutions:**

#### Solution 1: Allocate More Resources

```bash
# Increase CPU and memory
docker run --cpus=2 --memory=2g myimage

# In docker-compose.yml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

#### Solution 2: Optimize Application

```bash
# Use production builds
ENV NODE_ENV=production

# Enable caching
# Use CDN for static assets
# Optimize database queries
```

---

## General Debugging Commands

```bash
# View container logs
docker logs <container-id>
docker logs -f <container-id>  # Follow
docker logs --tail 100 <container-id>  # Last 100 lines

# Execute command in container
docker exec <container-id> <command>
docker exec -it <container-id> /bin/sh  # Interactive shell

# Inspect container
docker inspect <container-id>

# Check container processes
docker top <container-id>

# View container stats
docker stats <container-id>

# View container events
docker events --filter container=<container-id>

# Copy files from container
docker cp <container-id>:/path/to/file ./local/path

# View container filesystem changes
docker diff <container-id>

# Export container filesystem
docker export <container-id> > container.tar
```

---

## Best Practices for Troubleshooting

1. **Check logs first**: Most issues are visible in logs
2. **Use docker inspect**: Provides detailed container information
3. **Test interactively**: Use `docker run -it` to debug
4. **Check resource usage**: Use `docker stats` to monitor
5. **Verify network connectivity**: Test with ping and curl
6. **Check permissions**: Ensure correct user and file permissions
7. **Review Dockerfile**: Look for common mistakes
8. **Use .dockerignore**: Exclude unnecessary files
9. **Enable BuildKit**: Faster builds with better caching
10. **Keep Docker updated**: Use latest stable version
