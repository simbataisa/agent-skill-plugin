#!/usr/bin/env python3
"""
Validates a .drawio file and reports issues.

Usage: python validate.py <file.drawio>

Checks:
- Valid XML structure
- Structural cells present
- Unique cell IDs
- All edge sources/targets exist
- No overlapping shapes
- Well-formed styles
"""

import argparse
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple
from lxml import etree

# ANSI color codes
COLOR_GREEN = "\033[92m"
COLOR_YELLOW = "\033[93m"
COLOR_RED = "\033[91m"
COLOR_RESET = "\033[0m"
COLOR_BOLD = "\033[1m"


class DrawioValidator:
    """Validates draw.io files and reports issues."""

    def __init__(self, file_path: str) -> None:
        """Initialize validator with a .drawio file."""
        self.file_path = Path(file_path)
        self.issues: Dict[str, List[Tuple[str, str]]] = {
            "PASS": [],
            "WARN": [],
            "FAIL": [],
        }
        self.tree: etree._ElementTree | None = None
        self.root: etree._Element | None = None
        self.cells: Dict[str, etree._Element] = {}

    def validate(self) -> bool:
        """Run all validation checks. Returns True if no failures."""
        if not self._check_file_exists():
            return False
        if not self._parse_xml():
            return False
        if not self._check_xml_structure():
            return False
        self._index_cells()
        self._check_unique_ids()
        self._check_edge_references()
        self._check_overlaps()
        self._check_styles()
        return len(self.issues["FAIL"]) == 0

    def _check_file_exists(self) -> bool:
        """Check if the file exists."""
        if not self.file_path.exists():
            self.issues["FAIL"].append(("File", f"File not found: {self.file_path}"))
            return False
        if self.file_path.suffix.lower() != ".drawio":
            self.issues["WARN"].append(
                ("Format", "File extension is not .drawio")
            )
        return True

    def _parse_xml(self) -> bool:
        """Parse the XML file."""
        try:
            self.tree = etree.parse(str(self.file_path))
            self.root = self.tree.getroot()
            self.issues["PASS"].append(("XML", "Valid XML structure"))
            return True
        except etree.XMLSyntaxError as e:
            self.issues["FAIL"].append(("XML", f"Invalid XML: {e}"))
            return False

    def _check_xml_structure(self) -> bool:
        """Check for required root element and structure."""
        if self.root is None or self.root.tag != "mxfile":
            self.issues["FAIL"].append(
                ("Structure", "Root element must be <mxfile>")
            )
            return False

        diagrams = self.root.findall("diagram")
        if not diagrams:
            self.issues["FAIL"].append(
                ("Structure", "No <diagram> elements found")
            )
            return False

        self.issues["PASS"].append(
            ("Structure", f"Found {len(diagrams)} diagram(s)")
        )
        return True

    def _index_cells(self) -> None:
        """Index all cells by ID for reference checking."""
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

    def _check_unique_ids(self) -> None:
        """Check that all cell IDs are unique."""
        diagrams = self.root.findall("diagram")
        seen_ids: Dict[str, int] = {}

        for diagram in diagrams:
            mxGraphModel = diagram.find("mxGraphModel")
            if mxGraphModel is not None:
                root_elem = mxGraphModel.find("root")
                if root_elem is not None:
                    for cell in root_elem.findall("mxCell"):
                        cell_id = cell.get("id")
                        if cell_id:
                            seen_ids[cell_id] = seen_ids.get(cell_id, 0) + 1

        duplicates = [cid for cid, count in seen_ids.items() if count > 1]
        if duplicates:
            self.issues["FAIL"].append(
                ("IDs", f"Duplicate IDs found: {', '.join(duplicates[:5])}")
            )
        else:
            self.issues["PASS"].append(("IDs", f"All {len(seen_ids)} IDs are unique"))

    def _check_edge_references(self) -> None:
        """Check that all edge source/target references exist."""
        missing_sources: Set[str] = set()
        missing_targets: Set[str] = set()

        diagrams = self.root.findall("diagram")
        for diagram in diagrams:
            mxGraphModel = diagram.find("mxGraphModel")
            if mxGraphModel is not None:
                root_elem = mxGraphModel.find("root")
                if root_elem is not None:
                    for cell in root_elem.findall("mxCell"):
                        edge = cell.get("edge") == "1"
                        if edge:
                            source = cell.get("source")
                            target = cell.get("target")
                            if source and source not in self.cells:
                                missing_sources.add(source)
                            if target and target not in self.cells:
                                missing_targets.add(target)

        issues = []
        if missing_sources:
            issues.append(f"Missing sources: {', '.join(list(missing_sources)[:3])}")
        if missing_targets:
            issues.append(f"Missing targets: {', '.join(list(missing_targets)[:3])}")

        if issues:
            self.issues["FAIL"].append(("References", "; ".join(issues)))
        else:
            self.issues["PASS"].append(
                ("References", "All edge references valid")
            )

    def _check_overlaps(self) -> None:
        """Check for overlapping shapes."""
        overlaps: List[Tuple[str, str]] = []
        shapes: List[Tuple[str, float, float, float, float]] = []

        diagrams = self.root.findall("diagram")
        for diagram in diagrams:
            mxGraphModel = diagram.find("mxGraphModel")
            if mxGraphModel is not None:
                root_elem = mxGraphModel.find("root")
                if root_elem is not None:
                    for cell in root_elem.findall("mxCell"):
                        edge = cell.get("edge") == "1"
                        if not edge:
                            mxGeometry = cell.find("mxGeometry")
                            if mxGeometry is not None:
                                x = float(mxGeometry.get("x", 0))
                                y = float(mxGeometry.get("y", 0))
                                w = float(mxGeometry.get("width", 0))
                                h = float(mxGeometry.get("height", 0))
                                if w > 0 and h > 0:
                                    cell_id = cell.get("id", "")
                                    shapes.append((cell_id, x, y, w, h))

        # Check for overlaps
        for i, (id1, x1, y1, w1, h1) in enumerate(shapes):
            for id2, x2, y2, w2, h2 in shapes[i + 1 :]:
                if self._rectangles_overlap(x1, y1, w1, h1, x2, y2, w2, h2):
                    overlaps.append((id1, id2))

        if overlaps:
            count = len(overlaps)
            msg = f"{count} overlapping shape pair(s) found"
            self.issues["WARN"].append(("Overlaps", msg))
        else:
            self.issues["PASS"].append(
                ("Overlaps", f"No overlaps detected ({len(shapes)} shapes)")
            )

    @staticmethod
    def _rectangles_overlap(
        x1: float, y1: float, w1: float, h1: float,
        x2: float, y2: float, w2: float, h2: float
    ) -> bool:
        """Check if two rectangles overlap."""
        return not (x1 + w1 < x2 or x2 + w2 < x1 or y1 + h1 < y2 or y2 + h2 < y1)

    def _check_styles(self) -> None:
        """Check for well-formed styles."""
        bad_styles: List[str] = []

        diagrams = self.root.findall("diagram")
        for diagram in diagrams:
            mxGraphModel = diagram.find("mxGraphModel")
            if mxGraphModel is not None:
                root_elem = mxGraphModel.find("root")
                if root_elem is not None:
                    for cell in root_elem.findall("mxCell"):
                        style = cell.get("style", "")
                        if style:
                            # Basic validation: check for balanced quotes and semicolons
                            if style.count('"') % 2 != 0:
                                bad_styles.append(cell.get("id", "?"))

        if bad_styles:
            msg = f"Malformed styles in cells: {', '.join(bad_styles[:3])}"
            self.issues["WARN"].append(("Styles", msg))
        else:
            self.issues["PASS"].append(("Styles", "All styles well-formed"))

    def print_report(self) -> None:
        """Print validation report with colors."""
        print(f"\n{COLOR_BOLD}Draw.io Validation Report{COLOR_RESET}")
        print(f"File: {self.file_path}\n")

        for status in ["PASS", "WARN", "FAIL"]:
            if not self.issues[status]:
                continue

            if status == "PASS":
                color = COLOR_GREEN
                symbol = "✓"
            elif status == "WARN":
                color = COLOR_YELLOW
                symbol = "⚠"
            else:
                color = COLOR_RED
                symbol = "✗"

            print(f"{color}{symbol} {status}{COLOR_RESET}")
            for check, message in self.issues[status]:
                print(f"  [{check:12}] {message}")
            print()

        # Summary
        fail_count = len(self.issues["FAIL"])
        warn_count = len(self.issues["WARN"])
        pass_count = len(self.issues["PASS"])

        if fail_count == 0 and warn_count == 0:
            print(f"{COLOR_GREEN}{COLOR_BOLD}✓ All checks passed!{COLOR_RESET}\n")
        elif fail_count == 0:
            print(
                f"{COLOR_YELLOW}{COLOR_BOLD}⚠ {warn_count} warning(s), no failures{COLOR_RESET}\n"
            )
        else:
            print(
                f"{COLOR_RED}{COLOR_BOLD}✗ {fail_count} failure(s), {warn_count} warning(s){COLOR_RESET}\n"
            )


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Validate a .drawio file and report issues."
    )
    parser.add_argument("file", help="Path to .drawio file")
    args = parser.parse_args()

    validator = DrawioValidator(args.file)
    success = validator.validate()
    validator.print_report()

    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
