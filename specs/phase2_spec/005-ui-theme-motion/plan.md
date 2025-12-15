# Implementation Plan: UI Theme, Motion & Calm Experience

**Branch**: `006-ui-theme-motion` | **Date**: 2024-12-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-ui-theme-motion/spec.md`

---

## Summary

Transform the existing Phase II todo web app into a calm, premium-feeling product by:
1. Establishing a documented design system with semantic tokens in Tailwind config
2. Applying cohesive dark theme with time-of-day gradient variations across all screens
3. Adding smooth micro-interactions using Tailwind transitions + Framer Motion (for list animations only)
4. Implementing personalized greeting using authenticated user's name from session
5. Ensuring accessibility via `prefers-reduced-motion` support and WCAG AA contrast
6. **Wow Layer**: Ambient background animations (orbital rings, corner orb), refined header with profile avatar dropdown, Focus Summary and Reflection panels, and footer

**Technical Approach**: Tailwind CSS for 90% of animations, Framer Motion AnimatePresence for list enter/exit only, CSS keyframes for ambient animations, client-side time detection hook, session-based personalization.

---

## Technical Context

**Language/Version**: TypeScript 5.x, React 18+, Next.js 16 App Router
**Primary Dependencies**: Tailwind CSS 3.4+, Framer Motion 11.x (new), React 18
**Storage**: N/A (no data changes in this chunk)
**Testing**: Manual visual testing, browser dev tools for 60fps validation
**Target Platform**: Web (desktop/mobile responsive)
**Project Type**: Web application (frontend-only changes)
**Performance Goals**: 60fps animations (no frames >16ms)
**Constraints**: Only `transform` and `opacity` for animations; respect reduced motion
**Scale/Scope**: 9 screens/states + wow layer (ambient background, refined header, panels, footer)

---

## Constitution Check

*GATE: Must pass before implementation. Verified against `.specify/memory/constitution.md`*

| Principle | Status | Notes |
|-----------|--------|-------|
| Strict SDD | PASS | Spec exists at `specs/006-ui-theme-motion/spec.md` |
| AI-Native Architecture | N/A | No AI features in this chunk |
| Progressive Evolution | PASS | Frontend-only changes; no backend/API modifications |
| Documentation First | PASS | Spec + Plan created before implementation |
| Tech Stack Adherence | PASS | Next.js 16, Tailwind CSS per Phase II requirements |
| No Vibe Coding | PASS | All changes traceable to spec requirements |
| Phase Logic | PASS | This is Phase II work; no Phase III features |

---

## Architecture Overview

### 1. UI Layer Organization

```
+------------------------------------------------------------------+
|                        Design Tokens                              |
|              (tailwind.config.ts - colors, spacing, etc.)         |
+------------------------------------------------------------------+
                                |
                                v
+------------------------------------------------------------------+
|                      Base UI Components                           |
|  Button, Input, Textarea, Checkbox, Modal, Toast, Skeleton        |
|              (components/ui/ - consume tokens)                    |
+------------------------------------------------------------------+
                                |
                                v
+------------------------------------------------------------------+
|                    Feature Components                             |
|    TaskItem, TaskList, TaskModal, EmptyState, FilterTabs          |
|         (components/tasks/ - compose base components)             |
+------------------------------------------------------------------+
                                |
                                v
+------------------------------------------------------------------+
|                      Layout & Pages                               |
|   AuthenticatedLayout (greeting + gradient), Login, Register      |
|              (app/ - compose feature components)                  |
+------------------------------------------------------------------+
```

### 2. Time-of-Day Theming Integration

```
+------------------+     +------------------+     +------------------+
|  useTimeOfDay()  |---->|  TimePeriod      |---->|  Gradient Class  |
|  (client hook)   |     | morning/afternoon|     |  bg-gradient-*   |
|                  |     | /evening         |     |                  |
+------------------+     +------------------+     +------------------+
         |
         v
+------------------+     +------------------+
|  getSession()    |---->|  GreetingHeader  |
|  (existing auth) |     |"Good morning,    |
|                  |     | Sarah"           |
+------------------+     +------------------+
```

### 3. Responsiveness Strategy

- **Mobile-first**: Default styles for < 640px
- **Breakpoints**: `sm:` (640px+) for tablet/desktop adjustments
- **No layout restructuring**: Existing responsive patterns preserved per Non-Goals

---

## Project Structure

### Documentation (this feature)

```text
specs/006-ui-theme-motion/
├── spec.md              # Feature specification
├── plan.md              # This implementation plan
├── research.md          # Technical decisions and rationale
├── checklists/
│   └── requirements.md  # Quality validation checklist
└── tasks.md             # Generated by /sp.tasks (next step)
```

### Source Code (phase2/frontend/)

```text
phase2/frontend/
├── tailwind.config.ts          # [MODIFY] Design tokens
├── app/
│   ├── globals.css             # [MODIFY] Gradient definitions, reduced motion
│   ├── layout.tsx              # [MINOR] Ensure dark mode
│   ├── login/page.tsx          # [MODIFY] Apply design system
│   ├── register/page.tsx       # [MODIFY] Apply design system
│   └── (authenticated)/
│       ├── layout.tsx          # [MODIFY] Greeting + gradient background
│       └── tasks/
│           ├── page.tsx        # [MINOR] Component composition
│           └── loading.tsx     # [MODIFY] Calm skeleton styles
├── components/
│   ├── ui/
│   │   ├── Button.tsx          # [MODIFY] Design tokens + transitions
│   │   ├── Input.tsx           # [MODIFY] Design tokens + focus
│   │   ├── Textarea.tsx        # [MODIFY] Design tokens + focus
│   │   ├── Checkbox.tsx        # [MODIFY] Smooth state transitions
│   │   ├── Modal.tsx           # [MODIFY] Fade/scale animations
│   │   ├── Toast.tsx           # [MODIFY] Calm styling
│   │   ├── Skeleton.tsx        # [MODIFY] Calm colors
│   │   ├── Tabs.tsx            # [MODIFY] Design tokens
│   │   ├── AnimatedList.tsx    # [CREATE] Framer Motion wrapper
│   │   └── index.ts            # [MODIFY] Export AnimatedList
│   ├── tasks/
│   │   ├── TaskItem.tsx        # [MODIFY] Design tokens
│   │   ├── TaskList.tsx        # [MODIFY] AnimatePresence integration
│   │   ├── EmptyState.tsx      # [MODIFY] Serene copy + styling
│   │   ├── TaskModal.tsx       # [MODIFY] Design tokens
│   │   ├── DeleteConfirmModal.tsx # [MODIFY] Design tokens
│   │   ├── TaskFilterTabs.tsx  # [MODIFY] Transitions
│   │   ├── TaskSearchInput.tsx # [MODIFY] Focus states
│   │   └── TaskSortDropdown.tsx # [MODIFY] Design tokens
│   └── layout/
│       └── GreetingHeader.tsx  # [CREATE] Time-aware greeting
├── hooks/
│   ├── useTimeOfDay.ts         # [CREATE] Time period detection
│   ├── useReducedMotion.ts     # [CREATE] Motion preference
│   ├── useTaskStats.ts         # [CREATE] Task statistics computation
│   └── index.ts                # [MODIFY] Export new hooks
├── types/
│   └── theme.ts                # [CREATE] TimePeriod type
└── components/
    ├── layout/
    │   ├── GreetingHeader.tsx      # [CREATE] Time-aware greeting
    │   ├── ProfileAvatar.tsx       # [CREATE] Avatar with initials + dropdown
    │   ├── ProfileDropdown.tsx     # [CREATE] Sign-out dropdown menu
    │   ├── OrbitalAuroraBelt.tsx   # [CREATE] Ambient orbital rings
    │   ├── CalmOrbitMarker.tsx     # [CREATE] Corner orb animation
    │   ├── FocusSummaryPanel.tsx   # [CREATE] Task stats panel
    │   ├── ReflectionPanel.tsx     # [CREATE] Motivational text panel
    │   └── Footer.tsx              # [CREATE] Authenticated footer
    └── ui/
        └── ProgressBar.tsx         # [CREATE] Visual progress indicator
```

**Structure Decision**: Frontend-only modifications within existing `phase2/frontend/` structure. No backend changes.

---

## Implementation Phases

### Phase 1: Design Foundation (Tokens + Global Styles)

**Goal**: Establish the design system foundation that all subsequent work depends on.

**Tasks**:
1. Update `tailwind.config.ts` with semantic color tokens
2. Add spacing, radius, and typography tokens
3. Define time-of-day gradient classes in `globals.css`
4. Add reduced motion CSS overrides
5. Create `types/theme.ts` with `TimePeriod` type

**Files Changed**:
- `tailwind.config.ts`
- `app/globals.css`
- `types/theme.ts` (new)

**Done When**:
- SC-007: Design tokens fully documented in tailwind.config.ts with semantic naming
- Gradients render correctly for morning/afternoon/evening
- `motion-reduce:` classes work in Tailwind

**Dependencies**: None (foundation layer)

---

### Phase 2: Core UI Components

**Goal**: Update all base UI components to use design tokens and add smooth transitions.

**Tasks**:
1. Create `useReducedMotion` hook
2. Update `Button.tsx` - design tokens + press feedback
3. Update `Input.tsx` - design tokens + focus ring transition
4. Update `Textarea.tsx` - design tokens + focus ring transition
5. Update `Checkbox.tsx` - smooth state change animation
6. Update `Modal.tsx` - fade + scale enter/exit
7. Update `Toast.tsx` - calm colors + slide animation
8. Update `Skeleton.tsx` - calm pulse colors
9. Update `Tabs.tsx` - design tokens + indicator transition

**Files Changed**:
- `hooks/useReducedMotion.ts` (new)
- `hooks/index.ts`
- `components/ui/Button.tsx`
- `components/ui/Input.tsx`
- `components/ui/Textarea.tsx`
- `components/ui/Checkbox.tsx`
- `components/ui/Modal.tsx`
- `components/ui/Toast.tsx`
- `components/ui/Skeleton.tsx`
- `components/ui/Tabs.tsx`

**Done When**:
- FR-010, FR-011: Modal animations work
- FR-013: Checkbox transitions smooth
- FR-018: Reduced motion respected
- FR-020: Focus states visible with transition
- All UI components use semantic token classes

**Dependencies**: Phase 1 (tokens must exist)

---

### Phase 3: Task Components + List Animations

**Goal**: Apply design system to task-specific components and implement list animations.

**Tasks**:
1. Install `framer-motion` dependency
2. Create `AnimatedList.tsx` wrapper component
3. Create `useTimeOfDay` hook
4. Create `GreetingHeader.tsx` component
5. Update `TaskItem.tsx` - design tokens
6. Update `TaskList.tsx` - integrate AnimatePresence
7. Update `EmptyState.tsx` - serene copy + styling
8. Update `TaskModal.tsx` - design tokens
9. Update `DeleteConfirmModal.tsx` - design tokens + calm error styling
10. Update `TaskFilterTabs.tsx` - transitions
11. Update `TaskSearchInput.tsx` - focus states
12. Update `TaskSortDropdown.tsx` - design tokens

**Files Changed**:
- `package.json` (add framer-motion)
- `components/ui/AnimatedList.tsx` (new)
- `components/ui/index.ts`
- `hooks/useTimeOfDay.ts` (new)
- `hooks/index.ts`
- `components/layout/GreetingHeader.tsx` (new)
- `components/tasks/TaskItem.tsx`
- `components/tasks/TaskList.tsx`
- `components/tasks/EmptyState.tsx`
- `components/tasks/TaskModal.tsx`
- `components/tasks/DeleteConfirmModal.tsx`
- `components/tasks/TaskFilterTabs.tsx`
- `components/tasks/TaskSearchInput.tsx`
- `components/tasks/TaskSortDropdown.tsx`

**Done When**:
- FR-012: New task entrance animation works
- FR-014: Task deletion animates out
- FR-015: Filter/sort changes animate list
- FR-006, FR-007, FR-008: Time-of-day greeting works with user name
- FR-027: Empty states use serene copy
- SC-006: No generic "No data" language

**Dependencies**: Phase 2 (base components must be styled)

---

### Phase 4: Page Integration + Auth Screens

**Goal**: Wire everything together at page level and style auth screens.

**Tasks**:
1. Update `(authenticated)/layout.tsx` - integrate greeting + gradient background
2. Update `tasks/page.tsx` - ensure components compose correctly
3. Update `tasks/loading.tsx` - calm skeleton styling
4. Update `login/page.tsx` - full design system application
5. Update `register/page.tsx` - full design system application
6. Verify time-of-day gradient transitions
7. Verify personalized greeting with session.user.name

**Files Changed**:
- `app/(authenticated)/layout.tsx`
- `app/(authenticated)/tasks/page.tsx`
- `app/(authenticated)/tasks/loading.tsx`
- `app/login/page.tsx`
- `app/register/page.tsx`

**Done When**:
- FR-009: Time-appropriate gradient on authenticated layout
- FR-021, FR-022: Auth pages use design system
- SC-002: Greeting shows user's actual name
- SC-001: All screens use design tokens

**Dependencies**: Phase 3 (greeting component must exist)

---

### Phase 5: Polish, QA & Accessibility

**Goal**: Final polish, performance validation, and accessibility verification.

**Tasks**:
1. Verify 60fps animations using Chrome DevTools Performance tab
2. Test `prefers-reduced-motion` across all flows
3. Run WCAG AA contrast checks on all color combinations
4. Test edge cases (long names, rapid filter changes, etc.)
5. Fix any visual inconsistencies
6. Update error states and toasts for calm styling

**Files Changed**: Various (bug fixes and polish)

**Done When**:
- SC-003: All must-have animations at 60fps
- SC-004: Zero transform/slide when reduced motion enabled
- SC-005: All colors pass WCAG AA
- SC-008: Interface feels calm and premium

**Dependencies**: Phase 4 (full integration required)

---

### Phase 6: Wow Layer – Ambient Background & Content Panels

**Goal**: Add premium visual polish with ambient animations, refined header, content panels, and footer.

**Tasks**:
1. Add CSS keyframes for orbital rotation and orb pulse animations in `globals.css`
2. Create `OrbitalAuroraBelt.tsx` component with 2-3 animated rings
3. Create `CalmOrbitMarker.tsx` component with pulsing corner orb
4. Create `ProfileAvatar.tsx` component with initials extraction logic
5. Create `ProfileDropdown.tsx` component with keyboard accessibility
6. Create `useTaskStats.ts` hook for computing pending/completed/total/percentage
7. Create `ProgressBar.tsx` UI component
8. Create `FocusSummaryPanel.tsx` with stats and progress bar
9. Create `ReflectionPanel.tsx` with rule-based motivational text
10. Create `Footer.tsx` component
11. Update `(authenticated)/layout.tsx` to integrate ambient background, refined header, and footer
12. Update `tasks/page.tsx` to integrate Focus Summary and Reflection panels with responsive layout
13. Test ambient animations respect reduced motion
14. Verify all panels are responsive (desktop: beside list, mobile: stacked below)

**Files Changed**:
- `app/globals.css` (add ambient animation keyframes)
- `components/layout/OrbitalAuroraBelt.tsx` (new)
- `components/layout/CalmOrbitMarker.tsx` (new)
- `components/layout/ProfileAvatar.tsx` (new)
- `components/layout/ProfileDropdown.tsx` (new)
- `components/layout/FocusSummaryPanel.tsx` (new)
- `components/layout/ReflectionPanel.tsx` (new)
- `components/layout/Footer.tsx` (new)
- `components/ui/ProgressBar.tsx` (new)
- `hooks/useTaskStats.ts` (new)
- `hooks/index.ts` (add export)
- `app/(authenticated)/layout.tsx` (integrate ambient + header + footer)
- `app/(authenticated)/tasks/page.tsx` (integrate panels)

**Done When**:
- SC-009: Orbital Aurora Belt and Calm Orbit Marker visible, time-of-day aware
- SC-010: Ambient animations static when reduced motion enabled
- SC-011: Profile avatar shows correct initials
- SC-012: Profile dropdown fully keyboard accessible
- SC-013: Focus Summary shows correct stats
- SC-014: Reflection shows correct rule-based text
- SC-015: Panels responsive at desktop/mobile breakpoints
- SC-016: Footer visible and non-overlapping

**Dependencies**: Phase 5 (base theme must be stable before adding wow layer)

---

### Phase 7: Final QA & Wow Layer Polish

**Goal**: Verify all wow layer elements work correctly and polish any issues.

**Tasks**:
1. Test ambient animations at all three time periods
2. Verify avatar initials for various name formats (full name, single name, email-only)
3. Test dropdown menu on mobile viewports
4. Verify Focus Summary calculations with various task states
5. Test Reflection text for all rule branches
6. Test footer positioning at all breakpoints
7. Performance test ambient animations (ensure no impact on 60fps)
8. Final visual audit of wow layer integration

**Files Changed**: Various (bug fixes and polish)

**Done When**:
- All SC-009 through SC-016 pass
- No visual regressions from earlier phases
- Ambient animations do not impact interactive element performance

**Dependencies**: Phase 6 (wow layer must be implemented)

---

## Dependencies and Sequencing

### Dependency Graph

```
Phase 1: Design Foundation
    |
    v
Phase 2: Core UI Components ------+
    |                             |
    v                             |
Phase 3: Task Components ---------+
    |                             |
    v                             |
Phase 4: Page Integration --------+
    |
    v
Phase 5: Polish & QA
    |
    v
Phase 6: Wow Layer (Ambient, Header, Panels, Footer)
    |
    v
Phase 7: Final QA & Wow Layer Polish
```

### Parallel Work Opportunities

| Phase | Parallelizable Within Phase |
|-------|----------------------------|
| Phase 1 | Tailwind config and globals.css can be edited in parallel |
| Phase 2 | All UI component updates are independent of each other |
| Phase 3 | AnimatedList and GreetingHeader are independent; task components depend on AnimatedList |
| Phase 4 | Login and Register can be done in parallel; authenticated layout must precede tasks |
| Phase 5 | QA tasks are sequential (must see full integration) |
| Phase 6 | Ambient components (OrbitalAuroraBelt, CalmOrbitMarker) are independent; Panels depend on useTaskStats hook; Footer is independent |
| Phase 7 | QA tasks are sequential |

### Critical Path

1. `tailwind.config.ts` tokens -> everything else
2. `Modal.tsx` animations -> `TaskModal.tsx`, `DeleteConfirmModal.tsx`
3. `AnimatedList.tsx` -> `TaskList.tsx`
4. `useTimeOfDay.ts` + `GreetingHeader.tsx` -> `(authenticated)/layout.tsx`
5. `useTaskStats.ts` -> `FocusSummaryPanel.tsx`, `ReflectionPanel.tsx`
6. `ProfileAvatar.tsx` + `ProfileDropdown.tsx` -> refined header in `layout.tsx`
7. All Phase 6 components -> `layout.tsx` and `tasks/page.tsx` integration

---

## Component Breakdown

### New Components to Create

| Component | Location | Purpose |
|-----------|----------|---------|
| `AnimatedList` | `components/ui/AnimatedList.tsx` | Framer Motion wrapper for list animations |
| `GreetingHeader` | `components/layout/GreetingHeader.tsx` | Time-aware personalized greeting |
| `useTimeOfDay` | `hooks/useTimeOfDay.ts` | Detect morning/afternoon/evening |
| `useReducedMotion` | `hooks/useReducedMotion.ts` | Detect user motion preference |
| `TimePeriod` | `types/theme.ts` | Type for time periods |
| `OrbitalAuroraBelt` | `components/layout/OrbitalAuroraBelt.tsx` | Ambient animated orbital rings |
| `CalmOrbitMarker` | `components/layout/CalmOrbitMarker.tsx` | Pulsing corner orb |
| `ProfileAvatar` | `components/layout/ProfileAvatar.tsx` | Circular avatar with initials |
| `ProfileDropdown` | `components/layout/ProfileDropdown.tsx` | Sign-out dropdown menu |
| `FocusSummaryPanel` | `components/layout/FocusSummaryPanel.tsx` | Task statistics panel |
| `ReflectionPanel` | `components/layout/ReflectionPanel.tsx` | Motivational text panel |
| `Footer` | `components/layout/Footer.tsx` | Authenticated footer |
| `ProgressBar` | `components/ui/ProgressBar.tsx` | Visual progress indicator |
| `useTaskStats` | `hooks/useTaskStats.ts` | Compute task statistics |

### Existing Components to Modify

| Component | Changes |
|-----------|---------|
| Button | Design tokens, hover/active transitions |
| Input | Design tokens, focus ring animation |
| Textarea | Design tokens, focus ring animation |
| Checkbox | Smooth check/uncheck transition |
| Modal | Fade + scale enter/exit |
| Toast | Calm colors, slide animation |
| Skeleton | Calm pulse colors |
| Tabs | Design tokens, indicator transition |
| TaskItem | Design tokens, completion animation |
| TaskList | AnimatePresence wrapper |
| EmptyState | Serene copy, calm styling |
| TaskModal | Design tokens |
| DeleteConfirmModal | Design tokens, calm error |
| TaskFilterTabs | Tab transition |
| TaskSearchInput | Focus states |
| TaskSortDropdown | Design tokens |

### New Utility Hooks

```typescript
// hooks/useTimeOfDay.ts
export type TimePeriod = 'morning' | 'afternoon' | 'evening';
export function useTimeOfDay(): TimePeriod;

// hooks/useReducedMotion.ts
export function useReducedMotion(): boolean;
```

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Framer Motion bundle size | Scoped to single AnimatedList component; tree-shaking removes unused features |
| Animation performance | Limited to transform/opacity; tested with DevTools |
| Breaking existing functionality | No behavior changes; all existing interactions preserved |
| Color contrast issues | Use WCAG checker before finalizing palette |
| Time-of-day edge cases | Client-side detection uses local time; no server dependency |

---

## Success Validation Checklist

### Core Theme (Phases 1-5)
- [ ] SC-001: 100% token usage (audit all color/spacing classes)
- [ ] SC-002: Greeting shows session.user.name
- [ ] SC-003: 60fps animations (DevTools Performance)
- [ ] SC-004: Reduced motion eliminates transforms
- [ ] SC-005: WCAG AA contrast (4.5:1 / 3:1)
- [ ] SC-006: Serene empty state copy
- [ ] SC-007: Tokens documented in tailwind.config.ts
- [ ] SC-008: Qualitative "calm/premium" feel

### Wow Layer (Phases 6-7)
- [ ] SC-009: Orbital Aurora Belt and Calm Orbit Marker visible, time-of-day aware
- [ ] SC-010: Ambient animations static when reduced motion enabled
- [ ] SC-011: Profile avatar shows correct initials
- [ ] SC-012: Profile dropdown fully keyboard accessible
- [ ] SC-013: Focus Summary shows correct stats
- [ ] SC-014: Reflection shows correct rule-based text
- [ ] SC-015: Panels responsive at desktop/mobile breakpoints
- [ ] SC-016: Footer visible and non-overlapping

---

## Next Steps

1. Run `/sp.tasks` to generate detailed task breakdown (including Phase 6 & 7 tasks)
2. Complete Phases 1-5 (base theme) if not already done
3. Install framer-motion before Phase 3 if not already installed
4. Implement Phase 6 (Wow Layer) after base theme is stable
5. Run Phase 7 QA to verify all wow layer success criteria
