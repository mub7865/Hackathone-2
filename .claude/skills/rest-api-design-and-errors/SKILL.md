# Skill: rest-api-design-and-errors

## Purpose

Ye Skill Claude ko **framework-agnostic REST API design rules** sikhata hai, jo FastAPI, Express, NestJS, Django REST, waghera sab par apply ho sakte hain. [web:103][web:142]  
Focus hai **resource naming, HTTP methods, pagination/filtering, status codes, aur standardized error JSON** (RFC 7807 style `application/problem+json`). [web:146][web:107][web:150]  

Jab bhi koi project “REST API” ya “backend endpoints” kaam maange, aur koi aur specific framework Skill (jaise `fastapi-sqlmodel-crud-patterns`) active ho, to **ye Skill bhi saath active hona chahiye** taa ke design har repo me consistent rahe. [web:103][web:142]  

---

## Global principles

- API **resources ko nouns se model karo, verbs se nahi** (e.g. `/tasks`, `/users`, `/projects` instead of `/getTasks` ya `/createUser`). [web:138][web:153][web:156]  
- **Plural nouns** use karo collections ke liye, aur `{id}` ke sath single resource represent karo: `/users` + `/users/{user_id}`, `/tasks` + `/tasks/{task_id}`. [web:152][web:158]  
- HTTP status codes ka semantics respect karo: 2xx success ke liye, 4xx client errors, 5xx server errors. [web:114][web:116][web:154]  

Har naya REST endpoint design karte waqt Claude ko in principles ko default maan kar chalna hai, jab tak spec explicitly kuch aur na bole. [web:103][web:142]  

---

## Resource naming & URLs

- **Base pattern**:  

  - Collections: `/users`, `/tasks`, `/projects`. [web:138][web:153]  
  - Single resource: `/users/{user_id}`, `/tasks/{task_id}`. [web:152][web:158]  
  - Strong ownership / hierarchy ho to nested resources: `/users/{user_id}/tasks`, `/projects/{project_id}/members`. [web:156][web:158]  

- **Kya avoid karna hai**:  

  - Verb‑style paths: `/getUsers`, `/createTask`, `/deleteUser`. [web:138][web:153]  
  - RPC‑ish actions in path: `/tasks/{id}/completeTask`; iske bajaye `POST /tasks/{id}/complete` ya `PATCH /tasks/{id}` with `completed: true` spec‑dependent. [web:103][web:142]  

- **Versioning**:  

  - Default convention: path versioning use karo: `/api/v1/...`. [web:103][web:142]  
  - Agar spec kuch aur kahe (e.g. header‑based version), to usko follow karo, lekin bina wajah mixed styles mat banao. [web:103][web:142]  

Agar koi spec vague ho (e.g. “user tasks API banao”), Claude ko default pattern `/api/v1/users/{user_id}/tasks` choose karna hai jab user ownership clear ho. [web:103][web:142][file:137]  

---

## HTTP methods semantics

Claude ko har framework me **same method semantics** follow karne hain:

- `GET`  
  - Sirf data read kare, side effects na ho (safe + idempotent). [web:142][web:105]  
  - Collections: `GET /tasks` ya `GET /users/{user_id}/tasks`. [web:103][web:142]  
  - Single: `GET /tasks/{task_id}`. [web:103][web:142]  

- `POST`  
  - Nai resource create karne ya non‑idempotent operation ke liye. [web:103][web:105]  
  - Example: `POST /tasks` to create task, `POST /tasks/{id}/complete` agar action endpoint choose kiya gaya ho. [web:103][web:142]  

- `PUT`  
  - Existing resource ka **full replace**, idempotent; repeated same body → same state. [web:142][web:105]  
  - Example: `PUT /tasks/{id}` jahan body me complete representation aaye. [web:142][web:105]  

- `PATCH`  
  - Partial update ke liye (e.g. sirf `title` change ya `completed` toggle). [web:142][web:105]  
  - Example: `PATCH /tasks/{id}` payload `{ "completed": true }`. [web:103][web:142]  

- `DELETE`  
  - Resource ko delete kare, idempotent hona chahiye (bar‑bar call karne se extra error nahi, usually 204 ya 404). [web:142][web:112]  

Agar spec kuch aur na bole to Claude ko ye semantics assume karke endpoints aur controller/route handlers likhne hain. [web:103][web:142]  

---

## Query params, filtering & pagination

Default conventions:

- **Pagination**  

  - Recommended query params: `page` (1‑based) aur `page_size`. [web:103][web:105]  
  - API response collections ke liye structure:  

    ```
    {
      "items": [ /* resources */ ],
      "page": 1,
      "page_size": 20,
      "total": 123
    }
    ```  

    Ye pattern documentation aur industry guides me commonly recommend hota hai for predictable pagination. [web:103][web:105][web:142]  

  - Reasonable default `page_size` (e.g. 20) aur max cap (e.g. 100) rakhna chahiye; values spec me tweak ho sakti hain. [web:103][web:142]  

- **Filtering**  

  - Simple filters ko **plain query params** me rakho: `GET /tasks?status=pending&priority=high`. [web:103][web:142]  
  - Agar domain complex ho (advanced filters), to `filter[...]` convention use kar sakte ho: `filter[status]=pending&filter[priority]=high`. [web:103][web:142]  

- **Sorting**  

  - Single sort param: `sort=created_at` ascending, `sort=-created_at` descending. [web:103][web:142]  

Agar koi spec filtering/pagination ke baare me blank ho, Claude ko upar wale defaults use karne hain taa ke har project me same mental model rahe. [web:103][web:105][web:142]  

---

## Success responses

- **Collection responses**  

  - Hamesha array ko ek top‑level object me wrap karo (`items` + pagination meta) instead of raw array root, taa ke future me fields add karna easy ho. [web:103][web:105]  
  - Default pattern:  

    ```
    {
      "items": [/* ... */],
      "page": 1,
      "page_size": 20,
      "total": 123
    }
    ```  

    Ye shape most REST best‑practice guides ke pagination examples se align karta hai. [web:103][web:105][web:142]  

- **Single resource success**  

  - `GET /resource/{id}` → `200 OK` with full resource JSON. [web:112][web:114]  
  - `POST /resources` → `201 Created`, body = new resource JSON, aur `Location` header me naya URI if framework easily support kare. [web:112][web:103]  
  - `PUT` / `PATCH` success usually `200 OK` (updated body) ya `204 No Content` agar body nahi deni. [web:112][web:154]  
  - `DELETE` success by default `204 No Content` without body. [web:112][web:114]  

Jab spec explicitly kuch aur status na maange, Claude ko ye defaults follow karne hain. [web:103][web:112][web:142]  

---

## Status codes: 2xx / 4xx / 5xx rules

Claude ko har API me **same mapping** use karni hai:

- **2xx**  

  - `200 OK` – Normal success with response body. [web:114][web:116]  
  - `201 Created` – Resource successfully created. [web:112][web:114]  
  - `204 No Content` – Request successful, response body empty (common for DELETE or idempotent updates). [web:112][web:114]  

- **4xx – client errors**  

  - `400 Bad Request` – Malformed request, invalid syntax, generic client error jab more specific code fit na ho. [web:140][web:112]  
  - `401 Unauthorized` – Auth missing ya invalid (e.g. missing Bearer token, expired token). [web:112][web:160]  
  - `403 Forbidden` – Client authenticated hai lekin is resource/action ki permission nahi. [web:114][web:154]  
  - `404 Not Found` – Resource exist nahi karta ya route invalid. [web:112][web:114]  
  - `409 Conflict` – State conflict (e.g. duplicate unique field, resource state incompatible). [web:107][web:112]  
  - `422 Unprocessable Entity` – Request syntactically sahi hai lekin semantic validation fail hui (e.g. field constraints violate). [web:107][web:112]  

- **5xx – server errors**  

  - `500 Internal Server Error` – Unexpected/unhandled server error. [web:114][web:116]  
  - `502 Bad Gateway`, `503 Service Unavailable` etc. infra/proxy scenarios ke liye, framework/infrastructure dependent. [web:114][web:116]  

Rule: **client mistakes → 4xx**, **server bugs or dependency failures → 5xx**, Claude ko ye split har error handling code me respect karna hai. [web:140][web:107][web:114]  

---

## Standard error response format (Problem Details)

Is Skill ka central part ye hai ke **saare errors structured JSON format use karein**, preferably RFC 7807 **Problem Details** style. [web:146][web:150][web:107]  

- **Content type**  

  - Default error responses ke liye `Content-Type: application/problem+json` use karo jab possible ho. [web:146][web:150][web:151]  

- **Base JSON shape** (Problem Details object)

  RFC 7807 ek standard error object define karta hai jisme kuch required aur kuch optional fields hoti hain. [web:146][web:150][web:143]  

  Minimum fields jo Claude ko design me prefer karne chahiye:

  - `type` – URI string jo error type ko identify kare (e.g. `"https://example.com/errors/validation-error"`). [web:146][web:150][web:161]  
  - `title` – Short, human‑readable summary of problem type. [web:146][web:150]  
  - `status` – HTTP status code number. [web:146][web:150]  
  - `detail` – Human‑readable explanation for is specific occurrence. [web:146][web:150][web:107]  
  - `instance` – URI path ya identifier for this specific error occurrence (e.g. current request path). [web:146][web:150]  

  Example fields mapping industry guidance ko follow karta hai, jo bataata hai ke Problem Details error ke high‑level aur fine‑grained info dono convey kar sakta hai. [web:146][web:150][web:143]  

- **Validation errors ke liye extended field**

  - Validation scenarios (422 / 400) me ek extra field `errors` include karna recommended hai, jo per‑field issues list kare:  

    ```
    {
      "type": "https://example.com/errors/validation-error",
      "title": "Validation failed",
      "status": 422,
      "detail": "One or more fields are invalid.",
      "instance": "/api/v1/tasks",
      "errors": [
        { "field": "title", "message": "Title is required." },
        { "field": "due_date", "message": "Must be in the future." }
      ]
    }
    ```  

    RFC 7807 explicitly allow karta hai custom extension members jisse APIs apni domain‑specific details add kar sakti hain. [web:146][web:150][web:143]  

- **Consistency rules**

  - Har framework (FastAPI, Express, etc.) me Claude ko **ya to central error middleware / exception handler** configure karna chahiye jo sab errors ko isi schema me map kare. [web:159][web:157]  
  - Kisi bhi endpoint me random ad‑hoc error JSON (e.g. `{ "error": "something bad" }`) return nahi karna, balki Problem Details schema ka hi variant use karna hai. [web:148][web:107]  

---

## How other Skills must use this

Jab bhi koi aur backend Skill active ho (e.g. `fastapi-sqlmodel-crud-patterns`, `fastapi-auth-jwt-backend-verification`), to:

- **Resource design**  

  - CRUD endpoints banate waqt yahi naming rules aur HTTP methods assume karo, unless spec explicitly kuch aur kahe. [web:103][web:142]  

- **Auth failures**  

  - Auth related issues (missing token, invalid JWT, expired session) always `401` with Problem Details body aur `WWW-Authenticate` header as needed. [web:112][web:160]  
  - Permission issues (role mismatch, foreign user ki resource access) `403` with Problem Details. [web:114][web:154]  

- **Validation & business errors**  

  - Input validation fail → `422` Problem Details with `errors` array. [web:107][web:112]  
  - Business rule violation (e.g. duplicate title in unique constraint) → `409` Problem Details. [web:107][web:112]  

- **Unhandled exceptions**  

  - Catch‑all handler 500 Problem Details return kare (internal error), aur sensitive internals kabhi client ko leak na kare. [web:114][web:116]  

Ye Skill ka kaam hai ensure karna ke chahe backend FastAPI ho ya koi aur technology, tumhare saare REST APIs **same mental model, same status codes, aur same error JSON** follow karein. [web:103][web:142][web:146]  
