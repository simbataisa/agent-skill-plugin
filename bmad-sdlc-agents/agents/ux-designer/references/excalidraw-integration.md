# Excalidraw Integration

Excalidraw gives wireframes a hand-drawn / whiteboard aesthetic. It's popular for early exploration, architecture sketches, and low-fi flows. The `.excalidraw` file format is JSON, commits cleanly to git, and renders natively in GitHub / GitLab via embed previews.

## Master file convention

One file per project: `docs/ux/wireframes/master.excalidraw`.

Every feature / epic becomes a named library element or a separate "scene" section within the same file. For larger projects, split by domain:

```
docs/ux/wireframes/
  master.excalidraw          # the project-wide master
  library/
    components.excalidraw    # reusable symbol library (optional)
```

## Workflow — MCP connected (`mcp__excalidraw__*`)

If an Excalidraw MCP server is wired up:

1. Read the existing master via the MCP's read tool (typically `get_scene` / `read_file`).
2. Append a new "scene" or "page" for the feature/epic. Name it `[EPIC-ID] Feature Name` for consistency with the page-index convention in `.bmad/ux-design-master.md`.
3. Lay out the screens left-to-right in reading order; connect them with labelled arrows for flow.
4. Export a screenshot (PNG) via the MCP's export tool into `docs/ux/wireframes/[feature-slug]/` so downstream reviewers don't need to open the `.excalidraw` file.
5. Save the master file back.

## Workflow — no MCP (manual edit-commit loop)

Print clear, copy-pasteable instructions to the human:

```
To update the wireframes for [Feature X]:

1. Open https://excalidraw.com/
2. Load the master file: docs/ux/wireframes/master.excalidraw
   (File → Open → pick the file from your repo working copy)
3. Add a new frame/page titled: [EPIC-ID] Feature X
4. Draft the screens left-to-right, connect with arrows for flow.
5. File → Save to disk → overwrite docs/ux/wireframes/master.excalidraw
6. File → Export image → PNG → save to docs/ux/wireframes/[feature-slug]/overview.png
7. Commit both files.
```

Then ask the human to confirm when they're done, and update the page index.

## Design-system conformance

Excalidraw's freeform nature makes it easy to drift from `docs/ux/DESIGN.md` tokens. Mitigations:

- **Colour palette:** paste the `{colors.primary-500}` / `{colors.neutral-0}` hex values from `docs/ux/DESIGN.md` into the Excalidraw custom palette at the start of every session.
- **Annotation rule:** every interactive element in an Excalidraw screen must be labelled with the component name it maps to in DESIGN.md's `components:` block (e.g. `button-primary`, `card`, `input`). If a screen needs a visual element that isn't in DESIGN.md, stop and update DESIGN.md first (per the Design System Bootstrap protocol).

## When Excalidraw is the wrong choice

- **Pixel-perfect mocks** — use Figma or Pencil instead; Excalidraw's hand-drawn style obscures precise sizing.
- **Real-time multi-person editing** — Excalidraw supports rooms but the `.excalidraw` file is single-user when committed; for heavy collaboration pick Figma, tldraw, or Miro.
- **Complex component states** — low-fi wireframes can't show 5 states per screen cleanly; pair Excalidraw with text state specs in `docs/ux/specs/`.

## Handoff to engineering

Export every finalised screen to PNG alongside the `.excalidraw` source so Frontend / Mobile engineers can read them without opening the editor. The PNG lives at `docs/ux/wireframes/[feature-slug]/<screen>.png`; the source-of-truth is the master `.excalidraw` file.
