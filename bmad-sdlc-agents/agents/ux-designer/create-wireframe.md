---
description: "[UX Designer] Create wireframes for a feature or user flow. Uses the project's chosen design tool (ASCII / Pencil / Figma) from .bmad/ux-design-master.md."
argument-hint: "[feature name or user flow]"
---

Create wireframes for a feature or user flow using the configured design tool.

## Steps

1. Parse $ARGUMENTS to extract the feature name. If empty, ask: "What feature or user flow should I create wireframes for?"

2. Check `.bmad/ux-design-master.md` to determine the configured design tool.

3. If `.bmad/ux-design-master.md` doesn't exist, run the **Wireframe Mode Selection** protocol from SKILL.md. Present the full option list and let the human choose:
   - **A) ASCII / Text** — markdown-embedded wireframes. No tool needed.
   - **B) Mermaid** — text diagrams for flows / IA. No tool needed.
   - **C) Excalidraw** — hand-drawn feel. Excalidraw MCP if connected, else edit in excalidraw.com and commit `master.excalidraw`.
   - **D) tldraw** — infinite-canvas whiteboard with AI integration.
   - **E) Pencil** — open-source desktop wireframing (Pencil MCP).
   - **F) Figma** — industry-standard collaborative design (Figma MCP).
   - **G) Penpot** — open-source Figma alternative.
   - **H) HTML / React prototype** — interactive prototypes via shadcn/ui + Tailwind.
   - **I) Google Stitch** — AI-generated UIs driven by `docs/ux/DESIGN.md`.
   - **J) Miro** — digital whiteboard for flows and journey maps.
   - **K) None / defer** — text-only specs for now.

   Before presenting the list, probe which MCPs are connected and mark those options as "✓ connected". Default if no answer is given: the first of `E → F → C → D → A` that has a connected MCP.

   Save the choice to `.bmad/ux-design-master.md` using the structure in SKILL.md §"Step 4 — Record the choice" (records design_tool, master file path/URL, page index).

3a. **Design system check (mandatory).** If `docs/ux/DESIGN.md` does not exist, run the **Design System Bootstrap** protocol from SKILL.md — copy `templates/design-system-template.md` to `docs/ux/DESIGN.md`, seed it with project defaults, and add an initial Changelog row before continuing. If it exists, read it in full now and use its tokens/components/patterns for every wireframe you produce in the next steps. No hardcoded colours, spacing, or component forks.

4. Read `docs/analysis/requirements-analysis.md` for feature requirements and acceptance criteria.

5. Read `docs/ux/user-journeys.md` if it exists to understand the user flows.

6. Produce the wireframes in the mode recorded in `.bmad/ux-design-master.md`:

   - **ASCII / Text** — markdown files under `docs/ux/wireframes/[feature-slug]/[screen-name].md`. Use box drawing or markdown tables. Document screen-to-screen flow and annotations.
   - **Mermaid** — `.mmd` files under `docs/ux/flows/` or ` ```mermaid ` fenced blocks in the feature UI spec. Good for flows, state diagrams, navigation trees.
   - **Excalidraw** — append/update `docs/ux/wireframes/master.excalidraw`. Use the Excalidraw MCP if connected; otherwise print the direction: *"Open master.excalidraw in excalidraw.com, add page `[EPIC-ID] Feature`, commit the updated file back."* Reference [`references/excalidraw-integration.md`](references/excalidraw-integration.md).
   - **tldraw** — append to `docs/ux/wireframes/master.tldr`. Use the tldraw MCP if connected. Reference [`references/tldraw-integration.md`](references/tldraw-integration.md).
   - **Pencil** — use `mcp__pencil__open_document` → `mcp__pencil__batch_design` on the master `.pencil` file. Create a new page per screen/flow. Reference [`references/pencil-mcp-integration.md`](references/pencil-mcp-integration.md).
   - **Figma** — use `mcp__figma__get_figma_data` to read existing frames; follow the master file convention (one page per epic). Reference [`references/figma-mcp-integration.md`](references/figma-mcp-integration.md).
   - **Penpot** — instruct the human to open the Penpot project URL, add the new page, export PNGs into `docs/ux/wireframes/[feature]/`.
   - **HTML / React prototype** — scaffold `docs/ux/wireframes/[feature-slug]/page.tsx` using shadcn/ui + Tailwind. Every style value must resolve to a token path from `docs/ux/DESIGN.md` via CSS variables — no hex/px literals. Reference [`references/html-prototype-integration.md`](references/html-prototype-integration.md).
   - **Stitch** — compose a prompt referencing `docs/ux/DESIGN.md`, paste into the Stitch project, export the generated screens as reference images into `docs/ux/wireframes/[feature-slug]/`. Reference [`references/stitch-integration.md`](references/stitch-integration.md).
   - **Miro** — for flows / journey maps only. Pair with a pixel-fidelity mode for actual screens.
   - **None / defer** — skip this step and proceed to annotations-only text specs.

7. Update `.bmad/ux-design-master.md` to add the new pages/frames to the page index (include the tool, page name, feature/epic, and status).

8. **DESIGN.html sync (mandatory).** If step 6 wrote any new token, component, or pattern into `docs/ux/DESIGN.md`, immediately regenerate the HTML visualization:
   ```bash
   python3 ~/.bmad/scripts/render-design-md.py --input docs/ux/DESIGN.md
   ```
   On Claude Code / Kiro the PostToolUse hook fires automatically — confirm by checking that `docs/ux/DESIGN.html` has an mtime ≥ `docs/ux/DESIGN.md`. If the mtimes disagree, run the renderer manually. See SKILL.md §"🔒 Non-negotiable: DESIGN.html stays in lockstep with DESIGN.md".

9. Confirm: "Wireframes created for [feature] → [location]. [N] screens designed. Tool: [mode]. DESIGN.html regenerated: [yes/no/not needed]."
