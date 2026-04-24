---
description: "[UX Designer] Create, audit, extend, validate, sync, or render docs/ux/DESIGN.md — the project's Google Stitch DESIGN.md file. Also regenerates docs/ux/DESIGN.html, a self-contained browser visualization of every token, component, and pattern. Every feature that touches the UI must read or update the design system via this command."
argument-hint: "[create|audit|extend <thing>|validate|sync|render] (default: auto-detect; after create/extend the HTML visualization is refreshed automatically)"
---

Create, audit, extend, validate, or render the project's design system at `docs/ux/DESIGN.md`, following the **Google Stitch DESIGN.md specification** ([spec](https://stitch.withgoogle.com/docs/design-md/specification/) · [open-source ref + linter](https://github.com/google-labs-code/design.md)). The command also maintains a **browser-viewable HTML visualization** at `docs/ux/DESIGN.html` that renders every color swatch, typography specimen, spacing/radius scale, elevation level, component preview, and WCAG contrast report.

## Arguments (auto-detected if omitted)

| $ARGUMENTS            | Action                                                                                                                                       |
|-----------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| `create`              | Bootstrap a new `docs/ux/DESIGN.md` from the Stitch-compliant template **and** regenerate `docs/ux/DESIGN.html`.                              |
| `audit`               | Read the existing file, check Stitch spec compliance, list issues. Does not edit. Refreshes `docs/ux/DESIGN.html` so the audit reflects live tokens. |
| `extend <thing>`      | Add a new token / component / pattern, bump version, add Changelog row **and** regenerate `docs/ux/DESIGN.html`.                              |
| `validate`            | Run `npx @google/design.md lint docs/ux/DESIGN.md` and report. No edits, no HTML rebuild.                                                    |
| `sync`                | Reconcile the file against the latest agent inputs (PRD, wireframes, UI spec). Regenerates HTML after changes.                              |
| `render` (alias `html`) | Regenerate `docs/ux/DESIGN.html` from the existing `docs/ux/DESIGN.md`. No edits to the markdown source.                                    |
| *(empty)*             | Auto-detect: `create` if `DESIGN.md` is missing, `audit` if it exists.                                                                       |

## Steps

### 0. Preflight — read the SKILL.md Bootstrap protocol

If this is your first turn on this project, read `SKILL.md` sections **Project Context Loading**, **Wireframe Mode Selection**, and **Design System Bootstrap** before taking any action on the design system file. They define the file location, the Stitch spec commitments, and the cross-agent contract this command enforces.

### 1. Load inputs

Read, in priority order, whichever of these exist:

- `.bmad/PROJECT-CONTEXT.md` — project name, brand constraints
- `.bmad/tech-stack.md` — component library choice (shadcn/ui, MUI, native, etc.)
- `docs/prd.md` — product vision, user segments
- `docs/ux/personas.md`, `docs/ux/user-journeys.md` — UX context
- `docs/analysis/*-impact.md` — feature impact (when extending for a specific feature)

### 2. Check the file

Look for `docs/ux/DESIGN.md` (case-sensitive, per the Stitch spec). Branch on what you find:

#### 2a. File missing → CREATE

1. Copy [`templates/design-system-template.md`](templates/design-system-template.md) to `docs/ux/DESIGN.md`.
2. **Patch the YAML front matter** with project-specific values:
   - `name`: from `.bmad/PROJECT-CONTEXT.md` or the $ARGUMENTS
   - `description`: one-sentence project description
   - `version`: keep `"alpha"` (current Stitch spec version)
   - `colors`: use brand colours from PRD / project context if specified, otherwise keep the template defaults and flag them as provisional in your completion summary
   - `typography`: use the specified type ramp if given, otherwise keep the Inter-based template defaults
   - `spacing`, `rounded`, `components`: keep template defaults unless the project has decided otherwise
3. **Preserve canonical Stitch section order** in the markdown body: Overview → Colors → Typography → Layout → Elevation & Depth → Shapes → Components → Do's and Don'ts. The `section-order` linter rule will fail if you reorder.
4. In §Overview, replace the bracketed brand-voice prompt with 2–4 paragraphs describing the project's design intent (pulled from the PRD + persona files).
5. In the Changelog table (inside §Do's and Don'ts), add a seed row: `YYYY-MM-DD | 0.1.0 | Initial seed | UX Designer — [project initialisation | bootstrap for feature X]`.
6. Jump to step 4 (validate), then step 5 (announce).

#### 2b. File exists → AUDIT (or EXTEND / VALIDATE per argument)

Read the whole file. Confirm the following structural invariants before any edit:

- YAML front matter exists between `---` fences at the top.
- Required fields present: `name`, `colors` (object of hex values), `typography` (object with at least one entry that has `fontFamily` + `fontSize`).
- Markdown sections appear in the canonical Stitch order.
- Changelog is present under §Do's and Don'ts.

Then branch on $ARGUMENTS:

- **`audit`** — print a structured report of: structural violations, token coverage gaps, orphaned tokens, component inventory holes, missing accessibility pairings. Suggest fixes but do not apply them.
- **`extend <thing>`** — add the new entry in the right place:
  - New **token** → under the appropriate YAML block (`colors:` / `typography:` / `spacing:` / `rounded:`). If it's a new alias of an existing value, also add a `{path}` reference comment.
  - New **component** → add a YAML entry under `components:` with `backgroundColor`, `textColor`, `typography`, `rounded`, `padding` as applicable (using `{path.to.token}` refs), then add a Components subsection describing variants, states, anatomy, accessibility contract, and do/don'ts.
  - New **pattern or rule** → add under §Do's and Don'ts with explicit `Do:` / `Don't:` bullets.
  - **Bump the version** in the YAML front matter: patch (e.g. 0.1.0 → 0.1.1) for additive tokens, minor (0.1.0 → 0.2.0) for new components or patterns, major (0.1.0 → 1.0.0) for breaking renames/removals.
  - **Add a Changelog row** with date, bumped version, one-line summary, and the feature story/PRD ID that drove the change.
- **`validate`** — run the Stitch linter (step 4) and report results; no file edits.
- **`sync`** — cross-reference against recent wireframes in `docs/ux/wireframes/` and the latest `docs/ux/ui-spec.md`; add any tokens/components that are used in specs but missing from the YAML; remove any orphaned tokens (but only after checking `git blame` hasn't just added them).

#### Conflict-resolution rule (applies to EXTEND and SYNC)

If an addition would **contradict** an existing entry — different primary colour, different button padding, incompatible component naming — **do NOT silently override.** Stop, surface the conflict to the human with a short comparison table (existing vs. proposed), and wait for a decision. Once the human decides, update the file with the resolved value and add a Changelog row that references the decision.

### 3. Cite tokens in every downstream spec

After every edit, remind the caller that downstream specs must reference tokens via the Stitch `{path.to.token}` syntax — e.g. `{colors.primary}`, `{typography.body-md}`, `{spacing.base}`, `{rounded.md}`. Never inline hex/px/ms values in wireframes, UI specs, or component code. Frontend/Mobile engineers will refuse to implement screens that cite tokens not declared in DESIGN.md.

### 4. Validate against the Stitch spec

Run the official linter:

```bash
npx @google/design.md lint docs/ux/DESIGN.md
```

Resolution policy:

| Rule                | Severity | Action                                                                   |
|---------------------|----------|--------------------------------------------------------------------------|
| `broken-ref`        | error    | Merge blocker. Fix every one before declaring completion.                |
| `contrast-ratio`    | warning  | Fix when it touches brand-critical pairs; otherwise document exception.  |
| `orphaned-tokens`   | warning  | Remove if truly unused; keep (justified) if reserved for upcoming work.  |
| `missing-primary`   | warning  | Add a `primary` colour unless the brand explicitly has none.             |
| `missing-typography`| warning  | Add at least one typography entry.                                       |
| `section-order`     | warning  | Restore canonical order (Overview → Colors → … → Do's and Don'ts).      |
| `token-summary`     | info     | Review the count; unusually low counts usually mean you missed a block. |

If `npx` isn't available or the linter errors, fall back to a manual structural check:

- Do `broken-ref` yourself: for every `{path.to.token}` reference in the file, verify the path resolves inside the YAML front matter. Report any that don't.
- Do `contrast-ratio` yourself: compute the ratio for every `backgroundColor`/`textColor` pair in `components:`. Flag pairs below 4.5:1.

### 5. Render the HTML visualization

After any edit (or on explicit `render` / `html` invocation), regenerate the browser-viewable HTML at `docs/ux/DESIGN.html`. This file is a self-contained page (inline CSS + JS, no external dependencies beyond system fonts) using a dual-column layout — fixed left sidebar + scrollable main — that renders:

- **Sidebar** — sticky left nav with brand-gradient mark, project name, and version. Grouped into **Foundations** (Colors, Typography, Spacing, Radius, Shadows, Motion), **Components** (one link per component), **Patterns** (auto-extracted from `## Patterns` subheadings), and **Principles** (Design principles, Accessibility). A scroll-spy highlights the active section as the reader scrolls.
- **Dark-mode toggle** — explicit button in the header; persists choice to `localStorage` and honours `prefers-color-scheme` on first visit.
- **Page header** — project name, description, version, source path, generation timestamp.
- **Brand gradient hero** — if the YAML declares a `gradients:` block, the first gradient is rendered as a full-width hero with the CSS gradient string shown inline. Otherwise, a gradient is synthesized from the first three palette colors.
- **Auto-grouped color palette** — the renderer detects scale patterns (`primary-50…primary-900`, or nested `primary: {50: …}`) and emits them as cohesive ramps labelled "Brand — Primary", "Brand — Neutral", etc. Flat non-scale tokens collect into a "Tokens" group. Each swatch card shows chip + label + hex + click-to-copy token path + WCAG AA grade vs. a detected background.
- **Typography specimens** — each `typography:` entry rendered at its exact font/size/weight/line-height with the pangram and a mono-spaced metadata line.
- **Spacing scale** — proportional bars showing each `spacing:` value with its token path and measurement.
- **Radius scale** — live corner previews with a visible gradient demo block for each `rounded:` token.
- **Shadows ramp** — four-level elevation samples (Level 0 → Level 3).
- **Motion tokens** — if `motion:` is declared in the YAML, each easing/duration is rendered as a card; otherwise a placeholder prompts you to add the block.
- **Component gallery** — every `components:` entry gets its own `<section id="{component-name}">` (sidebar-jumpable), rendered with tokens applied (buttons render as buttons, inputs as inputs, cards as cards), variants shown inline as pills, full props table with raw reference + resolved value.
- **Patterns** — each `### <name>` under `## Patterns` renders as a standalone card with its own anchor id.
- **Accessibility contrast report** — auto-computed WCAG 2.2 ratios for every `backgroundColor`/`textColor` pair in components; AAA / AA / AA-large / Fail badges.
- **Design principles** — rendered prose from the §Do's and Don'ts section including Do/Don't bullets + Changelog table.
- **Click-to-copy** — token paths like `{colors.primary-500}` are clickable for direct copy into screen specs (visual "Copied!" confirmation).

**Primary rendering path (deterministic, CI-friendly):**

```bash
python3 /path/to/bmad-sdlc-agents/scripts/render-design-md.py \
    --input docs/ux/DESIGN.md \
    --output docs/ux/DESIGN.html
```

The script is stdlib-only (no PyYAML, no build step) and works on macOS / Linux / Windows with any Python 3.8+. Output summary example: `✓ Rendered docs/ux/DESIGN.md -> docs/ux/DESIGN.html — 12 colors · 6 type tokens · 6 components`.

**Fallback path (agent-authored):** if Python isn't available on the host, emit `docs/ux/DESIGN.html` directly using the Write tool. Structure must match what the Python script produces — same 9 sections in canonical order, same click-to-copy token paths, same inline CSS. The cross-agent contract requires that the HTML reflects the current `docs/ux/DESIGN.md` byte-for-byte; if you hand-author it, re-run `npx @google/design.md lint docs/ux/DESIGN.md` afterwards to catch drift.

**Commit policy:** commit `docs/ux/DESIGN.html` alongside `docs/ux/DESIGN.md`. The HTML is an auto-generated artefact but teams benefit from being able to click straight to the visualization from their repo browser (GitHub, GitLab, Bitbucket all render HTML previews).

### 6. Announce, record, and hand off

Print:

```
🎨 docs/ux/DESIGN.md — <created | updated | audited>
   Stitch spec: v<YAML version>
   Linter: <N> errors, <M> warnings (<top-level summary>)
   HTML: docs/ux/DESIGN.html (<N> colors · <M> type tokens · <K> components · dark-mode ready)
   This session added: [list of tokens/components/patterns, or 'no changes' for audit-only]
   Changelog: Row <YYYY-MM-DD | vX.Y.Z | summary>
```

Then:

- Update `.bmad/handoff-log.md` with a one-line entry referencing the new version **and** the HTML file (so the next reviewer can jump straight to the visualization).
- If running in a squad and the design system is now ready for engineering, note that in the handoff log so Frontend/Mobile can pick it up — they should open `docs/ux/DESIGN.html` in a browser before reading screen specs.

## Stitch spec quick reference

**YAML front matter (required fields):** `name`, `colors`, `typography`.
**YAML front matter (optional):** `version` ("alpha"), `description`, `rounded`, `spacing`, `components`.
**Markdown sections (canonical order):** Overview · Colors · Typography · Layout · Elevation & Depth · Shapes · Components · Do's and Don'ts.
**Token reference syntax:** `{path.to.token}` — e.g. `{colors.primary}`, `{typography.body-md}`, `{spacing.base}`.
**File name:** `DESIGN.md` (case-sensitive).
**File location in this project:** `docs/ux/DESIGN.md` (+ `docs/ux/DESIGN.html` visualization, regenerated by this command).
**Linter:** `npx @google/design.md lint docs/ux/DESIGN.md`.
**HTML renderer:** `python3 scripts/render-design-md.py --input docs/ux/DESIGN.md` (stdlib-only, no deps).

## Completion rule

Never complete this command with a `broken-ref` error outstanding. If you cannot resolve one (missing token, undecided brand choice), return to the caller with the conflict surfaced and wait for a decision — do NOT guess a value. Similarly, never complete `create` / `extend` without regenerating `docs/ux/DESIGN.html` — the HTML is part of the deliverable, not an afterthought.
