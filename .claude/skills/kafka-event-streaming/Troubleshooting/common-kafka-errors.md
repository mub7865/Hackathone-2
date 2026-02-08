# Common Kafka Errors and Solutions

This guide covers common errors you might encounter when working with Kafka and how to fix them.

## Connection Errors

### Error: `KafkaTimeoutError: Failed to update metadata after 60.0 secs`

**Cause**: Cannot connect to Kafka broker

**Solutions**:
1. Verify Kafka is running:
   ```bash
   # For local Kafka
   docker ps | grep kafka

   # For Redpanda
   docker ps | grep redpanda
   ```

2. Check bootstrap servers address:
   ```python
   # Correct
   bootstrap_servers=['localhost:9092']

   # Wrong
   bootstrap_servers=['localhost:9093']  # Wrong port
   ```

3. Test connectivity:
   ```bash
   telnet localhost 9092
   # or
   nc -zv localhost 9092
   ```

4. Check firewall rules:
   ```bash
   # Linux
   sudo ufw status

   # Check if port 9092 is open
   sudo netstat -tulpn | grep 9092
   ```

---

### Error: `NoBrokersAvailable: NoBrokersAvailable`

**Cause**: No Kafka brokers are reachable

**Solutions**:
1. Verify Kafka service is running:
   ```bash
   # Docker
   docker logs kafka-container-name

   # Kubernetes
   kubectl logs -n todo-app kafka-pod-name
   ```

2. Check broker configuration:
   ```bash
   # Verify advertised listeners
   docker exec kafka-container kafka-configs.sh \
     --bootstrap-server localhost:9092 \
     --describe --entity-type brokers --entity-name 0
   ```

3. Restart Kafka:
   ```bash
   # Docker
   docker restart kafka-container-name

   # Kubernetes
   kubectl rollout restart deployment/kafka -n todo-app
   ```

---

## Authentication Errors

### Error: `AuthenticationFailedError`

**Cause**: Invalid credentials or wrong authentication mechanism

**Solutions**:
1. Verify credentials:
   ```python
   # Check environment variables
   import os
   print(os.getenv('KAFKA_USERNAME'))
   print(os.getenv('KAFKA_PASSWORD'))  # Don't log in production!
   ```

2. Verify SASL mechanism:
   ```python
   # For Redpanda Cloud
   sasl_mechanism='SCRAM-SHA-256'  # Correct

   # Wrong
   sasl_mechanism='PLAIN'  # Wrong mechanism
   ```

3. Check security protocol:
   ```python
   # For Redpanda Cloud
   security_protocol='SASL_SSL'  # Correct

   # Wrong
   security_protocol='PLAINTEXT'  # Wrong protocol
   ```

4. Test with rpk (Redpanda CLI):
   ```bash
   rpk topic list \
     --brokers seed-xxx.cloud.redpanda.com:9092 \
     --user your-username \
     --password your-password \
     --tls-enabled
   ```

---

### Error: `SSLError: [SSL: CERTIFICATE_VERIFY_FAILED]`

**Cause**: SSL certificate verification failed

**Solutions**:
1. Update CA certificates:
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install ca-certificates

   # macOS
   brew install ca-certificates
   ```

2. Disable SSL verification (NOT recommended for production):
   ```python
   from kafka import KafkaProducer
   import ssl

   context = ssl.create_default_context()
   context.check_hostname = False
   context.verify_mode = ssl.CERT_NONE

   producer = KafkaProducer(
       bootstrap_servers=['...'],
       security_protocol='SASL_SSL',
       ssl_context=context
   )
   ```

3. Provide CA certificate:
   ```python
   producer = KafkaProducer(
       bootstrap_servers=['...'],
       security_protocol='SASL_SSL',
       ssl_cafile='/path/to/ca-cert.pem'
   )
   ```

---

## Topic Errors

### Error: `UnknownTopicOrPartitionError`

**Cause**: Topic doesn't exist

**Solutions**:
1. Create topic:
   ```python
   from kafka.admin import KafkaAdminClient, NewTopic

   admin = KafkaAdminClient(bootstrap_servers=['localhost:9092'])
   topic = NewTopic(name='my-topic', num_partitions=3, replication_factor=1)
   admin.create_topics([topic])
   admin.close()
   ```

2. List existing topics:
   ```bash
   # Using rpk
   rpk topic list

   # Using kafka-topics.sh
   kafka-topics.sh --list --bootstrap-server localhost:9092
   ```

3. Enable auto-create topics (not recommended for production):
   ```properties
   # server.properties
   auto.create.topics.enable=true
   ```

---

### Error: `TopicAuthorizationFailedError`

**Cause**: User doesn't have permission to access topic

**Solutions**:
1. Check ACLs:
   ```bash
   kafka-acls.sh --list \
     --bootstrap-server localhost:9092 \
     --topic my-topic
   ```

2. Grant permissions:
   ```bash
   kafka-acls.sh --add \
     --allow-principal User:my-user \
     --operation All \
     --topic my-topic \
     --bootstrap-server localhost:9092
   ```

3. For Redpanda Cloud, check user permissions in console

---

## Producer Errors

### Error: `MessageSizeTooLargeError`

**Cause**: Message exceeds max size limit

**Solutions**:
1. Check message size:
   ```python
   import json
   message_size = len(json.dumps(event_data).encode('utf-8'))
   print(f"Message size: {message_size} bytes")
   ```

2. Increase max message size:
   ```python
   producer = KafkaProducer(
       bootstrap_servers=['localhost:9092'],
       max_request_size=10485760  # 10MB
   )
   ```

3. Split large messages into smaller chunks

4. Use compression:
   ```python
   producer = KafkaProducer(
       bootstrap_servers=['localhost:9092'],
       compression_type='snappy'  # or 'gzip', 'lz4', 'zstd'
   )
   ```

---

### Error: `BufferError: Local: Queue full`

**Cause**: Producer buffer is full

**Solutions**:
1. Increase buffer memory:
   ```python
   producer = KafkaProducer(
       bootstrap_servers=['localhost:9092'],
       buffer_memory=67108864  # 64MB (default is 32MB)
   )
   ```

2. Call flush more frequently:
   ```python
   producer.send('topic', value=data)
   producer.flush()  # Force send immediately
   ```

3. Reduce batch size:
   ```python
   producer = KafkaProducer(
       bootstrap_servers=['localhost:9092'],
       batch_size=8192  # Smaller batches
   )
   ```

---

## Consumer Errors

### Error: `OffsetOutOfRangeError`

**Cause**: Requested offset doesn't exist

**Solutions**:
1. Reset offset to earliest:
   ```python
   consumer = KafkaConsumer(
       'my-topic',
       bootstrap_servers=['localhost:9092'],
       auto_offset_reset='earliest'  # Start from beginning
   )
   ```

2. Reset offset to latest:
   ```python
   consumer = KafkaConsumer(
       'my-topic',
       bootstrap_servers=['localhost:9092'],
       auto_offset_reset='latest'  # Start from end
   )
   ```

3. Manually reset offset:
   ```bash
   kafka-consumer-groups.sh --reset-offsets \
     --group my-group \
     --topic my-topic \
     --to-earliest \
     --execute \
     --bootstrap-server localhost:9092
   ```

---

### Error: `CommitFailedError: Commit cannot be completed`

**Cause**: Consumer group rebalance or session timeout

**Solutions**:
1. Increase session timeout:
   ```python
   consumer = KafkaConsumer(
       'my-topic',
       bootstrap_servers=['localhost:9092'],
       session_timeout_ms=30000,  # 30 seconds
       heartbeat_interval_ms=3000  # 3 seconds
   )
   ```

2. Process messages faster:
   ```python
   # Bad - slow processing
   for message in consumer:
       time.sleep(10)  # Too slow!
       process(message)

   # Good - fast processing
   for message in consumer:
       process(message)  # Quick processing
   ```

3. Disable auto-commit and commit manually:
   ```python
   consumer = KafkaConsumer(
       'my-topic',
       bootstrap_servers=['localhost:9092'],
       enable_auto_commit=False
   )

   for message in consumer:
       process(message)
       consumer.commit()  # Manual commit
   ```

---

## Serialization Errors

### Error: `SerializationError: Can't serialize value`

**Cause**: Value cannot be serialized to bytes

**Solutions**:
1. Use proper serializer:
   ```python
   import json
   from datetime import datetime

   # Custom serializer for datetime
   def json_serializer(obj):
       if isinstance(obj, datetime):
           return obj.isoformat()
       raise TypeError(f"Type {type(obj)} not serializable")

   producer = KafkaProducer(
       bootstrap_servers=['localhost:9092'],
       value_serializer=lambda v: json.dumps(v, default=json_serializer).encode('utf-8')
   )
   ```

2. Convert data before sending:
   ```python
   # Convert datetime to string
   event_data['timestamp'] = event_data['timestamp'].isoformat()
   producer.send('topic', value=event_data)
   ```

---

## Performance Issues

### Issue: Slow message publishing

**Solutions**:
1. Enable batching:
   ```python
   producer = KafkaProducer(
       bootstrap_servers=['localhost:9092'],
       linger_ms=10,  # Wait 10ms to batch messages
       batch_size=16384  # 16KB batches
   )
   ```

2. Use async sending:
   ```python
   # Don't wait for confirmation
   producer.send('topic', value=data)
   # Continue without blocking
   ```

3. Enable compression:
   ```python
   producer = KafkaProducer(
       bootstrap_servers=['localhost:9092'],
       compression_type='snappy'
   )
   ```

---

### Issue: Consumer lag increasing

**Solutions**:
1. Scale consumers horizontally:
   ```bash
   # Run multiple consumer instances with same group_id
   # Each will process different partitions
   ```

2. Increase partitions:
   ```bash
   kafka-topics.sh --alter \
     --topic my-topic \
     --partitions 6 \
     --bootstrap-server localhost:9092
   ```

3. Optimize processing:
   ```python
   # Bad - processing one by one
   for message in consumer:
       process(message)

   # Good - batch processing
   batch = []
   for message in consumer:
       batch.append(message)
       if len(batch) >= 100:
           process_batch(batch)
           batch = []
   ```

---

## Debugging Tips

### Enable Debug Logging

```python
import logging

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('kafka')
logger.setLevel(logging.DEBUG)
```

### Check Kafka Logs

```bash
# Docker
docker logs kafka-container-name

# Kubernetes
kubectl logs -n todo-app kafka-pod-name

# Local Kafka
tail -f /var/log/kafka/server.log
```

### Monitor Consumer Lag

```bash
kafka-consumer-groups.sh --describe \
  --group my-group \
  --bootstrap-server localhost:9092
```

### Test with CLI Tools

```bash
# Produce test message
echo "test message" | kafka-console-producer.sh \
  --broker-list localhost:9092 \
  --topic my-topic

# Consume messages
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic my-topic \
  --from-beginning
```

---

## Getting Help

If you're still stuck:

1. Check Kafka logs for detailed error messages
2. Search Kafka documentation: https://kafka.apache.org/documentation/
3. Check kafka-python issues: https://github.com/dpkp/kafka-python/issues
4. For Redpanda: https://docs.redpanda.com/
5. Stack Overflow: Tag your question with `apache-kafka` and `python`
