# Research: Tasks CRUD UX (Web App)

**Feature**: 004-tasks-crud-ux
**Date**: 2025-12-13
**Purpose**: Resolve technical unknowns before implementation planning

---

## Research Questions

### RQ-1: Next.js App Router Structure for Phase II

**Question**: What is the correct App Router structure for the tasks page under `phase2/frontend`?

**Decision**: Use Next.js 16+ App Router with the following structure:
- Route: `app/(authenticated)/tasks/page.tsx`
- Layout: `app/(authenticated)/layout.tsx` (handles auth protection)
- Components: `components/tasks/` directory

**Rationale**:
- Route groups `(authenticated)` allow shared auth-protected layout without affecting URL
- Collocated components in `components/tasks/` for feature isolation
- Server Components by default, Client Components only where needed (interactivity)

**Alternatives Considered**:
- `app/tasks/page.tsx` without route group → Would require per-page auth checks
- `pages/` directory → Legacy, not recommended for new Next.js projects

---

### RQ-2: Better Auth Client Integration

**Question**: How should the frontend integrate with Better Auth for authentication state?

**Decision**: Use Better Auth's React client with:
- `useSession()` hook for auth state in Client Components
- `auth.api.getSession()` for Server Components
- Auth middleware in `middleware.ts` for route protection

**Rationale**:
- Better Auth provides official React integration
- Session available on both server and client
- Middleware protects routes before rendering

**Alternatives Considered**:
- Custom auth context → Unnecessary, Better Auth handles this
- Per-component auth checks → Fragile, easy to miss routes

---

### RQ-3: API Client Architecture

**Question**: How should the frontend communicate with the Tasks API?

**Decision**: Create a typed API client module:
- Location: `lib/api/tasks.ts`
- Pattern: Function-based client with TypeScript types matching backend schemas
- Auth: Automatically attach JWT from Better Auth session
- Error handling: Wrap responses in Result type or throw typed errors

**Rationale**:
- Type safety prevents runtime errors
- Centralized auth token handling
- Consistent error handling across all API calls

**Alternatives Considered**:
- Raw `fetch()` everywhere → No type safety, duplicated auth logic
- TanStack Query alone → Good for caching but still needs typed client underneath
- OpenAPI codegen → Overkill for 5 endpoints, adds build complexity

---

### RQ-4: State Management Approach

**Question**: How should task list state be managed (pagination, filtering, mutations)?

**Decision**: Use React hooks with URL state:
- Filter state: URL search params (`?status=pending`)
- Task list: `useState` + custom hook (`useTasks`)
- Mutations: Direct API calls with list refetch after success
- No global state library needed

**Rationale**:
- URL params make filter state shareable/bookmarkable
- Simple hooks sufficient for single-page scope
- Spec explicitly says no optimistic updates (wait for API response)

**Alternatives Considered**:
- Zustand/Redux → Overkill for single route
- TanStack Query → Good choice but adds dependency; can add later if needed
- React Context → Unnecessary indirection for this scope

---

### RQ-5: Modal/Panel Implementation

**Question**: How should create/edit overlays be implemented?

**Decision**: Client-side modal with:
- Pattern: Controlled modal component with state in parent
- Trigger: URL hash or component state (prefer component state for simplicity)
- Accessibility: Focus trap, escape to close, ARIA attributes
- Animation: CSS transitions (minimal, not motion system)

**Rationale**:
- Spec says "slide-out panel or modal" - modal is simpler
- Component state avoids URL complexity for transient UI
- Accessibility requirements in spec (SC-008, SC-009)

**Alternatives Considered**:
- Parallel routes (`@modal`) → Complex, better for shareable URLs
- Radix Dialog → Good but adds dependency; can use native dialog or custom
- Sheet/drawer → Equivalent to modal for this use case

---

### RQ-6: Form Handling and Validation

**Question**: How should forms handle validation and submission?

**Decision**: Use controlled form components:
- Validation: Client-side before submit (title required, 255 char max)
- Character counter: Live update as user types
- Submission: Disable button during API call, show loading state
- Errors: Display inline field errors + toast for API errors

**Rationale**:
- Spec requires character counter (FR-005a) and prevent over-limit (FR-005b)
- Client validation prevents unnecessary API calls
- Loading states required per spec (FR-017)

**Alternatives Considered**:
- React Hook Form → Good but adds dependency; controlled inputs sufficient
- Zod validation → Nice but simple rules don't need schema library
- Native form validation → Less control over UX

---

### RQ-7: Loading and Error States

**Question**: How should loading and error states be displayed?

**Decision**: Implement three state patterns:
- **Initial load**: Skeleton placeholders for task list
- **Action loading**: Button spinner + disabled state
- **Error display**: Toast notifications for transient errors, inline for form errors, full-page for fatal errors

**Rationale**:
- Skeleton provides better UX than spinner for list loading
- Inline errors for forms match expected behavior
- Toast for success/error feedback after actions (spec SC-012)

**Alternatives Considered**:
- Loading.tsx file → Good for initial page load, still need skeleton component
- Error boundaries → For unexpected errors; API errors need explicit handling

---

## Technology Decisions Summary

| Decision | Choice | Confidence |
|----------|--------|------------|
| Routing | App Router with route groups | High |
| Auth integration | Better Auth React client | High |
| API client | Custom typed functions | High |
| State management | React hooks + URL params | High |
| Forms | Controlled components | High |
| Modals | Custom accessible modal | Medium |
| Loading states | Skeleton + button spinners | High |

---

## Dependencies to Install

```
# Core (likely already in Next.js)
react
react-dom
next

# Better Auth client (assumed pre-wired per spec)
better-auth/react  # or equivalent

# No additional dependencies needed for MVP
```

---

## Open Items

None - all technical decisions resolved. Ready for Phase 1 design.
