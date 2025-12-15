# Research: UI Theme, Motion & Calm Experience

**Feature**: 006-ui-theme-motion
**Date**: 2024-12-14
**Status**: Complete

---

## Technical Decisions

### 1. Animation Library Strategy

**Decision**: Use Tailwind CSS transitions + CSS keyframes as primary; introduce Framer Motion only for AnimatePresence (list enter/exit)

**Rationale**:
- Tailwind's built-in `transition-*` classes handle 90% of use cases (buttons, inputs, modal fade/scale)
- CSS keyframes can handle custom animations (pulse, highlight)
- Framer Motion's `AnimatePresence` is uniquely capable of animating elements leaving the DOM (task deletion, filter changes)
- Single, scoped usage keeps bundle size minimal (~15KB gzipped for framer-motion)

**Alternatives Considered**:
| Option | Rejected Because |
|--------|------------------|
| Pure CSS only | Cannot animate DOM removal without complex workarounds |
| React Spring | Heavier bundle, steeper learning curve, no AnimatePresence equivalent |
| GSAP | Overkill for UI micro-interactions, licensing considerations |
| Full Framer Motion everywhere | Unnecessary complexity; Tailwind handles simple cases better |

---

### 2. Design Token Architecture

**Decision**: Semantic tokens in `tailwind.config.ts` using Tailwind's `extend.colors` with nested object structure

**Rationale**:
- Native Tailwind approach—no build plugins needed
- Semantic naming (`bg-surface-card`, `text-primary`) is self-documenting
- Easy to maintain and update across all components
- TypeScript autocomplete works out of the box

**Token Structure**:
```typescript
theme: {
  extend: {
    colors: {
      background: { base, elevated, surface },
      text: { primary, secondary, muted },
      accent: { primary, hover, success, warning, error },
      border: { subtle, visible },
    },
    backgroundImage: {
      'gradient-morning': '...',
      'gradient-afternoon': '...',
      'gradient-evening': '...',
    },
  },
}
```

**Alternatives Considered**:
| Option | Rejected Because |
|--------|------------------|
| CSS Custom Properties directly | Less Tailwind integration, no autocomplete |
| Tailwind plugin (tailwindcss-theme-variants) | Added dependency, unnecessary complexity |
| Separate design-tokens.ts file | Extra indirection; Tailwind config is already the source of truth |

---

### 3. Time-of-Day Detection

**Decision**: Client-side hook `useTimeOfDay()` using `new Date().getHours()` with client's local timezone

**Rationale**:
- Simple, no server dependency
- Respects user's actual local time (not server timezone)
- Can be memoized to avoid recalculation on every render
- Easy to test with mocked dates

**Implementation**:
```typescript
// hooks/useTimeOfDay.ts
type TimePeriod = 'morning' | 'afternoon' | 'evening';

export function useTimeOfDay(): TimePeriod {
  const hour = new Date().getHours();
  if (hour >= 6 && hour < 12) return 'morning';
  if (hour >= 12 && hour < 18) return 'afternoon';
  return 'evening';
}
```

**Alternatives Considered**:
| Option | Rejected Because |
|--------|------------------|
| Server-side detection | Would need user timezone passed, adds complexity |
| Real-time updates (setInterval) | Unnecessary; users don't stare at greeting for hours |
| Geolocation-based sunrise/sunset | Over-engineered for this use case |

---

### 4. Personalized Greeting Source

**Decision**: Read `session.user.name` from existing auth client via `getSession()` in authenticated layout

**Rationale**:
- Session already loaded in `AuthenticatedLayout`
- No new API calls needed
- Graceful fallback when name is undefined
- Consistent with existing auth patterns

**Implementation Location**: `app/(authenticated)/layout.tsx` or a new `GreetingHeader` component

**Alternatives Considered**:
| Option | Rejected Because |
|--------|------------------|
| New API endpoint for user profile | Unnecessary network request; data already in session |
| Context provider for user | Over-engineered; session is already accessible |
| Server component fetch | Complicates hydration; client already has session |

---

### 5. Reduced Motion Detection

**Decision**: CSS media query `@media (prefers-reduced-motion: reduce)` + React hook for JS-controlled animations

**Rationale**:
- CSS handles Tailwind transition overrides automatically
- Hook needed for Framer Motion's `animate` prop adjustments
- Tailwind v3.4+ has `motion-reduce:` variant built-in

**Implementation**:
```typescript
// hooks/useReducedMotion.ts
export function useReducedMotion(): boolean {
  const [prefersReduced, setPrefersReduced] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReduced(mq.matches);
    const handler = (e: MediaQueryListEvent) => setPrefersReduced(e.matches);
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, []);

  return prefersReduced;
}
```

**CSS Approach**:
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

### 6. Modal Animation Strategy

**Decision**: CSS transitions for fade + scale (no Framer Motion needed for modals)

**Rationale**:
- Modal is shown/hidden via `isOpen` prop, not removed from DOM
- Tailwind `transition-opacity transition-transform` handles both directions
- Simpler than Framer Motion for this use case

**Implementation Pattern**:
```tsx
// Modal.tsx
<div className={`
  transition-all duration-200 ease-out
  ${isOpen
    ? 'opacity-100 scale-100'
    : 'opacity-0 scale-95 pointer-events-none'
  }
`}>
```

---

### 7. List Animation Strategy (Task Add/Delete/Reorder)

**Decision**: Framer Motion `AnimatePresence` + `motion.div` for task list items

**Rationale**:
- AnimatePresence is the only React-friendly way to animate exit
- Staggered animations are trivial with `transition.delay`
- FLIP animations for reordering via `layout` prop

**Implementation**:
```tsx
// TaskList.tsx
<AnimatePresence mode="popLayout">
  {tasks.map((task, index) => (
    <motion.div
      key={task.id}
      layout
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, x: -20 }}
      transition={{ duration: 0.2, delay: index * 0.02 }}
    >
      <TaskItem ... />
    </motion.div>
  ))}
</AnimatePresence>
```

---

### 8. Responsive Strategy

**Decision**: Mobile-first with Tailwind breakpoints; existing responsive patterns preserved

**Rationale**:
- Existing app already uses `sm:` breakpoints
- No layout restructuring needed per spec Non-Goals
- Focus is on visual theme, not responsive redesign

**Key Breakpoints Used**:
- Default: Mobile (< 640px)
- `sm:` (640px+): Tablet/Desktop adjustments

---

## Dependencies

### New Dependencies

| Package | Version | Purpose | Bundle Impact |
|---------|---------|---------|---------------|
| framer-motion | ^11.x | AnimatePresence for list animations | ~15KB gzipped |

### Existing Dependencies (No Changes)

- tailwindcss: Already configured
- next: App Router patterns unchanged
- react: Hooks patterns unchanged

---

## File Impact Summary

### Files to Create (New)
- `hooks/useTimeOfDay.ts` - Time period detection
- `hooks/useReducedMotion.ts` - Motion preference detection
- `components/ui/AnimatedList.tsx` - Framer Motion wrapper for lists
- `components/layout/GreetingHeader.tsx` - Time-aware greeting component

### Files to Modify (Existing)
- `tailwind.config.ts` - Design tokens
- `app/globals.css` - Reduced motion styles, gradient definitions
- `app/(authenticated)/layout.tsx` - Integrate greeting, gradient background
- `app/login/page.tsx` - Apply design tokens
- `app/register/page.tsx` - Apply design tokens
- `components/ui/Button.tsx` - Design tokens + transitions
- `components/ui/Input.tsx` - Design tokens + focus transitions
- `components/ui/Textarea.tsx` - Design tokens + focus transitions
- `components/ui/Checkbox.tsx` - Smooth state transitions
- `components/ui/Modal.tsx` - Fade/scale animations
- `components/ui/Toast.tsx` - Calm styling + animations
- `components/ui/Skeleton.tsx` - Calm colors
- `components/tasks/TaskItem.tsx` - Design tokens
- `components/tasks/TaskList.tsx` - AnimatePresence integration
- `components/tasks/EmptyState.tsx` - Serene copy + styling
- `components/tasks/TaskModal.tsx` - Design tokens
- `components/tasks/DeleteConfirmModal.tsx` - Design tokens
- `components/tasks/TaskFilterTabs.tsx` - Design tokens + transitions
- `components/tasks/TaskSearchInput.tsx` - Design tokens + focus
- `components/tasks/TaskSortDropdown.tsx` - Design tokens

---

## Open Questions Resolved

All technical questions have been resolved through this research phase. No blockers remain for implementation planning.
