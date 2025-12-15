# Feature Specification: Task Querying & Listing Behavior

**Feature Branch**: `005-task-query-listing`
**Created**: 2025-12-14
**Status**: Draft
**Phase**: Phase II – Chunk 4

---

## Intent

Make the `/tasks` page "query-smart" for signed-in users by extending the existing task listing with:

1. **Free-text search** across title and description fields
2. **Flexible sorting** by creation date or title
3. **Combined filtering** where status, search, and sort work together seamlessly
4. **Full URL state** so users can bookmark, share, and reload filtered views

The goal is to help users quickly find specific tasks within a potentially large list (up to ~1000 tasks) without introducing new domain concepts like priorities or due dates.

---

## Clarifications

### Session 2025-12-14

- Q: How does frontend know when to show/hide "Load More" button? → A: API returns list only; frontend infers "has more" if `results.length === limit`
- Q: When is search triggered as user types? → A: Debounced (300-500ms delay after typing stops)
- Q: What is the maximum search string length? → A: 100 characters max

---

## Constraints

1. **Tech Stack**: FastAPI + SQLModel + Neon DB backend; Next.js App Router frontend
2. **Extend, Don't Replace**: Enhance the existing `GET /api/v1/tasks` endpoint; no separate search endpoint
3. **User Isolation**: All queries remain scoped to the authenticated user via existing JWT auth
4. **No New Domain Concepts**: No priority, tags, due dates, or recurring tasks in this chunk
5. **Folder Structure**: Continue using `phase2/backend` and `phase2/frontend` directories
6. **Performance Target**: Filtered/sorted queries complete under ~500ms for users with up to 1000 tasks

---

## User Scenarios & Testing

### User Story 1 - Search Tasks by Text (Priority: P1)

A signed-in user wants to find tasks containing specific words in the title or description without scrolling through all tasks.

**Why this priority**: Search is the most impactful query feature—it transforms a static list into a useful tool for finding specific items quickly.

**Independent Test**: Can be fully tested by typing a search term and verifying only matching tasks appear, regardless of other features.

**Acceptance Scenarios**:

1. **Given** a user has tasks with titles "Weekly Report", "Monthly Report", and "Buy groceries", **When** they search for "report", **Then** only "Weekly Report" and "Monthly Report" are displayed.

2. **Given** a user has a task with description containing "budget review", **When** they search for "budget", **Then** that task appears in results even if "budget" is not in the title.

3. **Given** a user searches for "REPORT" (uppercase), **When** results are displayed, **Then** tasks with "report" (lowercase) are included (case-insensitive).

4. **Given** a user has an active search, **When** they clear the search field, **Then** all tasks matching the current status filter are displayed.

---

### User Story 2 - Sort Tasks (Priority: P2)

A signed-in user wants to change the order of displayed tasks to see oldest tasks first or sort alphabetically by title.

**Why this priority**: Sorting helps users organize their view but is secondary to finding specific tasks via search.

**Independent Test**: Can be tested by selecting different sort options and verifying task order changes correctly.

**Acceptance Scenarios**:

1. **Given** a user is viewing tasks, **When** the page loads, **Then** tasks are sorted by "Newest first" (created_at DESC) by default.

2. **Given** a user selects "Oldest first", **When** results are displayed, **Then** tasks are ordered by created_at ASC.

3. **Given** a user selects "Title A–Z", **When** results are displayed, **Then** tasks are ordered alphabetically by title (case-insensitive).

4. **Given** a user selects "Title Z–A", **When** results are displayed, **Then** tasks are ordered reverse-alphabetically by title (case-insensitive).

5. **Given** a user has search and status filters active, **When** they change the sort order, **Then** the filtered results are re-sorted without losing the filters.

---

### User Story 3 - Combine Filters with Search and Sort (Priority: P2)

A signed-in user wants to use status tabs, search, and sort together to narrow down their task view.

**Why this priority**: Filter combination is essential for power users but builds on P1 functionality.

**Independent Test**: Can be tested by applying multiple filters simultaneously and verifying the intersection of all conditions.

**Acceptance Scenarios**:

1. **Given** a user selects "Pending" tab and searches for "report", **When** results are displayed, **Then** only pending tasks containing "report" appear.

2. **Given** a user has status=completed, search="meeting", sort="oldest", **When** results are displayed, **Then** only completed tasks containing "meeting" appear, sorted by oldest first.

3. **Given** a user applies filters that match zero tasks, **When** results are displayed, **Then** an empty state message is shown (not an error).

---

### User Story 4 - Load More Results (Priority: P3)

A signed-in user viewing a long filtered list wants to load additional results without losing their current view.

**Why this priority**: Pagination is important for performance but only matters when users have many tasks.

**Independent Test**: Can be tested by creating >20 tasks, loading the page, clicking "Load More", and verifying additional tasks append correctly.

**Acceptance Scenarios**:

1. **Given** a user has 50 pending tasks, **When** they view the Pending tab, **Then** the first 20 tasks are displayed with a "Load More" button.

2. **Given** a user clicks "Load More", **When** additional tasks load, **Then** 20 more tasks are appended to the existing list (no duplicates, no gaps).

3. **Given** a user has loaded 40 of 50 tasks and clicks "Load More", **When** the remaining 10 tasks load, **Then** the "Load More" button disappears.

4. **Given** a user has filters active and clicks "Load More", **When** additional tasks load, **Then** all loaded tasks still match the active filters.

---

### User Story 5 - Shareable/Bookmarkable URLs (Priority: P3)

A signed-in user wants to bookmark a specific filtered view or share it with themselves across devices.

**Why this priority**: URL state improves UX but is not blocking for core functionality.

**Independent Test**: Can be tested by applying filters, copying the URL, opening in a new tab, and verifying the same view loads.

**Acceptance Scenarios**:

1. **Given** a user applies status=pending, search="report", sort=title, order=asc, **When** they look at the URL, **Then** it contains all query parameters: `?status=pending&search=report&sort=title&order=asc`.

2. **Given** a user copies a URL with query parameters, **When** they paste and navigate to it in a new browser tab, **Then** the page loads with the exact same filters, search, and sort applied.

3. **Given** a user has loaded additional pages (offset=40), **When** they reload the page, **Then** the view resets to offset=0 with the same filters (pagination is ephemeral).

4. **Given** a user clears all filters, **When** they look at the URL, **Then** default parameters are omitted to keep the URL clean.

---

### Edge Cases

- **Empty search string**: Treated as "no search filter"—returns all tasks matching status
- **Search with only whitespace**: Treated as empty search (trimmed)
- **Special characters in search**: Handled gracefully (no SQL injection, no crashes)
- **Search string exceeds 100 characters**: Truncated or rejected with validation error
- **Invalid sort parameter in URL**: Falls back to default (created_at DESC)
- **Invalid status parameter in URL**: Falls back to "all" (no status filter)
- **Negative or non-numeric offset/limit**: Returns 422 validation error
- **Offset beyond total results**: Returns empty list (not an error)
- **Concurrent task deletion**: If a task is deleted while user is on page 2, "Load More" may return fewer items than expected (acceptable)

---

## Requirements

### Functional Requirements

**Search:**
- **FR-001**: System MUST support free-text search on task `title` field
- **FR-002**: System MUST support free-text search on task `description` field
- **FR-003**: Search MUST be case-insensitive (substring/contains matching)
- **FR-004**: Search MUST combine with status filter using AND logic
- **FR-005**: Empty or whitespace-only search MUST be treated as "no search filter"
- **FR-006**: Search input MUST be limited to 100 characters maximum
- **FR-007**: Frontend MUST debounce search input (300-500ms delay after typing stops)

**Sorting:**
- **FR-008**: System MUST support sorting by `created_at` in ascending or descending order
- **FR-009**: System MUST support sorting by `title` in ascending or descending order (case-insensitive)
- **FR-010**: Default sort MUST be `created_at DESC` (newest first)
- **FR-011**: Sort MUST apply after all filters (status + search)

**Pagination:**
- **FR-012**: System MUST support offset-based pagination with configurable `offset` and `limit`
- **FR-013**: Default `limit` MUST be 20; maximum `limit` MUST be 100
- **FR-014**: Frontend MUST display "Load More" button when `results.length === limit` (inferred pagination)
- **FR-015**: "Load More" MUST append results to existing list without duplicates

**URL State:**
- **FR-016**: Frontend MUST reflect `status`, `search`, `sort`, and `order` in URL query parameters
- **FR-017**: Frontend MUST restore filter/sort state from URL on page load
- **FR-018**: Default values MUST be omitted from URL to keep it clean
- **FR-019**: Invalid URL parameters MUST fall back to defaults (no error page)

**API Contract:**
- **FR-020**: `GET /api/v1/tasks` MUST accept `search` query parameter (string, optional, max 100 chars)
- **FR-021**: `GET /api/v1/tasks` MUST accept `sort` query parameter (enum: `created_at`, `title`)
- **FR-022**: `GET /api/v1/tasks` MUST accept `order` query parameter (enum: `asc`, `desc`)
- **FR-023**: Invalid `sort` or `order` values MUST return 422 validation error
- **FR-024**: All queries MUST remain scoped to the authenticated user

### Key Entities

- **Task**: Existing entity with `id`, `user_id`, `title`, `description`, `status`, `created_at`, `updated_at`
- **No new entities required**—this chunk extends query capabilities only

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can find a specific task among 100+ tasks in under 5 seconds using search
- **SC-002**: Filtered/sorted queries for users with up to 1000 tasks complete in under 500ms
- **SC-003**: URL-based state restoration works 100% of the time (reload shows same view)
- **SC-004**: Zero duplicate tasks appear when using "Load More" pagination
- **SC-005**: All filter combinations (status × search × sort × order) return correct results
- **SC-006**: Search results correctly include matches in both title and description fields

---

## Non-Goals

The following are explicitly **out of scope** for Chunk 4:

1. **New task fields**: No priority, due date, tags, or categories
2. **Full-text search engine**: No Elasticsearch, PostgreSQL FTS, or similar—simple ILIKE is sufficient
3. **Saved searches/filters**: Users cannot save custom filter presets
4. **Bulk operations**: No multi-select or batch actions on filtered results
5. **Export functionality**: No CSV/JSON export of filtered results
6. **Real-time updates**: Task list does not auto-refresh when tasks change
7. **AI/chatbot integration**: No natural language query parsing
8. **UI theme or animation work**: No visual design changes beyond functional filter/sort controls
9. **Advanced pagination**: No cursor-based pagination or infinite scroll (offset-based only)
10. **Cross-user queries**: Admin views or shared task lists

---

## Assumptions

1. The existing composite index on `(user_id, status)` provides adequate performance for status filtering
2. PostgreSQL ILIKE with appropriate indexes will meet the 500ms performance target for substring search
3. Users will primarily search for 2-5 word phrases, not single characters or very long strings
4. The "Load More" pattern is preferred over traditional page numbers for this task management use case
5. Pagination offset does not need to persist in URL (acceptable to reset to page 1 on reload)
