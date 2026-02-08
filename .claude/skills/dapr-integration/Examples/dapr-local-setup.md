# Dapr Local Development Setup

This guide walks you through setting up Dapr for local development on your machine.

## Prerequisites

- Docker Desktop installed and running
- Python 3.8+ installed
- Terminal/Command Prompt access

## Step 1: Install Dapr CLI

### Linux/macOS

```bash
wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash
```

### Windows (PowerShell as Administrator)

```powershell
powershell -Command "iwr -useb https://raw.githubusercontent.com/dapr/cli/master/install/install.ps1 | iex"
```

### Verify Installation

```bash
dapr --version
# Expected output: CLI version: 1.12.0
```

## Step 2: Initialize Dapr

This installs the Dapr runtime, Redis (for state/pub-sub), Zipkin (for tracing), and Placement service (for actors).

```bash
dapr init
```

**Expected Output:**
```
⌛  Making the jump to hyperspace...
✅  Downloading binaries and setting up components...
✅  Downloaded binaries and completed components set up.
ℹ️  daprd binary has been installed to ~/.dapr/bin.
ℹ️  dapr_placement container is running.
ℹ️  dapr_redis container is running.
ℹ️  dapr_zipkin container is running.
ℹ️  Use `docker ps` to check running containers.
```

### Verify Dapr Installation

```bash
# Check Dapr version
dapr --version

# Check running containers
docker ps

# Expected containers:
# - dapr_redis
# - dapr_zipkin
# - dapr_placement
```

## Step 3: Create Project Structure

```bash
mkdir my-dapr-app
cd my-dapr-app

# Create directories
mkdir -p components
mkdir -p app

# Create Python virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install fastapi uvicorn dapr dapr-ext-fastapi
```

## Step 4: Create Dapr Components

### Pub/Sub Component

**components/pubsub.yaml**
```yaml
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
```

### State Store Component

**components/statestore.yaml**
```yaml
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
  - name: actorStateStore
    value: "true"
```

## Step 5: Create a Simple FastAPI App

**app/main.py**
```python
from fastapi import FastAPI
from dapr.ext.fastapi import DaprApp
from dapr.clients import DaprClient
import json

app = FastAPI()
dapr_app = DaprApp(app)

@app.get("/")
async def root():
    return {"message": "Hello from Dapr!"}

@app.post("/publish")
async def publish_message(message: dict):
    """Publish a message to pub/sub."""
    with DaprClient() as client:
        client.publish_event(
            pubsub_name='pubsub',
            topic_name='messages',
            data=json.dumps(message)
        )
    return {"status": "published"}

@dapr_app.subscribe(pubsub='pubsub', topic='messages')
async def message_subscriber(event_data: dict):
    """Subscribe to messages."""
    print(f"Received message: {event_data}")
    return {"status": "SUCCESS"}

@app.post("/state")
async def save_state(key: str, value: str):
    """Save state."""
    with DaprClient() as client:
        client.save_state(
            store_name='statestore',
            key=key,
            value=value
        )
    return {"status": "saved"}

@app.get("/state/{key}")
async def get_state(key: str):
    """Get state."""
    with DaprClient() as client:
        state = client.get_state(
            store_name='statestore',
            key=key
        )
        return {"value": state.data.decode('utf-8') if state.data else None}

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

## Step 6: Run Your App with Dapr

```bash
# Run with Dapr sidecar
dapr run \
  --app-id myapp \
  --app-port 8000 \
  --dapr-http-port 3500 \
  --dapr-grpc-port 50001 \
  --components-path ./components \
  -- uvicorn app.main:app --port 8000
```

**Expected Output:**
```
ℹ️  Starting Dapr with id myapp. HTTP Port: 3500. gRPC Port: 50001
✅  You're up and running! Both Dapr and your app logs will appear here.
```

## Step 7: Test Your App

### Test Health Endpoint

```bash
curl http://localhost:8000/health
# {"status":"healthy"}
```

### Test State Management

```bash
# Save state
curl -X POST "http://localhost:8000/state?key=mykey&value=myvalue"
# {"status":"saved"}

# Get state
curl http://localhost:8000/state/mykey
# {"value":"myvalue"}
```

### Test Pub/Sub

```bash
# Publish message
curl -X POST http://localhost:8000/publish \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello Dapr!"}'
# {"status":"published"}

# Check app logs to see the received message
```

### Test via Dapr API Directly

```bash
# Invoke method via Dapr
curl http://localhost:3500/v1.0/invoke/myapp/method/health
# {"status":"healthy"}

# Save state via Dapr
curl -X POST http://localhost:3500/v1.0/state/statestore \
  -H "Content-Type: application/json" \
  -d '[{"key":"test","value":"hello"}]'

# Get state via Dapr
curl http://localhost:3500/v1.0/state/statestore/test
# "hello"

# Publish event via Dapr
curl -X POST http://localhost:3500/v1.0/publish/pubsub/messages \
  -H "Content-Type: application/json" \
  -d '{"message":"test"}'
```

## Step 8: View Dapr Dashboard (Optional)

```bash
# Install dashboard
dapr dashboard

# Opens browser at http://localhost:8080
```

The dashboard shows:
- Running applications
- Components
- Configurations
- Logs

## Step 9: View Distributed Traces

Zipkin is automatically installed with `dapr init`.

```bash
# Open Zipkin UI
open http://localhost:9411

# Or visit in browser: http://localhost:9411
```

## Common Commands

### Start/Stop Dapr

```bash
# Stop Dapr
dapr stop --app-id myapp

# Uninstall Dapr (removes containers)
dapr uninstall

# Reinstall Dapr
dapr init
```

### View Logs

```bash
# View app logs
dapr logs --app-id myapp

# View Dapr sidecar logs
docker logs dapr_myapp
```

### List Running Apps

```bash
dapr list
```

## Troubleshooting

### Port Already in Use

```bash
# Check what's using the port
lsof -i :3500  # macOS/Linux
netstat -ano | findstr :3500  # Windows

# Use different ports
dapr run --app-id myapp --dapr-http-port 3501 ...
```

### Redis Connection Issues

```bash
# Check if Redis is running
docker ps | grep redis

# Restart Redis
docker restart dapr_redis

# Check Redis logs
docker logs dapr_redis
```

### Component Not Found

```bash
# Verify components path
ls -la ./components

# Check component YAML syntax
cat components/pubsub.yaml

# Restart app with correct path
dapr run --components-path ./components ...
```

## Next Steps

1. **Add More Components**: Try different state stores (PostgreSQL, MongoDB)
2. **Service Invocation**: Create multiple services that call each other
3. **Secrets Management**: Add secret store component
4. **Bindings**: Connect to external systems (Twilio, SendGrid, etc.)
5. **Deploy to Kubernetes**: See dapr-k8s-deployment.md

## Project Structure

```
my-dapr-app/
├── components/
│   ├── pubsub.yaml
│   ├── statestore.yaml
│   └── secrets.yaml
├── app/
│   ├── main.py
│   ├── models.py
│   └── handlers.py
├── venv/
├── requirements.txt
└── README.md
```

## Requirements.txt

```txt
fastapi==0.115.0
uvicorn[standard]==0.30.0
dapr==1.12.0
dapr-ext-fastapi==1.12.0
pydantic==2.5.0
```

## Tips

1. **Always use components-path**: Specify `--components-path` to load your components
2. **Check logs**: Use `dapr logs` to debug issues
3. **Use dashboard**: Great for visualizing your Dapr setup
4. **Test with Dapr API**: Use Dapr HTTP API for quick testing
5. **Enable tracing**: Zipkin helps debug distributed systems

## Resources

- [Dapr Documentation](https://docs.dapr.io/)
- [Dapr Python SDK](https://github.com/dapr/python-sdk)
- [Dapr Quickstarts](https://github.com/dapr/quickstarts)
- [Dapr Community](https://discord.com/invite/ptHhX6jc34)
