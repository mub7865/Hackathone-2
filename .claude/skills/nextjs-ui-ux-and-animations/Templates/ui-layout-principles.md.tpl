# Page Layout & UX Principles (Template)

> Is template ko har nayi screen / page ke design brief ke liye copy karo.
> Yahan pe tum apne page-specific decisions fill karoge, lekin rules
> hamesha same rahenge.

## 1. Page purpose

- Primary goal of this page:
  - Example: "Show user's tasks and let them quickly filter / complete."
- Primary action(s) user should be able to take:
  - Example: "Create task", "Filter tasks", "Mark as complete".

## 2. Information hierarchy

- Top-level sections (in vertical order):
  1. Hero / header:
     - Title:
     - Subtitle / context:
     - Primary CTA:
  2. Main content:
     - What user sees first:
     - Key data blocks / lists:
  3. Support / secondary info:
     - Tips, empty states, secondary actions:
  4. Footer / meta:
     - Links, copyright, etc.

- For each section, define:
  - Visual weight (high / medium / low).
  - One primary focal element.

## 3. Layout & spacing

- Global constraints:
  - Max content width:
    - e.g. `max-w-5xl` / `max-w-6xl`.
  - Alignment:
    - Centered or left-aligned content?

- Spacing system (4- or 8-point grid):
  - Vertical section padding:
    - Example: `py-16` or `py-20` (keep consistent across page).
  - Inner component spacing:
    - Allowed gaps/padding (multiples of 4): 4, 8, 12, 16, 24, 32, 40, 48.

- Grid:
  - Desktop:
    - How many columns / content splits? (e.g. 2-column layout: text + illustration)
  - Mobile:
    - Stacking order of sections / columns.

## 4. Typography

- Font family:
  - Headings:
  - Body:

- Type scale:
  - h1:
    - Size / weight / line-height:
  - h2:
    - Size / weight / line-height:
  - h3 / section titles:
  - Body:
  - Small text / captions:

- Hierarchy rules:
  - One h1 per page.
  - h2 for major sections, h3 for sub-sections.
  - Avoid more than 3 body text sizes.

## 5. Color & states

- Background(s):
  - Main background:
  - Section alternation (if any):

- Text colors:
  - Primary text:
  - Muted / secondary text:
  - Inverse (on dark surfaces):

- Interactive states:
  - Buttons:
    - Default:
    - Hover:
    - Active:
    - Disabled:
  - Links:
    - Default:
    - Hover / focus underline behavior:

## 6. Components used

- Cards:
  - Card variant(s) used on this page:
    - Padding:
    - Border radius:
    - Shadow / border:
  - Hover / focus behavior:

- Lists:
  - Item layout:
    - Leading element (icon/avatar):
    - Title + metadata:
    - Actions (buttons/menu placement):

- Forms:
  - Field spacing:
  - Label placement (above / inline):
  - Error message style:

## 7. Motion & interactions (high-level)

- Micro-interactions:
  - Buttons:
    - Hover behavior (scale / color / shadow):
  - Cards:
    - Hover behavior (lift / shadow / tilt):
  - Icons:
    - Any special motion?

- Content reveal:
  - Which sections animate on scroll into view?
    - Example: "Features grid fades in + slides up once when visible."

- Page transitions:
  - Entry / exit behavior (if using global PageTransition component).

## 8. Accessibility & reduced motion

- `prefers-reduced-motion` behavior:
  - Which animations are turned off or simplified?
  - Any large motion patterns to disable for these users?

- Focus states:
  - Confirm:
    - All interactive elements visibly focusable.
    - No animation hides or moves focused elements unexpectedly.
