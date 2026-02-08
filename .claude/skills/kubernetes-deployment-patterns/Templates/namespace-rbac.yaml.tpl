# Kubernetes Namespace and RBAC Templates
# Namespaces provide logical isolation, RBAC controls access

---
# Basic Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: {{NAMESPACE}}
  labels:
    name: {{NAMESPACE}}
    environment: {{ENVIRONMENT}}

---
# Namespace with Resource Quotas
apiVersion: v1
kind: Namespace
metadata:
  name: {{NAMESPACE}}
  labels:
    name: {{NAMESPACE}}
    environment: {{ENVIRONMENT}}

---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: {{NAMESPACE}}-quota
  namespace: {{NAMESPACE}}
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    persistentvolumeclaims: "10"
    pods: "50"
    services: "20"
    secrets: "50"
    configmaps: "50"

---
# Namespace with Limit Ranges
apiVersion: v1
kind: LimitRange
metadata:
  name: {{NAMESPACE}}-limits
  namespace: {{NAMESPACE}}
spec:
  limits:
  # Container limits
  - type: Container
    default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "2000m"
      memory: "2Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
  # Pod limits
  - type: Pod
    max:
      cpu: "4000m"
      memory: "4Gi"
    min:
      cpu: "100m"
      memory: "128Mi"
  # PVC limits
  - type: PersistentVolumeClaim
    max:
      storage: "100Gi"
    min:
      storage: "1Gi"

---
# Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{SERVICE_ACCOUNT_NAME}}
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
automountServiceAccountToken: true

---
# Role (Namespace-scoped permissions)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ROLE_NAME}}
  namespace: {{NAMESPACE}}
rules:
# Pods
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
# ConfigMaps
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
# Secrets
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]

---
# RoleBinding (Bind Role to ServiceAccount)
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ROLE_BINDING_NAME}}
  namespace: {{NAMESPACE}}
subjects:
- kind: ServiceAccount
  name: {{SERVICE_ACCOUNT_NAME}}
  namespace: {{NAMESPACE}}
roleRef:
  kind: Role
  name: {{ROLE_NAME}}
  apiGroup: rbac.authorization.k8s.io

---
# ClusterRole (Cluster-wide permissions)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{CLUSTER_ROLE_NAME}}
rules:
# Read-only access to all resources
- apiGroups: [""]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]

---
# ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{CLUSTER_ROLE_BINDING_NAME}}
subjects:
- kind: ServiceAccount
  name: {{SERVICE_ACCOUNT_NAME}}
  namespace: {{NAMESPACE}}
roleRef:
  kind: ClusterRole
  name: {{CLUSTER_ROLE_NAME}}
  apiGroup: rbac.authorization.k8s.io

---
# Role for Application (Read ConfigMaps and Secrets)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{APP_NAME}}-role
  namespace: {{NAMESPACE}}
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]

---
# Role for CI/CD (Deploy and Update)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cicd-deployer
  namespace: {{NAMESPACE}}
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]

---
# Role for Monitoring (Read-only)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: monitoring-reader
  namespace: {{NAMESPACE}}
rules:
- apiGroups: [""]
  resources: ["pods", "services", "endpoints"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]

---
# Complete RBAC Setup for Application
# 1. Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{APP_NAME}}-sa
  namespace: {{NAMESPACE}}

---
# 2. Role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{APP_NAME}}-role
  namespace: {{NAMESPACE}}
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

---
# 3. RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{APP_NAME}}-binding
  namespace: {{NAMESPACE}}
subjects:
- kind: ServiceAccount
  name: {{APP_NAME}}-sa
  namespace: {{NAMESPACE}}
roleRef:
  kind: Role
  name: {{APP_NAME}}-role
  apiGroup: rbac.authorization.k8s.io

---
# 4. Use in Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{APP_NAME}}
  namespace: {{NAMESPACE}}
spec:
  template:
    spec:
      serviceAccountName: {{APP_NAME}}-sa
      containers:
      - name: {{APP_NAME}}
        image: {{IMAGE}}

---
# Network Policy (Restrict Traffic)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{APP_NAME}}-netpol
  namespace: {{NAMESPACE}}
spec:
  podSelector:
    matchLabels:
      app: {{APP_NAME}}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow from frontend
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8000
  egress:
  # Allow to database
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  # Allow DNS
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53

---
# Network Policy (Deny All)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: {{NAMESPACE}}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
# Network Policy (Allow All)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all
  namespace: {{NAMESPACE}}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  egress:
  - {}

---
# kubectl Commands for RBAC

# Create namespace
# kubectl create namespace {{NAMESPACE}}

# Create service account
# kubectl create serviceaccount {{SERVICE_ACCOUNT_NAME}} -n {{NAMESPACE}}

# Get service accounts
# kubectl get serviceaccounts -n {{NAMESPACE}}

# Get roles
# kubectl get roles -n {{NAMESPACE}}

# Get role bindings
# kubectl get rolebindings -n {{NAMESPACE}}

# Describe role
# kubectl describe role {{ROLE_NAME}} -n {{NAMESPACE}}

# Check permissions
# kubectl auth can-i get pods --as=system:serviceaccount:{{NAMESPACE}}:{{SERVICE_ACCOUNT_NAME}} -n {{NAMESPACE}}

# Get resource quotas
# kubectl get resourcequota -n {{NAMESPACE}}

# Get limit ranges
# kubectl get limitrange -n {{NAMESPACE}}

---
# Variable Reference
# Replace these placeholders with actual values:
#
# {{NAMESPACE}}                  - Kubernetes namespace
# {{ENVIRONMENT}}                - Environment (dev, staging, prod)
# {{APP_NAME}}                   - Application name
# {{SERVICE_ACCOUNT_NAME}}       - Service account name
# {{ROLE_NAME}}                  - Role name
# {{ROLE_BINDING_NAME}}          - RoleBinding name
# {{CLUSTER_ROLE_NAME}}          - ClusterRole name
# {{CLUSTER_ROLE_BINDING_NAME}}  - ClusterRoleBinding name
# {{IMAGE}}                      - Container image
