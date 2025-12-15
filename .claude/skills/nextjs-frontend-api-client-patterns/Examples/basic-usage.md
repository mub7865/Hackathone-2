# Basic API Client Usage (Example)

## GOOD: Centralized API client

- All HTTP calls go through a shared client module, e.g. `@/lib/api.ts`.
- Components and hooks only call typed functions like `getTasks()` and `createTask(payload)`.
- Errors are normalized into a common `ApiError` shape.
- Auth headers (e.g. `Authorization: Bearer <token>`) are attached inside the client,
  not manually in each component.
- The API base URL comes from a single config file (e.g. `@/lib/api-config.ts`),
  not hard-coded strings.

Example pattern:

- `lib/api-config.ts` → exports `API_BASE_URL`.
- `lib/api.ts` → builds `api = createApiClient({ baseUrl: API_BASE_URL, getAuthToken })`.
- `hooks/useTasks.ts` → uses `useApiRequest(api.getTasks)` to manage loading/error/data.

## BAD: Scattered fetch calls

- Every page or component calls `fetch("/api/...")` directly.
- Each component builds its own headers and error handling.
- Some components forget to attach the auth token or use different header names.
- URLs and paths are duplicated and slightly different across the app.
- Types are missing or everything is typed as `any`.

This leads to:

- Inconsistent behaviour when the backend changes.
- Hard-to-maintain error handling.
- Subtle auth bugs that are difficult to debug.
