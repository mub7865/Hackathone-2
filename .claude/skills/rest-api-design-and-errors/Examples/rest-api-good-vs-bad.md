# REST API Design & Errors – GOOD vs BAD

## GOOD: Consistent REST + Problem Details

- Resource naming:
  - `/api/v1/users`, `/api/v1/users/{user_id}/tasks`, `/api/v1/projects/{project_id}`.
  - Plural nouns for collections, `{id}` pattern for single resources.

- HTTP methods:
  - `GET /api/v1/users/{user_id}/tasks` → list tasks.
  - `POST /api/v1/users/{user_id}/tasks` → create a task.
  - `GET /api/v1/users/{user_id}/tasks/{task_id}` → task detail.
  - `PATCH /api/v1/users/{user_id}/tasks/{task_id}` → partial update.
  - `DELETE /api/v1/users/{user_id}/tasks/{task_id}` → delete.

- Pagination and filtering:
  - `GET /api/v1/users/{user_id}/tasks?page=1&page_size=20&status=pending&sort=-created_at`.
  - Response shape:
    ```
    {
      "items": [ /* tasks */ ],
      "page": 1,
      "page_size": 20,
      "total": 42
    }
    ```

- Success status codes:
  - `200 OK` for reads and updates with body.
  - `201 Created` on successful creation, optionally with `Location` header.
  - `204 No Content` on successful delete with no body.

- Error responses (Problem Details, application/problem+json):
  - 404 example:
    ```
    {
      "type": "https://example.com/errors/resource-not-found",
      "title": "Resource not found",
      "status": 404,
      "detail": "Task with id 123 was not found.",
      "instance": "/api/v1/users/ziakhan/tasks/123"
    }
    ```
  - 422 validation example:
    ```
    {
      "type": "https://example.com/errors/validation-error",
      "title": "Validation failed",
      "status": 422,
      "detail": "One or more fields are invalid.",
      "instance": "/api/v1/users/ziakhan/tasks",
      "errors": [
        { "field": "title", "message": "Title is required." },
        { "field": "due_date", "message": "Must be in the future." }
      ]
    }
    ```

Result:  
Har endpoint same resource naming, HTTP methods, pagination fields, aur error JSON format follow karta hai, isliye frontend/clients ko har project me ek hi mental model use karna padta hai.

---

## BAD: Inconsistent paths and ad-hoc errors

- Resource naming:
  - Endpoints like `/getAllTasks`, `/createTask`, `/deleteTaskById`, `/userTasksList`.
  - Kabhi singular, kabhi plural, kabhi verbs — predict karna mushkil.

- HTTP methods misuse:
  - `POST /getTasks` for listing.
  - `GET /deleteTask?id=123` for deletion.
  - `POST /tasks/update` instead of `PUT/PATCH /tasks/{id}`.

- Pagination and filtering:
  - Kabhi `pageNumber`, kabhi `p`, kabhi query me kuch nahi.
  - Kabhi raw array return, kabhi `{ data: [...] }`, koi stable pattern nahi.

- Status codes:
  - Har error ko `200 OK` ke saath `{ "success": false, "message": "error" }`.
  - 404 ki jagah 500, ya 401/403 clearly differentiate nahi hote.

- Error responses:
  - Kabhi `{ "error": "Something went wrong" }`.
  - Kabhi `{ "message": "Validation error", "fields": { "title": "required" } }`.
  - Har endpoint ka error shape alag, koi standard `type/title/status/detail/instance` nahi.

Result:  
Clients ko har project / endpoint ke liye alag error parsing logic likhna padta hai, aur status codes dekh ke bhi pata nahi chalta ke bug client side hai ya server side.
