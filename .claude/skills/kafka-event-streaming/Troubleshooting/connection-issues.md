# Kafka Connection Issues Troubleshooting

This guide helps diagnose and fix connection problems with Kafka/Redpanda.

## Quick Diagnosis Checklist

Run through these checks in order:

```bash
# 1. Check if Kafka is running
docker ps | grep -E "kafka|redpanda"

# 2. Test port connectivity
nc -zv localhost 9092

# 3. Check Kafka logs
docker logs kafka-container-name --tail 50

# 4. Verify network
ping localhost

# 5. Check firewall
sudo ufw status
```

---

## Issue 1: Cannot Connect to localhost:9092

### Symptoms
```
KafkaTimeoutError: Failed to update metadata after 60.0 secs
```

### Diagnosis Steps

**Step 1: Verify Kafka is Running**
```bash
# Check Docker containers
docker ps

# Expected output should show Kafka/Redpanda container
# If not running, start it:
docker start kafka-container-name
```

**Step 2: Check Port Binding**
```bash
# Check if port 9092 is listening
sudo netstat -tulpn | grep 9092

# Or use lsof
sudo lsof -i :9092

# Expected output:
# LISTEN on 0.0.0.0:9092 or 127.0.0.1:9092
```

**Step 3: Test Connection**
```bash
# Using telnet
telnet localhost 9092

# Using nc (netcat)
nc -zv localhost 9092

# Expected: Connection succeeded
```

### Solutions

**Solution 1: Start Kafka**
```bash
# Docker
docker start kafka-container-name

# Docker Compose
docker-compose up -d kafka

# Kubernetes
kubectl scale deployment kafka --replicas=1 -n todo-app
```

**Solution 2: Fix Port Mapping**
```yaml
# docker-compose.yml
services:
  kafka:
    ports:
      - "9092:9092"  # Ensure this is present
```

**Solution 3: Check Advertised Listeners**
```bash
# For Docker Kafka
docker exec kafka-container kafka-configs.sh \
  --bootstrap-server localhost:9092 \
  --describe --entity-type brokers --entity-name 0

# Should show advertised.listeners including localhost:9092
```

---

## Issue 2: Connection Works Locally but Not from Docker Container

### Symptoms
```python
# Works from host
producer = KafkaProducer(bootstrap_servers=['localhost:9092'])  # ✅

# Fails from Docker container
producer = KafkaProducer(bootstrap_servers=['localhost:9092'])  # ❌
```

### Diagnosis
```bash
# From inside container
docker exec -it your-app-container bash
nc -zv localhost 9092  # Will fail

# From host
nc -zv localhost 9092  # Works
```

### Solutions

**Solution 1: Use Docker Network**
```yaml
# docker-compose.yml
services:
  kafka:
    container_name: kafka
    networks:
      - app-network

  your-app:
    environment:
      - KAFKA_BOOTSTRAP_SERVERS=kafka:9092  # Use container name
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

**Solution 2: Use Host Network (Linux only)**
```yaml
# docker-compose.yml
services:
  your-app:
    network_mode: "host"
    environment:
      - KAFKA_BOOTSTRAP_SERVERS=localhost:9092
```

**Solution 3: Use Host IP**
```bash
# Get host IP
ip addr show docker0 | grep inet

# Use in container
export KAFKA_BOOTSTRAP_SERVERS=172.17.0.1:9092
```

---

## Issue 3: Connection Works but Metadata Update Fails

### Symptoms
```
KafkaTimeoutError: Failed to update metadata after 60.0 secs
```
But initial connection succeeds.

### Diagnosis
```python
# Enable debug logging
import logging
logging.basicConfig(level=logging.DEBUG)

# Try to create producer
producer = KafkaProducer(bootstrap_servers=['localhost:9092'])
# Check logs for "Metadata update failed"
```

### Solutions

**Solution 1: Fix Advertised Listeners**
```bash
# For Redpanda
docker run -d \
  -p 9092:9092 \
  docker.redpanda.com/redpandadata/redpanda:latest \
  redpanda start \
  --kafka-addr PLAINTEXT://0.0.0.0:29092,OUTSIDE://0.0.0.0:9092 \
  --advertise-kafka-addr PLAINTEXT://redpanda:29092,OUTSIDE://localhost:9092
```

**Solution 2: Increase Timeout**
```python
producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    request_timeout_ms=120000,  # 2 minutes
    metadata_max_age_ms=300000  # 5 minutes
)
```

---

## Issue 4: SSL/TLS Connection Failures

### Symptoms
```
SSLError: [SSL: CERTIFICATE_VERIFY_FAILED]
```

### Diagnosis
```python
# Test SSL connection
import ssl
import socket

context = ssl.create_default_context()
with socket.create_connection(('seed-xxx.cloud.redpanda.com', 9092)) as sock:
    with context.wrap_socket(sock, server_hostname='seed-xxx.cloud.redpanda.com') as ssock:
        print(ssock.version())
```

### Solutions

**Solution 1: Update CA Certificates**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install --reinstall ca-certificates

# macOS
brew install ca-certificates

# Python
pip install --upgrade certifi
```

**Solution 2: Provide CA Certificate**
```python
producer = KafkaProducer(
    bootstrap_servers=['seed-xxx.cloud.redpanda.com:9092'],
    security_protocol='SASL_SSL',
    ssl_cafile='/etc/ssl/certs/ca-certificates.crt'
)
```

**Solution 3: Disable Verification (Development Only)**
```python
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

---

## Issue 5: Kubernetes Pod Cannot Connect to Kafka

### Symptoms
```bash
kubectl logs backend-pod -n todo-app
# Shows: KafkaTimeoutError
```

### Diagnosis
```bash
# Test from pod
kubectl exec -it backend-pod -n todo-app -- bash
nc -zv kafka-service 9092

# Check service
kubectl get svc -n todo-app
kubectl describe svc kafka-service -n todo-app
```

### Solutions

**Solution 1: Use Correct Service Name**
```yaml
# deployment.yaml
env:
  - name: KAFKA_BOOTSTRAP_SERVERS
    value: "kafka-service.todo-app.svc.cluster.local:9092"
```

**Solution 2: Check Service Selector**
```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: kafka-service
spec:
  selector:
    app: kafka  # Must match pod labels
  ports:
    - port: 9092
      targetPort: 9092
```

**Solution 3: Verify Network Policy**
```bash
# Check if network policies are blocking
kubectl get networkpolicies -n todo-app

# If blocking, create policy to allow
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-kafka
  namespace: todo-app
spec:
  podSelector:
    matchLabels:
      app: backend
  egress:
    - to:
      - podSelector:
          matchLabels:
            app: kafka
      ports:
        - protocol: TCP
          port: 9092
EOF
```

---

## Issue 6: Redpanda Cloud Connection Fails

### Symptoms
```
AuthenticationFailedError
```

### Diagnosis
```bash
# Test with rpk CLI
rpk topic list \
  --brokers seed-xxx.cloud.redpanda.com:9092 \
  --user your-username \
  --password your-password \
  --tls-enabled

# Check credentials
echo $KAFKA_USERNAME
echo $KAFKA_PASSWORD
```

### Solutions

**Solution 1: Verify Credentials**
```python
import os

# Check environment variables
print(f"Bootstrap: {os.getenv('KAFKA_BOOTSTRAP_SERVERS')}")
print(f"Username: {os.getenv('KAFKA_USERNAME')}")
# Don't print password in production!

# Ensure they match Redpanda Console
```

**Solution 2: Use Correct SASL Mechanism**
```python
producer = KafkaProducer(
    bootstrap_servers=['seed-xxx.cloud.redpanda.com:9092'],
    security_protocol='SASL_SSL',
    sasl_mechanism='SCRAM-SHA-256',  # Must be SCRAM-SHA-256
    sasl_plain_username=os.getenv('KAFKA_USERNAME'),
    sasl_plain_password=os.getenv('KAFKA_PASSWORD')
)
```

---

## Diagnostic Script

Save this as `diagnose_kafka.py`:

```python
#!/usr/bin/env python3
"""Kafka Connection Diagnostic Tool"""

import socket
import sys
from kafka import KafkaProducer, KafkaConsumer
from kafka.errors import KafkaError

def test_port(host, port):
    """Test if port is reachable."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except Exception as e:
        print(f"❌ Port test failed: {e}")
        return False

def test_producer(bootstrap_servers):
    """Test Kafka producer connection."""
    try:
        producer = KafkaProducer(
            bootstrap_servers=bootstrap_servers,
            request_timeout_ms=10000
        )
        producer.close()
        return True
    except KafkaError as e:
        print(f"❌ Producer test failed: {e}")
        return False

def test_consumer(bootstrap_servers):
    """Test Kafka consumer connection."""
    try:
        consumer = KafkaConsumer(
            bootstrap_servers=bootstrap_servers,
            request_timeout_ms=10000
        )
        consumer.close()
        return True
    except KafkaError as e:
        print(f"❌ Consumer test failed: {e}")
        return False

def main():
    bootstrap_servers = sys.argv[1] if len(sys.argv) > 1 else 'localhost:9092'
    host, port = bootstrap_servers.split(':')
    port = int(port)

    print(f"🔍 Diagnosing Kafka connection to {bootstrap_servers}")
    print("=" * 60)

    # Test 1: Port connectivity
    print("\n1️⃣  Testing port connectivity...")
    if test_port(host, port):
        print(f"✅ Port {port} is reachable")
    else:
        print(f"❌ Cannot reach port {port}")
        print("   → Check if Kafka is running")
        print("   → Check firewall rules")
        return 1

    # Test 2: Producer connection
    print("\n2️⃣  Testing producer connection...")
    if test_producer([bootstrap_servers]):
        print("✅ Producer connection successful")
    else:
        print("❌ Producer connection failed")
        print("   → Check advertised listeners")
        print("   → Check authentication settings")
        return 1

    # Test 3: Consumer connection
    print("\n3️⃣  Testing consumer connection...")
    if test_consumer([bootstrap_servers]):
        print("✅ Consumer connection successful")
    else:
        print("❌ Consumer connection failed")
        return 1

    print("\n" + "=" * 60)
    print("✅ All connection tests passed!")
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

Run it:
```bash
python diagnose_kafka.py localhost:9092
```

---

## Prevention Tips

1. **Use Health Checks**
   ```python
   def check_kafka_health():
       try:
           producer = KafkaProducer(
               bootstrap_servers=['localhost:9092'],
               request_timeout_ms=5000
           )
           producer.close()
           return True
       except:
           return False
   ```

2. **Monitor Connections**
   ```python
   from prometheus_client import Gauge

   kafka_connection_status = Gauge(
       'kafka_connection_status',
       'Kafka connection status (1=connected, 0=disconnected)'
   )
   ```

3. **Use Connection Pooling**
   ```python
   # Reuse producer instance
   _producer = None

   def get_producer():
       global _producer
       if _producer is None:
           _producer = KafkaProducer(...)
       return _producer
   ```

4. **Implement Retry Logic**
   ```python
   from tenacity import retry, stop_after_attempt, wait_exponential

   @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
   def connect_to_kafka():
       return KafkaProducer(bootstrap_servers=['localhost:9092'])
   ```

---

## Getting More Help

If still stuck:
1. Enable DEBUG logging
2. Check Kafka broker logs
3. Use diagnostic script above
4. Search GitHub issues: https://github.com/dpkp/kafka-python/issues
5. Ask on Stack Overflow with tag `apache-kafka`
