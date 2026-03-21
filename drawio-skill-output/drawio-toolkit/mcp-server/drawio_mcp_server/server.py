"""MCP server for draw.io diagram operations."""

import re
import json
from pathlib import Path
from typing import Any, Dict, List, Optional
from mcp.server.fastmcp import FastMCP
from .diagram_core import (
    create_empty_diagram,
    parse_diagram,
    add_vertex,
    add_edge,
    remove_element,
    update_element,
    list_elements,
    get_element,
    auto_layout,
    validate_diagram,
    to_xml,
    mermaid_to_drawio,
    plantuml_to_drawio,
)
from .style_maps import SHAPE_STYLES, COLOR_PALETTE, EDGE_STYLES

# Initialize MCP server
server = FastMCP("drawio-mcp-server")


def _ensure_drawio_path(path: str) -> Path:
    """Ensure path is valid and add .drawio extension if needed.

    Args:
        path: File path

    Returns:
        Path object with .drawio extension
    """
    p = Path(path)
    if p.suffix != ".drawio":
        p = p.with_suffix(".drawio")
    return p


def _save_diagram(diagram: Any, filepath: Path) -> None:
    """Save diagram to file.

    Args:
        diagram: Diagram object
        filepath: Path to save to
    """
    filepath.parent.mkdir(parents=True, exist_ok=True)
    xml_content = to_xml(diagram)
    filepath.write_text(xml_content, encoding="utf-8")


# Tool implementations


@server.tool()
def create_diagram(name: str = "Untitled") -> Dict[str, Any]:
    """Create a new empty .drawio diagram.

    Args:
        name: Name of the diagram

    Returns:
        Dictionary with diagram info and XML content
    """
    try:
        diagram = create_empty_diagram(name)
        xml_content = to_xml(diagram)
        return {
            "success": True,
            "name": name,
            "xml_preview": xml_content[:500] + "..." if len(xml_content) > 500 else xml_content,
            "cell_count": len(diagram.find_all_cells()),
        }
    except Exception as e:
        return {"success": False, "error": str(e)}


@server.tool()
def add_node(
    diagram_path: str,
    node_id: str,
    label: str,
    x: int = 0,
    y: int = 0,
    width: int = 120,
    height: int = 60,
    shape: str = "rectangle",
    color: str = "blue",
    parent: str = "1",
) -> Dict[str, Any]:
    """Add a shape (node) to a diagram.

    Args:
        diagram_path: Path to .drawio file
        node_id: Unique identifier for the node
        label: Text label for the shape
        x: X coordinate (default 0)
        y: Y coordinate (default 0)
        width: Width of shape (default 120)
        height: Height of shape (default 60)
        shape: Shape type - rectangle, rounded, diamond, circle, cylinder, cloud, parallelogram, hexagon (default rectangle)
        color: Color - blue, green, yellow, red, purple, orange, gray, pink, teal, light_blue (default blue)
        parent: Parent cell id (default 1)

    Returns:
        Dictionary with operation result
    """
    try:
        filepath = _ensure_drawio_path(diagram_path)

        if not filepath.exists():
            return {"success": False, "error": f"Diagram file not found: {filepath}"}

        diagram = parse_diagram(filepath)

        # Validate shape and color
        if shape not in SHAPE_STYLES:
            return {
                "success": False,
                "error": f"Unknown shape: {shape}. Available: {', '.join(SHAPE_STYLES.keys())}",
            }
        if color not in COLOR_PALETTE:
            return {
                "success": False,
                "error": f"Unknown color: {color}. Available: {', '.join(COLOR_PALETTE.keys())}",
            }

        add_vertex(diagram, node_id, label, x, y, width, height, shape, color, parent)
        _save_diagram(diagram, filepath)

        return {
            "success": True,
            "node_id": node_id,
            "label": label,
            "shape": shape,
            "color": color,
            "position": {"x": x, "y": y},
            "size": {"width": width, "height": height},
        }
    except ValueError as e:
        return {"success": False, "error": str(e)}
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}


@server.tool()
def add_connection(
    diagram_path: str,
    connection_id: str,
    source: str,
    target: str,
    label: str = "",
    style: str = "orthogonal",
    parent: str = "1",
) -> Dict[str, Any]:
    """Add a connector between two shapes.

    Args:
        diagram_path: Path to .drawio file
        connection_id: Unique identifier for the connection
        source: Source node id
        target: Target node id
        label: Label text for the connection (default empty)
        style: Connection style - orthogonal, straight, curved, dashed, bold, arrow (default orthogonal)
        parent: Parent cell id (default 1)

    Returns:
        Dictionary with operation result
    """
    try:
        filepath = _ensure_drawio_path(diagram_path)

        if not filepath.exists():
            return {"success": False, "error": f"Diagram file not found: {filepath}"}

        diagram = parse_diagram(filepath)

        # Validate style
        if style not in EDGE_STYLES:
            return {
                "success": False,
                "error": f"Unknown edge style: {style}. Available: {', '.join(EDGE_STYLES.keys())}",
            }

        add_edge(diagram, connection_id, source, target, label, style, parent)
        _save_diagram(diagram, filepath)

        return {
            "success": True,
            "connection_id": connection_id,
            "source": source,
            "target": target,
            "label": label,
            "style": style,
        }
    except ValueError as e:
        return {"success": False, "error": str(e)}
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}


@server.tool()
def remove_element(diagram_path: str, element_id: str) -> Dict[str, Any]:
    """Remove a shape or connector from a diagram.

    Args:
        diagram_path: Path to .drawio file
        element_id: ID of the element to remove

    Returns:
        Dictionary with operation result
    """
    try:
        filepath = _ensure_drawio_path(diagram_path)

        if not filepath.exists():
            return {"success": False, "error": f"Diagram file not found: {filepath}"}

        diagram = parse_diagram(filepath)

        if remove_element(diagram, element_id):
            _save_diagram(diagram, filepath)
            return {"success": True, "removed_id": element_id}
        else:
            return {"success": False, "error": f"Element not found: {element_id}"}
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}


@server.tool()
def update_element(
    diagram_path: str,
    element_id: str,
    label: Optional[str] = None,
    style: Optional[str] = None,
    x: Optional[int] = None,
    y: Optional[int] = None,
    width: Optional[int] = None,
    height: Optional[int] = None,
) -> Dict[str, Any]:
    """Update properties of an element in a diagram.

    Args:
        diagram_path: Path to .drawio file
        element_id: ID of the element to update
        label: New label text (optional)
        style: New style string (optional)
        x: New X coordinate (optional)
        y: New Y coordinate (optional)
        width: New width (optional)
        height: New height (optional)

    Returns:
        Dictionary with operation result
    """
    try:
        filepath = _ensure_drawio_path(diagram_path)

        if not filepath.exists():
            return {"success": False, "error": f"Diagram file not found: {filepath}"}

        diagram = parse_diagram(filepath)

        if update_element(diagram, element_id, label, style, x, y, width, height):
            _save_diagram(diagram, filepath)
            return {
                "success": True,
                "updated_id": element_id,
                "changes": {
                    "label": label,
                    "style": style,
                    "position": {"x": x, "y": y} if x is not None or y is not None else None,
                    "size": {"width": width, "height": height}
                    if width is not None or height is not None
                    else None,
                },
            }
        else:
            return {"success": False, "error": f"Element not found: {element_id}"}
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}


@server.tool()
def list_elements(diagram_path: str) -> Dict[str, Any]:
    """List all shapes and connectors in a diagram.

    Args:
        diagram_path: Path to .drawio file

    Returns:
        Dictionary with list of elements
    """
    try:
        filepath = _ensure_drawio_path(diagram_path)

        if not filepath.exists():
            return {"success": False, "error": f"Diagram file not found: {filepath}"}

        diagram = parse_diagram(filepath)
        elements = list_elements(diagram)

        return {
            "success": True,
            "diagram_path": str(filepath),
            "element_count": len(elements),
            "elements": elements,
        }
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}


@server.tool()
def read_diagram(diagram_path: str) -> Dict[str, Any]:
    """Read and return a structured summary of a .drawio file.

    Args:
        diagram_path: Path to .drawio file

    Returns:
        Dictionary with diagram structure
    """
    try:
        filepath = _ensure_drawio_path(diagram_path)

        if not filepath.exists():
            return {"success": False, "error": f"Diagram file not found: {filepath}"}

        diagram = parse_diagram(filepath)
        elements = list_elements(diagram)

        vertices = [e for e in elements if e["type"] == "vertex"]
        edges = [e for e in elements if e["type"] == "edge"]

        return {
            "success": True,
            "diagram_path": str(filepath),
            "file_size_bytes": filepath.stat().st_size,
            "total_elements": len(elements),
            "vertices": len(vertices),
            "edges": len(edges),
            "elements_summary": elements,
        }
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}


@server.tool()
def validate_diagram(diagram_path: str) -> Dict[str, Any]:
    """Validate a diagram and report issues.

    Args:
        diagram_path: Path to .drawio file

    Returns:
        Dictionary with validation results
    """
    try:
        filepath = _ensure_drawio_path(diagram_path)

        if not filepath.exists():
            return {"success": False, "error": f"Diagram file not found: {filepath}"}

        diagram = parse_diagram(filepath)
        issues = validate_diagram(diagram)

        return {
            "success": True,
            "diagram_path": str(filepath),
            "is_valid": len(issues) == 0,
            "issue_count": len(issues),
            "issues": issues,
        }
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}


@server.tool()
def auto_layout(diagram_path: str, layout: str = "tree") -> Dict[str, Any]:
    """Auto-arrange elements in a diagram.

    Args:
        diagram_path: Path to .drawio file
        layout: Layout algorithm - tree, grid, lr (left-to-right) (default tree)

    Returns:
        Dictionary with operation result
    """
    try:
        filepath = _ensure_drawio_path(diagram_path)

        if not filepath.exists():
            return {"success": False, "error": f"Diagram file not found: {filepath}"}

        diagram = parse_diagram(filepath)

        if layout not in ("tree", "grid", "lr"):
            return {
                "success": False,
                "error": f"Unknown layout: {layout}. Available: tree, grid, lr",
            }

        auto_layout(diagram, layout)
        _save_diagram(diagram, filepath)

        return {
            "success": True,
            "diagram_path": str(filepath),
            "layout_applied": layout,
            "element_count": len(list_elements(diagram)),
        }
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}


@server.tool()
def import_mermaid(mermaid_text: str, output_path: str) -> Dict[str, Any]:
    """Convert Mermaid syntax to a .drawio file.

    Supports: graph TD/LR, A[text]/A(text)/A{text}/A((text)), A-->B/A-->|label|B/A---B

    Args:
        mermaid_text: Mermaid diagram syntax
        output_path: Path to save the .drawio file

    Returns:
        Dictionary with operation result
    """
    try:
        diagram = mermaid_to_drawio(mermaid_text)
        filepath = _ensure_drawio_path(output_path)
        _save_diagram(diagram, filepath)

        elements = list_elements(diagram)
        return {
            "success": True,
            "output_path": str(filepath),
            "elements_created": len(elements),
            "vertices": len([e for e in elements if e["type"] == "vertex"]),
            "edges": len([e for e in elements if e["type"] == "edge"]),
        }
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}


@server.tool()
def import_plantuml(plantuml_text: str, output_path: str) -> Dict[str, Any]:
    """Convert PlantUML syntax to a .drawio file.

    Supports: [Component], (Actor), database "Name", A-->B:label

    Args:
        plantuml_text: PlantUML diagram syntax
        output_path: Path to save the .drawio file

    Returns:
        Dictionary with operation result
    """
    try:
        diagram = plantuml_to_drawio(plantuml_text)
        filepath = _ensure_drawio_path(output_path)
        _save_diagram(diagram, filepath)

        elements = list_elements(diagram)
        return {
            "success": True,
            "output_path": str(filepath),
            "elements_created": len(elements),
            "vertices": len([e for e in elements if e["type"] == "vertex"]),
            "edges": len([e for e in elements if e["type"] == "edge"]),
        }
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}


@server.tool()
def export_svg(diagram_path: str, output_path: str) -> Dict[str, Any]:
    """Export a diagram to SVG format.

    Args:
        diagram_path: Path to .drawio file
        output_path: Path to save the SVG file

    Returns:
        Dictionary with operation result
    """
    try:
        filepath = _ensure_drawio_path(diagram_path)

        if not filepath.exists():
            return {"success": False, "error": f"Diagram file not found: {filepath}"}

        diagram = parse_diagram(filepath)
        elements = list_elements(diagram)

        # Build SVG from elements
        svg_parts = [
            '<?xml version="1.0" encoding="UTF-8"?>',
            '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="800" viewBox="0 0 1200 800">',
            '<rect width="1200" height="800" fill="white"/>',
        ]

        # Draw vertices (shapes) first
        for elem in elements:
            if elem["type"] == "vertex":
                x = elem.get("x", 0)
                y = elem.get("y", 0)
                width = elem.get("width", 120)
                height = elem.get("height", 60)
                label = elem.get("label", "")

                # Simple rectangle for now
                svg_parts.append(
                    f'<rect x="{x}" y="{y}" width="{width}" height="{height}" '
                    f'fill="#DAE8FC" stroke="#6C8EBF" stroke-width="2"/>'
                )

                # Add text
                if label:
                    text_x = x + width / 2
                    text_y = y + height / 2
                    svg_parts.append(
                        f'<text x="{text_x}" y="{text_y}" text-anchor="middle" '
                        f'dominant-baseline="middle" font-family="Arial" font-size="12">{label}</text>'
                    )

        # Draw edges (connections)
        for elem in elements:
            if elem["type"] == "edge":
                source_id = elem.get("source")
                target_id = elem.get("target")

                # Find source and target positions
                source = next((e for e in elements if e["id"] == source_id), None)
                target = next((e for e in elements if e["id"] == target_id), None)

                if source and target:
                    x1 = source.get("x", 0) + source.get("width", 120) / 2
                    y1 = source.get("y", 0) + source.get("height", 60) / 2
                    x2 = target.get("x", 0) + target.get("width", 120) / 2
                    y2 = target.get("y", 0) + target.get("height", 60) / 2

                    label = elem.get("label", "")
                    svg_parts.append(
                        f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" '
                        f'stroke="black" stroke-width="2" marker-end="url(#arrowhead)"/>'
                    )

                    # Add label if present
                    if label:
                        mid_x = (x1 + x2) / 2
                        mid_y = (y1 + y2) / 2
                        svg_parts.append(
                            f'<text x="{mid_x}" y="{mid_y}" font-family="Arial" '
                            f'font-size="10" fill="black">{label}</text>'
                        )

        # Add arrow marker
        svg_parts.append(
            '<defs>'
            '<marker id="arrowhead" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto">'
            '<polygon points="0 0, 10 3, 0 6" fill="black" />'
            "</marker>"
            "</defs>"
        )

        svg_parts.append("</svg>")

        svg_content = "\n".join(svg_parts)

        # Save SVG file
        svg_filepath = Path(output_path)
        if svg_filepath.suffix != ".svg":
            svg_filepath = svg_filepath.with_suffix(".svg")

        svg_filepath.parent.mkdir(parents=True, exist_ok=True)
        svg_filepath.write_text(svg_content, encoding="utf-8")

        return {
            "success": True,
            "output_path": str(svg_filepath),
            "elements_exported": len(elements),
        }
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}


@server.tool()
def generate_diagram(
    description: str, output_path: str, diagram_type: str = "auto"
) -> Dict[str, Any]:
    """Generate a complete diagram from a natural language description.

    Args:
        description: Natural language description of the diagram
        output_path: Path to save the .drawio file
        diagram_type: Type of diagram - auto, flowchart, class, deployment, architecture (default auto)

    Returns:
        Dictionary with operation result
    """
    try:
        diagram = create_empty_diagram(f"Generated - {diagram_type}")

        # Simple NLP: extract nouns as nodes, verbs as edges
        words = description.split()

        # Very basic: assume pattern of "noun verb noun"
        nouns = [
            w.lower()
            for w in words
            if w[0].isupper() or w.lower() in {"user", "system", "database", "api", "server"}
        ]
        nouns = list(dict.fromkeys(nouns))  # Remove duplicates, preserve order

        # Add nodes
        for i, noun in enumerate(nouns):
            x = i * 200
            y = 100
            shape = "rounded" if "user" in noun.lower() else "rectangle"
            color = "green" if "database" in noun.lower() else "blue"
            add_vertex(diagram, f"node_{i}", noun, x, y, shape=shape, color=color)

        # Add simple linear connections
        for i in range(len(nouns) - 1):
            add_edge(
                diagram,
                f"edge_{i}",
                f"node_{i}",
                f"node_{i+1}",
                value="connects to",
                style="orthogonal",
            )

        filepath = _ensure_drawio_path(output_path)
        _save_diagram(diagram, filepath)

        elements = list_elements(diagram)
        return {
            "success": True,
            "output_path": str(filepath),
            "diagram_type": diagram_type,
            "elements_created": len(elements),
            "vertices": len([e for e in elements if e["type"] == "vertex"]),
            "edges": len([e for e in elements if e["type"] == "edge"]),
            "note": "Generated from description - review and refine as needed",
        }
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}


def main() -> None:
    """Main entry point for the MCP server."""
    server.run()


if __name__ == "__main__":
    main()
