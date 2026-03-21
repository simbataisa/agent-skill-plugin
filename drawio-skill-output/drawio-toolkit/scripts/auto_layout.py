#!/usr/bin/env python3
"""
Re-layout an existing .drawio file using various algorithms.

Usage: python auto_layout.py <file.drawio> [--layout tree|grid|lr|radial] [--spacing 80] [--output <out.drawio>]

Algorithms:
- tree: BFS from root nodes, arrange in levels top-to-bottom
- grid: arrange all nodes in a grid pattern
- lr: left-to-right tree layout
- radial: central node with others in concentric circles
"""

import argparse
import math
import sys
from collections import defaultdict, deque
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple
from lxml import etree

# ANSI color codes
COLOR_GREEN = "\033[92m"
COLOR_RED = "\033[91m"
COLOR_RESET = "\033[0m"


class DrawioAutoLayout:
    """Auto-layout for DrawIO diagrams."""

    def __init__(self, file_path: str, output_file: Optional[str] = None) -> None:
        """Initialize auto-layout."""
        self.file_path = Path(file_path)
        self.output_file = Path(output_file or file_path)
        self.tree: etree._ElementTree | None = None
        self.root: etree._Element | None = None
        self.cells: Dict[str, etree._Element] = {}
        self.graph: Dict[str, List[str]] = defaultdict(list)
        self.reverse_graph: Dict[str, List[str]] = defaultdict(list)
        self.positions: Dict[str, Tuple[float, float]] = {}

    def load(self) -> bool:
        """Load the DrawIO file."""
        try:
            self.tree = etree.parse(str(self.file_path))
            self.root = self.tree.getroot()
            self._index_cells()
            self._build_graph()
            return True
        except Exception as e:
            print(f"{COLOR_RED}Error loading file: {e}{COLOR_RESET}")
            return False

    def _index_cells(self) -> None:
        """Index all cells by ID."""
        diagrams = self.root.findall("diagram")
        for diagram in diagrams:
            mxGraphModel = diagram.find("mxGraphModel")
            if mxGraphModel is not None:
                root_elem = mxGraphModel.find("root")
                if root_elem is not None:
                    for cell in root_elem.findall("mxCell"):
                        cell_id = cell.get("id")
                        if cell_id:
                            self.cells[cell_id] = cell

    def _build_graph(self) -> None:
        """Build adjacency list from edges."""
        for cell_id, cell in self.cells.items():
            if cell.get("edge") == "1":
                source = cell.get("source")
                target = cell.get("target")
                if source and target:
                    self.graph[source].append(target)
                    self.reverse_graph[target].append(source)

    def apply_layout(self, layout_type: str, spacing: int) -> bool:
        """Apply layout algorithm."""
        try:
            if layout_type == "tree":
                self.positions = self._layout_tree(spacing)
            elif layout_type == "grid":
                self.positions = self._layout_grid(spacing)
            elif layout_type == "lr":
                self.positions = self._layout_lr(spacing)
            elif layout_type == "radial":
                self.positions = self._layout_radial(spacing)
            else:
                print(f"{COLOR_RED}Unknown layout: {layout_type}{COLOR_RESET}")
                return False

            self._apply_positions()
            return True
        except Exception as e:
            print(f"{COLOR_RED}Error applying layout: {e}{COLOR_RESET}")
            return False

    def _layout_tree(self, spacing: int) -> Dict[str, Tuple[float, float]]:
        """Tree layout: BFS from root nodes."""
        positions: Dict[str, Tuple[float, float]] = {}

        # Find root nodes (no incoming edges)
        roots = [cid for cid in self.cells if cid not in self.reverse_graph or cid in ["0", "1"]]
        roots = [cid for cid in roots if cid not in ["0", "1"]]

        if not roots:
            # No roots, pick arbitrary node
            roots = [next(iter(self.cells))]

        # BFS to assign levels
        levels: Dict[str, int] = {}
        visited: Set[str] = set()
        queue = deque((node, 0) for node in roots)

        while queue:
            node, level = queue.popleft()
            if node in visited or node in ["0", "1"]:
                continue
            visited.add(node)
            levels[node] = level
            for neighbor in self.graph.get(node, []):
                if neighbor not in visited:
                    queue.append((neighbor, level + 1))

        # Position nodes by level
        level_counts: Dict[int, int] = defaultdict(int)
        level_positions: Dict[int, List[str]] = defaultdict(list)

        for node, level in levels.items():
            level_positions[level].append(node)

        y_spacing = spacing
        for level, nodes in sorted(level_positions.items()):
            x_start = 50
            x_spacing = spacing + 100
            for i, node in enumerate(nodes):
                x = x_start + i * x_spacing
                y = 50 + level * y_spacing
                positions[node] = (x, y)

        # Position unvisited nodes at bottom
        for node in self.cells:
            if node not in positions and node not in ["0", "1"]:
                positions[node] = (50, 50 + (max(levels.values(), default=0) + 1) * y_spacing)

        return positions

    def _layout_grid(self, spacing: int) -> Dict[str, Tuple[float, float]]:
        """Grid layout: arrange nodes in a grid pattern."""
        positions: Dict[str, Tuple[float, float]] = {}
        nodes = [cid for cid in self.cells if cid not in ["0", "1"]]
        cols = max(1, int(math.ceil(math.sqrt(len(nodes)))))

        for i, node in enumerate(nodes):
            row = i // cols
            col = i % cols
            x = 50 + col * (spacing + 120)
            y = 50 + row * (spacing + 80)
            positions[node] = (x, y)

        return positions

    def _layout_lr(self, spacing: int) -> Dict[str, Tuple[float, float]]:
        """Left-to-right tree layout."""
        positions: Dict[str, Tuple[float, float]] = {}

        # Find root nodes
        roots = [cid for cid in self.cells if cid not in self.reverse_graph and cid not in ["0", "1"]]
        if not roots:
            roots = [next(iter(n for n in self.cells if n not in ["0", "1"]))]

        # BFS to assign levels
        levels: Dict[str, int] = {}
        visited: Set[str] = set()
        queue = deque((node, 0) for node in roots)

        while queue:
            node, level = queue.popleft()
            if node in visited or node in ["0", "1"]:
                continue
            visited.add(node)
            levels[node] = level
            for neighbor in self.graph.get(node, []):
                if neighbor not in visited:
                    queue.append((neighbor, level + 1))

        # Position nodes left-to-right by level
        level_positions: Dict[int, List[str]] = defaultdict(list)
        for node, level in levels.items():
            level_positions[level].append(node)

        x_spacing = spacing + 120
        for level, nodes in sorted(level_positions.items()):
            y_start = 50
            y_spacing = spacing + 80
            for i, node in enumerate(nodes):
                x = 50 + level * x_spacing
                y = y_start + i * y_spacing
                positions[node] = (x, y)

        return positions

    def _layout_radial(self, spacing: int) -> Dict[str, Tuple[float, float]]:
        """Radial layout: central node with others in concentric circles."""
        positions: Dict[str, Tuple[float, float]] = {}
        nodes = [cid for cid in self.cells if cid not in ["0", "1"]]

        if not nodes:
            return positions

        # Use first node as center
        center_node = nodes[0]
        center_x, center_y = 400, 300

        positions[center_node] = (center_x, center_y)

        # Arrange others in circles
        remaining = nodes[1:]
        radius = spacing + 100

        for i, node in enumerate(remaining):
            angle = (2 * math.pi * i) / len(remaining)
            x = center_x + radius * math.cos(angle)
            y = center_y + radius * math.sin(angle)
            positions[node] = (x, y)

        return positions

    def _apply_positions(self) -> None:
        """Apply calculated positions to cells."""
        for node_id, (x, y) in self.positions.items():
            cell = self.cells.get(node_id)
            if cell is None:
                continue

            mxGeometry = cell.find("mxGeometry")
            if mxGeometry is not None:
                mxGeometry.set("x", str(int(x)))
                mxGeometry.set("y", str(int(y)))

    def save(self) -> bool:
        """Save the modified file."""
        try:
            self.tree.write(
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
        description="Auto-layout a .drawio file using various algorithms."
    )
    parser.add_argument("file", help="Input .drawio file")
    parser.add_argument(
        "--layout",
        choices=["tree", "grid", "lr", "radial"],
        default="tree",
        help="Layout algorithm (default: tree)"
    )
    parser.add_argument(
        "--spacing",
        type=int,
        default=80,
        help="Spacing between nodes in pixels (default: 80)"
    )
    parser.add_argument(
        "--output",
        help="Output file (default: overwrite input)"
    )
    args = parser.parse_args()

    layout = DrawioAutoLayout(args.file, args.output)
    if not layout.load():
        return 1

    if not layout.apply_layout(args.layout, args.spacing):
        return 1

    if not layout.save():
        return 1

    output_path = args.output or args.file
    print(f"{COLOR_GREEN}✓ Layout applied and saved to {output_path}{COLOR_RESET}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
