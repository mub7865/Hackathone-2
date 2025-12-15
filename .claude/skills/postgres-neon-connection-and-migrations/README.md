# Skill: postgres-neon-connection-and-migrations

## Purpose

This Skill teaches Claude a consistent, reusable way to:

- Connect applications to **Neon Postgres** using environment-based URLs.
- Configure engines/pools correctly for Neon’s serverless behaviour.
- Manage schema changes with a proper **migrations-first** workflow
  (e.g. Alembic with SQLModel/SQLAlchemy).

The goal is that any Neon-backed project can reuse the same connection
and migration patterns instead of reinventing them in each repo.

## What this Skill defines

- **SKILL.md** – Rules and patterns for:
  - Reading the Neon connection string from environment variables
    (`DATABASE_URL` or similar).
  - Creating a single, reusable engine/pool for long-running app
    servers, and adapting patterns for serverless runtimes.
  - Handling Neon-specific behaviours (scaling-to-zero, connection
    pooling, idle connection drops).
  - Treating schema changes as code, managed via migrations rather than
    ad-hoc `CREATE TABLE` calls.

- **Templates/**
  - `neon-db-config.sqlmodel.tpl`  
    Standard Python + SQLModel database config module:
    - Reads `DATABASE_URL` from the environment.
    - Creates a singleton engine with `pool_pre_ping` enabled for Neon.
    - Exposes `init_db()` for dev/tests.
    - Re-exports `metadata = SQLModel.metadata` for migration tools.

  - `alembic-env.neon.sqlmodel.tpl`  
    Example Alembic `env.py` for Neon + SQLModel:
    - Reads `DATABASE_URL` from the same env var used by the app.
    - Sets `config.set_main_option("sqlalchemy.url", ...)`.
    - Uses the app’s `metadata` as `target_metadata` for autogenerate.
    - Configures offline and online migrations with `compare_type=True`.

- **Examples/**
  - `migration-flow.md`  
    Shows GOOD vs BAD patterns:
    - GOOD: single env-based URL, central DB config, Alembic migrations
      driven by ORM models.
    - BAD: hard-coded URLs, `create_all()` in production, manual schema
      edits in the DB, ignoring Neon’s serverless connection details.

## When to enable this Skill

Enable/use this Skill in any backend project where:

- Your Postgres database is hosted on **Neon** (serverless Postgres).
- You are using SQLModel/SQLAlchemy (e.g. with FastAPI) and need a
  reliable DB config.
- You want a clean, repeatable migrations workflow (Alembic or similar)
  that stays in sync with your models.

It is especially useful for apps that:

- Run as long-lived API servers (FastAPI, Node, etc.) and need to reuse
  a single engine/pool.
- May later run in serverless environments and must respect Neon’s
  connection pooling recommendations.

## How to integrate in a project

Typical integration steps:

1. Create a DB config module (e.g. `app/db.py`) from
   `neon-db-config.sqlmodel.tpl`:
   - Ensure `DATABASE_URL` points to your Neon database.
   - Use `get_engine()` and a separate session helper (e.g. `get_session`)
     in your app.

2. Initialize Alembic (if not already present), then adapt `alembic/env.py`
   using `alembic-env.neon.sqlmodel.tpl`:
   - Import `NEON_DATABASE_URL_ENV` and `metadata` from your DB module.
   - Let Alembic read the same `DATABASE_URL` env var.

3. Define or update your ORM models (SQLModel/SQLAlchemy) and run Alembic
   migrations to apply schema changes to Neon.

4. In your application code, assume the schema is managed by migrations
   and avoid calling `create_all()` on production startup paths.

After this, Claude should always propose Neon connection and migration
code that follows the same safe, serverless-aware patterns.
