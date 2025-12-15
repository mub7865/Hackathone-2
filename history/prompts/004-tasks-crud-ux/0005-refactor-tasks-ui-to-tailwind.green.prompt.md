---
id: "0005"
title: "Refactor Tasks UI to Tailwind"
stage: green
date: 2025-12-13
surface: agent
model: claude-sonnet-4-5-20250929
feature: 004-tasks-crud-ux
branch: 004-tasks-crud-ux
user: architect
command: /sp.implement
labels: ["frontend", "tailwind", "refactor", "styling", "implementation"]
links:
  spec: specs/004-tasks-crud-ux/spec.md
  ticket: null
  adr: null
  pr: null
files:
  - phase2/frontend/package.json
  - phase2/frontend/tailwind.config.ts
  - phase2/frontend/postcss.config.js
  - phase2/frontend/app/globals.css
  - phase2/frontend/app/layout.tsx
  - phase2/frontend/app/login/page.tsx
  - phase2/frontend/app/(authenticated)/layout.tsx
  - phase2/frontend/app/(authenticated)/tasks/page.tsx
tests:
  - npm run type-check (PASS)
---

## Prompt

Right now the Tasks CRUD UI implementation is using normal CSS instead of Tailwind, which violates the updated spec and plan. Refactor the existing Tasks UI under phase2/frontend so that:
- All styling is expressed via Tailwind utility classes or shared components.
- Any new CSS modules or global CSS files added for this chunk are removed or minimized back to only what the Tailwind setup requires.

Show me the diffs for the frontend files you change, and explain briefly how you replaced the old CSS with Tailwind classes.

## Response snapshot

Refactored all frontend files from inline CSS styles and CSS variables to Tailwind utility classes:

**Files Changed**:
1. `package.json` - Added tailwindcss, postcss, autoprefixer dependencies
2. `tailwind.config.ts` - Created Tailwind configuration with content paths
3. `postcss.config.js` - Created PostCSS configuration
4. `globals.css` - Reduced from 100 lines of CSS variables/rules to 3 lines of Tailwind directives
5. `layout.tsx` - Added Tailwind classes for body styling
6. `login/page.tsx` - Replaced all `style={{}}` with Tailwind classes
7. `(authenticated)/layout.tsx` - Replaced inline styles and `<style>` tag with Tailwind
8. `(authenticated)/tasks/page.tsx` - Replaced inline styles with Tailwind

**Key Replacements**:
- `style={{ display: 'flex' }}` → `className="flex"`
- `var(--color-primary)` → `bg-blue-600`
- `var(--spacing-md)` → `p-4`
- `@keyframes spin` inline → `animate-spin` Tailwind utility
- Dark mode CSS variables → `dark:` prefix variants

## Outcome

- ✅ Impact: All styling now uses Tailwind CSS utility classes, spec compliance achieved
- 🧪 Tests: TypeScript type-check passes
- 📁 Files: 8 files modified/created
- 🔁 Next prompts: Continue Phase 1 implementation (T002-T008)
- 🧠 Reflection: Clean migration from inline styles to Tailwind; dark mode support preserved via Tailwind dark: variants

## Evaluation notes (flywheel)

- Failure modes observed: None - straightforward CSS-to-Tailwind mapping
- Graders run and results (PASS/FAIL): type-check PASS
- Prompt variant (if applicable): Standard /sp.implement with refactor focus
- Next experiment (smallest change to try): Verify build works in dev mode
