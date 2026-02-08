# Redpanda Cloud Setup Guide

This guide shows how to set up Redpanda Cloud for your Kafka event streaming.

## Why Redpanda Cloud?

- **Free Tier**: Serverless tier available without credit card
- **Kafka Compatible**: Use standard Kafka clients
- **No Zookeeper**: Simpler architecture
- **Fast Setup**: Under 5 minutes
- **Managed Service**: No infrastructure to maintain

## Step 1: Create Account

1. Go to https://redpanda.com/cloud
2. Click "Sign Up" or "Try Free"
3. Create account with email
4. Verify email address

## Step 2: Create Cluster

1. Click "Create Cluster"
2. Choose **Serverless** tier (free)
3. Select region (choose closest to your users)
4. Name your cluster (e.g., "todo-app-prod")
5. Click "Create"

Wait 2-3 minutes for cluster to be ready.

## Step 3: Get Connection Details

1. Click on your cluster name
2. Go to "Overview" tab
3. Copy **Bootstrap Server** address
   - Example: `seed-a1b2c3d4.cloud.redpanda.com:9092`

## Step 4: Create User Credentials

1. Go to "Security" tab
2. Click "Create User"
3. Enter username (e.g., "todo-app-user")
4. Select mechanism: **SCRAM-SHA-256**
5. Click "Create"
6. **IMPORTANT**: Copy the password immediately (shown only once)

## Step 5: Create Topics

1. Go to "Topics" tab
2. Click "Create Topic"
3. Create these topics:

**Topic 1: task-events**
- Name: `task-events`
- Partitions: 3
- Retention: 7 days
- Cleanup policy: delete

**Topic 2: reminders**
- Name: `reminders`
- Partitions: 3
- Retention: 1 day
- Cleanup policy: delete

**Topic 3: notifications**
- Name: `notifications`
- Partitions: 3
- Retention: 3 days
- Cleanup policy: delete

## Step 6: Configure Your Application

### Environment Variables

Create `.env` file:

```bash
# Redpanda Cloud Configuration
KAFKA_BOOTSTRAP_SERVERS=seed-a1b2c3d4.cloud.redpanda.com:9092
KAFKA_USERNAME=todo-app-user
KAFKA_PASSWORD=your-password-here
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=SCRAM-SHA-256
```

### Python Producer Configuration

```python
# app/events/config.py
import os
from kafka import KafkaProducer
import json

def get_kafka_producer():
    """Create Kafka producer with Redpanda Cloud config."""
    return KafkaProducer(
        bootstrap_servers=os.getenv('KAFKA_BOOTSTRAP_SERVERS').split(','),
        security_protocol=os.getenv('KAFKA_SECURITY_PROTOCOL', 'SASL_SSL'),
        sasl_mechanism=os.getenv('KAFKA_SASL_MECHANISM', 'SCRAM-SHA-256'),
        sasl_plain_username=os.getenv('KAFKA_USERNAME'),
        sasl_plain_password=os.getenv('KAFKA_PASSWORD'),
        value_serializer=lambda v: json.dumps(v, default=str).encode('utf-8'),
        acks='all',
        retries=3,
        compression_type='snappy'
    )
```

### Python Consumer Configuration

```python
# services/consumer_config.py
import os
from kafka import KafkaConsumer
import json

def get_kafka_consumer(topics, group_id):
    """Create Kafka consumer with Redpanda Cloud config."""
    return KafkaConsumer(
        *topics,
        bootstrap_servers=os.getenv('KAFKA_BOOTSTRAP_SERVERS').split(','),
        security_protocol=os.getenv('KAFKA_SECURITY_PROTOCOL', 'SASL_SSL'),
        sasl_mechanism=os.getenv('KAFKA_SASL_MECHANISM', 'SCRAM-SHA-256'),
        sasl_plain_username=os.getenv('KAFKA_USERNAME'),
        sasl_plain_password=os.getenv('KAFKA_PASSWORD'),
        group_id=group_id,
        auto_offset_reset='earliest',
        enable_auto_commit=True,
        value_deserializer=lambda m: json.loads(m.decode('utf-8'))
    )
```

## Step 7: Test Connection

### Test Producer

```python
# test_connection.py
from kafka import KafkaProducer
import json
import os
from datetime import datetime

# Load environment variables
from dotenv import load_dotenv
load_dotenv()

# Create producer
producer = KafkaProducer(
    bootstrap_servers=os.getenv('KAFKA_BOOTSTRAP_SERVERS').split(','),
    security_protocol='SASL_SSL',
    sasl_mechanism='SCRAM-SHA-256',
    sasl_plain_username=os.getenv('KAFKA_USERNAME'),
    sasl_plain_password=os.getenv('KAFKA_PASSWORD'),
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# Send test message
test_event = {
    'event_type': 'test',
    'message': 'Hello from Redpanda Cloud!',
    'timestamp': datetime.utcnow().isoformat()
}

future = producer.send('task-events', value=test_event)
record_metadata = future.get(timeout=10)

print(f"✅ Message sent successfully!")
print(f"Topic: {record_metadata.topic}")
print(f"Partition: {record_metadata.partition}")
print(f"Offset: {record_metadata.offset}")

producer.close()
```

Run test:
```bash
pip install kafka-python python-dotenv
python test_connection.py
```

### Test Consumer

```python
# test_consumer.py
from kafka import KafkaConsumer
import json
import os
from dotenv import load_dotenv

load_dotenv()

consumer = KafkaConsumer(
    'task-events',
    bootstrap_servers=os.getenv('KAFKA_BOOTSTRAP_SERVERS').split(','),
    security_protocol='SASL_SSL',
    sasl_mechanism='SCRAM-SHA-256',
    sasl_plain_username=os.getenv('KAFKA_USERNAME'),
    sasl_plain_password=os.getenv('KAFKA_PASSWORD'),
    group_id='test-consumer',
    auto_offset_reset='earliest',
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)

print("Waiting for messages...")
for message in consumer:
    print(f"✅ Received: {message.value}")
    break  # Exit after first message

consumer.close()
```

## Step 8: Monitor in Redpanda Console

1. Go to Redpanda Cloud dashboard
2. Click on your cluster
3. Go to "Topics" tab
4. Click on "task-events" topic
5. View messages, partitions, and consumer groups

## Kubernetes Deployment

### Create Secret

```bash
kubectl create secret generic kafka-config \
  --from-literal=bootstrap-servers=$KAFKA_BOOTSTRAP_SERVERS \
  --from-literal=username=$KAFKA_USERNAME \
  --from-literal=password=$KAFKA_PASSWORD \
  -n todo-app
```

### Update Deployment

```yaml
# k8s/backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  template:
    spec:
      containers:
      - name: backend
        env:
        - name: KAFKA_BOOTSTRAP_SERVERS
          valueFrom:
            secretKeyRef:
              name: kafka-config
              key: bootstrap-servers
        - name: KAFKA_USERNAME
          valueFrom:
            secretKeyRef:
              name: kafka-config
              key: username
        - name: KAFKA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: kafka-config
              key: password
        - name: KAFKA_SECURITY_PROTOCOL
          value: "SASL_SSL"
        - name: KAFKA_SASL_MECHANISM
          value: "SCRAM-SHA-256"
```

## Troubleshooting

### Connection Timeout

**Error**: `KafkaTimeoutError: Failed to update metadata after 60.0 secs`

**Solution**:
1. Check bootstrap server address is correct
2. Verify network connectivity
3. Check firewall rules allow port 9092

### Authentication Failed

**Error**: `AuthenticationFailedError`

**Solution**:
1. Verify username and password are correct
2. Check SASL mechanism is SCRAM-SHA-256
3. Ensure security protocol is SASL_SSL

### Topic Not Found

**Error**: `UnknownTopicOrPartitionError`

**Solution**:
1. Create topic in Redpanda Console
2. Wait 30 seconds for topic to propagate
3. Verify topic name spelling

## Cost Considerations

### Serverless Tier (Free)
- **Ingress**: 10 GB/month free
- **Egress**: 30 GB/month free
- **Storage**: 10 GB free
- **Partitions**: 10 free

### Beyond Free Tier
- Additional ingress: $0.10/GB
- Additional egress: $0.05/GB
- Additional storage: $0.10/GB/month
- Additional partitions: $0.01/partition/hour

**Tip**: Monitor usage in Redpanda Console to stay within free tier.

## Best Practices

1. **Use Compression**: Enable snappy compression to reduce data transfer
2. **Batch Messages**: Send multiple events in batches
3. **Monitor Usage**: Check Redpanda Console regularly
4. **Secure Credentials**: Never commit passwords to git
5. **Use Separate Clusters**: Dev, staging, and prod environments

## Next Steps

1. ✅ Redpanda Cloud cluster created
2. ✅ Topics created
3. ✅ Connection tested
4. → Integrate with FastAPI application
5. → Deploy consumer services
6. → Set up monitoring and alerts

## Resources

- Redpanda Cloud Docs: https://docs.redpanda.com/current/deploy/deployment-option/cloud/
- Python Client Docs: https://kafka-python.readthedocs.io/
- Redpanda Console: https://cloud.redpanda.com/
