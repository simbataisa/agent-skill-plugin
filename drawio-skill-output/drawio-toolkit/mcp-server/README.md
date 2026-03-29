# Draw.io MCP Server

A complete Model Context Protocol (MCP) server for draw.io diagram operations. Works seamlessly with Claude Code, Cursor, Copilot, and any MCP-compatible AI tool.

## Features

- **Create & Manage Diagrams**: Create new diagrams, add shapes and connectors
- **Diagram Manipulation**: Add/remove/update elements with full control over positioning and styling
- **Auto-Layout**: Arrange diagram elements automatically using tree, grid, or left-to-right layouts
- **Format Conversion**: Import from Mermaid and PlantUML syntax
- **Validation**: Check diagrams for structural issues and orphaned elements
- **Export**: Convert diagrams to SVG format
- **Smart Generation**: Create diagrams from natural language descriptions

## Installation

### Prerequisites

- Python 3.8 or higher
- pip or uv

### Install via pip

```bash
pip install -e .
```

### Install via uv (faster)

```bash
uv pip install -e .
```

### Verify Installation

```bash
drawio-mcp-server --help
```

## Configuration

### Claude Code

Add the following to `.claude/settings.json`:

```json
{
  "mcpServers": {
    "drawio": {
      "command": "drawio-mcp-server"
    }
  }
}
```

### Cursor

Add the following to `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "drawio": {
      "command": "drawio-mcp-server"
    }
  }
}
```

### VS Code with Continue Extension

Add the following to `.continue/config.json`:

```json
{
  "mcpServers": {
    "drawio": {
      "command": "drawio-mcp-server"
    }
  }
}
```

### Generic MCP Clients

The server can be integrated with any MCP-compatible tool using the stdio transport:

```bash
drawio-mcp-server
```

## Available Tools

### `create_diagram`

Create an in-memory empty .drawio diagram preview.

This tool does not write a file. Use it to preview the XML structure and cell count before creating or modifying on-disk diagrams with the other tools.

**Parameters:**
- `name` (string, optional): Name of the diagram (default: "Untitled")

**Returns:**
- `success` (boolean): Whether the operation succeeded
- `name` (string): The diagram name
- `xml_preview` (string): Preview of the XML structure
- `cell_count` (integer): Number of cells in the diagram

**Example:**
```
create_diagram(name="System Architecture")
```

### `add_node`

Add a shape (node) to a diagram.

**Parameters:**
- `diagram_path` (string): Path to .drawio file
- `node_id` (string): Unique identifier for the node
- `label` (string): Text label for the shape
- `x` (integer, optional): X coordinate (default: 0)
- `y` (integer, optional): Y coordinate (default: 0)
- `width` (integer, optional): Width of shape (default: 120)
- `height` (integer, optional): Height of shape (default: 60)
- `shape` (string, optional): Shape type (default: "rectangle")
  - Options: rectangle, rounded, diamond, circle, cylinder, cloud, parallelogram, hexagon, triangle, actor, component, database, folder, document, image
- `color` (string, optional): Color (default: "blue")
  - Options: blue, green, yellow, red, purple, orange, gray, pink, teal, light_blue
- `parent` (string, optional): Parent cell id (default: "1")

**Returns:**
- `success` (boolean): Whether the operation succeeded
- `node_id` (string): The node ID
- `label` (string): The node label
- `shape` (string): The shape type used
- `color` (string): The color used
- `position` (object): X and Y coordinates
- `size` (object): Width and height

**Example:**
```
add_node(diagram_path="app.drawio", node_id="user1", label="User", shape="actor", color="green", x=50, y=50)
```

### `add_connection`

Add a connector between two shapes.

**Parameters:**
- `diagram_path` (string): Path to .drawio file
- `connection_id` (string): Unique identifier for the connection
- `source` (string): Source node id
- `target` (string): Target node id
- `label` (string, optional): Label text for the connection (default: empty)
- `style` (string, optional): Connection style (default: "orthogonal")
  - Options: orthogonal, straight, curved, dashed, bold, arrow
- `parent` (string, optional): Parent cell id (default: "1")

**Returns:**
- `success` (boolean): Whether the operation succeeded
- `connection_id` (string): The connection ID
- `source` (string): Source node ID
- `target` (string): Target node ID
- `label` (string): The connection label
- `style` (string): The style applied

**Example:**
```
add_connection(diagram_path="app.drawio", connection_id="conn1", source="user1", target="api1", label="calls", style="curved")
```

### `remove_element`

Remove a shape or connector from a diagram.

**Parameters:**
- `diagram_path` (string): Path to .drawio file
- `element_id` (string): ID of the element to remove

**Returns:**
- `success` (boolean): Whether the operation succeeded
- `removed_id` (string): The ID of the removed element

**Example:**
```
remove_element(diagram_path="app.drawio", element_id="node1")
```

### `update_element`

Update properties of an element in a diagram.

**Parameters:**
- `diagram_path` (string): Path to .drawio file
- `element_id` (string): ID of the element to update
- `label` (string, optional): New label text
- `style` (string, optional): New style string
- `x` (integer, optional): New X coordinate
- `y` (integer, optional): New Y coordinate
- `width` (integer, optional): New width
- `height` (integer, optional): New height

**Returns:**
- `success` (boolean): Whether the operation succeeded
- `updated_id` (string): The element ID
- `changes` (object): Summary of changes made

**Example:**
```
update_element(diagram_path="app.drawio", element_id="node1", label="Updated Label", x=100, y=100)
```

### `list_elements`

List all shapes and connectors in a diagram.

**Parameters:**
- `diagram_path` (string): Path to .drawio file

**Returns:**
- `success` (boolean): Whether the operation succeeded
- `diagram_path` (string): The file path
- `element_count` (integer): Total number of elements
- `elements` (array): List of element objects with properties

**Example:**
```
list_elements(diagram_path="app.drawio")
```

### `read_diagram`

Read and return a structured summary of a .drawio file.

**Parameters:**
- `diagram_path` (string): Path to .drawio file

**Returns:**
- `success` (boolean): Whether the operation succeeded
- `diagram_path` (string): The file path
- `file_size_bytes` (integer): Size of the file
- `total_elements` (integer): Total number of elements
- `vertices` (integer): Number of shapes
- `edges` (integer): Number of connectors
- `elements_summary` (array): Detailed element information

**Example:**
```
read_diagram(diagram_path="app.drawio")
```

### `validate_diagram`

Validate a diagram and report issues.

**Parameters:**
- `diagram_path` (string): Path to .drawio file

**Returns:**
- `success` (boolean): Whether the operation succeeded
- `diagram_path` (string): The file path
- `is_valid` (boolean): Whether the diagram is valid
- `issue_count` (integer): Number of issues found
- `issues` (array): List of issues (e.g., missing cells, duplicate IDs, orphaned edges)

**Example:**
```
validate_diagram(diagram_path="app.drawio")
```

### `auto_layout`

Auto-arrange elements in a diagram.

**Parameters:**
- `diagram_path` (string): Path to .drawio file
- `layout` (string, optional): Layout algorithm (default: "tree")
  - Options: tree, grid, lr (left-to-right)

**Returns:**
- `success` (boolean): Whether the operation succeeded
- `diagram_path` (string): The file path
- `layout_applied` (string): The layout type applied
- `element_count` (integer): Number of elements laid out

**Example:**
```
auto_layout(diagram_path="app.drawio", layout="tree")
```

### `import_mermaid`

Convert Mermaid syntax to a .drawio file.

**Supports:**
- `graph TD` / `graph LR` for direction (top-down or left-to-right)
- `A[text]` for rectangles
- `A(text)` for rounded rectangles
- `A{text}` for diamonds
- `A((text))` for circles
- `A --> B` for connections
- `A -->|label| B` for labeled connections
- `A --- B` for undirected connections

**Parameters:**
- `mermaid_text` (string): Mermaid diagram syntax
- `output_path` (string): Path to save the .drawio file

**Returns:**
- `success` (boolean): Whether the operation succeeded
- `output_path` (string): The saved file path
- `elements_created` (integer): Total elements created
- `vertices` (integer): Number of shapes created
- `edges` (integer): Number of connectors created

**Example:**
```
import_mermaid(mermaid_text="""
graph TD
  A[User] --> B(API Gateway)
  B --> C{Check Auth}
  C -->|Yes| D[Database]
  C -->|No| E[Error]
""", output_path="system.drawio")
```

### `import_plantuml`

Convert PlantUML syntax to a .drawio file.

**Supports:**
- `[Component]` for components
- `(Actor)` for actors
- `database "Name"` for databases
- `A --> B : label` for connections with labels
- `@startuml` / `@enduml` delimiters (optional)

**Parameters:**
- `plantuml_text` (string): PlantUML diagram syntax
- `output_path` (string): Path to save the .drawio file

**Returns:**
- `success` (boolean): Whether the operation succeeded
- `output_path` (string): The saved file path
- `elements_created` (integer): Total elements created
- `vertices` (integer): Number of shapes created
- `edges` (integer): Number of connectors created

**Example:**
```
import_plantuml(plantuml_text="""
@startuml
[Web Server] --> (User)
[Web Server] --> database "PostgreSQL"
@enduml
""", output_path="deployment.drawio")
```

### `export_svg`

Export a diagram to a simplified SVG preview.

Current limitation: exported SVGs render nodes as simple rectangles and connectors as straight lines. This is intended as a lightweight preview, not a pixel-faithful draw.io renderer.

**Parameters:**
- `diagram_path` (string): Path to .drawio file
- `output_path` (string): Path to save the SVG file

**Returns:**
- `success` (boolean): Whether the operation succeeded
- `output_path` (string): The saved SVG file path
- `elements_exported` (integer): Number of elements exported

**Example:**
```
export_svg(diagram_path="app.drawio", output_path="app.svg")
```

### `generate_diagram`

Generate a basic starter diagram from a natural language description.

Current limitation: generation uses a lightweight heuristic to infer a few nodes and linear connections. Treat the output as a starting point to review and refine, not a final architecture diagram.

**Parameters:**
- `description` (string): Natural language description of the diagram
- `output_path` (string): Path to save the .drawio file
- `diagram_type` (string, optional): Type of diagram (default: "auto")
  - Options: auto, flowchart, class, deployment, architecture

**Returns:**
- `success` (boolean): Whether the operation succeeded
- `output_path` (string): The saved file path
- `diagram_type` (string): The diagram type
- `elements_created` (integer): Total elements created
- `vertices` (integer): Number of shapes created
- `edges` (integer): Number of connectors created
- `note` (string): Reminder to review and refine

**Example:**
```
generate_diagram(description="A user connects to an API gateway which connects to a database", output_path="generated.drawio", diagram_type="architecture")
```

## Color Palette

The server includes a professional color palette:

- **blue**: Light blue with darker blue border
- **green**: Light green with darker green border
- **yellow**: Light yellow with golden border
- **red**: Light red with darker red border
- **purple**: Light purple with darker purple border
- **orange**: Light orange with darker orange border
- **gray**: Light gray with dark gray border
- **pink**: Light pink with darker pink border
- **teal**: Light teal with darker teal border
- **light_blue**: Very light blue with blue border

## Shape Types

Available shapes for creating nodes:

- **rectangle**: Standard rectangular shape
- **rounded**: Rounded rectangle
- **diamond**: Diamond shape (good for decisions)
- **circle**: Perfect circle/ellipse
- **cylinder**: Cylinder (good for databases)
- **cloud**: Cloud shape
- **parallelogram**: Parallelogram (good for I/O)
- **hexagon**: Hexagon
- **triangle**: Triangle
- **actor**: Actor/stick figure
- **component**: Software component
- **folder**: Folder icon
- **document**: Document icon
- **image**: Image placeholder

## Layout Algorithms

### Tree Layout
Arranges elements hierarchically in levels, with source nodes at the top and their children below. Supports BFS traversal from root nodes.

### Grid Layout
Arranges elements in a regular grid pattern. Number of columns is determined by the square root of the number of elements.

### Left-to-Right (LR) Layout
Similar to tree layout but horizontal orientation. Useful for timelines and sequential processes.

## Development

### Running Tests

```bash
pip install -e ".[dev]"
pytest
```

### Code Style

Format code with Black:

```bash
black drawio_mcp_server/
```

Lint with Ruff:

```bash
ruff check drawio_mcp_server/
```

## Technical Details

### XML Structure

The server uses the standard draw.io XML format with:

- **mxfile**: Root element containing metadata
- **diagram**: Page/diagram container
- **mxGraphModel**: Graph model with configuration
- **root**: Contains all cells (mxCell elements)
- **mxCell**: Individual shapes or connectors
- **mxGeometry**: Position and size information

### File Format

All diagrams are saved as `.drawio` files, which are standard XML files that can be opened directly in draw.io, Diagrams.net, or other compatible editors.

### Error Handling

All tools include comprehensive error handling:

- Invalid file paths return specific error messages
- Missing elements are reported clearly
- Duplicate IDs are detected and prevented
- Orphaned edges are identified during validation

## Limitations

- SVG export provides basic representation; complex styling may differ from draw.io
- Natural language diagram generation uses simple NLP; complex diagrams should be built manually
- Mermaid and PlantUML imports support core syntax; advanced features may require manual adjustment

## Support

For issues or feature requests, please refer to the documentation or contact the maintainers.

## License

MIT
