---
id: "0003"
title: "UI Theme Motion Tasks Generation"
stage: tasks
date: 2024-12-15
surface: agent
model: claude-sonnet-4-5-20250929
feature: 006-ui-theme-motion
branch: 006-ui-theme-motion
user: user
command: /sp.tasks
labels: ["ui-theme", "motion", "tasks", "phase2-chunk5"]
links:
  spec: specs/006-ui-theme-motion/spec.md
  ticket: null
  adr: null
  pr: null
files:
  - specs/006-ui-theme-motion/tasks.md
tests:
  - N/A (planning phase)
---

## Prompt

Generate the Tasks phase for Phase II Chunk 5: UI Theme, Motion and Calm Experience.

Break the work into small 30–90 minute tasks that:
- Follow the plan's phases (Phase 1: Design tokens, Phase 2: Core UI, Phase 3: Apply theme + motion + greeting, Phase 4: Responsiveness + motion-safety)
- Are specific and actionable with concrete files/components
- Include tasks for time-of-day greeting, animations, responsiveness, prefers-reduced-motion verification

## Response snapshot

Generated comprehensive tasks.md with 40 tasks across 5 phases:

**Phase 1: Design Foundation (T001-T005)**
- Create TimePeriod type definition
- Add semantic color tokens to Tailwind config
- Add spacing, radius, typography tokens
- Define time-of-day gradient classes in globals.css
- Add reduced motion CSS overrides

**Phase 2: Core UI Components (T006-T015)**
- Create useReducedMotion hook
- Update Button, Input, Textarea, Checkbox, Modal, Toast, Skeleton, Tabs components

**Phase 3: Task Components + List Animations (T016-T028)**
- Install framer-motion dependency
- Create AnimatedList wrapper component
- Create useTimeOfDay hook
- Create GreetingHeader component
- Update TaskItem, TaskList, EmptyState, TaskModal, DeleteConfirmModal, TaskFilterTabs, TaskSearchInput, TaskSortDropdown

**Phase 4: Page Integration + Auth Screens (T029-T035)**
- Update authenticated layout with greeting and gradient
- Update tasks page, loading state
- Update login and register pages

**Phase 5: Polish, QA & Accessibility (T036-T040)**
- Verify 60fps animations
- Test prefers-reduced-motion
- Run WCAG AA contrast checks
- Test edge cases
- Final visual consistency audit

**Statistics**: 40 tasks total (18 P1, 22 P2), 6 files to create, ~20 files to modify

## Outcome

- Impact: Complete task breakdown ready for implementation
- Tests: N/A (planning phase)
- Files: 1 file created (tasks.md)
- Next prompts: /sp.implement to begin Phase 1 implementation
- Reflection: Tasks are granular with specific file paths; dependency chain ensures correct ordering

## Evaluation notes (flywheel)

- Failure modes observed: None
- Graders run and results (PASS/FAIL): Task coverage check PASS
- Prompt variant (if applicable): N/A
- Next experiment (smallest change to try): N/A
