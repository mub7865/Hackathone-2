---
id: "0002"
title: "UI Theme Motion Implementation Plan"
stage: plan
date: 2024-12-14
surface: agent
model: claude-sonnet-4-5-20250929
feature: 006-ui-theme-motion
branch: 006-ui-theme-motion
user: user
command: /sp.plan
labels: ["ui-theme", "motion", "implementation-plan", "phase2-chunk5"]
links:
  spec: specs/006-ui-theme-motion/spec.md
  ticket: null
  adr: null
  pr: null
files:
  - specs/006-ui-theme-motion/plan.md
  - specs/006-ui-theme-motion/research.md
tests:
  - N/A (planning phase)
---

## Prompt

Generate the Plan phase for Phase II Chunk 5: UI Theme, Motion and Calm Experience.

Goals: Apply dark, calm design system across all screens. Add micro-interactions and time-of-day greeting. Keep existing functionality intact.

Requested: Architecture overview, implementation phases, component breakdown, dependencies and sequencing.

## Response snapshot

Created comprehensive 5-phase implementation plan:

Phase 1: Design Foundation - Tailwind tokens, gradients, reduced motion CSS
Phase 2: Core UI Components - Button, Input, Modal, Toast, Checkbox animations
Phase 3: Task Components - Framer Motion for list, GreetingHeader, useTimeOfDay hook
Phase 4: Page Integration - Auth screens, authenticated layout with greeting
Phase 5: Polish and QA - 60fps validation, WCAG checks, edge cases

Key Technical Decisions (from research.md):
- Tailwind CSS for 90% of animations
- Framer Motion AnimatePresence ONLY for list enter/exit
- Client-side useTimeOfDay hook
- session.user.name for personalized greeting

New Components: AnimatedList, GreetingHeader, useTimeOfDay, useReducedMotion, types/theme.ts

## Outcome

- Impact: Complete implementation roadmap ready for task generation
- Tests: N/A (planning phase)
- Files: 2 files created (plan.md, research.md)
- Next prompts: /sp.tasks to generate detailed task breakdown
- Reflection: Research phase resolved all technical unknowns; Framer Motion scoped narrowly

## Evaluation notes (flywheel)

- Failure modes observed: None
- Graders run and results (PASS/FAIL): Constitution check PASS
- Prompt variant (if applicable): N/A
- Next experiment (smallest change to try): N/A
