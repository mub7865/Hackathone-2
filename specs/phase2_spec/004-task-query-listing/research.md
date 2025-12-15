# Research: Task Querying & Listing Behavior

**Feature**: 005-task-query-listing
**Date**: 2025-12-14
**Status**: Complete

---

## Research Questions

This document resolves technical unknowns identified during planning.

---

## 1. PostgreSQL ILIKE Performance for Search

**Question**: Will PostgreSQL ILIKE meet the 500ms performance target for substring search on 1000 tasks?

### Decision: Use ILIKE with OR condition

### Rationale
- ILIKE is PostgreSQL's case-insensitive pattern matching operator
- For datasets under 10,000 rows per user, sequential scan is acceptable
- Combined with user_id filter, the working set is small (~1000 rows max)
- No need for full-text search complexity (pg_trgm, tsvector) at this scale

### Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|--------------|
| PostgreSQL FTS (tsvector) | Fast for large datasets | Complex setup, overkill for <10k rows | Over-engineering |
| pg_trgm extension | Fuzzy matching | Requires extension install | Not needed for substring match |
| Application-level filter | Simple | Loads all data, slow | Poor performance |
| Elasticsearch | Powerful search | External dependency | Way overkill |

### Implementation Pattern
```python
# Search on title OR description
if search:
    search_pattern = f"%{search}%"
    query = query.where(
        or_(
            Task.title.ilike(search_pattern),
            Task.description.ilike(search_pattern)
        )
    )
```

---

## 2. Case-Insensitive Title Sorting

**Question**: How to implement case-insensitive alphabetical sorting in SQLModel/SQLAlchemy?

### Decision: Use `func.lower()` for title sorting

### Rationale
- PostgreSQL's default `ORDER BY` is case-sensitive (uppercase before lowercase)
- Users expect "apple" and "Apple" to sort together
- `func.lower()` is a standard SQL function supported by all databases

### Implementation Pattern
```python
from sqlalchemy import func

if sort == SortField.TITLE:
    sort_column = func.lower(Task.title)
else:
    sort_column = Task.created_at

if order == SortOrder.ASC:
    query = query.order_by(sort_column.asc())
else:
    query = query.order_by(sort_column.desc())
```

### Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|--------------|
| COLLATE "C" | Consistent | Still case-sensitive | Doesn't solve the problem |
| Store lowercase title | Fast sort | Duplicate data, sync issues | Unnecessary complexity |
| Client-side sort | Simple | Breaks pagination | Incorrect results |

---

## 3. URL State Synchronization Pattern (Next.js App Router)

**Question**: What's the best pattern for syncing filter state with URL in Next.js 16 App Router?

### Decision: Custom hook with useSearchParams + router.replace

### Rationale
- `useSearchParams()` provides reactive access to URL params
- `router.replace()` updates URL without adding history entries
- Avoids full page reload while maintaining shareable URLs
- Pattern aligns with existing TaskFilterTabs implementation

### Implementation Pattern
```typescript
'use client';
import { useSearchParams, useRouter, usePathname } from 'next/navigation';

export function useTaskQuery() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();

  // Read from URL with defaults
  const status = searchParams.get('status') || 'pending';
  const search = searchParams.get('search') || '';
  const sort = searchParams.get('sort') || 'created_at';
  const order = searchParams.get('order') || 'desc';

  // Update URL
  const setQuery = (updates: Partial<QueryParams>) => {
    const params = new URLSearchParams(searchParams.toString());

    // Apply updates, remove defaults
    Object.entries(updates).forEach(([key, value]) => {
      if (isDefault(key, value)) {
        params.delete(key);
      } else {
        params.set(key, value);
      }
    });

    router.replace(`${pathname}?${params.toString()}`, { scroll: false });
  };

  return { status, search, sort, order, setQuery };
}
```

### Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|--------------|
| nuqs library | Type-safe URL state | External dependency | Overkill for 4 params |
| React state only | Simpler | No URL persistence | Breaks shareable links |
| Server component params | SSR-friendly | Complex for dynamic updates | Client interactions needed |

---

## 4. Debounce Implementation for Search Input

**Question**: What's the recommended debounce approach for React 19 / Next.js 16?

### Decision: Use `useDebouncedCallback` from `use-debounce` package

### Rationale
- Well-maintained, popular package (2M+ weekly downloads)
- Simple API, TypeScript support
- Handles cleanup automatically
- Already used in similar patterns across React ecosystem

### Implementation Pattern
```typescript
import { useDebouncedCallback } from 'use-debounce';

export function TaskSearchInput({ value, onChange }) {
  const [localValue, setLocalValue] = useState(value);

  const debouncedOnChange = useDebouncedCallback(
    (newValue: string) => onChange(newValue),
    300 // ms delay
  );

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setLocalValue(e.target.value);
    debouncedOnChange(e.target.value);
  };

  return (
    <input
      value={localValue}
      onChange={handleChange}
      maxLength={100}
    />
  );
}
```

### Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|--------------|
| Custom useDebounce hook | No dependency | More code to maintain | Reinventing the wheel |
| lodash.debounce | Well-known | Larger bundle, cleanup issues | use-debounce is lighter |
| setTimeout manual | No dependency | Complex cleanup, race conditions | Error-prone |

---

## 5. Handling Invalid URL Parameters

**Question**: How should invalid URL params (e.g., `?sort=invalid`) be handled?

### Decision: Silent fallback to defaults on frontend; 422 error on backend

### Rationale
- **Frontend**: Invalid params from manual URL editing should not crash the app
- **Backend**: API contract should be strict for programmatic clients
- This dual approach provides good UX while maintaining API integrity

### Frontend Pattern
```typescript
const VALID_SORTS = ['created_at', 'title'];
const VALID_ORDERS = ['asc', 'desc'];

const rawSort = searchParams.get('sort');
const sort = VALID_SORTS.includes(rawSort) ? rawSort : 'created_at';

const rawOrder = searchParams.get('order');
const order = VALID_ORDERS.includes(rawOrder) ? rawOrder : 'desc';
```

### Backend Pattern
```python
class SortField(str, Enum):
    CREATED_AT = "created_at"
    TITLE = "title"

# FastAPI auto-validates enum, returns 422 for invalid values
sort: SortField = Query(SortField.CREATED_AT)
```

---

## 6. "Load More" vs Total Count API Response

**Question**: Should the API return total count for pagination, or should frontend infer "has more"?

### Decision: Frontend infers "has more" from `results.length === limit`

### Rationale (from Clarification session):
- Simpler API contract (just returns array)
- No extra COUNT query needed (better performance)
- Matches existing implementation pattern in useTasks hook
- Sufficient for "Load More" UX (don't need page numbers)

### Tradeoff
- Cannot show "X of Y tasks" counter
- Accepted: Product decision confirmed in clarification

---

## Summary Table

| Question | Decision | Confidence |
|----------|----------|------------|
| Search performance | ILIKE with OR | High - proven at this scale |
| Case-insensitive sort | `func.lower()` | High - standard SQL |
| URL state sync | useSearchParams + router.replace | High - Next.js pattern |
| Debounce | use-debounce package | High - industry standard |
| Invalid URL params | Frontend fallback, Backend 422 | High - best of both |
| Pagination metadata | Infer from length | High - clarified with user |

---

## Dependencies to Install

### Frontend
```bash
cd phase2/frontend
npm install use-debounce
```

### Backend
No new dependencies required - using existing SQLModel/SQLAlchemy features.
