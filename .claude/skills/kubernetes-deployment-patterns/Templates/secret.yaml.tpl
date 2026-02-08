# Kubernetes Secret Templates
# Secrets store sensitive data (passwords, API keys, certificates)

---
# Basic Secret (Opaque)
apiVersion: v1
kind: Secret
metadata:
  name: {{APP_NAME}}-secrets
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
type: Opaque
stringData:
  # Use stringData for plaintext (K8s converts to base64)
  DATABASE_URL: "{{DATABASE_URL}}"
  API_KEY: "{{API_KEY}}"
  JWT_SECRET: "{{JWT_SECRET}}"
  ENCRYPTION_KEY: "{{ENCRYPTION_KEY}}"

---
# Secret with Base64 Encoded Data
apiVersion: v1
kind: Secret
metadata:
  name: {{APP_NAME}}-secrets-encoded
  namespace: {{NAMESPACE}}
type: Opaque
data:
  # Values must be base64 encoded
  # echo -n "value" | base64
  DATABASE_URL: {{DATABASE_URL_BASE64}}
  API_KEY: {{API_KEY_BASE64}}

---
# Docker Registry Secret
# For pulling images from private registries
apiVersion: v1
kind: Secret
metadata:
  name: {{REGISTRY_SECRET_NAME}}
  namespace: {{NAMESPACE}}
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: {{DOCKER_CONFIG_JSON_BASE64}}

# Create with kubectl:
# kubectl create secret docker-registry {{REGISTRY_SECRET_NAME}} \
#   --docker-server={{REGISTRY_SERVER}} \
#   --docker-username={{REGISTRY_USERNAME}} \
#   --docker-password={{REGISTRY_PASSWORD}} \
#   --docker-email={{REGISTRY_EMAIL}} \
#   -n {{NAMESPACE}}

---
# TLS Secret
# For HTTPS/TLS certificates
apiVersion: v1
kind: Secret
metadata:
  name: {{APP_NAME}}-tls
  namespace: {{NAMESPACE}}
type: kubernetes.io/tls
data:
  # Base64 encoded certificate and key
  tls.crt: {{TLS_CERT_BASE64}}
  tls.key: {{TLS_KEY_BASE64}}

# Create with kubectl:
# kubectl create secret tls {{APP_NAME}}-tls \
#   --cert=path/to/tls.crt \
#   --key=path/to/tls.key \
#   -n {{NAMESPACE}}

---
# SSH Auth Secret
# For SSH authentication
apiVersion: v1
kind: Secret
metadata:
  name: {{APP_NAME}}-ssh
  namespace: {{NAMESPACE}}
type: kubernetes.io/ssh-auth
data:
  ssh-privatekey: {{SSH_PRIVATE_KEY_BASE64}}

# Create with kubectl:
# kubectl create secret generic {{APP_NAME}}-ssh \
#   --from-file=ssh-privatekey=path/to/id_rsa \
#   --type=kubernetes.io/ssh-auth \
#   -n {{NAMESPACE}}

---
# Basic Auth Secret
# For basic HTTP authentication
apiVersion: v1
kind: Secret
metadata:
  name: {{APP_NAME}}-basic-auth
  namespace: {{NAMESPACE}}
type: kubernetes.io/basic-auth
stringData:
  username: {{USERNAME}}
  password: {{PASSWORD}}

---
# Complete Application Secrets
apiVersion: v1
kind: Secret
metadata:
  name: {{APP_NAME}}-app-secrets
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
    environment: {{ENVIRONMENT}}
type: Opaque
stringData:
  # Database credentials
  DATABASE_URL: "postgresql://{{DB_USER}}:{{DB_PASSWORD}}@{{DB_HOST}}:{{DB_PORT}}/{{DB_NAME}}"
  DB_USER: "{{DB_USER}}"
  DB_PASSWORD: "{{DB_PASSWORD}}"

  # API keys
  GEMINI_API_KEY: "{{GEMINI_API_KEY}}"
  OPENAI_API_KEY: "{{OPENAI_API_KEY}}"
  STRIPE_API_KEY: "{{STRIPE_API_KEY}}"
  SENDGRID_API_KEY: "{{SENDGRID_API_KEY}}"

  # Authentication
  JWT_SECRET: "{{JWT_SECRET}}"
  BETTER_AUTH_SECRET: "{{BETTER_AUTH_SECRET}}"
  SESSION_SECRET: "{{SESSION_SECRET}}"

  # Encryption
  ENCRYPTION_KEY: "{{ENCRYPTION_KEY}}"
  ENCRYPTION_IV: "{{ENCRYPTION_IV}}"

  # OAuth credentials
  GOOGLE_CLIENT_ID: "{{GOOGLE_CLIENT_ID}}"
  GOOGLE_CLIENT_SECRET: "{{GOOGLE_CLIENT_SECRET}}"
  GITHUB_CLIENT_ID: "{{GITHUB_CLIENT_ID}}"
  GITHUB_CLIENT_SECRET: "{{GITHUB_CLIENT_SECRET}}"

  # Cloud provider credentials
  AWS_ACCESS_KEY_ID: "{{AWS_ACCESS_KEY_ID}}"
  AWS_SECRET_ACCESS_KEY: "{{AWS_SECRET_ACCESS_KEY}}"
  GCP_SERVICE_ACCOUNT_KEY: "{{GCP_SERVICE_ACCOUNT_KEY}}"

  # Monitoring and logging
  SENTRY_DSN: "{{SENTRY_DSN}}"
  DATADOG_API_KEY: "{{DATADOG_API_KEY}}"

---
# Multi-Environment Secrets
# Development
apiVersion: v1
kind: Secret
metadata:
  name: {{APP_NAME}}-dev-secrets
  namespace: {{NAMESPACE}}-dev
type: Opaque
stringData:
  DATABASE_URL: "{{DEV_DATABASE_URL}}"
  API_KEY: "{{DEV_API_KEY}}"

---
# Staging
apiVersion: v1
kind: Secret
metadata:
  name: {{APP_NAME}}-staging-secrets
  namespace: {{NAMESPACE}}-staging
type: Opaque
stringData:
  DATABASE_URL: "{{STAGING_DATABASE_URL}}"
  API_KEY: "{{STAGING_API_KEY}}"

---
# Production
apiVersion: v1
kind: Secret
metadata:
  name: {{APP_NAME}}-prod-secrets
  namespace: {{NAMESPACE}}-prod
type: Opaque
stringData:
  DATABASE_URL: "{{PROD_DATABASE_URL}}"
  API_KEY: "{{PROD_API_KEY}}"

---
# Using Secrets in Deployment

# Method 1: All keys as environment variables
spec:
  containers:
  - name: {{APP_NAME}}
    envFrom:
    - secretRef:
        name: {{APP_NAME}}-secrets

# Method 2: Specific keys as environment variables
spec:
  containers:
  - name: {{APP_NAME}}
    env:
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: {{APP_NAME}}-secrets
          key: DATABASE_URL
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: {{APP_NAME}}-secrets
          key: API_KEY

# Method 3: Mount as volume (files)
spec:
  containers:
  - name: {{APP_NAME}}
    volumeMounts:
    - name: secrets-volume
      mountPath: /app/secrets
      readOnly: true
  volumes:
  - name: secrets-volume
    secret:
      secretName: {{APP_NAME}}-secrets
      defaultMode: 0400  # Read-only for owner

# Method 4: Mount specific keys as files
spec:
  containers:
  - name: {{APP_NAME}}
    volumeMounts:
    - name: secrets-volume
      mountPath: /app/secrets
      readOnly: true
  volumes:
  - name: secrets-volume
    secret:
      secretName: {{APP_NAME}}-secrets
      items:
      - key: DATABASE_URL
        path: database-url
        mode: 0400
      - key: API_KEY
        path: api-key
        mode: 0400

# Method 5: Use with imagePullSecrets (Docker registry)
spec:
  imagePullSecrets:
  - name: {{REGISTRY_SECRET_NAME}}
  containers:
  - name: {{APP_NAME}}
    image: {{PRIVATE_REGISTRY}}/{{IMAGE}}:{{VERSION}}

---
# Secret Best Practices

# 1. Never commit secrets to Git
# 2. Use external secret management (Sealed Secrets, External Secrets Operator)
# 3. Rotate secrets regularly
# 4. Use RBAC to restrict secret access
# 5. Enable encryption at rest for secrets
# 6. Use separate secrets for different environments
# 7. Mount secrets as volumes (not env vars) when possible
# 8. Set appropriate file permissions (0400)

---
# Creating Secrets with kubectl

# From literal values
# kubectl create secret generic {{APP_NAME}}-secrets \
#   --from-literal=DATABASE_URL="{{DATABASE_URL}}" \
#   --from-literal=API_KEY="{{API_KEY}}" \
#   -n {{NAMESPACE}}

# From file
# kubectl create secret generic {{APP_NAME}}-secrets \
#   --from-file=database-url=./database-url.txt \
#   --from-file=api-key=./api-key.txt \
#   -n {{NAMESPACE}}

# From env file
# kubectl create secret generic {{APP_NAME}}-secrets \
#   --from-env-file=.env.secrets \
#   -n {{NAMESPACE}}

# Docker registry secret
# kubectl create secret docker-registry {{REGISTRY_SECRET_NAME}} \
#   --docker-server={{REGISTRY_SERVER}} \
#   --docker-username={{REGISTRY_USERNAME}} \
#   --docker-password={{REGISTRY_PASSWORD}} \
#   -n {{NAMESPACE}}

# TLS secret
# kubectl create secret tls {{APP_NAME}}-tls \
#   --cert=path/to/tls.crt \
#   --key=path/to/tls.key \
#   -n {{NAMESPACE}}

---
# Sealed Secrets (GitOps-friendly)
# Install Sealed Secrets controller first
# https://github.com/bitnami-labs/sealed-secrets

apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: {{APP_NAME}}-sealed
  namespace: {{NAMESPACE}}
spec:
  encryptedData:
    DATABASE_URL: {{SEALED_DATABASE_URL}}
    API_KEY: {{SEALED_API_KEY}}

# Create sealed secret:
# echo -n "secret-value" | kubeseal --raw --from-file=/dev/stdin --namespace={{NAMESPACE}} --name={{APP_NAME}}-sealed

---
# External Secrets Operator
# Install External Secrets Operator first
# https://external-secrets.io/

apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{APP_NAME}}-external
  namespace: {{NAMESPACE}}
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: {{SECRET_STORE_NAME}}
    kind: SecretStore
  target:
    name: {{APP_NAME}}-secrets
    creationPolicy: Owner
  data:
  - secretKey: DATABASE_URL
    remoteRef:
      key: {{REMOTE_SECRET_PATH}}
      property: database_url
  - secretKey: API_KEY
    remoteRef:
      key: {{REMOTE_SECRET_PATH}}
      property: api_key

---
# Variable Reference
# Replace these placeholders with actual values:
#
# {{APP_NAME}}                  - Application name
# {{NAMESPACE}}                 - Kubernetes namespace
# {{ENVIRONMENT}}               - Environment (dev, staging, prod)
# {{DATABASE_URL}}              - Database connection string
# {{API_KEY}}                   - API key
# {{JWT_SECRET}}                - JWT secret key
# {{ENCRYPTION_KEY}}            - Encryption key
# {{REGISTRY_SECRET_NAME}}      - Docker registry secret name
# {{REGISTRY_SERVER}}           - Docker registry server
# {{REGISTRY_USERNAME}}         - Docker registry username
# {{REGISTRY_PASSWORD}}         - Docker registry password
# {{TLS_CERT_BASE64}}           - Base64 encoded TLS certificate
# {{TLS_KEY_BASE64}}            - Base64 encoded TLS key
# {{DB_USER}}                   - Database user
# {{DB_PASSWORD}}               - Database password
# {{DB_HOST}}                   - Database host
# {{DB_PORT}}                   - Database port
# {{DB_NAME}}                   - Database name
