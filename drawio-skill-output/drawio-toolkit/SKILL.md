---
name: drawio
description: >
  Full-featured draw.io diagram toolkit: create, edit, validate, convert, and export .drawio diagrams.
  Includes an MCP server (works with Claude Code, Cursor, Copilot, and any MCP-compatible AI tool),
  CLI scripts, and comprehensive XML generation guidance.
  Supports flowcharts, architecture diagrams, UML, ERD, org charts, mind maps, network diagrams,
  swimlane processes, sequence diagrams, and any other diagram type.
  Use this skill whenever the user mentions diagrams, draw.io, .drawio files, flowcharts,
  architecture diagrams, UML, ERD, org charts, mind maps, network topology, process flows, swimlanes,
  Mermaid-to-drawio conversion, PlantUML conversion, diagram validation, diagram export,
  or any request to visualize relationships, systems, or workflows — even if they don't explicitly say "draw.io".
  Also trigger when the user asks to convert code, data, CSV, or text descriptions into visual diagrams.
---

# draw.io Diagram Toolkit

A complete toolkit for creating and manipulating draw.io diagrams. This skill includes three layers — use whichever fits the task:

1. **MCP Server** (`mcp-server/`) — Structured tools for AI coders. Any MCP-compatible tool (Claude Code, Cursor, Copilot) can call `create_diagram`, `add_node`, `import_mermaid`, etc.
2. **CLI Scripts** (`scripts/`) — Standalone command-line tools for validation, conversion, layout, merging, and CSV-to-diagram generation.
3. **XML Generation Guidance** (this file + `references/xml-format.md`) — When you need to write raw .drawio XML directly (for maximum control or when MCP isn't available).

## Choosing Your Approach

| Situation                                       | Use                                                        |
| ----------------------------------------------- | ---------------------------------------------------------- |
| MCP server is connected                         | Use the MCP tools — they handle XML for you                |
| Building programmatically (scripts, automation) | Use CLI scripts via bash                                   |
| Need full control or custom layouts             | Write XML directly using the reference guide               |
| Converting from Mermaid/PlantUML                | MCP `import_mermaid`/`import_plantuml` or CLI `convert.py` |
| Validating an existing diagram                  | MCP `validate_diagram` or CLI `validate.py`                |
| Re-laying out a messy diagram                   | MCP `auto_layout` or CLI `auto_layout.py`                  |
| Generating from CSV data                        | CLI `create_from_csv.py`                                   |
| Merging multiple diagrams                       | CLI `merge.py`                                             |

---

## MCP Server

### Setup

The MCP server lives in `mcp-server/`. To install:

```bash
cd mcp-server/
pip install -e .
```

Then configure your AI tool:

**Claude Code** — add to `.claude/settings.json`:

```json
{
  "mcpServers": {
    "drawio": {
      "command": "drawio-mcp-server"
    }
  }
}
```

**Cursor** — add to `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "drawio": {
      "command": "drawio-mcp-server"
    }
  }
}
```

### Available MCP Tools

| Tool               | Description                                                                               |
| ------------------ | ----------------------------------------------------------------------------------------- |
| `create_diagram`   | Create a new empty .drawio file                                                           |
| `add_node`         | Add a shape (rectangle, diamond, circle, cylinder, cloud, etc.) with friendly color names |
| `add_connection`   | Connect two shapes with labeled edges (orthogonal, straight, or curved)                   |
| `remove_element`   | Remove a shape or connector by ID                                                         |
| `update_element`   | Change label, style, position, or size of an element                                      |
| `list_elements`    | List all shapes and connectors with properties                                            |
| `read_diagram`     | Get a structured summary of a .drawio file                                                |
| `validate_diagram` | Check for issues (orphaned edges, overlaps, duplicate IDs, etc.)                          |
| `auto_layout`      | Auto-arrange elements (tree, grid, or left-to-right)                                      |
| `import_mermaid`   | Convert Mermaid syntax to .drawio                                                         |
| `import_plantuml`  | Convert PlantUML to .drawio                                                               |
| `export_svg`       | Export diagram to SVG                                                                     |
| `generate_diagram` | Generate a complete diagram from a natural language description                           |

### MCP Tool Examples

**Build a diagram step by step:**

1. `create_diagram(name="Auth Flow")` → returns path
2. `add_node(path, "start", "Start", 200, 30, shape="circle", color="green")`
3. `add_node(path, "login", "User Login", 170, 130, shape="rectangle", color="blue")`
4. `add_node(path, "check", "Valid?", 195, 250, shape="diamond", color="yellow")`
5. `add_connection(path, "e1", "start", "login")`
6. `add_connection(path, "e2", "login", "check")`

**Convert from Mermaid:**

```
import_mermaid("graph TD\n  A[Start] --> B{Valid?}\n  B -->|Yes| C[Process]\n  B -->|No| D[Error]", "flow.drawio")
```

---

## CLI Scripts

All scripts are in `scripts/` and run standalone with Python 3.10+ and lxml.

### validate.py — Diagram Validation

```bash
python scripts/validate.py diagram.drawio
```

Checks: valid XML, structural cells, unique IDs, edge references, overlapping shapes, well-formed styles. Outputs colored PASS/WARN/FAIL results.

### convert.py — Format Conversion

```bash
python scripts/convert.py input.mmd output.drawio      # Mermaid → draw.io
python scripts/convert.py input.puml output.drawio      # PlantUML → draw.io
python scripts/convert.py diagram.drawio output.svg     # draw.io → SVG
python scripts/convert.py diagram.drawio output.mmd     # draw.io → Mermaid
```

### auto_layout.py — Auto Layout

```bash
python scripts/auto_layout.py diagram.drawio --layout tree --spacing 80
python scripts/auto_layout.py diagram.drawio --layout grid --output clean.drawio
python scripts/auto_layout.py diagram.drawio --layout lr          # left-to-right
python scripts/auto_layout.py diagram.drawio --layout radial      # radial/circular
```

### merge.py — Merge Diagrams

```bash
python scripts/merge.py a.drawio b.drawio --output merged.drawio --as-pages
python scripts/merge.py a.drawio b.drawio --output merged.drawio --side-by-side
python scripts/merge.py a.drawio b.drawio --output merged.drawio --stack
```

### info.py — Diagram Info

```bash
python scripts/info.py diagram.drawio
```

Prints: page count, shape count, edge count, all labels, connections list, containers.

### create_from_csv.py — CSV to Diagram

```bash
python scripts/create_from_csv.py team.csv --output org.drawio --type orgchart
python scripts/create_from_csv.py flow.csv --output process.drawio --type flowchart
python scripts/create_from_csv.py schema.csv --output schema.drawio --type erd
python scripts/create_from_csv.py infra.csv --output network.drawio --type network
```

CSV formats per type:

- **orgchart**: `name,title,reports_to`
- **flowchart**: `step,type,next_step,label`
- **erd**: `entity,attribute,type,relationship_to,cardinality`
- **network**: `device,type,connects_to,label`

---

## Writing Raw XML

When you need maximum control (custom shapes, precise positioning, complex containers), write the XML directly.

### Quick Start

Read `references/xml-format.md` for the complete format reference. The essentials:

1. Every .drawio file has this skeleton:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net">
  <diagram name="Page-1" id="page1">
    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="850" pageHeight="1100">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <!-- your elements here -->
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

2. **Shapes** are `<mxCell vertex="1">` with `<mxGeometry x y width height>`
3. **Connectors** are `<mxCell edge="1" source="id" target="id">`
4. **Styles** are semicolon-separated: `rounded=1;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;`

### Layout Planning

Before writing XML, plan the layout:

- **Flowcharts**: Top-to-bottom, 60-80px vertical gap. Decisions branch left/right.
- **Architecture**: Layered (client → server → database). Group related services in containers.
- **Org charts**: Tree layout. Center each level. Even spacing between siblings.
- **Mind maps**: Central node, branches radiate outward.
- **ERD**: Entities spread across canvas, relationship diamonds between them.
- **Network**: Layered — internet/cloud at top, servers below, databases at bottom.

**Spacing rules:** 40px minimum between unconnected shapes, 60-100px between connected ones. Standard shapes: 120x60 rectangles, 80x80 diamonds, 80x60 ellipses.

### Color Palette

| Purpose          | Fill      | Stroke    |
| ---------------- | --------- | --------- |
| Primary / Blue   | `#DAE8FC` | `#6C8EBF` |
| Success / Green  | `#D5E8D4` | `#82B366` |
| Warning / Yellow | `#FFF2CC` | `#D6B656` |
| Danger / Red     | `#F8CECC` | `#B85450` |
| Purple           | `#E1D5E7` | `#9673A6` |
| Orange           | `#FFE6CC` | `#D79B00` |
| Neutral / Gray   | `#F5F5F5` | `#666666` |

### Validation Checklist

Before saving, verify:

- All IDs are unique
- All edge `source`/`target` reference valid cell IDs
- Child elements reference correct `parent`
- XML special chars are escaped (`&amp;`, `&lt;`, `&gt;`, `&#10;` for newlines)
- No shapes overlap (check x,y,width,height)
- File extension is `.drawio` (not `.xml`)

If the CLI tools are available, run `python scripts/validate.py <file>` for automated checking.

### Working with Existing Files

When modifying an existing .drawio:

1. Parse the XML and understand existing layout, styles, and IDs
2. Preserve existing positions and styles — make targeted changes
3. Follow the existing naming/style conventions for new elements
4. Ensure new IDs don't conflict

### Working with Data Sources

When converting structured data (CSV, JSON, code) to diagrams:

1. If the CLI tools are available, use `create_from_csv.py` for CSV data
2. Otherwise, parse the data, determine the best diagram type, auto-layout, and generate XML
3. Apply meaningful labels from data fields

## Output

Save `.drawio` files to the workspace folder. Include a brief text summary of what's in the diagram so the user knows what to expect when they open it.
