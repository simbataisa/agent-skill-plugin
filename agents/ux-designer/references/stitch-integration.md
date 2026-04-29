# Google Stitch Integration

[Google Stitch](https://stitch.withgoogle.com/) is an AI-powered UI generator from Google Labs. It reads your `docs/ux/DESIGN.md` directly (the file format is literally Google's open-source `DESIGN.md` spec) and produces UI screens that respect your tokens, components, and constraints.

This makes Stitch a natural fit for BMAD: your design system is already in the format Stitch expects, so there's zero translation cost.

## Master file convention

Stitch is a hosted service, so the "master file" is a Stitch project URL recorded in `.bmad/ux-design-master.md`:

```markdown
**Design Tool:** Stitch
**Master File:** https://stitch.withgoogle.com/projects/<project-id>
**DESIGN.md:** docs/ux/DESIGN.md  (Stitch reads this directly)
```

Stitch projects also let you export individual screens as PNGs. Save those alongside your wireframes folder for offline review:

```
docs/ux/wireframes/
  <feature-slug>/
    stitch-export-1.png
    stitch-export-2.png
    PROMPT.md           # the prompt used to generate the screens
```

## Workflow

1. **Confirm DESIGN.md is current.** Stitch will read whatever is in `docs/ux/DESIGN.md` at the moment of generation. Run `/ux-designer:design-system audit` first; ensure `npx @google/design.md lint docs/ux/DESIGN.md` reports zero `broken-ref` errors.

2. **Open the Stitch project** at the URL recorded in `.bmad/ux-design-master.md`. If it doesn't exist yet, create one and paste the URL back into the master reference.

3. **Upload / paste DESIGN.md** into the Stitch project context. Stitch automatically applies the YAML tokens to its generated UIs.

4. **Compose the prompt** — keep it grounded in the design system. A good Stitch prompt for BMAD:
   ```
   Generate the [Feature X] [screen name] screen.
   Conform strictly to the attached DESIGN.md:
     - Primary action uses the `button` component (variant `button-primary`)
     - Card styling uses the `card` component
     - All colours must resolve to {colors.*} tokens
     - All spacing must resolve to {spacing.*} tokens
     - Show all 5 states: loading, empty, populated, error, offline
   Layout: [describe the screen's information architecture in 2–3 sentences]
   ```
   Save the final prompt in `docs/ux/wireframes/[feature-slug]/PROMPT.md` so the generation is reproducible.

5. **Iterate visually** in Stitch until the screen matches the spec. Stitch's iteration UI is the strength — keep refining the prompt rather than hand-editing pixels.

6. **Export** each finalised screen as PNG into `docs/ux/wireframes/[feature-slug]/`. Commit both PNGs and `PROMPT.md`.

7. **Update the page index** in `.bmad/ux-design-master.md`.

## Cross-tool synergy

Stitch is best as a *generator*, not a final source-of-truth. Common patterns:

- **Stitch + Figma** — generate in Stitch, hand-tune in Figma. Record both URLs in the master reference.
- **Stitch + HTML/React** — use Stitch to bootstrap the design quickly, then re-implement as a real interactive prototype with shadcn/ui + Tailwind.
- **Stitch + Excalidraw** — wireframe the flow in Excalidraw, generate the actual screens in Stitch.

## Why pick Stitch

- **Zero token-translation cost** — Stitch reads `DESIGN.md` natively.
- **Speed** — generate 5 screen variants in 30 seconds.
- **Constraint-respecting** — Stitch won't drift outside the declared tokens (unlike unconstrained image-generation models).

## When Stitch is the wrong choice

- **Highly novel UI patterns** — Stitch generates from a token-bound design system, so wholly new patterns require human ideation first.
- **Engineering handoff as final deliverable** — the PNGs aren't editable; pair Stitch with HTML/React for the final spec.
- **Air-gapped / on-prem teams** — Stitch is a hosted Google service; pick Penpot or HTML/React if Stitch can't be reached.

## Design-system conformance

Because Stitch reads `DESIGN.md` and generates from it, conformance is implicit. The risk is the inverse: humans tweaking screens *outside* the system. The rule:

- **If a Stitch generation surfaces a need for a new token / component / pattern**, stop. Run `/ux-designer:design-system extend <thing>` to add it to `DESIGN.md` first, then regenerate.
- **Never** edit Stitch screens with hex literals or bespoke values that aren't backed by the YAML.
