---
name: fastapi-auth-jwt-backend-verification
description: >
  Standard pattern for verifying JWTs in FastAPI backends: read the
  Authorization header, validate the token with a secret or JWKS, and
  inject the current user into request handlers.
---

# FastAPI JWT Backend Verification Skill

## When to use this Skill

Use this Skill whenever you are:

- Securing FastAPI routes with JWT-based authentication.
- Verifying tokens issued by a separate auth system (e.g. Better Auth,
  Auth0, custom identity provider).
- Implementing dependencies like `get_current_user` or auth middleware.
- Returning proper 401/403 responses when auth fails. [web:121][web:122][web:124][web:129]

This Skill must work for any FastAPI + JWT backend, not just one project.

## Core goals

- Read JWTs from the `Authorization: Bearer <token>` header.
- Validate tokens using a shared secret or JWKS, according to the issuer.
- Extract user identity (e.g. `sub`, `user_id`, `email`, roles/claims).
- Provide a reusable dependency (e.g. `get_current_user`) used in routes.
- Return consistent 401/403 errors for missing/invalid/unauthorized cases.

## Token source and format

- Tokens are expected in the HTTP header:

  - `Authorization: Bearer <jwt-token>`

- The JWT payload should include at least:

  - A stable user identifier (e.g. `sub`, `user_id`).
  - Optional claims like `email`, `scope`, `roles`, `exp`. [web:121][web:124]

- The exact claim names depend on the issuer; keep mapping logic in one
  place (e.g. an adapter function).

## Verification rules

- When using an HMAC secret (symmetric key):

  - Read the secret from an environment variable (e.g. `JWT_SECRET`).
  - Use the same algorithm used by the issuer (e.g. `HS256`).
  - Verify signature and standard claims (`exp`, `nbf`, `iat`) according
    to library defaults. [web:121][web:122][web:124]

- When using JWKS / public keys (asymmetric):

  - Read the issuer (`iss`) and JWKS URL from environment/config.
  - Cache keys according to best practices of the chosen library.
  - Verify `aud`, `iss`, and other registered claims as required.

- Never hard-code secrets or JWKS URLs in code.

## FastAPI dependency pattern

- Implement a reusable dependency, for example:

  - `get_current_user(token: str = Depends(oauth2_scheme))` OR
  - `get_current_user(request: Request)` that reads the header manually.

- This dependency should:

  - Extract the bearer token from the header.
  - Verify the JWT.
  - Decode payload and map it to a user object/model (Pydantic/SQLModel).
  - Raise `HTTPException(status_code=401)` if:

    - The header is missing.
    - The token is malformed.
    - Verification fails.

  - Optionally raise `HTTPException(status_code=403)` if the user is
    authenticated but not allowed to access a resource (e.g. role/owner
    mismatch). [web:121][web:122][web:124][web:129]

- Routes should depend on this function:

  - `def protected_route(current_user: User = Depends(get_current_user))`

## Error handling

- On missing or invalid token:

  - Return `401 Unauthorized` with a clear, generic message.
  - Include a `WWW-Authenticate: Bearer` header when appropriate. [web:121][web:122]

- On forbidden access (user authenticated but not allowed):

  - Return `403 Forbidden` with a clear message.

- Do not leak sensitive details about why token verification failed
  (invalid signature, key id, etc.) in client-facing messages.

## User identity model

- Define a small Pydantic model (e.g. `CurrentUser`) to represent the
  user extracted from the token:

  - Minimal fields: `id` (or `sub`), maybe `email`, `roles`.
  - This model is used as the type for `current_user` in dependencies.

- Map JWT claims → `CurrentUser` in one place; do not repeat mapping in
  multiple routes.

## Integration with external issuers (Better Auth, Auth0, etc.)

- Keep issuer-specific logic isolated:

  - For Better Auth JWTs, use the secret / JWKS config indicated by the
    Better Auth setup.
  - For Auth0 or other providers, follow their recommended validation
    pattern (issuer, audience, JWKS). [web:124][web:126][web:129]

- The rest of the FastAPI app should not care who issued the token; it
  should rely on the `CurrentUser` model and `get_current_user`
  dependency.

## Things to avoid

- Parsing JWTs without verifying signatures.
- Accepting tokens from multiple unrelated issuers in the same logic
  without clear separation.
- Duplicating token parsing/verification logic in every route.
- Returning 200 with an error body for auth failures instead of using
  401/403.

## References inside the repo

When present, this Skill should align with:

- A config module providing:

  - `JWT_SECRET` or JWKS config (issuer URL, audience, etc.).
  - Any auth-related settings.

- A dedicated auth module, e.g. `app/auth/jwt.py`, that exposes:

  - `verify_token()` / `decode_token()` helpers.
  - `get_current_user()` FastAPI dependency.
  - `CurrentUser` model.

If these are missing, propose creating them using this pattern instead
of inventing a new ad-hoc JWT verification flow.
