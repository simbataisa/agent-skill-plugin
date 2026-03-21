# Draw.io MCP Server - Architecture Documentation

## Overview

The draw.io MCP Server is a production-quality Model Context Protocol server that enables AI tools (Claude, Cursor, Copilot, etc.) to create, manipulate, and analyze draw.io diagrams programmatically.

## Project Structure

```
drawio-mcp-server/
├── pyproject.toml                 # Python project configuration
├── README.md                       # Complete documentation
├── QUICK_START.md                  # Getting started guide
├── ARCHITECTURE.md                 # This file
├── example_usage.py               # Usage examples and demonstrations
├── test_diagram_core.py            # Comprehensive unit tests
├── drawio_mcp_server/
│   ├── __init__.py                # Package initialization
│   ├── server.py                  # MCP server and tool definitions
│   ├── diagram_core.py            # Core diagram manipulation logic
│   └── style_maps.py              # Style constants and configurations
```

## Core Components

### 1. `diagram_core.py` - Core Diagram Library

**Purpose**: Provides the fundamental XML manipulation and diagram logic.

**Key Classes**:
- `Diagram`: Wrapper class for lxml XML tree representing a draw.io file

**Key Functions**:

#### Diagram Lifecycle
- `create_empty_diagram(name)` → Diagram: Creates new diagram with valid structure
- `parse_diagram(xml_source)` → Diagram: Parses existing diagram from XML string or file
- `to_xml(diagram)` → str: Serializes diagram back to XML string

#### Element Operations
- `add_vertex(diagram, id, value, x, y, width, height, shape, color, parent)` → mxCell
  - Adds a shape node to the diagram
  - Validates shape type and color
  - Prevents duplicate IDs

- `add_edge(diagram, id, source, target, value, style, parent)` → mxCell
  - Adds a connector between two nodes
  - Validates source and target exist
  - Supports multiple connector styles

- `remove_element(diagram, element_id)` → bool
  - Removes a cell and its orphaned edges
  - Returns success status

- `update_element(diagram, element_id, label, style, x, y, width, height)` → bool
  - Updates element properties in-place
  - Partial updates supported

#### Query Operations
- `list_elements(diagram)` → List[Dict]: Returns all elements with properties
- `get_element(diagram, element_id)` → Dict: Returns single element details
- `validate_diagram(diagram)` → List[str]: Reports structural issues

#### Layout Operations
- `auto_layout(diagram, layout_type)` → None
  - "tree": Hierarchical BFS layout
  - "grid": Grid arrangement
  - "lr": Left-to-right tree layout

#### Format Conversion
- `mermaid_to_drawio(mermaid_text)` → Diagram
  - Parses Mermaid syntax with regex
  - Supports graph TD/LR directions
  - Handles multiple shape types and labels

- `plantuml_to_drawio(plantuml_text)` → Diagram
  - Parses PlantUML component/actor/database syntax
  - Extracts connections with labels

### 2. `server.py` - MCP Server Implementation

**Purpose**: Implements the Model Context Protocol server and exposes tools.

**Framework**: `mcp.server.fastmcp.FastMCP`

**Tools Exposed** (all with comprehensive error handling):

1. `create_diagram(name)` → Creates new diagram file
2. `add_node(diagram_path, node_id, label, x, y, width, height, shape, color, parent)` → Adds shape
3. `add_connection(diagram_path, connection_id, source, target, label, style, parent)` → Adds connector
4. `remove_element(diagram_path, element_id)` → Removes element
5. `update_element(diagram_path, element_id, label, style, x, y, width, height)` → Updates element
6. `list_elements(diagram_path)` → Lists all elements
7. `read_diagram(diagram_path)` → Summary of diagram
8. `validate_diagram(diagram_path)` → Validation report
9. `auto_layout(diagram_path, layout)` → Auto-arrange elements
10. `import_mermaid(mermaid_text, output_path)` → Convert Mermaid to .drawio
11. `import_plantuml(plantuml_text, output_path)` → Convert PlantUML to .drawio
12. `export_svg(diagram_path, output_path)` → Export to SVG
13. `generate_diagram(description, output_path, diagram_type)` → NLP-based generation

**Transport**: stdio (standard MCP transport)

**Tool Response Format**: All tools return dictionaries with:
- `success` (boolean): Whether operation succeeded
- Tool-specific data on success
- `error` (string) on failure with detailed message

### 3. `style_maps.py` - Configuration Constants

**Contents**:

```python
SHAPE_STYLES          # Map of shape names to draw.io styles
COLOR_PALETTE         # Professional color schemes with fill/stroke
EDGE_STYLES           # Connector style mappings
FONT_STYLES           # Typography options
DEFAULT_VERTEX_STYLE  # Base vertex style string
DEFAULT_EDGE_STYLE    # Base edge style string
GRID_CELL_WIDTH/HEIGHT  # Grid layout dimensions
TREE_LEVEL_HEIGHT     # Hierarchical layout spacing
TREE_NODE_SPACING     # Node separation in tree layout
```

## Data Flow

### Creating a Diagram Through MCP

```
AI Request
    ↓
MCP Server (server.py)
    ↓
Tool Function (create_diagram)
    ↓
diagram_core.create_empty_diagram()
    ↓
Diagram Object (XML wrapped)
    ↓
to_xml() / File Save
    ↓
Response to AI
```

### Manipulating Existing Diagram

```
AI Request
    ↓
MCP Server (server.py)
    ↓
_ensure_drawio_path() [validate path]
    ↓
parse_diagram(filepath) [load XML]
    ↓
Diagram Object
    ↓
diagram_core.add_vertex/add_edge/etc.
    ↓
_save_diagram() [write XML back]
    ↓
Response to AI
```

## XML Structure

The server works with standard draw.io XML format:

```xml
<mxfile host="Claude MCP Server" version="24.1.0">
  <diagram name="Page-1">
    <mxGraphModel dx="1200" dy="750" ...>
      <root>
        <mxCell id="0"/>  <!-- Root cell -->
        <mxCell id="1" parent="0"/>  <!-- Default parent -->

        <!-- User shapes -->
        <mxCell id="node1" value="Label" style="..." vertex="1" parent="1">
          <mxGeometry x="0" y="0" width="120" height="60" as="geometry"/>
        </mxCell>

        <!-- Connectors -->
        <mxCell id="edge1" value="" style="..." edge="1" parent="1" source="node1" target="node2">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

## Style System

### Shape Styling

Shapes are styled using draw.io's style string format:
```
rounded=0;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;
```

### Color Palette

Professional draw.io color scheme:
- 8 primary colors (blue, green, yellow, red, purple, orange, gray, pink)
- 2 additional tones (teal, light_blue)
- Each color has fill and stroke values

### Edge Styling

Connectors support multiple visual styles:
- orthogonal: Manhattan routing
- straight: Direct line
- curved: Smooth Bézier curve
- dashed: Dashed line
- bold: Thicker stroke
- arrow: With arrowhead

## Layout Algorithms

### Tree Layout
- BFS traversal from root nodes
- Root nodes identified as those without incoming edges
- Children positioned in levels below parents
- Horizontal spacing maintained

### Grid Layout
- Arranges elements in rectangular grid
- Columns determined by sqrt(element_count)
- Uniform cell sizing

### Left-to-Right Layout
- Variation of tree layout
- Positions elements horizontally instead of vertically
- Useful for timelines and horizontal flows

## Error Handling

All operations include comprehensive error handling:

1. **File Operations**
   - File not found → descriptive error
   - Invalid XML → parsing error with details
   - Permission issues → clear messages

2. **Validation**
   - Duplicate IDs → prevented at insertion
   - Missing references → detected in validation
   - Structural errors → reported with context

3. **Type Safety**
   - Unknown shape types → enumerated options in error
   - Unknown colors → available palette listed
   - Unknown styles → valid options provided

## Testing

`test_diagram_core.py` provides comprehensive test coverage:

- **Diagram Creation**: Empty diagram creation with correct structure
- **Vertex Operations**: Adding, updating, removing vertices
- **Edge Operations**: Adding, updating edges with validation
- **Serialization**: XML conversion and parsing
- **Validation**: Structural checks and issue detection
- **Layout**: All layout algorithms
- **Format Conversion**: Mermaid and PlantUML import
- **Query Operations**: Element listing and retrieval

Tests are organized in classes by functionality and follow pytest conventions.

## Performance Characteristics

- **Diagram Creation**: O(1) - template-based
- **Add Element**: O(1) - direct XML insertion
- **List Elements**: O(n) - must traverse all cells
- **Remove Element**: O(n) - must find element and cleanup edges
- **Auto-Layout**: O(n) - traverses all elements once
- **Validation**: O(n²) worst case - checks all edge references

For typical diagrams (<500 elements), all operations complete in milliseconds.

## Integration Points

### Claude Code / Cursor Integration

The server integrates with Claude Code through `.claude/settings.json`:
```json
{
  "mcpServers": {
    "drawio": {"command": "drawio-mcp-server"}
  }
}
```

Users then request: "Create a diagram showing X" and Claude uses the tools.

### Copilot Integration

Similar configuration in Copilot's MCP settings (once published).

### Custom Tools

The server can be used directly in any MCP-compatible tool by running:
```bash
drawio-mcp-server
```

## Security Considerations

1. **File Path Validation**
   - Uses `pathlib.Path` for safe path handling
   - Prevents directory traversal via absolute path conversion
   - Creates parent directories as needed

2. **XML Validation**
   - Uses lxml for secure XML parsing
   - Validates structure before modifications
   - Detects malformed input early

3. **Tool Sandboxing**
   - Tools only operate on explicitly specified files
   - No global state or environment access
   - Each operation is isolated

## Future Enhancements

Possible improvements:
- Advanced SVG export with style preservation
- Graph analysis and statistics
- Diagram diffing and merging
- Template library
- Python-to-draw.io code generation
- Collaborative editing support

## Dependencies

- **mcp** (>=1.0.0): Model Context Protocol library
- **lxml** (>=4.9.0): XML parsing and manipulation
- **Python** (>=3.8): Core language

No other external dependencies required.

## Files and Locations

All files are located in `/sessions/brave-fervent-turing/drawio-skill/drawio/mcp-server/`

Key paths:
- Server entry point: `drawio_mcp_server/server.py:main()`
- Core logic: `drawio_mcp_server/diagram_core.py`
- Configuration: `drawio_mcp_server/style_maps.py`
- Tests: `test_diagram_core.py`
- Examples: `example_usage.py`

## Maintenance

The codebase follows best practices:
- Type hints throughout
- Comprehensive docstrings
- Error handling with descriptive messages
- Clean separation of concerns
- Well-organized constants
- Extensive test coverage
