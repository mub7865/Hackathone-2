# Requirements Checklist: Tasks API & Endpoints

**Purpose**: Track implementation progress against Success Criteria and Functional Requirements
**Created**: 2025-12-13
**Feature**: [spec.md](../spec.md) | [plan.md](../plan.md)

---

## Success Criteria Checklist

### SC-001: All 5 Endpoints Functional
- [ ] `GET /api/v1/tasks` returns 200 with task array
- [ ] `POST /api/v1/tasks` returns 201 with created task
- [ ] `GET /api/v1/tasks/{id}` returns 200 with single task
- [ ] `PATCH /api/v1/tasks/{id}` returns 200 with updated task
- [ ] `DELETE /api/v1/tasks/{id}` returns 204 No Content

### SC-002: Authentication Enforcement (401 Unauthorized)
- [ ] Missing `Authorization` header returns 401
- [ ] Invalid Bearer format returns 401
- [ ] Expired JWT returns 401
- [ ] Malformed JWT returns 401
- [ ] All 401 responses use RFC 7807 format

### SC-003: User Isolation
- [ ] User A cannot list User B's tasks
- [ ] User A cannot read User B's task (returns 404, not 403)
- [ ] User A cannot update User B's task (returns 404)
- [ ] User A cannot delete User B's task (returns 404)
- [ ] Multi-user test scenarios pass

### SC-004: Pagination
- [ ] Default pagination: offset=0, limit=20
- [ ] Custom offset/limit parameters work correctly
- [ ] `limit` clamped to max 100
- [ ] Negative offset returns 422
- [ ] Offset beyond total returns empty array

### SC-005: Status Filter
- [ ] `?status=pending` returns only pending tasks
- [ ] `?status=completed` returns only completed tasks
- [ ] No status param returns all tasks
- [ ] Invalid status value returns 422

### SC-006: Validation Errors (422 with RFC 7807)
- [ ] Missing required `title` on POST returns 422
- [ ] Empty `title` on POST returns 422
- [ ] Empty `title` on PATCH returns 422
- [ ] Invalid `status` value on PATCH returns 422
- [ ] Invalid UUID format in path returns 422
- [ ] All 422 responses include `errors` array with field details

### SC-007: Test Coverage (10+ Integration Tests)
- [ ] `test_tasks_list.py` - list endpoint tests
- [ ] `test_tasks_create.py` - create endpoint tests
- [ ] `test_tasks_get.py` - get single task tests
- [ ] `test_tasks_update.py` - update endpoint tests
- [ ] `test_tasks_delete.py` - delete endpoint tests
- [ ] `test_auth.py` - authentication error tests
- [ ] Total integration tests >= 10

### SC-008: Real Neon Database
- [ ] Tests use `DATABASE_URL` from environment
- [ ] Tests run against Neon Postgres (not SQLite)
- [ ] Test isolation via transaction rollback

### SC-009: Response Time (<500ms)
- [ ] Typical operations complete under 500ms
- [ ] Sanity check verified in test assertions or manual testing

---

## Functional Requirements Checklist

### Endpoints (FR-001 to FR-005)
- [ ] FR-001: `GET /api/v1/tasks` exposed
- [ ] FR-002: `POST /api/v1/tasks` exposed
- [ ] FR-003: `GET /api/v1/tasks/{id}` exposed
- [ ] FR-004: `PATCH /api/v1/tasks/{id}` exposed
- [ ] FR-005: `DELETE /api/v1/tasks/{id}` exposed

### Authentication (FR-006 to FR-007)
- [ ] FR-006: All endpoints require `Authorization: Bearer <token>`
- [ ] FR-007: 401 returned for missing/invalid/expired JWT

### Pagination (FR-008 to FR-009)
- [ ] FR-008: `offset` and `limit` query params supported
- [ ] FR-009: Defaults to offset=0, limit=20

### Filtering (FR-010 to FR-010a)
- [ ] FR-010: `status` query param with pending/completed
- [ ] FR-010a: Results sorted by `created_at DESC`

### Error Handling (FR-011 to FR-013)
- [ ] FR-011: All errors use RFC 7807 Problem Details
- [ ] FR-012: 404 for non-existent or other user's tasks
- [ ] FR-013: 422 for validation errors

### Response Behavior (FR-014 to FR-016)
- [ ] FR-014: POST returns 201 with Location header
- [ ] FR-015: DELETE returns 204 No Content
- [ ] FR-016: `user_id` auto-set from JWT `sub` claim

### Observability (FR-017)
- [ ] FR-017: Structured JSON logs emitted per request
- [ ] Logs include: request_id, user_id, endpoint, status, duration

---

## Implementation Files Checklist

### New Files
- [ ] `phase2/backend/app/main.py`
- [ ] `phase2/backend/app/schemas/__init__.py`
- [ ] `phase2/backend/app/schemas/task.py`
- [ ] `phase2/backend/app/schemas/error.py`
- [ ] `phase2/backend/app/api/__init__.py`
- [ ] `phase2/backend/app/api/deps.py`
- [ ] `phase2/backend/app/api/v1/__init__.py`
- [ ] `phase2/backend/app/api/v1/router.py`
- [ ] `phase2/backend/app/api/v1/tasks.py`
- [ ] `phase2/backend/app/core/__init__.py`
- [ ] `phase2/backend/app/core/auth.py`
- [ ] `phase2/backend/app/core/exceptions.py`
- [ ] `phase2/backend/app/core/logging.py`

### Modified Files
- [ ] `phase2/backend/pyproject.toml` (add python-jose)
- [ ] `phase2/backend/app/config.py` (add JWT settings)
- [ ] `phase2/backend/tests/conftest.py` (add auth fixtures)

### Test Files
- [ ] `phase2/backend/tests/integration/__init__.py`
- [ ] `phase2/backend/tests/integration/conftest.py`
- [ ] `phase2/backend/tests/integration/test_tasks_list.py`
- [ ] `phase2/backend/tests/integration/test_tasks_create.py`
- [ ] `phase2/backend/tests/integration/test_tasks_get.py`
- [ ] `phase2/backend/tests/integration/test_tasks_update.py`
- [ ] `phase2/backend/tests/integration/test_tasks_delete.py`
- [ ] `phase2/backend/tests/integration/test_auth.py`

---

## Specification Quality

### Content Quality
- [x] Implementation approach defined in plan.md
- [x] Focused on API behavior and contracts
- [x] All mandatory sections completed
- [x] Clarifications documented

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable (9 criteria)
- [x] All acceptance scenarios defined (5 user stories)
- [x] Edge cases identified (6 cases)
- [x] Scope clearly bounded (13 non-goals)
- [x] Dependencies identified (5 dependencies)

### Feature Readiness
- [x] All functional requirements have acceptance criteria
- [x] User scenarios cover CRUD flows
- [x] API contract documented (OpenAPI spec)
- [x] Pydantic schemas defined

---

## Notes

- JWT claim uses `sub` (RFC 7519 standard) per clarification session
- Structured JSON logging required per FR-017
- Default sort order: `created_at DESC` per FR-010a
- User isolation enforced via 404 (not 403) to prevent enumeration
- Max pagination limit: 100 items
