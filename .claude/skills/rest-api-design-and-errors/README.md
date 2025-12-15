# Skill: rest-api-design-and-errors

## Purpose

Ye Skill framework-agnostic **REST API design rules** define karta hai jo
har backend stack (FastAPI, Express, NestJS, Django REST, waghera) par
apply ho sakte hain.

Focus areas:

- Resource naming (plural nouns, nesting, verbs avoid).
- HTTP methods ka sahi istemal (GET/POST/PUT/PATCH/DELETE).
- Pagination, filtering, sorting ka standard query param pattern.
- Status code mapping (2xx/4xx/5xx, 400 vs 404 vs 409 vs 422, 401 vs 403).
- Standardized error JSON format using Problem Details (RFC 7807-style
  `application/problem+json`).

Goal ye hai ke jab bhi tum kisi bhi project me “REST API banao” bolo,
Claude hamesha **same conventions** follow kare — chahe underlying
framework kuch bhi ho.

## What this Skill defines

- **SKILL.md**

  - Global principles for REST resource modeling.
  - URL structure aur versioning (`/api/v1/...` default).
  - HTTP method semantics (safe, idempotent, partial vs full update).
  - Pagination (`page`, `page_size`), filtering (simple query params ya `filter[...]`), aur sorting (`sort`).
  - Status codes mapping for common scenarios (auth, validation, not found, conflict).
  - Problem Details error object (`type`, `title`, `status`, `detail`, `instance`, optional `errors`).

- **Templates/**

  - `problem-details-schema.generic.tpl`

    - Generic RFC 7807-style error schema documentation.
    - Shows required fields plus optional `errors` array for validation.
    - Framework-agnostic; kisi bhi stack ke design doc me embed kiya ja sakta hai.

  - `fastapi-problem-details-handler.py.tpl`

    - FastAPI ke liye standard error-handling module.
    - Central exception handlers jo:
      - `HTTPException` ko Problem Details JSON me map karte hain.
      - `RequestValidationError` / `ValidationError` ko `422` + `errors[]` ke sath return karte hain.
      - `application/problem+json` content-type set karte hain.

  - `express-problem-details-middleware.js.tpl`

    - Node/Express ke liye global error-handling middleware.
    - `(err, req, res, next)` pattern follow karta hai.
    - `statusCode` / `status` / `type` / `errors` fields support karta hai.
    - Saare errors ko Problem Details JSON format me convert karta hai.

- **Examples/**

  - `rest-api-good-vs-bad.md`

    - GOOD vs BAD REST API examples:
      - Good: `/api/v1/users/{user_id}/tasks` pattern, correct methods, predictable pagination and Problem Details errors.
      - Bad: verb-based paths, wrong methods, arbitrary JSON error shapes.

## When to enable this Skill

Ye Skill tab enable hona chahiye jab:

- Kisi bhi project me REST API endpoints design / implement ho rahe hon.
- Koi framework-specific backend Skill already on ho (e.g. FastAPI CRUD patterns).
- Tum consistent status codes aur error bodies chahte ho across microservices
  ya multiple projects.

Specially useful:

- Multi-frontend ecosystems (web, mobile, other services) jahan ek hi REST
  contract ko multiple clients use karte ho.
- Jab tum auth Skill (JWT verification) ya CRUD Skill ke sath proper 401/403/404/422
  behavior enforce karna chahte ho.

## How other Skills should use it

- **FastAPI Skills**:

  - `fastapi-sqlmodel-crud-patterns` ya JWT Skills ko:
    - Resource paths aur methods SKILL.md me defined rules ke mutabiq choose karne chahiye.
    - `fastapi-problem-details-handler.py.tpl` se central handlers register karne chahiye.
    - Sab `HTTPException` aise raise karne chahiye ke woh Problem Details format me map ho saken.

- **Express / Node Skills**:

  - REST API banaate waqt:
    - `express-problem-details-middleware.js.tpl` ko global error middleware ki tarah use karo.
    - Routes me `next(err)` call karo, aur error objects me `statusCode`, `type`, `errors` jaise fields set karo jab zaroorat ho.

- **Generic REST Skills / Other Frameworks**:

  - Agar koi naya framework use ho (Django REST, NestJS, etc.),
    to unke liye bhi Problem Details-based central handler / filter likhna chahiye,
    lekin **error JSON shape yahi rahe**.

## Design guarantees

Agar ye Skill active ho:

- Resource naming predictable hoti hai (plural nouns, nested ownership,
  versioned base paths).
- Clients hamesha:
  - Same pagination fields (`page`, `page_size`, `total`) expect kar sakte hain.
  - Same error fields par rely kar sakte hain (`type`, `title`, `status`,
    `detail`, `instance`, optional `errors`).
- Status code semantics har project me same rehte hain, jisse debugging,
  logging, aur monitoring simplify ho jaate hain.

Is se tum future me multiple microservices aur clients ke beech ek **stable,
uniform REST contract** maintain kar sakte ho, bina har repo me design ko
dobara sochne ke.
