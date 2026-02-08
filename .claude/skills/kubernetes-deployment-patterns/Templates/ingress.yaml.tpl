# Kubernetes Ingress Templates
# Ingress manages external HTTP/HTTPS access to services

---
# Basic Ingress (Single Service)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-ingress
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
spec:
  ingressClassName: nginx  # or traefik, haproxy, etc.
  rules:
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{SERVICE_NAME}}
            port:
              number: {{SERVICE_PORT}}

---
# Ingress with TLS (HTTPS)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-tls-ingress
  namespace: {{NAMESPACE}}
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - {{DOMAIN}}
    secretName: {{APP_NAME}}-tls
  rules:
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{SERVICE_NAME}}
            port:
              number: {{SERVICE_PORT}}

---
# Multi-Path Ingress (Multiple Services)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-multipath
  namespace: {{NAMESPACE}}
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8000
      - path: /frontend(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 3000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 3000

---
# Multi-Host Ingress (Multiple Domains)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-multihost
  namespace: {{NAMESPACE}}
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.{{DOMAIN}}
    - app.{{DOMAIN}}
    secretName: {{APP_NAME}}-tls
  rules:
  - host: api.{{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8000
  - host: app.{{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 3000

---
# Ingress with Annotations (Nginx)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-annotated
  namespace: {{NAMESPACE}}
  annotations:
    # SSL/TLS
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"

    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"

    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "100"
    nginx.ingress.kubernetes.io/limit-connections: "10"

    # Timeouts
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"

    # Body size
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"

    # Custom headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-XSS-Protection: 1; mode=block";

    # Whitelist IPs
    nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/8,192.168.0.0/16"

    # Basic auth
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
spec:
  ingressClassName: nginx
  rules:
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{SERVICE_NAME}}
            port:
              number: {{SERVICE_PORT}}

---
# Ingress with URL Rewriting
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-rewrite
  namespace: {{NAMESPACE}}
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8000

---
# Ingress with Load Balancing
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-lb
  namespace: {{NAMESPACE}}
  annotations:
    nginx.ingress.kubernetes.io/load-balance: "ewma"  # or round_robin, ip_hash
    nginx.ingress.kubernetes.io/upstream-hash-by: "$request_uri"
spec:
  ingressClassName: nginx
  rules:
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{SERVICE_NAME}}
            port:
              number: {{SERVICE_PORT}}

---
# Ingress with Canary Deployment
# Stable version
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-stable
  namespace: {{NAMESPACE}}
spec:
  ingressClassName: nginx
  rules:
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{APP_NAME}}-stable
            port:
              number: {{SERVICE_PORT}}

---
# Canary version (10% traffic)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-canary
  namespace: {{NAMESPACE}}
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"  # 10% traffic
spec:
  ingressClassName: nginx
  rules:
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{APP_NAME}}-canary
            port:
              number: {{SERVICE_PORT}}

---
# Ingress with Header-Based Canary
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-canary-header
  namespace: {{NAMESPACE}}
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-by-header: "X-Canary"
    nginx.ingress.kubernetes.io/canary-by-header-value: "always"
spec:
  ingressClassName: nginx
  rules:
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{APP_NAME}}-canary
            port:
              number: {{SERVICE_PORT}}

---
# Ingress with OAuth2 Authentication
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-oauth2
  namespace: {{NAMESPACE}}
  annotations:
    nginx.ingress.kubernetes.io/auth-url: "https://oauth2.{{DOMAIN}}/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth2.{{DOMAIN}}/oauth2/start?rd=$escaped_request_uri"
spec:
  ingressClassName: nginx
  rules:
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{SERVICE_NAME}}
            port:
              number: {{SERVICE_PORT}}

---
# Ingress with Custom Error Pages
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-errors
  namespace: {{NAMESPACE}}
  annotations:
    nginx.ingress.kubernetes.io/custom-http-errors: "404,503"
    nginx.ingress.kubernetes.io/default-backend: error-pages-service
spec:
  ingressClassName: nginx
  rules:
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{SERVICE_NAME}}
            port:
              number: {{SERVICE_PORT}}

---
# Ingress with WebSocket Support
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-websocket
  namespace: {{NAMESPACE}}
  annotations:
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
    nginx.ingress.kubernetes.io/websocket-services: "{{SERVICE_NAME}}"
spec:
  ingressClassName: nginx
  rules:
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /ws
        pathType: Prefix
        backend:
          service:
            name: {{SERVICE_NAME}}
            port:
              number: {{SERVICE_PORT}}

---
# Complete Production Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{APP_NAME}}-prod
  namespace: {{NAMESPACE}}
  labels:
    app: {{APP_NAME}}
    environment: production
  annotations:
    # TLS/SSL
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"

    # Security headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-XSS-Protection: 1; mode=block";
      more_set_headers "Strict-Transport-Security: max-age=31536000; includeSubDomains";

    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "100"
    nginx.ingress.kubernetes.io/limit-connections: "10"

    # Timeouts
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"

    # Body size
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"

    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://{{DOMAIN}}"
    nginx.ingress.kubernetes.io/cors-allow-credentials: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - {{DOMAIN}}
    - api.{{DOMAIN}}
    secretName: {{APP_NAME}}-tls
  rules:
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 3000
  - host: api.{{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8000

---
# Variable Reference
# Replace these placeholders with actual values:
#
# {{APP_NAME}}      - Application name
# {{NAMESPACE}}     - Kubernetes namespace
# {{DOMAIN}}        - Domain name (e.g., example.com)
# {{SERVICE_NAME}}  - Service name
# {{SERVICE_PORT}}  - Service port
