# Research: Core Data & Domain Model

**Feature**: 002-core-data-model
**Date**: 2025-12-12
**Purpose**: Resolve technical unknowns and document best practices before implementation

---

## Research Questions

### RQ-1: SQLModel with Neon Postgres

**Question**: What is the recommended way to configure SQLModel for async operations with Neon Postgres?

**Findings**:
- Neon recommends `asyncpg` as the async PostgreSQL driver
- SQLModel supports async via `create_async_engine` from SQLAlchemy 2.0
- Connection string format: `postgresql+asyncpg://user:password@host/database?sslmode=require`
- Neon requires SSL (`sslmode=require`) for all connections
- Connection pooling: Use `pool_size=5` and `max_overflow=10` for small-scale apps

**Decision**: Use `asyncpg` driver with SQLModel's async engine. Configure SSL and reasonable pool sizes.

**Alternatives Considered**:
- `psycopg2`: Synchronous only, not suitable for FastAPI async
- `psycopg3`: Newer but less documented with SQLModel
- Raw asyncpg without ORM: Too low-level, loses type safety benefits

---

### RQ-2: UUID Generation Strategy

**Question**: Should UUIDs be generated in Python or by the database?

**Findings**:
- Python `uuid.uuid4()` is cryptographically random and fast
- Database-side generation (PostgreSQL `gen_random_uuid()`) requires extension but ensures uniqueness even if Python fails
- SQLModel supports both via `default_factory` (Python) or `server_default` (database)
- For distributed systems, UUIDv7 (time-ordered) offers better index performance, but adds complexity

**Decision**: Generate UUIDs in Python using `uuid.uuid4()` via `Field(default_factory=uuid4)`. Simpler, portable, and sufficient for this scale.

**Alternatives Considered**:
- Database-generated UUIDs: Adds PostgreSQL extension dependency
- UUIDv7: Over-engineering for current scale; can migrate later if needed
- Auto-increment integers: Not globally unique; problematic for distributed scenarios

---

### RQ-3: Status Field Implementation

**Question**: How to implement the Task status enum in SQLModel with database constraint?

**Findings**:
- Python `enum.Enum` provides type safety in application code
- SQLModel can map enums to PostgreSQL ENUM type or VARCHAR with CHECK
- PostgreSQL ENUM is strict but requires migration for new values
- VARCHAR + CHECK is more flexible for adding statuses later

**Decision**: Use Python `str` enum subclass with SQLModel's `sa_column` to create a VARCHAR column with CHECK constraint. This balances type safety with migration flexibility.

**Implementation Pattern**:
```python
class TaskStatus(str, Enum):
    PENDING = "pending"
    COMPLETED = "completed"

class Task(SQLModel, table=True):
    status: TaskStatus = Field(
        default=TaskStatus.PENDING,
        sa_column=Column(String, CheckConstraint("status IN ('pending', 'completed')"))
    )
```

**Alternatives Considered**:
- PostgreSQL ENUM type: Harder to add new values; requires migration
- Plain string without validation: Loses type safety
- Integer codes: Less readable; requires mapping table

---

### RQ-4: Better Auth User Reference

**Question**: How does Better Auth store user IDs, and how should Task reference them?

**Findings**:
- Better Auth creates its own `user` table with configurable schema
- Default user ID is a UUID string
- Better Auth tables should not be modified by other migrations
- Foreign key to Better Auth user table is optional (can use soft reference)

**Decision**: Store `user_id` as a `String` (UUID format) without formal foreign key constraint. This decouples our schema from Better Auth's and avoids migration conflicts.

**Rationale**:
- Better Auth manages its own migrations
- Soft reference (no FK) prevents cascade issues if auth schema changes
- Application layer enforces ownership via authenticated user_id from JWT
- Indexing on `user_id` ensures query performance

**Alternatives Considered**:
- Hard FK to Better Auth user table: Creates migration coupling; risky
- Duplicate user data in our schema: Violates DRY; sync issues
- Integer user IDs: Better Auth uses UUIDs by default

---

### RQ-5: Alembic Configuration for SQLModel

**Question**: How to configure Alembic to work with SQLModel's async engine?

**Findings**:
- Alembic supports async via `run_sync` wrapper in `env.py`
- SQLModel models must be imported before `target_metadata` is set
- Use `SQLModel.metadata` as `target_metadata` for autogenerate
- Neon connection works same as standard PostgreSQL in migrations

**Decision**: Configure Alembic with async support using the standard SQLAlchemy 2.0 pattern. Import all models in `env.py` to enable autogenerate.

**Configuration Pattern**:
```python
# alembic/env.py
from sqlmodel import SQLModel
from app.models import *  # Import all models

target_metadata = SQLModel.metadata

async def run_migrations_online():
    # Use async engine for migrations
```

---

### RQ-6: Timestamp Handling

**Question**: How to implement auto-updating `created_at` and `updated_at` fields?

**Findings**:
- `created_at`: Use `server_default=func.now()` for database-side timestamp
- `updated_at`: Use `onupdate=func.now()` for automatic update on modification
- Timezone: Use `TIMESTAMP WITH TIME ZONE` for consistency across time zones
- SQLModel exposes these via `sa_column` parameter

**Decision**: Use PostgreSQL `now()` function for both fields. `created_at` is immutable after insert; `updated_at` auto-refreshes on any update.

**Implementation Pattern**:
```python
from sqlalchemy import Column, DateTime, func

created_at: datetime = Field(
    sa_column=Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
)
updated_at: datetime = Field(
    sa_column=Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
)
```

---

## Summary of Decisions

| Topic | Decision | Rationale |
|-------|----------|-----------|
| Async Driver | asyncpg | Neon recommended; FastAPI compatible |
| UUID Generation | Python uuid4() | Simple, portable, sufficient for scale |
| Status Enum | str Enum + CHECK constraint | Type safe + migration flexible |
| User Reference | Soft reference (no FK) | Decouples from Better Auth schema |
| Migrations | Alembic with async support | Industry standard; SQLModel compatible |
| Timestamps | Database-managed with func.now() | Consistent; no client clock issues |

---

## Outstanding Questions

None. All technical unknowns have been resolved.

---

## References

- [SQLModel Documentation](https://sqlmodel.tiangolo.com/)
- [Neon Postgres Python Guide](https://neon.tech/docs/guides/python)
- [Alembic with SQLAlchemy 2.0](https://alembic.sqlalchemy.org/en/latest/cookbook.html)
- [Better Auth Database Schema](https://www.better-auth.com/docs/concepts/database)
