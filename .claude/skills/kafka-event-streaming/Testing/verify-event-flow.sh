#!/bin/bash
# End-to-End Event Flow Verification Script
# This script verifies that events flow correctly from producer to consumer

set -e

echo "🔍 Kafka Event Flow Verification"
echo "================================"
echo ""

# Configuration
KAFKA_BOOTSTRAP_SERVERS="${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}"
TEST_TOPIC="test-event-flow"
TEST_GROUP="test-verification-group"
TEST_EVENT_ID="test-$(date +%s)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Kafka is running
echo "1️⃣  Checking Kafka connectivity..."
if timeout 5 bash -c "echo > /dev/tcp/${KAFKA_BOOTSTRAP_SERVERS%%:*}/${KAFKA_BOOTSTRAP_SERVERS##*:}" 2>/dev/null; then
    echo -e "${GREEN}✅ Kafka is reachable${NC}"
else
    echo -e "${RED}❌ Cannot connect to Kafka at $KAFKA_BOOTSTRAP_SERVERS${NC}"
    exit 1
fi

# Create test topic if it doesn't exist
echo ""
echo "2️⃣  Creating test topic..."
python3 << EOF
from kafka.admin import KafkaAdminClient, NewTopic
from kafka.errors import TopicAlreadyExistsError

admin = KafkaAdminClient(bootstrap_servers='$KAFKA_BOOTSTRAP_SERVERS')
topic = NewTopic(name='$TEST_TOPIC', num_partitions=1, replication_factor=1)

try:
    admin.create_topics([topic])
    print("✅ Topic created: $TEST_TOPIC")
except TopicAlreadyExistsError:
    print("✅ Topic already exists: $TEST_TOPIC")
except Exception as e:
    print(f"❌ Error creating topic: {e}")
    exit(1)
finally:
    admin.close()
EOF

# Publish test event
echo ""
echo "3️⃣  Publishing test event..."
python3 << EOF
from kafka import KafkaProducer
import json
from datetime import datetime

producer = KafkaProducer(
    bootstrap_servers='$KAFKA_BOOTSTRAP_SERVERS',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

test_event = {
    'event_id': '$TEST_EVENT_ID',
    'event_type': 'test',
    'message': 'End-to-end verification test',
    'timestamp': datetime.utcnow().isoformat()
}

try:
    future = producer.send('$TEST_TOPIC', value=test_event)
    record_metadata = future.get(timeout=10)
    print(f"✅ Event published to partition {record_metadata.partition} at offset {record_metadata.offset}")
except Exception as e:
    print(f"❌ Failed to publish event: {e}")
    exit(1)
finally:
    producer.close()
EOF

# Wait for event to be available
echo ""
echo "4️⃣  Waiting for event to be available..."
sleep 2

# Consume and verify event
echo ""
echo "5️⃣  Consuming and verifying event..."
python3 << EOF
from kafka import KafkaConsumer
import json
import sys

consumer = KafkaConsumer(
    '$TEST_TOPIC',
    bootstrap_servers='$KAFKA_BOOTSTRAP_SERVERS',
    auto_offset_reset='earliest',
    group_id='$TEST_GROUP',
    value_deserializer=lambda m: json.loads(m.decode('utf-8')),
    consumer_timeout_ms=10000
)

event_found = False
try:
    for message in consumer:
        event = message.value
        if event.get('event_id') == '$TEST_EVENT_ID':
            print(f"✅ Event received successfully!")
            print(f"   Topic: {message.topic}")
            print(f"   Partition: {message.partition}")
            print(f"   Offset: {message.offset}")
            print(f"   Event ID: {event['event_id']}")
            print(f"   Message: {event['message']}")
            event_found = True
            break
except Exception as e:
    print(f"❌ Error consuming event: {e}")
    sys.exit(1)
finally:
    consumer.close()

if not event_found:
    print("❌ Test event not found")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Event flow verification PASSED${NC}"
    echo ""
    echo "Summary:"
    echo "  ✅ Kafka connectivity"
    echo "  ✅ Topic creation"
    echo "  ✅ Event publishing"
    echo "  ✅ Event consumption"
    echo ""
    echo "Your Kafka event streaming is working correctly! 🎉"
else
    echo ""
    echo -e "${RED}❌ Event flow verification FAILED${NC}"
    exit 1
fi

# Cleanup (optional)
read -p "Delete test topic? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    python3 << EOF
from kafka.admin import KafkaAdminClient

admin = KafkaAdminClient(bootstrap_servers='$KAFKA_BOOTSTRAP_SERVERS')
try:
    admin.delete_topics(['$TEST_TOPIC'])
    print("✅ Test topic deleted")
except Exception as e:
    print(f"⚠️  Could not delete topic: {e}")
finally:
    admin.close()
EOF
fi

echo ""
echo "Verification complete!"
