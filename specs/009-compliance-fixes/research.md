# Research: Hackathon Compliance Fixes

**Date**: 2026-01-07
**Feature**: 009-compliance-fixes
**Status**: Complete

## Overview

This document consolidates research findings for implementing Better Auth, ChatKit, dual token validation, feature flags, Docker/Helm updates, and autonomous testing to achieve hackathon compliance.

---

## 1. Better Auth Configuration

### 1.1 Bcrypt Password Compatibility

**Decision**: Use custom hash/verify functions to maintain bcrypt compatibility

**Implementation**:
```typescript
import bcrypt from "bcrypt";

export const auth = betterAuth({
  emailAndPassword: {
    enabled: true,
    password: {
      hash: async (password) => {
        return await bcrypt.hash(password, 10);
      },
      verify: async ({ hash, password }) => {
        return await bcrypt.compare(password, hash);
      }
    }
  }
});
```

**Rationale**: Better Auth uses scrypt by default, but custom hash/verify functions allow seamless integration with existing bcrypt-hashed passwords without requiring password resets.

**Alternatives Considered**:
- Force password reset for all users (rejected: violates zero data loss constraint)
- Migrate passwords to scrypt (rejected: requires password reset)

---

### 1.2 JWT Token Structure with user_id in "sub" Claim

**Decision**: Use Better Auth JWT plugin with custom payload definition

**Implementation**:
```typescript
import { jwt } from "better-auth/plugins";

export const auth = betterAuth({
  plugins: [
    jwt({
      jwt: {
        getSubject: (user) => user.id,  // user_id in "sub" claim
        definePayload: ({user}) => ({
          id: user.id,
          email: user.email,
          role: user.role
        }),
        issuer: "better-auth",
        expirationTime: "15 minutes"
      }
    })
  ]
});
```

**Rationale**: Better Auth JWT plugin defaults to using `user.id` as the `sub` claim, which matches existing backend expectations. The `definePayload` function provides complete control over JWT contents.

**Alternatives Considered**:
- Custom JWT generation (rejected: reinvents Better Auth functionality)
- Modify backend to accept different claim structure (rejected: violates API compatibility constraint)

---

### 1.3 Database Table Mapping

**Decision**: Use hybrid approach with custom adapter for account table mapping

**Critical Finding**: Better Auth expects separate `user` and `account` tables:
- **User table**: id, email, name, timestamps
- **Account table**: userId, providerId, password

**Current Schema**:
```sql
users: id (UUID), email, hashed_password, name, created_at, updated_at
```

**Implementation Strategy**:
```typescript
export const auth = betterAuth({
  user: {
    modelName: "users",
    fields: {
      email: "email",
      name: "name"
    }
  },
  generateId: "uuid",

  // Custom adapter to map account queries to users table
  database: customAdapter({
    // Map account.password queries to users.hashed_password
  })
});
```

**Rationale**: Preserves existing database schema while providing Better Auth compatibility through custom adapter. Avoids data migration during time-constrained implementation.

**Alternatives Considered**:
- Full schema migration (rejected: time constraint, complexity)
- Keep both schemas (rejected: data duplication, sync issues)

---

## 2. ChatKit Integration

### 2.1 Current State Analysis

**Critical Finding**: Current implementation uses **custom React components**, NOT ChatKit:
- Custom components: ChatArea, ChatInput, ChatSidebar, ChatMessage
- REST API endpoints: `/api/v1/chat`, `/api/v1/conversations`
- OpenAI Agents SDK with MCP Server via `MCPServerStreamableHttp`

**Decision**: Replace custom components with ChatKit while maintaining existing backend

---

### 2.2 ChatKit Setup for Next.js 15 App Router

**Implementation**:

**Step 1: Install dependencies**
```bash
npm install @openai/chatkit-react
```

**Step 2: Add ChatKit script to layout**
```typescript
// app/layout.tsx
import Script from 'next/script';

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <head>
        <Script
          src="https://cdn.platform.openai.com/deployments/chatkit/chatkit.js"
          strategy="beforeInteractive"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

**Step 3: Create ChatWidget component**
```typescript
// components/ChatWidget.tsx
'use client';

import { ChatKit, useChatKit } from '@openai/chatkit-react';

export function ChatWidget() {
  const { control } = useChatKit({
    api: {
      async getClientSecret() {
        const authToken = await getAuthToken(); // Better Auth JWT
        const res = await fetch('/api/chatkit/session', {
          method: 'POST',
          headers: { 'Authorization': `Bearer ${authToken}` }
        });
        const { client_secret } = await res.json();
        return client_secret;
      }
    }
  });

  return <ChatKit control={control} className="h-[600px]" />;
}
```

**Rationale**: ChatKit provides polished UI out of the box while maintaining existing backend logic through session endpoint.

---

### 2.3 ChatKit Authentication with Better Auth JWT

**Decision**: Pass Better Auth JWT token in Authorization header to session endpoint

**Implementation**:
```typescript
const { control } = useChatKit({
  api: {
    async getClientSecret(existingSecret?: string): Promise<string> {
      const authToken = await getAuthToken(); // Better Auth JWT

      const response = await fetch('/api/chatkit/session', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`
        },
        body: JSON.stringify({
          user_id: currentUserId,
          refresh: existingSecret ? true : false
        })
      });

      const data = await response.json();
      return data.client_secret;
    }
  }
});
```

**Rationale**: Maintains existing authentication pattern (JWT in Authorization header) while integrating ChatKit.

---

## 3. Dual Token Validation

### 3.1 Implementation Pattern

**Decision**: Use try-catch fallback pattern for dual token validation

**Implementation**:
```python
# app/core/auth.py
async def get_current_user_dual(
    authorization: Annotated[str | None, Header()] = None,
    settings: Annotated[Settings, Depends(get_settings)] = None,
) -> str:
    """Validate JWT from either custom or Better Auth issuer."""
    token = _extract_token(authorization)

    # Try custom JWT first (legacy)
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
        user_id = payload.get("sub")
        if user_id:
            logger.warning(f"Legacy token used by user {user_id}")
            return user_id
    except JWTError:
        pass

    # Try Better Auth JWT
    try:
        payload = jwt.decode(
            token,
            settings.better_auth_secret,
            algorithms=["HS256"],
            issuer="better-auth"
        )
        user_id = payload.get("sub")
        if user_id:
            return user_id
    except JWTError as e:
        raise AuthenticationError(f"Invalid token: {e}")
```

**Rationale**: Simplest and most maintainable approach. Attempts legacy validation first, falls back to Better Auth. Provides clear logging for monitoring migration progress.

**Alternatives Considered**:
- Issuer-based routing (rejected: requires decoding tokens twice)
- Parallel validation (rejected: unnecessary complexity)

---

### 3.2 7-Day Transition Period

**Decision**: Use environment variables for cutoff date configuration

**Implementation**:
```python
# app/config.py
class Settings:
    auth_migration_enabled: bool = os.getenv("AUTH_MIGRATION_ENABLED", "true").lower() == "true"
    legacy_token_cutoff_date: str = os.getenv("LEGACY_TOKEN_CUTOFF_DATE", "")
    enable_legacy_tokens: bool = os.getenv("ENABLE_LEGACY_TOKENS", "true").lower() == "true"
```

**Environment Variables**:
```bash
AUTH_MIGRATION_ENABLED=true
ENABLE_LEGACY_TOKENS=true
LEGACY_TOKEN_CUTOFF_DATE=2026-01-15T00:00:00Z  # 7 days from deployment
```

**Rationale**: Externalized configuration allows runtime control without code changes. Clear cutoff date provides predictable migration timeline.

---

## 4. Feature Flags

### 4.1 Implementation Strategy

**Decision**: Use simple environment-based feature flags (no external dependencies)

**Backend Implementation**:
```python
# app/config.py
class Settings:
    use_new_auth: bool = os.getenv("FEATURE_NEW_AUTH", "false").lower() == "true"
    use_new_chat: bool = os.getenv("FEATURE_NEW_CHAT", "false").lower() == "true"
    rollback_auth: bool = os.getenv("ROLLBACK_AUTH", "false").lower() == "true"
    rollback_chat: bool = os.getenv("ROLLBACK_CHAT", "false").lower() == "true"
```

**Frontend Implementation**:
```typescript
// lib/features/flags.ts
export const featureFlags = {
  useNewAuth: process.env.NEXT_PUBLIC_FEATURE_NEW_AUTH === 'true',
  useNewChat: process.env.NEXT_PUBLIC_FEATURE_NEW_CHAT === 'true',
} as const;
```

**Rationale**: Zero external dependencies, instant rollback via environment variables, works across all environments (dev, staging, prod).

**Alternatives Considered**:
- LaunchDarkly (rejected: external service dependency)
- Flagsmith (rejected: unnecessary complexity for 2 flags)
- @vercel/flags (rejected: Vercel-specific)

---

### 4.2 Factory Pattern for System Toggling

**Authentication Toggle**:
```python
# app/core/auth_factory.py
def get_auth_provider() -> AuthProvider:
    settings = get_settings()

    if settings.rollback_auth:
        return LegacyAuthProvider()

    if settings.use_new_auth:
        return NewAuthProvider()

    return LegacyAuthProvider()
```

**Chat Component Toggle**:
```typescript
// app/(authenticated)/chatbot/page.tsx
export default function ChatbotPage() {
  const useNewChat =
    process.env.NEXT_PUBLIC_ROLLBACK_CHAT !== 'true' &&
    featureFlags.useNewChat;

  if (useNewChat) {
    return <ChatKitPage />;
  }

  return <LegacyChatPage />;
}
```

**Rationale**: Factory pattern provides clean abstraction for toggling implementations. Rollback flags take precedence over feature flags for instant disable.

---

## 5. Docker and Helm Updates

### 5.1 Docker Image Versioning

**Decision**: Use semantic versioning with v1.1.0 for this update

**Tagging Strategy**:
```bash
# Build with version tag
docker build -t todo-backend:v1.1.0 ./calm-orbit-todo/backend
docker build -t todo-frontend:v1.1.0 ./calm-orbit-todo/frontend

# Load into Minikube
minikube image load todo-backend:v1.1.0
minikube image load todo-frontend:v1.1.0
```

**Rationale**: Semantic versioning provides clear version history. Minor version bump (1.0.0 → 1.1.0) indicates new features without breaking changes.

---

### 5.2 Dockerfile Updates

**Frontend Dockerfile** (no changes needed):
- Existing multi-stage build automatically includes Better Auth when added to package.json
- Layer caching preserved

**Backend Dockerfile** (no changes needed):
- Existing multi-stage build automatically includes feature flag libraries when added to requirements.txt
- Layer caching preserved

**Rationale**: Well-designed Dockerfiles require no modifications for dependency updates.

---

### 5.3 Helm Chart Updates

**values.yaml Updates**:
```yaml
backend:
  image:
    tag: v1.1.0  # Updated from v1.0.0

frontend:
  image:
    tag: v1.1.0  # Updated from v1.0.0

featureFlags:
  dualAuth: "true"
  betterAuth: "true"
  legacyJwt: "false"
```

**ConfigMap for Feature Flags**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
data:
  FEATURE_NEW_AUTH: "false"
  FEATURE_NEW_CHAT: "false"
  ROLLBACK_AUTH: "false"
  ROLLBACK_CHAT: "false"
```

**Deployment Command**:
```bash
helm upgrade --install todo-chatbot ./charts/todo-chatbot \
  --set backend.image.tag=v1.1.0 \
  --set frontend.image.tag=v1.1.0 \
  -n todo-app
```

**Rationale**: Helm values provide declarative configuration. ConfigMap enables runtime feature flag updates without pod restarts.

---

## 6. Autonomous Testing

### 6.1 Testing Capabilities

**Decision**: Use Claude Code CLI with programmatic test execution via Bash tool

**Capabilities**:
- Execute pytest tests programmatically
- Generate test scripts dynamically
- Parse JSON test reports
- Validate API responses
- Perform multi-step workflows

**Implementation Pattern**:
```python
# tests/autonomous/test_api_workflow.py
async def test_api_workflow():
    async with httpx.AsyncClient(base_url="http://localhost:8000") as client:
        # Register user
        response = await client.post("/api/v1/auth/register", json={...})

        # Login and get token
        response = await client.post("/api/v1/auth/login", json={...})
        token = response.json()["access_token"]

        # Perform CRUD operations
        # ...

        return results
```

**Rationale**: Leverages existing test infrastructure while adding autonomous orchestration layer.

---

### 6.2 Chatbot Natural Language Testing

**Decision**: Use pattern-based response validation

**Implementation**:
```python
class ChatbotResponseValidator:
    @staticmethod
    def validate_task_creation(response: str) -> bool:
        patterns = [
            r"added.*task",
            r"created.*task",
            r"I've added",
            r"task.*created"
        ]
        return any(re.search(pattern, response, re.IGNORECASE) for pattern in patterns)
```

**Test Scenarios**:
1. "Add a task to buy groceries" → Validate task creation confirmation
2. "Show me my tasks" → Validate task list response
3. "Mark task 1 as complete" → Validate completion confirmation
4. "Delete all completed tasks" → Validate deletion confirmation

**Rationale**: Pattern matching provides robust validation without requiring exact response matching.

---

### 6.3 Test Report Generation

**Decision**: Generate both Markdown and JSON reports

**Markdown Report Format**:
```markdown
# Autonomous Test Report: full_task_lifecycle

**Generated**: 2026-01-07T10:30:00
**Duration**: 12 minutes

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 25 |
| Passed | 25 ✓ |
| Failed | 0 ✗ |
| Pass Rate | 100.0% |
| Status | SUCCESS |

## Test Results

1. **register_user**: ✓ PASS
2. **login_user**: ✓ PASS
...
```

**JSON Report Format**:
```json
{
  "workflow": "full_task_lifecycle",
  "timestamp": "2026-01-07T10:30:00",
  "summary": {
    "total": 25,
    "passed": 25,
    "failed": 0,
    "pass_rate": 100.0,
    "status": "SUCCESS"
  },
  "tests": [...]
}
```

**Rationale**: Markdown for human readability, JSON for CI/CD integration and programmatic parsing.

---

### 6.4 Time-Constrained Execution

**Decision**: Use priority-based test execution with 15-minute timeout

**Implementation**:
```python
class TimeConstrainedTestRunner:
    def __init__(self, max_duration_seconds: int = 900):  # 15 minutes
        self.max_duration = max_duration_seconds

    async def run_with_timeout(self, test_suites: List[Callable]):
        # Execute P1 tests first (critical path)
        # Then P2 tests (important features)
        # Finally P3 tests (edge cases)
        # Stop if time limit approaching
```

**Priority Levels**:
- **P1 (Critical)**: Health checks, authentication, basic CRUD (5 minutes)
- **P2 (Important)**: Search, filtering, chatbot (5 minutes)
- **P3 (Nice-to-have)**: Edge cases, error handling (5 minutes)

**Rationale**: Ensures critical tests always run even if time runs short. Graceful degradation if timeout approaches.

---

## 7. Implementation Recommendations

### 7.1 Phased Rollout Strategy

**Phase 1: Preparation (Day 0)**
- Implement Better Auth with feature flag disabled
- Implement ChatKit with feature flag disabled
- Deploy dual token validation
- Test in staging

**Phase 2: Soft Launch (Day 1-2)**
- Enable Better Auth for new registrations
- Enable ChatKit for 10% of users
- Monitor metrics and error rates

**Phase 3: Full Rollout (Day 3-7)**
- Enable Better Auth for all users
- Enable ChatKit for all users
- Both token types accepted
- Monitor legacy token usage

**Phase 4: Deprecation (Day 8+)**
- Disable legacy token validation
- Remove old code
- Update documentation

---

### 7.2 Monitoring and Observability

**Key Metrics**:
- Token usage by type (legacy vs Better Auth)
- Authentication failure rates
- ChatKit load times
- Feature flag toggle events
- Error rates by endpoint

**Logging Strategy**:
```python
logger.warning(f"Legacy token used by user {user_id}")
logger.info(f"Better Auth token validated for user {user_id}")
logger.error(f"Token validation failed: {error}")
```

---

### 7.3 Rollback Procedures

**Instant Rollback via Feature Flags**:
```bash
# Disable Better Auth
kubectl patch configmap feature-flags -p '{"data":{"ROLLBACK_AUTH":"true"}}'

# Disable ChatKit
kubectl patch configmap feature-flags -p '{"data":{"ROLLBACK_CHAT":"true"}}'
```

**Full Rollback via Helm**:
```bash
# Rollback to previous release
helm rollback todo-chatbot -n todo-app

# Or deploy previous image versions
helm upgrade todo-chatbot ./charts/todo-chatbot \
  --set backend.image.tag=v1.0.0 \
  --set frontend.image.tag=v1.0.0 \
  -n todo-app
```

---

## 8. Risk Mitigation

### 8.1 Identified Risks

1. **Better Auth schema mismatch** → Mitigated by custom adapter
2. **Token validation failures** → Mitigated by dual token support
3. **ChatKit integration issues** → Mitigated by feature flag rollback
4. **Data loss during migration** → Mitigated by zero schema changes
5. **Performance degradation** → Mitigated by monitoring and rollback

### 8.2 Contingency Plans

- Feature flags enable instant rollback
- Dual token support prevents authentication failures
- Existing backend logic preserved (no breaking changes)
- Comprehensive testing before production deployment
- Gradual rollout with monitoring at each stage

---

## 9. Success Criteria

- ✅ All existing user accounts can log in with Better Auth
- ✅ New users can register via Better Auth
- ✅ ChatKit components render and function correctly
- ✅ All existing API endpoints work without modification
- ✅ Dual token validation accepts both token types
- ✅ Feature flags enable instant rollback
- ✅ Docker images rebuild successfully
- ✅ Helm chart deploys to Minikube
- ✅ Autonomous testing achieves 100% pass rate
- ✅ Implementation completes within 4-5 hours

---

## 10. References

- Better Auth Documentation: https://better-auth.com
- OpenAI ChatKit Documentation: https://platform.openai.com/docs/chatkit
- FastAPI JWT Authentication: https://fastapi.tiangolo.com/tutorial/security/
- Helm Best Practices: https://helm.sh/docs/chart_best_practices/
- Docker Multi-Stage Builds: https://docs.docker.com/build/building/multi-stage/

---

**Research Status**: ✅ Complete
**Next Phase**: Phase 1 - Design & Contracts (data-model.md, contracts/, quickstart.md)
