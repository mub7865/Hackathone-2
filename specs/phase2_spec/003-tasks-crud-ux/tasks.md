# Implementation Tasks: Tasks CRUD UX (Web App)

**Feature**: 004-tasks-crud-ux
**Branch**: `004-tasks-crud-ux`
**Generated**: 2025-12-13
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

---

## Task Summary

| Phase | Focus | Task Count | Agent |
|-------|-------|------------|-------|
| 1 | Setup & Foundation | 9 | frontend-router-specialist |
| 2 | Core UI Components | 9 | ui-ux-animation-designer / frontend-router-specialist |
| 3 | US1: View My Tasks | 8 | frontend-router-specialist |
| 4 | US2: Create Task | 6 | frontend-router-specialist |
| 5 | US3: Edit Task | 4 | frontend-router-specialist |
| 6 | US4: Complete Toggle | 3 | frontend-router-specialist |
| 7 | US5: Delete Task | 4 | frontend-router-specialist |
| 8 | US6 & US7: Empty/Error States | 4 | frontend-router-specialist |
| 9 | Polish & Accessibility | 5 | ui-ux-animation-designer |
| **Total** | | **52** | |

---

## Phase 1: Setup & Foundation

**Goal**: Initialize Next.js project with auth and API client infrastructure.
**Blocking**: Must complete before any user story work.
**Styling Constraint**: All components must use Tailwind CSS utility classes only (no raw CSS files or inline styles per spec).

- [x] T001 Initialize Next.js 16 project with TypeScript strict mode in `phase2/frontend/`
- [x] T001a Configure Tailwind CSS with project-wide setup in `phase2/frontend/tailwind.config.ts`
- [x] T002 [P] Create folder structure: `app/`, `components/tasks/`, `components/ui/`, `hooks/`, `lib/api/`, `lib/auth/`, `types/`
- [x] T003 [P] Create environment config with `.env.local` template in `phase2/frontend/.env.local`
- [x] T004 [P] Define TypeScript types for Task, TaskCreate, TaskUpdate, TaskFilter in `phase2/frontend/types/task.ts`
- [x] T005 [P] Define API response and error types (ProblemDetail, ValidationError) in `phase2/frontend/types/api.ts`
- [x] T006 Configure Better Auth client with session hooks in `phase2/frontend/lib/auth/client.ts`
- [x] T007 Create auth middleware for route protection in `phase2/frontend/middleware.ts`
- [x] T008 Create base API client with JWT injection and error handling in `phase2/frontend/lib/api/client.ts`

**Deliverables**: Working Next.js project with Tailwind CSS, auth-protected routes, and typed API client.

---

## Phase 2: Core UI Components (Foundational)

**Goal**: Build reusable UI primitives needed by all user stories.
**Blocking**: Must complete before user story phases.
**Agent**: `ui-ux-animation-designer` for component specs, `frontend-router-specialist` for implementation.
**Styling**: All components use Tailwind utility classes only; no raw CSS or inline styles.

- [x] T009 [P] Create Button component with Tailwind variants (primary/secondary), loading, disabled states in `phase2/frontend/components/ui/Button.tsx`
- [x] T010 [P] Create Input component with Tailwind styling, label, error display, 255-char counter in `phase2/frontend/components/ui/Input.tsx`
- [x] T011 [P] Create Textarea component with Tailwind styling for description field in `phase2/frontend/components/ui/Textarea.tsx`
- [x] T012 [P] Create Checkbox component with Tailwind styling and accessible label in `phase2/frontend/components/ui/Checkbox.tsx`
- [x] T013 [P] Create Skeleton component with Tailwind animate-pulse for loading placeholders in `phase2/frontend/components/ui/Skeleton.tsx`
- [x] T014 [P] Create Tabs component with Tailwind active state styling in `phase2/frontend/components/ui/Tabs.tsx`
- [x] T015 Create Modal component with Tailwind backdrop, focus trap, escape-to-close in `phase2/frontend/components/ui/Modal.tsx`
- [x] T016 Create Toast component with Tailwind color variants for notifications in `phase2/frontend/components/ui/Toast.tsx`
- [x] T017 Create useToast hook for toast state management in `phase2/frontend/hooks/useToast.ts`

**Deliverables**: Complete UI component library styled with Tailwind CSS and accessibility support.

---

## Phase 3: User Story 1 - View My Tasks (P1)

**Goal**: Display paginated task list with status filtering.
**Independent Test**: Sign in → navigate to `/tasks` → verify list displays with filters and pagination.
**FRs**: FR-001, FR-002, FR-002a, FR-003, FR-010, FR-014, FR-018
**Styling**: Use shared UI components and Tailwind utility classes.

### API Layer

- [x] T018 [US1] Implement listTasks API function with status/offset/limit params in `phase2/frontend/lib/api/tasks.ts`
- [x] T019 [US1] Create useTasks hook for list fetching with filter/pagination state in `phase2/frontend/hooks/useTasks.ts`

### Components

- [x] T020 [US1] Create TaskFilterTabs component using shared Tabs, Tailwind styling, URL sync, default "Pending" in `phase2/frontend/components/tasks/TaskFilterTabs.tsx`
- [x] T021 [US1] Create TaskItem component with Tailwind styling, status indicator, action buttons using shared Button in `phase2/frontend/components/tasks/TaskItem.tsx`
- [x] T022 [US1] Create TaskList component with Tailwind layout, shared Skeleton, "Load More" using shared Button in `phase2/frontend/components/tasks/TaskList.tsx`
- [x] T023 [US1] Create authenticated layout with Tailwind styling, session check, redirect in `phase2/frontend/app/(authenticated)/layout.tsx`
- [x] T024 [US1] Create tasks page with Tailwind layout integrating TaskFilterTabs and TaskList in `phase2/frontend/app/(authenticated)/tasks/page.tsx`
- [x] T025 [US1] Create loading.tsx with shared Skeleton placeholders in `phase2/frontend/app/(authenticated)/tasks/loading.tsx`

**Deliverables**: Working task list view styled with Tailwind, filtering and pagination.

---

## Phase 4: User Story 2 - Create Task (P1)

**Goal**: Enable task creation via modal form with validation.
**Independent Test**: Click "Add Task" → enter title → submit → verify task appears with highlight.
**FRs**: FR-004, FR-005, FR-005a, FR-005b, FR-016, FR-017, FR-019, FR-019a, FR-020
**Styling**: Use shared UI components (Modal, Input, Textarea, Button) with Tailwind classes.

### API Layer

- [x] T026 [US2] Implement createTask API function in `phase2/frontend/lib/api/tasks.ts`
- [x] T027 [US2] Create useTaskMutations hook with create/loading states in `phase2/frontend/hooks/useTaskMutations.ts`

### Components

- [x] T028 [US2] Create TaskForm component using shared Input/Textarea/Button, Tailwind validation styling in `phase2/frontend/components/tasks/TaskForm.tsx`
- [x] T029 [US2] Create TaskModal component wrapping shared Modal + TaskForm for create/edit modes in `phase2/frontend/components/tasks/TaskModal.tsx`
- [x] T030 [US2] Add "Add Task" using shared Button and create modal state to tasks page in `phase2/frontend/app/(authenticated)/tasks/page.tsx`
- [x] T031 [US2] Implement highlight effect using Tailwind animation classes for newly created tasks in `phase2/frontend/components/tasks/TaskItem.tsx`

**Deliverables**: Working create task flow styled with Tailwind, validation and highlight effect.

---

## Phase 5: User Story 3 - Edit Task (P2)

**Goal**: Enable task editing via modal form with pre-filled values.
**Independent Test**: Click edit on task → modify fields → submit → verify changes in list.
**FRs**: FR-006, FR-007, FR-016, FR-017, FR-019, FR-020
**Styling**: Reuses TaskForm with shared UI components and Tailwind classes.

### API Layer

- [x] T032 [US3] Implement updateTask API function (PATCH) in `phase2/frontend/lib/api/tasks.ts`
- [x] T033 [US3] Add update mutation to useTaskMutations hook in `phase2/frontend/hooks/useTaskMutations.ts`

### Components

- [x] T034 [US3] Add edit mode to TaskForm with Tailwind-styled status field and pre-populated values in `phase2/frontend/components/tasks/TaskForm.tsx`
- [x] T035 [US3] Add edit button using shared Button to TaskItem and wire edit modal state in `phase2/frontend/components/tasks/TaskItem.tsx`

**Deliverables**: Working edit task flow styled with Tailwind, status change capability.

---

## Phase 6: User Story 4 - Mark Task Complete (P2)

**Goal**: Enable one-click status toggle from task list.
**Independent Test**: Click checkbox on pending task → verify status changes to completed.
**FRs**: FR-008, FR-017, FR-019
**Styling**: Uses shared Checkbox component with Tailwind loading states.

- [x] T036 [US4] Add complete/uncomplete toggle using shared Checkbox with Tailwind loading state in `phase2/frontend/components/tasks/TaskItem.tsx`
- [x] T037 [US4] Implement status toggle in useTaskMutations using updateTask in `phase2/frontend/hooks/useTaskMutations.ts`
- [x] T038 [US4] Handle filter-aware list update (remove task from view if filtered out) in `phase2/frontend/hooks/useTasks.ts`

**Deliverables**: One-click complete/uncomplete styled with Tailwind, proper loading and filter behavior.

---

## Phase 7: User Story 5 - Delete Task (P2)

**Goal**: Enable task deletion with confirmation modal.
**Independent Test**: Click delete → confirm → verify task removed from list.
**FRs**: FR-009, FR-017, FR-019
**Styling**: Uses shared Modal and Button components with Tailwind classes.

### API Layer

- [x] T039 [US5] Implement deleteTask API function in `phase2/frontend/lib/api/tasks.ts`
- [x] T040 [US5] Add delete mutation to useTaskMutations hook in `phase2/frontend/hooks/useTaskMutations.ts`

### Components

- [x] T041 [US5] Create DeleteConfirmModal using shared Modal/Button with Tailwind styling in `phase2/frontend/components/tasks/DeleteConfirmModal.tsx`
- [x] T042 [US5] Add delete button using shared Button to TaskItem and wire delete modal state in `phase2/frontend/components/tasks/TaskItem.tsx`

**Deliverables**: Working delete flow styled with Tailwind, confirmation modal.

---

## Phase 8: User Stories 6 & 7 - Empty & Error States (P3)

**Goal**: Handle empty list and API error scenarios gracefully.
**Independent Test**: Create user with no tasks → verify empty state; simulate API error → verify error message.
**FRs**: FR-011, FR-012, FR-013, FR-015
**Styling**: Error and empty states use Tailwind color utilities and shared components.

- [x] T043 [US6] Create EmptyState component with Tailwind styling, CTA using shared Button in `phase2/frontend/components/tasks/EmptyState.tsx`
- [x] T044 [US6] Integrate EmptyState into TaskList for both scenarios in `phase2/frontend/components/tasks/TaskList.tsx`
- [x] T045 [US7] Add error state display with Tailwind error styling, retry using shared Button in `phase2/frontend/components/tasks/TaskList.tsx`
- [x] T046 [US7] Implement 401 redirect and error toast using shared Toast in API client in `phase2/frontend/lib/api/client.ts`

**Deliverables**: Comprehensive empty and error state handling styled with Tailwind.

---

## Phase 9: Polish & Accessibility (P3)

**Goal**: Ensure WCAG 2.1 AA compliance and keyboard accessibility.
**Agent**: `ui-ux-animation-designer` for accessibility audit, `frontend-router-specialist` for fixes.
**SCs**: SC-008, SC-009
**Styling**: All visual polish via Tailwind utilities; no custom CSS files.

- [x] T047 Add ARIA labels to all interactive elements across components in `phase2/frontend/components/`
- [x] T048 Implement focus management for modal open/close in `phase2/frontend/components/ui/Modal.tsx`
- [x] T049 Add keyboard handlers (Enter submit, Escape close) to forms and modals in `phase2/frontend/components/tasks/`
- [x] T050 Add Tailwind focus ring/outline indicators and tab order verification across all components in `phase2/frontend/components/`
- [x] T051 Create root layout with Tailwind base styles and providers in `phase2/frontend/app/layout.tsx`

**Deliverables**: WCAG 2.1 AA compliant, keyboard-accessible interface styled with Tailwind.

---

## Dependency Graph

```
Phase 1 (Setup) ─────────────────────────────────┐
                                                  │
Phase 2 (UI Components) ─────────────────────────┤
                                                  │
                    ┌─────────────────────────────┴─────────────────────────────┐
                    │                                                           │
                    ▼                                                           │
           Phase 3 (US1: View) ◄──────── Required for all other user stories   │
                    │                                                           │
        ┌───────────┴───────────┐                                              │
        │                       │                                              │
        ▼                       ▼                                              │
Phase 4 (US2: Create)    Phase 6 (US4: Complete)                              │
        │                       │                                              │
        ▼                       │                                              │
Phase 5 (US3: Edit) ◄───────────┘ (Shares TaskForm, updateTask)               │
                                                                               │
Phase 7 (US5: Delete) ◄──────────────────────────────────────────────────────┤
                                                                               │
Phase 8 (US6-7: Empty/Error) ◄─────────────────────────────────────────────────┤
                                                                               │
Phase 9 (Polish) ◄─────────────────────────────────────────────────────────────┘
```

---

## Parallel Execution Opportunities

### Within Phase 1 (Setup)
```
T001 (init) → then parallel: T002, T003, T004, T005
T006, T007, T008 can run after T001 completes
```

### Within Phase 2 (UI Components)
```
All [P] tasks (T009-T014) can run in parallel
T015 (Modal) → then T016 (Toast) → then T017 (useToast)
```

### Within Phase 3 (US1)
```
T018, T019 (API layer) can run in parallel
T020, T021 can run in parallel after T018/T019
T022 depends on T021
T023, T024, T025 sequential (layout → page → loading)
```

### Across User Stories
```
After US1 complete:
- US2 (Create) and US4 (Complete) can run in parallel
- US3 (Edit) depends on US2 (shares TaskForm)
- US5 (Delete) can run parallel to US2/US3/US4
- US6/US7 (Empty/Error) can run parallel to US3-5
```

---

## Agent Assignment Recommendations

| Task Range | Recommended Agent | Rationale |
|------------|-------------------|-----------|
| T001-T008 | `frontend-router-specialist` | Project setup, routing, API client |
| T009-T017 | `ui-ux-animation-designer` | UI component design specs |
| T009-T017 | `frontend-router-specialist` | Component implementation |
| T018-T046 | `frontend-router-specialist` | Feature implementation |
| T047-T051 | `ui-ux-animation-designer` | Accessibility audit |
| T047-T051 | `frontend-router-specialist` | Accessibility fixes |

---

## MVP Scope (Recommended)

**Minimum Viable Product**: Phases 1-4 (Setup + UI + US1 + US2)

This delivers:
- ✅ Task list view with filtering and pagination
- ✅ Task creation with validation
- ✅ Loading and basic error states
- ✅ Auth protection

**Tasks for MVP**: T001-T031 (31 tasks)

**Post-MVP**: Phases 5-9 add edit, complete toggle, delete, and polish.

---

## Definition of Done (Per Task)

- [ ] Code compiles with no TypeScript errors
- [ ] Component renders correctly
- [ ] All styling uses Tailwind utility classes only (no raw CSS or inline styles)
- [ ] Uses shared UI components where applicable
- [ ] Accessibility attributes present (where applicable)
- [ ] No console errors or warnings
- [ ] Follows project structure from plan.md
