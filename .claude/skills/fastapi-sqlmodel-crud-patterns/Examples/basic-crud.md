# FastAPI + SQLModel CRUD Basics (Example)

## GOOD: Structured, consistent CRUD

- A shared database module (e.g. `app/db.py`) exposes:
  - `engine` – configured once with DATABASE_URL.
  - `get_session()` – FastAPI dependency for SQLModel `Session`.

- Models are defined in one place (e.g. `app/models.py` or `app/models/`):
  - SQLModel classes describe table structure and constraints.
  - Optional separate schemas (Create/Update/Read) are used when needed.

- Each resource has its own router module:
  - `app/routers/tasks.py` with `APIRouter(prefix="/tasks", tags=["tasks"])`.
  - Endpoints follow REST semantics:
    - `GET /tasks` – list tasks.
    - `POST /tasks` – create task.
    - `GET /tasks/{id}` – get one task.
    - `PUT /tasks/{id}` – replace task.
    - `DELETE /tasks/{id}` – delete task.

- Common patterns:
  - Helper like `_get_task_or_404(session, task_id)` for lookups.
  - `HTTPException(status_code=404, detail="Task not found")` for missing rows.
  - `response_model=...` declared on routes for clear typing and docs.

Result:

- Code is easy to navigate:
  - DB config in one module.
  - Models in one place.
  - Routers per resource.
- New resources can reuse the same layout and patterns with minimal changes.

## BAD: Ad-hoc, inconsistent CRUD

- Each endpoint opens its own database connection and closes it manually.
- SQL queries or session creation are repeated in every route function.
- Routers mix multiple unrelated resources in a single module.
- Paths and verbs are inconsistent:
  - `POST /createTask`, `GET /getAllTasks`, `POST /deleteTask`.
- Error handling is random:
  - Sometimes returns `None`, sometimes raw exceptions, sometimes
    custom dicts with different shapes for the same error.

Result:

- Hard to add new features or resources without copy-paste.
- Difficult to reason about database usage and performance.
- API consumers cannot rely on consistent behaviour or responses.
