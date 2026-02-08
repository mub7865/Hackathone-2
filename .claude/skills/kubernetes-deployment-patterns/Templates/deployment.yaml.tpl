# Kubernetes Deployment Template
# This template provides production-ready Deployment configurations for various scenarios

---
# Basic Deployment (Minimal)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{APP_NAME}}
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
    version: {{VERSION}}
spec:
  replicas: {{REPLICAS}}
  selector:
    matchLabels:
      app: {{APP_NAME}}
  template:
    metadata:
      labels:
        app: {{APP_NAME}}
        version: {{VERSION}}
    spec:
      containers:
      - name: {{APP_NAME}}
        image: {{IMAGE}}:{{VERSION}}
        ports:
        - containerPort: {{PORT}}

---
# Production Deployment (Complete)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{APP_NAME}}
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
    version: {{VERSION}}
    tier: {{TIER}}  # frontend, backend, database
    environment: {{ENVIRONMENT}}  # dev, staging, production
  annotations:
    kubernetes.io/description: "{{DESCRIPTION}}"
    deployment.kubernetes.io/revision: "{{REVISION}}"
spec:
  # Replica configuration
  replicas: {{REPLICAS}}

  # Update strategy
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max extra pods during update
      maxUnavailable: 0  # Keep all replicas available during update

  # Minimum time for pod to be ready
  minReadySeconds: 10

  # Revision history limit
  revisionHistoryLimit: 10

  # Selector
  selector:
    matchLabels:
      app: {{APP_NAME}}

  # Pod template
  template:
    metadata:
      labels:
        app: {{APP_NAME}}
        version: {{VERSION}}
        tier: {{TIER}}
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "{{METRICS_PORT}}"
        prometheus.io/path: "/metrics"

    spec:
      # Security context for pod
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        fsGroup: 10001

      # Service account
      serviceAccountName: {{SERVICE_ACCOUNT}}

      # Init containers (optional)
      initContainers:
      - name: init-db
        image: busybox:1.36
        command: ['sh', '-c', 'until nc -z {{DB_HOST}} {{DB_PORT}}; do echo waiting for db; sleep 2; done']

      # Main containers
      containers:
      - name: {{APP_NAME}}
        image: {{IMAGE}}:{{VERSION}}
        imagePullPolicy: IfNotPresent

        # Ports
        ports:
        - name: http
          containerPort: {{PORT}}
          protocol: TCP
        - name: metrics
          containerPort: {{METRICS_PORT}}
          protocol: TCP

        # Environment variables
        env:
        - name: PORT
          value: "{{PORT}}"
        - name: NODE_ENV
          value: "{{ENVIRONMENT}}"
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP

        # Environment from ConfigMap
        envFrom:
        - configMapRef:
            name: {{APP_NAME}}-config

        # Environment from Secret
        - secretRef:
            name: {{APP_NAME}}-secrets

        # Resource management
        resources:
          requests:
            cpu: "{{CPU_REQUEST}}"
            memory: "{{MEMORY_REQUEST}}"
          limits:
            cpu: "{{CPU_LIMIT}}"
            memory: "{{MEMORY_LIMIT}}"

        # Health probes
        livenessProbe:
          httpGet:
            path: /health
            port: http
            scheme: HTTP
          initialDelaySeconds: 30
          periodSeconds: 15
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /ready
            port: http
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 3

        startupProbe:
          httpGet:
            path: /health
            port: http
            scheme: HTTP
          initialDelaySeconds: 0
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 30  # 30 * 5s = 150s max startup time

        # Volume mounts
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
          readOnly: true
        - name: secrets-volume
          mountPath: /app/secrets
          readOnly: true
        - name: tmp
          mountPath: /tmp

        # Security context for container
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 10001
          capabilities:
            drop:
            - ALL

      # Volumes
      volumes:
      - name: config-volume
        configMap:
          name: {{APP_NAME}}-config
      - name: secrets-volume
        secret:
          secretName: {{APP_NAME}}-secrets
      - name: tmp
        emptyDir: {}

      # Restart policy
      restartPolicy: Always

      # Termination grace period
      terminationGracePeriodSeconds: 30

      # DNS policy
      dnsPolicy: ClusterFirst

      # Node selector (optional)
      nodeSelector:
        kubernetes.io/os: linux

      # Affinity rules (optional)
      affinity:
        # Pod anti-affinity (spread pods across nodes)
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - {{APP_NAME}}
              topologyKey: kubernetes.io/hostname

      # Tolerations (optional)
      tolerations:
      - key: "node.kubernetes.io/not-ready"
        operator: "Exists"
        effect: "NoExecute"
        tolerationSeconds: 300

---
# High Availability Deployment (Multi-Zone)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{APP_NAME}}-ha
  namespace: {{NAMESPACE}}
spec:
  replicas: 5  # Minimum 3 for HA

  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1

  selector:
    matchLabels:
      app: {{APP_NAME}}

  template:
    metadata:
      labels:
        app: {{APP_NAME}}
    spec:
      containers:
      - name: {{APP_NAME}}
        image: {{IMAGE}}:{{VERSION}}
        ports:
        - containerPort: {{PORT}}
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "1000m"
            memory: "512Mi"
        livenessProbe:
          httpGet:
            path: /health
            port: {{PORT}}
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: {{PORT}}
          initialDelaySeconds: 10
          periodSeconds: 5

      # Topology spread constraints (spread across zones)
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: {{APP_NAME}}
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: ScheduleAnyway
        labelSelector:
          matchLabels:
            app: {{APP_NAME}}

      # Pod disruption budget (separate resource)
      # See pdb.yaml.tpl

---
# Canary Deployment (Progressive Rollout)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{APP_NAME}}-stable
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
    version: stable
spec:
  replicas: 9  # 90% of traffic
  selector:
    matchLabels:
      app: {{APP_NAME}}
      version: stable
  template:
    metadata:
      labels:
        app: {{APP_NAME}}
        version: stable
    spec:
      containers:
      - name: {{APP_NAME}}
        image: {{IMAGE}}:{{STABLE_VERSION}}
        ports:
        - containerPort: {{PORT}}

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{APP_NAME}}-canary
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
    version: canary
spec:
  replicas: 1  # 10% of traffic
  selector:
    matchLabels:
      app: {{APP_NAME}}
      version: canary
  template:
    metadata:
      labels:
        app: {{APP_NAME}}
        version: canary
    spec:
      containers:
      - name: {{APP_NAME}}
        image: {{IMAGE}}:{{CANARY_VERSION}}
        ports:
        - containerPort: {{PORT}}

---
# Blue-Green Deployment
# Deploy new version (green) alongside old version (blue)
# Switch traffic by updating Service selector

# Blue (current version)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{APP_NAME}}-blue
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: {{APP_NAME}}
      version: blue
  template:
    metadata:
      labels:
        app: {{APP_NAME}}
        version: blue
    spec:
      containers:
      - name: {{APP_NAME}}
        image: {{IMAGE}}:{{BLUE_VERSION}}
        ports:
        - containerPort: {{PORT}}

---
# Green (new version)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{APP_NAME}}-green
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: {{APP_NAME}}
      version: green
  template:
    metadata:
      labels:
        app: {{APP_NAME}}
        version: green
    spec:
      containers:
      - name: {{APP_NAME}}
        image: {{IMAGE}}:{{GREEN_VERSION}}
        ports:
        - containerPort: {{PORT}}

# Service selector determines which version receives traffic
# Update Service selector from "version: blue" to "version: green" to switch

---
# Variable Reference
# Replace these placeholders with actual values:
#
# {{APP_NAME}}          - Application name (e.g., backend, frontend)
# {{NAMESPACE}}         - Kubernetes namespace (e.g., todo-app)
# {{VERSION}}           - Image version tag (e.g., v1.0.0)
# {{IMAGE}}             - Container image (e.g., myregistry/myapp)
# {{PORT}}              - Container port (e.g., 8000)
# {{REPLICAS}}          - Number of replicas (e.g., 3)
# {{TIER}}              - Application tier (e.g., frontend, backend)
# {{ENVIRONMENT}}       - Environment (e.g., production, staging)
# {{DESCRIPTION}}       - Deployment description
# {{REVISION}}          - Deployment revision number
# {{METRICS_PORT}}      - Metrics port (e.g., 9090)
# {{SERVICE_ACCOUNT}}   - Service account name
# {{DB_HOST}}           - Database host for init container
# {{DB_PORT}}           - Database port for init container
# {{CPU_REQUEST}}       - CPU request (e.g., 100m)
# {{MEMORY_REQUEST}}    - Memory request (e.g., 128Mi)
# {{CPU_LIMIT}}         - CPU limit (e.g., 500m)
# {{MEMORY_LIMIT}}      - Memory limit (e.g., 512Mi)
# {{STABLE_VERSION}}    - Stable version for canary
# {{CANARY_VERSION}}    - Canary version for testing
# {{BLUE_VERSION}}      - Blue version for blue-green
# {{GREEN_VERSION}}     - Green version for blue-green
