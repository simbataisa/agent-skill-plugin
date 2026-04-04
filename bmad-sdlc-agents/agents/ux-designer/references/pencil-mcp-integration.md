# Pencil MCP Integration

> This reference is loaded from `ux-designer/SKILL.md` when Pencil MCP tools are available in the session.

[Pencil.dev](https://pencil.dev) is an AI-native infinite design canvas with an MCP server. When Pencil MCP tools are available in your session, **always prefer them** over generating static markdown wireframes — they produce pixel-accurate, vector designs with real design tokens that Claude Code can read directly when generating frontend code.

### Detecting Pencil MCP

At the start of any design task, check whether Pencil MCP tools are available:

```
If mcp__pencil__* tools are listed in your available tools → Pencil is connected. Use it.
If not → fall back to HTML/SVG wireframes or markdown specs.
```

### When Pencil Is Connected — Workflow

#### 1. Open / Create a Design File
```
mcp__pencil__open_file       # Open an existing .pen file
mcp__pencil__create_file     # Create a new design file
mcp__pencil__list_pages      # List all pages/frames in the file
```

#### 2. Read Existing Designs (Design-to-Code Context)
Before generating any component code, read the design:
```
mcp__pencil__get_frame           # Read a specific frame/screen
mcp__pencil__get_components      # List all components in the design
mcp__pencil__get_design_tokens   # Extract all colour, typography, spacing tokens
mcp__pencil__get_layer           # Inspect a specific layer's properties
mcp__pencil__export_frame        # Export a frame as SVG/PNG for reference
```

Always extract design tokens via `mcp__pencil__get_design_tokens` **before** writing any CSS or component code. This ensures your colour, spacing, and typography values are pixel-accurate, not guessed.

#### 3. Create / Modify Designs
```
mcp__pencil__create_frame        # Create a new screen/wireframe frame
mcp__pencil__create_component    # Add a reusable component to the canvas
mcp__pencil__update_layer        # Modify an existing layer's properties
mcp__pencil__apply_token         # Apply a design token to a layer
mcp__pencil__set_layout          # Set auto-layout / flexbox constraints
mcp__pencil__add_text            # Add text with font spec
mcp__pencil__add_shape           # Add rectangle, circle, or path
mcp__pencil__add_icon            # Insert icon from connected icon set
```

#### 4. Annotate for Engineering Handoff
```
mcp__pencil__add_annotation      # Add a developer note to a layer
mcp__pencil__set_spacing_spec    # Document padding/margin specs
mcp__pencil__mark_handoff_ready  # Flag a frame as ready for dev
```

#### 5. Generate Code from Design
After completing designs, trigger code generation:
```
mcp__pencil__generate_component  # Generate React/TypeScript from a frame
mcp__pencil__generate_css        # Generate CSS/Tailwind from tokens
mcp__pencil__generate_tokens_file # Export tokens as tokens.ts / tokens.css
```

### Pencil Design Workflow — Step by Step

```
1. mcp__pencil__open_file (.pen) or create_file
2. Run Design Preferences Elicitation (if not done yet)
3. Apply confirmed design tokens to canvas:
   - mcp__pencil__apply_token → colours (background, primary, accent, etc.)
   - mcp__pencil__apply_token → typography (font-sans, font-heading, base-size)
   - mcp__pencil__apply_token → border-radius, spacing-density
   - mcp__pencil__set_design_system → link canvas to shadcn token set
4. For each screen in the user flow:
   a. mcp__pencil__create_frame (name: screen ID from UI spec)
   b. Build layout using shadcn-mapped components via create_component
      (Button, Card, Table, Sheet, Dialog, Badge, etc.)
   c. Apply tokens with apply_token (never hardcode hex/px values)
   d. Add states as separate frames: default, loading, error, empty, success
   e. add_annotation for complex interactions (e.g., "Sheet slides from right")
   f. mark_handoff_ready when screen is complete
5. mcp__pencil__generate_tokens_file → tokens.ts  (save to docs/ux/tokens/)
6. For each component: generate_component → save to docs/ux/components/
7. export_frame (SVG) for each screen → save to docs/ux/wireframes/
```

### Fallback: No Pencil MCP

If Pencil MCP is not available, produce designs as:
- **Token files**: `tailwind.config.ts` + `globals.css` from Design Preferences → `docs/ux/tokens/`
- **Wireframes**: Interactive React `.tsx` files using shadcn/ui + Tailwind → `docs/ux/wireframes/`
- **UI Specs**: Fill in `templates/ui-spec-template.md` → `docs/ux/specs/`
- **Component Specs**: Markdown tables listing shadcn component + variant + props for each screen element

### Connecting Pencil MCP (for README / setup instructions)

Add to your project's MCP configuration (`.claude/mcp.json` or `claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "pencil": {
      "command": "/Applications/Pencil.app/Contents/Resources/app.asar.unpacked/out/mcp-server-darwin-arm64",
      "args": [
        "--app",
        "desktop"
      ],
      "env": {}
    }
  }
}
```

This uses the Pencil desktop app's bundled MCP server binary directly. Make sure Pencil.app is installed at `/Applications/Pencil.app` before adding this config. Once added, restart Claude Code and the `mcp__pencil__*` tools will be available in your sessions.

---

