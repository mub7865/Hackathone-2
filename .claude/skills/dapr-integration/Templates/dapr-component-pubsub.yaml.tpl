# Dapr Pub/Sub Component Configuration Template
#
# This template provides pub/sub component configurations for various backends.
# Place this file in: ./components/pubsub.yaml (local) or deploy to Kubernetes

# ============================================================================
# Redis Pub/Sub (Local Development)
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub
spec:
  type: pubsub.redis
  version: v1
  metadata:
  - name: redisHost
    value: localhost:6379
  - name: redisPassword
    value: ""
  - name: enableTLS
    value: "false"
  - name: consumerID
    value: "{podName}"  # Unique consumer ID per pod
  - name: redeliverInterval
    value: "60s"  # Retry interval for failed messages
  - name: processingTimeout
    value: "60s"  # Message processing timeout
  - name: queueDepth
    value: "100"  # Max messages in processing queue
  - name: concurrency
    value: "10"  # Parallel message processing

---
# ============================================================================
# Redis Pub/Sub (Production with TLS)
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub
spec:
  type: pubsub.redis
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
  - name: consumerID
    value: "{podName}"
  - name: redeliverInterval
    value: "30s"
  - name: processingTimeout
    value: "120s"
  - name: queueDepth
    value: "1000"
  - name: concurrency
    value: "50"

---
# ============================================================================
# Kafka/Redpanda Pub/Sub
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub-kafka
spec:
  type: pubsub.kafka
  version: v1
  metadata:
  - name: brokers
    value: "localhost:9092"
  - name: authType
    value: "none"  # or "password", "certificate"
  - name: consumerGroup
    value: "myapp-group"
  - name: clientID
    value: "myapp"
  - name: maxMessageBytes
    value: "1048576"  # 1MB
  - name: version
    value: "2.8.0"

---
# ============================================================================
# Kafka with SASL/SSL (Redpanda Cloud)
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub-kafka-cloud
spec:
  type: pubsub.kafka
  version: v1
  metadata:
  - name: brokers
    value: "seed-xxx.cloud.redpanda.com:9092"
  - name: authType
    value: "password"
  - name: saslUsername
    secretKeyRef:
      name: kafka-secret
      key: username
  - name: saslPassword
    secretKeyRef:
      name: kafka-secret
      key: password
  - name: saslMechanism
    value: "SCRAM-SHA-256"
  - name: enableTLS
    value: "true"
  - name: consumerGroup
    value: "myapp-group"
  - name: clientID
    value: "myapp"

---
# ============================================================================
# RabbitMQ Pub/Sub
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub-rabbitmq
spec:
  type: pubsub.rabbitmq
  version: v1
  metadata:
  - name: host
    value: "amqp://localhost:5672"
  - name: consumerID
    value: "{podName}"
  - name: durable
    value: "true"
  - name: deletedWhenUnused
    value: "false"
  - name: autoAck
    value: "false"
  - name: deliveryMode
    value: "2"  # Persistent
  - name: requeueInFailure
    value: "true"
  - name: prefetchCount
    value: "10"
  - name: reconnectWait
    value: "3s"
  - name: concurrency
    value: "10"

---
# ============================================================================
# Azure Service Bus Pub/Sub
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub-servicebus
spec:
  type: pubsub.azure.servicebus
  version: v1
  metadata:
  - name: connectionString
    secretKeyRef:
      name: servicebus-secret
      key: connectionString
  - name: consumerID
    value: "{podName}"
  - name: timeoutInSec
    value: "60"
  - name: maxDeliveryCount
    value: "10"
  - name: lockDurationInSec
    value: "60"
  - name: maxConcurrentHandlers
    value: "10"

---
# ============================================================================
# AWS SNS/SQS Pub/Sub
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub-aws
spec:
  type: pubsub.aws.snssqs
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
  - name: sessionToken
    value: ""
  - name: messageVisibilityTimeout
    value: "60"
  - name: messageRetryLimit
    value: "10"
  - name: messageWaitTimeSeconds
    value: "1"
  - name: messageMaxNumber
    value: "10"

---
# ============================================================================
# GCP Pub/Sub
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub-gcp
spec:
  type: pubsub.gcp.pubsub
  version: v1
  metadata:
  - name: projectId
    value: "my-gcp-project"
  - name: authProviderX509CertUrl
    value: "https://www.googleapis.com/oauth2/v1/certs"
  - name: authUri
    value: "https://accounts.google.com/o/oauth2/auth"
  - name: clientX509CertUrl
    value: "https://www.googleapis.com/robot/v1/metadata/x509/..."
  - name: clientEmail
    value: "my-service-account@my-project.iam.gserviceaccount.com"
  - name: clientId
    value: "1234567890"
  - name: privateKey
    secretKeyRef:
      name: gcp-secret
      key: privateKey
  - name: privateKeyId
    value: "key-id"
  - name: type
    value: "service_account"
  - name: consumerID
    value: "{podName}"

---
# ============================================================================
# In-Memory Pub/Sub (Testing Only)
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub-memory
spec:
  type: pubsub.in-memory
  version: v1
  metadata: []

---
# ============================================================================
# Scopes (Limit component to specific apps)
# ============================================================================
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: pubsub
spec:
  type: pubsub.redis
  version: v1
  metadata:
  - name: redisHost
    value: localhost:6379
scopes:
  - app1
  - app2
  # Only app1 and app2 can use this component
