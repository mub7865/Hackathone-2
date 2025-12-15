# Basic Next.js App Router Structure (Example)

GOOD:

- `app/layout.tsx` defines the HTML shell and wraps `children`.
- `app/page.tsx` defines the landing page for `/`.
- Additional routes go under `app/<segment>/page.tsx`.
- Shared components live under `app/(components)` or `/components`.

BAD:

- No `app/layout.tsx`, everything rendered from a single client component.
- Mixing multiple unrelated routes in one file.
- Deeply nested folders without clear layouts or route groups.
