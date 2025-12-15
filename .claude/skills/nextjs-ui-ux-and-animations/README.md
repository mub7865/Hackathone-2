# Skill: nextjs-ui-ux-and-animations

## Purpose

Yeh Skill Next.js App Router projects ke liye ek opinionated **UI/UX + high-performance animation system** define karta hai. [web:204]  
Goal yeh hai ke har naya frontend project same spacing, typography, layout aur smooth, GPU‑friendly animations follow kare, taake tumhara “signature look” consistent rahe.

## What this Skill defines

- **SKILL.md**  
  - Layout & spacing rules (4/8-point grid, section structure, max content width).
  - Typography hierarchy (limited type scale, clear headings vs body text).
  - Component patterns (cards, lists, CTAs) as design guidelines.
  - Motion system:
    - Transform + opacity‑only animations.
    - Duration/easing tokens (fast/normal/slow).
    - Micro‑interactions, section reveal, page transitions.
  - Performance & accessibility guardrails:
    - Avoid layout‑thrashing animations.
    - Respect `prefers-reduced-motion` for motion-sensitive users. [web:204][web:205]

- **Templates/**
  - `ui-layout-principles.md.tpl`  
    - Page design brief template:
      - Page purpose, information hierarchy.
      - Layout & spacing decisions (section padding, grid).
      - Typography & color choices.
      - Components used (cards, lists, forms).
      - Motion plan (what animates, how, and reduced‑motion behavior).

  - `framer-motion-patterns.tsx.tpl`  
    - Reusable motion primitives for Next.js + Framer Motion:
      - `PageTransition` – subtle page enter/exit animation.
      - `FadeInSection` – scroll-in fade + slide‑up for sections.
      - `HoverLift` – small lift/scale for cards/buttons.
      - `staggerContainer` + `fadeInUpItem` – staggered list reveals.
    - Sab components `transform` + `opacity` animate karte hain aur
      `useReducedMotion` ke through reduced‑motion users ke liye
      graceful fallback dete hain. [web:204][web:205]

- **Examples/**
  - `ui-motion-showcase.md`  
    - GOOD vs BAD examples:
      - GOOD: calm, purposeful motion, consistent spacing & typography,
        scroll‑reveal + subtle hovers.
      - BAD: over‑animated UI, layout‑thrashing properties, inconsistent
        micro‑interactions, no reduced‑motion handling. [web:204][web:211]

## When to enable this Skill

Is Skill ko enable karo jab:

- Next.js App Router frontend ke liye **clean, premium‑feel UI** chahiye ho.
- Tum chahte ho ke Claude:
  - Har page ke liye structured UX brief follow kare.
  - Animations hamesha smooth, short, aur GPU‑friendly likhe.
  - `prefers-reduced-motion` automatically respect kare. [web:204][web:205]

Ye Skill `nextjs-16-app-router-structure` aur
`nextjs-frontend-api-client-patterns` ke sath best kaam karta hai, taake
structure, data fetching aur animations teenon aligned rahen.

## How to integrate in a project

Typical integration steps:

1. **Design brief**  
   - Har nayi page/screen ke liye `ui-layout-principles.md.tpl` ko copy
     karke fill karo (e.g. `specs/ui/home-page.md`).
   - Is brief ke basis pe Claude se layout + components banwao.

2. **Motion primitives add karo**  
   - `framer-motion-patterns.tsx.tpl` se file create karo, for example:
     - `frontend/components/motion/patterns.tsx`.
   - Pages aur sections ko:
     - `<PageTransition>` se wrap karo.
     - Major sections ko `<FadeInSection>` me daalo.
     - Cards/buttons pe `<HoverLift>` use karo.

3. **Design system align karo**  
   - Spacing, typography, aur colors ko Tailwind config ya design tokens
     file me lock karo, aur components (Button, Card, Section) ko
     inhi rules ke mutabiq build karo.

4. **Reduced motion verify karo**  
   - Browser dev tools / OS settings se `prefers-reduced-motion` enable
     karke ensure karo ke heavy motion gracefully disable/soft ho jaye. [web:205]

Iske baad Claude se jab bhi “UI banao” ya “animations add karo” bolo,
to woh isi Skill ke patterns aur components reuse karega, na ke har baar
naya random style invent kare.

## Components ka status (short explanation)

- Is Skill me **components ka zikr do levels par hua tha**:
  - Conceptual base UI components (Button, Card, Section, etc.) – ye
    abhi sirf rules/description ke level par define kiye gaye hain, unke
    liye abhi concrete `.tsx` templates nahi likhe.  
  - Motion components – inka **actual template humne bana diya hai**:
    `PageTransition`, `FadeInSection`, `HoverLift`, `staggerContainer`,
    `fadeInUpItem` Framer Motion file me ready honge.

