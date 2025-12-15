# Skill: nextjs-better-auth-jwt-usage

## Purpose

This Skill teaches Claude a consistent, reusable way to use **Better Auth**
with **Next.js 16+ App Router** and **JWT tokens**.

It standardizes:

- How to configure Better Auth once for the entire app.
- How to expose an auth route handler under `/api/auth`.
- How to obtain a JWT for the current user (when needed).
- How to attach that JWT to frontend → backend API calls using the
  `Authorization: Bearer <token>` header.

The goal is that any Next.js + Better Auth project can reuse the same
pattern without inventing a new auth flow each time.

## What this Skill defines

- **SKILL.md** – Rules and patterns for:
  - Centralizing Better Auth configuration in a single module.
  - Enabling and using the Better Auth JWT plugin when a separate
    backend (e.g. FastAPI) needs to verify users.
  - Keeping JWT retrieval and header attachment in one place.
  - Protecting routes and accessing sessions on the server and client.

- **Templates/**
  - `auth-config.ts.tpl`  
    Standard Better Auth configuration file (e.g. `lib/auth-config.ts`):
    - Creates a shared `auth` instance.
    - Reads secret(s) from environment variables.
    - Provides a helper to get the current session/user on the server.

  - `auth-route-handler.ts.tpl`  
    Standard Next.js route handler (e.g. `app/api/auth/[...all]/route.ts`):
    - Mounts the Better Auth handler on a catch-all API route.
    - Delegates HTTP methods (GET/POST/PUT/PATCH/DELETE) to Better Auth.

  - `auth-jwt.ts.tpl`  
    JWT helper module (e.g. `lib/auth-jwt.ts`):
    - Exposes `getAuthTokenForCurrentUser()`.
    - Is the single place that knows how to obtain a JWT from Better Auth
      for the current session.

- **Examples/**
  - `basic-flow.md`  
    Shows GOOD vs BAD patterns:
    - GOOD: one `auth-config`, one route handler, one JWT helper, one
      shared API client that attaches the token.
    - BAD: multiple ad-hoc auth configs, scattered token handling, and
      inconsistent headers.

## When to enable this Skill

Enable/use this Skill in any Next.js App Router project where:

- You are using **Better Auth** for authentication.
- You plan to issue **JWT tokens** that a separate backend will verify.
- You want a clear, repeatable auth pattern across multiple projects
  instead of custom, one-off flows.

## How it works with other Skills

This Skill is designed to work together with:

- `nextjs-frontend-api-client-patterns`  
  The API client Skill can use `getAuthTokenForCurrentUser()` as the
  `getAuthToken` option in `createApiClient`, so all requests automatically
  attach the correct `Authorization` header.

- `nextjs-16-app-router-structure`  
  The App Router structure Skill defines where your `lib/` and `app/api`
  files live; this auth Skill plugs into that structure.

## Typical integration steps

1. Create `lib/auth-config.ts` from `auth-config.ts.tpl`.
2. Create `app/api/auth/[...all]/route.ts` from `auth-route-handler.ts.tpl`.
3. Create `lib/auth-jwt.ts` from `auth-jwt.ts.tpl`.
4. In your API client (e.g. `lib/api.ts`), call:

```typescript
import { getAuthTokenForCurrentUser } from "@/lib/auth-jwt";

const api = createApiClient({
baseUrl: API_BASE_URL,
getAuthToken: getAuthTokenForCurrentUser,
});
```


5. Use the API client from components and hooks; do not manually attach
tokens in every component.

After this, Claude should always follow the same Better Auth + JWT
pattern and avoid inventing new, inconsistent auth flows.
