#!/usr/bin/env python3
"""
Create a diagram from a CSV file.

Usage: python create_from_csv.py <data.csv> --output <diagram.drawio> [--type flowchart|orgchart|erd|network]

CSV formats:

Orgchart: name,title,reports_to
  Example:
    name,title,reports_to
    Alice,CEO,
    Bob,VP Engineering,Alice
    Carol,Engineer,Bob

Flowchart: step,type,next_step,label
  Example:
    step,type,next_step,label
    start,oval,,
    process1,rect,decision1,Calculate
    decision1,diamond,process2,Result?

ERD: entity,attribute,type,relationship_to,cardinality
  Example:
    entity,attribute,type,relationship_to,cardinality
    User,id,PK,Order,1:N
    User,name,string,,
    Order,id,PK,User,N:1

Network: device,type,connects_to,label
  Example:
    device,type,connects_to,label
    Router,device,Switch1,1Gbps
    Switch1,device,PC1,100Mbps
"""

import argparse
import csv
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from lxml import etree

# ANSI color codes
COLOR_GREEN = "\033[92m"
COLOR_RED = "\033[91m"
COLOR_RESET = "\033[0m"


class DiagramFromCSV:
    """Create diagrams from CSV data."""

    def __init__(self, csv_file: str, output_file: str, diagram_type: str) -> None:
        """Initialize diagram creator."""
        self.csv_file = Path(csv_file)
        self.output_file = Path(output_file)
        self.diagram_type = diagram_type
        self.data: List[Dict] = []
        self.positions: Dict[str, Tuple[float, float]] = {}

    def load_csv(self) -> bool:
        """Load CSV file."""
        if not self.csv_file.exists():
            print(f"{COLOR_RED}Error: CSV file not found{COLOR_RESET}")
            return False

        try:
            with open(self.csv_file, "r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                self.data = list(reader)
            return True
        except Exception as e:
            print(f"{COLOR_RED}Error reading CSV: {e}{COLOR_RESET}")
            return False

    def create(self) -> bool:
        """Create diagram based on type."""
        try:
            if self.diagram_type == "orgchart":
                self._create_orgchart()
            elif self.diagram_type == "flowchart":
                self._create_flowchart()
            elif self.diagram_type == "erd":
                self._create_erd()
            elif self.diagram_type == "network":
                self._create_network()
            else:
                print(f"{COLOR_RED}Unknown diagram type: {self.diagram_type}{COLOR_RESET}")
                return False

            return self._save_xml()
        except Exception as e:
            print(f"{COLOR_RED}Error creating diagram: {e}{COLOR_RESET}")
            return False

    def _create_orgchart(self) -> None:
        """Create organizational chart from CSV."""
        mxfile = etree.Element("mxfile", host="Sketchy", modified="0", version="1.0")
        diagram = etree.SubElement(mxfile, "diagram", name="Org Chart", id="page-1")
        mxGraphModel = self._create_graph_model(diagram)
        root = mxGraphModel.find("root")

        # Build parent-child relationships
        nodes: Dict[str, str] = {}  # name -> row
        parent_map: Dict[str, str] = {}

        for row in self.data:
            name = row.get("name", "").strip()
            if name:
                nodes[name] = row
                reports_to = row.get("reports_to", "").strip()
                if reports_to:
                    parent_map[name] = reports_to

        # Position nodes hierarchically
        self._position_tree(nodes, parent_map)

        # Add cells
        node_counter = 2
        for name, row in nodes.items():
            x, y = self.positions.get(name, (50, 50))
            title = row.get("title", "")
            label = f"{name}\n{title}" if title else name

            cell = etree.SubElement(
                root, "mxCell",
                id=f"node_{node_counter}",
                value=label,
                style="rounded=1;whiteSpace=wrap;html=1;fillColor=#d4e6f1;",
                vertex="1",
                parent="1"
            )
            etree.SubElement(cell, "mxGeometry", x=str(int(x)), y=str(int(y)), width="120", height="80", as_="geometry")
            node_counter += 1

        # Add edges
        edge_counter = 0
        for name, parent in parent_map.items():
            cell = etree.SubElement(
                root, "mxCell",
                id=f"edge_{edge_counter}",
                style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;",
                edge="1",
                parent="1",
                source=f"node_{list(nodes.keys()).index(parent) + 2}",
                target=f"node_{list(nodes.keys()).index(name) + 2}"
            )
            etree.SubElement(cell, "mxGeometry", relative="1", as_="geometry")
            edge_counter += 1

        self.mxfile = mxfile

    def _create_flowchart(self) -> None:
        """Create flowchart from CSV."""
        mxfile = etree.Element("mxfile", host="Sketchy", modified="0", version="1.0")
        diagram = etree.SubElement(mxfile, "diagram", name="Flowchart", id="page-1")
        mxGraphModel = self._create_graph_model(diagram)
        root = mxGraphModel.find("root")

        # Create nodes
        node_map: Dict[str, int] = {}
        node_counter = 2

        for row in self.data:
            step = row.get("step", "").strip()
            if not step:
                continue

            shape_type = row.get("type", "rect").lower()
            label = row.get("label", step)
            x = (node_counter - 2) * 150 + 50
            y = 50

            node_map[step] = node_counter

            # Style based on type
            if shape_type == "oval":
                style = "ellipse;whiteSpace=wrap;html=1;fillColor=#d5f4d5;"
                width, height = "100", "60"
            elif shape_type == "diamond":
                style = "rhombus;whiteSpace=wrap;html=1;fillColor=#fff2cc;"
                width, height = "100", "100"
            else:  # rect
                style = "rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;"
                width, height = "120", "60"

            cell = etree.SubElement(
                root, "mxCell",
                id=f"node_{node_counter}",
                value=label,
                style=style,
                vertex="1",
                parent="1"
            )
            etree.SubElement(cell, "mxGeometry", x=str(x), y=str(y), width=width, height=height, as_="geometry")
            node_counter += 1

        # Create edges
        edge_counter = 0
        for row in self.data:
            step = row.get("step", "").strip()
            next_step = row.get("next_step", "").strip()
            if step and next_step and step in node_map and next_step in node_map:
                label = row.get("label", "")
                cell = etree.SubElement(
                    root, "mxCell",
                    id=f"edge_{edge_counter}",
                    value=label,
                    style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;",
                    edge="1",
                    parent="1",
                    source=f"node_{node_map[step]}",
                    target=f"node_{node_map[next_step]}"
                )
                etree.SubElement(cell, "mxGeometry", relative="1", as_="geometry")
                edge_counter += 1

        self.mxfile = mxfile

    def _create_erd(self) -> None:
        """Create Entity-Relationship Diagram from CSV."""
        mxfile = etree.Element("mxfile", host="Sketchy", modified="0", version="1.0")
        diagram = etree.SubElement(mxfile, "diagram", name="ERD", id="page-1")
        mxGraphModel = self._create_graph_model(diagram)
        root = mxGraphModel.find("root")

        # Group by entity
        entities: Dict[str, List[Dict]] = {}
        for row in self.data:
            entity = row.get("entity", "").strip()
            if entity:
                if entity not in entities:
                    entities[entity] = []
                entities[entity].append(row)

        # Position entities
        node_counter = 2
        entity_map: Dict[str, int] = {}
        entity_positions: Dict[str, Tuple[float, float]] = {}

        for i, entity in enumerate(sorted(entities.keys())):
            x = 50 + i * 200
            y = 50
            entity_positions[entity] = (x, y)
            entity_map[entity] = node_counter

            # Create entity box
            attributes = entities[entity]
            attr_text = entity + "\n---\n"
            attr_text += "\n".join(f"{a.get('attribute', '')} ({a.get('type', '')})" for a in attributes if a.get("attribute"))

            cell = etree.SubElement(
                root, "mxCell",
                id=f"node_{node_counter}",
                value=attr_text,
                style="shape=rectangle;whiteSpace=wrap;html=1;fillColor=#e1d5e7;align=left;",
                vertex="1",
                parent="1"
            )
            etree.SubElement(cell, "mxGeometry", x=str(int(x)), y=str(int(y)), width="150", height="120", as_="geometry")
            node_counter += 1

        # Add relationships
        edge_counter = 0
        for row in self.data:
            entity = row.get("entity", "").strip()
            rel_to = row.get("relationship_to", "").strip()
            cardinality = row.get("cardinality", "").strip()
            if entity and rel_to and entity in entity_map and rel_to in entity_map:
                cell = etree.SubElement(
                    root, "mxCell",
                    id=f"edge_{edge_counter}",
                    value=cardinality,
                    style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;",
                    edge="1",
                    parent="1",
                    source=f"node_{entity_map[entity]}",
                    target=f"node_{entity_map[rel_to]}"
                )
                etree.SubElement(cell, "mxGeometry", relative="1", as_="geometry")
                edge_counter += 1

        self.mxfile = mxfile

    def _create_network(self) -> None:
        """Create network diagram from CSV."""
        mxfile = etree.Element("mxfile", host="Sketchy", modified="0", version="1.0")
        diagram = etree.SubElement(mxfile, "diagram", name="Network", id="page-1")
        mxGraphModel = self._create_graph_model(diagram)
        root = mxGraphModel.find("root")

        # Create devices
        devices: Dict[str, str] = {}
        node_counter = 2
        device_map: Dict[str, int] = {}

        for row in self.data:
            device = row.get("device", "").strip()
            if device and device not in devices:
                devices[device] = row.get("type", "device")
                device_map[device] = node_counter

                x = (node_counter - 2) * 150 + 50
                y = 50

                icon = "🖥️" if row.get("type") == "device" else "🔌"
                cell = etree.SubElement(
                    root, "mxCell",
                    id=f"node_{node_counter}",
                    value=f"{icon} {device}",
                    style="shape=rectangle;whiteSpace=wrap;html=1;fillColor=#cce5ff;",
                    vertex="1",
                    parent="1"
                )
                etree.SubElement(cell, "mxGeometry", x=str(x), y=str(y), width="120", height="60", as_="geometry")
                node_counter += 1

        # Create connections
        edge_counter = 0
        for row in self.data:
            device = row.get("device", "").strip()
            connects_to = row.get("connects_to", "").strip()
            label = row.get("label", "")
            if device and connects_to and device in device_map and connects_to in device_map:
                cell = etree.SubElement(
                    root, "mxCell",
                    id=f"edge_{edge_counter}",
                    value=label,
                    style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;",
                    edge="1",
                    parent="1",
                    source=f"node_{device_map[device]}",
                    target=f"node_{device_map[connects_to]}"
                )
                etree.SubElement(cell, "mxGeometry", relative="1", as_="geometry")
                edge_counter += 1

        self.mxfile = mxfile

    @staticmethod
    def _create_graph_model(diagram: etree._Element) -> etree._Element:
        """Create and return mxGraphModel element."""
        mxGraphModel = etree.SubElement(
            diagram, "mxGraphModel",
            dx="0", dy="0", grid="1", gridSize="10", guides="1",
            tooltips="1", connect="1", arrows="1", fold="1", page="1",
            pageScale="1", pageWidth="850", pageHeight="1100",
            math="0", shadow="0"
        )
        root = etree.SubElement(mxGraphModel, "root")
        etree.SubElement(root, "mxCell", id="0")
        etree.SubElement(root, "mxCell", id="1", parent="0")
        return mxGraphModel

    def _position_tree(self, nodes: Dict[str, str], parent_map: Dict[str, str]) -> None:
        """Position nodes in a tree layout."""
        # Find roots
        all_children = set(parent_map.keys())
        roots = [name for name in nodes if name not in all_children]

        if not roots:
            roots = [next(iter(nodes))]

        # BFS positioning
        y_offset = 50
        level = 0
        current_level = roots
        x_pos = 50

        while current_level:
            x_pos = 50
            for i, node in enumerate(current_level):
                self.positions[node] = (x_pos, y_offset)
                x_pos += 200
            level += 1
            y_offset += 120

            next_level = []
            for node in current_level:
                for child, parent in parent_map.items():
                    if parent == node and child not in self.positions:
                        next_level.append(child)
            current_level = next_level

    def _save_xml(self) -> bool:
        """Save the diagram as XML."""
        try:
            tree = etree.ElementTree(self.mxfile)
            tree.write(
                str(self.output_file),
                xml_declaration=True,
                encoding="UTF-8",
                pretty_print=True
            )
            return True
        except Exception as e:
            print(f"{COLOR_RED}Error saving file: {e}{COLOR_RESET}")
            return False


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Create a diagram from a CSV file."
    )
    parser.add_argument("csv_file", help="Input CSV file")
    parser.add_argument("--output", required=True, help="Output .drawio file")
    parser.add_argument(
        "--type",
        choices=["orgchart", "flowchart", "erd", "network"],
        default="orgchart",
        help="Diagram type (default: orgchart)"
    )
    args = parser.parse_args()

    creator = DiagramFromCSV(args.csv_file, args.output, args.type)
    if not creator.load_csv():
        return 1

    if not creator.create():
        return 1

    print(f"{COLOR_GREEN}✓ Created {args.type} diagram: {args.output}{COLOR_RESET}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
