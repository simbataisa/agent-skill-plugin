# HTML / React Prototype Integration

The highest-fidelity wireframe mode: build actual interactive prototypes with shadcn/ui + Tailwind inside the project repo, using real components resolved from `docs/ux/DESIGN.md`. Frontend and Mobile engineers can run them in-place, verify accessibility in a real browser, and reuse the components in production with minimal rewriting.

## Master file convention

One folder per feature under `docs/ux/wireframes/`:

```
docs/ux/wireframes/
  login-flow/
    page.tsx                 # the interactive prototype
    README.md                # state list, interaction spec
  transfer-flow/
    page.tsx
    amount-input.tsx         # sub-components extracted when shared
    README.md
```

Each prototype is a standalone Next.js / Vite / plain-React page. If the project has a Storybook or design-system package, mirror the convention used there.

## DESIGN.md → CSS-variable bridge

HTML/React prototypes must pull every colour, spacing, typography, and radius value from `docs/ux/DESIGN.md` — no hardcoded values. Expose the YAML tokens as CSS custom properties:

```css
/* docs/ux/wireframes/_tokens.css — generated once, committed alongside the prototype */
:root {
  --colors-primary-500: #E31B8E;   /* from {colors.primary-500} */
  --colors-neutral-0: #FFFFFF;     /* from {colors.neutral-0} */
  --spacing-base: 16px;            /* from {spacing.base} */
  --rounded-md: 10px;              /* from {rounded.md} */
}
```

Then in Tailwind config:

```ts
// tailwind.config.ts (in the prototype folder or repo root)
export default {
  theme: {
    extend: {
      colors: { primary: 'var(--colors-primary-500)', /* … */ },
      spacing: { base: 'var(--spacing-base)', /* … */ },
      borderRadius: { md: 'var(--rounded-md)', /* … */ },
    },
  },
};
```

Every component in the prototype must reference Tailwind classes that resolve to these tokens — never `bg-[#E31B8E]` or inline styles with raw hex.

## Workflow

1. Check the project has shadcn/ui + Tailwind set up. If not, ask the human to confirm before scaffolding — this mode has real dependency weight.
2. Read `docs/ux/DESIGN.md` and generate / update `docs/ux/wireframes/_tokens.css` from the YAML front matter. Re-run whenever DESIGN.md changes.
3. Scaffold `docs/ux/wireframes/[feature-slug]/page.tsx` using the shadcn component primitives that map 1:1 to the entries in DESIGN.md's `components:` block (Button → `<Button variant="primary">`, Input → `<Input>`, Card → `<Card>`, etc.).
4. Write each screen as a separate function component; switch between them via a local state router so the prototype is self-contained.
5. Add a `README.md` next to `page.tsx` that lists: the 5 states (loading / empty / populated / error / offline), interaction spec (every click/hover/focus target), a11y notes (focus order, ARIA roles).
6. Link the prototype from `.bmad/ux-design-master.md`'s page index.

## Why pick HTML/React

- **Highest engineering fidelity** — what you see is exactly what Frontend will build.
- **Accessibility verification in a real browser** — keyboard nav, screen reader, `prefers-reduced-motion`, dark mode — all testable.
- **No translation loss at handoff** — the prototype code becomes the starting point for production components.

## When HTML/React is the wrong choice

- **Early exploration** — too expensive; use Excalidraw or tldraw first.
- **Projects without a React host** — mobile-only native teams, server-rendered stacks without React, etc. Use Figma or Pencil instead.
- **Time-boxed design spikes** — pixel-fidelity up-front is not always worth the build time.

## Handoff to engineering

Treat the prototype as the UI spec. In the feature story, reference the prototype path (`docs/ux/wireframes/[feature]/page.tsx`) instead of describing screens in prose. The Frontend engineer reads the prototype source, copies the components into the production tree, wires real data / state management, and keeps the props contract intact.
