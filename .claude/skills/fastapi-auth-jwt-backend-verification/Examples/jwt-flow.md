# FastAPI JWT Auth Flow (Example)

## GOOD: Centralized, predictable JWT verification

- A config or env-based setup provides:

  - `JWT_SECRET` (or keys / JWKS URL) via environment variables.
  - `JWT_ALGORITHM` (e.g. HS256) via environment or config.

- Auth models and helpers live in `app/auth/`:

  - `app/auth/models.py` defines `CurrentUser`.
  - `app/auth/jwt_dependency.py` defines:
    - `_extract_token_from_auth_header(...)`
    - `_decode_and_verify_jwt(...)`
    - `_payload_to_current_user(...)`
    - `get_current_user(...)` FastAPI dependency.

- Routes use `get_current_user` as a dependency:

```typescript
@router.get("/me")
async def read_me(current_user: CurrentUser = Depends(get_current_user)):
return current_user
```


- Error behaviour:

- Missing or malformed Authorization header → 401 Unauthorized.
- Invalid or expired token → 401 Unauthorized.
- Authenticated but not allowed (e.g. role mismatch) → 403 Forbidden.
- `WWW-Authenticate: Bearer` header is returned on 401. [web:121][web:122]

Result:

- JWT verification logic is in **one place**.
- All protected routes share the same auth behaviour.
- Changing token structure or verification rules is localized.

## BAD: Scattered, ad-hoc JWT handling

- Multiple routes manually:

- Read the Authorization header directly from `request.headers`.
- Call `jwt.decode(...)` without verification options or shared config.
- Parse claims differently in each endpoint.

- Some routes forget to check auth at all, or:

- Accept tokens from query parameters or request bodies.
- Return 200 with an `"error": "invalid token"` body instead of 401.

- Secrets or issuer details are hard-coded:

- `jwt.decode(token, "super-secret", algorithms=["HS256"])` inline.
- Different secrets used in different files.

Result:

- Inconsistent security posture.
- Difficult to rotate keys or change issuers.
- Easy to introduce subtle bugs where some endpoints are less secure.
