#!/usr/bin/env python3
"""
Convert between diagram formats.

Usage: python convert.py <input> <output>

Supported conversions:
- .mermaid / .mmd → .drawio (parse Mermaid syntax)
- .puml / .plantuml → .drawio (parse PlantUML syntax)
- .drawio → .svg (generate SVG from diagram)
- .drawio → .mermaid (extract to Mermaid syntax)
"""

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from lxml import etree

# ANSI color codes
COLOR_GREEN = "\033[92m"
COLOR_RED = "\033[91m"
COLOR_RESET = "\033[0m"


class DrawioConverter:
    """Converts between diagram formats."""

    def __init__(self, input_file: str, output_file: str) -> None:
        """Initialize converter."""
        self.input_file = Path(input_file)
        self.output_file = Path(output_file)
        self.input_format = self.input_file.suffix.lower()
        self.output_format = self.output_file.suffix.lower()

    def convert(self) -> bool:
        """Perform conversion based on file formats."""
        if not self.input_file.exists():
            print(f"{COLOR_RED}Error: Input file not found: {self.input_file}{COLOR_RESET}")
            return False

        # Mermaid/PlantUML -> DrawIO
        if self.input_format in [".mermaid", ".mmd", ".puml", ".plantuml"]:
            if self.output_format != ".drawio":
                print(
                    f"{COLOR_RED}Error: Can only convert {self.input_format} to .drawio{COLOR_RESET}"
                )
                return False
            return self._convert_to_drawio()

        # DrawIO conversions
        elif self.input_format == ".drawio":
            if self.output_format == ".svg":
                return self._convert_drawio_to_svg()
            elif self.output_format in [".mermaid", ".mmd"]:
                return self._convert_drawio_to_mermaid()
            else:
                print(
                    f"{COLOR_RED}Error: Unsupported output format {self.output_format}{COLOR_RESET}"
                )
                return False
        else:
            print(
                f"{COLOR_RED}Error: Unsupported input format {self.input_format}{COLOR_RESET}"
            )
            return False

    def _convert_to_drawio(self) -> bool:
        """Convert Mermaid or PlantUML to DrawIO."""
        try:
            with open(self.input_file, "r") as f:
                content = f.read()

            if self.input_format in [".puml", ".plantuml"]:
                drawio_xml = self._plantuml_to_drawio(content)
            else:
                drawio_xml = self._mermaid_to_drawio(content)

            with open(self.output_file, "wb") as f:
                f.write(drawio_xml)

            print(
                f"{COLOR_GREEN}✓ Converted {self.input_file} → {self.output_file}{COLOR_RESET}"
            )
            return True
        except Exception as e:
            print(f"{COLOR_RED}Error: {e}{COLOR_RESET}")
            return False

    def _mermaid_to_drawio(self, content: str) -> bytes:
        """Convert Mermaid syntax to DrawIO XML."""
        lines = content.strip().split("\n")

        # Detect graph type
        graph_type = "TD"  # default
        direction_map = {"TD": "down", "LR": "right", "BT": "up", "RL": "left"}

        for line in lines:
            if line.startswith("graph"):
                parts = line.split()
                if len(parts) > 1:
                    graph_type = parts[1]
                break

        direction = direction_map.get(graph_type, "down")

        # Parse nodes and edges
        nodes: Dict[str, str] = {}  # id -> label
        edges: List[Tuple[str, str, Optional[str]]] = []  # source, target, label

        for line in lines:
            line = line.strip()
            if not line or line.startswith("graph") or line.startswith("subgraph") or line == "end":
                continue

            # Parse node definitions: id[label], id(label), id{label}, etc.
            node_pattern = r'(\w+)\s*([(\[{])(.*?)([)\]}])'
            node_match = re.search(node_pattern, line)
            if node_match:
                node_id = node_match.group(1)
                node_label = node_match.group(3)
                nodes[node_id] = node_label

            # Parse edges: id1 --> id2 |label|
            edge_pattern = r'(\w+)\s*(?:-->|---|-\.->|==>)\s*(\w+)(?:\s*\|([^|]*)\|)?'
            for match in re.finditer(edge_pattern, line):
                source = match.group(1)
                target = match.group(2)
                label = match.group(3)
                edges.append((source, target, label))

        return self._create_drawio_xml(nodes, edges, direction)

    def _plantuml_to_drawio(self, content: str) -> bytes:
        """Convert PlantUML syntax to DrawIO XML."""
        lines = content.strip().split("\n")
        nodes: Dict[str, str] = {}
        edges: List[Tuple[str, str, Optional[str]]] = []

        for line in lines:
            line = line.strip()
            if not line or line.startswith("@") or line.startswith("!"):
                continue

            # Parse component definitions: [Name], (Name), database "Name", etc.
            comp_pattern = r'\[([^\]]+)\]|\(([^)]+)\)|database\s+"([^"]+)"|node\s+"([^"]+)"|cloud\s+"([^"]+)"'
            for match in re.finditer(comp_pattern, line):
                label = next(g for g in match.groups() if g)
                node_id = label.replace(" ", "_")
                nodes[node_id] = label

            # Parse arrows: -->, ->, ..>, --
            arrow_pattern = r'(\S+)\s*(?:-->|->|\.\..>|--)\s*(\S+)(?:\s*:\s*([^:\n]+))?'
            for match in re.finditer(arrow_pattern, line):
                source = match.group(1).strip('[]()":')
                target = match.group(2).strip('[]()":')
                label = match.group(3)
                source_id = source.replace(" ", "_")
                target_id = target.replace(" ", "_")
                if source_id not in nodes:
                    nodes[source_id] = source
                if target_id not in nodes:
                    nodes[target_id] = target
                edges.append((source_id, target_id, label))

        return self._create_drawio_xml(nodes, edges, "right")

    def _create_drawio_xml(
        self, nodes: Dict[str, str], edges: List[Tuple[str, str, Optional[str]]], direction: str
    ) -> bytes:
        """Create DrawIO XML structure."""
        mxfile = etree.Element("mxfile", host="Sketchy", modified="0", version="1.0")
        diagram = etree.SubElement(mxfile, "diagram", name="Page-1", id="page-1")
        mxGraphModel = etree.SubElement(
            diagram, "mxGraphModel", dx="0", dy="0", grid="1", gridSize="10", guides="1", tooltips="1", connect="1",
            arrows="1", fold="1", page="1", pageScale="1", pageWidth="850", pageHeight="1100", math="0", shadow="0"
        )
        root = etree.SubElement(mxGraphModel, "root")

        # Add default cells
        etree.SubElement(root, "mxCell", id="0")
        etree.SubElement(root, "mxCell", id="1", parent="0")

        # Layout nodes
        x_spacing = 180
        y_spacing = 100
        x_pos = 50
        y_pos = 50

        node_positions: Dict[str, Tuple[int, int]] = {}

        if direction == "right":
            for i, (node_id, label) in enumerate(nodes.items()):
                node_positions[node_id] = (x_pos, y_pos + i * y_spacing)
        else:  # down (default)
            for i, (node_id, label) in enumerate(nodes.items()):
                node_positions[node_id] = (x_pos + i * x_spacing, y_pos)

        # Add node cells
        for node_id, label in nodes.items():
            x, y = node_positions[node_id]
            cell = etree.SubElement(
                root, "mxCell", id=node_id, value=label, style="rounded=1;whiteSpace=wrap;html=1;", vertex="1", parent="1"
            )
            geom = etree.SubElement(cell, "mxGeometry", x=str(x), y=str(y), width="120", height="60", as_="geometry")

        # Add edge cells
        for i, (source, target, label) in enumerate(edges):
            edge_id = f"edge_{i}"
            edge_label = label or ""
            cell = etree.SubElement(
                root, "mxCell", id=edge_id, value=edge_label, style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;",
                edge="1", parent="1", source=source, target=target
            )
            geom = etree.SubElement(cell, "mxGeometry", relative="1", as_="geometry")

        return etree.tostring(mxfile, xml_declaration=True, encoding="UTF-8", pretty_print=True)

    def _convert_drawio_to_svg(self) -> bool:
        """Convert DrawIO to SVG (basic implementation)."""
        try:
            tree = etree.parse(str(self.input_file))
            root = tree.getroot()

            # Create SVG
            svg = etree.Element("svg", xmlns="http://www.w3.org/2000/svg", width="800", height="600")

            # Extract cells and convert to SVG shapes
            diagrams = root.findall("diagram")
            for diagram in diagrams:
                mxGraphModel = diagram.find("mxGraphModel")
                if mxGraphModel is not None:
                    root_elem = mxGraphModel.find("root")
                    if root_elem is not None:
                        for cell in root_elem.findall("mxCell"):
                            self._cell_to_svg(cell, svg)

            # Write SVG
            svg_tree = etree.ElementTree(svg)
            svg_tree.write(str(self.output_file), xml_declaration=True, encoding="UTF-8", pretty_print=True)

            print(
                f"{COLOR_GREEN}✓ Converted {self.input_file} → {self.output_file}{COLOR_RESET}"
            )
            return True
        except Exception as e:
            print(f"{COLOR_RED}Error: {e}{COLOR_RESET}")
            return False

    def _cell_to_svg(self, cell: etree._Element, svg: etree._Element) -> None:
        """Convert a DrawIO cell to SVG element."""
        edge = cell.get("edge") == "1"
        value = cell.get("value", "")
        style = cell.get("style", "")
        mxGeometry = cell.find("mxGeometry")

        if mxGeometry is None:
            return

        x = float(mxGeometry.get("x", 0))
        y = float(mxGeometry.get("y", 0))
        w = float(mxGeometry.get("width", 0))
        h = float(mxGeometry.get("height", 0))

        if edge:
            # Draw line for edges (simplified)
            line = etree.SubElement(
                svg, "line", x1="0", y1="0", x2="100", y2="100", stroke="black", stroke_width="2"
            )
        else:
            if w > 0 and h > 0:
                # Draw rectangle
                rect = etree.SubElement(
                    svg, "rect", x=str(int(x)), y=str(int(y)), width=str(int(w)), height=str(int(h)),
                    fill="white", stroke="black", stroke_width="1"
                )
                # Add text
                if value:
                    text = etree.SubElement(
                        svg, "text", x=str(int(x + w / 2)), y=str(int(y + h / 2)),
                        text_anchor="middle", dominant_baseline="middle", font_size="12"
                    )
                    text.text = value

    def _convert_drawio_to_mermaid(self) -> bool:
        """Convert DrawIO to Mermaid syntax."""
        try:
            tree = etree.parse(str(self.input_file))
            root = tree.getroot()

            mermaid_lines = ["graph TD"]
            nodes: Dict[str, str] = {}
            edges: List[Tuple[str, str, Optional[str]]] = []

            diagrams = root.findall("diagram")
            for diagram in diagrams:
                mxGraphModel = diagram.find("mxGraphModel")
                if mxGraphModel is not None:
                    root_elem = mxGraphModel.find("root")
                    if root_elem is not None:
                        for cell in root_elem.findall("mxCell"):
                            cell_id = cell.get("id", "")
                            value = cell.get("value", "")
                            edge = cell.get("edge") == "1"

                            if not edge and cell_id not in ["0", "1"]:
                                nodes[cell_id] = value or cell_id

                            if edge:
                                source = cell.get("source")
                                target = cell.get("target")
                                label = value
                                if source and target:
                                    edges.append((source, target, label or None))

            # Format as Mermaid
            for node_id, label in nodes.items():
                if label:
                    mermaid_lines.append(f'    {node_id}["{label}"]')
                else:
                    mermaid_lines.append(f"    {node_id}")

            for source, target, label in edges:
                if label:
                    mermaid_lines.append(f'    {source} -->|{label}| {target}')
                else:
                    mermaid_lines.append(f"    {source} --> {target}")

            with open(self.output_file, "w") as f:
                f.write("\n".join(mermaid_lines) + "\n")

            print(
                f"{COLOR_GREEN}✓ Converted {self.input_file} → {self.output_file}{COLOR_RESET}"
            )
            return True
        except Exception as e:
            print(f"{COLOR_RED}Error: {e}{COLOR_RESET}")
            return False


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Convert between diagram formats (.mermaid, .puml, .drawio, .svg)"
    )
    parser.add_argument("input", help="Input file")
    parser.add_argument("output", help="Output file")
    args = parser.parse_args()

    converter = DrawioConverter(args.input, args.output)
    success = converter.convert()
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
