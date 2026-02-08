# Kubernetes PodDisruptionBudget (PDB) Templates
# PDB ensures minimum availability during voluntary disruptions

---
# Basic PDB (Minimum Available)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{APP_NAME}}-pdb
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
spec:
  minAvailable: {{MIN_AVAILABLE}}  # e.g., 2 or "50%"
  selector:
    matchLabels:
      app: {{APP_NAME}}

---
# PDB with Maximum Unavailable
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{APP_NAME}}-pdb-maxunavailable
  namespace: {{NAMESPACE}}
spec:
  maxUnavailable: {{MAX_UNAVAILABLE}}  # e.g., 1 or "25%"
  selector:
    matchLabels:
      app: {{APP_NAME}}

---
# PDB for High Availability (Percentage)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{APP_NAME}}-pdb-ha
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
    tier: {{TIER}}
spec:
  minAvailable: "80%"  # Keep 80% of pods available
  selector:
    matchLabels:
      app: {{APP_NAME}}

---
# PDB for Critical Services
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{APP_NAME}}-pdb-critical
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
    criticality: high
spec:
  minAvailable: 3  # Always keep at least 3 pods
  selector:
    matchLabels:
      app: {{APP_NAME}}

---
# PDB with Unhealthy Pod Eviction Policy
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{APP_NAME}}-pdb-eviction
  namespace: {{NAMESPACE}}
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: {{APP_NAME}}
  unhealthyPodEvictionPolicy: IfHealthyBudget  # or AlwaysAllow

---
# PDB Best Practices

# 1. Use minAvailable for critical services
#    - Ensures minimum number of pods always running
#    - Example: minAvailable: 2 (for 3 replicas)

# 2. Use maxUnavailable for flexible scaling
#    - Allows more aggressive updates
#    - Example: maxUnavailable: 1 (for 5 replicas)

# 3. Use percentages for dynamic scaling
#    - Works with HPA
#    - Example: minAvailable: "75%"

# 4. Don't set too restrictive PDBs
#    - Can block node drains and cluster upgrades
#    - Balance availability with operational flexibility

# 5. Test PDB behavior
#    - Simulate node drains
#    - Verify updates work as expected

---
# PDB Examples by Use Case

# Web Frontend (High Availability)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: frontend-pdb
  namespace: {{NAMESPACE}}
spec:
  minAvailable: "75%"
  selector:
    matchLabels:
      app: frontend

---
# Backend API (Critical Service)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: backend-pdb
  namespace: {{NAMESPACE}}
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: backend

---
# Database (Stateful)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: database-pdb
  namespace: {{NAMESPACE}}
spec:
  maxUnavailable: 1  # Only one pod can be down at a time
  selector:
    matchLabels:
      app: database

---
# Worker Pods (Flexible)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: worker-pdb
  namespace: {{NAMESPACE}}
spec:
  maxUnavailable: "50%"  # Can tolerate half being down
  selector:
    matchLabels:
      app: worker

---
# kubectl Commands for PDB

# Create PDB
# kubectl apply -f pdb.yaml

# Get PDBs
# kubectl get pdb -n {{NAMESPACE}}

# Describe PDB
# kubectl describe pdb {{APP_NAME}}-pdb -n {{NAMESPACE}}

# Check PDB status
# kubectl get pdb {{APP_NAME}}-pdb -n {{NAMESPACE}} -o yaml

# Delete PDB
# kubectl delete pdb {{APP_NAME}}-pdb -n {{NAMESPACE}}

---
# Testing PDB

# 1. Drain a node (simulates maintenance)
# kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# 2. Watch pod evictions
# kubectl get pods -n {{NAMESPACE}} --watch

# 3. Check PDB status
# kubectl get pdb -n {{NAMESPACE}}

# 4. Verify minimum pods maintained
# kubectl get pods -n {{NAMESPACE}} -l app={{APP_NAME}}

# 5. Uncordon node after testing
# kubectl uncordon <node-name>

---
# PDB and Deployment Updates

# PDB affects rolling updates
# If PDB is too restrictive, updates may be blocked

# Example: 3 replicas, minAvailable: 3
# - Rolling update cannot proceed (no pod can be terminated)
# - Solution: Set minAvailable: 2 or maxUnavailable: 1

# Example: 5 replicas, maxUnavailable: 1
# - Rolling update can proceed (1 pod can be terminated at a time)
# - Update will be slower but safer

---
# Variable Reference
# Replace these placeholders with actual values:
#
# {{APP_NAME}}         - Application name
# {{NAMESPACE}}        - Kubernetes namespace
# {{MIN_AVAILABLE}}    - Minimum available pods (number or percentage)
# {{MAX_UNAVAILABLE}}  - Maximum unavailable pods (number or percentage)
# {{TIER}}             - Application tier
