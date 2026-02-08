# Redpanda Cloud Configuration

# Connection Configuration
bootstrap_servers:
  - "seed-12345.cloud.redpanda.com:9092"

# Authentication (SASL/SCRAM)
security_protocol: "SASL_SSL"
sasl_mechanism: "SCRAM-SHA-256"
sasl_username: "your-username"
sasl_password: "your-password"

# SSL Configuration
ssl_ca_location: "/path/to/ca-cert.pem"  # Optional, for custom CA

# Producer Configuration
producer:
  acks: "all"  # Wait for all replicas
  retries: 3
  max_in_flight_requests_per_connection: 5
  compression_type: "snappy"  # Options: none, gzip, snappy, lz4, zstd
  batch_size: 16384  # Bytes
  linger_ms: 10  # Wait time before sending batch
  buffer_memory: 33554432  # 32MB

# Consumer Configuration
consumer:
  group_id: "my-consumer-group"
  auto_offset_reset: "earliest"  # Options: earliest, latest, none
  enable_auto_commit: true
  auto_commit_interval_ms: 5000
  max_poll_records: 500
  session_timeout_ms: 30000
  heartbeat_interval_ms: 3000

# Topic Configuration
topics:
  task-events:
    partitions: 3
    replication_factor: 3
    retention_ms: 604800000  # 7 days
    cleanup_policy: "delete"  # Options: delete, compact

  reminders:
    partitions: 3
    replication_factor: 3
    retention_ms: 86400000  # 1 day
    cleanup_policy: "delete"

  notifications:
    partitions: 3
    replication_factor: 3
    retention_ms: 259200000  # 3 days
    cleanup_policy: "delete"

# Python Client Configuration Example
python_config:
  producer:
    bootstrap_servers: ["seed-12345.cloud.redpanda.com:9092"]
    security_protocol: "SASL_SSL"
    sasl_mechanism: "SCRAM-SHA-256"
    sasl_plain_username: "your-username"
    sasl_plain_password: "your-password"
    acks: "all"
    retries: 3
    compression_type: "snappy"

  consumer:
    bootstrap_servers: ["seed-12345.cloud.redpanda.com:9092"]
    security_protocol: "SASL_SSL"
    sasl_mechanism: "SCRAM-SHA-256"
    sasl_plain_username: "your-username"
    sasl_plain_password: "your-password"
    group_id: "my-consumer-group"
    auto_offset_reset: "earliest"
    enable_auto_commit: true

# Environment Variables (Recommended)
# Set these in your .env file:
# REDPANDA_BOOTSTRAP_SERVERS=seed-12345.cloud.redpanda.com:9092
# REDPANDA_USERNAME=your-username
# REDPANDA_PASSWORD=your-password
# REDPANDA_SECURITY_PROTOCOL=SASL_SSL
# REDPANDA_SASL_MECHANISM=SCRAM-SHA-256

# Local Development (Docker)
local_docker:
  image: "docker.redpanda.com/redpandadata/redpanda:latest"
  ports:
    - "9092:9092"  # Kafka API
    - "8081:8081"  # Schema Registry
    - "8082:8082"  # HTTP Proxy
  command: |
    redpanda start
    --smp 1
    --memory 1G
    --reserve-memory 0M
    --overprovisioned
    --node-id 0
    --check=false
    --kafka-addr PLAINTEXT://0.0.0.0:29092,OUTSIDE://0.0.0.0:9092
    --advertise-kafka-addr PLAINTEXT://redpanda:29092,OUTSIDE://localhost:9092

# Monitoring
monitoring:
  metrics_port: 9644
  admin_api_port: 9644
  prometheus_enabled: true
