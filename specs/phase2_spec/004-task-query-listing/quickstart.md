# Quickstart: Task Querying & Listing Behavior

**Feature**: 005-task-query-listing
**Date**: 2025-12-14

---

## Prerequisites

Before implementing this chunk, ensure:

- [x] Chunk 1-3 complete (Task entity, Auth, CRUD UX)
- [x] Backend running at `http://localhost:8000`
- [x] Frontend running at `http://localhost:3000`
- [x] Neon DB connected and migrated
- [x] User can log in and see /tasks page

---

## Quick Test: Current State

1. **Login** to the app at `http://localhost:3000`
2. **Create 5+ tasks** with different titles (e.g., "Weekly Report", "Buy groceries", "Team meeting")
3. **Mark some complete** to have mixed statuses
4. **Verify tabs work**: Pending, Completed, All show correct counts

---

## Implementation Order

### Step 1: Backend Enums (5 min)

Add to `phase2/backend/app/schemas/task.py`:

```python
from enum import Enum

class SortField(str, Enum):
    CREATED_AT = "created_at"
    TITLE = "title"

class SortOrder(str, Enum):
    ASC = "asc"
    DESC = "desc"
```

### Step 2: Backend Endpoint (15 min)

Update `phase2/backend/app/api/v1/tasks.py` `list_tasks`:

```python
from sqlalchemy import or_, func
from app.schemas.task import SortField, SortOrder

@router.get("", response_model=list[TaskResponse])
async def list_tasks(
    db: DbSession,
    user_id: CurrentUser,
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    status: TaskStatus | None = Query(None),
    search: str | None = Query(None, max_length=100),
    sort: SortField = Query(SortField.CREATED_AT),
    order: SortOrder = Query(SortOrder.DESC),
) -> list[TaskResponse]:
    # Base query with user isolation
    query = select(Task).where(Task.user_id == user_id)

    # Status filter
    if status is not None:
        query = query.where(Task.status == status)

    # Search filter (title OR description)
    if search and search.strip():
        pattern = f"%{search.strip()}%"
        query = query.where(
            or_(
                Task.title.ilike(pattern),
                Task.description.ilike(pattern)
            )
        )

    # Sorting
    if sort == SortField.TITLE:
        sort_col = func.lower(Task.title)
    else:
        sort_col = Task.created_at

    if order == SortOrder.ASC:
        query = query.order_by(sort_col.asc())
    else:
        query = query.order_by(sort_col.desc())

    # Pagination
    query = query.offset(offset).limit(limit)

    result = await db.execute(query)
    return result.scalars().all()
```

### Step 3: Test Backend (5 min)

```bash
# Test search
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/tasks?search=report"

# Test sort
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/tasks?sort=title&order=asc"

# Test combined
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/tasks?status=pending&search=report&sort=title&order=asc"
```

### Step 4: Frontend Types (5 min)

Add to `phase2/frontend/types/task.ts`:

```typescript
export type SortField = 'created_at' | 'title';
export type SortOrder = 'asc' | 'desc';

export interface TaskQueryParams {
  status?: TaskFilter;
  search?: string;
  sort?: SortField;
  order?: SortOrder;
  offset?: number;
  limit?: number;
}
```

### Step 5: Frontend API Client (10 min)

Update `phase2/frontend/lib/api/tasks.ts`:

```typescript
export async function listTasks(params: TaskQueryParams = {}): Promise<Task[]> {
  const { status, search, sort, order, offset = 0, limit = 20 } = params;

  const queryParams = new URLSearchParams();

  if (status && status !== 'all') {
    queryParams.append('status', status);
  }
  if (search?.trim()) {
    queryParams.append('search', search.trim());
  }
  if (sort && sort !== 'created_at') {
    queryParams.append('sort', sort);
  }
  if (order && order !== 'desc') {
    queryParams.append('order', order);
  }
  queryParams.append('offset', String(offset));
  queryParams.append('limit', String(limit));

  const queryString = queryParams.toString();
  const endpoint = `${TASKS_ENDPOINT}${queryString ? `?${queryString}` : ''}`;

  return apiRequest<Task[]>(endpoint);
}
```

### Step 6: Install Debounce Package (1 min)

```bash
cd phase2/frontend
npm install use-debounce
```

### Step 7: Create useTaskQuery Hook (15 min)

Create `phase2/frontend/hooks/useTaskQuery.ts`:

```typescript
'use client';

import { useSearchParams, useRouter, usePathname } from 'next/navigation';
import { useCallback } from 'react';
import type { TaskFilter, SortField, SortOrder } from '@/types/task';

interface TaskQueryState {
  status: TaskFilter;
  search: string;
  sort: SortField;
  order: SortOrder;
}

const DEFAULTS: TaskQueryState = {
  status: 'pending',
  search: '',
  sort: 'created_at',
  order: 'desc',
};

export function useTaskQuery() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();

  // Read from URL with validation
  const status = (searchParams.get('status') as TaskFilter) || DEFAULTS.status;
  const search = searchParams.get('search') || DEFAULTS.search;
  const sort = (['created_at', 'title'].includes(searchParams.get('sort') || '')
    ? searchParams.get('sort')
    : DEFAULTS.sort) as SortField;
  const order = (['asc', 'desc'].includes(searchParams.get('order') || '')
    ? searchParams.get('order')
    : DEFAULTS.order) as SortOrder;

  const setQuery = useCallback((updates: Partial<TaskQueryState>) => {
    const params = new URLSearchParams();

    const newStatus = updates.status ?? status;
    const newSearch = updates.search ?? search;
    const newSort = updates.sort ?? sort;
    const newOrder = updates.order ?? order;

    // Only include non-default values
    if (newStatus !== DEFAULTS.status) params.set('status', newStatus);
    if (newSearch) params.set('search', newSearch);
    if (newSort !== DEFAULTS.sort) params.set('sort', newSort);
    if (newOrder !== DEFAULTS.order) params.set('order', newOrder);

    const queryString = params.toString();
    router.replace(`${pathname}${queryString ? `?${queryString}` : ''}`, { scroll: false });
  }, [status, search, sort, order, pathname, router]);

  return { status, search, sort, order, setQuery };
}
```

### Step 8: Create Search Input Component (15 min)

Create `phase2/frontend/components/tasks/TaskSearchInput.tsx`:

```typescript
'use client';

import { useState, useEffect } from 'react';
import { useDebouncedCallback } from 'use-debounce';

interface TaskSearchInputProps {
  value: string;
  onChange: (value: string) => void;
}

export function TaskSearchInput({ value, onChange }: TaskSearchInputProps) {
  const [localValue, setLocalValue] = useState(value);

  // Sync external value changes
  useEffect(() => {
    setLocalValue(value);
  }, [value]);

  const debouncedOnChange = useDebouncedCallback(
    (newValue: string) => onChange(newValue),
    300
  );

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;
    setLocalValue(newValue);
    debouncedOnChange(newValue);
  };

  const handleClear = () => {
    setLocalValue('');
    onChange('');
  };

  return (
    <div className="relative">
      <input
        type="text"
        value={localValue}
        onChange={handleChange}
        placeholder="Search tasks..."
        maxLength={100}
        className="w-full px-4 py-2 border rounded-lg pr-10"
      />
      {localValue && (
        <button
          onClick={handleClear}
          className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
        >
          ×
        </button>
      )}
    </div>
  );
}
```

### Step 9: Create Sort Dropdown Component (10 min)

Create `phase2/frontend/components/tasks/TaskSortDropdown.tsx`:

```typescript
'use client';

import type { SortField, SortOrder } from '@/types/task';

interface TaskSortDropdownProps {
  sort: SortField;
  order: SortOrder;
  onChange: (sort: SortField, order: SortOrder) => void;
}

const SORT_OPTIONS = [
  { label: 'Newest first', sort: 'created_at' as SortField, order: 'desc' as SortOrder },
  { label: 'Oldest first', sort: 'created_at' as SortField, order: 'asc' as SortOrder },
  { label: 'Title A–Z', sort: 'title' as SortField, order: 'asc' as SortOrder },
  { label: 'Title Z–A', sort: 'title' as SortField, order: 'desc' as SortOrder },
];

export function TaskSortDropdown({ sort, order, onChange }: TaskSortDropdownProps) {
  const currentValue = `${sort}-${order}`;

  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const [newSort, newOrder] = e.target.value.split('-') as [SortField, SortOrder];
    onChange(newSort, newOrder);
  };

  return (
    <select
      value={currentValue}
      onChange={handleChange}
      className="px-4 py-2 border rounded-lg bg-white"
    >
      {SORT_OPTIONS.map((option) => (
        <option key={`${option.sort}-${option.order}`} value={`${option.sort}-${option.order}`}>
          {option.label}
        </option>
      ))}
    </select>
  );
}
```

### Step 10: Integrate in Page (15 min)

Update `phase2/frontend/app/(authenticated)/tasks/page.tsx` to use the new hooks and components.

---

## Verification Checklist

After implementation, verify:

- [ ] **Search**: Type "report" → only matching tasks shown
- [ ] **Case-insensitive**: "REPORT" and "report" return same results
- [ ] **Sort**: Select "Title A-Z" → tasks alphabetically ordered
- [ ] **Combined**: Pending + "report" + A-Z → correct intersection
- [ ] **URL state**: Filters reflected in URL
- [ ] **URL reload**: Copy URL, paste in new tab → same view
- [ ] **Load More**: With >20 tasks, button appears and works
- [ ] **Clear search**: X button clears and shows all tasks

---

## Common Issues

### Issue: Search not working
- Check backend ILIKE query uses `or_()` for title OR description
- Verify search param is being sent in API request

### Issue: Sort not changing order
- Ensure `func.lower()` used for case-insensitive title sort
- Check both `sort` and `order` params sent to API

### Issue: URL not updating
- Use `router.replace()` not `router.push()`
- Include `{ scroll: false }` option

### Issue: Debounce not working
- Verify `use-debounce` package installed
- Check `useDebouncedCallback` returns a function

---

## Next Steps

After completing this quickstart:

1. Run `/sp.tasks` to generate detailed implementation tasks
2. Write backend integration tests
3. Manual QA of all edge cases
