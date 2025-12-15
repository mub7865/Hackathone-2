# Skill: nextjs-frontend-api-client-patterns

## Purpose

This Skill teaches Claude a consistent, reusable way to call HTTP/REST
APIs from any Next.js 16+ App Router frontend.

Instead of scattering raw `fetch` calls, it enforces:

- A single, shared API client module.
- Strongly typed requests and responses.
- Centralized error handling.
- Centralized auth header handling.
- A single source of truth for API base URL and configuration.

The goal is that future projects can reuse the same pattern without
reinventing API access every time.

## What this Skill defines

- **SKILL.md** – Rules and patterns for:
  - Where the API client lives (e.g. `lib/api.ts`).
  - How to type requests and responses.
  - How to handle errors in a consistent way.
  - How to attach auth tokens in one place.
  - How to separate server and client usage.

- **Templates/**
  - `api-client.ts.tpl` – Standard `createApiClient` implementation using `fetch`,
    with a typed `request` wrapper and a shared `ApiError` model.
  - `use-api-request.ts.tpl` – Generic React hook that wraps any async API
    function with `loading`, `error`, and `data` state for client components.
  - `api-config.ts.tpl` – Central configuration for `API_BASE_URL` and
    environment-dependent API settings.

- **Examples/**
  - `basic-usage.md` – Shows GOOD vs BAD patterns:
    - GOOD: central `api.ts` + config + hooks.
    - BAD: scattered `fetch` calls, duplicated URLs, inconsistent headers.

## When to enable this Skill

Enable/use this Skill in any Next.js App Router project where:

- The frontend talks to a backend via HTTP/REST/JSON.
- You want a clean, predictable API layer that can be reused across
  multiple projects.
- You want Claude to stop inventing new ad-hoc ways of calling the
  backend and always follow the same client pattern.

## How to integrate in a project

Typical integration steps:

1. Create a config file (e.g. `lib/api-config.ts`) using the template.
2. Create a shared client (e.g. `lib/api.ts`) using `createApiClient(...)`.
3. Build domain-specific hooks (e.g. `useTasks`, `useUserProfile`) on top
   of the client using the `useApiRequest` template.
4. In components and pages, only call the domain hooks or functions from
   the shared API client module.

After this, Claude should always use the same structure for new API
endpoints and avoid hallucinated, one-off HTTP code.
