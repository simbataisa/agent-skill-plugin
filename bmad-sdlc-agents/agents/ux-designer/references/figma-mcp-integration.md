# Figma MCP Integration

> Load this reference when `mcp__figma__*` tools are available in your session. Figma MCP provides bidirectional design-to-code sync — read frames into code, or push UI back to Figma as editable layers.

---

## Detecting Figma MCP

```
If mcp__figma__* tools appear in your available tools → Figma MCP is connected. Use it.
If not → check for mcp__pencil__* (Pencil desktop), or fall back to HTML/SVG wireframes.
```

## Setup (User Action Required)

Figma MCP requires a personal access token. If not yet configured:

1. In Figma: **Help & Account → Account Settings → Personal Access Tokens → Generate token** (scope: File content — Read, Dev resources — Read/Write)
2. Add to Claude Code MCP config — see `mcp-configs/global/figma.json` in this repo for the server definition
3. Paste the Figma frame/file URL when invoking the agent

---

## Tool Reference (Figma MCP)

### Reading Design Data

| Tool | Purpose |
|---|---|
| `mcp__figma__get_figma_data` | Read all design data from a Figma file or frame URL — nodes, styles, components |
| `mcp__figma__download_figma_images` | Download images/assets referenced in a Figma frame |

> Figma's MCP server exposes these two primary tools. The heavy lifting is in `get_figma_data` — it returns the complete node tree, styles, variables, and layout data for any file URL or specific frame/node link.

---

## Standard Workflow

### 1. Design-to-Code (Figma Frame → Component)

```
1. Ask the user for the Figma frame URL (or node URL for a specific component)
2. mcp__figma__get_figma_data (url: <frame-url>)
   → Returns: node tree, fill/stroke styles, typography, layout constraints, component instances
3. Extract design tokens from the styles object
4. Generate React/TypeScript component from the node tree
5. mcp__figma__download_figma_images → fetch any image fills needed
```

Always read the `styles` and `variables` from `get_figma_data` before writing any CSS — use the exact values from Figma rather than approximating.

### 2. Inspect a Design System

```
1. mcp__figma__get_figma_data (url: <library-file-url>)
   → components: all published components with variant properties
   → styles: colour styles, text styles, effect styles
   → variables: all variable collections and modes (light/dark, etc.)
2. Map Figma variable names → CSS custom properties for the FE engineer
3. Document component API (props = variant properties)
```

### 3. New Design Work (Figma as Source of Truth)

When the user has an existing Figma file and wants new screens designed to match:

```
1. mcp__figma__get_figma_data (url: <existing-file-url>)
   → read existing patterns, component library, grid settings
2. Design new screens following extracted patterns
3. Output as: annotated markdown spec + HTML prototype
4. Include Figma component references by name so FE engineer knows which components to use
```

### 4. Audit Existing Implementation Against Figma

```
1. mcp__figma__get_figma_data (url: <design-frame-url>) → design intent
2. Read the existing FE component code (Read tool)
3. Compare: token values, spacing, typography, component hierarchy
4. Produce a deviation report in docs/ux/design-audit-sprint-N.md
```

---

## Output Conventions

When producing deliverables based on Figma data:

- Reference Figma component names exactly as they appear in the node tree (e.g. `Button/Primary/Large`)
- Map Figma variable names to CSS custom property equivalents (e.g. `color/brand/primary` → `--color-brand-primary`)
- Include the source Figma frame URL in every spec document for traceability
- Save exported images to `docs/ux/assets/` and reference them in specs

---

## Fallback — No Figma Connected

If Figma MCP is not available, ask the user to either:
- Share the Figma frame as an exported PNG/SVG (use `Read` tool to inspect)
- Describe the design intent verbally, then produce HTML/SVG wireframes using [`templates/screen-template.md`](../templates/screen-template.md)
