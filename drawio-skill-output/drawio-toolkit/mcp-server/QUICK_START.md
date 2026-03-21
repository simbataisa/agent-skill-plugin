# Quick Start Guide - Draw.io MCP Server

Get started with the draw.io MCP server in 5 minutes.

## 1. Installation

```bash
cd /path/to/drawio-mcp-server
pip install -e .
```

Verify installation:
```bash
python -c "from drawio_mcp_server import diagram_core; print('✓ Installation successful')"
```

## 2. Basic Python Usage

```python
from drawio_mcp_server.diagram_core import (
    create_empty_diagram,
    add_vertex,
    add_edge,
    to_xml,
)
from pathlib import Path

# Create a new diagram
diagram = create_empty_diagram("My Diagram")

# Add shapes
add_vertex(diagram, "node1", "Start", 0, 0, shape="circle", color="green")
add_vertex(diagram, "node2", "Process", 200, 0, shape="rectangle", color="blue")
add_vertex(diagram, "node3", "End", 400, 0, shape="circle", color="red")

# Add connectors
add_edge(diagram, "edge1", "node1", "node2", "go")
add_edge(diagram, "edge2", "node2", "node3", "done")

# Save
xml = to_xml(diagram)
Path("mydiagram.drawio").write_text(xml)
```

## 3. MCP Server Configuration

### For Claude Code

Edit `.claude/settings.json`:
```json
{
  "mcpServers": {
    "drawio": {
      "command": "drawio-mcp-server"
    }
  }
}
```

### For Cursor

Edit `.cursor/mcp.json`:
```json
{
  "mcpServers": {
    "drawio": {
      "command": "drawio-mcp-server"
    }
  }
}
```

## 4. Use in Claude Code

Once configured, you can ask Claude:

> "Create a diagram showing a user connecting to an API which connects to a database. Save it as architecture.drawio"

Claude will use the MCP tools to:
1. Create the diagram
2. Add nodes (User, API, Database)
3. Add connections
4. Save the file

## 5. Common Tasks

### Import Mermaid Diagram

```python
from drawio_mcp_server.diagram_core import mermaid_to_drawio, to_xml
from pathlib import Path

mermaid = """
graph TD
  A[Input] --> B{Check}
  B -->|Yes| C[Process]
  B -->|No| D[Skip]
"""

diagram = mermaid_to_drawio(mermaid)
Path("diagram.drawio").write_text(to_xml(diagram))
```

### Import PlantUML Diagram

```python
from drawio_mcp_server.diagram_core import plantuml_to_drawio, to_xml
from pathlib import Path

plantuml = """
@startuml
[Component A] --> (User)
[Component B] --> database "PostgreSQL"
@enduml
"""

diagram = plantuml_to_drawio(plantuml)
Path("diagram.drawio").write_text(to_xml(diagram))
```

### Auto-Layout a Diagram

```python
from drawio_mcp_server.diagram_core import parse_diagram, auto_layout, to_xml
from pathlib import Path

diagram = parse_diagram("mydiagram.drawio")
auto_layout(diagram, layout_type="tree")  # or "grid" or "lr"
Path("mydiagram.drawio").write_text(to_xml(diagram))
```

### Validate a Diagram

```python
from drawio_mcp_server.diagram_core import parse_diagram, validate_diagram

diagram = parse_diagram("mydiagram.drawio")
issues = validate_diagram(diagram)
if issues:
    for issue in issues:
        print(f"Issue: {issue}")
else:
    print("Diagram is valid")
```

## 6. Available Shapes

- rectangle
- rounded
- diamond
- circle
- cylinder (database)
- cloud
- parallelogram
- hexagon
- triangle
- actor
- component
- folder
- document
- image

## 7. Available Colors

- blue
- green
- yellow
- red
- purple
- orange
- gray
- pink
- teal
- light_blue

## 8. Connection Styles

- orthogonal (right angles)
- straight (direct line)
- curved (smooth curve)
- dashed (dashed line)
- bold (thick line)
- arrow (with arrow)

## 9. Run Examples

```bash
python example_usage.py
```

This generates several example diagrams:
- example_architecture.drawio
- example_mermaid.drawio
- example_plantuml.drawio
- example_gallery.drawio

Open them in draw.io or Diagrams.net to view.

## 10. Next Steps

- Read the full [README.md](README.md) for complete documentation
- Check [example_usage.py](example_usage.py) for more examples
- Use with your AI tool of choice (Claude, Cursor, Copilot, etc.)

## Troubleshooting

### Import Error: "No module named 'mcp'"
Install MCP:
```bash
pip install mcp
```

### Import Error: "No module named 'lxml'"
Install lxml:
```bash
pip install lxml
```

### File Not Found Errors
Use absolute paths:
```python
from pathlib import Path
filepath = Path.home() / "Documents" / "diagram.drawio"
```

### Diagram Not Opening
Ensure the .drawio file has valid XML:
```bash
python -c "from drawio_mcp_server.diagram_core import parse_diagram; parse_diagram('file.drawio')"
```

## Support

For more help, see the README.md file or check the inline documentation in the source code.
