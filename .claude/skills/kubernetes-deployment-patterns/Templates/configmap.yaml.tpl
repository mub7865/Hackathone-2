# Kubernetes ConfigMap Templates
# ConfigMaps store non-sensitive configuration data

---
# Basic ConfigMap (Key-Value Pairs)
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{APP_NAME}}-config
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
data:
  # Simple key-value pairs
  APP_ENV: "{{ENVIRONMENT}}"
  LOG_LEVEL: "{{LOG_LEVEL}}"
  PORT: "{{PORT}}"
  API_TIMEOUT: "30"
  MAX_CONNECTIONS: "100"

---
# ConfigMap with Configuration Files
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{APP_NAME}}-files
  namespace: {{NAMESPACE}}
data:
  # JSON configuration file
  config.json: |
    {
      "server": {
        "port": {{PORT}},
        "host": "0.0.0.0"
      },
      "database": {
        "maxConnections": 100,
        "timeout": 30000
      },
      "features": {
        "enableCache": true,
        "enableMetrics": true
      }
    }

  # YAML configuration file
  config.yaml: |
    server:
      port: {{PORT}}
      host: 0.0.0.0
    database:
      maxConnections: 100
      timeout: 30000
    features:
      enableCache: true
      enableMetrics: true

  # Properties file
  application.properties: |
    server.port={{PORT}}
    server.host=0.0.0.0
    database.maxConnections=100
    database.timeout=30000

  # Environment file
  .env: |
    NODE_ENV={{ENVIRONMENT}}
    PORT={{PORT}}
    LOG_LEVEL={{LOG_LEVEL}}

---
# ConfigMap for Nginx Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: {{NAMESPACE}}
data:
  nginx.conf: |
    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log warn;
    pid /var/run/nginx.pid;

    events {
      worker_connections 1024;
    }

    http {
      include /etc/nginx/mime.types;
      default_type application/octet-stream;

      log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

      access_log /var/log/nginx/access.log main;

      sendfile on;
      tcp_nopush on;
      keepalive_timeout 65;
      gzip on;

      server {
        listen 80;
        server_name _;

        location / {
          proxy_pass http://backend-service:8000;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /health {
          access_log off;
          return 200 "healthy\n";
          add_header Content-Type text/plain;
        }
      }
    }

---
# ConfigMap for Application Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
    environment: {{ENVIRONMENT}}
data:
  # Application settings
  APP_NAME: "{{APP_NAME}}"
  APP_ENV: "{{ENVIRONMENT}}"
  LOG_LEVEL: "{{LOG_LEVEL}}"

  # Server settings
  PORT: "{{PORT}}"
  HOST: "0.0.0.0"

  # Database settings (non-sensitive)
  DB_HOST: "{{DB_HOST}}"
  DB_PORT: "{{DB_PORT}}"
  DB_NAME: "{{DB_NAME}}"
  DB_POOL_SIZE: "10"
  DB_TIMEOUT: "30000"

  # Cache settings
  CACHE_ENABLED: "true"
  CACHE_TTL: "3600"

  # API settings
  API_TIMEOUT: "30000"
  API_RETRY_COUNT: "3"
  API_RATE_LIMIT: "100"

  # Feature flags
  FEATURE_NEW_UI: "true"
  FEATURE_ANALYTICS: "true"
  FEATURE_NOTIFICATIONS: "true"

---
# ConfigMap for Multi-Environment
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{APP_NAME}}-{{ENVIRONMENT}}
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
    environment: {{ENVIRONMENT}}
data:
  # Development
  {{#if ENVIRONMENT == "development"}}
  DEBUG: "true"
  LOG_LEVEL: "debug"
  CACHE_ENABLED: "false"
  {{/if}}

  # Staging
  {{#if ENVIRONMENT == "staging"}}
  DEBUG: "false"
  LOG_LEVEL: "info"
  CACHE_ENABLED: "true"
  {{/if}}

  # Production
  {{#if ENVIRONMENT == "production"}}
  DEBUG: "false"
  LOG_LEVEL: "warn"
  CACHE_ENABLED: "true"
  {{/if}}

---
# ConfigMap for Scripts
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{APP_NAME}}-scripts
  namespace: {{NAMESPACE}}
data:
  # Startup script
  startup.sh: |
    #!/bin/bash
    set -e

    echo "Starting {{APP_NAME}}..."

    # Wait for dependencies
    until nc -z $DB_HOST $DB_PORT; do
      echo "Waiting for database..."
      sleep 2
    done

    # Run migrations
    if [ "$RUN_MIGRATIONS" = "true" ]; then
      echo "Running migrations..."
      npm run migrate
    fi

    # Start application
    echo "Starting application..."
    exec npm start

  # Health check script
  healthcheck.sh: |
    #!/bin/bash
    curl -f http://localhost:$PORT/health || exit 1

  # Backup script
  backup.sh: |
    #!/bin/bash
    set -e

    BACKUP_DIR="/backups"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)

    echo "Creating backup at $TIMESTAMP..."
    pg_dump $DATABASE_URL > "$BACKUP_DIR/backup_$TIMESTAMP.sql"

    echo "Backup completed: backup_$TIMESTAMP.sql"

---
# ConfigMap for Logging Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: logging-config
  namespace: {{NAMESPACE}}
data:
  # Log4j configuration
  log4j2.xml: |
    <?xml version="1.0" encoding="UTF-8"?>
    <Configuration status="WARN">
      <Appenders>
        <Console name="Console" target="SYSTEM_OUT">
          <PatternLayout pattern="%d{HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n"/>
        </Console>
      </Appenders>
      <Loggers>
        <Root level="{{LOG_LEVEL}}">
          <AppenderRef ref="Console"/>
        </Root>
      </Loggers>
    </Configuration>

  # Winston configuration (Node.js)
  winston.json: |
    {
      "level": "{{LOG_LEVEL}}",
      "format": "json",
      "transports": [
        {
          "type": "console",
          "format": "simple"
        },
        {
          "type": "file",
          "filename": "/var/log/app/error.log",
          "level": "error"
        },
        {
          "type": "file",
          "filename": "/var/log/app/combined.log"
        }
      ]
    }

---
# Using ConfigMap in Deployment

# Method 1: All keys as environment variables
spec:
  containers:
  - name: {{APP_NAME}}
    envFrom:
    - configMapRef:
        name: {{APP_NAME}}-config

# Method 2: Specific keys as environment variables
spec:
  containers:
  - name: {{APP_NAME}}
    env:
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: {{APP_NAME}}-config
          key: LOG_LEVEL
    - name: PORT
      valueFrom:
        configMapKeyRef:
          name: {{APP_NAME}}-config
          key: PORT

# Method 3: Mount as volume (files)
spec:
  containers:
  - name: {{APP_NAME}}
    volumeMounts:
    - name: config-volume
      mountPath: /app/config
      readOnly: true
  volumes:
  - name: config-volume
    configMap:
      name: {{APP_NAME}}-files

# Method 4: Mount specific keys as files
spec:
  containers:
  - name: {{APP_NAME}}
    volumeMounts:
    - name: config-volume
      mountPath: /app/config
      readOnly: true
  volumes:
  - name: config-volume
    configMap:
      name: {{APP_NAME}}-files
      items:
      - key: config.json
        path: config.json
      - key: nginx.conf
        path: nginx.conf

---
# Creating ConfigMap from Files (kubectl)

# From literal values
# kubectl create configmap {{APP_NAME}}-config \
#   --from-literal=APP_ENV={{ENVIRONMENT}} \
#   --from-literal=LOG_LEVEL={{LOG_LEVEL}} \
#   -n {{NAMESPACE}}

# From file
# kubectl create configmap {{APP_NAME}}-config \
#   --from-file=config.json \
#   --from-file=nginx.conf \
#   -n {{NAMESPACE}}

# From directory
# kubectl create configmap {{APP_NAME}}-config \
#   --from-file=./config/ \
#   -n {{NAMESPACE}}

# From env file
# kubectl create configmap {{APP_NAME}}-config \
#   --from-env-file=.env \
#   -n {{NAMESPACE}}

---
# Variable Reference
# Replace these placeholders with actual values:
#
# {{APP_NAME}}      - Application name (e.g., backend, frontend)
# {{NAMESPACE}}     - Kubernetes namespace (e.g., todo-app)
# {{ENVIRONMENT}}   - Environment (e.g., development, staging, production)
# {{LOG_LEVEL}}     - Log level (e.g., debug, info, warn, error)
# {{PORT}}          - Application port (e.g., 8000)
# {{DB_HOST}}       - Database host
# {{DB_PORT}}       - Database port
# {{DB_NAME}}       - Database name
