# Pencil MCP Integration

> Load this reference at the start of any design task when `mcp__pencil__*` tools are available in your session. Always prefer Pencil over static markdown wireframes — it produces real, editable designs with live design tokens.

---

## Detecting Pencil MCP

```
If mcp__pencil__* tools appear in your available tools → Pencil desktop is connected. Use it.
If not → fall back to HTML/SVG wireframes or markdown specs (see Fallback section below).
```

Check with `mcp__pencil__get_editor_state` first — it tells you what document is open and the current canvas state.

---

## Tool Reference (Pencil Desktop MCP)

### Session & Document

| Tool | Purpose |
|---|---|
| `mcp__pencil__open_document` | Open a `.pen` design file by path |
| `mcp__pencil__get_editor_state` | Get current editor state — what's open, selected layer, viewport |
| `mcp__pencil__get_screenshot` | Capture a screenshot of the current canvas view (returns image) |
| `mcp__pencil__snapshot_layout` | Full layout snapshot — all frames, positions, and layer hierarchy |

### Reading Design Data

| Tool | Purpose |
|---|---|
| `mcp__pencil__batch_get` | Read multiple nodes/layers in one call — preferred for bulk inspection |
| `mcp__pencil__get_style_guide` | Full style guide — colours, typography, spacing, effects |
| `mcp__pencil__get_style_guide_tags` | List style guide categories/tags for filtering |
| `mcp__pencil__get_variables` | All design variables/tokens (colours, spacing, radius, etc.) |
| `mcp__pencil__get_guidelines` | Alignment guidelines defined on the canvas |
| `mcp__pencil__search_all_unique_properties` | Search all nodes for a property value (e.g. audit every use of a colour) |
| `mcp__pencil__find_empty_space_on_canvas` | Find a clear area on canvas to place new content without overlap |

### Writing & Modifying Design

| Tool | Purpose |
|---|---|
| `mcp__pencil__batch_design` | Batch create or modify design elements — frames, shapes, text, components |
| `mcp__pencil__set_variables` | Update design variable/token values (e.g. rebrand a colour token system-wide) |
| `mcp__pencil__replace_all_matching_properties` | Find-and-replace a property value across all matching nodes |

### Export

| Tool | Purpose |
|---|---|
| `mcp__pencil__export_nodes` | Export nodes as PNG, SVG, or PDF for handoff or spec reference |

---

## Standard Workflow

### 1. Start Every Design Session

```
1. mcp__pencil__get_editor_state    → confirm what document is open; note current page/frame
2. mcp__pencil__get_style_guide     → load colours, typography, spacing system
3. mcp__pencil__get_variables       → load all design tokens for consistent application
```

Never hardcode colour values, font sizes, or spacing — always read them from `get_variables` / `get_style_guide` first.

### 2. Explore an Existing Design

```
1. mcp__pencil__snapshot_layout           → full layout map — all frames and layer hierarchy
2. mcp__pencil__batch_get                 → inspect specific nodes in bulk
3. mcp__pencil__get_screenshot            → visual confirmation of current canvas state
4. mcp__pencil__search_all_unique_properties → audit consistent use of design tokens
```

### 3. Create New Screens / Wireframes

```
1. mcp__pencil__find_empty_space_on_canvas → pick a safe drop zone on canvas
2. mcp__pencil__batch_design               → create frame + all child layers in one call
3. mcp__pencil__get_screenshot             → visually verify the result
4. mcp__pencil__snapshot_layout            → confirm hierarchy is correct
```

### 4. Update Design Tokens (e.g. Rebrand)

```
1. mcp__pencil__get_variables                   → read current token values
2. mcp__pencil__set_variables                   → update the token(s)
3. mcp__pencil__replace_all_matching_properties → propagate old → new value across all nodes
4. mcp__pencil__get_screenshot                  → verify the result visually
```

### 5. Engineering Handoff

```
1. mcp__pencil__snapshot_layout   → full layout spec document for engineers
2. mcp__pencil__export_nodes      → export frames as SVG/PNG to attach to PR
3. mcp__pencil__get_variables     → export token map for CSS/Tailwind mapping
4. mcp__pencil__get_screenshot    → attach visual to handoff doc in docs/ux/
```

---

## batch_design Usage Pattern

`mcp__pencil__batch_design` is the primary creation/modification tool. It accepts an array of design operations:

```json
[
  {
    "type": "create_frame",
    "name": "Login Screen",
    "properties": { "x": 0, "y": 0, "width": 375, "height": 812 }
  },
  {
    "type": "create_text",
    "name": "Heading",
    "parent": "Login Screen",
    "properties": {
      "content": "Sign in",
      "x": 24, "y": 80,
      "fontStyle": "var(--text-heading-xl)",
      "fill": "var(--color-text-primary)"
    }
  }
]
```

Always reference design token variables (e.g. `var(--color-primary)`) rather than raw hex values when tokens are available from `get_variables`.

---

## Fallback — No Pencil Connected

If `mcp__pencil__*` tools are not available:

1. **HTML/SVG wireframes** — write a single `.html` file with inline SVG frames saved to `docs/ux/wireframes/`
2. **Markdown specs** — use [`templates/screen-template.md`](../templates/screen-template.md) format
3. **Design token YAML** — output tokens as `docs/ux/design-tokens.yaml` for the FE engineer to consume

---

## Figma MCP (Alternative)

If the user has Figma MCP connected instead (`mcp__figma__*` tools available), read [`references/figma-mcp-integration.md`](figma-mcp-integration.md) for the Figma-specific workflow.
