#!/usr/bin/env python3
"""
Merge multiple .drawio files into one.

Usage: python merge.py <file1.drawio> <file2.drawio> ... --output <merged.drawio>

Options:
- --as-pages: each input file becomes a separate page/tab in the output
- --side-by-side: place all diagrams on one page, arranged left to right
- --stack: place all diagrams on one page, stacked vertically
"""

import argparse
import sys
from pathlib import Path
from typing import Dict, List, Tuple
from lxml import etree

# ANSI color codes
COLOR_GREEN = "\033[92m"
COLOR_RED = "\033[91m"
COLOR_RESET = "\033[0m"


class DrawioMerger:
    """Merge multiple DrawIO files."""

    def __init__(self, input_files: List[str], output_file: str, mode: str = "as-pages") -> None:
        """Initialize merger."""
        self.input_files = [Path(f) for f in input_files]
        self.output_file = Path(output_file)
        self.mode = mode
        self.trees: List[etree._ElementTree] = []

    def load_files(self) -> bool:
        """Load all input files."""
        for file_path in self.input_files:
            if not file_path.exists():
                print(f"{COLOR_RED}Error: File not found: {file_path}{COLOR_RESET}")
                return False
            try:
                tree = etree.parse(str(file_path))
                self.trees.append(tree)
            except Exception as e:
                print(f"{COLOR_RED}Error loading {file_path}: {e}{COLOR_RESET}")
                return False

        return True

    def merge(self) -> bool:
        """Merge files based on selected mode."""
        try:
            if self.mode == "as-pages":
                self._merge_as_pages()
            elif self.mode == "side-by-side":
                self._merge_side_by_side()
            elif self.mode == "stack":
                self._merge_stack()
            return True
        except Exception as e:
            print(f"{COLOR_RED}Error during merge: {e}{COLOR_RESET}")
            return False

    def _merge_as_pages(self) -> None:
        """Each input becomes a separate page."""
        # Create base mxfile
        mxfile = etree.Element("mxfile", host="Sketchy", modified="0", version="1.0")

        page_num = 1
        for file_idx, tree in enumerate(self.trees):
            root = tree.getroot()
            diagrams = root.findall("diagram")

            for diagram in diagrams:
                # Clone diagram
                new_diagram = etree.Element("diagram")
                new_diagram.set("name", f"Page-{page_num}")
                new_diagram.set("id", f"page-{page_num}")

                # Copy mxGraphModel
                old_model = diagram.find("mxGraphModel")
                if old_model is not None:
                    new_model = etree.fromstring(etree.tostring(old_model))
                    new_diagram.append(new_model)

                mxfile.append(new_diagram)
                page_num += 1

        # Write output
        output_tree = etree.ElementTree(mxfile)
        output_tree.write(
            str(self.output_file),
            xml_declaration=True,
            encoding="UTF-8",
            pretty_print=True
        )

    def _merge_side_by_side(self) -> None:
        """Place all diagrams on one page, left to right."""
        mxfile = etree.Element("mxfile", host="Sketchy", modified="0", version="1.0")
        diagram = etree.SubElement(mxfile, "diagram", name="Page-1", id="page-1")
        mxGraphModel = etree.SubElement(
            diagram, "mxGraphModel",
            dx="0", dy="0", grid="1", gridSize="10", guides="1",
            tooltips="1", connect="1", arrows="1", fold="1", page="1",
            pageScale="1", pageWidth="850", pageHeight="1100",
            math="0", shadow="0"
        )
        root = etree.SubElement(mxGraphModel, "root")

        # Add default cells
        etree.SubElement(root, "mxCell", id="0")
        etree.SubElement(root, "mxCell", id="1", parent="0")

        x_offset = 50
        max_height = 0

        for tree in self.trees:
            old_root = tree.getroot()
            diagrams = old_root.findall("diagram")

            for diagram_elem in diagrams:
                old_model = diagram_elem.find("mxGraphModel")
                if old_model is not None:
                    old_root_elem = old_model.find("root")
                    if old_root_elem is not None:
                        # Copy cells with offset
                        offset_map = self._copy_cells_with_offset(
                            old_root_elem, root, x_offset, 50
                        )
                        # Calculate bounds
                        bounds = self._get_bounds(old_root_elem)
                        if bounds:
                            _, _, max_x, max_y = bounds
                            x_offset += max_x + 50
                            max_height = max(max_height, max_y)

        output_tree = etree.ElementTree(mxfile)
        output_tree.write(
            str(self.output_file),
            xml_declaration=True,
            encoding="UTF-8",
            pretty_print=True
        )

    def _merge_stack(self) -> None:
        """Place all diagrams on one page, stacked vertically."""
        mxfile = etree.Element("mxfile", host="Sketchy", modified="0", version="1.0")
        diagram = etree.SubElement(mxfile, "diagram", name="Page-1", id="page-1")
        mxGraphModel = etree.SubElement(
            diagram, "mxGraphModel",
            dx="0", dy="0", grid="1", gridSize="10", guides="1",
            tooltips="1", connect="1", arrows="1", fold="1", page="1",
            pageScale="1", pageWidth="850", pageHeight="1100",
            math="0", shadow="0"
        )
        root = etree.SubElement(mxGraphModel, "root")

        # Add default cells
        etree.SubElement(root, "mxCell", id="0")
        etree.SubElement(root, "mxCell", id="1", parent="0")

        y_offset = 50

        for tree in self.trees:
            old_root = tree.getroot()
            diagrams = old_root.findall("diagram")

            for diagram_elem in diagrams:
                old_model = diagram_elem.find("mxGraphModel")
                if old_model is not None:
                    old_root_elem = old_model.find("root")
                    if old_root_elem is not None:
                        # Copy cells with offset
                        self._copy_cells_with_offset(
                            old_root_elem, root, 50, y_offset
                        )
                        # Calculate bounds
                        bounds = self._get_bounds(old_root_elem)
                        if bounds:
                            _, _, max_x, max_y = bounds
                            y_offset += max_y + 50

        output_tree = etree.ElementTree(mxfile)
        output_tree.write(
            str(self.output_file),
            xml_declaration=True,
            encoding="UTF-8",
            pretty_print=True
        )

    def _copy_cells_with_offset(
        self, source_root: etree._Element, target_root: etree._Element,
        x_offset: float, y_offset: float
    ) -> Dict[str, str]:
        """Copy cells from source to target with coordinate offset."""
        id_map: Dict[str, str] = {"0": "0", "1": "1"}
        cell_counter = 2

        # First pass: copy cells and build ID map
        for cell in source_root.findall("mxCell"):
            old_id = cell.get("id", "")
            if old_id in ["0", "1"]:
                continue

            new_id = f"cell_{cell_counter}"
            cell_counter += 1
            id_map[old_id] = new_id

            # Create new cell
            new_cell = etree.SubElement(
                target_root, "mxCell",
                id=new_id,
                parent="1"
            )

            # Copy attributes except id and geometric changes
            for attr in ["value", "style", "edge", "vertex"]:
                if cell.get(attr):
                    new_cell.set(attr, cell.get(attr))

            # Copy and offset geometry
            mxGeometry = cell.find("mxGeometry")
            if mxGeometry is not None:
                new_geom = etree.SubElement(new_cell, "mxGeometry", as_="geometry")
                x = float(mxGeometry.get("x", 0))
                y = float(mxGeometry.get("y", 0))
                new_geom.set("x", str(int(x + x_offset)))
                new_geom.set("y", str(int(y + y_offset)))
                if mxGeometry.get("width"):
                    new_geom.set("width", mxGeometry.get("width"))
                if mxGeometry.get("height"):
                    new_geom.set("height", mxGeometry.get("height"))
                if mxGeometry.get("relative"):
                    new_geom.set("relative", mxGeometry.get("relative"))

        # Second pass: update source/target references
        for cell in target_root.findall("mxCell"):
            if cell.get("edge") == "1":
                source = cell.get("source")
                target = cell.get("target")
                if source and source in id_map:
                    cell.set("source", id_map[source])
                if target and target in id_map:
                    cell.set("target", id_map[target])

        return id_map

    @staticmethod
    def _get_bounds(root: etree._Element) -> Tuple[float, float, float, float] | None:
        """Calculate bounding box of all cells."""
        min_x = float('inf')
        min_y = float('inf')
        max_x = float('-inf')
        max_y = float('-inf')

        for cell in root.findall("mxCell"):
            mxGeometry = cell.find("mxGeometry")
            if mxGeometry is not None:
                x = float(mxGeometry.get("x", 0))
                y = float(mxGeometry.get("y", 0))
                w = float(mxGeometry.get("width", 0))
                h = float(mxGeometry.get("height", 0))
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x + w)
                max_y = max(max_y, y + h)

        if max_x == float('-inf'):
            return None
        return (min_x, min_y, max_x, max_y)


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Merge multiple .drawio files into one."
    )
    parser.add_argument("files", nargs="+", help="Input .drawio files")
    parser.add_argument("--output", required=True, help="Output .drawio file")
    parser.add_argument(
        "--mode",
        choices=["as-pages", "side-by-side", "stack"],
        default="as-pages",
        help="Merge mode (default: as-pages)"
    )
    args = parser.parse_args()

    merger = DrawioMerger(args.files, args.output, args.mode)
    if not merger.load_files():
        return 1

    if not merger.merge():
        return 1

    print(f"{COLOR_GREEN}✓ Merged {len(args.files)} file(s) into {args.output}{COLOR_RESET}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
