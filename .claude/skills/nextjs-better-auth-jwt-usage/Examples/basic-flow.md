# Better Auth + JWT Basic Flow (Example)

## GOOD: Centralized, predictable auth flow

- A single auth config exists at `lib/auth-config.ts`:
  - Creates the Better Auth instance with secrets and plugins.
  - Enables the JWT plugin if an external backend needs tokens.

- Auth HTTP handling is mounted in one place:
  - `app/api/auth/[...all]/route.ts` uses the shared `auth` instance.

- JWT logic is centralized:
  - `lib/auth-jwt.ts` exports `getAuthTokenForCurrentUser()`.
  - This function is the *only* place that knows how to obtain a JWT
    from Better Auth for the current user.

- Frontend → backend API calls use a shared client:
  - `lib/api-config.ts` defines `API_BASE_URL`.
  - `lib/api.ts` creates `api = createApiClient({ baseUrl: API_BASE_URL, getAuthToken: getAuthTokenForCurrentUser })`.
  - Components and hooks call functions like `api.getTasks()` or use
    domain hooks built on top of the client.

Result:

- Auth configuration is easy to find and reason about.
- JWT handling is consistent across all API calls.
- Changing how tokens are issued or validated only requires changes
  in `auth-config.ts` and `auth-jwt.ts`, not in every component.

## BAD: Scattered, ad-hoc auth and tokens

- Multiple files create their own Better Auth instances with slightly
  different options or secrets.
- Some auth routes are handled via Better Auth, others via custom
  `fetch` calls to random endpoints.
- JWT tokens are:
  - Manually requested in many different components.
  - Stored in localStorage in some places, cookies in others.
  - Attached to requests with inconsistent header names.

- Frontend components directly read environment variables or cookies
  for tokens and manually build `Authorization` headers.

Result:

- Hard to audit which parts of the app are truly authenticated.
- Easy to introduce subtle bugs (wrong secret, wrong token format).
- Very difficult to rotate secrets, update token structure, or migrate
  to a different backend without breaking multiple code paths.
