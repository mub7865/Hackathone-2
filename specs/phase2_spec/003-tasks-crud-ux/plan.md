# Implementation Plan: Tasks CRUD UX (Web App)

**Branch**: `004-tasks-crud-ux` | **Date**: 2025-12-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-tasks-crud-ux/spec.md`

---

## Summary

Implement the authenticated Tasks management frontend in Next.js App Router under `phase2/frontend`. The feature provides a single-page task list at `/tasks` with overlay modals for create/edit, status filtering (All/Pending/Completed), pagination, and full CRUD operations against the existing `/api/v1/tasks` backend API.

**Key Deliverables**:
- Protected `/tasks` route with auth redirect
- Task list with filter tabs (default: Pending)
- Create/Edit modal forms with validation
- Quick complete/uncomplete toggle
- Delete with confirmation
- Loading, empty, and error states

---

## Technical Context

**Language/Version**: TypeScript 5.x, Next.js 16+ (App Router)
**Primary Dependencies**: React 18+, Next.js, Better Auth (React client), Tailwind CSS
**Styling**: Tailwind CSS utility classes only (no raw CSS files or inline styles per spec)
**Storage**: N/A (frontend consumes backend API)
**Testing**: Vitest + React Testing Library (unit), Playwright (e2e optional)
**Target Platform**: Modern browsers (Chrome, Firefox, Safari, Edge)
**Project Type**: Web application (frontend only)
**Performance Goals**: Page load <3s, actions <2s (per spec SC-001 to SC-005)
**Constraints**: No optimistic updates, no offline support, wait for API response
**Scale/Scope**: Single authenticated route, ~10 components, ~5 API functions

---

## Constitution Check

*GATE: Must pass before implementation. Based on constitution v2.1.0.*

| Principle | Status | Notes |
|-----------|--------|-------|
| **Strict SDD** | ✅ PASS | Spec exists at `specs/004-tasks-crud-ux/spec.md` with 24 FRs |
| **AI-Native Architecture** | ✅ PASS | Frontend prepared for future AI integration (Phase III) |
| **Progressive Evolution** | ✅ PASS | Clean separation; frontend can evolve independently |
| **Documentation First** | ✅ PASS | Spec, plan, data-model, research all documented |
| **Tech Stack (Phase II)** | ✅ PASS | Next.js 16+ App Router, Better Auth as specified |
| **Code Quality** | ✅ PASS | TypeScript with strict types planned |
| **No Vibe Coding** | ✅ PASS | Implementation follows approved spec |

**Gate Result**: PASSED - Ready for implementation

---

## Project Structure

### Documentation (this feature)

```text
specs/004-tasks-crud-ux/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── research.md          # Technical decisions (complete)
├── data-model.md        # TypeScript types (complete)
├── quickstart.md        # Setup guide (complete)
└── tasks.md             # Implementation tasks (via /sp.tasks)
```

### Source Code Structure

```text
phase2/frontend/
├── app/
│   ├── (authenticated)/           # Route group for protected pages
│   │   ├── layout.tsx             # Auth check, redirect if not logged in
│   │   └── tasks/
│   │       ├── page.tsx           # Main tasks page (Server Component entry)
│   │       └── loading.tsx        # Loading skeleton
│   ├── login/
│   │   └── page.tsx               # Login page (assumed exists)
│   ├── layout.tsx                 # Root layout (providers, metadata)
│   └── page.tsx                   # Home redirect to /tasks
│
├── components/
│   ├── tasks/                     # Feature-specific components
│   │   ├── TaskList.tsx           # List container with pagination
│   │   ├── TaskItem.tsx           # Single task row with actions
│   │   ├── TaskForm.tsx           # Create/Edit form (shared)
│   │   ├── TaskFilterTabs.tsx     # All/Pending/Completed tabs
│   │   ├── TaskModal.tsx          # Modal wrapper for forms
│   │   ├── DeleteConfirmModal.tsx # Delete confirmation dialog
│   │   └── EmptyState.tsx         # No tasks message with CTA
│   │
│   └── ui/                        # Reusable UI primitives
│       ├── Modal.tsx              # Accessible modal base
│       ├── Button.tsx             # Button with loading state
│       ├── Input.tsx              # Input with character counter
│       ├── Textarea.tsx           # Textarea for description
│       ├── Checkbox.tsx           # Checkbox for complete action
│       ├── Tabs.tsx               # Tab navigation component
│       ├── Skeleton.tsx           # Loading skeleton
│       └── Toast.tsx              # Toast notifications
│
├── hooks/
│   ├── useTasks.ts                # Task list state management
│   ├── useTaskMutations.ts        # Create/update/delete operations
│   └── useToast.ts                # Toast notification state
│
├── lib/
│   ├── api/
│   │   ├── client.ts              # Base fetch wrapper with auth
│   │   ├── tasks.ts               # Tasks API functions
│   │   └── errors.ts              # Error handling utilities
│   └── auth/
│       └── client.ts              # Better Auth client config
│
├── types/
│   ├── task.ts                    # Task-related types
│   └── api.ts                     # API response types
│
├── middleware.ts                  # Auth middleware for route protection
├── next.config.js                 # Next.js configuration
├── package.json
├── tsconfig.json
└── .env.local                     # Environment variables
```

**Structure Decision**: Web application structure with App Router route groups for authentication. Feature components isolated in `components/tasks/`, reusable primitives in `components/ui/`.

---

## Implementation Phases

### Phase 1: Foundation (Priority: P0)

**Goal**: Set up project structure and core infrastructure.

#### 1.1 Project Initialization
- Initialize Next.js 16 project in `phase2/frontend`
- Configure TypeScript with strict mode
- Configure Tailwind CSS (all styling via utility classes per spec constraint)
- Set up ESLint and Prettier
- Create folder structure as defined above

#### 1.2 Environment Configuration
- Create `.env.local` with `NEXT_PUBLIC_API_URL`
- Configure Next.js for API proxy (if needed for CORS)

#### 1.3 Auth Integration
- Configure Better Auth client in `lib/auth/client.ts`
- Create auth middleware in `middleware.ts`
- Set up `(authenticated)` route group layout with session check

#### 1.4 API Client Foundation
- Create base fetch wrapper with JWT injection (`lib/api/client.ts`)
- Create error handling utilities (`lib/api/errors.ts`)
- Define TypeScript types (`types/task.ts`, `types/api.ts`)

**Deliverables**:
- Working Next.js project
- Auth-protected route structure
- Typed API client ready for use

---

### Phase 2: Core UI Components (Priority: P0)

**Goal**: Build reusable UI primitives needed by feature components.
**Styling**: All components styled with Tailwind utility classes; leverage existing shared components where available.

#### 2.1 Base Components
- `Button.tsx`: Primary/secondary variants via Tailwind classes, loading state, disabled state
- `Input.tsx`: Text input with label, error display, character counter (Tailwind styling)
- `Textarea.tsx`: Multi-line input for description (Tailwind styling)
- `Checkbox.tsx`: Accessible checkbox for complete toggle (Tailwind styling)
- `Skeleton.tsx`: Loading placeholder shapes using Tailwind animate utilities

#### 2.2 Modal System
- `Modal.tsx`: Accessible modal with focus trap, escape to close, backdrop (Tailwind backdrop/overlay classes)
- Portal-based rendering for proper stacking

#### 2.3 Feedback Components
- `Toast.tsx`: Success/error/info notifications (Tailwind color variants)
- `useToast.ts`: Toast state management hook
- `Tabs.tsx`: Tab navigation with active state (Tailwind styling)

**Deliverables**:
- Complete UI component library using Tailwind CSS
- Accessible, keyboard-navigable components
- Consistent loading and error states

---

### Phase 3: Tasks API Integration (Priority: P1)

**Goal**: Implement typed API client functions for all task operations.

#### 3.1 API Functions
Create `lib/api/tasks.ts` with:

```typescript
// Function signatures (not implementation)
listTasks(params: { status?: TaskFilter; offset?: number; limit?: number }): Promise<Task[]>
createTask(data: TaskCreateRequest): Promise<Task>
getTask(id: string): Promise<Task>
updateTask(id: string, data: TaskUpdateRequest): Promise<Task>
deleteTask(id: string): Promise<void>
```

#### 3.2 Error Handling
- Parse RFC 7807 Problem Details
- Map HTTP status codes to user-friendly messages
- Handle 401 → redirect to login
- Handle 422 → extract field errors

#### 3.3 Custom Hooks
- `useTasks.ts`: Fetch list with filter/pagination, refetch on change
- `useTaskMutations.ts`: Create/update/delete with loading states

**Deliverables**:
- Complete typed API client
- Reusable hooks for data fetching
- Consistent error handling

---

### Phase 4: Task List View (Priority: P1)

**Goal**: Implement the main task list with filtering and pagination.
**Styling**: All components use Tailwind utility classes and shared UI components from Phase 2.

#### 4.1 Filter Tabs Component
- `TaskFilterTabs.tsx`: All/Pending/Completed tabs using shared Tabs component
- Sync with URL search params (`?status=`)
- Default to "Pending" on initial load (FR-002a)
- Visual active state via Tailwind classes

#### 4.2 Task List Component
- `TaskList.tsx`: Container for task items (Tailwind flex/grid layout)
- Handle loading state with Skeleton components
- Handle empty state with EmptyState component
- Implement "Load More" pagination with Button component

#### 4.3 Task Item Component
- `TaskItem.tsx`: Single task row (Tailwind styling)
- Display title, status indicator (Tailwind color classes)
- Action buttons using shared Button component
- Highlight effect for newly created tasks via Tailwind animation classes (FR-019a)

#### 4.4 Empty States
- `EmptyState.tsx`: Different messages for (Tailwind styling):
  - No tasks at all → "No tasks yet" + CTA using Button
  - No tasks matching filter → "No pending/completed tasks"

**Deliverables**:
- Fully functional task list view styled with Tailwind
- Working filter tabs with URL sync
- Pagination with "Load More"
- Proper empty states

---

### Phase 5: Create Task Flow (Priority: P1)

**Goal**: Implement task creation via modal form.
**Styling**: Uses shared UI components (Modal, Input, Textarea, Button) with Tailwind classes.

#### 5.1 Task Form Component
- `TaskForm.tsx`: Shared form for create/edit using shared Input/Textarea/Button components
- Title input with 255-char counter and limit (FR-005a, FR-005b)
- Description textarea (optional)
- Submit and Cancel buttons using shared Button component
- Validation: title required, max 255 chars (error states via Tailwind)

#### 5.2 Create Modal
- "Add Task" button in header/toolbar using shared Button component
- Opens `TaskModal.tsx` with `TaskForm` in create mode
- On submit: call API, close modal, prepend task to list
- Show highlight effect on new task via Tailwind animation
- Show success toast using shared Toast component

#### 5.3 Error Handling
- Display validation errors inline (Tailwind error styling)
- Display API errors in form
- Keep form open on error for retry

**Deliverables**:
- Working create task flow styled with Tailwind
- Form validation with character counter
- Success/error feedback

---

### Phase 6: Edit Task Flow (Priority: P2)

**Goal**: Implement task editing via modal form.
**Styling**: Reuses TaskForm with shared UI components and Tailwind classes.

#### 6.1 Edit Mode for TaskForm
- Pre-populate form with existing task values
- Add status dropdown/toggle (pending/completed) styled with Tailwind
- Track dirty state for unsaved changes warning (optional)

#### 6.2 Edit Modal Trigger
- Edit button/icon on each TaskItem using shared Button component
- Fetch single task (or use cached data)
- Open modal with edit mode

#### 6.3 Update Flow
- On submit: call PATCH API
- Close modal, update task in list
- Show success toast using shared Toast component
- Handle errors (keep modal open)

**Deliverables**:
- Working edit task flow styled with Tailwind
- Status change capability
- Proper error handling

---

### Phase 7: Complete/Uncomplete Action (Priority: P2)

**Goal**: Implement quick status toggle from task list.
**Styling**: Uses shared Checkbox component with Tailwind loading states.

#### 7.1 Complete Toggle
- Checkbox using shared Checkbox component on TaskItem
- Clicking triggers PATCH with status change
- Disable during API call (FR-017) via Tailwind disabled styling
- Visual feedback: loading spinner via Tailwind animate classes

#### 7.2 Status Update
- On success: update task in list
- If filter is "Pending" and task completed → remove from view
- If filter is "Completed" and task uncompleted → remove from view
- Show brief success indication

**Deliverables**:
- One-click complete/uncomplete styled with Tailwind
- Proper loading states
- Filter-aware list updates

---

### Phase 8: Delete Task Flow (Priority: P2)

**Goal**: Implement task deletion with confirmation.
**Styling**: Uses shared Modal and Button components with Tailwind classes.

#### 8.1 Delete Confirmation Modal
- `DeleteConfirmModal.tsx`: "Are you sure?" dialog using shared Modal
- Task title displayed for confirmation (Tailwind typography)
- Confirm (destructive variant) and Cancel buttons using shared Button

#### 8.2 Delete Flow
- Delete button/icon on TaskItem using shared Button component
- Opens confirmation modal
- On confirm: call DELETE API
- On success: remove task from list, close modal
- Show success toast using shared Toast component

#### 8.3 Error Handling
- Display error in modal if delete fails (Tailwind error styling)
- Keep modal open for retry

**Deliverables**:
- Working delete with confirmation styled with Tailwind
- Proper error handling
- Success feedback

---

### Phase 9: Error States & Edge Cases (Priority: P3)

**Goal**: Handle all error scenarios per spec.
**Styling**: Error states use Tailwind color utilities and shared components.

#### 9.1 Global Error Handling
- 401 errors → redirect to login (FR-015)
- Network errors → show connectivity message via Toast
- 500 errors → show generic error with retry via Toast

#### 9.2 List Load Errors
- Error state in TaskList with retry button (Tailwind error styling)
- Preserve filter state on retry

#### 9.3 Form Errors
- Field-level validation errors (FR-016) via Tailwind error classes
- API validation errors mapped to fields
- General error banner for non-field errors (Tailwind alert styling)

#### 9.4 Edge Cases
- Rapid click prevention (disable during API calls via Tailwind disabled states)
- Session expiry handling
- Pagination end state (hide "Load More")

**Deliverables**:
- Comprehensive error handling styled with Tailwind
- All edge cases covered
- Graceful degradation

---

### Phase 10: Accessibility & Polish (Priority: P3)

**Goal**: Ensure accessibility requirements are met.
**Styling**: All visual polish via Tailwind utilities; no custom CSS files.

#### 10.1 Keyboard Navigation
- Tab order through all interactive elements
- Enter to submit forms
- Escape to close modals
- Arrow keys for tab navigation (optional)

#### 10.2 Screen Reader Support
- ARIA labels on all interactive elements (SC-009)
- Live regions for dynamic updates
- Proper heading hierarchy
- Focus management on modal open/close

#### 10.3 Visual Polish
- Consistent loading states via Tailwind animate utilities
- Smooth transitions via Tailwind transition classes (no motion system)
- Clear focus indicators via Tailwind ring/outline utilities

**Deliverables**:
- WCAG 2.1 AA compliance
- Keyboard fully accessible
- Screen reader tested
- All styling via Tailwind CSS

---

## Component Dependency Graph

```
app/(authenticated)/tasks/page.tsx
├── TaskFilterTabs
├── TaskList
│   ├── TaskItem (multiple)
│   │   ├── Checkbox (complete toggle)
│   │   ├── Button (edit)
│   │   └── Button (delete)
│   ├── Skeleton (loading)
│   └── EmptyState (empty)
├── TaskModal
│   └── TaskForm
│       ├── Input (title with counter)
│       ├── Textarea (description)
│       └── Button (submit/cancel)
├── DeleteConfirmModal
│   └── Modal
│       └── Button (confirm/cancel)
└── Toast (notifications)
```

---

## API Integration Map

| User Action | Component | API Call | Response Handling |
|-------------|-----------|----------|-------------------|
| Page load | TaskList | `GET /tasks?status=pending` | Display list or empty state |
| Change filter | TaskFilterTabs | `GET /tasks?status={filter}` | Replace list, reset pagination |
| Load more | TaskList | `GET /tasks?offset={n}` | Append to list |
| Add task | TaskForm | `POST /tasks` | Prepend to list, highlight |
| Edit task | TaskForm | `PATCH /tasks/{id}` | Update in list |
| Complete task | TaskItem | `PATCH /tasks/{id}` | Update or remove from filtered list |
| Delete task | DeleteConfirmModal | `DELETE /tasks/{id}` | Remove from list |

---

## State Management Summary

| State | Location | Persistence |
|-------|----------|-------------|
| Filter selection | URL params | Yes (shareable) |
| Task list | `useTasks` hook | No (refetch on mount) |
| Pagination offset | Component state | No (reset on filter) |
| Modal open/close | Component state | No |
| Form values | Component state | No |
| Toast messages | `useToast` hook | No (auto-dismiss) |
| Highlight task ID | Component state | No (auto-clear) |

---

## Testing Strategy

### Unit Tests (Vitest + RTL)
- Component rendering
- Form validation logic
- API client functions (mocked fetch)
- Hook behavior

### Integration Tests
- User flows (create, edit, delete)
- Filter switching
- Error handling

### E2E Tests (Playwright, optional)
- Full user journey
- Auth flow integration
- Cross-browser testing

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Better Auth integration issues | Medium | High | Test auth flow early in Phase 1 |
| CORS issues with backend | Medium | Medium | Configure Next.js proxy or backend CORS |
| Performance with large task lists | Low | Medium | Pagination limits impact; virtualization if needed later |
| Accessibility gaps | Low | Medium | Use semantic HTML, test with screen reader |

---

## Definition of Done

- [ ] All 24 functional requirements (FR-001 to FR-020, plus sub-items) implemented
- [ ] All 12 success criteria (SC-001 to SC-012) verified
- [ ] All 7 user stories testable with their acceptance scenarios
- [ ] Keyboard accessible (tab, enter, escape)
- [ ] Screen reader labels present
- [ ] Error states handled (401, 422, 500, network)
- [ ] Loading states shown during operations
- [ ] TypeScript strict mode, no `any` types
- [ ] Code reviewed and merged

---

## Next Steps

1. Run `/sp.tasks` to generate implementation task list
2. Begin Phase 1 (Foundation) implementation
3. Test auth integration before proceeding to UI
