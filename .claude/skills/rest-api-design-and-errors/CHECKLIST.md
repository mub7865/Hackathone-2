# REST API Design & Errors – Checklist

Use this checklist har naya REST endpoint / API design karte waqt.
Goal: har project me same patterns, same status codes, same error JSON.

---

## 1. Resource & URL design

- [ ] Resource noun-based hai? e.g. `/tasks` instead of `/getTasks` ya `/createTask`. [web:103][web:142]
- [ ] Collection plural noun use kar rahi hai? e.g. `/users`, `/tasks`, `/projects`. [web:103][web:142]
- [ ] Strong ownership ho to nested pattern use ho raha hai? e.g. `/api/v1/users/{user_id}/tasks`. [web:103][web:196]
- [ ] Base path versioned hai? e.g. `/api/v1/...`. [web:103][web:105]
- [ ] Path me action verbs avoid kiye gaye hain (sirf rare action endpoints jese `/tasks/{id}/complete` jab spec kahe). [web:103][web:142]

---

## 2. HTTP methods

- [ ] `GET` sirf data read karta hai, side-effects nahi (safe + idempotent). [web:142][web:105]
- [ ] `POST` new resource create ya non-idempotent operation ke liye use ho raha hai. [web:103][web:105]
- [ ] `PUT` full replace ke liye, idempotent semantics ke sath. [web:142][web:105]
- [ ] `PATCH` partial update ke liye, e.g. `{ "completed": true }`. [web:142][web:105]
- [ ] `DELETE` idempotent hai (second delete par 204/404, lekin crash ya 5xx nahi). [web:142][web:112]

---

## 3. Query params, filtering & pagination

- [ ] List endpoints pagination support karte hain? `page` + `page_size` (ya agreed alternative). [web:103][web:105]
- [ ] Reasonable defaults set hain (e.g. `page=1`, `page_size=20`) aur max `page_size` cap hai. [web:103][web:142]
- [ ] Filtering clear query params se ho rahi hai? e.g. `?status=pending&priority=high` ya `filter[status]=pending`. [web:103][web:142]
- [ ] Sorting ke liye consistent `sort` param use ho raha hai? e.g. `sort=created_at` ya `sort=-created_at`. [web:103][web:142]

---

## 4. Success response shape

- [ ] Collection responses ek object return karte hain, raw array nahi:
      `{ "items": [...], "page": 1, "page_size": 20, "total": 123 }`. [web:103][web:105]
- [ ] Single resource endpoints full resource JSON return karte hain (no half-baked shapes). [web:112][web:196]
- [ ] Create par `201 Created` + body (aur `Location` header agar possible) return ho raha hai. [web:112][web:105]
- [ ] Delete par `204 No Content` use ho raha hai jab body ki zarurat nahi. [web:112][web:114]

---

## 5. Status codes

Client vs server error split:

- [ ] Client mistakes → 4xx (kabhi bhi 5xx nahi) e.g. invalid input, missing auth. [web:107][web:114]
- [ ] Server bugs / dependency failures → 5xx (500/502/503). [web:114][web:116]

Common codes mapping:

- [ ] `400 Bad Request` – malformed request / generic client error. [web:112][web:140]
- [ ] `401 Unauthorized` – missing/invalid auth (e.g. JWT missing/expired). [web:112][web:160]
- [ ] `403 Forbidden` – authenticated but not allowed (role / ownership mismatch). [web:114][web:154]
- [ ] `404 Not Found` – resource ya route exist nahi karta. [web:112][web:114]
- [ ] `409 Conflict` – state conflict (e.g. duplicate unique constraint). [web:107][web:112]
- [ ] `422 Unprocessable Entity` – validation fail (fields invalid). [web:107][web:112]
- [ ] `500 Internal Server Error` – unexpected / unhandled server-side error. [web:114][web:116]

---

## 6. Error body (Problem Details)

- [ ] Saare 4xx/5xx errors JSON format use karte hain, **never** HTML / plain string. [web:103][web:107]
- [ ] Error responses `Content-Type: application/problem+json` set karte hain. [web:146][web:162]
- [ ] Har error object me ye base fields hain:
      - `type` (URI for error type)
      - `title` (short label)
      - `status` (HTTP code)
      - `detail` (human-readable explanation)
      - `instance` (request path / id) [web:146][web:150][web:202]
- [ ] Validation errors me `errors` array include hoti hai with `{ field, message, code }`. [web:146][web:150][web:107]
- [ ] Sensitive details (stack traces, SQL errors, secrets) kabhi client ko leak nahi ho rahe. [web:107][web:201]

---

## 7. Centralized error handling

- [ ] Framework ke level par **central error handler / middleware** configured hai:
      - FastAPI: custom exception handlers, Problem Details builder. [web:168][web:172]
      - Express: global `(err, req, res, next)` middleware for Problem Details. [web:169][web:181][web:107]
- [ ] Route handlers `next(err)` (Express) ya `raise HTTPException` (FastAPI) use karte hain, har jaga custom `res.status(...).json(...)` error shapes nahi bana rahe. [web:169][web:168][web:107]
- [ ] Logging / monitoring error handler ke andar ho raha hai (stack trace sirf logs me, client response me nahi). [web:107][web:184]

---

## 8. Consistency across services

- [ ] Saare microservices / backends same naming, pagination fields, aur Problem Details error shape use karte hain. [web:103][web:196]
- [ ] API docs / OpenAPI spec me bhi yehi status codes aur error JSON shape documented hai. [web:105][web:142]
- [ ] New endpoints add karte waqt existing patterns reuse kiye jate hain (no one-off custom contracts). [web:103][web:199]
