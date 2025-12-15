# Skill: fastapi-sqlmodel-crud-patterns

## Purpose

This Skill teaches Claude a consistent, reusable way to build CRUD
(Create, Read, Update, Delete) APIs using **FastAPI** and **SQLModel**.

It standardizes:

- How to configure the database engine and session dependency.
- How to structure models, routers, and endpoints.
- How to implement common CRUD operations.
- How to handle errors and write basic tests.

The goal is that any FastAPI + SQLModel project can reuse the same
patterns without inventing a new CRUD style each time.

## What this Skill defines

- **SKILL.md** – Rules and patterns for:
  - Organizing FastAPI projects using `db.py`, `models/`, and `routers/`.
  - Defining SQLModel models and optional Create/Update/Read schemas.
  - Implementing RESTful endpoints with clear HTTP verbs and paths.
  - Using a shared `get_session()` dependency for database access.
  - Handling errors with `HTTPException` and consistent status codes.

- **Templates/**
  - `db-session.sqlmodel.tpl`  
    Standard database module:
    - Reads `DATABASE_URL` from environment variables.
    - Creates a single SQLModel engine.
    - Exposes `init_db()` to create tables (useful for dev/tests).
    - Exposes `get_session()` as the FastAPI dependency for `Session`.

  - `crud-router.fastapi.tpl`  
    Generic CRUD router skeleton:
    - Defines a resource router with `APIRouter(prefix="/resources")`.
    - Implements list, create, get, update, and delete endpoints.
    - Uses a helper like `_get_resource_or_404()` to centralize lookups.
    - Designed to be adapted per resource (Task, Item, Project, etc.).

  - `crud-tests.py.tpl`  
    Basic pytest template:
    - Sets up a test client with an in-memory database.
    - Overrides `get_session()` for tests.
    - Includes example tests for create, list, and not-found cases.

- **Examples/**
  - `basic-crud.md`  
    Shows GOOD vs BAD CRUD patterns:
    - GOOD: shared `db.py`, models in one place, routers per resource,
      RESTful paths (`/tasks`, `/tasks/{id}`), consistent error handling.
    - BAD: ad-hoc connections in every route, inconsistent endpoints
      like `/createTask`, `/getAllTasks`, random error responses.

## When to enable this Skill

Enable/use this Skill in any backend project where:

- You are using **FastAPI** with **SQLModel** for a relational database.
- You need to implement or refactor CRUD endpoints for one or more
  resources.
- You want Claude to follow a clean, predictable CRUD style instead of
  generating different patterns for each resource.

## How to integrate in a project

Typical integration steps:

1. Create a database module (e.g. `app/db.py`) from
   `db-session.sqlmodel.tpl`:
   - Configure the engine with `DATABASE_URL`.
   - Use `get_session()` in routers with `Depends(get_session)`.

2. Define your SQLModel models and optional schemas in `app/models.py`
   or `app/models/`.

3. For each resource, create a router (e.g. `app/routers/tasks.py`) from
   `crud-router.fastapi.tpl`:
   - Replace `Resource`, `ResourceCreate`, `ResourceUpdate`, and
     `/resources` with your domain names and paths.

4. Register routers in your `main.py` FastAPI app.

5. Set up tests using `crud-tests.py.tpl`, adjusting resource names,
   payloads, and URLs.

After this, Claude should consistently generate CRUD code that matches
the same structure, making your FastAPI + SQLModel backends easier to
maintain and extend.
