---
name: "[Project Name]"
version: "alpha"
description: "[One-sentence description of the brand / product / system this design system governs.]"
colors:
  primary: "#1A73E8"
  primaryHover: "#1557B0"
  onPrimary: "#FFFFFF"
  danger: "#D93025"
  onDanger: "#FFFFFF"
  success: "#1E8E3E"
  warning: "#F9AB00"
  background: "#F8F9FA"
  surface: "#FFFFFF"
  border: "#E8EAED"
  textSecondary: "#5F6368"
  text: "#202124"
typography:
  display-lg:
    fontFamily: "Inter"
    fontSize: "32px"
    fontWeight: 700
    lineHeight: "40px"
    letterSpacing: "-0.02em"
  heading-lg:
    fontFamily: "Inter"
    fontSize: "24px"
    fontWeight: 600
    lineHeight: "32px"
    letterSpacing: "-0.01em"
  heading-md:
    fontFamily: "Inter"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: "28px"
  body-md:
    fontFamily: "Inter"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: "24px"
  body-sm:
    fontFamily: "Inter"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "20px"
  label:
    fontFamily: "Inter"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: "16px"
    letterSpacing: "0.04em"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  base: "16px"
  lg: "24px"
  xl: "32px"
  2xl: "48px"
rounded:
  sm: "4px"
  md: "8px"
  lg: "12px"
  full: "9999px"
components:
  button:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.onPrimary}"
    typography: "{typography.body-md}"
    rounded: "{rounded.md}"
    padding: "{spacing.sm} {spacing.base}"
  button-hover:
    backgroundColor: "{colors.primaryHover}"
    textColor: "{colors.onPrimary}"
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary}"
    typography: "{typography.body-md}"
    rounded: "{rounded.md}"
    padding: "{spacing.sm} {spacing.base}"
  button-danger:
    backgroundColor: "{colors.danger}"
    textColor: "{colors.onDanger}"
    typography: "{typography.body-md}"
    rounded: "{rounded.md}"
    padding: "{spacing.sm} {spacing.base}"
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    typography: "{typography.body-md}"
    rounded: "{rounded.sm}"
    padding: "{spacing.sm} {spacing.md}"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.md}"
    padding: "{spacing.lg}"
---

## Overview

[Two to four short paragraphs describing the brand's personality, tone, and how this design system expresses them. Call out the three to five non-negotiable principles — e.g. "clarity over decoration", "predictable not clever", "accessible by default". These principles are the "why" behind every token and component decision that follows; every agent that implements UI should be able to trace a token back to a principle.]

**Authority.** This file is the single source of truth for every UI/UX decision in this project. Every feature that changes the UI must read it, conform to it, and update it (with a Changelog row in the Do's and Don'ts section) when it introduces anything new. If a feature needs something that would contradict an existing entry, stop and resolve the conflict with the human before coding.

**Cross-agent contract.** UX Designer authors and extends this file. Frontend Engineer and Mobile Engineer read it and refuse to implement screens whose tokens/components aren't declared here. If a UI spec and this file disagree, **this file wins** — send the story back to UX Designer.

## Colors

[Explain the palette intent: which colour carries primary actions, which carries destructive actions, which carries surface/background vs. text. Call out any WCAG pairings the agent must respect — e.g. `{colors.text}` on `{colors.surface}` = 16.1:1 (AAA), `{colors.onPrimary}` on `{colors.primary}` = 5.2:1 (AA).]

- `{colors.primary}` — primary actions, links, active navigation.
- `{colors.danger}` — destructive actions, error messages, validation failures. Never as decoration.
- `{colors.success}` — confirmations, success toasts. Never as decoration.
- `{colors.warning}` — attention-required states. Pair with an icon; never rely on colour alone.
- `{colors.background}` / `{colors.surface}` — page vs. card. Agents must compose surface on background, never surface on surface without a separator.
- `{colors.text}` / `{colors.textSecondary}` — primary vs. secondary typography. Contrast must remain ≥4.5:1 against whichever surface they sit on.

## Typography

[Describe the type scale's intent: which ramp is for narrative reading, which is for UI labels, which is for hierarchy. Name the font family choice and the fallback stack. Note any platform-specific adjustments (e.g. iOS defaults to San Francisco when Inter is unavailable).]

- `{typography.display-lg}` — hero headlines, dashboard page titles (one per screen).
- `{typography.heading-lg}` — section titles within a page.
- `{typography.heading-md}` — card / panel titles.
- `{typography.body-md}` — default body text, inputs, buttons.
- `{typography.body-sm}` — tables, dense lists, captions.
- `{typography.label}` — form labels, tags, small uppercase UI chrome.

## Layout

[Describe the spacing scale intent and the responsive grid. Name the canonical breakpoints and how margins/gutters scale across them.]

- Spacing scale: `{spacing.xs}` → `{spacing.2xl}`. Never use values outside the scale.
- Responsive breakpoints:
  - Mobile — up to 767px.
  - Tablet — 768px–1023px.
  - Desktop — 1024px and above.
- Gutters: `{spacing.base}` on mobile, `{spacing.lg}` on tablet, `{spacing.xl}` on desktop.
- Container max-width: 1280px with centred alignment on desktop.

## Elevation & Depth

[Define the elevation ramp and what each level means. Keep it short — 3–4 levels total.]

| Level | Shadow                     | Usage                                         |
| ----- | -------------------------- | --------------------------------------------- |
| 0     | none                       | Flat elements, flush surfaces                 |
| 1     | 0 1px 2px rgba(0,0,0,0.10) | Cards, raised list items                      |
| 2     | 0 2px 8px rgba(0,0,0,0.15) | Dropdowns, popovers, autocomplete menus       |
| 3     | 0 4px 16px rgba(0,0,0,0.20)| Modals, sheets, dialogs                       |

## Shapes

[Describe the corner-radius language. Tie each radius to a purpose — inputs vs. cards vs. pills.]

- `{rounded.sm}` — text inputs, small buttons, tags.
- `{rounded.md}` — cards, modals, primary buttons.
- `{rounded.lg}` — marketing / hero surfaces only.
- `{rounded.full}` — avatars, status pills.

## Components

[One subsection per component in the inventory. Each subsection must describe: purpose, variants, states (default / hover / focus / active / disabled / loading / error), anatomy (sub-elements in layout order), accessibility contract (role, keyboard behaviour, ARIA attributes), and "do / don't" rules. Always cite tokens by reference — never inline hex/px/ms.]

### Button

Primary call-to-action. One primary button per screen; everything else uses `button-secondary` or `button-ghost`.

- **Variants:** `button` (primary), `button-secondary`, `button-danger`, `button-icon` (24×24, requires tooltip).
- **States:** default, hover (`button-hover`), focus-visible (2px focus ring in `{colors.primary}`), active (shifted 1px down), disabled (`aria-disabled="true"`, opacity 0.5, no pointer events), loading (spinner replaces label, width preserved).
- **Anatomy:** `[optional leading icon] · [label] · [optional trailing icon]`.
- **A11y contract:** role `button`, keyboard activatable via Enter + Space, visible focus ring at all times, loading announces via `aria-busy="true"`.
- **Do / Don't:** do — single primary per screen. Don't — two primaries side-by-side. Don't — remove focus ring.

### Input

Text input for form fields.

- **Variants:** `input` (default), `input-readonly`, `input-error`.
- **States:** default, focus (ring in `{colors.primary}`), error (border in `{colors.danger}`, helper text references field via `aria-describedby`), disabled.
- **Anatomy:** `[label above field] · [optional leading icon] · [text] · [optional trailing icon] · [helper text below]`.
- **A11y contract:** native `<input>`, `<label>` linked via `htmlFor`; error text linked via `aria-describedby`.

### Card

Content container for grouped information.

- **Variants:** `card` (default), `card-interactive` (adds hover state for click targets).
- **States:** default, hover (elevation level 1 → 2), focus (2px ring) when interactive.
- **Anatomy:** `[optional header] · [body] · [optional footer with actions]`.
- **A11y contract:** non-interactive by default; when interactive, wrap in a `<button>` or `<a>` with a visible focus ring.

*(Add new component subsections in place when a feature introduces them — never fork into a separate file.)*

## Do's and Don'ts

### Do

- **Reference tokens by name** in every screen spec and UI spec — e.g. `{colors.primary}`, `{spacing.base}`, `{typography.body-md}`. Never inline hex / px / ms literals.
- **Reuse components** before proposing new ones. Every new component needs a justification entry in §Components and an existing screen that motivates it.
- **Define all 5 screen states** — loading, empty, populated, error, offline/degraded — for every screen before handing off to engineering.
- **Extend this file in place** for every new token / component / pattern. Add the entry in the right section, add a Changelog row, bump the Version.
- **Verify with the validator** before handing off: `npx @google/design.md lint docs/ux/DESIGN.md`. Fix every `broken-ref` error; resolve `contrast-ratio` and `orphaned-tokens` warnings.

### Don't

- **Don't hardcode values.** A screen spec that says "background: #1a73e8" instead of "background: {colors.primary}" is a drift bug waiting to happen.
- **Don't fork a component** to add a single prop. Extend the existing component entry instead.
- **Don't silently override.** If a feature needs a change that conflicts with an existing entry, stop and resolve with the human before coding — then update this file to reflect the decision.
- **Don't ship a screen with only the happy path.** Empty / loading / error / offline must all be defined.
- **Don't rely on colour alone** to convey meaning. Every coloured state needs an icon, text, or pattern.

### Changelog

Every feature that adds, removes, or changes a token/component/pattern appends an entry here. Reference the feature PRD or story ID. The changelog is how future agents (and future humans) understand *why* the design system looks the way it does.

| Date       | Version | Change                               | Driven by                           |
|------------|---------|--------------------------------------|-------------------------------------|
| YYYY-MM-DD | 0.1.0   | Initial seed (bootstrap defaults)    | UX Designer — project initialisation |

Version bump convention: **patch** = additive token (e.g. new colour alias); **minor** = new component or pattern; **major** = breaking rename or removal.

### Validation

Run the Google Stitch linter after every change:

```bash
npx @google/design.md lint docs/ux/DESIGN.md
```

The linter checks: `broken-ref` (error — token references that don't resolve), `contrast-ratio` (warning — WCAG AA 4.5:1 on `backgroundColor`/`textColor` pairs), `orphaned-tokens` (warning — defined but never referenced), `missing-primary`, `missing-typography`, `section-order`, and `token-summary`. Treat every error as a merge blocker; treat warnings as "resolve or justify."

### Extend this file (for feature teams)

1. **Check first.** Search this file for an existing token / component / pattern that covers the use case. Reuse always beats adding.
2. **If nothing fits, propose an addition.** Draft the new entry in the relevant section (YAML front matter for tokens, Components section for components, Do's/Don'ts for rules).
3. **Conflict?** Do NOT silently override. Ask the human which should win — then update *this file* with the resolved value and a Changelog row explaining the decision.
4. **Record it.** Append a Changelog row with the date, a semver bump, a one-line summary, and the feature that drove it.
5. **Link it from the feature spec.** In `docs/ux/specs/[feature].md`, reference every new token/component by name — never inline the value.
6. **Validate.** Run `npx @google/design.md lint docs/ux/DESIGN.md`. Zero errors before you commit.
