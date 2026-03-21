"""Core draw.io diagram manipulation library."""

import re
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union
from lxml import etree
from .style_maps import (
    SHAPE_STYLES,
    COLOR_PALETTE,
    EDGE_STYLES,
    DEFAULT_VERTEX_STYLE,
    DEFAULT_EDGE_STYLE,
    GRID_CELL_WIDTH,
    GRID_CELL_HEIGHT,
    TREE_LEVEL_HEIGHT,
    TREE_NODE_SPACING,
)


class Diagram:
    """Wrapper class for a draw.io diagram XML structure."""

    def __init__(self, root: etree._Element):
        """Initialize a Diagram with an XML root element.

        Args:
            root: lxml Element representing the <mxfile> root
        """
        self.root = root
        self.namespace = {"mx": "http://www.jgraph.com/xml/format/basic"}

    def get_mxgraph_model(self) -> etree._Element:
        """Get the mxGraphModel element."""
        model = self.root.find(".//mxGraphModel")
        if model is None:
            raise ValueError("Invalid draw.io file: missing mxGraphModel")
        return model

    def get_root_cell(self) -> Optional[etree._Element]:
        """Get the root cell element (usually with id='0')."""
        model = self.get_mxgraph_model()
        root_cell = model.find(".//mxCell[@id='0']")
        return root_cell

    def get_default_parent(self) -> Optional[etree._Element]:
        """Get the default parent cell (usually with id='1')."""
        model = self.get_mxgraph_model()
        default_parent = model.find(".//mxCell[@id='1']")
        return default_parent

    def find_cell_by_id(self, cell_id: str) -> Optional[etree._Element]:
        """Find a cell element by its id attribute."""
        model = self.get_mxgraph_model()
        cell = model.find(f".//mxCell[@id='{cell_id}']")
        return cell

    def find_all_cells(self) -> List[etree._Element]:
        """Find all cell elements in the diagram."""
        model = self.get_mxgraph_model()
        cells = model.findall(".//mxCell")
        return cells


def create_empty_diagram(name: str = "Page-1") -> Diagram:
    """Create an empty draw.io diagram with structural cells.

    Args:
        name: Name of the diagram page

    Returns:
        Diagram object with minimal structure
    """
    mxfile = etree.Element("mxfile")
    mxfile.set("host", "Claude MCP Server")
    mxfile.set("modified", "2026-03-20T00:00:00.000Z")
    mxfile.set("agent", "drawio-mcp-server/1.0")
    mxfile.set("version", "24.1.0")

    diagram = etree.SubElement(mxfile, "diagram")
    diagram.set("name", name)
    diagram.set("id", "0")

    mxgraph_model = etree.SubElement(diagram, "mxGraphModel")
    mxgraph_model.set("dx", "1200")
    mxgraph_model.set("dy", "750")
    mxgraph_model.set("grid", "1")
    mxgraph_model.set("gridSize", "10")
    mxgraph_model.set("guides", "1")
    mxgraph_model.set("tooltips", "1")
    mxgraph_model.set("connect", "1")
    mxgraph_model.set("arrows", "1")
    mxgraph_model.set("fold", "1")
    mxgraph_model.set("page", "1")
    mxgraph_model.set("pageScale", "1")
    mxgraph_model.set("pageWidth", "827")
    mxgraph_model.set("pageHeight", "1169")
    mxgraph_model.set("background", "#ffffff")
    mxgraph_model.set("math", "0")
    mxgraph_model.set("shadow", "0")

    root = etree.SubElement(mxgraph_model, "root")

    # Root cell (id='0')
    root_cell = etree.SubElement(root, "mxCell")
    root_cell.set("id", "0")

    # Default parent cell (id='1')
    parent_cell = etree.SubElement(root, "mxCell")
    parent_cell.set("id", "1")
    parent_cell.set("parent", "0")
    parent_cell.set("edge", "0")

    return Diagram(mxfile)


def parse_diagram(xml_source: Union[str, Path]) -> Diagram:
    """Parse a draw.io diagram from XML string or filepath.

    Args:
        xml_source: Either an XML string or a Path to a .drawio file

    Returns:
        Parsed Diagram object

    Raises:
        ValueError: If the input is invalid XML or file cannot be read
    """
    try:
        if isinstance(xml_source, (str, Path)):
            xml_source_path = Path(xml_source)
            if xml_source_path.exists():
                # It's a file path
                tree = etree.parse(str(xml_source_path))
                root = tree.getroot()
            else:
                # Try to parse as XML string
                root = etree.fromstring(xml_source.encode("utf-8"))
        else:
            root = etree.fromstring(xml_source.encode("utf-8"))

        return Diagram(root)
    except etree.XMLSyntaxError as e:
        raise ValueError(f"Invalid XML: {e}")
    except FileNotFoundError as e:
        raise ValueError(f"File not found: {e}")


def _build_style_string(
    base_style: str,
    shape: Optional[str] = None,
    color: Optional[str] = None,
    **kwargs: Any,
) -> str:
    """Build a draw.io style string from components.

    Args:
        base_style: Base style string
        shape: Shape type (from SHAPE_STYLES)
        color: Color name (from COLOR_PALETTE)
        **kwargs: Additional style properties

    Returns:
        Complete style string
    """
    style_parts = [base_style]

    if shape and shape in SHAPE_STYLES:
        style_parts.append(SHAPE_STYLES[shape])

    if color and color in COLOR_PALETTE:
        palette = COLOR_PALETTE[color]
        style_parts.append(f"fillColor={palette['fill']};strokeColor={palette['stroke']};")

    for key, value in kwargs.items():
        if value is not None:
            style_parts.append(f"{key}={value};")

    return "".join(style_parts)


def add_vertex(
    diagram: Diagram,
    cell_id: str,
    value: str,
    x: int,
    y: int,
    width: int = 120,
    height: int = 60,
    shape: str = "rectangle",
    color: str = "blue",
    parent: str = "1",
) -> etree._Element:
    """Add a vertex (shape) to the diagram.

    Args:
        diagram: Diagram object
        cell_id: Unique identifier for the cell
        value: Text label for the shape
        x: X coordinate
        y: Y coordinate
        width: Width of the shape
        height: Height of the shape
        shape: Shape type (see SHAPE_STYLES)
        color: Color name (see COLOR_PALETTE)
        parent: Parent cell id

    Returns:
        The created mxCell element
    """
    model = diagram.get_mxgraph_model()
    root = model.find("root")

    if root is None:
        raise ValueError("Invalid diagram: no root element")

    # Check for duplicate ID
    if diagram.find_cell_by_id(cell_id):
        raise ValueError(f"Cell with id '{cell_id}' already exists")

    cell = etree.SubElement(root, "mxCell")
    cell.set("id", cell_id)
    cell.set("value", value)
    cell.set("style", _build_style_string(DEFAULT_VERTEX_STYLE, shape=shape, color=color))
    cell.set("vertex", "1")
    cell.set("parent", parent)

    geometry = etree.SubElement(cell, "mxGeometry")
    geometry.set("x", str(x))
    geometry.set("y", str(y))
    geometry.set("width", str(width))
    geometry.set("height", str(height))
    geometry.set("as", "geometry")

    return cell


def add_edge(
    diagram: Diagram,
    edge_id: str,
    source: str,
    target: str,
    value: str = "",
    style: str = "orthogonal",
    parent: str = "1",
) -> etree._Element:
    """Add an edge (connector) between two cells.

    Args:
        diagram: Diagram object
        edge_id: Unique identifier for the edge
        source: Source cell id
        target: Target cell id
        value: Label text for the edge
        style: Edge style type (see EDGE_STYLES)
        parent: Parent cell id

    Returns:
        The created mxCell element
    """
    model = diagram.get_mxgraph_model()
    root = model.find("root")

    if root is None:
        raise ValueError("Invalid diagram: no root element")

    # Check for duplicate ID
    if diagram.find_cell_by_id(edge_id):
        raise ValueError(f"Cell with id '{edge_id}' already exists")

    # Verify source and target exist
    if diagram.find_cell_by_id(source) is None:
        raise ValueError(f"Source cell '{source}' not found")
    if diagram.find_cell_by_id(target) is None:
        raise ValueError(f"Target cell '{target}' not found")

    edge = etree.SubElement(root, "mxCell")
    edge.set("id", edge_id)
    edge.set("value", value)
    edge_style = EDGE_STYLES.get(style, EDGE_STYLES["orthogonal"])
    edge.set("style", DEFAULT_EDGE_STYLE + edge_style)
    edge.set("edge", "1")
    edge.set("parent", parent)
    edge.set("source", source)
    edge.set("target", target)

    geometry = etree.SubElement(edge, "mxGeometry")
    geometry.set("relative", "1")
    geometry.set("as", "geometry")

    return edge


def remove_element(diagram: Diagram, element_id: str) -> bool:
    """Remove a cell from the diagram.

    Args:
        diagram: Diagram object
        element_id: ID of the element to remove

    Returns:
        True if element was removed, False if not found
    """
    cell = diagram.find_cell_by_id(element_id)
    if cell is None:
        return False

    model = diagram.get_mxgraph_model()
    root = model.find("root")
    if root is not None:
        root.remove(cell)

    # Also remove any edges referencing this cell
    for edge_cell in diagram.find_all_cells():
        source = edge_cell.get("source")
        target = edge_cell.get("target")
        if source == element_id or target == element_id:
            root.remove(edge_cell)

    return True


def update_element(
    diagram: Diagram,
    element_id: str,
    label: Optional[str] = None,
    style: Optional[str] = None,
    x: Optional[int] = None,
    y: Optional[int] = None,
    width: Optional[int] = None,
    height: Optional[int] = None,
) -> bool:
    """Update properties of an existing element.

    Args:
        diagram: Diagram object
        element_id: ID of the element to update
        label: New label text
        style: New style string
        x: New X coordinate
        y: New Y coordinate
        width: New width
        height: New height

    Returns:
        True if element was updated, False if not found
    """
    cell = diagram.find_cell_by_id(element_id)
    if cell is None:
        return False

    if label is not None:
        cell.set("value", label)

    if style is not None:
        cell.set("style", style)

    geometry = cell.find("mxGeometry")
    if geometry is None:
        geometry = etree.SubElement(cell, "mxGeometry")
        geometry.set("as", "geometry")

    if x is not None:
        geometry.set("x", str(x))
    if y is not None:
        geometry.set("y", str(y))
    if width is not None:
        geometry.set("width", str(width))
    if height is not None:
        geometry.set("height", str(height))

    return True


def list_elements(diagram: Diagram) -> List[Dict[str, Any]]:
    """Get a structured list of all elements in the diagram.

    Args:
        diagram: Diagram object

    Returns:
        List of element dictionaries with properties
    """
    elements = []
    for cell in diagram.find_all_cells():
        cell_id = cell.get("id")
        if cell_id in ("0", "1"):  # Skip structural cells
            continue

        element_dict = {
            "id": cell_id,
            "type": "edge" if cell.get("edge") == "1" else "vertex",
            "label": cell.get("value", ""),
            "style": cell.get("style", ""),
        }

        if cell.get("edge") == "1":
            element_dict["source"] = cell.get("source")
            element_dict["target"] = cell.get("target")
        else:
            geometry = cell.find("mxGeometry")
            if geometry is not None:
                element_dict["x"] = int(geometry.get("x", 0))
                element_dict["y"] = int(geometry.get("y", 0))
                element_dict["width"] = int(geometry.get("width", 0))
                element_dict["height"] = int(geometry.get("height", 0))

        elements.append(element_dict)

    return elements


def get_element(diagram: Diagram, element_id: str) -> Optional[Dict[str, Any]]:
    """Get details of a single element.

    Args:
        diagram: Diagram object
        element_id: ID of the element

    Returns:
        Dictionary with element properties or None if not found
    """
    cell = diagram.find_cell_by_id(element_id)
    if cell is None:
        return None

    element_dict = {
        "id": element_id,
        "type": "edge" if cell.get("edge") == "1" else "vertex",
        "label": cell.get("value", ""),
        "style": cell.get("style", ""),
        "parent": cell.get("parent"),
    }

    if cell.get("edge") == "1":
        element_dict["source"] = cell.get("source")
        element_dict["target"] = cell.get("target")
    else:
        geometry = cell.find("mxGeometry")
        if geometry is not None:
            element_dict["x"] = int(geometry.get("x", 0))
            element_dict["y"] = int(geometry.get("y", 0))
            element_dict["width"] = int(geometry.get("width", 0))
            element_dict["height"] = int(geometry.get("height", 0))

    return element_dict


def auto_layout(diagram: Diagram, layout_type: str = "tree") -> None:
    """Auto-arrange elements using a layout algorithm.

    Args:
        diagram: Diagram object
        layout_type: Type of layout - "tree", "grid", or "lr" (left-to-right)
    """
    cells = [c for c in diagram.find_all_cells() if c.get("id") not in ("0", "1")]
    vertices = [c for c in cells if c.get("edge") != "1"]

    if not vertices:
        return

    if layout_type == "tree":
        _layout_tree(diagram, vertices)
    elif layout_type == "grid":
        _layout_grid(diagram, vertices)
    elif layout_type == "lr":
        _layout_tree(diagram, vertices, horizontal=True)


def _layout_tree(
    diagram: Diagram, vertices: List[etree._Element], horizontal: bool = False
) -> None:
    """Arrange vertices in a tree/hierarchical layout.

    Args:
        diagram: Diagram object
        vertices: List of vertex cells
        horizontal: If True, arrange left-to-right instead of top-down
    """
    # Build adjacency info
    edges = [c for c in diagram.find_all_cells() if c.get("edge") == "1"]
    children_map: Dict[str, List[str]] = {}
    parents_set = set()

    for edge in edges:
        source = edge.get("source")
        target = edge.get("target")
        if source and target:
            if source not in children_map:
                children_map[source] = []
            children_map[source].append(target)
            parents_set.add(target)

    # Find root nodes (those with no parents)
    root_ids = [c.get("id") for c in vertices if c.get("id") not in parents_set]

    # BFS layout
    positioned = set()
    queue: List[Tuple[str, int, int]] = [
        (root_id, 0, i * TREE_NODE_SPACING) for i, root_id in enumerate(root_ids)
    ]

    while queue:
        cell_id, level, x_offset = queue.pop(0)
        if cell_id in positioned:
            continue

        cell = diagram.find_cell_by_id(cell_id)
        if cell is None:
            continue

        y = level * TREE_LEVEL_HEIGHT
        x = x_offset

        geometry = cell.find("mxGeometry")
        if geometry is None:
            geometry = etree.SubElement(cell, "mxGeometry")
            geometry.set("as", "geometry")

        if horizontal:
            geometry.set("x", str(y))
            geometry.set("y", str(x))
        else:
            geometry.set("x", str(x))
            geometry.set("y", str(y))

        geometry.set("width", "120")
        geometry.set("height", "60")

        positioned.add(cell_id)

        # Add children to queue
        for child_id in children_map.get(cell_id, []):
            queue.append((child_id, level + 1, x_offset))


def _layout_grid(diagram: Diagram, vertices: List[etree._Element]) -> None:
    """Arrange vertices in a grid layout.

    Args:
        diagram: Diagram object
        vertices: List of vertex cells
    """
    cols = max(1, int(len(vertices) ** 0.5))
    for i, cell in enumerate(vertices):
        row = i // cols
        col = i % cols

        x = col * GRID_CELL_WIDTH
        y = row * GRID_CELL_HEIGHT

        geometry = cell.find("mxGeometry")
        if geometry is None:
            geometry = etree.SubElement(cell, "mxGeometry")
            geometry.set("as", "geometry")

        geometry.set("x", str(x))
        geometry.set("y", str(y))
        geometry.set("width", "120")
        geometry.set("height", "60")


def validate_diagram(diagram: Diagram) -> List[str]:
    """Validate a diagram and report issues.

    Args:
        diagram: Diagram object

    Returns:
        List of warning/error messages
    """
    issues = []
    cells = diagram.find_all_cells()

    # Check for structural cells
    has_root = any(c.get("id") == "0" for c in cells)
    has_parent = any(c.get("id") == "1" for c in cells)

    if not has_root:
        issues.append("Missing root cell (id='0')")
    if not has_parent:
        issues.append("Missing default parent cell (id='1')")

    # Check for duplicate IDs
    ids = [c.get("id") for c in cells if c.get("id")]
    duplicates = [id for id in set(ids) if ids.count(id) > 1]
    if duplicates:
        issues.append(f"Duplicate cell IDs: {', '.join(duplicates)}")

    # Check for orphaned edges
    cell_ids = set(c.get("id") for c in cells if c.get("id"))
    for edge in cells:
        if edge.get("edge") == "1":
            source = edge.get("source")
            target = edge.get("target")
            if source not in cell_ids:
                issues.append(f"Edge {edge.get('id')} has missing source: {source}")
            if target not in cell_ids:
                issues.append(f"Edge {edge.get('id')} has missing target: {target}")

    return issues


def to_xml(diagram: Diagram) -> str:
    """Serialize diagram to XML string.

    Args:
        diagram: Diagram object

    Returns:
        XML string representation
    """
    return etree.tostring(diagram.root, pretty_print=True, encoding="unicode")


def mermaid_to_drawio(mermaid_text: str) -> Diagram:
    """Convert Mermaid flowchart syntax to a draw.io diagram.

    Supports:
    - graph TD / graph LR for direction
    - A[text], A(text), A{text}, A((text)) for shapes
    - A --> B, A -->|label| B, A --- B for connections

    Args:
        mermaid_text: Mermaid diagram syntax

    Returns:
        Diagram object
    """
    diagram = create_empty_diagram("Mermaid Diagram")

    # Parse direction
    direction_match = re.search(r"graph\s+(TD|LR|BT|RL)", mermaid_text)
    direction = direction_match.group(1) if direction_match else "TD"

    # Parse nodes: A[text], A(text), A{text}, A((text))
    node_pattern = r"(\w+)\s*([(\[{].*?[)\]}])"
    node_matches = re.finditer(node_pattern, mermaid_text)

    nodes = {}
    for match in node_matches:
        node_id = match.group(1)
        node_content = match.group(2)

        # Determine shape
        if node_content.startswith("[") and node_content.endswith("]"):
            shape, label = "rectangle", node_content[1:-1].strip()
        elif node_content.startswith("(") and node_content.endswith(")"):
            if node_content.startswith("((") and node_content.endswith("))"):
                shape, label = "circle", node_content[2:-2].strip()
            else:
                shape, label = "rounded", node_content[1:-1].strip()
        elif node_content.startswith("{") and node_content.endswith("}"):
            shape, label = "diamond", node_content[1:-1].strip()
        else:
            shape, label = "rectangle", node_content

        nodes[node_id] = {"label": label, "shape": shape}

    # Add nodes to diagram
    pos_map = {}
    for i, (node_id, node_data) in enumerate(nodes.items()):
        x = i * 200 if direction in ("TD", "BT") else i * 250
        y = i * 150 if direction in ("TD", "BT") else 100
        if direction == "LR":
            x, y = i * 250, i * 80
        elif direction == "RL":
            x, y = -(i * 250), i * 80

        add_vertex(
            diagram,
            node_id,
            node_data["label"],
            x,
            y,
            shape=node_data["shape"],
            color="blue",
        )
        pos_map[node_id] = (x, y)

    # Parse edges: A --> B, A -->|label| B, A --- B
    edge_pattern = r"(\w+)\s*(?:-->|---)\s*(?:\|([^|]+)\|)?\s*(\w+)"
    edge_matches = re.finditer(edge_pattern, mermaid_text)

    for i, match in enumerate(edge_matches):
        source = match.group(1)
        label = match.group(2) or ""
        target = match.group(3)

        if source in nodes and target in nodes:
            add_edge(diagram, f"edge_{i}", source, target, value=label.strip())

    return diagram


def plantuml_to_drawio(plantuml_text: str) -> Diagram:
    """Convert PlantUML syntax to a draw.io diagram.

    Supports:
    - [Component], (Actor), database "Name"
    - A --> B : label

    Args:
        plantuml_text: PlantUML diagram syntax

    Returns:
        Diagram object
    """
    diagram = create_empty_diagram("PlantUML Diagram")

    # Remove @startuml/@enduml tags
    text = re.sub(r"@startuml|@enduml", "", plantuml_text)

    # Parse components/actors: [Name], (Name), database "Name"
    nodes = {}

    # [Component]
    component_pattern = r"\[([^\]]+)\]"
    for match in re.finditer(component_pattern, text):
        node_id = match.group(1).replace(" ", "_")
        nodes[node_id] = {"label": match.group(1), "shape": "component"}

    # (Actor)
    actor_pattern = r"\(([^)]+)\)"
    for match in re.finditer(actor_pattern, text):
        node_id = match.group(1).replace(" ", "_")
        nodes[node_id] = {"label": match.group(1), "shape": "actor"}

    # database "Name"
    database_pattern = r'database\s+"([^"]+)"'
    for match in re.finditer(database_pattern, text):
        node_id = match.group(1).replace(" ", "_")
        nodes[node_id] = {"label": match.group(1), "shape": "cylinder"}

    # Add nodes to diagram
    for i, (node_id, node_data) in enumerate(nodes.items()):
        x = i * 200
        y = i * 150
        add_vertex(
            diagram,
            node_id,
            node_data["label"],
            x,
            y,
            shape=node_data["shape"],
            color="green",
        )

    # Parse connections: A --> B : label
    connection_pattern = r"(\w+)\s*-->\s*(\w+)\s*:?\s*(.*)$"
    for i, match in re.finditer(connection_pattern, text, re.MULTILINE):
        source = match.group(1)
        target = match.group(2)
        label = match.group(3).strip() if match.group(3) else ""

        source_id = source.replace(" ", "_")
        target_id = target.replace(" ", "_")

        if source_id in nodes and target_id in nodes:
            add_edge(
                diagram, f"edge_{i}", source_id, target_id, value=label, style="arrow"
            )

    return diagram
