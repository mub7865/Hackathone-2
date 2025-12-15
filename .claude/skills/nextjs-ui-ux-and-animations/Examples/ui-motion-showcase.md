# UI & Motion Showcase (Example)

## GOOD: Calm, purposeful motion

- Layout:
  - Sections clearly separated with consistent vertical spacing (e.g. `py-16` on desktop, `py-10` on mobile).
  - Content width constrained (`max-w-5xl`), centered, with 4/8-point spacing inside cards and lists.
  - Typography uses a tight scale: single h1, h2 for sections, consistent body size and line-height.

- Motion:
  - Hero content:
    - Page wraps in `<PageTransition>`: subtle fade + 10px slide-up on entry, no crazy zoom.
  - Sections:
    - Each major section wrapped in `<FadeInSection>` so it fades & slides up once when scrolled into view.
    - Staggered list items using `staggerContainer` + `fadeInUpItem` variants for cards.
  - Hover:
    - Cards wrapped in `<HoverLift>` for tiny lift + scale on hover, tap compress on mobile.

Result:  
Page feels alive but not “noisy”; animations guide attention, remain under ~250ms, and only animate `opacity` + `transform`, which keeps performance smooth even on mid‑range devices. [web:204][web:205][web:211][web:214]

---

## GOOD: Respecting reduced motion

- Behavior when `prefers-reduced-motion: reduce` is set:
  - `<PageTransition>`, `<FadeInSection>`, and `<HoverLift>` all fall back to plain `<div>` / `<main>` without motion.
  - No auto-scrolling, no parallax, no continuous looping animations.
  - Focus outlines and keyboard navigation behave identically with or without motion.

Result:  
Users who are motion-sensitive still get a clean, usable UI with clear hierarchy, just minus the transitions, matching modern accessibility guidance. [web:205][web:214]

---

## BAD: Overdone, janky animation

- Layout issues:
  - Every section has different random paddings (`py-13`, `py-27`), inconsistent card spacing.
  - Text blocks span full width on desktop, making them hard to read.
  - No clear visual hierarchy; multiple h1-sized elements on the same screen.

- Motion problems:
  - Multiple large elements animate `width`, `height`, `margin`, and `box-shadow` on hover and scroll.
  - Scroll-linked parallax on 3–4 layers simultaneously; FPS drops on laptops and phones.
  - Long (600–800ms) bouncy animations on every route change, causing lag and “UI laggy” feeling.
  - No `prefers-reduced-motion` handling: even motion-sensitive users get full animations.

Result:  
Site looks “flashy” but feels heavy; scrolling stutters, route changes feel slow, and users can’t predict where to look first. [web:204][web:205][web:211][web:217]

---

## BAD: Inconsistent micro-interactions

- Buttons:
  - Every button variant has different hover behavior (one scales 1.2x, another rotates slightly, third only changes color).
  - Some buttons animate color with very slow transitions (~600ms), making UI feel laggy.

- Cards:
  - Some cards jump 10–15px on hover and push nearby content down (layout shift).
  - Others animate both `top` and `left` causing reflow instead of using `transform`.

Result:  
Interactions feel unpredictable and “cheap”; users can’t build muscle memory, and layout shifts on hover break the sense of polish. [web:206][web:208][web:211][web:214]
