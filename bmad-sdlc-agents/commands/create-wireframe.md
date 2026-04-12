---
description: Create wireframes for a feature or user flow. Uses the project's chosen design tool (ASCII / Pencil / Figma) from .bmad/ux-design-master.md.
argument-hint: "[feature name or user flow]"
---

Create wireframes for a feature or user flow using the configured design tool.

## Steps

1. Parse $ARGUMENTS to extract the feature name. If empty, ask: "What feature or user flow should I create wireframes for?"

2. Check `.bmad/ux-design-master.md` to determine the configured design tool.

3. If `.bmad/ux-design-master.md` doesn't exist:
   - Ask the user to choose: A) ASCII text wireframes (markdown), B) Pencil (if MCP connected), C) Figma (web-based).
   - Save the choice to `.bmad/ux-design-master.md` with format: "design_tool: [ascii|pencil|figma]" and "pages: []"

4. Read `docs/requirements/requirements-analysis.md` for feature requirements and acceptance criteria.

5. Read `docs/ux/user-journeys.md` if it exists to understand the user flows.

6. For **ASCII mode** (markdown):
   - Create text-based wireframes showing key screens/components using ASCII box drawing or markdown tables.
   - Document flow: which screens connect to which, what user actions trigger transitions.
   - Include annotations: UI elements, form fields, buttons, error states.
   - Save wireframe artifacts to `docs/ux/wireframes/[feature-slug]/[screen-name].md`.

7. For **Pencil mode** (using mcp__pencil__ tools):
   - Use `mcp__pencil__open_document` to open the master design file (or create a new one).
   - Create a new page per screen/flow.
   - Design frames with proper labeling and annotations.
   - Save wireframes to the Pencil document.

8. For **Figma mode** (web-based):
   - Use the Figma API/URL to access the project.
   - Create frames for each screen in the feature flow.
   - Document interactions and annotations in Figma.

9. Update `.bmad/ux-design-master.md` to add the new pages/frames to the page index.

10. Confirm: "Wireframes created for [feature] → [location]. [N] screens designed."
