---
description: "Task list for Todo Operations (View, Update, Delete, Mark Complete) implementation"
---

# Tasks: Todo Operations (View, Update, Delete, Mark Complete)

**Input**: Design documents from `/specs/001-todo-operations/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Test tasks are included based on the project's emphasis on quality and validation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: No additional setup needed as infrastructure exists from previous feature

- [x] T001 Verify existing project structure from previous feature is in place

---
## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Extend existing service layer with new operations

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 Extend TodoService with get_all_todos method in src/services/todo_service.py
- [x] T003 Extend TodoService with get_todo_by_id method in src/services/todo_service.py
- [x] T004 Extend TodoService with update_todo method in src/services/todo_service.py
- [x] T005 Extend TodoService with delete_todo method in src/services/todo_service.py
- [x] T006 Extend TodoService with mark_complete method in src/services/todo_service.py
- [x] T007 Extend TodoService with mark_incomplete method in src/services/todo_service.py
- [x] T008 [P] Create unit tests for get_all_todos in tests/unit/test_todo.py
- [x] T009 [P] Create unit tests for update_todo in tests/unit/test_todo.py
- [x] T010 [P] Create unit tests for delete_todo in tests/unit/test_todo.py
- [x] T011 [P] Create unit tests for mark_complete/mark_incomplete in tests/unit/test_todo.py

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---
## Phase 3: User Story 1 - View Todos (Priority: P1) 🎯 MVP

**Goal**: Enable users to view all their todo items in a clear, organized list with status indicators

**Independent Test**: User can see a list of all their todos with titles, descriptions, and completion status clearly displayed

### Tests for User Story 1 (Test-Driven Development) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T012 [P] [US1] Create test for viewing all todos when list is empty in tests/unit/test_todo.py
- [x] T013 [P] [US1] Create test for viewing all todos with multiple items in tests/unit/test_todo.py
- [x] T014 [P] [US1] Create integration test for viewing todos in tests/integration/test_todo_service.py

### Implementation for User Story 1

- [x] T015 [US1] Implement view todos functionality in CLI interface in src/cli/main.py
- [x] T016 [US1] Add view todos menu option to main menu in src/cli/main.py
- [x] T017 [US1] Format and display todos with ID, title, description, and status in src/cli/main.py

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---
## Phase 4: User Story 2 - Update Todo (Priority: P2)

**Goal**: Allow users to modify existing todo items to update titles or descriptions as needed

**Independent Test**: User can select an existing todo by ID and update its title and/or description successfully

### Tests for User Story 2 (Test-Driven Development) ⚠️

- [x] T018 [P] [US2] Create test for updating todo title successfully in tests/unit/test_todo.py
- [x] T019 [P] [US2] Create test for updating todo description successfully in tests/unit/test_todo.py
- [x] T020 [P] [US2] Create test for updating non-existent todo in tests/unit/test_todo.py
- [x] T021 [P] [US2] Create integration test for updating todos in tests/integration/test_todo_service.py

### Implementation for User Story 2

- [x] T022 [US2] Implement update todo functionality in CLI interface in src/cli/main.py
- [x] T023 [US2] Add update todo menu option to main menu in src/cli/main.py
- [x] T024 [US2] Implement validation for update operations in src/services/todo_service.py

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---
## Phase 5: User Story 3 - Delete Todo (Priority: P3)

**Goal**: Allow users to remove completed or irrelevant todos from their list

**Independent Test**: User can select a todo by ID and remove it from their list permanently

### Tests for User Story 3 (Test-Driven Development) ⚠️

- [x] T025 [P] [US3] Create test for deleting existing todo successfully in tests/unit/test_todo.py
- [x] T026 [P] [US3] Create test for attempting to delete non-existent todo in tests/unit/test_todo.py
- [x] T027 [P] [US3] Create integration test for deleting todos in tests/integration/test_todo_service.py

### Implementation for User Story 3

- [x] T028 [US3] Implement delete todo functionality in CLI interface in src/cli/main.py
- [x] T029 [US3] Add delete todo menu option to main menu in src/cli/main.py
- [x] T030 [US3] Implement validation for delete operations in src/services/todo_service.py

**Checkpoint**: At this point, User Stories 1, 2 AND 3 should all work independently

---
## Phase 6: User Story 4 - Mark Todo Complete/Incomplete (Priority: P4)

**Goal**: Allow users to track the progress of their tasks by marking them as complete or incomplete

**Independent Test**: User can mark any todo as complete or incomplete to track their progress

### Tests for User Story 4 (Test-Driven Development) ⚠️

- [x] T031 [P] [US4] Create test for marking incomplete todo as complete in tests/unit/test_todo.py
- [x] T032 [P] [US4] Create test for marking complete todo as incomplete in tests/unit/test_todo.py
- [x] T033 [P] [US4] Create test for attempting to mark non-existent todo status in tests/unit/test_todo.py
- [x] T034 [P] [US4] Create integration test for marking todo status in tests/integration/test_todo_service.py

### Implementation for User Story 4

- [x] T035 [US4] Implement mark complete functionality in CLI interface in src/cli/main.py
- [x] T036 [US4] Implement mark incomplete functionality in CLI interface in src/cli/main.py
- [x] T037 [US4] Add mark complete/incomplete menu options to main menu in src/cli/main.py
- [x] T038 [US4] Implement validation for status change operations in src/services/todo_service.py

**Checkpoint**: At this point, all User Stories should work independently

---
## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T039 [P] Add docstrings to all new methods in src/services/todo_service.py and src/cli/main.py
- [x] T040 Update main menu to include all new operations in src/cli/main.py
- [x] T041 Code cleanup and refactoring across all modules
- [x] T042 Run quickstart.md validation to ensure all functionality works as described
- [x] T043 Final integration testing across all features

---
## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - verification only
- **Foundational (Phase 2)**: Depends on existing infrastructure from previous feature - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3 → P4)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May build on US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May build on US1/US2 but should be independently testable
- **User Story 4 (P4)**: Can start after Foundational (Phase 2) - May build on US1/US2/US3 but should be independently testable

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Services before CLI
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---
## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Create test for viewing all todos when list is empty in tests/unit/test_todo.py"
Task: "Create test for viewing all todos with multiple items in tests/unit/test_todo.py"
Task: "Create integration test for viewing todos in tests/integration/test_todo_service.py"

# Launch all implementation for User Story 1 together:
Task: "Implement view todos functionality in CLI interface in src/cli/main.py"
Task: "Add view todos menu option to main menu in src/cli/main.py"
```

---
## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Add User Story 4 → Test independently → Deploy/Demo
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
   - Developer D: User Story 4
3. Stories complete and integrate independently

---
## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence