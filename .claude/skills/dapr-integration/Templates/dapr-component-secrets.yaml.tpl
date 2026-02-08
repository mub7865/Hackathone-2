# Dapr Secrets Component Configuration Template
#
# This template provides secrets component configurations for various secret stores.
# Place this file in: ./components/secrets.yaml (local) or deploy to Kubernetes

# ============================================================================
# Local File Secret Store (Development Only)
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: local-secret-store
spec:
  type: secretstores.local.file
  version: v1
  metadata:
  - name: secretsFile
    value: "./secrets.json"
  - name: nestedSeparator
    value: ":"

---
# ============================================================================
# Kubernetes Secret Store
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: kubernetes-secret-store
spec:
  type: secretstores.kubernetes
  version: v1
  metadata: []
# No additional metadata needed - uses Kubernetes service account

---
# ============================================================================
# Azure Key Vault Secret Store
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: azurekeyvault-secret-store
spec:
  type: secretstores.azure.keyvault
  version: v1
  metadata:
  - name: vaultName
    value: "my-keyvault"
  - name: azureTenantId
    value: "tenant-id"
  - name: azureClientId
    value: "client-id"
  - name: azureClientSecret
    value: "client-secret"

---
# ============================================================================
# Azure Key Vault with Managed Identity
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: azurekeyvault-mi-secret-store
spec:
  type: secretstores.azure.keyvault
  version: v1
  metadata:
  - name: vaultName
    value: "my-keyvault"
  - name: azureEnvironment
    value: "AZUREPUBLICCLOUD"
  # Uses Azure Managed Identity - no credentials needed

---
# ============================================================================
# AWS Secrets Manager
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: aws-secret-store
spec:
  type: secretstores.aws.secretmanager
  version: v1
  metadata:
  - name: region
    value: "us-east-1"
  - name: accessKey
    value: "AWS_ACCESS_KEY"
  - name: secretKey
    value: "AWS_SECRET_KEY"
  - name: sessionToken
    value: ""

---
# ============================================================================
# AWS Secrets Manager with IAM Role
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: aws-iam-secret-store
spec:
  type: secretstores.aws.secretmanager
  version: v1
  metadata:
  - name: region
    value: "us-east-1"
  # Uses IAM role attached to pod - no credentials needed

---
# ============================================================================
# GCP Secret Manager
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: gcp-secret-store
spec:
  type: secretstores.gcp.secretmanager
  version: v1
  metadata:
  - name: type
    value: "service_account"
  - name: project_id
    value: "my-gcp-project"
  - name: private_key_id
    value: "key-id"
  - name: private_key
    value: "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
  - name: client_email
    value: "my-service-account@my-project.iam.gserviceaccount.com"
  - name: client_id
    value: "1234567890"
  - name: auth_uri
    value: "https://accounts.google.com/o/oauth2/auth"
  - name: token_uri
    value: "https://oauth2.googleapis.com/token"
  - name: auth_provider_x509_cert_url
    value: "https://www.googleapis.com/oauth2/v1/certs"
  - name: client_x509_cert_url
    value: "https://www.googleapis.com/robot/v1/metadata/x509/..."

---
# ============================================================================
# HashiCorp Vault Secret Store
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: vault-secret-store
spec:
  type: secretstores.hashicorp.vault
  version: v1
  metadata:
  - name: vaultAddr
    value: "https://vault.example.com:8200"
  - name: vaultToken
    value: "vault-token"
  - name: vaultTokenMountPath
    value: "/vault/secrets"
  - name: skipVerify
    value: "false"
  - name: enginePath
    value: "secret"
  - name: vaultValueType
    value: "map"  # or "text"

---
# ============================================================================
# HashiCorp Vault with Kubernetes Auth
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: vault-k8s-secret-store
spec:
  type: secretstores.hashicorp.vault
  version: v1
  metadata:
  - name: vaultAddr
    value: "https://vault.example.com:8200"
  - name: vaultKubernetesMountPath
    value: "kubernetes"
  - name: vaultRole
    value: "myapp-role"
  - name: skipVerify
    value: "false"
  - name: enginePath
    value: "secret"

---
# ============================================================================
# Environment Variables Secret Store (Development Only)
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: env-secret-store
spec:
  type: secretstores.local.env
  version: v1
  metadata: []

---
# ============================================================================
# Using Secrets in Other Components
# ============================================================================

# Example: Redis with secret password
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
spec:
  type: state.redis
  version: v1
  metadata:
  - name: redisHost
    value: localhost:6379
  - name: redisPassword
    secretKeyRef:
      name: redis-secret  # Secret name in secret store
      key: password       # Key within the secret
auth:
  secretStore: kubernetes-secret-store  # Which secret store to use

---
# ============================================================================
# Scopes (Limit secret store to specific apps)
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: kubernetes-secret-store
spec:
  type: secretstores.kubernetes
  version: v1
  metadata: []
scopes:
  - app1
  - app2
  # Only app1 and app2 can access this secret store

---
# ============================================================================
# Local Secrets File Format (secrets.json)
# ============================================================================
# {
#   "redis-password": "my-redis-password",
#   "database": {
#     "username": "admin",
#     "password": "db-password"
#   },
#   "api-keys": {
#     "stripe": "sk_test_...",
#     "sendgrid": "SG...."
#   }
# }
#
# Access nested secrets with separator:
# - redis-password → "my-redis-password"
# - database:username → "admin"
# - api-keys:stripe → "sk_test_..."
