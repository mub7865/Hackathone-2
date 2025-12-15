# Research: Tasks API & Endpoints

**Feature**: 003-tasks-crud-api
**Date**: 2025-12-13
**Status**: Complete

---

## Research Topics

### 1. JWT Library Selection

**Decision**: `python-jose[cryptography]`

**Rationale**:
- Industry standard for JWT in Python
- Supports HS256 (symmetric) and RS256 (asymmetric) algorithms
- Better Auth typically uses HS256 for simplicity
- Well-maintained, widely adopted
- Pydantic-friendly (returns dict from decode)

**Alternatives Considered**:
| Library | Pros | Cons | Verdict |
|---------|------|------|---------|
| PyJWT | Simpler API, lightweight | Less cryptographic flexibility | Good but python-jose more feature-complete |
| authlib | Full OAuth2 support | Overkill for JWT-only validation | Too heavy |
| python-jose | Industry standard, crypto support | Slightly more deps | ✅ Selected |

**Installation**:
```bash
uv add "python-jose[cryptography]"
```

---

### 2. JWT Validation Strategy

**Decision**: Decode token → verify signature → extract `sub` claim

**Rationale**:
- Better Auth follows RFC 7519, using `sub` (subject) for user identifier
- Signature verification ensures token integrity
- `sub` claim contains the user's UUID from Better Auth

**Token Structure Expected**:
```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "iat": 1702483200,
  "exp": 1702569600,
  "iss": "better-auth"
}
```

**Validation Steps**:
1. Extract `Authorization: Bearer <token>` header
2. Decode JWT with secret key
3. Verify expiration (`exp` claim)
4. Extract `sub` as `user_id`
5. Return `user_id` to route handler

**Error Cases**:
| Scenario | HTTP Status | Response |
|----------|-------------|----------|
| No Authorization header | 401 | Missing authentication |
| Invalid Bearer format | 401 | Invalid authentication |
| Expired token | 401 | Token expired |
| Invalid signature | 401 | Invalid token |
| Missing `sub` claim | 401 | Invalid token payload |

---

### 3. Error Handling Pattern

**Decision**: FastAPI exception handlers with RFC 7807 Problem Details

**Rationale**:
- FastAPI's exception handlers integrate natively with request lifecycle
- RFC 7807 provides machine-readable, consistent error format
- Custom exceptions map to specific HTTP status codes

**Implementation Pattern**:
```python
class TaskNotFoundError(Exception):
    pass

@app.exception_handler(TaskNotFoundError)
async def task_not_found_handler(request: Request, exc: TaskNotFoundError):
    return JSONResponse(
        status_code=404,
        content={
            "type": "about:blank",
            "title": "Not Found",
            "status": 404,
            "detail": str(exc),
            "instance": str(request.url.path)
        }
    )
```

**Exception Mapping**:
| Exception | Status | Title |
|-----------|--------|-------|
| `AuthenticationError` | 401 | Unauthorized |
| `ValidationError` (Pydantic) | 422 | Unprocessable Entity |
| `TaskNotFoundError` | 404 | Not Found |
| `RequestValidationError` | 422 | Validation Error |
| Generic `Exception` | 500 | Internal Server Error |

---

### 4. Structured Logging Approach

**Decision**: Python stdlib logging with JSON formatter (or structlog for richer features)

**Rationale**:
- Structured JSON logs are required per FR-017
- Need: request_id, user_id, endpoint, status, duration
- FastAPI middleware can wrap request lifecycle

**Minimal Implementation** (stdlib):
```python
import logging
import json
from uuid import uuid4
from time import perf_counter

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_data = {
            "timestamp": self.formatTime(record),
            "level": record.levelname,
            "message": record.getMessage(),
            **getattr(record, "extra", {})
        }
        return json.dumps(log_data)
```

**Middleware Pattern**:
```python
@app.middleware("http")
async def logging_middleware(request: Request, call_next):
    request_id = str(uuid4())
    start = perf_counter()
    response = await call_next(request)
    duration_ms = (perf_counter() - start) * 1000

    logger.info("request", extra={
        "request_id": request_id,
        "user_id": getattr(request.state, "user_id", None),
        "endpoint": request.url.path,
        "method": request.method,
        "status": response.status_code,
        "duration_ms": round(duration_ms, 2)
    })
    return response
```

**Alternative**: `structlog` provides richer context binding but adds dependency. For Phase II, stdlib is sufficient.

---

### 5. Test Authentication Strategy

**Decision**: Mock JWT with known `sub` claim for testing

**Rationale**:
- Integration tests should not depend on real Better Auth service
- Generate valid JWTs with test secret for predictable user IDs
- Test fixtures provide authenticated requests

**Test Fixture Pattern**:
```python
import pytest
from jose import jwt

TEST_SECRET = "test-secret-key"
TEST_USER_ID = "test-user-123"

@pytest.fixture
def auth_headers():
    token = jwt.encode(
        {"sub": TEST_USER_ID, "exp": datetime.utcnow() + timedelta(hours=1)},
        TEST_SECRET,
        algorithm="HS256"
    )
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def other_user_headers():
    token = jwt.encode(
        {"sub": "other-user-456", "exp": datetime.utcnow() + timedelta(hours=1)},
        TEST_SECRET,
        algorithm="HS256"
    )
    return {"Authorization": f"Bearer {token}"}
```

**Test Configuration**:
- Set `JWT_SECRET=test-secret-key` in test environment
- Use `httpx.AsyncClient` with FastAPI's `TestClient`
- Real Neon test database for data operations

---

### 6. Pagination Implementation

**Decision**: Offset/limit with defaults and max limits

**Rationale**:
- Simple, well-understood pattern
- Default: offset=0, limit=20
- Max limit: 100 (prevent excessive queries)

**Query Parameters**:
```python
@router.get("/tasks")
async def list_tasks(
    offset: int = Query(0, ge=0, description="Number of items to skip"),
    limit: int = Query(20, ge=1, le=100, description="Max items to return"),
    status: TaskStatus | None = Query(None, description="Filter by status"),
    ...
):
```

**SQL Translation**:
```sql
SELECT * FROM task
WHERE user_id = :user_id
  AND (status = :status OR :status IS NULL)
ORDER BY created_at DESC
OFFSET :offset
LIMIT :limit
```

---

## Dependencies to Add

```toml
# pyproject.toml additions
dependencies = [
    # ... existing ...
    "python-jose[cryptography]>=3.3.0",
]
```

---

## Open Items Resolved

| Item | Resolution |
|------|------------|
| JWT claim name | `sub` (confirmed in spec clarifications) |
| Logging format | Structured JSON via middleware |
| Test auth | Mock JWT with test secret |
| Pagination | Offset/limit, max 100 |

---

## Conclusion

All technical decisions are validated. Ready for Phase 1 design artifacts.
