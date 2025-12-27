# Full-Stack Application Helm Chart

Complete example of a Helm chart for deploying a full-stack application (Frontend + Backend).

## Chart Structure

```
todo-chart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── NOTES.txt
└── .helmignore
```

---

## Chart.yaml

```yaml
apiVersion: v2
name: todo-app
description: A Helm chart for Todo Application (Frontend + Backend)
type: application
version: 1.0.0
appVersion: "1.0.0"

maintainers:
  - name: Your Name
    email: your@email.com

keywords:
  - todo
  - fullstack
  - fastapi
  - nextjs

home: https://github.com/yourusername/todo-app

kubeVersion: ">=1.25.0"
```

---

## values.yaml

```yaml
# ======================
# Global Configuration
# ======================
global:
  environment: production
  namespace: todo-app

# ======================
# Backend Configuration
# ======================
backend:
  enabled: true
  replicaCount: 2

  image:
    repository: todo-backend
    tag: "v1"
    pullPolicy: IfNotPresent

  service:
    type: ClusterIP
    port: 8000

  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"

  env:
    APP_ENV: "production"
    LOG_LEVEL: "info"

  livenessProbe:
    enabled: true
    path: /docs
    initialDelaySeconds: 15
    periodSeconds: 20
    timeoutSeconds: 5
    failureThreshold: 3

  readinessProbe:
    enabled: true
    path: /docs
    initialDelaySeconds: 5
    periodSeconds: 10
    timeoutSeconds: 3
    failureThreshold: 3

# ======================
# Frontend Configuration
# ======================
frontend:
  enabled: true
  replicaCount: 2

  image:
    repository: todo-frontend
    tag: "v1"
    pullPolicy: IfNotPresent

  service:
    type: NodePort
    port: 3000
    nodePort: 30000

  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "256Mi"

  env:
    NODE_ENV: "production"

  livenessProbe:
    enabled: true
    path: /
    initialDelaySeconds: 15
    periodSeconds: 20

  readinessProbe:
    enabled: true
    path: /
    initialDelaySeconds: 5
    periodSeconds: 10

# ======================
# Secrets Configuration
# ======================
secrets:
  # Leave empty - pass via --set at install time
  databaseUrl: ""
  authSecret: ""
  geminiApiKey: ""

# ======================
# ConfigMap Configuration
# ======================
config:
  backendUrl: "http://todo-backend-service:8000"
```

---

## templates/_helpers.tpl

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "todo-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "todo-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "todo-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "todo-app.labels" -}}
helm.sh/chart: {{ include "todo-app.chart" . }}
{{ include "todo-app.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "todo-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "todo-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Backend name
*/}}
{{- define "todo-app.backendName" -}}
{{- printf "%s-backend" (include "todo-app.fullname" .) }}
{{- end }}

{{/*
Frontend name
*/}}
{{- define "todo-app.frontendName" -}}
{{- printf "%s-frontend" (include "todo-app.fullname" .) }}
{{- end }}

{{/*
Secret name
*/}}
{{- define "todo-app.secretName" -}}
{{- printf "%s-secrets" (include "todo-app.fullname" .) }}
{{- end }}

{{/*
ConfigMap name
*/}}
{{- define "todo-app.configMapName" -}}
{{- printf "%s-config" (include "todo-app.fullname" .) }}
{{- end }}
```

---

## templates/secret.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "todo-app.secretName" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "todo-app.labels" . | nindent 4 }}
type: Opaque
stringData:
  {{- if .Values.secrets.databaseUrl }}
  DATABASE_URL: {{ .Values.secrets.databaseUrl | quote }}
  {{- end }}
  {{- if .Values.secrets.authSecret }}
  BETTER_AUTH_SECRET: {{ .Values.secrets.authSecret | quote }}
  {{- end }}
  {{- if .Values.secrets.geminiApiKey }}
  GEMINI_API_KEY: {{ .Values.secrets.geminiApiKey | quote }}
  {{- end }}
```

---

## templates/configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "todo-app.configMapName" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "todo-app.labels" . | nindent 4 }}
data:
  APP_ENV: {{ .Values.global.environment | quote }}
  BACKEND_URL: {{ .Values.config.backendUrl | quote }}
  {{- range $key, $value := .Values.backend.env }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
```

---

## templates/backend-deployment.yaml

```yaml
{{- if .Values.backend.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "todo-app.backendName" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "todo-app.labels" . | nindent 4 }}
    component: backend
spec:
  replicas: {{ .Values.backend.replicaCount }}
  selector:
    matchLabels:
      {{- include "todo-app.selectorLabels" . | nindent 6 }}
      component: backend
  template:
    metadata:
      labels:
        {{- include "todo-app.selectorLabels" . | nindent 8 }}
        component: backend
    spec:
      containers:
        - name: backend
          image: "{{ .Values.backend.image.repository }}:{{ .Values.backend.image.tag }}"
          imagePullPolicy: {{ .Values.backend.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.backend.service.port }}
              protocol: TCP
          env:
            {{- range $key, $value := .Values.backend.env }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
          envFrom:
            - secretRef:
                name: {{ include "todo-app.secretName" . }}
          {{- with .Values.backend.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if .Values.backend.livenessProbe.enabled }}
          livenessProbe:
            httpGet:
              path: {{ .Values.backend.livenessProbe.path }}
              port: {{ .Values.backend.service.port }}
            initialDelaySeconds: {{ .Values.backend.livenessProbe.initialDelaySeconds }}
            periodSeconds: {{ .Values.backend.livenessProbe.periodSeconds }}
            timeoutSeconds: {{ .Values.backend.livenessProbe.timeoutSeconds }}
            failureThreshold: {{ .Values.backend.livenessProbe.failureThreshold }}
          {{- end }}
          {{- if .Values.backend.readinessProbe.enabled }}
          readinessProbe:
            httpGet:
              path: {{ .Values.backend.readinessProbe.path }}
              port: {{ .Values.backend.service.port }}
            initialDelaySeconds: {{ .Values.backend.readinessProbe.initialDelaySeconds }}
            periodSeconds: {{ .Values.backend.readinessProbe.periodSeconds }}
            timeoutSeconds: {{ .Values.backend.readinessProbe.timeoutSeconds }}
            failureThreshold: {{ .Values.backend.readinessProbe.failureThreshold }}
          {{- end }}
{{- end }}
```

---

## templates/backend-service.yaml

```yaml
{{- if .Values.backend.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "todo-app.backendName" . }}-service
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "todo-app.labels" . | nindent 4 }}
    component: backend
spec:
  type: {{ .Values.backend.service.type }}
  ports:
    - port: {{ .Values.backend.service.port }}
      targetPort: {{ .Values.backend.service.port }}
      protocol: TCP
      name: http
  selector:
    {{- include "todo-app.selectorLabels" . | nindent 4 }}
    component: backend
{{- end }}
```

---

## templates/frontend-deployment.yaml

```yaml
{{- if .Values.frontend.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "todo-app.frontendName" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "todo-app.labels" . | nindent 4 }}
    component: frontend
spec:
  replicas: {{ .Values.frontend.replicaCount }}
  selector:
    matchLabels:
      {{- include "todo-app.selectorLabels" . | nindent 6 }}
      component: frontend
  template:
    metadata:
      labels:
        {{- include "todo-app.selectorLabels" . | nindent 8 }}
        component: frontend
    spec:
      containers:
        - name: frontend
          image: "{{ .Values.frontend.image.repository }}:{{ .Values.frontend.image.tag }}"
          imagePullPolicy: {{ .Values.frontend.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.frontend.service.port }}
              protocol: TCP
          env:
            - name: NEXT_PUBLIC_API_URL
              value: "http://{{ include "todo-app.backendName" . }}-service:{{ .Values.backend.service.port }}"
            {{- range $key, $value := .Values.frontend.env }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
          {{- with .Values.frontend.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if .Values.frontend.livenessProbe.enabled }}
          livenessProbe:
            httpGet:
              path: {{ .Values.frontend.livenessProbe.path }}
              port: {{ .Values.frontend.service.port }}
            initialDelaySeconds: {{ .Values.frontend.livenessProbe.initialDelaySeconds }}
            periodSeconds: {{ .Values.frontend.livenessProbe.periodSeconds }}
          {{- end }}
          {{- if .Values.frontend.readinessProbe.enabled }}
          readinessProbe:
            httpGet:
              path: {{ .Values.frontend.readinessProbe.path }}
              port: {{ .Values.frontend.service.port }}
            initialDelaySeconds: {{ .Values.frontend.readinessProbe.initialDelaySeconds }}
            periodSeconds: {{ .Values.frontend.readinessProbe.periodSeconds }}
          {{- end }}
{{- end }}
```

---

## templates/frontend-service.yaml

```yaml
{{- if .Values.frontend.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "todo-app.frontendName" . }}-service
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "todo-app.labels" . | nindent 4 }}
    component: frontend
spec:
  type: {{ .Values.frontend.service.type }}
  ports:
    - port: {{ .Values.frontend.service.port }}
      targetPort: {{ .Values.frontend.service.port }}
      protocol: TCP
      name: http
      {{- if and (eq .Values.frontend.service.type "NodePort") .Values.frontend.service.nodePort }}
      nodePort: {{ .Values.frontend.service.nodePort }}
      {{- end }}
  selector:
    {{- include "todo-app.selectorLabels" . | nindent 4 }}
    component: frontend
{{- end }}
```

---

## templates/NOTES.txt

```
=======================================================
  {{ .Chart.Name }} has been deployed successfully!
=======================================================

Release: {{ .Release.Name }}
Namespace: {{ .Release.Namespace }}
Chart Version: {{ .Chart.Version }}
App Version: {{ .Chart.AppVersion }}

-------------------------------------------------------
Access the application:
-------------------------------------------------------

{{- if .Values.frontend.enabled }}
Frontend:
{{- if eq .Values.frontend.service.type "NodePort" }}
  Run: minikube service {{ include "todo-app.frontendName" . }}-service -n {{ .Release.Namespace }}
  Or:
  export NODE_PORT=$(kubectl get svc {{ include "todo-app.frontendName" . }}-service -n {{ .Release.Namespace }} -o jsonpath='{.spec.ports[0].nodePort}')
  export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
  echo "http://$NODE_IP:$NODE_PORT"
{{- else }}
  kubectl port-forward svc/{{ include "todo-app.frontendName" . }}-service {{ .Values.frontend.service.port }}:{{ .Values.frontend.service.port }} -n {{ .Release.Namespace }}
  Open: http://localhost:{{ .Values.frontend.service.port }}
{{- end }}
{{- end }}

{{- if .Values.backend.enabled }}
Backend (internal):
  http://{{ include "todo-app.backendName" . }}-service:{{ .Values.backend.service.port }}

To test backend locally:
  kubectl port-forward svc/{{ include "todo-app.backendName" . }}-service 8000:{{ .Values.backend.service.port }} -n {{ .Release.Namespace }}
  Open: http://localhost:8000/docs
{{- end }}

-------------------------------------------------------
Useful Commands:
-------------------------------------------------------

# Check pod status
kubectl get pods -n {{ .Release.Namespace }} -l "app.kubernetes.io/instance={{ .Release.Name }}"

# View logs
kubectl logs -l "app.kubernetes.io/instance={{ .Release.Name }},component=backend" -n {{ .Release.Namespace }}
kubectl logs -l "app.kubernetes.io/instance={{ .Release.Name }},component=frontend" -n {{ .Release.Namespace }}

# Upgrade release
helm upgrade {{ .Release.Name }} ./{{ .Chart.Name }} -n {{ .Release.Namespace }}

# Uninstall release
helm uninstall {{ .Release.Name }} -n {{ .Release.Namespace }}
```

---

## .helmignore

```
# Patterns to ignore when building packages
.DS_Store
.git/
.gitignore
.vscode/
*.swp
*.bak
*.tmp
*.orig
*~
.project
.idea/
*.tmproj
.hg/
.hgignore
.bzr/
.bzrignore
.svn/

# Testing
tests/

# Documentation
*.md
LICENSE
```

---

## Deployment Commands

### Install

```bash
# Basic install
helm install todo ./todo-chart -n todo-app --create-namespace

# With secrets
helm install todo ./todo-chart -n todo-app --create-namespace \
  --set secrets.databaseUrl="postgresql://user:pass@host/db" \
  --set secrets.authSecret="your-auth-secret" \
  --set secrets.geminiApiKey="your-api-key"
```

### Upgrade

```bash
helm upgrade todo ./todo-chart -n todo-app \
  --set backend.image.tag="v2" \
  --set frontend.image.tag="v2"
```

### Dry Run (Test)

```bash
helm install todo ./todo-chart --dry-run --debug
```

### Uninstall

```bash
helm uninstall todo -n todo-app
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    HELM CHART                           │
│                                                         │
│  ┌──────────────────┐       ┌──────────────────┐      │
│  │   values.yaml    │──────▶│    templates/    │      │
│  │   (Config)       │       │   (K8s YAMLs)    │      │
│  └──────────────────┘       └────────┬─────────┘      │
│                                      │                 │
│                              helm install              │
│                                      │                 │
└──────────────────────────────────────┼─────────────────┘
                                       ▼
┌─────────────────────────────────────────────────────────┐
│                 KUBERNETES CLUSTER                      │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Secret    │  │  ConfigMap  │  │  Deployment │    │
│  │  (Secrets)  │  │  (Config)   │  │  (Backend)  │    │
│  └─────────────┘  └─────────────┘  └──────┬──────┘    │
│                                           │            │
│                                    ┌──────▼──────┐    │
│  ┌─────────────┐                  │   Service   │    │
│  │ Deployment  │                  │  (Backend)  │    │
│  │ (Frontend)  │                  └─────────────┘    │
│  └──────┬──────┘                                      │
│         │                                             │
│  ┌──────▼──────┐                                     │
│  │   Service   │◀──── External Access               │
│  │ (Frontend)  │                                     │
│  └─────────────┘                                     │
└─────────────────────────────────────────────────────────┘
```
