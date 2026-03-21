# draw.io Diagram Toolkit

A complete toolkit for creating, editing, validating, converting, and exporting draw.io diagrams. Works with **Claude Code**, **Claude Desktop**, **Cursor**, **GitHub Copilot**, **Windsurf**, and any other MCP-compatible AI coding tool.

## What's Inside

```
drawio-toolkit/
├── SKILL.md                    # Skill file (AI prompt guidance for diagram generation)
├── README.md                   # This file
├── mcp-server/                 # MCP server — structured tools for AI coders
│   ├── drawio_mcp_server/      # Python package
│   │   ├── server.py           # MCP tool definitions (13 tools)
│   │   ├── diagram_core.py     # Core diagram manipulation library
│   │   └── style_maps.py       # Shape, color, and connector style mappings
│   └── pyproject.toml          # Package config (pip-installable)
├── scripts/                    # CLI tools — standalone command-line utilities
│   ├── validate.py             # Validate .drawio files for errors
│   ├── convert.py              # Convert between Mermaid/PlantUML/draw.io/SVG
│   ├── auto_layout.py          # Auto-arrange diagram elements
│   ├── merge.py                # Merge multiple .drawio files
│   ├── info.py                 # Print diagram summary
│   └── create_from_csv.py      # Generate diagrams from CSV data
└── references/
    └── xml-format.md           # Complete draw.io XML format reference
```

---

## Installation

### Prerequisites

- Python 3.10+
- `lxml` library (for XML processing)
- `mcp` library (for MCP server only)

### Step 1: Install the MCP Server

```bash
# Clone or copy the drawio-toolkit folder to your machine, then:
cd drawio-toolkit/mcp-server
pip install -e .
```

This installs the `drawio-mcp-server` command and all dependencies (`mcp`, `lxml`).

### Step 2: Install CLI Script Dependencies

The CLI scripts only need `lxml`:

```bash
pip install lxml
```

### Step 3: Verify Installation

```bash
# Verify the MCP server entry point exists
which drawio-mcp-server

# Verify CLI scripts work
python drawio-toolkit/scripts/validate.py --help
python drawio-toolkit/scripts/info.py --help
```

---

## Connecting the MCP Server to Your AI Tool

### Claude Code

Add to your project-level config (`.claude/settings.json`) or global config (`~/.claude/settings.json`):

```json
{
  "mcpServers": {
    "drawio": {
      "command": "drawio-mcp-server"
    }
  }
}
```

If you installed with a virtual environment, use the full path:

```json
{
  "mcpServers": {
    "drawio": {
      "command": "/path/to/your/venv/bin/drawio-mcp-server"
    }
  }
}
```

Restart Claude Code after editing. Verify with `/mcp` — you should see `drawio` listed with 13 tools.

### Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "drawio": {
      "command": "drawio-mcp-server"
    }
  }
}
```

Or with a virtual environment (macOS example):

```json
{
  "mcpServers": {
    "drawio": {
      "command": "/path/to/your/venv/bin/drawio-mcp-server"
    }
  }
}
```

Or using `uv` to run without pre-installing:

```json
{
  "mcpServers": {
    "drawio": {
      "command": "uvx",
      "args": ["--from", "/path/to/drawio-toolkit/mcp-server", "drawio-mcp-server"]
    }
  }
}
```

Restart Claude Desktop after saving.

### Cursor

Add to `.cursor/mcp.json` in your project root:

```json
{
  "mcpServers": {
    "drawio": {
      "command": "drawio-mcp-server"
    }
  }
}
```

Or globally at `~/.cursor/mcp.json`.

### Windsurf (Codeium)

Add to `~/.codeium/windsurf/mcp_config.json`:

```json
{
  "mcpServers": {
    "drawio": {
      "command": "drawio-mcp-server"
    }
  }
}
```

### GitHub Copilot (VS Code)

Add to `.vscode/mcp.json` in your project root:

```json
{
  "servers": {
    "drawio": {
      "command": "drawio-mcp-server"
    }
  }
}
```

Or globally via VS Code settings (`settings.json`):

```json
{
  "mcp": {
    "servers": {
      "drawio": {
        "command": "drawio-mcp-server"
      }
    }
  }
}
```

### Cline (VS Code Extension)

Add to `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`:

```json
{
  "mcpServers": {
    "drawio": {
      "command": "drawio-mcp-server"
    }
  }
}
```

### Continue.dev

Add to `~/.continue/config.yaml`:

```yaml
mcpServers:
  - name: drawio
    command: drawio-mcp-server
```

### Any Other MCP-Compatible Tool

The server follows the standard MCP protocol over stdio. Configure it with:
- **Command:** `drawio-mcp-server`
- **Transport:** stdio (default)
- **Protocol:** MCP 1.0+

---

## MCP Tools Reference

Once connected, your AI tool can call these 13 tools:

### Diagram Lifecycle

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `create_diagram` | Create a new empty .drawio file | `name` |
| `read_diagram` | Get structured summary of a diagram | `diagram_path` |
| `validate_diagram` | Check for errors (orphaned edges, overlaps, etc.) | `diagram_path` |
| `export_svg` | Export to SVG format | `diagram_path`, `output_path` |

### Building Diagrams

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `add_node` | Add a shape | `diagram_path`, `node_id`, `label`, `x`, `y`, `shape`, `color` |
| `add_connection` | Connect two shapes | `diagram_path`, `connection_id`, `source`, `target`, `label`, `style` |
| `remove_element` | Remove a shape or connector | `diagram_path`, `element_id` |
| `update_element` | Change label, style, position, or size | `diagram_path`, `element_id`, `label`, `style`, `x`, `y` |
| `list_elements` | List all shapes and connectors | `diagram_path` |

### Conversion & Layout

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `import_mermaid` | Convert Mermaid syntax to .drawio | `mermaid_text`, `output_path` |
| `import_plantuml` | Convert PlantUML to .drawio | `plantuml_text`, `output_path` |
| `auto_layout` | Auto-arrange elements | `diagram_path`, `layout` (tree/grid/lr) |
| `generate_diagram` | Generate from natural language description | `description`, `output_path`, `diagram_type` |

### Available Shapes

`rectangle`, `rounded`, `diamond`, `circle`, `cylinder`, `cloud`, `parallelogram`, `hexagon`, `triangle`, `actor`, `component`, `database`, `folder`, `document`

### Available Colors

`blue`, `green`, `yellow`, `red`, `purple`, `orange`, `gray`, `pink`, `teal`, `light_blue`

### Available Edge Styles

`orthogonal` (right-angle, default), `straight`, `curved`, `dashed`, `bold`, `arrow`

### Example: Build a Flowchart Step by Step

```
You: "Create a flowchart for login"

AI calls: create_diagram(name="Login Flow")
AI calls: add_node(path, "start", "Start", 200, 30, shape="circle", color="green")
AI calls: add_node(path, "input", "Enter Credentials", 160, 120, shape="rectangle", color="blue")
AI calls: add_node(path, "check", "Valid?", 195, 230, shape="diamond", color="yellow")
AI calls: add_node(path, "success", "Dashboard", 160, 340, shape="rounded", color="green")
AI calls: add_node(path, "fail", "Show Error", 380, 230, shape="rectangle", color="red")
AI calls: add_connection(path, "e1", "start", "input")
AI calls: add_connection(path, "e2", "input", "check")
AI calls: add_connection(path, "e3", "check", "success", label="Yes")
AI calls: add_connection(path, "e4", "check", "fail", label="No")
AI calls: add_connection(path, "e5", "fail", "input", label="Retry")
```

### Example: Import from Mermaid

```
AI calls: import_mermaid(
  "graph TD\n  A[User] --> B{Auth}\n  B -->|Pass| C[Dashboard]\n  B -->|Fail| D[Error]",
  "auth.drawio"
)
```

---

## CLI Scripts Reference

All scripts are standalone and can be run directly from the command line.

### validate.py — Check Diagrams for Errors

```bash
python scripts/validate.py diagram.drawio
```

Checks for: invalid XML, missing structural cells, duplicate IDs, broken edge references, overlapping shapes, malformed styles. Outputs colored PASS/WARN/FAIL results.

### convert.py — Format Conversion

```bash
# Mermaid → draw.io
python scripts/convert.py flow.mmd output.drawio

# PlantUML → draw.io
python scripts/convert.py system.puml output.drawio

# draw.io → SVG
python scripts/convert.py diagram.drawio output.svg

# draw.io → Mermaid (reverse)
python scripts/convert.py diagram.drawio output.mmd
```

Supported Mermaid syntax: `graph TD/LR/BT/RL`, node shapes `A[text]`/`A(text)`/`A{text}`/`A((text))`, edges `-->`, `---`, `-.->`, `==>` with `|labels|`, and `subgraph`.

### auto_layout.py — Rearrange Diagrams

```bash
python scripts/auto_layout.py messy.drawio --layout tree          # top-to-bottom tree
python scripts/auto_layout.py messy.drawio --layout grid          # grid arrangement
python scripts/auto_layout.py messy.drawio --layout lr             # left-to-right
python scripts/auto_layout.py messy.drawio --layout radial         # radial/circular
python scripts/auto_layout.py messy.drawio --layout tree --spacing 100 --output clean.drawio
```

### merge.py — Combine Diagrams

```bash
python scripts/merge.py a.drawio b.drawio --output merged.drawio --as-pages      # separate tabs
python scripts/merge.py a.drawio b.drawio --output merged.drawio --side-by-side   # one page, horizontal
python scripts/merge.py a.drawio b.drawio --output merged.drawio --stack          # one page, vertical
```

### info.py — Inspect Diagrams

```bash
python scripts/info.py diagram.drawio
```

Outputs: page count, shape count, edge count, all shape labels, connections list (source → target), containers/groups.

### create_from_csv.py — Generate from CSV

```bash
python scripts/create_from_csv.py team.csv --output org.drawio --type orgchart
python scripts/create_from_csv.py steps.csv --output process.drawio --type flowchart
python scripts/create_from_csv.py schema.csv --output db.drawio --type erd
python scripts/create_from_csv.py infra.csv --output network.drawio --type network
```

**CSV formats:**

Org chart (`name,title,reports_to`):
```csv
name,title,reports_to
Sarah,CEO,
Mike,CTO,Sarah
Lisa,CFO,Sarah
Bob,VP Engineering,Mike
```

Flowchart (`step,type,next_step,label`):
```csv
step,type,next_step,label
Start,start,Get Input,
Get Input,process,Validate,
Validate,decision,Process,Yes
Validate,decision,Show Error,No
```

ERD (`entity,attribute,type,relationship_to,cardinality`):
```csv
entity,attribute,type,relationship_to,cardinality
Customer,id,PK,,
Customer,name,VARCHAR,,
Customer,,FK,Order,1:N
Order,id,PK,,
```

Network (`device,type,connects_to,label`):
```csv
device,type,connects_to,label
Internet,cloud,Firewall,HTTPS
Firewall,rectangle,Web Server,Port 443
Web Server,rectangle,Database,SQL
Database,cylinder,,
```

---

## Using the SKILL.md (for AI Prompt Guidance)

The `SKILL.md` file provides comprehensive instructions for AI tools that support skill/prompt files (like Claude Code's custom instructions). It teaches the AI how to generate well-structured draw.io XML from scratch when MCP tools aren't available.

To use it, place the `drawio-toolkit` folder where your AI tool can read it, or copy the `SKILL.md` into your project's custom instructions.

---

## Opening .drawio Files

Generated `.drawio` files can be opened in:

- **draw.io Desktop App** — [download at drawio.com](https://www.drawio.com/)
- **draw.io Web** — open [app.diagrams.net](https://app.diagrams.net) and drag-drop or File → Open
- **VS Code** — install the [Draw.io Integration](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio) extension
- **IntelliJ / JetBrains** — install the [Diagrams.net Integration](https://plugins.jetbrains.com/plugin/15635-diagrams-net-integration) plugin

---

## Troubleshooting

### MCP server not showing up in Claude Code

1. Check the config file path is correct for your OS
2. Verify `drawio-mcp-server` is on your PATH: `which drawio-mcp-server`
3. If using a virtual environment, use the full path to the executable
4. Restart Claude Code / Claude Desktop after editing config
5. In Claude Code, run `/mcp` to see connected servers

### "Module not found" errors

Make sure you installed from the `mcp-server/` directory:
```bash
cd drawio-toolkit/mcp-server
pip install -e .
```

### CLI scripts fail with "No module named lxml"

```bash
pip install lxml
```

### Generated diagrams look empty in draw.io

The file may have valid XML but elements positioned off-screen. Try `Edit → Fit Page` in draw.io, or run:
```bash
python scripts/auto_layout.py diagram.drawio --layout grid
```

---

## License

MIT
