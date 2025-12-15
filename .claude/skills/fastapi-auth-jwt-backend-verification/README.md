# Skill: fastapi-auth-jwt-backend-verification

## Purpose

This Skill teaches Claude a consistent, reusable way to secure FastAPI
backends with **JWT authentication**.

It standardizes:

- How to read the `Authorization: Bearer <token>` header.
- How to verify JWTs using a shared secret or public key/JWKS.
- How to map token payloads to a `CurrentUser` model.
- How to expose `get_current_user` as a FastAPI dependency and return
  correct 401/403 responses. [web:121][web:122][web:124][web:129]

The goal is that any FastAPI + JWT project can reuse the same pattern
instead of inventing new auth flows per repo.

## What this Skill defines

- **SKILL.md** – Rules and patterns for:

  - Token source and format (Authorization: Bearer).
  - Verification rules using secrets or JWKS.
  - A reusable `get_current_user` dependency.
  - Proper 401 vs 403 error semantics.
  - A `CurrentUser` model that represents the authenticated user.

- **Templates/**
  - `jwt-dependency.fastapi.tpl`  
    Standard FastAPI dependency module:

    - Uses `HTTPBearer` to extract the bearer token.
    - Verifies the JWT via `jose.jwt.decode(...)` using `JWT_SECRET` and
      `JWT_ALGORITHM` from env.
    - Maps the payload to `CurrentUser`.
    - Raises `HTTPException(401)` with `WWW-Authenticate: Bearer` on
      missing/invalid tokens.

  - `current_user_model.py.tpl`  
    Pydantic model representing the authenticated user:

    - Fields: `id`, `email`, `roles`, `raw_claims`.
    - Used as the type for `current_user` in dependencies and routes.

- **Examples/**
  - `jwt-flow.md`  
    Shows GOOD vs BAD JWT auth flow:

    - GOOD: central `CurrentUser` model, single `get_current_user`
      dependency, env-based secrets, consistent 401/403.
    - BAD: scattered token parsing, hard-coded secrets, inconsistent
      auth checks.

## When to enable this Skill

Enable/use this Skill in any backend project where:

- FastAPI is used as the web framework.
- Requests are authenticated via JWTs issued by:

  - Better Auth (with JWT plugin),
  - Auth0 or other OAuth/OpenID providers,
  - A custom identity service.

- You want Claude to:

  - Always build a clean `get_current_user` dependency.
  - Avoid inventing different JWT verification logic per route.
  - Use correct HTTP status codes and headers for auth failures. [web:121][web:122][web:129]

## How to integrate in a project

Typical integration steps:

1. Create `app/auth/models.py` from `current_user_model.py.tpl`:

   - Adjust field names if needed, but keep a stable `CurrentUser`.

2. Create `app/auth/jwt_dependency.py` from `jwt-dependency.fastapi.tpl`:

   - Set `JWT_SECRET` and `JWT_ALGORITHM` via environment variables.
   - Adapt `_payload_to_current_user` to match your issuer's claim names
     (e.g. `sub`, `user_id`, `email`, `roles`).

3. Configure your environment:

   - Set `JWT_SECRET` (or configure JWKS/issuer if using asymmetric keys).
   - Optionally define `JWT_ALGORITHM`, `JWT_ISSUER`, `JWT_AUDIENCE`.

4. Use `get_current_user` in protected routes:

```typscript
from fastapi import APIRouter, Depends
from app.auth.models import CurrentUser
from app.auth.jwt_dependency import get_current_user

router = APIRouter()

@router.get("/me")
async def read_me(current_user: CurrentUser = Depends(get_current_user)):
return current_user

```


5. For role/permission checks, build additional dependencies or decorators
that inspect `current_user.roles`.

After this, Claude should always follow the same JWT verification pattern
for FastAPI backends, making auth logic easier to reason about and reuse
across projects.
