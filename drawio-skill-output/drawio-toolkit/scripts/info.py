#!/usr/bin/env python3
"""
Print a summary of a .drawio file.

Usage: python info.py <file.drawio>

Output includes:
- Number of pages
- Number of shapes
- Number of edges
- List of shape labels
- List of connections (source → target)
- Containers/groups
"""

import argparse
import sys
from pathlib import Path
from typing import Dict, List, Set
from lxml import etree

# ANSI color codes
COLOR_GREEN = "\033[92m"
COLOR_BLUE = "\033[94m"
COLOR_CYAN = "\033[96m"
COLOR_BOLD = "\033[1m"
COLOR_RESET = "\033[0m"


class DrawioInfo:
    """Extracts and displays information about a DrawIO file."""

    def __init__(self, file_path: str) -> None:
        """Initialize info extractor."""
        self.file_path = Path(file_path)
        self.tree: etree._ElementTree | None = None
        self.root: etree._Element | None = None

    def load(self) -> bool:
        """Load the DrawIO file."""
        if not self.file_path.exists():
            print(f"Error: File not found: {self.file_path}")
            return False

        try:
            self.tree = etree.parse(str(self.file_path))
            self.root = self.tree.getroot()
            return True
        except Exception as e:
            print(f"Error loading file: {e}")
            return False

    def print_info(self) -> None:
        """Print file information."""
        print(f"\n{COLOR_BOLD}Draw.io File Information{COLOR_RESET}")
        print(f"File: {self.file_path}")
        print(f"Size: {self.file_path.stat().st_size} bytes\n")

        diagrams = self.root.findall("diagram")
        print(f"{COLOR_BOLD}Diagrams: {len(diagrams)}{COLOR_RESET}\n")

        for page_num, diagram in enumerate(diagrams, 1):
            self._print_diagram_info(diagram, page_num)

    def _print_diagram_info(self, diagram: etree._Element, page_num: int) -> None:
        """Print information for a single diagram/page."""
        name = diagram.get("name", f"Page {page_num}")
        print(f"{COLOR_CYAN}Page {page_num}: {name}{COLOR_RESET}")

        mxGraphModel = diagram.find("mxGraphModel")
        if mxGraphModel is None:
            print("  (empty)\n")
            return

        root_elem = mxGraphModel.find("root")
        if root_elem is None:
            print("  (empty)\n")
            return

        # Count shapes and edges
        cells = root_elem.findall("mxCell")
        shapes: List[Dict] = []
        edges: List[Dict] = []
        containers: List[Dict] = []

        for cell in cells:
            cell_id = cell.get("id", "")
            if cell_id in ["0", "1"]:
                continue

            edge = cell.get("edge") == "1"
            value = cell.get("value", "")
            style = cell.get("style", "")

            if edge:
                source = cell.get("source", "")
                target = cell.get("target", "")
                edges.append({
                    "id": cell_id,
                    "source": source,
                    "target": target,
                    "label": value
                })
            else:
                # Check if it's a container
                is_container = "container=1" in style or cell.get("parent") in ["0", "1"]
                shape_type = "container" if is_container else "shape"

                shapes.append({
                    "id": cell_id,
                    "label": value or "(unlabeled)",
                    "type": shape_type,
                    "style": style
                })

                if is_container:
                    containers.append({
                        "id": cell_id,
                        "label": value
                    })

        # Print statistics
        print(f"  Shapes: {len(shapes)}")
        print(f"  Edges: {len(edges)}")
        if containers:
            print(f"  Containers: {len(containers)}")
        print()

        # Print shape labels
        if shapes:
            print(f"  {COLOR_BLUE}Shapes:{COLOR_RESET}")
            for shape in shapes[:20]:  # Limit to first 20
                marker = "📦" if shape["type"] == "container" else "□"
                print(f"    {marker} {shape['label']}")
            if len(shapes) > 20:
                print(f"    ... and {len(shapes) - 20} more")
            print()

        # Print connections
        if edges:
            print(f"  {COLOR_BLUE}Connections:{COLOR_RESET}")
            for edge in edges[:15]:  # Limit to first 15
                source_label = self._get_label(root_elem, edge["source"])
                target_label = self._get_label(root_elem, edge["target"])
                label_text = f' |{edge["label"]}|' if edge["label"] else ""
                print(f"    {source_label} → {target_label}{label_text}")
            if len(edges) > 15:
                print(f"    ... and {len(edges) - 15} more")
            print()

        # Print containers
        if containers:
            print(f"  {COLOR_BLUE}Containers:{COLOR_RESET}")
            for container in containers:
                print(f"    📦 {container['label'] or '(unnamed)'}")
            print()

    def _get_label(self, root: etree._Element, cell_id: str) -> str:
        """Get the label of a cell by ID."""
        for cell in root.findall("mxCell"):
            if cell.get("id") == cell_id:
                label = cell.get("value", "")
                return label or cell_id
        return cell_id


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Print information about a .drawio file."
    )
    parser.add_argument("file", help="Path to .drawio file")
    args = parser.parse_args()

    info = DrawioInfo(args.file)
    if not info.load():
        return 1

    info.print_info()
    return 0


if __name__ == "__main__":
    sys.exit(main())
