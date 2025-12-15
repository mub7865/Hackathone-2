# Neon Postgres + Migrations Basic Flow (Example)

## GOOD: Env-based config + migrations-first

- The application has a central DB config module (e.g. `app/db.py`):
  - Reads `DATABASE_URL` from the environment.
  - Creates a single engine or pool (for long-running app servers).
  - Exposes `metadata` for migrations.

- Alembic is configured to use the same URL and metadata:
  - `alembic.ini` has a placeholder URL that is overridden in `env.py`.
  - `alembic/env.py` reads `DATABASE_URL` from the environment and sets
    `config.set_main_option("sqlalchemy.url", ...)`.
  - `target_metadata` is imported from the app’s ORM models.

- Migration workflow:
  - Developer updates ORM models (SQLModel/SQLAlchemy).
  - Runs Alembic to autogenerate a migration (if appropriate).
  - Reviews and edits the migration script if needed.
  - Applies migrations with Alembic commands against the Neon database.

- Application startup:
  - Assumes the schema is already up to date.
  - Uses the shared engine and session helpers.
  - Does not call `create_all()` in production paths.

Result:

- One source of truth for DB URL (the environment).
- Schema changes are tracked and reversible.
- Application and migrations are always in sync.

## BAD: Hard-coded URLs + ad-hoc schema changes

- Connection details are hard-coded:
  - `create_engine("postgresql://user:pass@neon-host/db")` scattered
    in multiple files.
  - Different URLs used in app code and in migration scripts.

- Schema is managed ad-hoc:
  - Application calls `metadata.create_all()` on every startup.
  - Columns are added or removed directly in the database using a GUI
    or manual SQL, without migrations.
  - Alembic (if used) is not updated to reflect the actual database
    state.

- Neon-specific behaviour is ignored:
  - No `pool_pre_ping` or equivalent to handle idle connections.
  - Too many engines or pools are created, exhausting connection limits.

Result:

- Difficult to reproduce or revert schema changes.
- Risk of mismatches between code models and actual database schema.
- Fragile connections that occasionally fail when Neon scales to zero
  or drops idle connections.
