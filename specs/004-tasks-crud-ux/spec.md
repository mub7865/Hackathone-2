# Feature Specification: Tasks CRUD UX (Web App)

**Feature Branch**: `004-tasks-crud-ux`
**Created**: 2025-12-13
**Status**: Draft (Clarified)
**Input**: User description: "Authenticated Tasks experience in the Next.js frontend with list, create, edit, complete, and delete flows using existing backend API"

---

## Intent

This specification defines the frontend user experience for task management in the Todo web application. The feature provides authenticated users with a streamlined interface to view, create, edit, complete, and delete their personal tasks.

**Core Purpose**: Deliver a responsive, intuitive task management interface that enables signed-in users to efficiently manage their tasks without leaving the main tasks page.

**Key Characteristics**:
- Single-page hybrid layout at `/tasks` with overlay panels for create/edit actions
- Status-based filtering (All, Pending, Completed) with visual tab navigation; defaults to "Pending" on initial page load
- Immediate visual feedback for all user actions, including brief highlight animation for newly created tasks
- Graceful handling of loading, empty, and error states
- Full keyboard accessibility and screen reader support

**Primary User Scenario** (in order of importance):
1. **View tasks at a glance**: User lands on the tasks page and immediately sees their task list
2. **Quickly add a new task**: User creates a task without navigating away from the list
3. **Mark tasks complete or edit them**: User updates task status or details with minimal friction
4. **Delete unwanted tasks**: User removes tasks with appropriate confirmation

---

## Constraints

### Business Constraints
- **Authentication Required**: All task operations require a signed-in user; unauthenticated users are redirected to login
- **User Isolation**: Users can only see and manage their own tasks (enforced by backend API)
- **Data Source**: All task data comes from the existing `/api/v1/tasks` backend endpoints
- **No Offline Mode**: Application requires active network connection; no local caching or offline support

### UX Constraints
- **Hybrid Layout**: Main task list displayed at `/tasks` route; create and edit forms appear as slide-out panels or modals overlaying the list (no separate detail pages)
- **Tailwind-Based Styling**: All components MUST be styled using Tailwind CSS utility classes and any existing shared UI components; creating new raw CSS files (`.css`, `.scss`, `.sass`) or adding inline `style={{}}` attributes is NOT allowed for this feature
- **Filter Synchronization**: Status filter tabs must stay in sync with the current API query state
- **Wait-for-Response**: UI updates occur only after successful API responses (no optimistic updates)

### Integration Constraints
- **Auth Client Pre-wired**: Assumes authentication client is already configured and provides session/auth hooks
- **Typed API Client**: Assumes a typed API client exists that automatically attaches JWT tokens to requests
- **Backend API Contract**: Must consume existing endpoints as defined in `003-tasks-crud-api` spec:
  - `GET /api/v1/tasks` (list with pagination and status filter)
  - `POST /api/v1/tasks` (create)
  - `GET /api/v1/tasks/{id}` (single task)
  - `PATCH /api/v1/tasks/{id}` (update)
  - `DELETE /api/v1/tasks/{id}` (delete)

### Scope Constraints
- **Code Location**: All frontend code resides under `phase2/frontend` directory
- **Page Route**: Single route at `/tasks` (or equivalent app router path)

---

## User Scenarios & Testing

### User Story 1 - View My Tasks (Priority: P1)

A signed-in user navigates to the tasks page to see their current tasks at a glance.

**Why this priority**: Viewing tasks is the most frequent user action and the foundation for all other interactions. Users must be able to see their tasks before they can manage them.

**Independent Test**: Can be fully tested by signing in, navigating to `/tasks`, and verifying the task list displays with correct data, pagination, and filtering.

**Acceptance Scenarios**:

1. **Given** a signed-in user with 5 tasks (3 pending, 2 completed), **When** they navigate to `/tasks` for the first time, **Then** they see only the 3 pending tasks with the "Pending" tab selected by default.
2. **Given** a signed-in user with 25 tasks, **When** they view the tasks page with default settings, **Then** they see the first 20 tasks with pagination controls to load more.
3. **Given** a signed-in user viewing tasks, **When** they click "Load More" or scroll to trigger pagination, **Then** the next page of tasks appends to the list.
4. **Given** a signed-in user with pending and completed tasks, **When** they select the "Pending" filter tab, **Then** only pending tasks are displayed and the tab appears selected.
5. **Given** a signed-in user with pending and completed tasks, **When** they select the "Completed" filter tab, **Then** only completed tasks are displayed.
6. **Given** a signed-in user with pending and completed tasks, **When** they select the "All" filter tab, **Then** all tasks are displayed regardless of status.
7. **Given** tasks are being fetched, **When** the user waits, **Then** they see a loading indicator (skeleton or spinner) until data arrives.
8. **Given** an unauthenticated user, **When** they navigate to `/tasks`, **Then** they are redirected to the login page.

---

### User Story 2 - Create a New Task (Priority: P1)

A signed-in user adds a new task to their list quickly without leaving the page.

**Why this priority**: Task creation is essential for the app to provide value. Users need to add tasks easily to build their task list.

**Independent Test**: Can be tested by opening the create form, entering valid data, submitting, and verifying the new task appears in the list.

**Acceptance Scenarios**:

1. **Given** a signed-in user on the tasks page, **When** they click the "Add Task" button, **Then** a create form panel/modal appears overlaying the task list.
2. **Given** the create form is open, **When** the user enters a title and submits, **Then** the task is created and appears at the top of the task list with a brief highlight effect (subtle background or border) to draw attention.
3. **Given** the create form is open, **When** the user enters a title and optional description and submits, **Then** both fields are saved to the new task.
4. **Given** the create form is open, **When** the user submits without entering a title, **Then** a validation error message is displayed and the form is not submitted.
5. **Given** the create form is open, **When** the user types in the title field, **Then** a character counter shows remaining characters (out of 255 max) and input is prevented beyond 255 characters.
6. **Given** the create form is open, **When** the user clicks outside the panel or clicks a close button, **Then** the form closes without creating a task.
7. **Given** task creation is in progress, **When** the user waits, **Then** the submit button shows a loading state and is disabled.
8. **Given** task creation succeeds, **When** the response is received, **Then** the form closes, the list refreshes, and a success message is shown.
9. **Given** task creation fails (API error), **When** the error response is received, **Then** an error message is displayed and the form remains open for retry.

---

### User Story 3 - Edit an Existing Task (Priority: P2)

A signed-in user modifies the title, description, or status of an existing task.

**Why this priority**: Editing allows users to correct mistakes and update task details, which is core to ongoing task management.

**Independent Test**: Can be tested by opening the edit form for a task, modifying fields, submitting, and verifying changes persist.

**Acceptance Scenarios**:

1. **Given** a signed-in user viewing their task list, **When** they click the edit action on a task, **Then** an edit form panel/modal appears with the task's current values pre-filled.
2. **Given** the edit form is open, **When** the user changes the title and submits, **Then** the task title is updated in the list.
3. **Given** the edit form is open, **When** the user changes the description and submits, **Then** the task description is updated.
4. **Given** the edit form is open, **When** the user changes the status and submits, **Then** the task status is updated and the task moves to the appropriate filter group.
5. **Given** the edit form is open, **When** the user clears the title and submits, **Then** a validation error is displayed (title required).
6. **Given** the edit form is open, **When** the user types in the title field, **Then** a character counter shows remaining characters (out of 255 max) and input is prevented beyond 255 characters.
7. **Given** task update is in progress, **When** the user waits, **Then** the submit button shows a loading state.
8. **Given** task update fails (API error), **When** the error response is received, **Then** an error message is displayed and original values can be restored.

---

### User Story 4 - Mark Task as Complete (Priority: P2)

A signed-in user quickly marks a task as completed directly from the task list.

**Why this priority**: Completing tasks is the primary goal of task management and should be as frictionless as possible.

**Independent Test**: Can be tested by clicking the complete action on a pending task and verifying the status changes.

**Acceptance Scenarios**:

1. **Given** a signed-in user viewing a pending task, **When** they click the "complete" action (checkbox or button), **Then** the task status changes to "completed" with visual feedback.
2. **Given** the complete action is triggered, **When** the API request is in progress, **Then** the action control shows a loading/disabled state.
3. **Given** the complete action succeeds, **When** the response is received, **Then** the task visually updates to show completed status (e.g., strikethrough, checkmark).
4. **Given** the "Pending" filter is active and a task is completed, **When** the update succeeds, **Then** the task is removed from the visible list (filtered out).
5. **Given** a signed-in user viewing a completed task, **When** they click an "uncomplete" action, **Then** the task status changes back to "pending".

---

### User Story 5 - Delete a Task (Priority: P2)

A signed-in user removes a task they no longer need.

**Why this priority**: Deletion allows users to clean up their task list and is necessary for complete task lifecycle management.

**Independent Test**: Can be tested by triggering delete on a task, confirming, and verifying the task is removed from the list.

**Acceptance Scenarios**:

1. **Given** a signed-in user viewing a task, **When** they click the "delete" action, **Then** a confirmation prompt appears asking them to confirm deletion.
2. **Given** the delete confirmation is shown, **When** the user confirms, **Then** the task is deleted and removed from the list.
3. **Given** the delete confirmation is shown, **When** the user cancels, **Then** the prompt closes and the task remains.
4. **Given** deletion is in progress, **When** the user waits, **Then** a loading indicator is shown.
5. **Given** deletion succeeds, **When** the response is received, **Then** the task disappears from the list and a success message is shown.
6. **Given** deletion fails (API error), **When** the error response is received, **Then** an error message is displayed and the task remains in the list.

---

### User Story 6 - Handle Empty State (Priority: P3)

A signed-in user with no tasks sees helpful guidance instead of a blank page.

**Why this priority**: Empty states guide new users and provide a clear call-to-action, improving first-time user experience.

**Independent Test**: Can be tested by signing in as a user with zero tasks and verifying the empty state message and CTA appear.

**Acceptance Scenarios**:

1. **Given** a signed-in user with no tasks, **When** they view the tasks page, **Then** they see an empty state message (e.g., "No tasks yet") with a call-to-action to create their first task.
2. **Given** a signed-in user with tasks but none matching the current filter, **When** they view the filtered list, **Then** they see an appropriate message (e.g., "No pending tasks" or "No completed tasks").
3. **Given** the empty state is displayed, **When** the user clicks the create CTA, **Then** the create form opens.

---

### User Story 7 - Handle Error States (Priority: P3)

A signed-in user sees informative error messages when something goes wrong.

**Why this priority**: Clear error handling maintains user trust and helps users understand and recover from problems.

**Independent Test**: Can be tested by simulating API failures and verifying appropriate error messages appear.

**Acceptance Scenarios**:

1. **Given** the task list fails to load (API error), **When** the error occurs, **Then** an error message is displayed with an option to retry.
2. **Given** an authentication error (401), **When** any API call fails with 401, **Then** the user is redirected to login.
3. **Given** a validation error (422), **When** a form submission fails, **Then** field-level error messages are displayed.
4. **Given** a server error (500), **When** any operation fails, **Then** a generic error message is shown with retry option.
5. **Given** a network error, **When** the request times out or fails, **Then** a connectivity error message is shown.

---

### Edge Cases

- What happens when user rapidly clicks "complete" multiple times? → The action control is disabled during the API call to prevent duplicate requests.
- What happens when the session expires mid-interaction? → 401 response triggers redirect to login; any unsaved form data is lost.
- What happens when pagination reaches the end? → "Load More" button is hidden or disabled when no more tasks exist.
- What happens when a filter is applied and then tasks are created? → New tasks appear if they match the current filter; otherwise they're created but not visible until filter changes.
- What happens when two browser tabs are open? → No automatic sync; each tab operates independently. Refresh shows latest data.

---

## Requirements

### Functional Requirements

- **FR-001**: System MUST display a paginated list of the authenticated user's tasks at the `/tasks` route
- **FR-002**: System MUST provide filter tabs for "All", "Pending", and "Completed" status filtering
- **FR-002a**: System MUST default to the "Pending" filter tab when the user first navigates to `/tasks`
- **FR-003**: System MUST keep filter tabs visually synchronized with the current API query state
- **FR-004**: System MUST provide an "Add Task" action that opens a create form as a panel/modal overlay
- **FR-005**: System MUST validate that task title is non-empty before allowing form submission
- **FR-005a**: System MUST enforce a 255-character maximum for task titles with a visible character counter
- **FR-005b**: System MUST prevent input beyond 255 characters (not just warn)
- **FR-006**: System MUST provide an edit action for each task that opens an edit form with pre-filled values
- **FR-007**: System MUST allow editing of task title, description, and status
- **FR-008**: System MUST provide a quick "complete" action to mark pending tasks as completed
- **FR-009**: System MUST provide a delete action with confirmation prompt before removing tasks
- **FR-010**: System MUST display a loading indicator while fetching task data
- **FR-011**: System MUST display an empty state message with CTA when no tasks exist
- **FR-012**: System MUST display an empty state message when no tasks match the current filter
- **FR-013**: System MUST display error messages when API operations fail
- **FR-014**: System MUST redirect unauthenticated users to the login page
- **FR-015**: System MUST redirect users to login when receiving 401 authentication errors
- **FR-016**: System MUST display field-level validation errors for form submissions
- **FR-017**: System MUST disable action controls during in-progress API operations to prevent duplicate submissions
- **FR-018**: System MUST provide pagination controls (e.g., "Load More") when more tasks exist beyond the current page
- **FR-019**: System MUST update the task list after successful create, update, or delete operations
- **FR-019a**: System MUST display newly created tasks at the top of the list with a brief highlight effect (subtle background or border) to draw user attention
- **FR-020**: System MUST allow closing create/edit forms without submitting

### Key Entities

- **Task**: A user's task item with title (required), description (optional), and status (pending/completed)
- **Task List**: A paginated collection of the user's tasks with status filter applied
- **Create Form**: Input form for new tasks with title and description fields
- **Edit Form**: Input form for modifying existing tasks with title, description, and status fields
- **Filter Tabs**: Navigation element to switch between All, Pending, and Completed views

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can view their complete task list within 3 seconds of page load under normal network conditions
- **SC-002**: Users can create a new task in under 10 seconds (from clicking "Add Task" to seeing the task in the list)
- **SC-003**: Users can mark a task complete in under 2 seconds (single click/tap to visual confirmation)
- **SC-004**: Users can edit a task in under 15 seconds (from clicking edit to seeing updated task in list)
- **SC-005**: Users can delete a task in under 5 seconds (including confirmation step)
- **SC-006**: 100% of unauthenticated access attempts result in redirect to login (no task data exposed)
- **SC-007**: All user flows are testable with automated tests (create, read, update, delete, filter, paginate)
- **SC-008**: All interactive elements are keyboard accessible (tab navigation, enter to submit, escape to close)
- **SC-009**: All interactive elements have appropriate ARIA labels for screen reader users
- **SC-010**: Filter state persists correctly: switching between tabs shows only matching tasks without full page reload
- **SC-011**: Form validation prevents submission of invalid data and displays clear error messages
- **SC-012**: Users always see appropriate feedback: loading states during operations, success/error messages after completion

---

## Non-Goals

The following are explicitly **out of scope** for this specification:

- **Advanced Filtering/Search**: No text search, date filters, or sorting options beyond basic status filter
- **Sorting Options**: No user-selectable sort order (backend returns tasks in default order)
- **Drag-and-Drop Reordering**: No manual task ordering through drag-and-drop
- **Optimistic Updates**: No immediate UI updates before API confirmation (wait for response)
- **Offline/PWA Support**: No offline capability, service workers, or local data persistence
- **Theme/Branding Work**: No visual theming, color schemes, or brand styling (separate chunk)
- **Animation/Motion System**: No transition animations, micro-interactions, or motion design (separate chunk)
- **Authentication Implementation**: No login/signup flows, session management, or Better Auth configuration (assumed pre-wired)
- **Separate Detail Pages**: No `/tasks/[id]` routes; all detail views are in overlay panels
- **Bulk Operations**: No multi-select or batch actions on tasks
- **Due Dates/Reminders**: No date-based features or notifications
- **Task Categories/Tags**: No labeling or categorization system
- **Real-time Updates**: No WebSocket or polling for live data sync across tabs/devices

---

## Clarifications

### Session 2025-12-13

| Question | Decision | Rationale |
|----------|----------|-----------|
| Default filter tab on page load | "Pending" tab selected by default | Users see actionable items first; completed tasks available via tab switch |
| New task placement in list | Top of list with brief highlight effect | Matches backend `created_at DESC` sort; highlight draws user attention to new item |
| Title character limit enforcement | Frontend enforces 255-char limit with counter; input prevented beyond limit | Better UX than hitting backend 422; user sees constraint before submitting |

---

## Assumptions

- Better Auth client is configured and provides session hooks (e.g., `useSession`) for authentication state
- A typed API client exists that automatically attaches JWT tokens to all requests
- The backend API at `/api/v1/tasks` is fully operational per the `003-tasks-crud-api` specification
- Users have modern browsers with JavaScript enabled
- Standard web performance expectations apply (sub-second interactions on typical connections)
- Pagination uses offset/limit with 20 items per page (matching backend defaults)

---

## Dependencies

- **003-tasks-crud-api**: Backend REST API for task CRUD operations (completed)
- **Better Auth**: Authentication provider (assumed configured)
- **Phase II Frontend Foundation**: Base Next.js application structure under `phase2/frontend`
