# tldraw Integration

tldraw is an infinite-canvas whiteboard with strong AI-agent integration (the tldraw team ships SDK support for programmatic generation + manipulation). It's a good choice for projects where the agent needs to *author* the wireframes directly rather than hand them to a human editor.

## Master file convention

One file per project: `docs/ux/wireframes/master.tldr`.

Each feature / epic becomes a named "page" within the same file. The infinite canvas means you can also lay everything out side-by-side on a single page with labelled regions — whichever fits the project's information architecture.

## Workflow — MCP connected (`mcp__tldraw__*`)

When the tldraw MCP is connected:

1. Open the master file — `mcp__tldraw__open_file` (or equivalent tool name, depending on the MCP server's surface).
2. Create a new page for the feature/epic with the name convention `[EPIC-ID] Feature Name`.
3. Programmatically emit shapes for each screen, connected by arrows for flow. Use tldraw's built-in shape library — not custom freehand — so layouts stay editable.
4. Set the style of every coloured shape to a palette colour that matches `docs/ux/DESIGN.md`'s `colors:` block. Use tldraw's color-palette customization if the MCP exposes it.
5. Export a PNG per screen into `docs/ux/wireframes/[feature-slug]/` and save the master.

## Workflow — no MCP (manual edit-commit loop)

```
To update the wireframes for [Feature X]:

1. Open https://tldraw.com/ (or the self-hosted instance if you have one)
2. File → Open → docs/ux/wireframes/master.tldr (from your repo working copy)
3. Add a new page named: [EPIC-ID] Feature X
4. Draft screens, use Connect tool for flow arrows.
5. File → Save → overwrite master.tldr
6. File → Export image → PNG → save to docs/ux/wireframes/[feature-slug]/
7. Commit both.
```

## Why pick tldraw over Excalidraw

- **AI-first:** tldraw's data model is explicit and easy for an agent to manipulate directly via MCP — Excalidraw's is also JSON but with less programmatic tooling.
- **Infinite canvas zoom:** easier to keep the whole project's screens visible on one page.
- **More pixel-accurate:** tldraw's shapes are geometric by default, which aligns better with DESIGN.md token sizes than Excalidraw's hand-drawn aesthetic.

## When tldraw is the wrong choice

- **Engineering-grade handoff** — Figma / Pencil produce more faithful engineering deliverables.
- **Teams already invested in Figma/Excalidraw** — the switching cost outweighs the advantages.

## Design-system conformance

Same rule as every other tool: every interactive element annotates the component name it maps to in `docs/ux/DESIGN.md`'s `components:` block. Colors must come from the palette. No magic values — if tldraw displays a hex, that hex must also be in the YAML front matter of DESIGN.md.
