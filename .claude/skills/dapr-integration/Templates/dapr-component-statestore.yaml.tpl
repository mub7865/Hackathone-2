# Dapr State Store Component Configuration Template
#
# This template provides state store component configurations for various backends.
# Place this file in: ./components/statestore.yaml (local) or deploy to Kubernetes

# ============================================================================
# Redis State Store (Local Development)
# ============================================================================
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
    value: ""
  - name: enableTLS
    value: "false"
  - name: actorStateStore
    value: "true"  # Enable for actor state storage
  - name: keyPrefix
    value: "myapp"  # Prefix for all keys

---
# ============================================================================
# Redis State Store (Production with TLS)
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
spec:
  type: state.redis
  version: v1
  metadata:
  - name: redisHost
    value: redis.production.svc.cluster.local:6379
  - name: redisPassword
    secretKeyRef:
      name: redis-secret
      key: password
  - name: enableTLS
    value: "true"
  - name: actorStateStore
    value: "true"
  - name: keyPrefix
    value: "prod"
  - name: ttlInSeconds
    value: "3600"  # Default TTL for all keys

---
# ============================================================================
# PostgreSQL State Store
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore-postgres
spec:
  type: state.postgresql
  version: v1
  metadata:
  - name: connectionString
    secretKeyRef:
      name: postgres-secret
      key: connectionString
  - name: tableName
    value: "state"
  - name: metadataTableName
    value: "state_metadata"
  - name: actorStateStore
    value: "true"
  - name: keyPrefix
    value: "myapp"

---
# ============================================================================
# MongoDB State Store
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore-mongodb
spec:
  type: state.mongodb
  version: v1
  metadata:
  - name: host
    value: "mongodb://localhost:27017"
  - name: username
    secretKeyRef:
      name: mongodb-secret
      key: username
  - name: password
    secretKeyRef:
      name: mongodb-secret
      key: password
  - name: databaseName
    value: "myapp"
  - name: collectionName
    value: "state"
  - name: actorStateStore
    value: "true"

---
# ============================================================================
# Azure Cosmos DB State Store
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore-cosmosdb
spec:
  type: state.azure.cosmosdb
  version: v1
  metadata:
  - name: url
    value: "https://myaccount.documents.azure.com:443/"
  - name: masterKey
    secretKeyRef:
      name: cosmosdb-secret
      key: masterKey
  - name: database
    value: "myapp"
  - name: collection
    value: "state"
  - name: actorStateStore
    value: "true"

---
# ============================================================================
# AWS DynamoDB State Store
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore-dynamodb
spec:
  type: state.aws.dynamodb
  version: v1
  metadata:
  - name: region
    value: "us-east-1"
  - name: accessKey
    secretKeyRef:
      name: aws-secret
      key: accessKey
  - name: secretKey
    secretKeyRef:
      name: aws-secret
      key: secretKey
  - name: table
    value: "myapp-state"
  - name: ttlAttributeName
    value: "ttl"

---
# ============================================================================
# GCP Firestore State Store
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore-firestore
spec:
  type: state.gcp.firestore
  version: v1
  metadata:
  - name: type
    value: "service_account"
  - name: project_id
    value: "my-gcp-project"
  - name: private_key_id
    value: "key-id"
  - name: private_key
    secretKeyRef:
      name: gcp-secret
      key: privateKey
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
  - name: entity_kind
    value: "DaprState"

---
# ============================================================================
# Cassandra State Store
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore-cassandra
spec:
  type: state.cassandra
  version: v1
  metadata:
  - name: hosts
    value: "localhost:9042"
  - name: username
    secretKeyRef:
      name: cassandra-secret
      key: username
  - name: password
    secretKeyRef:
      name: cassandra-secret
      key: password
  - name: keyspace
    value: "myapp"
  - name: table
    value: "state"
  - name: consistency
    value: "All"  # or "One", "Quorum", "LocalQuorum"

---
# ============================================================================
# In-Memory State Store (Testing Only)
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore-memory
spec:
  type: state.in-memory
  version: v1
  metadata: []

---
# ============================================================================
# State Store with Transactions Support
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore-transactional
spec:
  type: state.redis
  version: v1
  metadata:
  - name: redisHost
    value: localhost:6379
  - name: redisPassword
    value: ""
  - name: enableTLS
    value: "false"
  - name: actorStateStore
    value: "true"
  - name: keyPrefix
    value: "myapp"
  # Transaction support is automatic for Redis

---
# ============================================================================
# State Store with Encryption
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore-encrypted
spec:
  type: state.redis
  version: v1
  metadata:
  - name: redisHost
    value: localhost:6379
  - name: redisPassword
    secretKeyRef:
      name: redis-secret
      key: password
  - name: enableTLS
    value: "true"
  - name: actorStateStore
    value: "true"
  - name: keyPrefix
    value: "myapp"
# Note: For encryption at rest, configure your backend (Redis, PostgreSQL, etc.)
# Dapr doesn't provide built-in encryption, but you can use encrypted backends

---
# ============================================================================
# Scopes (Limit component to specific apps)
# ============================================================================
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
scopes:
  - app1
  - app2
  # Only app1 and app2 can use this component
