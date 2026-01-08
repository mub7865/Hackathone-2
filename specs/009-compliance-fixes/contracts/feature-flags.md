# Contract: Feature Flags

**Feature**: 009-compliance-fixes
**Date**: 2026-01-07
**Type**: Feature Flag System Contract

## Overview

This contract defines the feature flag system for toggling between old/new authentication and chat implementations, enabling instant rollback with zero downtime.

---

## Feature Flag Architecture

### Design Principles

1. **Zero External Dependencies**: No third-party services required
2. **Environment-Based**: Configuration via environment variables
3. **Instant Rollback**: Change environment variable, no deployment needed
4. **Hierarchical Priority**: Rollback flags override feature flags
5. **Runtime Evaluation**: Flags checked on each request (no restart required)

---

## Backend Implementation

### Configuration

**File**: `app/config.py`

```python
import os
from typing import Dict

class Settings:
    # Feature flags
    use_new_auth: bool = os.getenv("FEATURE_NEW_AUTH", "false").lower() == "true"
    use_new_chat: bool = os.getenv("FEATURE_NEW_CHAT", "false").lower() == "true"

    # Rollback flags (highest priority)
    rollback_auth: bool = os.getenv("ROLLBACK_AUTH", "false").lower() == "true"
    rollback_chat: bool = os.getenv("ROLLBACK_CHAT", "false").lower() == "true"

    def is_feature_enabled(self, feature: str) -> bool:
        """Check if feature is enabled with rollback support.

        Args:
            feature: Feature name ("auth" or "chat")

        Returns:
            bool: True if feature is enabled and not rolled back
        """
        rollback_flag = getattr(self, f"rollback_{feature}", False)
        if rollback_flag:
            return False  # Rollback overrides everything

        feature_flag = getattr(self, f"use_new_{feature}", False)
        return feature_flag
```

---

### Factory Pattern for Authentication

**File**: `app/core/auth_factory.py`

```python
from typing import Protocol
from app.config import get_settings
from app.core.auth import get_current_user_dual, get_current_user_legacy

class AuthProvider(Protocol):
    """Authentication provider interface."""
    async def get_current_user(self, authorization: str | None) -> str:
        """Extract user ID from authorization."""
        ...

class DualAuthProvider:
    """Dual token validation (legacy + Better Auth)."""
    async def get_current_user(self, authorization: str | None) -> str:
        from app.core.auth import get_current_user_dual
        return await get_current_user_dual(authorization)

class LegacyAuthProvider:
    """Legacy JWT-only authentication."""
    async def get_current_user(self, authorization: str | None) -> str:
        from app.core.auth import get_current_user_legacy
        return await get_current_user_legacy(authorization)

def get_auth_provider() -> AuthProvider:
    """Factory function to get active auth provider.

    Returns:
        AuthProvider: Active authentication provider based on feature flags
    """
    settings = get_settings()

    # Check rollback flag first (highest priority)
    if settings.rollback_auth:
        return LegacyAuthProvider()

    # Check feature flag
    if settings.is_feature_enabled("auth"):
        return DualAuthProvider()

    return LegacyAuthProvider()
```

---

## Frontend Implementation

### Configuration

**File**: `lib/features/flags.ts`

```typescript
export const featureFlags = {
  useNewAuth: process.env.NEXT_PUBLIC_FEATURE_NEW_AUTH === 'true',
  useNewChat: process.env.NEXT_PUBLIC_FEATURE_NEW_CHAT === 'true',
} as const;

export type FeatureFlag = keyof typeof featureFlags;

export function isFeatureEnabled(flag: FeatureFlag): boolean {
  // Check rollback flag first
  const rollbackKey = `NEXT_PUBLIC_ROLLBACK_${flag.replace('useNew', '').toUpperCase()}`;
  if (process.env[rollbackKey] === 'true') {
    return false;
  }

  return featureFlags[flag] ?? false;
}
```

---

### Factory Pattern for Authentication Client

**File**: `lib/auth/factory.ts`

```typescript
import { featureFlags } from '@/lib/features/flags';

interface AuthClient {
  signIn(email: string, password: string): Promise<Session>;
  signOut(): Promise<void>;
  getSession(): Session | null;
}

class LegacyAuthClient implements AuthClient {
  async signIn(email: string, password: string): Promise<Session> {
    // Existing custom JWT implementation
    const response = await fetch('/api/v1/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });

    if (!response.ok) {
      throw new Error('Login failed');
    }

    const data = await response.json();
    return data;
  }

  async signOut(): Promise<void> {
    // Clear local storage
    localStorage.removeItem('auth_token');
  }

  getSession(): Session | null {
    const token = localStorage.getItem('auth_token');
    if (!token) return null;

    // Decode and return session
    return decodeToken(token);
  }
}

class BetterAuthClient implements AuthClient {
  async signIn(email: string, password: string): Promise<Session> {
    // Better Auth implementation
    const { signIn } = await import('better-auth/react');
    return await signIn.email({ email, password });
  }

  async signOut(): Promise<void> {
    const { signOut } = await import('better-auth/react');
    await signOut();
  }

  getSession(): Session | null {
    const { useSession } = await import('better-auth/react');
    const { data } = useSession();
    return data;
  }
}

export function getAuthClient(): AuthClient {
  // Check rollback flag first
  if (process.env.NEXT_PUBLIC_ROLLBACK_AUTH === 'true') {
    return new LegacyAuthClient();
  }

  // Check feature flag
  if (featureFlags.useNewAuth) {
    return new BetterAuthClient();
  }

  return new LegacyAuthClient();
}

// Export singleton instance
export const authClient = getAuthClient();
```

---

### Component-Level Feature Flags

**File**: `app/(authenticated)/chatbot/page.tsx`

```typescript
'use client';

import { featureFlags, isFeatureEnabled } from '@/lib/features/flags';
import { LegacyChatPage } from '@/components/chat/LegacyChatPage';
import { ChatKitPage } from '@/components/chat/ChatKitPage';

export default function ChatbotPage() {
  // Runtime check with rollback support
  const useNewChat = isFeatureEnabled('useNewChat');

  if (useNewChat) {
    return <ChatKitPage />;
  }

  return <LegacyChatPage />;
}
```

---

## Kubernetes Configuration

### ConfigMap for Feature Flags

**File**: `k8s/feature-flags-configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
  namespace: todo-app
data:
  # Feature flags (enable new features)
  FEATURE_NEW_AUTH: "false"
  FEATURE_NEW_CHAT: "false"

  # Rollback flags (instant disable)
  ROLLBACK_AUTH: "false"
  ROLLBACK_CHAT: "false"

  # Migration control
  AUTH_MIGRATION_ENABLED: "true"
  ENABLE_LEGACY_TOKENS: "true"
  LEGACY_TOKEN_CUTOFF_DATE: "2026-01-15T00:00:00Z"
```

---

### Deployment Configuration

**File**: `k8s/backend-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: todo-app
spec:
  template:
    spec:
      containers:
      - name: backend
        image: todo-backend:v1.1.0
        envFrom:
        - configMapRef:
            name: feature-flags
        env:
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: todo-secrets
              key: JWT_SECRET
        - name: BETTER_AUTH_SECRET
          valueFrom:
            secretKeyRef:
              name: todo-secrets
              key: BETTER_AUTH_SECRET
```

**File**: `k8s/frontend-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: todo-app
spec:
  template:
    spec:
      containers:
      - name: frontend
        image: todo-frontend:v1.1.0
        env:
        - name: NEXT_PUBLIC_FEATURE_NEW_AUTH
          valueFrom:
            configMapKeyRef:
              name: feature-flags
              key: FEATURE_NEW_AUTH
        - name: NEXT_PUBLIC_FEATURE_NEW_CHAT
          valueFrom:
            configMapKeyRef:
              name: feature-flags
              key: FEATURE_NEW_CHAT
        - name: NEXT_PUBLIC_ROLLBACK_AUTH
          valueFrom:
            configMapKeyRef:
              name: feature-flags
              key: ROLLBACK_AUTH
        - name: NEXT_PUBLIC_ROLLBACK_CHAT
          valueFrom:
            configMapKeyRef:
              name: feature-flags
              key: ROLLBACK_CHAT
```

---

## Environment Variable Hierarchy

### Priority Order (Highest to Lowest)

1. **Rollback Flags** - Instant disable (highest priority)
   - `ROLLBACK_AUTH=true` → Disable Better Auth immediately
   - `ROLLBACK_CHAT=true` → Disable ChatKit immediately

2. **Feature Flags** - Enable new features
   - `FEATURE_NEW_AUTH=true` → Enable Better Auth
   - `FEATURE_NEW_CHAT=true` → Enable ChatKit

3. **Default Behavior** - Use legacy implementations
   - If no flags set, use custom JWT and custom chat

---

## Rollout Strategy

### Phase 1: Development Testing

```bash
# .env.development
FEATURE_NEW_AUTH=true
FEATURE_NEW_CHAT=true
ROLLBACK_AUTH=false
ROLLBACK_CHAT=false
```

**Behavior**: Test new implementations in development

---

### Phase 2: Staging Deployment

```bash
# .env.staging
FEATURE_NEW_AUTH=true
FEATURE_NEW_CHAT=false  # Chat not ready yet
ROLLBACK_AUTH=false
ROLLBACK_CHAT=false
```

**Behavior**: Test Better Auth in staging, keep legacy chat

---

### Phase 3: Production Soft Launch

```bash
# .env.production
FEATURE_NEW_AUTH=false  # Start disabled
FEATURE_NEW_CHAT=false
ROLLBACK_AUTH=false
ROLLBACK_CHAT=false
```

**Behavior**: Deploy code but keep features disabled

---

### Phase 4: Production Gradual Rollout

```bash
# Day 1: Enable Better Auth
kubectl patch configmap feature-flags -p '{"data":{"FEATURE_NEW_AUTH":"true"}}'

# Day 3: Enable ChatKit
kubectl patch configmap feature-flags -p '{"data":{"FEATURE_NEW_CHAT":"true"}}'
```

**Behavior**: Gradually enable features in production

---

### Phase 5: Emergency Rollback (If Needed)

```bash
# Instant rollback - no deployment required
kubectl patch configmap feature-flags -p '{"data":{"ROLLBACK_AUTH":"true"}}'
kubectl patch configmap feature-flags -p '{"data":{"ROLLBACK_CHAT":"true"}}'
```

**Behavior**: Instant disable of new features

---

## Monitoring and Observability

### Feature Flag Usage Metrics

```python
# app/core/metrics.py
from prometheus_client import Counter, Gauge

feature_flag_usage = Counter(
    'feature_flag_usage_total',
    'Total feature flag evaluations',
    ['feature', 'enabled']
)

feature_flag_state = Gauge(
    'feature_flag_state',
    'Current state of feature flags',
    ['feature']
)

def track_feature_flag(feature: str, enabled: bool):
    """Track feature flag usage."""
    feature_flag_usage.labels(feature=feature, enabled=str(enabled)).inc()
    feature_flag_state.labels(feature=feature).set(1 if enabled else 0)
```

---

### Logging

```python
import logging

logger = logging.getLogger(__name__)

def log_feature_flag_evaluation(feature: str, enabled: bool, reason: str):
    """Log feature flag evaluation for debugging."""
    logger.info(
        f"Feature flag evaluated: {feature}={enabled}",
        extra={
            "feature": feature,
            "enabled": enabled,
            "reason": reason
        }
    )
```

---

## Testing Contract

### Unit Tests

**File**: `tests/unit/test_feature_flags.py`

```python
import pytest
import os

from app.config import Settings

def test_feature_flag_enabled():
    """Test feature flag returns true when enabled."""
    os.environ["FEATURE_NEW_AUTH"] = "true"
    settings = Settings()
    assert settings.is_feature_enabled("auth") is True

def test_feature_flag_disabled():
    """Test feature flag returns false when disabled."""
    os.environ["FEATURE_NEW_AUTH"] = "false"
    settings = Settings()
    assert settings.is_feature_enabled("auth") is False

def test_rollback_overrides_feature_flag():
    """Test rollback flag overrides feature flag."""
    os.environ["FEATURE_NEW_AUTH"] = "true"
    os.environ["ROLLBACK_AUTH"] = "true"
    settings = Settings()
    assert settings.is_feature_enabled("auth") is False

def test_default_behavior():
    """Test default behavior when no flags set."""
    os.environ.pop("FEATURE_NEW_AUTH", None)
    os.environ.pop("ROLLBACK_AUTH", None)
    settings = Settings()
    assert settings.is_feature_enabled("auth") is False
```

---

### Integration Tests

**File**: `tests/integration/test_feature_flag_routing.py`

```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_auth_routes_to_legacy_when_disabled(client: AsyncClient):
    """Test authentication uses legacy when feature flag disabled."""
    os.environ["FEATURE_NEW_AUTH"] = "false"

    # Login should use legacy endpoint
    response = await client.post("/api/v1/auth/login", json={
        "email": "test@example.com",
        "password": "password123"
    })

    # Verify legacy JWT token format
    token = response.json()["access_token"]
    decoded = jwt.decode(token, verify=False)
    assert "iss" not in decoded  # Legacy tokens don't have issuer

@pytest.mark.asyncio
async def test_auth_routes_to_better_auth_when_enabled(client: AsyncClient):
    """Test authentication uses Better Auth when feature flag enabled."""
    os.environ["FEATURE_NEW_AUTH"] = "true"

    # Login should use Better Auth
    response = await client.post("/api/auth/login", json={
        "email": "test@example.com",
        "password": "password123"
    })

    # Verify Better Auth JWT token format
    token = response.json()["access_token"]
    decoded = jwt.decode(token, verify=False)
    assert decoded["iss"] == "better-auth"
```

---

## Helm Chart Integration

### values.yaml

```yaml
# Feature flags configuration
featureFlags:
  newAuth: false
  newChat: false
  rollbackAuth: false
  rollbackChat: false

# Migration control
authMigration:
  enabled: true
  enableLegacyTokens: true
  legacyTokenCutoffDate: "2026-01-15T00:00:00Z"
```

### templates/configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "todo-chatbot.fullname" . }}-feature-flags
  labels:
    {{- include "todo-chatbot.labels" . | nindent 4 }}
data:
  FEATURE_NEW_AUTH: {{ .Values.featureFlags.newAuth | quote }}
  FEATURE_NEW_CHAT: {{ .Values.featureFlags.newChat | quote }}
  ROLLBACK_AUTH: {{ .Values.featureFlags.rollbackAuth | quote }}
  ROLLBACK_CHAT: {{ .Values.featureFlags.rollbackChat | quote }}
  AUTH_MIGRATION_ENABLED: {{ .Values.authMigration.enabled | quote }}
  ENABLE_LEGACY_TOKENS: {{ .Values.authMigration.enableLegacyTokens | quote }}
  LEGACY_TOKEN_CUTOFF_DATE: {{ .Values.authMigration.legacyTokenCutoffDate | quote }}
```

---

## Operational Procedures

### Enable Feature in Production

```bash
# 1. Update Helm values
helm upgrade todo-chatbot ./charts/todo-chatbot \
  --set featureFlags.newAuth=true \
  -n todo-app

# 2. Verify ConfigMap updated
kubectl get configmap feature-flags -n todo-app -o yaml

# 3. Monitor logs for feature flag usage
kubectl logs -f deployment/backend-deployment -n todo-app | grep "Feature flag"

# 4. Check metrics
curl http://backend-service:8000/metrics | grep feature_flag
```

---

### Emergency Rollback

```bash
# Instant rollback via ConfigMap patch (no Helm upgrade needed)
kubectl patch configmap feature-flags -n todo-app \
  -p '{"data":{"ROLLBACK_AUTH":"true"}}'

# Verify rollback
kubectl get configmap feature-flags -n todo-app -o jsonpath='{.data.ROLLBACK_AUTH}'

# Monitor impact
kubectl logs -f deployment/backend-deployment -n todo-app
```

---

## Security Considerations

1. **No Sensitive Data**: Feature flags contain no secrets
2. **ConfigMap Permissions**: Restrict who can modify ConfigMaps
3. **Audit Logging**: Log all feature flag changes
4. **Gradual Rollout**: Test in dev/staging before production
5. **Monitoring**: Alert on unexpected feature flag changes

---

## Performance Considerations

1. **No Database Queries**: Flags evaluated from environment variables
2. **Minimal Overhead**: Simple boolean checks (<1μs)
3. **No External Calls**: No network requests to feature flag services
4. **Caching**: Environment variables cached by OS

---

**Contract Status**: ✅ Complete
**Implementation Files**: 4 files (config.py, flags.ts, factory.py, factory.ts)
**Dependencies**: None (zero external dependencies)
**Rollback Time**: <1 second (ConfigMap patch)
