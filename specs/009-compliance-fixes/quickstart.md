# Quickstart Guide: Hackathon Compliance Fixes

**Feature**: 009-compliance-fixes
**Date**: 2026-01-07
**Audience**: Developers implementing the compliance fixes

## Overview

This guide provides step-by-step instructions for implementing Better Auth, ChatKit, dual token validation, feature flags, Docker/Helm updates, and autonomous testing to achieve hackathon compliance.

**Estimated Time**: 4-5 hours
**Priority**: Better Auth (3 hours) → ChatKit (1-2 hours)

---

## Prerequisites

- ✅ Docker installed and running
- ✅ Minikube installed and configured
- ✅ Node.js 18+ and npm installed
- ✅ Python 3.13+ installed
- ✅ Access to Neon PostgreSQL database
- ✅ OpenAI API key for ChatKit

---

## Phase 1: Better Auth Integration (3 hours)

### Step 1.1: Install Dependencies (10 minutes)

**Frontend**:
```bash
cd calm-orbit-todo/frontend
npm install better-auth bcrypt
npm install -D @types/bcrypt
```

**Backend**:
```bash
cd calm-orbit-todo/backend
# Add to requirements.txt:
# python-decouple>=3.8  # For feature flags
pip install -r requirements.txt
```

---

### Step 1.2: Configure Better Auth (30 minutes)

**Create Better Auth configuration**:

```bash
# Create auth config file
touch calm-orbit-todo/frontend/lib/auth/config.ts
touch calm-orbit-todo/frontend/lib/auth/custom-adapter.ts
touch calm-orbit-todo/frontend/lib/auth/client.ts
```

**Copy implementation from contracts**:
- Reference: `specs/009-compliance-fixes/contracts/better-auth-config.md`
- Implement: `lib/auth/config.ts` (Better Auth server config)
- Implement: `lib/auth/custom-adapter.ts` (Database adapter)
- Implement: `lib/auth/client.ts` (Client-side auth)

**Create API route handler**:
```bash
mkdir -p calm-orbit-todo/frontend/app/api/auth/[...all]
touch calm-orbit-todo/frontend/app/api/auth/[...all]/route.ts
```

---

### Step 1.3: Update Environment Variables (10 minutes)

**Frontend `.env.local`**:
```bash
BETTER_AUTH_SECRET=your-secret-key-here-min-32-chars
NEXT_PUBLIC_API_URL=http://localhost:3000
DATABASE_URL=postgresql://user:pass@host:5432/db
```

**Backend `.env`**:
```bash
BETTER_AUTH_SECRET=your-secret-key-here-min-32-chars
JWT_SECRET=your-legacy-jwt-secret
AUTH_MIGRATION_ENABLED=true
ENABLE_LEGACY_TOKENS=true
LEGACY_TOKEN_CUTOFF_DATE=2026-01-15T00:00:00Z
```

---

### Step 1.4: Implement Dual Token Validation (45 minutes)

**Update backend authentication**:

```bash
# Edit these files:
# - calm-orbit-todo/backend/app/config.py
# - calm-orbit-todo/backend/app/core/auth.py
# - calm-orbit-todo/backend/app/api/deps.py
```

**Reference**: `specs/009-compliance-fixes/contracts/dual-token-validation.md`

**Key changes**:
1. Add Better Auth secret to Settings
2. Implement `get_current_user_dual()` function
3. Update `get_current_user()` to use dual validation

---

### Step 1.5: Update Login/Register Pages (30 minutes)

**Update login page**:
```bash
# Edit: calm-orbit-todo/frontend/app/login/page.tsx
```

**Update register page**:
```bash
# Edit: calm-orbit-todo/frontend/app/register/page.tsx
```

**Replace custom auth client calls with Better Auth**:
```typescript
// Before
import { authClient } from '@/lib/auth/client';
await authClient.login(email, password);

// After
import { signIn } from '@/lib/auth/client';
await signIn.email({ email, password });
```

---

### Step 1.6: Test Better Auth (30 minutes)

**Manual Testing**:
```bash
# 1. Start backend
cd calm-orbit-todo/backend
uvicorn app.main:app --reload

# 2. Start frontend
cd calm-orbit-todo/frontend
npm run dev

# 3. Test registration
# - Open http://localhost:3000/register
# - Create new account
# - Verify account created in database

# 4. Test login
# - Open http://localhost:3000/login
# - Login with new account
# - Verify JWT token issued

# 5. Test existing user login
# - Login with existing account
# - Verify bcrypt password compatibility
```

**Automated Testing**:
```bash
# Run backend tests
cd calm-orbit-todo/backend
pytest tests/integration/test_dual_auth.py -v

# Run frontend tests
cd calm-orbit-todo/frontend
npm test -- auth
```

---

## Phase 2: Feature Flags (30 minutes)

### Step 2.1: Implement Feature Flag System (20 minutes)

**Backend**:
```bash
# Edit: calm-orbit-todo/backend/app/config.py
# Add feature flag configuration
```

**Frontend**:
```bash
# Create: calm-orbit-todo/frontend/lib/features/flags.ts
# Implement feature flag utilities
```

**Reference**: `specs/009-compliance-fixes/contracts/feature-flags.md`

---

### Step 2.2: Test Feature Flags (10 minutes)

```bash
# Test rollback capability
export ROLLBACK_AUTH=true
# Verify application uses legacy auth

export ROLLBACK_AUTH=false
export FEATURE_NEW_AUTH=true
# Verify application uses Better Auth
```

---

## Phase 3: ChatKit Integration (1-2 hours)

### Step 3.1: Install ChatKit (5 minutes)

```bash
cd calm-orbit-todo/frontend
npm install @openai/chatkit-react
```

---

### Step 3.2: Add ChatKit Script to Layout (5 minutes)

**Edit**: `calm-orbit-todo/frontend/app/layout.tsx`

```typescript
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

---

### Step 3.3: Create ChatKit Session Endpoint (20 minutes)

```bash
mkdir -p calm-orbit-todo/frontend/app/api/chatkit/session
touch calm-orbit-todo/frontend/app/api/chatkit/session/route.ts
```

**Reference**: `specs/009-compliance-fixes/contracts/chatkit-integration.md`

**Implement session creation with Better Auth JWT authentication**

---

### Step 3.4: Replace Chat Components (45 minutes)

**Create new ChatKit page**:
```bash
# Edit: calm-orbit-todo/frontend/app/(authenticated)/chatbot/page.tsx
```

**Implement feature flag toggle**:
```typescript
const useNewChat = isFeatureEnabled('useNewChat');

if (useNewChat) {
  return <ChatKitPage />;
}

return <LegacyChatPage />;
```

---

### Step 3.5: Test ChatKit (15 minutes)

```bash
# 1. Enable ChatKit feature flag
export NEXT_PUBLIC_FEATURE_NEW_CHAT=true

# 2. Start application
npm run dev

# 3. Test chat interface
# - Open http://localhost:3000/chatbot
# - Send message: "Add a task to buy groceries"
# - Verify task created via MCP tools
# - Check conversation history
```

---

## Phase 4: Docker and Helm Updates (45 minutes)

### Step 4.1: Rebuild Docker Images (15 minutes)

```bash
# Backend
cd calm-orbit-todo/backend
docker build -t todo-backend:v1.1.0 .

# Frontend
cd calm-orbit-todo/frontend
docker build -t todo-frontend:v1.1.0 .

# Load into Minikube
minikube image load todo-backend:v1.1.0
minikube image load todo-frontend:v1.1.0
```

---

### Step 4.2: Update Helm Chart (15 minutes)

**Edit**: `charts/todo-chatbot/values.yaml`

```yaml
backend:
  image:
    tag: v1.1.0  # Updated

frontend:
  image:
    tag: v1.1.0  # Updated

featureFlags:
  newAuth: false  # Start disabled
  newChat: false
```

**Edit**: `charts/todo-chatbot/Chart.yaml`

```yaml
version: 0.2.0        # Chart version bump
appVersion: "1.1.0"   # Application version
```

---

### Step 4.3: Create Feature Flags ConfigMap (10 minutes)

```bash
kubectl create configmap feature-flags \
  --from-literal=FEATURE_NEW_AUTH=false \
  --from-literal=FEATURE_NEW_CHAT=false \
  --from-literal=ROLLBACK_AUTH=false \
  --from-literal=ROLLBACK_CHAT=false \
  -n todo-app --dry-run=client -o yaml | kubectl apply -f -
```

---

### Step 4.4: Deploy to Minikube (5 minutes)

```bash
# Deploy with Helm
helm upgrade --install todo-chatbot ./charts/todo-chatbot \
  -n todo-app --create-namespace

# Verify deployment
kubectl get pods -n todo-app
kubectl logs -f deployment/backend-deployment -n todo-app
kubectl logs -f deployment/frontend-deployment -n todo-app
```

---

## Phase 5: Autonomous Testing (30 minutes)

### Step 5.1: Create Test Scripts (15 minutes)

```bash
mkdir -p calm-orbit-todo/backend/tests/autonomous
touch calm-orbit-todo/backend/tests/autonomous/test_api_workflow.py
touch calm-orbit-todo/backend/tests/autonomous/test_chatbot_autonomous.py
```

**Reference**: `specs/009-compliance-fixes/research.md` (Section 6: Autonomous Testing)

---

### Step 5.2: Run Autonomous Tests (15 minutes)

```bash
# Run autonomous API tests
cd calm-orbit-todo/backend
python tests/autonomous/test_api_workflow.py

# Run autonomous chatbot tests
python tests/autonomous/test_chatbot_autonomous.py

# Generate test report
python tests/autonomous/generate_report.py
```

**Expected Output**:
```
========================================
AUTONOMOUS TEST REPORT
========================================
Total Tests: 25
Passed: 25
Failed: 0
Pass Rate: 100.0%
========================================
```

---

## Phase 6: Gradual Rollout (Ongoing)

### Step 6.1: Enable Better Auth in Production

```bash
# Day 1: Enable Better Auth
kubectl patch configmap feature-flags -n todo-app \
  -p '{"data":{"FEATURE_NEW_AUTH":"true"}}'

# Monitor logs
kubectl logs -f deployment/backend-deployment -n todo-app | grep "token"

# Check metrics
curl http://backend-service:8000/metrics | grep auth_token
```

---

### Step 6.2: Enable ChatKit in Production

```bash
# Day 3: Enable ChatKit (after Better Auth is stable)
kubectl patch configmap feature-flags -n todo-app \
  -p '{"data":{"FEATURE_NEW_CHAT":"true"}}'

# Monitor logs
kubectl logs -f deployment/frontend-deployment -n todo-app | grep "ChatKit"
```

---

### Step 6.3: Monitor Migration Progress

```bash
# Check token usage
kubectl logs deployment/backend-deployment -n todo-app | grep "Legacy token used" | wc -l
kubectl logs deployment/backend-deployment -n todo-app | grep "Better Auth token" | wc -l

# Check error rates
kubectl logs deployment/backend-deployment -n todo-app | grep "ERROR" | wc -l
```

---

### Step 6.4: Deprecate Legacy Tokens (Day 8+)

```bash
# Disable legacy tokens
kubectl patch configmap feature-flags -n todo-app \
  -p '{"data":{"ENABLE_LEGACY_TOKENS":"false"}}'

# Verify only Better Auth tokens accepted
curl -H "Authorization: Bearer <legacy-token>" http://backend-service:8000/api/v1/tasks
# Expected: 401 Unauthorized
```

---

## Emergency Rollback Procedures

### Rollback Better Auth

```bash
# Instant rollback via ConfigMap
kubectl patch configmap feature-flags -n todo-app \
  -p '{"data":{"ROLLBACK_AUTH":"true"}}'

# Verify rollback
kubectl get configmap feature-flags -n todo-app -o jsonpath='{.data.ROLLBACK_AUTH}'
# Expected: true

# Monitor impact
kubectl logs -f deployment/backend-deployment -n todo-app
```

---

### Rollback ChatKit

```bash
# Instant rollback via ConfigMap
kubectl patch configmap feature-flags -n todo-app \
  -p '{"data":{"ROLLBACK_CHAT":"true"}}'

# Verify rollback
kubectl get configmap feature-flags -n todo-app -o jsonpath='{.data.ROLLBACK_CHAT}'
# Expected: true
```

---

### Full Rollback via Helm

```bash
# Rollback to previous Helm release
helm rollback todo-chatbot -n todo-app

# Or deploy previous image versions
helm upgrade todo-chatbot ./charts/todo-chatbot \
  --set backend.image.tag=v1.0.0 \
  --set frontend.image.tag=v1.0.0 \
  -n todo-app
```

---

## Troubleshooting

### Issue: Better Auth login fails

**Symptoms**: 401 error on login, "Invalid credentials" message

**Diagnosis**:
```bash
# Check backend logs
kubectl logs deployment/backend-deployment -n todo-app | grep "Better Auth"

# Verify database connection
kubectl exec -it deployment/backend-deployment -n todo-app -- \
  python -c "from app.database import engine; print(engine.url)"

# Test bcrypt compatibility
kubectl exec -it deployment/backend-deployment -n todo-app -- \
  python -c "import bcrypt; print(bcrypt.hashpw(b'test', bcrypt.gensalt()))"
```

**Solution**:
1. Verify `BETTER_AUTH_SECRET` is set correctly
2. Check database connection string
3. Verify bcrypt is installed: `pip list | grep bcrypt`
4. Test with known good credentials

---

### Issue: ChatKit session creation fails

**Symptoms**: "Failed to get ChatKit session" error

**Diagnosis**:
```bash
# Check frontend logs
kubectl logs deployment/frontend-deployment -n todo-app | grep "ChatKit"

# Verify OpenAI API key
kubectl get secret todo-secrets -n todo-app -o jsonpath='{.data.OPENAI_API_KEY}' | base64 -d

# Test session endpoint
curl -X POST http://frontend-service:3000/api/chatkit/session \
  -H "Authorization: Bearer <jwt-token>" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test-user"}'
```

**Solution**:
1. Verify `OPENAI_API_KEY` is valid
2. Check network connectivity to OpenAI API
3. Verify JWT token is valid
4. Check CORS configuration

---

### Issue: Dual token validation not working

**Symptoms**: Both legacy and Better Auth tokens rejected

**Diagnosis**:
```bash
# Check backend logs
kubectl logs deployment/backend-deployment -n todo-app | grep "Token validation"

# Verify secrets
kubectl get secret todo-secrets -n todo-app -o yaml

# Test token validation
kubectl exec -it deployment/backend-deployment -n todo-app -- \
  python -c "from jose import jwt; print(jwt.decode('<token>', '<secret>', algorithms=['HS256']))"
```

**Solution**:
1. Verify both `JWT_SECRET` and `BETTER_AUTH_SECRET` are set
2. Check token format (Bearer prefix)
3. Verify token expiration
4. Check feature flag configuration

---

## Validation Checklist

### Better Auth Integration

- [ ] Better Auth dependencies installed
- [ ] Custom adapter implemented
- [ ] API route handler created
- [ ] Environment variables configured
- [ ] Login page updated
- [ ] Register page updated
- [ ] Existing users can log in
- [ ] New users can register
- [ ] JWT tokens include user_id in sub claim
- [ ] Backend accepts Better Auth tokens

### Dual Token Validation

- [ ] Dual validation function implemented
- [ ] Feature flags configured
- [ ] Legacy tokens accepted (during transition)
- [ ] Better Auth tokens accepted
- [ ] Invalid tokens rejected
- [ ] Logging implemented
- [ ] Metrics tracked
- [ ] Tests passing

### ChatKit Integration

- [ ] ChatKit dependencies installed
- [ ] ChatKit script added to layout
- [ ] Session endpoint implemented
- [ ] Chat page updated
- [ ] Feature flag toggle implemented
- [ ] Messages send correctly
- [ ] Conversation history loads
- [ ] New chat creation works
- [ ] Backend integration maintained

### Docker and Helm

- [ ] Docker images rebuilt
- [ ] Images loaded into Minikube
- [ ] Helm chart values updated
- [ ] ConfigMap created
- [ ] Deployment successful
- [ ] Pods running
- [ ] Services accessible
- [ ] Logs clean (no errors)

### Autonomous Testing

- [ ] Test scripts created
- [ ] API workflow tests pass
- [ ] Chatbot tests pass
- [ ] Test report generated
- [ ] 100% pass rate achieved
- [ ] Execution time < 15 minutes

---

## Success Criteria

✅ **All existing user accounts can log in with Better Auth**
✅ **New users can register via Better Auth**
✅ **ChatKit components render and function correctly**
✅ **All existing API endpoints work without modification**
✅ **Dual token validation accepts both token types**
✅ **Feature flags enable instant rollback**
✅ **Docker images rebuild successfully**
✅ **Helm chart deploys to Minikube**
✅ **Autonomous testing achieves 100% pass rate**
✅ **Implementation completes within 4-5 hours**

---

## Next Steps

After completing this quickstart:

1. **Monitor Production**: Track token usage, error rates, and user feedback
2. **Gradual Rollout**: Enable features for increasing percentages of users
3. **Deprecate Legacy**: After 7 days, disable legacy token validation
4. **Clean Up Code**: Remove old authentication and chat components
5. **Update Documentation**: Document new authentication and chat flows
6. **Phase V**: Proceed with next hackathon phase

---

**Quickstart Status**: ✅ Complete
**Estimated Time**: 4-5 hours
**Difficulty**: Medium
**Support**: Reference contracts in `specs/009-compliance-fixes/contracts/`
