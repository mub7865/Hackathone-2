# Minikube Local Development Skill

## Overview

This skill provides a complete guide for local Kubernetes development with Minikube. It covers installation, configuration, image management, addons, networking, and troubleshooting for efficient local development workflows.

## Key Features

- Cross-platform installation (Windows, macOS, Linux)
- Multiple driver support (Docker, Hyper-V, VirtualBox)
- Local Docker image management
- Essential addons (dashboard, ingress, metrics)
- Service access methods
- Troubleshooting common issues

## Quick Reference

### Start Cluster

```bash
# Basic start
minikube start

# With Docker driver
minikube start --driver=docker

# With custom resources
minikube start --cpus=4 --memory=8192
```

### Load Local Images

```bash
# Method 1: Use Minikube's Docker
eval $(minikube docker-env)
docker build -t my-app:v1 .

# Method 2: Load pre-built image
minikube image load my-app:v1
```

### Access Services

```bash
# Open service in browser
minikube service my-service

# Get service URL
minikube service my-service --url

# Start tunnel for LoadBalancer
minikube tunnel
```

### Essential Commands

```bash
minikube status        # Check status
minikube stop          # Stop cluster
minikube delete        # Delete cluster
minikube dashboard     # Open web UI
minikube ip            # Get cluster IP
minikube ssh           # SSH into node
```

## Files

- `SKILL.md` - Complete skill documentation
- `Examples/` - Practical examples and guides

## Usage

Reference this skill when:
- Setting up local Kubernetes environment
- Testing applications before cloud deployment
- Learning Kubernetes without cloud costs
- Debugging Kubernetes deployments

## Sources

- [Minikube Official Documentation](https://minikube.sigs.k8s.io/docs/)
- [Minikube Start Guide](https://minikube.sigs.k8s.io/docs/start/)
- [Pushing Images to Minikube](https://minikube.sigs.k8s.io/docs/handbook/pushing/)
