# Security Hardening Checklist

**Version**: 1.0
**Last Updated**: 2026-01-12
**Target**: Production Deployment

This checklist ensures the Todo Application meets security best practices before production deployment.

---

## Pre-Deployment Security Checklist

### Authentication & Authorization

- [ ] **JWT Secret**: Use strong, randomly generated secret (min 32 characters)
- [ ] **Token Expiration**: Set appropriate expiration times (15 min access, 7 days refresh)
- [ ] **Password Policy**: Enforce strong passwords (min 8 chars, uppercase, lowercase, numbers, symbols)
- [ ] **Password Hashing**: Use bcrypt with appropriate cost factor (12+)
- [ ] **Session Management**: Implement session timeout after inactivity
- [ ] **Two-Factor Authentication**: Enable 2FA for admin accounts
- [ ] **RBAC**: Verify role-based access control is enforced
- [ ] **API Authentication**: All endpoints require authentication (except public ones)
- [ ] **Token Refresh**: Implement secure token refresh mechanism
- [ ] **Logout**: Properly invalidate tokens on logout

### Data Protection

- [ ] **Encryption at Rest**: Enable database encryption
- [ ] **Encryption in Transit**: Use TLS/SSL for all connections
- [ ] **Sensitive Data**: Never log passwords, tokens, or PII
- [ ] **Database Credentials**: Store in Kubernetes secrets, not in code
- [ ] **API Keys**: Store in secrets, rotate regularly
- [ ] **Environment Variables**: Use secrets for sensitive config
- [ ] **Data Backup**: Encrypt backups
- [ ] **Data Retention**: Implement data retention policies
- [ ] **Data Deletion**: Securely delete user data on request
- [ ] **PII Handling**: Comply with GDPR/CCPA requirements

### Network Security

- [ ] **HTTPS Only**: Enforce HTTPS, redirect HTTP to HTTPS
- [ ] **TLS Version**: Use TLS 1.2 or higher
- [ ] **CORS**: Configure CORS properly, whitelist allowed origins
- [ ] **CSP**: Implement Content Security Policy headers
- [ ] **HSTS**: Enable HTTP Strict Transport Security
- [ ] **X-Frame-Options**: Prevent clickjacking
- [ ] **X-Content-Type-Options**: Prevent MIME sniffing
- [ ] **Network Policies**: Implement Kubernetes network policies
- [ ] **Firewall Rules**: Configure firewall to allow only necessary ports
- [ ] **DDoS Protection**: Implement rate limiting and DDoS protection

### Container Security

- [ ] **Non-Root User**: Run containers as non-root user
- [ ] **Read-Only Filesystem**: Use read-only root filesystem where possible
- [ ] **Security Context**: Set appropriate security context
- [ ] **Resource Limits**: Set CPU and memory limits
- [ ] **Image Scanning**: Scan images for vulnerabilities (Trivy)
- [ ] **Image Signing**: Sign images with Cosign
- [ ] **SBOM**: Generate Software Bill of Materials
- [ ] **Base Images**: Use minimal base images (alpine, distroless)
- [ ] **Image Registry**: Use private registry with authentication
- [ ] **Image Tags**: Use specific version tags, not `latest`

### Kubernetes Security

- [ ] **RBAC**: Configure Kubernetes RBAC properly
- [ ] **Service Accounts**: Use dedicated service accounts
- [ ] **Pod Security**: Implement Pod Security Standards
- [ ] **Network Policies**: Restrict pod-to-pod communication
- [ ] **Secrets Management**: Use Kubernetes secrets or external vault
- [ ] **Admission Controllers**: Enable security admission controllers
- [ ] **Audit Logging**: Enable Kubernetes audit logging
- [ ] **API Server**: Secure Kubernetes API server
- [ ] **etcd**: Encrypt etcd data
- [ ] **Namespace Isolation**: Use namespaces for isolation

### Application Security

- [ ] **Input Validation**: Validate all user inputs
- [ ] **SQL Injection**: Use parameterized queries (SQLModel handles this)
- [ ] **XSS Prevention**: Sanitize output, use CSP
- [ ] **CSRF Protection**: Implement CSRF tokens
- [ ] **Command Injection**: Never execute user input as commands
- [ ] **Path Traversal**: Validate file paths
- [ ] **Rate Limiting**: Implement rate limiting on all endpoints
- [ ] **Error Handling**: Don't expose stack traces in production
- [ ] **Logging**: Log security events (failed logins, unauthorized access)
- [ ] **Audit Trail**: Maintain audit logs for compliance

### Dependency Security

- [ ] **Dependency Scanning**: Scan dependencies for vulnerabilities
- [ ] **Dependency Updates**: Keep dependencies up to date
- [ ] **License Compliance**: Check for GPL/AGPL licenses
- [ ] **Pinned Versions**: Pin dependency versions
- [ ] **Vulnerability Alerts**: Enable GitHub Dependabot alerts
- [ ] **SBOM**: Generate and maintain SBOM
- [ ] **Supply Chain**: Verify package integrity
- [ ] **Private Registry**: Use private registry for internal packages
- [ ] **Dependency Review**: Review new dependencies before adding
- [ ] **Automated Updates**: Use Renovate or Dependabot

### CI/CD Security

- [ ] **Secret Management**: Never commit secrets to Git
- [ ] **Branch Protection**: Protect main/production branches
- [ ] **Code Review**: Require code review before merge
- [ ] **Automated Testing**: Run tests on every commit
- [ ] **Security Scanning**: Run security scans in CI/CD
- [ ] **SAST**: Static Application Security Testing
- [ ] **DAST**: Dynamic Application Security Testing (optional)
- [ ] **Container Scanning**: Scan container images
- [ ] **Secret Scanning**: Scan for hardcoded secrets
- [ ] **Deployment Approval**: Require approval for production deployments

### Monitoring & Incident Response

- [ ] **Security Monitoring**: Monitor for security events
- [ ] **Alerting**: Set up alerts for security incidents
- [ ] **Log Aggregation**: Centralize logs for analysis
- [ ] **Intrusion Detection**: Implement IDS/IPS
- [ ] **Incident Response Plan**: Document incident response procedures
- [ ] **Security Contacts**: Maintain list of security contacts
- [ ] **Vulnerability Disclosure**: Publish security policy
- [ ] **Penetration Testing**: Conduct regular pen tests
- [ ] **Security Audits**: Schedule regular security audits
- [ ] **Compliance**: Ensure compliance with regulations (GDPR, SOC 2, etc.)

### Database Security

- [ ] **Database Encryption**: Enable encryption at rest
- [ ] **Connection Encryption**: Use SSL/TLS for connections
- [ ] **Database Credentials**: Rotate credentials regularly
- [ ] **Least Privilege**: Grant minimum required permissions
- [ ] **Database Firewall**: Restrict database access
- [ ] **Backup Encryption**: Encrypt database backups
- [ ] **Audit Logging**: Enable database audit logging
- [ ] **SQL Injection**: Use parameterized queries
- [ ] **Database Patching**: Keep database up to date
- [ ] **Connection Pooling**: Limit connection pool size

### Event Streaming Security

- [ ] **Kafka Authentication**: Enable SASL authentication
- [ ] **Kafka Authorization**: Configure ACLs
- [ ] **Kafka Encryption**: Enable TLS for Kafka
- [ ] **Topic Permissions**: Restrict topic access
- [ ] **Consumer Groups**: Isolate consumer groups
- [ ] **Event Validation**: Validate event schemas
- [ ] **Idempotency**: Prevent duplicate event processing
- [ ] **Event Retention**: Set appropriate retention policies
- [ ] **Kafka Monitoring**: Monitor Kafka security events
- [ ] **Kafka Patching**: Keep Kafka up to date

---

## Security Testing

### Automated Security Testing

```bash
# Backend security scanning
cd backend

# Dependency scanning
safety check

# SAST scanning
bandit -r app/ -ll

# Secret scanning
gitleaks detect --source . --verbose

# Container scanning
trivy image todo-backend:latest
```

### Manual Security Testing

- [ ] **Authentication Testing**: Test login, logout, token refresh
- [ ] **Authorization Testing**: Test RBAC, resource access
- [ ] **Input Validation**: Test with malicious inputs
- [ ] **SQL Injection**: Test with SQL injection payloads
- [ ] **XSS Testing**: Test with XSS payloads
- [ ] **CSRF Testing**: Test CSRF protection
- [ ] **Rate Limiting**: Test rate limiting enforcement
- [ ] **Session Management**: Test session timeout
- [ ] **Error Handling**: Verify no sensitive data in errors
- [ ] **API Security**: Test all API endpoints

### Penetration Testing

- [ ] **External Pen Test**: Hire external security firm
- [ ] **Internal Pen Test**: Conduct internal testing
- [ ] **Red Team Exercise**: Simulate real attacks
- [ ] **Vulnerability Assessment**: Identify vulnerabilities
- [ ] **Remediation**: Fix identified vulnerabilities
- [ ] **Retest**: Verify fixes are effective
- [ ] **Report**: Document findings and remediation
- [ ] **Continuous Testing**: Schedule regular pen tests

---

## Security Hardening Steps

### 1. Secure Kubernetes Deployment

```yaml
# Pod Security Context
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false

# Network Policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-network-policy
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
```

### 2. Secure Backend Configuration

```python
# app/core/security.py

from passlib.context import CryptContext
from jose import jwt
from datetime import datetime, timedelta

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# JWT token generation
def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# Rate limiting
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.get("/api/v1/tasks")
@limiter.limit("100/minute")
async def list_tasks():
    pass
```

### 3. Secure Frontend Configuration

```typescript
// lib/security.ts

// CSRF token
export function getCsrfToken(): string {
  return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
}

// XSS prevention
export function sanitizeHtml(html: string): string {
  return DOMPurify.sanitize(html);
}

// Secure storage
export function secureStorage() {
  return {
    setItem: (key: string, value: string) => {
      sessionStorage.setItem(key, btoa(value));
    },
    getItem: (key: string) => {
      const value = sessionStorage.getItem(key);
      return value ? atob(value) : null;
    }
  };
}
```

### 4. Security Headers

```python
# app/main.py

from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware

app = FastAPI()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://todo-app.example.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
    allow_headers=["*"],
)

# Trusted hosts
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["todo-app.example.com", "*.todo-app.example.com"]
)

# Security headers
@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    return response
```

---

## Security Monitoring

### Key Security Metrics

- Failed login attempts
- Unauthorized access attempts
- Rate limit violations
- SQL injection attempts
- XSS attempts
- Unusual API usage patterns
- Privilege escalation attempts
- Data exfiltration attempts

### Security Alerts

```yaml
# Prometheus alert rules
- alert: HighFailedLoginRate
  expr: rate(failed_login_attempts_total[5m]) > 10
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High failed login rate detected"

- alert: UnauthorizedAccessAttempt
  expr: rate(unauthorized_access_attempts_total[5m]) > 5
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "Unauthorized access attempts detected"
```

---

## Incident Response

### Security Incident Procedure

1. **Detection**: Identify security incident
2. **Containment**: Isolate affected systems
3. **Investigation**: Analyze logs and evidence
4. **Eradication**: Remove threat
5. **Recovery**: Restore normal operations
6. **Lessons Learned**: Document and improve

### Emergency Contacts

- **Security Team**: security@todo-app.example.com
- **On-Call Engineer**: +1-XXX-XXX-XXXX
- **Legal**: legal@todo-app.example.com
- **PR**: pr@todo-app.example.com

---

## Compliance

### GDPR Compliance

- [ ] **Data Inventory**: Document all personal data
- [ ] **Consent**: Obtain explicit consent
- [ ] **Right to Access**: Provide data export
- [ ] **Right to Deletion**: Implement data deletion
- [ ] **Data Portability**: Enable data export
- [ ] **Privacy Policy**: Publish privacy policy
- [ ] **DPO**: Appoint Data Protection Officer
- [ ] **Breach Notification**: 72-hour breach notification
- [ ] **Data Processing Agreement**: Sign DPA with processors
- [ ] **Privacy by Design**: Implement privacy by design

### SOC 2 Compliance

- [ ] **Security**: Implement security controls
- [ ] **Availability**: Ensure system availability
- [ ] **Processing Integrity**: Ensure data integrity
- [ ] **Confidentiality**: Protect confidential data
- [ ] **Privacy**: Protect personal information
- [ ] **Audit**: Conduct annual SOC 2 audit
- [ ] **Documentation**: Maintain compliance documentation
- [ ] **Monitoring**: Continuous compliance monitoring

---

## Security Resources

### Tools

- **SAST**: Bandit, Semgrep, CodeQL
- **DAST**: OWASP ZAP, Burp Suite
- **Container Scanning**: Trivy, Clair, Anchore
- **Secret Scanning**: Gitleaks, TruffleHog
- **Dependency Scanning**: Safety, Snyk, Dependabot
- **Penetration Testing**: Metasploit, Kali Linux

### References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

---

## Sign-Off

**Security Review Completed By**: ___________________

**Date**: ___________________

**Approved for Production**: [ ] Yes [ ] No

**Notes**: ___________________

---

**Remember**: Security is an ongoing process, not a one-time checklist. Regularly review and update security measures.
