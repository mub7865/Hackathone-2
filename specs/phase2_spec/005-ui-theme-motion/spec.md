# Feature Specification: UI Theme, Motion & Calm Experience

**Feature Branch**: `006-ui-theme-motion`
**Created**: 2024-12-14
**Status**: Draft
**Input**: User description: "Phase II Chunk 5 - Transform the todo web app into a calm, premium-feeling product with consistent visual theme, reusable UI components, and tasteful motion."

---

## Intent

Transform the existing functional todo web application into a **calm, premium-feeling product** by establishing:

1. **Unified Visual Theme**: A cool/neutral dark theme with soft blues and slate grays, minimal visual density, and depth through soft shadows/blur rather than heavy borders.

2. **Time-of-Day Atmospherics**: Subtle background gradient shifts and contextual greeting text that adapt to morning, afternoon, and evening periods—without full UI recoloring.

3. **Personalized Experience**: A warm, time-aware greeting that addresses the signed-in user by their actual name (from the session), reinforcing a sense of personal calm.

4. **Tasteful Motion**: Smooth micro-interactions for key user flows (adding, completing, deleting tasks; opening/closing modals; filtering/sorting) using performant CSS transforms and opacity transitions.

5. **Documented Design System**: Explicit design tokens (colors, spacing, typography, radii) in Tailwind configuration for repeatability and consistency.

6. **Wow Layer – Ambient Visual Experience**: Elevated visual polish through:
   - **Orbital Aurora Belt**: 2-3 large, slowly animating circular/oval rings with time-of-day gradient borders anchored toward the bottom-left of the authenticated layout viewport.
   - **Calm Orbit Marker**: A small gradient orb in the bottom-right corner with subtle pulse/rotate animation.
   - **Focus Summary Panel**: Real-time task statistics (pending, completed, total, completion %) with progress bar and calm motivational text.
   - **Insights/Reflection Panel**: Context-aware motivational text based on task completion state.
   - **Refined Header**: Centered greeting block with user's name, profile avatar with initials, and dropdown menu for sign-out.
   - **Footer**: Slim footer with "Built with Spec-Driven Development" and placeholder links.

---

## Constraints

### Technical Stack
- **Framework**: Next.js 16 App Router (existing)
- **Styling**: Tailwind CSS (existing, will extend configuration)
- **Animation**: Default to Tailwind transitions + CSS keyframes (`transform`, `opacity` only for 60fps)
- **Optional**: Framer Motion may be introduced ONLY for list enter/exit animations if CSS proves insufficient—must be explicitly scoped to a single wrapper component

### Performance & Accessibility
- All animations MUST use only `transform` and `opacity` properties to ensure 60fps rendering
- MUST respect `prefers-reduced-motion` media query—reduce or disable animations for users who request it
- Color contrast MUST meet WCAG AA standards (4.5:1 for normal text, 3:1 for large text)
- Focus states MUST remain visible and distinct

### Scope Boundaries
- **Single dark theme** with time-of-day variations (no separate light mode in this chunk)
- **No new functional features**—this is purely visual/motion enhancement
- **No changes to data model, API contracts, or authentication flows**
- **Behavior preservation**: All existing interactions must work identically; only appearance and feel change

### Personalization Source
- User's name for greeting MUST come from `session.user.name` (authenticated user object)
- If name is unavailable, gracefully fall back to a generic greeting (no hardcoded names)
- Avatar initials derived from `user.name` (first letter of first/last name) or email as fallback

### Wow Layer Animation Constraints
- **Orbital Aurora Belt**: Very slow infinite animation (45-90s loop), using only `transform` (rotate, scale) and `opacity`
- **Calm Orbit Marker**: Subtle pulse/rotate animation (10-15s loop), using only `transform` and `opacity`
- **All ambient animations**: Must be disabled (static) when `prefers-reduced-motion: reduce` is enabled
- **Performance**: Ambient elements must not impact 60fps rendering of interactive elements

### Wow Layer Design Decisions (Clarified)
- **Orbital Aurora Belt Shape**: Elliptical (oval) rings, NOT perfect circles
- **Orbital Aurora Belt Position**: Centers are slightly outside viewport (bottom-left corner), so rings partially extend off-screen
- **Orbital Aurora Belt Size**: Largest ring ~60-80% of viewport width; smaller rings ~40-60%
- **Header Mobile Layout**: Stacked – top row (title left, avatar right), second row (greeting + subline full width)
- **"Today's Focus" Scope**: All current tasks (no date filtering) – stats computed from full task list snapshot
- **Profile Avatar Gradient**: Time-of-day aware, matching orbital aurora colors (morning: blue+teal, afternoon: blue+cyan, evening: purple+navy)
- **Footer Behavior**: Sticky footer pattern – at viewport bottom when content is short, after content in natural flow when tall
- **Panel Breakpoint**: `lg` (≥1024px) – panels beside list on lg+, stacked below on <lg
- **Dropdown Content**: Avatar-only UI with single "Sign out" action – NO name/email text anywhere in header or dropdown

---

## User Scenarios & Testing

### User Story 1 - Calm Visual Experience on Tasks Page (Priority: P1)

A signed-in user opens the `/tasks` page and immediately feels a sense of calm through the cohesive dark theme, spacious layout, soft ambient background, and personalized greeting.

**Why this priority**: This is the primary screen users interact with; establishing the calm aesthetic here is foundational.

**Independent Test**: Can be verified by loading the tasks page and confirming visual consistency, greeting personalization, and background atmosphere.

**Acceptance Scenarios**:

1. **Given** a user is signed in with name "Sarah", **When** they visit `/tasks` in the morning (6:00-11:59), **Then** they see "Good morning, Sarah" and a morning-tinted background gradient.

2. **Given** a user is signed in with name "Sarah", **When** they visit `/tasks` in the afternoon (12:00-17:59), **Then** they see "Good afternoon, Sarah" and an afternoon-tinted background gradient.

3. **Given** a user is signed in with name "Sarah", **When** they visit `/tasks` in the evening (18:00-5:59), **Then** they see "Good evening, Sarah" and an evening-tinted background gradient.

4. **Given** a user is signed in without a name set, **When** they visit `/tasks`, **Then** they see a generic greeting like "Good evening — one small step today is enough." without a name.

5. **Given** any user visits `/tasks`, **Then** the page uses the defined design tokens (colors, spacing, typography) consistently across header, task list, filters, and controls.

---

### User Story 2 - Smooth Task Interactions with Micro-Animations (Priority: P1)

When a user adds, completes, or deletes a task, the transitions feel smooth and intentional rather than jarring.

**Why this priority**: Micro-interactions directly impact perceived quality; choppy or absent transitions break the calm experience.

**Independent Test**: Can be verified by performing each task action and observing smooth transitions.

**Acceptance Scenarios**:

1. **Given** user clicks "Add Task", **When** the modal opens, **Then** it fades in with a subtle scale animation (not instant appearance).

2. **Given** user submits a new task, **When** the task is created, **Then** the new task item appears in the list with a subtle entrance animation (fade/slide in) and brief highlight.

3. **Given** user clicks the checkbox to complete a task, **When** the status changes, **Then** the task shows a smooth completion transition (e.g., checkbox fill animation, text style change with fade).

4. **Given** user deletes a task, **When** confirmed, **Then** the task item animates out (fade/slide) and remaining tasks smoothly close the gap.

5. **Given** user changes filter or sort, **When** the list updates, **Then** items reorder with a brief, smooth transition rather than instant jump.

6. **Given** user closes any modal, **When** dismissed, **Then** the modal fades out smoothly.

---

### User Story 3 - Calm Authentication Screens (Priority: P2)

The login and register pages share the same calm aesthetic as the main app, providing visual continuity from first impression.

**Why this priority**: First impressions matter; auth screens set tone but are visited less frequently than tasks.

**Independent Test**: Can be verified by visiting login/register pages and confirming visual consistency with design system.

**Acceptance Scenarios**:

1. **Given** a user visits `/login`, **Then** the page displays the calm dark theme with consistent typography, input styles, button styles, and subtle background atmosphere.

2. **Given** a user visits `/register`, **Then** the page matches the login page's visual style and uses the same design tokens.

3. **Given** a user submits the login form with invalid credentials, **When** an error appears, **Then** the error message is styled calmly (not harsh red) and appears with a subtle animation.

4. **Given** a user focuses on any input field, **When** focused, **Then** the input shows a smooth, visible focus ring transition.

---

### User Story 4 - Encouraging Empty & Success States (Priority: P2)

When there are no tasks or a task is completed, the messaging feels serene and gently motivating rather than sterile or harsh.

**Why this priority**: Empty states and feedback messages are key touchpoints for emotional tone.

**Independent Test**: Can be verified by viewing empty state and success toasts.

**Acceptance Scenarios**:

1. **Given** user has no tasks (all filter), **When** viewing empty state, **Then** message reads something like "A calm moment—no tasks yet. Start with just one."

2. **Given** user has no pending tasks (pending filter), **When** viewing empty state, **Then** message reads something like "You're all caught up. Enjoy the calm."

3. **Given** user successfully creates a task, **When** toast appears, **Then** it uses calm styling (subtle background, smooth entrance/exit) with encouraging text.

4. **Given** user successfully deletes a task, **When** toast appears, **Then** it confirms action with calm, non-alarming styling.

---

### User Story 5 - Reduced Motion Accessibility (Priority: P2)

Users who have `prefers-reduced-motion` enabled experience the app without distracting animations while retaining full functionality.

**Why this priority**: Accessibility is essential; motion can cause discomfort for some users.

**Independent Test**: Can be verified by enabling reduced motion preference and confirming animations are minimized.

**Acceptance Scenarios**:

1. **Given** user has `prefers-reduced-motion: reduce` set, **When** they perform any action, **Then** animations are either instant or use minimal fade (no transforms/slides).

2. **Given** user has `prefers-reduced-motion: reduce` set, **When** modals open/close, **Then** they appear/disappear without scale or slide animations.

3. **Given** reduced motion is enabled, **Then** all functionality remains intact—only animation duration/type changes.

---

### User Story 6 - Loading & Error States (Priority: P3)

Loading spinners and error messages fit the calm aesthetic and don't feel jarring.

**Why this priority**: These are transient states but contribute to overall polish.

**Independent Test**: Can be verified by simulating slow network and error conditions.

**Acceptance Scenarios**:

1. **Given** tasks are loading, **When** skeleton UI is displayed, **Then** skeletons use calm colors and subtle pulse animation.

2. **Given** an error occurs fetching tasks, **When** error message appears, **Then** it uses calm error styling (muted red/warm tone, not harsh) with retry affordance.

3. **Given** a modal is submitting, **When** button shows loading state, **Then** spinner animation is smooth and uses accent color.

---

### User Story 7 - Ambient Background Experience (Priority: P2)

The authenticated layout displays a mesmerizing but non-distracting ambient background with time-of-day aware orbital rings and a calm corner orb.

**Why this priority**: Creates the "wow" factor and premium feel; purely aesthetic enhancement.

**Independent Test**: Can be verified by viewing the authenticated layout at different times of day.

**Acceptance Scenarios**:

1. **Given** a user is on any authenticated page, **Then** they see 2-3 large circular/oval rings (Orbital Aurora Belt) anchored toward the bottom-left of the viewport.

2. **Given** it is morning (6:00-11:59), **Then** the orbital rings use soft blue + teal gradient colors.

3. **Given** it is afternoon (12:00-17:59), **Then** the orbital rings use blue + cyan gradient colors.

4. **Given** it is evening (18:00-5:59), **Then** the orbital rings use purple + deep navy gradient colors.

5. **Given** a user is on any authenticated page, **Then** they see a small gradient orb (Calm Orbit Marker) in the bottom-right corner with subtle pulse/rotate animation.

6. **Given** user has `prefers-reduced-motion: reduce` enabled, **Then** the orbital rings and orb are visible but completely static (no animation).

7. **Given** any ambient animation is running, **Then** text remains fully readable and interactive elements remain responsive.

---

### User Story 8 - Refined Header with Profile Avatar (Priority: P2)

The authenticated layout header displays a centered greeting and a profile avatar with dropdown menu.

**Why this priority**: Improves personalization and provides cleaner sign-out access.

**Independent Test**: Can be verified by logging in and interacting with the header.

**Acceptance Scenarios**:

1. **Given** a user is authenticated, **Then** the header displays: left (app title), center (greeting block), right (profile avatar).

2. **Given** user has name "Sarah Johnson", **Then** the avatar shows initials "SJ".

3. **Given** user has no name but email "alex@example.com", **Then** the avatar shows initials "A" (first letter of email).

4. **Given** user clicks or keyboard-activates the avatar, **Then** a dropdown menu opens showing user's name/email and "Sign out" action.

5. **Given** user clicks "Sign out" in the dropdown, **Then** existing signOut behavior is triggered and user is redirected to login.

6. **Given** user presses Escape or clicks outside dropdown, **Then** the dropdown closes.

7. **Given** user navigates with keyboard, **Then** dropdown is fully accessible (Tab, Enter, Escape work correctly).

---

### User Story 9 - Focus Summary Panel (Priority: P2)

The tasks page displays a Focus Summary Panel showing today's task statistics.

**Why this priority**: Provides at-a-glance progress awareness without adding new features.

**Independent Test**: Can be verified by viewing the tasks page with various task states.

**Acceptance Scenarios**:

1. **Given** user has 3 pending and 2 completed tasks, **Then** the Focus Summary shows: Pending: 3, Completed: 2, Total: 5, 40% completion.

2. **Given** user has 0 tasks, **Then** the Focus Summary shows: Pending: 0, Completed: 0, Total: 0, 0% completion.

3. **Given** any task state, **Then** a progress bar visually reflects the completion percentage.

4. **Given** 40% completion, **Then** motivational text displays "You're 40% through today's plan."

5. **Given** desktop viewport, **Then** the Focus Summary appears beside (e.g., right column) the main task list.

6. **Given** mobile viewport, **Then** the Focus Summary stacks below the task list.

---

### User Story 10 - Insights/Reflection Panel (Priority: P2)

The tasks page displays a Reflection Panel with context-aware motivational text.

**Why this priority**: Adds emotional polish without requiring AI or new backend features.

**Independent Test**: Can be verified by viewing the tasks page with various task states.

**Acceptance Scenarios**:

1. **Given** user has 0 total tasks, **Then** Reflection shows "A calm moment — you're all clear."

2. **Given** user has tasks but 0 completed, **Then** Reflection shows "Start with just one small task to build momentum."

3. **Given** user has < 50% completion, **Then** Reflection shows "Nice start. Keep a steady pace."

4. **Given** user has >= 50% completion, **Then** Reflection shows "Great progress. Protect your focus and finish strong."

5. **Given** any viewport size, **Then** the Reflection Panel displays below or beside the Focus Summary, responsive-friendly.

---

### User Story 11 - Authenticated Footer (Priority: P3)

The authenticated layout includes a slim footer with branding and links.

**Why this priority**: Adds polish and branding; lowest priority as it's purely informational.

**Independent Test**: Can be verified by scrolling to the bottom of any authenticated page.

**Acceptance Scenarios**:

1. **Given** user is on any authenticated page, **Then** a footer is visible at the bottom with "Built with Spec-Driven Development" on the left.

2. **Given** user views the footer, **Then** the right side shows text links: "Docs · GitHub · Contact" (placeholder hrefs).

3. **Given** any viewport size, **Then** the footer does not overlap main content.

4. **Given** the footer is visible, **Then** it has a subtle top border and uses calm, non-distracting styling.

---

### Edge Cases

- **Name contains special characters or is very long**: Greeting should truncate or handle gracefully without breaking layout.
- **Time zone edge cases**: Time-of-day detection should use client's local time, not server time.
- **Rapid filter/sort changes**: List should handle rapid state changes gracefully without animation pile-up.
- **Modal opened during list animation**: Should not cause visual glitches.
- **Very long task lists**: Animations should remain performant; consider limiting animated items in view.
- **Avatar with single-word name**: Show first letter only (e.g., "Madonna" → "M").
- **Dropdown menu positioning**: On mobile or near screen edge, dropdown should not overflow viewport.
- **Panel responsiveness**: Focus Summary and Reflection panels must not cause horizontal scroll on any breakpoint.
- **Footer spacing**: Footer must not overlap task list even when list is short.

---

## Requirements

### Functional Requirements

#### Design System & Tokens
- **FR-001**: System MUST define color tokens in Tailwind config for: background (primary, secondary, elevated), surface (card, modal, input), text (primary, secondary, muted), accent (primary, success, warning, error), and border colors.
- **FR-002**: System MUST define spacing scale tokens (xs, sm, md, lg, xl, 2xl) in Tailwind config.
- **FR-003**: System MUST define border-radius tokens (sm, md, lg, full) in Tailwind config.
- **FR-004**: System MUST define typography tokens (font sizes, weights, line heights) for headings, body, and small text.
- **FR-005**: System MUST define time-of-day color variants for background gradients (morning, afternoon, evening).

#### Time-of-Day Theming
- **FR-006**: System MUST detect user's local time and categorize as morning (6:00-11:59), afternoon (12:00-17:59), or evening (18:00-5:59).
- **FR-007**: System MUST display time-appropriate greeting text using the authenticated user's name from `session.user.name`.
- **FR-008**: System MUST gracefully handle missing user name by omitting the name portion from the greeting.
- **FR-009**: System MUST apply time-appropriate background gradient variant to the main layout.

#### Micro-Interactions (Must-Have)
- **FR-010**: Modal open MUST animate with fade + subtle scale transition.
- **FR-011**: Modal close MUST animate with fade out transition.
- **FR-012**: New task creation MUST show entrance animation on the new task item.
- **FR-013**: Task completion checkbox MUST show smooth state transition.
- **FR-014**: Task deletion MUST animate item exit and smooth gap closure.
- **FR-015**: Filter/sort changes MUST animate list reordering smoothly.

#### Micro-Interactions (Nice-to-Have)
- **FR-016**: Search input SHOULD show focus/blur transitions and clear button animation.
- **FR-017**: Load More button SHOULD animate newly loaded items into view.

#### Wow Layer – Ambient Background
- **FR-030**: System MUST render 2-3 large elliptical (oval) rings (Orbital Aurora Belt) with centers positioned slightly outside the viewport at the bottom-left corner, so rings partially extend off-screen.
- **FR-030a**: Largest ring MUST be ~60-80% of viewport width; smaller rings ~40-60%.
- **FR-031**: Orbital rings MUST use time-of-day gradient colors: morning (soft blue #60a5fa + teal #2dd4bf), afternoon (blue #3b82f6 + cyan #22d3ee), evening (purple #a78bfa + deep navy #1e3a8a).
- **FR-032**: Orbital rings MUST animate with very slow infinite rotation/scale (45-90s loop) using only `transform` and `opacity`.
- **FR-033**: System MUST render a small gradient orb (Calm Orbit Marker) in the bottom-right corner.
- **FR-034**: Calm orb MUST animate with subtle pulse/rotate (10-15s loop) using only `transform` and `opacity`.
- **FR-035**: All ambient animations MUST be disabled (static appearance) when `prefers-reduced-motion: reduce` is enabled.
- **FR-036**: Ambient elements MUST NOT impact readability of text or responsiveness of interactive elements.

#### Wow Layer – Header Refinement
- **FR-037**: Header layout MUST be responsive:
  - Desktop: left (app title), center (greeting block), right (profile avatar)
  - Mobile: stacked – top row (title left, avatar right), second row (greeting + subline full width)
- **FR-038**: Profile avatar MUST be circular with time-of-day aware gradient background (matching orbital aurora colors) and display user initials derived from `user.name` (first letter of first/last name) or first letter of email as fallback.
- **FR-039**: Profile avatar MUST open a dropdown menu on click or keyboard activation.
- **FR-040**: Dropdown menu MUST contain ONLY a single "Sign out" action – NO name/email text displayed.
- **FR-041**: Dropdown MUST close on Escape key, click outside, or selecting an action.
- **FR-042**: Dropdown MUST be keyboard accessible (Tab, Enter, Escape).
- **FR-043**: NO raw email or name text should be visible anywhere in header or dropdown – only avatar with initials.

#### Wow Layer – Content Panels
- **FR-044**: Tasks page MUST display a Focus Summary Panel with: pending count, completed count, total count, completion percentage (0-100, rounded). Stats computed from ALL current tasks (no date filtering).
- **FR-045**: Focus Summary Panel MUST include a progress bar visually reflecting completion percentage.
- **FR-046**: Focus Summary Panel MUST include calm motivational text using actual completion percentage (e.g., "You're 40% through today's plan.").
- **FR-047**: Tasks page MUST display a Reflection Panel with title "Reflection" and context-aware motivational text.
- **FR-048**: Reflection text rules (no AI): 0 tasks → "A calm moment — you're all clear."; 0 completed → "Start with just one small task to build momentum."; <50% → "Nice start. Keep a steady pace."; >=50% → "Great progress. Protect your focus and finish strong."
- **FR-049**: Focus Summary and Reflection panels MUST be responsive: beside task list on `lg` (≥1024px) and above, stacked below task list on <lg.

#### Wow Layer – Footer
- **FR-050**: Authenticated layout MUST display a slim footer using sticky footer pattern: at viewport bottom when content is short, after content in natural flow when content is tall.
- **FR-051**: Footer left MUST display "Built with Spec-Driven Development".
- **FR-052**: Footer right MUST display text links: "Docs · GitHub · Contact" (placeholder hrefs).
- **FR-053**: Footer MUST have subtle top border and blur/overlay styling.
- **FR-054**: Footer MUST NOT overlap main content at any breakpoint.

#### Accessibility
- **FR-018**: System MUST detect `prefers-reduced-motion` and reduce/disable animations accordingly.
- **FR-019**: All color combinations MUST meet WCAG AA contrast requirements.
- **FR-020**: Focus states MUST remain visible with smooth transition.

#### Screen Coverage
- **FR-021**: Login page MUST use the design system tokens and calm styling.
- **FR-022**: Register page MUST use the design system tokens and calm styling.
- **FR-023**: Tasks page (list, header, filters, search, sort, load more) MUST use design system tokens.
- **FR-024**: Add Task modal MUST use design system tokens and motion.
- **FR-025**: Edit Task modal MUST use design system tokens and motion.
- **FR-026**: Delete confirmation modal MUST use design system tokens and motion.
- **FR-027**: Empty states MUST display serene, encouraging copy with calm styling.
- **FR-028**: Loading states (skeletons, spinners) MUST use calm colors and smooth animations.
- **FR-029**: Error states and toasts MUST use calm styling (muted tones, smooth animations).

### Key Entities

- **Design Tokens**: Color palette, spacing scale, typography scale, border radii, animation durations—all documented in Tailwind config.
- **Time Period**: Enum-like concept (morning, afternoon, evening) derived from local time.
- **Greeting**: Composed of time-period prefix + optional user name + optional motivational suffix.
- **Animation Preset**: Reusable transition definitions (fade, scale, slide) with reduced-motion variants.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% of screens (login, register, tasks, modals, empty states, loading, error, toasts) use the documented design tokens—no one-off color or spacing values.

- **SC-002**: Time-of-day greeting correctly displays user's actual name (from session) in 100% of authenticated views when name is available.

- **SC-003**: All must-have micro-interactions (FR-010 through FR-015) render at 60fps as measured by browser performance tools (no frames >16ms).

- **SC-004**: When `prefers-reduced-motion: reduce` is enabled, 0 transform/slide animations occur—only opacity changes or instant transitions.

- **SC-005**: All text/background color combinations pass WCAG AA contrast checker (4.5:1 for body text, 3:1 for large text/UI components).

- **SC-006**: Empty state messaging uses approved serene copy (no generic "No data" or harsh language).

- **SC-007**: Design tokens are fully documented in `tailwind.config.ts` with semantic naming (e.g., `colors.surface.card`, `colors.text.primary`).

- **SC-008**: Users report the interface feels "calm" or "premium" in qualitative feedback (target: 80%+ positive sentiment if surveyed).

### Wow Layer Success Criteria

- **SC-009**: Orbital Aurora Belt and Calm Orbit Marker are visible on all authenticated pages, use correct time-of-day colors, and do not obstruct content.

- **SC-010**: All ambient animations (orbital rings, orb pulse) are completely static when `prefers-reduced-motion: reduce` is enabled.

- **SC-011**: Profile avatar displays correct initials (first letters of first/last name, or first letter of email as fallback).

- **SC-012**: Profile dropdown is fully keyboard accessible (Tab to focus, Enter to activate, Escape to close).

- **SC-013**: Focus Summary Panel correctly computes and displays pending, completed, total counts, and completion percentage based on current tasks.

- **SC-014**: Reflection Panel displays correct motivational text based on task completion state rules (no AI calls).

- **SC-015**: Focus Summary and Reflection panels are responsive: side-by-side with task list on desktop (≥1024px), stacked below on mobile/tablet (<1024px).

- **SC-016**: Footer is visible on all authenticated pages, does not overlap content, and contains correct branding text and placeholder links.

---

## Non-Goals

- **NG-001**: No structural changes to the data model or database schema.
- **NG-002**: No changes to API endpoints or contracts.
- **NG-003**: No changes to authentication/authorization flows (login logic, token handling, session management stay as-is).
- **NG-004**: No new business features (no priorities, tags, due dates, recurring tasks, reminders, AI chatbot).
- **NG-005**: No separate light mode implementation in this chunk.
- **NG-006**: No deployment, infrastructure, or Kubernetes work.
- **NG-007**: No mobile-specific responsive redesign beyond responsive stacking for new panels (existing responsive behavior remains).
- **NG-008**: No heavy animation libraries beyond potentially one scoped Framer Motion wrapper (if justified for list animations).
- **NG-009**: No AI/ML calls for the Reflection Panel—text is computed from simple rules only.
- **NG-010**: Footer links are placeholder hrefs only—no actual navigation or external pages required.

---

## Assumptions

- The authenticated user's name is optionally stored in `session.user.name` and was captured during registration.
- Client-side JavaScript can reliably detect local time for time-of-day theming.
- Tailwind CSS configuration can be extended without major build changes.
- Existing component structure (Button, Input, Modal, etc.) can be visually updated without changing their public API/props.
- The current dark background (`dark:bg-gray-900`) will be enhanced, not replaced with a fundamentally different approach.

---

## Design Token Reference (Proposed)

The following tokens will be defined in `tailwind.config.ts`. Exact hex values to be finalized during implementation:

### Colors
```
background:
  base: slate-950 (deepest dark)
  elevated: slate-900 (cards, modals)
  surface: slate-800 (inputs, hover states)

text:
  primary: slate-50 (headings, important text)
  secondary: slate-300 (body text)
  muted: slate-500 (placeholders, hints)

accent:
  primary: blue-400 (buttons, links, focus rings)
  primaryHover: blue-300
  success: emerald-400
  warning: amber-400
  error: rose-400 (muted, not harsh)

border:
  subtle: slate-700
  visible: slate-600

gradient:
  morning: soft amber/warm tint overlay
  afternoon: neutral/soft blue tint
  evening: deeper blue/purple tint
```

### Spacing
```
xs: 4px
sm: 8px
md: 16px
lg: 24px
xl: 32px
2xl: 48px
```

### Border Radius
```
sm: 4px
md: 8px
lg: 12px
full: 9999px
```

### Typography
```
heading-lg: 24px/32px, semibold
heading-md: 20px/28px, semibold
body: 16px/24px, normal
body-sm: 14px/20px, normal
caption: 12px/16px, normal
```

### Animation Durations
```
fast: 150ms
normal: 200ms
slow: 300ms
```

---

## Open Questions

None — all clarifications have been addressed in the pre-spec conversation.
