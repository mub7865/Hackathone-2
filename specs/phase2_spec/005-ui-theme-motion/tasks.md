# Tasks: UI Theme, Motion & Calm Experience

**Feature**: 006-ui-theme-motion | **Date**: 2024-12-15 | **Plan**: [plan.md](./plan.md) | **Spec**: [spec.md](./spec.md)

---

## Task Overview

| Phase | Tasks | Focus |
|-------|-------|-------|
| Phase 1 | T001-T005 | Design Foundation (Tokens + Global Styles) |
| Phase 2 | T006-T015 | Core UI Components |
| Phase 3 | T016-T028 | Task Components + List Animations |
| Phase 4 | T029-T035 | Page Integration + Auth Screens |
| Phase 5 | T036-T040 | Polish, QA & Accessibility |
| Phase 6 | T041-T060 | Wow Layer – Ambient Background, Header, Panels, Footer |
| Phase 7 | T061-T068 | Final QA & Wow Layer Polish |

**Priority Key**: P1 = Must Have, P2 = Should Have, P3 = Nice to Have

---

## Phase 1: Design Foundation (Tokens + Global Styles)

**Goal**: Establish the design system foundation that all subsequent work depends on.

### T001 [P1] [US1] Create TimePeriod type definition ✅
**File**: `phase2/frontend/types/theme.ts` (CREATE)
**Description**: Create the TimePeriod type for time-of-day theming.
**Acceptance Criteria**:
- [x] Export `TimePeriod` type with values: 'morning' | 'afternoon' | 'evening'
- [x] Export gradient mapping type `GradientMap`
- [x] File compiles without TypeScript errors

**Test Cases**:
```typescript
// Type should be usable as:
const period: TimePeriod = 'morning'; // ✓
const period: TimePeriod = 'night';   // ✗ Type error
```

---

### T002 [P1] [US1] Add semantic color tokens to Tailwind config ✅
**File**: `phase2/frontend/tailwind.config.ts` (MODIFY)
**Description**: Define semantic design tokens for the calm dark theme.
**Acceptance Criteria**:
- [x] Add `colors.background` tokens: `base`, `elevated`, `surface`
- [x] Add `colors.text` tokens: `primary`, `secondary`, `muted`
- [x] Add `colors.accent` tokens: `primary`, `hover`, `success`, `warning`, `error`
- [x] Add `colors.border` tokens: `subtle`, `visible`
- [x] All colors use cool/neutral palette (soft blues, slate grays)
- [x] TypeScript autocomplete works for new tokens

**Test Cases**:
- [x] `bg-background-base` class renders correct color
- [x] `text-text-primary` class renders correct color
- [x] All accent colors are visible against background colors

**References**: Spec FR-001, FR-002, SC-007

---

### T003 [P1] [US1] Add spacing, radius, and typography tokens ✅
**File**: `phase2/frontend/tailwind.config.ts` (MODIFY)
**Description**: Extend Tailwind with consistent spacing and typography scales.
**Acceptance Criteria**:
- [x] Add `borderRadius` tokens: `sm` (4px), `md` (8px), `lg` (12px), `xl` (16px)
- [x] Add `spacing` tokens if custom values needed (verify existing suffice)
- [x] Add `transitionDuration` tokens: `fast` (150ms), `normal` (200ms), `slow` (300ms)
- [x] Document token usage in comments

**Test Cases**:
- [x] `rounded-md` applies 8px border radius
- [x] `duration-fast` applies 150ms transition

**References**: Spec SC-007

---

### T004 [P1] [US2] Define time-of-day gradient classes in globals.css ✅
**File**: `phase2/frontend/app/globals.css` (MODIFY)
**Description**: Create gradient backgrounds for morning, afternoon, and evening.
**Acceptance Criteria**:
- [x] Add `.bg-gradient-morning` class (warm amber to soft slate)
- [x] Add `.bg-gradient-afternoon` class (soft blue to slate)
- [x] Add `.bg-gradient-evening` class (deep indigo to slate)
- [x] Gradients are subtle (not distracting)
- [x] Gradients work on `min-h-screen` containers

**Test Cases**:
- [x] Each gradient renders distinctly
- [x] Gradients don't cause readability issues with text
- [x] Gradients transition smoothly when class changes

**References**: Spec FR-004, FR-005, FR-009

---

### T005 [P1] [US6] Add reduced motion CSS overrides ✅
**File**: `phase2/frontend/app/globals.css` (MODIFY)
**Description**: Implement `prefers-reduced-motion` media query overrides.
**Acceptance Criteria**:
- [x] Add `@media (prefers-reduced-motion: reduce)` block
- [x] Set `animation-duration: 0.01ms !important` for all elements
- [x] Set `transition-duration: 0.01ms !important` for all elements
- [x] Preserve opacity changes (instant but still visible)

**Test Cases**:
- [x] With reduced motion enabled, no sliding/scaling animations occur
- [x] Elements still appear/disappear (instant opacity changes)
- [x] Test in browser with reduced motion setting enabled

**References**: Spec FR-018, SC-004

---

## Phase 2: Core UI Components

**Goal**: Update all base UI components to use design tokens and add smooth transitions.
**Dependencies**: Phase 1 complete (tokens must exist)

### T006 [P1] [US6] Create useReducedMotion hook ✅
**File**: `phase2/frontend/hooks/useReducedMotion.ts` (CREATE)
**Description**: Hook to detect user's motion preference for JS-controlled animations.
**Acceptance Criteria**:
- [x] Returns `boolean` indicating if reduced motion is preferred
- [x] Uses `window.matchMedia('(prefers-reduced-motion: reduce)')`
- [x] Listens for changes and updates state
- [x] Handles SSR (returns false on server, hydrates on client)
- [x] Properly cleans up event listener on unmount

**Test Cases**:
```typescript
// With reduced motion disabled:
const prefersReduced = useReducedMotion(); // false

// With reduced motion enabled:
const prefersReduced = useReducedMotion(); // true
```

**References**: Spec FR-018, research.md section 5

---

### T007 [P1] [US6] Export new hooks from hooks index ✅
**File**: `phase2/frontend/hooks/index.ts` (MODIFY or CREATE)
**Description**: Create/update barrel export for hooks.
**Acceptance Criteria**:
- [x] Export `useReducedMotion` from hooks index
- [ ] (Later) Export `useTimeOfDay` when created

**Test Cases**:
- [x] `import { useReducedMotion } from '@/hooks'` works

---

### T008 [P2] [US4] Update Button component with design tokens and transitions ✅
**File**: `phase2/frontend/components/ui/Button.tsx` (MODIFY)
**Description**: Apply semantic tokens and add hover/active micro-interactions.
**Acceptance Criteria**:
- [x] Use semantic color tokens (`bg-accent-primary`, `hover:bg-accent-hover`)
- [x] Add `transition-all duration-fast` for smooth state changes
- [x] Add subtle `active:scale-[0.98]` press feedback
- [x] Ensure focus ring is visible (`focus:ring-2 focus:ring-accent-primary`)
- [x] Use `motion-reduce:transition-none` for reduced motion

**Test Cases**:
- [x] Hover state transitions smoothly (not instant)
- [x] Button press shows subtle scale feedback
- [x] Focus ring is visible when tabbing
- [x] With reduced motion, transitions are instant

**References**: Spec FR-016, FR-020, SC-003

---

### T009 [P2] [US4] Update Input component with design tokens and focus animation ✅
**File**: `phase2/frontend/components/ui/Input.tsx` (MODIFY)
**Description**: Apply semantic tokens and smooth focus ring transition.
**Acceptance Criteria**:
- [x] Use `bg-background-elevated` for input background
- [x] Use `border-border-subtle` default, `border-accent-primary` on focus
- [x] Add `transition-colors duration-fast` for border color change
- [x] Ensure text uses `text-text-primary`
- [x] Placeholder uses `text-text-muted`

**Test Cases**:
- [x] Focus ring animates in smoothly
- [x] Border color transitions on focus/blur
- [x] Text is readable against background

**References**: Spec FR-020, SC-005

---

### T010 [P2] [US4] Update Textarea component with design tokens and focus animation ✅
**File**: `phase2/frontend/components/ui/Textarea.tsx` (MODIFY)
**Description**: Apply same styling pattern as Input component.
**Acceptance Criteria**:
- [x] Match Input component styling pattern
- [x] Use `bg-background-elevated`, semantic borders
- [x] Add smooth focus transition

**Test Cases**:
- [x] Textarea visually consistent with Input
- [x] Focus behavior matches Input

**References**: Spec FR-020

---

### T011 [P2] [US4] Update Checkbox component with smooth state transitions ✅
**File**: `phase2/frontend/components/ui/Checkbox.tsx` (MODIFY)
**Description**: Add smooth check/uncheck animation.
**Acceptance Criteria**:
- [x] Add `transition-all duration-fast` for state changes
- [x] Use semantic colors for checked/unchecked states
- [x] Checkmark appears with subtle scale animation
- [x] Use `motion-reduce:transition-none`

**Test Cases**:
- [x] Checking/unchecking has visible transition (not instant)
- [x] Checkmark scales in smoothly
- [x] With reduced motion, change is instant

**References**: Spec FR-013, SC-003

---

### T012 [P1] [US4] Update Modal component with fade/scale animations ✅
**File**: `phase2/frontend/components/ui/Modal.tsx` (MODIFY)
**Description**: Add smooth enter/exit animations for modals.
**Acceptance Criteria**:
- [x] Backdrop fades in with `transition-opacity duration-normal`
- [x] Modal content scales from 95% to 100% with opacity
- [x] Exit animation reverses (fade out, scale down)
- [x] Use CSS transitions (not Framer Motion)
- [x] Respect reduced motion preference

**Test Cases**:
- [x] Modal opens with smooth fade + scale
- [x] Modal closes with reverse animation
- [x] Animation is 60fps (no jank)
- [x] With reduced motion, modal appears/disappears instantly

**References**: Spec FR-010, FR-011, SC-003, research.md section 6

---

### T013 [P2] [US4] Update Toast component with calm styling and slide animation ✅
**File**: `phase2/frontend/components/ui/Toast.tsx` (MODIFY)
**Description**: Apply calm colors and smooth entrance animation.
**Acceptance Criteria**:
- [x] Use semantic color tokens for toast backgrounds
- [x] Success: calm green accent, Error: muted red, Info: slate
- [x] Add slide-in animation (from right or top)
- [x] Use `transition-transform` for smooth motion
- [x] Respect reduced motion

**Test Cases**:
- [x] Toast slides in smoothly
- [x] Toast auto-dismisses with fade out
- [x] Colors are calm, not jarring

**References**: Spec FR-025, FR-026

---

### T014 [P2] [US4] Update Skeleton component with calm pulse colors ✅
**File**: `phase2/frontend/components/ui/Skeleton.tsx` (MODIFY)
**Description**: Update skeleton loader to use calm, subtle pulse animation.
**Acceptance Criteria**:
- [x] Use `bg-background-elevated` for skeleton base
- [x] Pulse animation uses subtle opacity change (not color change)
- [x] Animation duration is slow (1.5-2s) for calm feel
- [x] Respect reduced motion (no pulse, static color)

**Test Cases**:
- [x] Skeleton pulse is subtle, not distracting
- [x] Animation is smooth 60fps
- [x] With reduced motion, skeleton is static

**References**: Spec FR-023, FR-024

---

### T015 [P2] [US4] Update Tabs component with design tokens and indicator transition ✅
**File**: `phase2/frontend/components/ui/Tabs.tsx` (MODIFY)
**Description**: Apply semantic tokens and smooth tab indicator transition.
**Acceptance Criteria**:
- [x] Use semantic color tokens
- [x] Tab indicator slides smoothly between tabs
- [x] Active tab has visible distinction
- [x] Use `transition-all duration-fast`

**Test Cases**:
- [x] Tab indicator animates when switching tabs
- [x] Active/inactive states clearly visible
- [x] Transitions are smooth

**References**: Spec FR-017

---

## Phase 3: Task Components + List Animations

**Goal**: Apply design system to task-specific components and implement list animations.
**Dependencies**: Phase 2 complete (base components must be styled)

### T016 [P1] [US5] Install framer-motion dependency
**File**: `phase2/frontend/package.json` (MODIFY via npm)
**Description**: Add framer-motion for list animations.
**Acceptance Criteria**:
- [ ] Run `npm install framer-motion` in phase2/frontend
- [ ] Version ^11.x installed
- [ ] No peer dependency warnings
- [ ] Build still succeeds

**Test Cases**:
- [ ] `npm run build` completes without errors
- [ ] `import { AnimatePresence } from 'framer-motion'` works

**References**: research.md section 1

---

### T017 [P1] [US5] Create AnimatedList wrapper component
**File**: `phase2/frontend/components/ui/AnimatedList.tsx` (CREATE)
**Description**: Create reusable Framer Motion wrapper for list animations.
**Acceptance Criteria**:
- [ ] Wrap children with `AnimatePresence mode="popLayout"`
- [ ] Accept `children` prop with motion-wrapped items
- [ ] Export for use in TaskList
- [ ] Respect reduced motion (skip animations if enabled)

**Implementation Pattern**:
```tsx
<AnimatePresence mode="popLayout">
  {items.map((item, index) => (
    <motion.div
      key={item.id}
      layout
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, x: -20 }}
      transition={{ duration: prefersReduced ? 0 : 0.2 }}
    >
      {children}
    </motion.div>
  ))}
</AnimatePresence>
```

**Test Cases**:
- [ ] Items animate in when added
- [ ] Items animate out when removed
- [ ] List reorders smoothly on filter/sort change

**References**: Spec FR-012, FR-014, FR-015, research.md section 7

---

### T018 [P1] [US5] Export AnimatedList from components/ui index
**File**: `phase2/frontend/components/ui/index.ts` (MODIFY)
**Description**: Add AnimatedList to barrel exports.
**Acceptance Criteria**:
- [ ] Export `AnimatedList` from index

---

### T019 [P1] [US2] Create useTimeOfDay hook
**File**: `phase2/frontend/hooks/useTimeOfDay.ts` (CREATE)
**Description**: Hook to detect current time period for theming.
**Acceptance Criteria**:
- [ ] Returns `TimePeriod` type ('morning' | 'afternoon' | 'evening')
- [ ] Morning: 6:00 - 11:59
- [ ] Afternoon: 12:00 - 17:59
- [ ] Evening: 18:00 - 5:59
- [ ] Uses client's local time
- [ ] Handles SSR gracefully (default to 'morning' or current time on client)

**Implementation**:
```typescript
export function useTimeOfDay(): TimePeriod {
  const [period, setPeriod] = useState<TimePeriod>('morning');

  useEffect(() => {
    const hour = new Date().getHours();
    if (hour >= 6 && hour < 12) setPeriod('morning');
    else if (hour >= 12 && hour < 18) setPeriod('afternoon');
    else setPeriod('evening');
  }, []);

  return period;
}
```

**Test Cases**:
- [ ] Returns 'morning' at 9am
- [ ] Returns 'afternoon' at 2pm
- [ ] Returns 'evening' at 8pm

**References**: Spec FR-004, FR-005, research.md section 3

---

### T020 [P1] [US2] Update hooks index to export useTimeOfDay
**File**: `phase2/frontend/hooks/index.ts` (MODIFY)
**Description**: Add useTimeOfDay to barrel exports.
**Acceptance Criteria**:
- [ ] Export `useTimeOfDay` from index
- [ ] Export `TimePeriod` type from index

---

### T021 [P1] [US2] Create GreetingHeader component
**File**: `phase2/frontend/components/layout/GreetingHeader.tsx` (CREATE)
**Description**: Time-aware personalized greeting component.
**Acceptance Criteria**:
- [ ] Display "Good morning/afternoon/evening, {name}"
- [ ] Use `useTimeOfDay` hook for time period
- [ ] Accept `userName` prop (from session)
- [ ] Fallback to "Good morning/afternoon/evening" if no name
- [ ] Use semantic typography tokens
- [ ] Subtle fade-in animation on mount

**Test Cases**:
- [ ] Shows "Good morning, Sarah" at 9am with name="Sarah"
- [ ] Shows "Good afternoon" at 2pm with no name
- [ ] Typography is readable and matches design system

**References**: Spec FR-006, FR-007, FR-008, SC-002

---

### T022 [P2] [US1] Update TaskItem component with design tokens
**File**: `phase2/frontend/components/tasks/TaskItem.tsx` (MODIFY)
**Description**: Apply semantic tokens to task item.
**Acceptance Criteria**:
- [ ] Use `bg-background-surface` for card background
- [ ] Use `border-border-subtle` for borders
- [ ] Use semantic text colors
- [ ] Add subtle hover state (`hover:bg-background-elevated`)
- [ ] Completion state uses `text-text-muted` for struck text

**Test Cases**:
- [ ] Task items have consistent styling
- [ ] Hover state is visible but subtle
- [ ] Completed tasks visually distinct

**References**: Spec FR-001, FR-002

---

### T023 [P1] [US5] Update TaskList to integrate AnimatePresence
**File**: `phase2/frontend/components/tasks/TaskList.tsx` (MODIFY)
**Description**: Wrap task items with AnimatePresence for enter/exit animations.
**Acceptance Criteria**:
- [ ] Import and use AnimatePresence from framer-motion
- [ ] Each TaskItem wrapped in motion.div with unique key
- [ ] Items animate in on add (fade + slide down)
- [ ] Items animate out on delete (fade + slide left)
- [ ] Filter/sort changes trigger layout animation
- [ ] Use `useReducedMotion` to skip animations if needed

**Test Cases**:
- [ ] Add task → new item fades/slides in
- [ ] Delete task → item fades/slides out
- [ ] Change filter → list animates smoothly
- [ ] All animations 60fps

**References**: Spec FR-012, FR-014, FR-015, SC-003

---

### T024 [P2] [US3] Update EmptyState with serene copy and styling
**File**: `phase2/frontend/components/tasks/EmptyState.tsx` (MODIFY)
**Description**: Apply calm styling and serene messaging.
**Acceptance Criteria**:
- [ ] Use semantic color tokens
- [ ] Replace generic text with serene copy:
  - No tasks: "Your task list is clear. Take a moment to breathe."
  - No matches: "No tasks match your search. Try adjusting your filters."
- [ ] Add subtle illustration or icon (optional)
- [ ] Centered, calm layout

**Test Cases**:
- [ ] Empty state displays correct serene message
- [ ] No generic "No data" language
- [ ] Visually calming

**References**: Spec FR-027, SC-006

---

### T025 [P2] [US4] Update TaskModal with design tokens
**File**: `phase2/frontend/components/tasks/TaskModal.tsx` (MODIFY)
**Description**: Apply semantic tokens to task create/edit modal.
**Acceptance Criteria**:
- [ ] Use semantic background and border colors
- [ ] Form inputs use updated Input/Textarea components
- [ ] Buttons use updated Button component
- [ ] Modal animation inherited from Modal base component

**Test Cases**:
- [ ] Modal visually consistent with design system
- [ ] Form elements have proper focus states

**References**: Spec FR-010, FR-011

---

### T026 [P2] [US4] Update DeleteConfirmModal with design tokens and calm error styling
**File**: `phase2/frontend/components/tasks/DeleteConfirmModal.tsx` (MODIFY)
**Description**: Apply semantic tokens with calmer error/warning styling.
**Acceptance Criteria**:
- [ ] Use muted error colors (not harsh red)
- [ ] Confirmation text is calm but clear
- [ ] Delete button uses `bg-accent-error` but muted
- [ ] Cancel button uses secondary styling

**Test Cases**:
- [ ] Delete modal is not jarring/alarming
- [ ] Actions are clearly distinguishable
- [ ] Styling consistent with design system

**References**: Spec FR-010, FR-011

---

### T027 [P2] [US4] Update TaskFilterTabs with transitions
**File**: `phase2/frontend/components/tasks/TaskFilterTabs.tsx` (MODIFY)
**Description**: Apply design tokens and smooth tab transitions.
**Acceptance Criteria**:
- [ ] Use semantic color tokens
- [ ] Tab indicator animates between tabs
- [ ] Add `transition-all duration-fast`

**Test Cases**:
- [ ] Switching tabs has smooth animation
- [ ] Active tab clearly indicated

**References**: Spec FR-017

---

### T028 [P2] [US4] Update TaskSearchInput and TaskSortDropdown
**Files**:
- `phase2/frontend/components/tasks/TaskSearchInput.tsx` (MODIFY)
- `phase2/frontend/components/tasks/TaskSortDropdown.tsx` (MODIFY)
**Description**: Apply design tokens and focus states.
**Acceptance Criteria**:
- [ ] Search input uses updated Input styling
- [ ] Dropdown uses semantic colors
- [ ] Focus states visible and animated

**Test Cases**:
- [ ] Search input matches design system
- [ ] Dropdown is visually consistent

---

## Phase 4: Page Integration + Auth Screens

**Goal**: Wire everything together at page level and style auth screens.
**Dependencies**: Phase 3 complete (greeting component must exist)

### T029 [P1] [US2] Update authenticated layout with greeting and gradient
**File**: `phase2/frontend/app/(authenticated)/layout.tsx` (MODIFY)
**Description**: Integrate GreetingHeader and time-of-day gradient background.
**Acceptance Criteria**:
- [ ] Import and use `useTimeOfDay` hook
- [ ] Apply gradient class based on time period (`bg-gradient-morning`, etc.)
- [ ] Import and render `GreetingHeader` component
- [ ] Pass `session.user.name` to GreetingHeader
- [ ] Gradient covers full viewport background

**Test Cases**:
- [ ] At 9am, background shows morning gradient
- [ ] At 2pm, background shows afternoon gradient
- [ ] At 8pm, background shows evening gradient
- [ ] Greeting shows authenticated user's name

**References**: Spec FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, SC-002

---

### T030 [P2] [US1] Verify tasks page component composition
**File**: `phase2/frontend/app/(authenticated)/tasks/page.tsx` (MINOR)
**Description**: Ensure all task components compose correctly with new styling.
**Acceptance Criteria**:
- [ ] Page renders with all updated components
- [ ] No styling conflicts or overrides needed
- [ ] Layout is visually cohesive

**Test Cases**:
- [ ] Full tasks page renders correctly
- [ ] All interactions work as before
- [ ] Visual consistency throughout

---

### T031 [P2] [US1] Update tasks loading state with calm skeleton styling
**File**: `phase2/frontend/app/(authenticated)/tasks/loading.tsx` (MODIFY)
**Description**: Apply calm skeleton styling to loading state.
**Acceptance Criteria**:
- [ ] Use updated Skeleton component
- [ ] Layout matches actual task list structure
- [ ] Pulse animation is calm and subtle

**Test Cases**:
- [ ] Loading state displays calm skeleton
- [ ] Transition to loaded state is smooth

**References**: Spec FR-023, FR-024

---

### T032 [P1] [US1] Update login page with full design system
**File**: `phase2/frontend/app/login/page.tsx` (MODIFY)
**Description**: Apply complete design system to login screen.
**Acceptance Criteria**:
- [ ] Use semantic color tokens throughout
- [ ] Form uses updated Input and Button components
- [ ] Background uses appropriate gradient or solid
- [ ] Error states use calm error styling
- [ ] Focus states visible on all inputs

**Test Cases**:
- [ ] Login page is visually consistent with design system
- [ ] All form interactions work correctly
- [ ] Error messages display with calm styling

**References**: Spec FR-021, SC-001

---

### T033 [P1] [US1] Update register page with full design system
**File**: `phase2/frontend/app/register/page.tsx` (MODIFY)
**Description**: Apply complete design system to registration screen.
**Acceptance Criteria**:
- [ ] Match login page styling pattern
- [ ] Use semantic color tokens
- [ ] Form validation uses calm error colors

**Test Cases**:
- [ ] Register page matches login styling
- [ ] All form interactions work correctly

**References**: Spec FR-022, SC-001

---

### T034 [P2] [US2] Verify time-of-day gradient transitions
**Description**: Manual verification task for gradient behavior.
**Acceptance Criteria**:
- [ ] Test at different times (or mock time)
- [ ] Verify each gradient renders correctly
- [ ] Ensure gradients are subtle and calming

**Test Cases**:
- [ ] Morning gradient: warm amber to soft slate
- [ ] Afternoon gradient: soft blue to slate
- [ ] Evening gradient: deep indigo to slate

---

### T035 [P2] [US2] Verify personalized greeting with session
**Description**: Manual verification task for greeting personalization.
**Acceptance Criteria**:
- [ ] Login with user that has name set
- [ ] Verify greeting shows "Good {time}, {name}"
- [ ] Test fallback when name is undefined

**Test Cases**:
- [ ] User "Sarah" sees "Good morning, Sarah"
- [ ] User without name sees "Good morning"

---

## Phase 5: Polish, QA & Accessibility

**Goal**: Final polish, performance validation, and accessibility verification.
**Dependencies**: Phase 4 complete (full integration required)

### T036 [P1] [US6] Verify 60fps animations using DevTools
**Description**: Performance validation using Chrome DevTools.
**Acceptance Criteria**:
- [ ] Open Chrome DevTools Performance tab
- [ ] Record interactions: modal open/close, task add/delete, checkbox toggle
- [ ] Verify no frames exceed 16ms
- [ ] All animations use only transform and opacity

**Test Cases**:
- [ ] Modal open: 60fps
- [ ] Modal close: 60fps
- [ ] Task add animation: 60fps
- [ ] Task delete animation: 60fps
- [ ] Checkbox toggle: 60fps

**References**: Spec SC-003

---

### T037 [P1] [US6] Test prefers-reduced-motion across all flows
**Description**: Accessibility testing for motion preferences.
**Acceptance Criteria**:
- [ ] Enable reduced motion in OS/browser settings
- [ ] Navigate through all screens
- [ ] Verify no sliding/scaling animations
- [ ] Elements still appear/disappear (instant)
- [ ] Test modal, toast, task list, checkbox, button states

**Test Cases**:
- [ ] Modal appears instantly (no scale)
- [ ] Tasks appear instantly (no slide)
- [ ] Checkboxes toggle instantly
- [ ] Buttons don't scale on press

**References**: Spec FR-018, SC-004

---

### T038 [P1] [US6] Run WCAG AA contrast checks
**Description**: Verify all color combinations meet accessibility standards.
**Acceptance Criteria**:
- [ ] Use contrast checker tool (e.g., WebAIM)
- [ ] Verify body text: 4.5:1 minimum contrast
- [ ] Verify large text/UI: 3:1 minimum contrast
- [ ] Check all color combinations:
  - text-primary on background-base
  - text-secondary on background-base
  - text-muted on background-elevated
  - accent colors on backgrounds
- [ ] Document any adjustments needed

**Test Cases**:
- [ ] Primary text passes 4.5:1
- [ ] Secondary text passes 4.5:1
- [ ] Button text passes 4.5:1
- [ ] Input text passes 4.5:1

**References**: Spec FR-019, SC-005

---

### T039 [P2] [US1] Test edge cases
**Description**: Test unusual scenarios and edge cases.
**Acceptance Criteria**:
- [ ] Long user names (20+ characters) in greeting
- [ ] Rapid filter changes don't break animations
- [ ] Many tasks (50+) animate smoothly
- [ ] Empty states display correctly after clearing filters
- [ ] Modal stacking (if applicable) works correctly

**Test Cases**:
- [ ] Name "Alexandra Elizabeth" fits in greeting
- [ ] Rapid tab clicks don't cause animation glitches
- [ ] 50 task items animate without performance issues

---

### T040 [P2] [US1] Final visual consistency audit
**Description**: Verify overall calm, premium feel.
**Acceptance Criteria**:
- [ ] Review all 9 screens/states visually
- [ ] Verify consistent spacing throughout
- [ ] Verify consistent color usage
- [ ] Verify animations feel cohesive
- [ ] Get qualitative feedback: "Does it feel calm?"

**Test Cases**:
- [ ] Login: calm and premium
- [ ] Register: calm and premium
- [ ] Tasks (with items): calm and premium
- [ ] Tasks (empty): calm and premium
- [ ] Task modal: calm and premium
- [ ] Delete modal: calm, not alarming
- [ ] Loading state: calm skeleton
- [ ] Error toasts: informative but not jarring

**References**: Spec SC-008

---

---

## Phase 6: Wow Layer – Ambient Background, Header, Panels, Footer

**Goal**: Add premium visual polish with ambient animations, refined header, content panels, and footer.
**Dependencies**: Phase 5 complete (base theme must be stable)

### T041 [P2] [US7] Add CSS keyframes for ambient animations
**File**: `phase2/frontend/app/globals.css` (MODIFY)
**Description**: Add CSS keyframes for orbital rotation and orb pulse animations.
**Acceptance Criteria**:
- [ ] Add `@keyframes orbital-rotate` with 360deg rotation (45-90s duration)
- [ ] Add `@keyframes orbital-scale` with subtle scale pulse (45-90s duration)
- [ ] Add `@keyframes orb-pulse` with subtle scale + rotate (10-15s duration)
- [ ] All keyframes use only `transform` and `opacity`
- [ ] Add `motion-reduce` variants that disable animations

**Test Cases**:
- [ ] Keyframes render correctly in browser
- [ ] Animations are smooth 60fps
- [ ] With reduced motion, elements are static

**References**: Spec FR-032, FR-034, FR-035

---

### T042 [P2] [US7] Create OrbitalAuroraBelt component
**File**: `phase2/frontend/components/layout/OrbitalAuroraBelt.tsx` (CREATE)
**Description**: Create ambient animated orbital rings component.
**Acceptance Criteria**:
- [ ] Render 2-3 large ELLIPTICAL (oval) rings with gradient borders (NOT perfect circles)
- [ ] Position fixed with centers OUTSIDE viewport at bottom-left corner (rings partially extend off-screen)
- [ ] Largest ring: ~60-80% of viewport width; smaller rings: ~40-60%
- [ ] Use `useTimeOfDay` hook for time-of-day gradient colors
- [ ] Morning: soft blue (#60a5fa) + teal (#2dd4bf)
- [ ] Afternoon: blue (#3b82f6) + cyan (#22d3ee)
- [ ] Evening: purple (#a78bfa) + deep navy (#1e3a8a)
- [ ] Apply CSS rotation/scale animations (45-90s loop)
- [ ] Use `useReducedMotion` to disable animations
- [ ] Low opacity (0.1-0.2) so text remains readable
- [ ] Use `pointer-events-none` so it doesn't block interactions

**Test Cases**:
- [ ] Rings are elliptical, NOT circular
- [ ] Rings partially extend off-screen from bottom-left
- [ ] Correct colors at each time period
- [ ] Animations run smoothly
- [ ] Static when reduced motion enabled
- [ ] Text over rings is readable

**References**: Spec FR-030, FR-030a, FR-031, FR-032, FR-035, FR-036, SC-009

---

### T043 [P2] [US7] Create CalmOrbitMarker component
**File**: `phase2/frontend/components/layout/CalmOrbitMarker.tsx` (CREATE)
**Description**: Create pulsing corner orb component.
**Acceptance Criteria**:
- [ ] Render small circular orb (e.g., 40-60px diameter)
- [ ] Position fixed in bottom-right corner
- [ ] Use time-of-day gradient fill (same colors as orbital rings)
- [ ] Apply CSS pulse/rotate animation (10-15s loop)
- [ ] Use `useReducedMotion` to disable animations
- [ ] Subtle blur/glow effect
- [ ] Use `pointer-events-none`

**Test Cases**:
- [ ] Orb is visible in bottom-right corner
- [ ] Correct colors at each time period
- [ ] Pulse animation runs smoothly
- [ ] Static when reduced motion enabled

**References**: Spec FR-033, FR-034, FR-035, SC-009

---

### T044 [P2] [US8] Create ProfileAvatar component
**File**: `phase2/frontend/components/layout/ProfileAvatar.tsx` (CREATE)
**Description**: Create circular avatar with user initials and TIME-OF-DAY AWARE gradient.
**Acceptance Criteria**:
- [ ] Accept `user` prop with `name` and `email` properties
- [ ] Extract initials from user.name (first letter of first + last word)
- [ ] If name is single word, use first letter only
- [ ] If no name, use first letter of email (NEVER show full email)
- [ ] Render circular avatar with TIME-OF-DAY gradient background (matching orbital aurora colors):
  - Morning: soft blue (#60a5fa) + teal (#2dd4bf)
  - Afternoon: blue (#3b82f6) + cyan (#22d3ee)
  - Evening: purple (#a78bfa) + deep navy (#1e3a8a)
- [ ] Display initials in center (uppercase, white text)
- [ ] Accept `onClick` prop for dropdown trigger
- [ ] Keyboard accessible (focusable, Enter to activate)
- [ ] `aria-haspopup` and `aria-expanded` attributes

**Test Cases**:
- [ ] "Sarah Johnson" → "SJ"
- [ ] "Madonna" → "M"
- [ ] No name, email "alex@example.com" → "A" (not full email)
- [ ] Avatar gradient changes with time of day
- [ ] Click triggers onClick
- [ ] Enter key triggers onClick
- [ ] Focus ring visible

**References**: Spec FR-038, SC-011

---

### T045 [P2] [US8] Create ProfileDropdown component
**File**: `phase2/frontend/components/layout/ProfileDropdown.tsx` (CREATE)
**Description**: Create minimal dropdown menu with ONLY "Sign out" action (no name/email text).
**Acceptance Criteria**:
- [ ] Accept `isOpen`, `onClose`, `onSignOut` props (NO user prop needed)
- [ ] Display ONLY a single "Sign out" button/link – NO name/email text
- [ ] Close on Escape key
- [ ] Close on click outside
- [ ] Close after selecting action
- [ ] Keyboard navigation (Tab, Enter, Escape)
- [ ] Animate open/close with fade + scale
- [ ] Position below avatar, aligned right
- [ ] Prevent overflow on mobile viewports

**Test Cases**:
- [ ] Dropdown shows ONLY "Sign out" action
- [ ] NO user name or email visible
- [ ] Sign out triggers onSignOut
- [ ] Escape closes dropdown
- [ ] Click outside closes dropdown
- [ ] Tab navigates to Sign out
- [ ] Enter activates Sign out
- [ ] Dropdown visible on mobile

**References**: Spec FR-039, FR-040, FR-041, FR-042, FR-043, SC-012

---

### T046 [P2] [US9] Create useTaskStats hook
**File**: `phase2/frontend/hooks/useTaskStats.ts` (CREATE)
**Description**: Hook to compute task statistics from task list.
**Acceptance Criteria**:
- [ ] Accept `tasks: Task[]` array parameter
- [ ] Return `{ pending, completed, total, percentage }` object
- [ ] `pending` = count of tasks with status === 'pending'
- [ ] `completed` = count of tasks with status === 'completed'
- [ ] `total` = pending + completed
- [ ] `percentage` = Math.round((completed / total) * 100) or 0 if total === 0
- [ ] Memoize calculations for performance

**Test Cases**:
```typescript
// 3 pending, 2 completed
useTaskStats(tasks) // { pending: 3, completed: 2, total: 5, percentage: 40 }

// 0 tasks
useTaskStats([]) // { pending: 0, completed: 0, total: 0, percentage: 0 }

// All completed
useTaskStats(allCompleted) // { pending: 0, completed: 5, total: 5, percentage: 100 }
```

**References**: Spec FR-044, SC-013

---

### T047 [P2] [US9] Export useTaskStats from hooks index
**File**: `phase2/frontend/hooks/index.ts` (MODIFY)
**Description**: Add useTaskStats to barrel exports.
**Acceptance Criteria**:
- [ ] Export `useTaskStats` from hooks index

---

### T048 [P2] [US9] Create ProgressBar component
**File**: `phase2/frontend/components/ui/ProgressBar.tsx` (CREATE)
**Description**: Visual progress bar component.
**Acceptance Criteria**:
- [ ] Accept `percentage` prop (0-100)
- [ ] Accept optional `className` prop
- [ ] Render background track with semantic colors
- [ ] Render filled portion based on percentage
- [ ] Smooth transition on percentage change
- [ ] Use accent-primary color for fill
- [ ] Respect reduced motion for transitions

**Test Cases**:
- [ ] 0% shows empty bar
- [ ] 50% shows half-filled bar
- [ ] 100% shows full bar
- [ ] Transition is smooth
- [ ] Instant change with reduced motion

**References**: Spec FR-045

---

### T049 [P2] [US9] Export ProgressBar from components/ui index
**File**: `phase2/frontend/components/ui/index.ts` (MODIFY)
**Description**: Add ProgressBar to barrel exports.
**Acceptance Criteria**:
- [ ] Export `ProgressBar` from index

---

### T050 [P2] [US9] Create FocusSummaryPanel component
**File**: `phase2/frontend/components/layout/FocusSummaryPanel.tsx` (CREATE)
**Description**: Task statistics panel with progress bar.
**Acceptance Criteria**:
- [ ] Accept `stats: TaskStats` prop from useTaskStats
- [ ] Display title "Today's Focus"
- [ ] Display pending count, completed count, total count
- [ ] Display completion percentage
- [ ] Include ProgressBar component
- [ ] Display calm motivational text with actual percentage (e.g., "You're 40% through today's plan.")
- [ ] Use semantic design tokens
- [ ] Card-like styling with subtle border

**Test Cases**:
- [ ] Shows correct stats values
- [ ] Progress bar reflects percentage
- [ ] Motivational text includes actual percentage
- [ ] Styling consistent with design system

**References**: Spec FR-044, FR-045, FR-046, SC-013

---

### T051 [P2] [US10] Create ReflectionPanel component
**File**: `phase2/frontend/components/layout/ReflectionPanel.tsx` (CREATE)
**Description**: Context-aware motivational text panel.
**Acceptance Criteria**:
- [ ] Accept `stats: TaskStats` prop from useTaskStats
- [ ] Display title "Reflection"
- [ ] Display motivational text based on rules:
  - If total === 0: "A calm moment — you're all clear."
  - Else if completed === 0: "Start with just one small task to build momentum."
  - Else if percentage < 50: "Nice start. Keep a steady pace."
  - Else: "Great progress. Protect your focus and finish strong."
- [ ] Use semantic design tokens
- [ ] Card-like styling with subtle border

**Test Cases**:
- [ ] 0 tasks → "A calm moment — you're all clear."
- [ ] Tasks but 0 completed → "Start with just one small task..."
- [ ] < 50% → "Nice start. Keep a steady pace."
- [ ] >= 50% → "Great progress. Protect your focus..."
- [ ] Styling consistent with design system

**References**: Spec FR-047, FR-048, SC-014

---

### T052 [P3] [US11] Create Footer component
**File**: `phase2/frontend/components/layout/Footer.tsx` (CREATE)
**Description**: Authenticated footer component with STICKY FOOTER pattern.
**Acceptance Criteria**:
- [ ] Display "Built with Spec-Driven Development" on left
- [ ] Display text links "Docs · GitHub · Contact" on right
- [ ] Links use placeholder hrefs (e.g., "#")
- [ ] Subtle top border
- [ ] Slight blur/overlay background (optional)
- [ ] Use semantic design tokens
- [ ] Responsive: stacks on mobile if needed
- [ ] STICKY FOOTER pattern: at viewport bottom when content is short, after content in natural flow when tall
- [ ] Must not overlap main content

**Test Cases**:
- [ ] Footer at viewport bottom when content is short
- [ ] Footer after content when content is tall
- [ ] Left text correct
- [ ] Right links visible
- [ ] No overlap with content
- [ ] Responsive on mobile

**References**: Spec FR-050, FR-051, FR-052, FR-053, FR-054, SC-016

---

### T053 [P2] [US8] Update GreetingHeader with centered layout
**File**: `phase2/frontend/components/layout/GreetingHeader.tsx` (MODIFY)
**Description**: Update greeting to work with new header layout.
**Acceptance Criteria**:
- [ ] Remove from tasks page (will be in header)
- [ ] Ensure greeting + subline work in centered header context
- [ ] No standalone rendering on tasks page anymore

**Test Cases**:
- [ ] Greeting displays correctly in header
- [ ] Subline displays correctly

**References**: Spec FR-037

---

### T054 [P1] [US7,US8] Update authenticated layout with ambient background and refined header
**File**: `phase2/frontend/app/(authenticated)/layout.tsx` (MODIFY)
**Description**: Integrate all wow layer components into authenticated layout.
**Acceptance Criteria**:
- [ ] Add OrbitalAuroraBelt component (positioned behind content)
- [ ] Add CalmOrbitMarker component (positioned in corner)
- [ ] Update header layout (RESPONSIVE):
  - Desktop: left (title), center (greeting), right (avatar)
  - Mobile: stacked – top row (title left, avatar right), second row (greeting + subline full width)
- [ ] Add ProfileAvatar with time-of-day gradient and dropdown toggle state
- [ ] Add ProfileDropdown with ONLY sign-out action (no name/email text)
- [ ] Remove ALL raw email/name from header (avatar initials only)
- [ ] Add Footer component with sticky footer pattern
- [ ] Ensure main content area doesn't overlap footer
- [ ] Use CSS Grid or Flexbox for full-height sticky footer layout

**Test Cases**:
- [ ] Orbital rings visible behind content
- [ ] Corner orb visible
- [ ] Desktop header: title | greeting | avatar
- [ ] Mobile header: stacked layout
- [ ] Clicking avatar opens dropdown with ONLY "Sign out"
- [ ] NO name/email text visible anywhere in header
- [ ] Sign out in dropdown works
- [ ] Footer at viewport bottom when content short
- [ ] No content overlap

**References**: Spec FR-030, FR-033, FR-037, FR-043, FR-050, SC-009, SC-016

---

### T055 [P1] [US9,US10] Update tasks page with Focus Summary and Reflection panels
**File**: `phase2/frontend/app/(authenticated)/tasks/page.tsx` (MODIFY)
**Description**: Integrate content panels into tasks page.
**Acceptance Criteria**:
- [ ] Import useTaskStats hook
- [ ] Compute stats from ALL current tasks (no date filtering)
- [ ] Add FocusSummaryPanel component
- [ ] Add ReflectionPanel component
- [ ] Desktop layout (lg: ≥1024px): 2-column grid (list left, panels right)
- [ ] Mobile/tablet layout (<1024px): single column (list, then panels below)
- [ ] Remove GreetingHeader from page (now in layout header)

**Test Cases**:
- [ ] Focus Summary shows stats from ALL tasks
- [ ] Reflection shows correct text
- [ ] At ≥1024px: panels beside list
- [ ] At <1024px: panels below list
- [ ] Stats update when tasks change

**References**: Spec FR-044, FR-047, FR-049, SC-013, SC-014, SC-015

---

### T056 [P2] [US7] Verify ambient animations respect reduced motion
**Description**: Manual verification task for ambient animation accessibility.
**Acceptance Criteria**:
- [ ] Enable reduced motion in OS/browser settings
- [ ] Verify OrbitalAuroraBelt rings are static (no rotation/scale)
- [ ] Verify CalmOrbitMarker orb is static (no pulse/rotate)
- [ ] Elements should still be visible, just not animated

**Test Cases**:
- [ ] Reduced motion enabled → rings static
- [ ] Reduced motion enabled → orb static
- [ ] Elements still visible

**References**: Spec FR-035, SC-010

---

### T057 [P2] [US9,US10] Verify panels responsiveness
**Description**: Manual verification task for panel layout.
**Acceptance Criteria**:
- [ ] Test at desktop width (>1024px): panels beside list
- [ ] Test at tablet width (768-1024px): determine behavior
- [ ] Test at mobile width (<768px): panels below list
- [ ] No horizontal scroll at any breakpoint
- [ ] No text clipping

**Test Cases**:
- [ ] Desktop: 2-column layout
- [ ] Mobile: stacked layout
- [ ] No overflow issues

**References**: Spec FR-049, SC-015

---

### T058 [P2] [US8] Verify avatar initials logic
**Description**: Manual verification task for avatar initials.
**Acceptance Criteria**:
- [ ] Test with full name "Sarah Johnson" → "SJ"
- [ ] Test with single name "Madonna" → "M"
- [ ] Test with no name, email only → first letter of email
- [ ] Test with special characters in name

**Test Cases**:
- [ ] All name formats display correctly
- [ ] Edge cases handled gracefully

**References**: Spec FR-038, SC-011

---

### T059 [P2] [US8] Verify dropdown keyboard accessibility
**Description**: Manual verification task for dropdown accessibility.
**Acceptance Criteria**:
- [ ] Tab to avatar, Enter to open dropdown
- [ ] Tab through dropdown items
- [ ] Enter to activate Sign out
- [ ] Escape to close dropdown
- [ ] Click outside to close dropdown

**Test Cases**:
- [ ] All keyboard interactions work
- [ ] Focus management correct

**References**: Spec FR-042, SC-012

---

### T060 [P2] [US11] Verify footer positioning
**Description**: Manual verification task for footer layout.
**Acceptance Criteria**:
- [ ] Footer visible at bottom of all authenticated pages
- [ ] Footer does not overlap main content
- [ ] Footer responsive on mobile
- [ ] Footer sticky at bottom when content is short

**Test Cases**:
- [ ] All viewports show footer correctly
- [ ] No overlap issues

**References**: Spec FR-054, SC-016

---

## Phase 7: Final QA & Wow Layer Polish

**Goal**: Verify all wow layer elements work correctly and polish any issues.
**Dependencies**: Phase 6 complete

### T061 [P1] [US7] Test ambient animations at all time periods
**Description**: Verify time-of-day colors for ambient elements.
**Acceptance Criteria**:
- [ ] Test at morning time (6:00-11:59): blue + teal colors
- [ ] Test at afternoon time (12:00-17:59): blue + cyan colors
- [ ] Test at evening time (18:00-5:59): purple + navy colors
- [ ] Colors transition correctly if page remains open across periods

**Test Cases**:
- [ ] Morning colors correct
- [ ] Afternoon colors correct
- [ ] Evening colors correct

**References**: Spec FR-031, SC-009

---

### T062 [P1] [US9] Verify Focus Summary calculations
**Description**: Verify task statistics are computed correctly.
**Acceptance Criteria**:
- [ ] Add tasks and verify pending count increases
- [ ] Complete tasks and verify completed count increases
- [ ] Delete tasks and verify totals decrease
- [ ] Percentage rounds correctly (e.g., 1/3 = 33%, not 33.33%)

**Test Cases**:
- [ ] All calculations correct
- [ ] Edge cases (0 tasks, all completed) handled

**References**: Spec FR-044, SC-013

---

### T063 [P1] [US10] Verify Reflection text rules
**Description**: Verify all rule branches for reflection text.
**Acceptance Criteria**:
- [ ] 0 tasks: "A calm moment — you're all clear."
- [ ] Tasks but 0 completed: "Start with just one small task..."
- [ ] 1-49% completed: "Nice start. Keep a steady pace."
- [ ] 50-100% completed: "Great progress. Protect your focus..."

**Test Cases**:
- [ ] All rule branches tested
- [ ] Correct text displayed for each state

**References**: Spec FR-048, SC-014

---

### T064 [P2] [US8] Test dropdown on mobile viewports
**Description**: Verify dropdown works correctly on mobile.
**Acceptance Criteria**:
- [ ] Dropdown opens correctly on mobile
- [ ] Dropdown doesn't overflow viewport
- [ ] Touch interactions work correctly
- [ ] Dropdown closes correctly

**Test Cases**:
- [ ] Mobile dropdown usable
- [ ] No overflow issues

**References**: Spec FR-039, SC-012

---

### T065 [P2] [US11] Test footer at all breakpoints
**Description**: Verify footer layout across breakpoints.
**Acceptance Criteria**:
- [ ] Desktop: left/right layout
- [ ] Tablet: verify layout
- [ ] Mobile: stacked or responsive layout
- [ ] No overflow or clipping

**Test Cases**:
- [ ] All breakpoints look correct
- [ ] No layout issues

**References**: Spec FR-054, SC-016

---

### T066 [P1] Performance test ambient animations
**Description**: Verify ambient animations don't impact performance.
**Acceptance Criteria**:
- [ ] Open Chrome DevTools Performance tab
- [ ] Record while ambient animations run
- [ ] Verify no frames exceed 16ms
- [ ] Interact with UI (add task, toggle, filter) while animations run
- [ ] Verify interactions remain 60fps

**Test Cases**:
- [ ] Ambient animations 60fps
- [ ] Interactive elements remain 60fps with ambient running

**References**: Spec FR-036, SC-003

---

### T067 [P2] Final visual audit of wow layer
**Description**: Overall visual consistency check.
**Acceptance Criteria**:
- [ ] Ambient background enhances, doesn't distract
- [ ] Header layout balanced and readable
- [ ] Panels complement main content
- [ ] Footer unobtrusive
- [ ] Overall "wow" effect achieved

**Test Cases**:
- [ ] Qualitative: interface feels premium
- [ ] All wow layer elements cohesive

**References**: Spec SC-008

---

### T068 [P2] Verify no regressions from base theme
**Description**: Ensure wow layer doesn't break earlier work.
**Acceptance Criteria**:
- [ ] Login page still works and looks correct
- [ ] Register page still works and looks correct
- [ ] Task CRUD operations still work
- [ ] Modals still animate correctly
- [ ] Empty states still display correctly
- [ ] Toasts still work

**Test Cases**:
- [ ] All Phase 1-5 functionality intact
- [ ] No visual regressions

**References**: All earlier SCs

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total Tasks | 68 |
| P1 (Must Have) | 24 |
| P2 (Should Have) | 41 |
| P3 (Nice to Have) | 3 |
| Files to Create | 15 |
| Files to Modify | ~25 |

## Dependency Chain

```
T001 (types/theme.ts)
  ↓
T002-T005 (tailwind.config.ts, globals.css) [Phase 1]
  ↓
T006-T007 (useReducedMotion) → T008-T015 (UI components) [Phase 2]
  ↓
T016-T018 (framer-motion, AnimatedList) → T019-T020 (useTimeOfDay)
  ↓
T021 (GreetingHeader) → T022-T028 (Task components) [Phase 3]
  ↓
T029-T035 (Page integration) [Phase 4]
  ↓
T036-T040 (QA) [Phase 5]
  ↓
T041 (ambient keyframes) → T042-T043 (OrbitalAuroraBelt, CalmOrbitMarker)
  ↓
T044-T045 (ProfileAvatar, ProfileDropdown)
  ↓
T046-T047 (useTaskStats) → T048-T049 (ProgressBar) → T050-T051 (FocusSummary, Reflection)
  ↓
T052 (Footer)
  ↓
T054-T055 (Layout + Page integration) [Phase 6]
  ↓
T061-T068 (QA) [Phase 7]
```

---

## Next Steps

1. Phases 1-5 already complete (base theme implemented)
2. Begin Phase 6 with T041 (ambient keyframes)
3. Manual testing required for Phase 7 QA tasks
