# kubectl Command Cheatsheet

Quick reference for commonly used kubectl commands.

## Cluster Info

```bash
# Cluster info
kubectl cluster-info

# View nodes
kubectl get nodes

# View all namespaces
kubectl get namespaces
```

## Context & Namespace

```bash
# View current context
kubectl config current-context

# Switch context
kubectl config use-context minikube

# Set default namespace
kubectl config set-context --current --namespace=todo-app
```

## Creating Resources

```bash
# Apply from file
kubectl apply -f deployment.yaml

# Apply all files in directory
kubectl apply -f k8s/

# Create from command line
kubectl create namespace todo-app
kubectl create secret generic my-secret --from-literal=key=value

# Create deployment directly
kubectl create deployment nginx --image=nginx:latest
```

## Viewing Resources

```bash
# Get pods
kubectl get pods
kubectl get pods -n todo-app
kubectl get pods -A  # All namespaces
kubectl get pods -o wide  # More details

# Get all resources
kubectl get all -n todo-app

# Get specific resource types
kubectl get deployments
kubectl get services
kubectl get configmaps
kubectl get secrets

# Watch mode (live updates)
kubectl get pods -w

# Output formats
kubectl get pods -o yaml
kubectl get pods -o json
kubectl get pods -o name
```

## Describing Resources

```bash
# Detailed info about resource
kubectl describe pod my-pod
kubectl describe deployment my-deployment
kubectl describe service my-service
kubectl describe node minikube

# Events (useful for debugging)
kubectl get events -n todo-app
kubectl get events --sort-by='.lastTimestamp'
```

## Logs

```bash
# View logs
kubectl logs my-pod
kubectl logs my-pod -c my-container  # Specific container

# Follow logs (live)
kubectl logs -f my-pod

# Last N lines
kubectl logs --tail=100 my-pod

# Logs by label
kubectl logs -l app=backend

# Logs from deployment
kubectl logs deployment/backend
```

## Executing Commands

```bash
# Get shell access
kubectl exec -it my-pod -- /bin/sh
kubectl exec -it my-pod -- /bin/bash

# Run single command
kubectl exec my-pod -- ls /app
kubectl exec my-pod -- env
kubectl exec my-pod -- cat /etc/hosts

# Specific container
kubectl exec -it my-pod -c my-container -- /bin/sh
```

## Port Forwarding

```bash
# Forward pod port
kubectl port-forward my-pod 8080:8000

# Forward service port
kubectl port-forward svc/my-service 8080:8000

# Forward deployment port
kubectl port-forward deployment/my-deployment 8080:8000

# Background (add & at end)
kubectl port-forward svc/my-service 8080:8000 &
```

## Scaling

```bash
# Scale deployment
kubectl scale deployment my-deployment --replicas=5

# Scale to zero (stop all pods)
kubectl scale deployment my-deployment --replicas=0

# Autoscale
kubectl autoscale deployment my-deployment --min=2 --max=10 --cpu-percent=80
```

## Updating Resources

```bash
# Edit resource
kubectl edit deployment my-deployment

# Update image
kubectl set image deployment/my-deployment container=image:v2

# Patch resource
kubectl patch deployment my-deployment -p '{"spec":{"replicas":3}}'

# Add label
kubectl label pods my-pod version=v1

# Add annotation
kubectl annotate pods my-pod description="my description"
```

## Rollout (Deployments)

```bash
# Check rollout status
kubectl rollout status deployment/my-deployment

# View rollout history
kubectl rollout history deployment/my-deployment

# Rollback to previous version
kubectl rollout undo deployment/my-deployment

# Rollback to specific revision
kubectl rollout undo deployment/my-deployment --to-revision=2

# Pause/Resume rollout
kubectl rollout pause deployment/my-deployment
kubectl rollout resume deployment/my-deployment

# Restart deployment (rolling restart)
kubectl rollout restart deployment/my-deployment
```

## Deleting Resources

```bash
# Delete by file
kubectl delete -f deployment.yaml

# Delete by name
kubectl delete pod my-pod
kubectl delete deployment my-deployment
kubectl delete service my-service

# Delete by label
kubectl delete pods -l app=backend

# Delete all pods in namespace
kubectl delete pods --all -n todo-app

# Delete namespace (and all resources)
kubectl delete namespace todo-app

# Force delete (stuck pods)
kubectl delete pod my-pod --force --grace-period=0
```

## ConfigMaps & Secrets

```bash
# Create ConfigMap
kubectl create configmap my-config --from-literal=key1=value1
kubectl create configmap my-config --from-file=config.json
kubectl create configmap my-config --from-env-file=.env

# Create Secret
kubectl create secret generic my-secret --from-literal=password=secret
kubectl create secret generic my-secret --from-file=ssh-key=~/.ssh/id_rsa

# View ConfigMap
kubectl get configmap my-config -o yaml

# View Secret (base64 encoded)
kubectl get secret my-secret -o yaml

# Decode secret value
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 -d
```

## Copying Files

```bash
# Copy from pod to local
kubectl cp my-pod:/path/to/file ./local-file

# Copy from local to pod
kubectl cp ./local-file my-pod:/path/to/file

# With namespace
kubectl cp todo-app/my-pod:/app/data ./data
```

## Resource Usage

```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods
kubectl top pods -n todo-app
kubectl top pods --containers  # Per container
```

## Debugging

```bash
# Run temporary debug pod
kubectl run debug --image=busybox -it --rm -- /bin/sh
kubectl run debug --image=curlimages/curl -it --rm -- /bin/sh

# Check pod events
kubectl describe pod my-pod | grep -A 10 Events

# Check why pod is not running
kubectl get pod my-pod -o yaml | grep -A 5 status

# Debug service connectivity
kubectl run curl --image=curlimages/curl -it --rm -- curl http://my-service:8000
```

## Labels & Selectors

```bash
# Get pods with specific label
kubectl get pods -l app=backend
kubectl get pods -l app=backend,version=v1

# Get pods without label
kubectl get pods -l '!version'

# Multiple conditions
kubectl get pods -l 'app in (frontend, backend)'
```

## Common Shortcuts

```bash
# Resource type shortcuts
kubectl get po      # pods
kubectl get svc     # services
kubectl get deploy  # deployments
kubectl get cm      # configmaps
kubectl get secret  # secrets
kubectl get ns      # namespaces
kubectl get no      # nodes
kubectl get rs      # replicasets
kubectl get ds      # daemonsets
kubectl get sts     # statefulsets
kubectl get ing     # ingress
kubectl get pv      # persistentvolumes
kubectl get pvc     # persistentvolumeclaims
```

## Useful Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kga='kubectl get all'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
```

## Quick Reference Table

| Action | Command |
|--------|---------|
| List pods | `kubectl get pods` |
| Pod logs | `kubectl logs <pod>` |
| Shell access | `kubectl exec -it <pod> -- /bin/sh` |
| Port forward | `kubectl port-forward <pod> 8080:8000` |
| Scale | `kubectl scale deploy/<name> --replicas=3` |
| Rollback | `kubectl rollout undo deploy/<name>` |
| Delete | `kubectl delete <type> <name>` |
| Apply changes | `kubectl apply -f <file>` |
