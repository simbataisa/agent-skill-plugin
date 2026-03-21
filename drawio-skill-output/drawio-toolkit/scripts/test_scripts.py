#!/usr/bin/env python3
"""
Test suite for Draw.io CLI scripts.

Run this to verify all scripts are working correctly.
Usage: python test_scripts.py
"""

import subprocess
import tempfile
import sys
from pathlib import Path

# ANSI color codes
COLOR_GREEN = "\033[92m"
COLOR_RED = "\033[91m"
COLOR_YELLOW = "\033[93m"
COLOR_RESET = "\033[0m"
COLOR_BOLD = "\033[1m"

SCRIPTS_DIR = Path(__file__).parent
TESTS_PASSED = 0
TESTS_FAILED = 0


def run_command(cmd, description):
    """Run a command and report result."""
    global TESTS_PASSED, TESTS_FAILED
    print(f"\n{COLOR_BOLD}Testing:{COLOR_RESET} {description}")
    print(f"  Command: {' '.join(cmd)}")
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=SCRIPTS_DIR)
        if result.returncode == 0:
            print(f"  {COLOR_GREEN}✓ PASSED{COLOR_RESET}")
            TESTS_PASSED += 1
            return True
        else:
            print(f"  {COLOR_RED}✗ FAILED{COLOR_RESET}")
            if result.stderr:
                print(f"  Error: {result.stderr[:200]}")
            TESTS_FAILED += 1
            return False
    except Exception as e:
        print(f"  {COLOR_RED}✗ EXCEPTION: {e}{COLOR_RESET}")
        TESTS_FAILED += 1
        return False


def create_test_files(temp_dir):
    """Create test input files."""
    # Test CSV files
    org_csv = temp_dir / "test_org.csv"
    org_csv.write_text("name,title,reports_to\nAlice,CEO,\nBob,VP,Alice\n")

    flow_csv = temp_dir / "test_flow.csv"
    flow_csv.write_text("step,type,next_step,label\nstart,oval,end,\nend,oval,,\n")

    erd_csv = temp_dir / "test_erd.csv"
    erd_csv.write_text("entity,attribute,type,relationship_to,cardinality\nUser,id,PK,,\n")

    network_csv = temp_dir / "test_network.csv"
    network_csv.write_text("device,type,connects_to,label\nRouter,device,Switch,1Gbps\n")

    mermaid_file = temp_dir / "test.mermaid"
    mermaid_file.write_text("graph TD\n    A[Start] --> B[End]\n")

    puml_file = temp_dir / "test.puml"
    puml_file.write_text("@startuml\n[A] --> [B]\n@enduml\n")

    return {
        "org_csv": org_csv,
        "flow_csv": flow_csv,
        "erd_csv": erd_csv,
        "network_csv": network_csv,
        "mermaid": mermaid_file,
        "puml": puml_file,
    }


def main():
    """Run all tests."""
    print(f"\n{COLOR_BOLD}Draw.io CLI Scripts Test Suite{COLOR_RESET}\n")

    with tempfile.TemporaryDirectory() as temp_dir:
        temp_dir = Path(temp_dir)
        files = create_test_files(temp_dir)

        # Test 1: Create from CSV (orgchart)
        org_drawio = temp_dir / "test_org.drawio"
        run_command(
            ["python3", "create_from_csv.py", str(files["org_csv"]),
             "--output", str(org_drawio), "--type", "orgchart"],
            "create_from_csv.py - orgchart"
        )

        # Test 2: Create from CSV (flowchart)
        flow_drawio = temp_dir / "test_flow.drawio"
        run_command(
            ["python3", "create_from_csv.py", str(files["flow_csv"]),
             "--output", str(flow_drawio), "--type", "flowchart"],
            "create_from_csv.py - flowchart"
        )

        # Test 3: Create from CSV (erd)
        erd_drawio = temp_dir / "test_erd.drawio"
        run_command(
            ["python3", "create_from_csv.py", str(files["erd_csv"]),
             "--output", str(erd_drawio), "--type", "erd"],
            "create_from_csv.py - erd"
        )

        # Test 4: Create from CSV (network)
        network_drawio = temp_dir / "test_network.drawio"
        run_command(
            ["python3", "create_from_csv.py", str(files["network_csv"]),
             "--output", str(network_drawio), "--type", "network"],
            "create_from_csv.py - network"
        )

        # Test 5: Validate
        if org_drawio.exists():
            run_command(
                ["python3", "validate.py", str(org_drawio)],
                "validate.py"
            )

        # Test 6: Info
        if org_drawio.exists():
            run_command(
                ["python3", "info.py", str(org_drawio)],
                "info.py"
            )

        # Test 7: Auto-layout (tree)
        if org_drawio.exists():
            run_command(
                ["python3", "auto_layout.py", str(org_drawio), "--layout", "tree"],
                "auto_layout.py - tree"
            )

        # Test 8: Auto-layout (grid)
        if flow_drawio.exists():
            run_command(
                ["python3", "auto_layout.py", str(flow_drawio), "--layout", "grid"],
                "auto_layout.py - grid"
            )

        # Test 9: Auto-layout (lr)
        if erd_drawio.exists():
            run_command(
                ["python3", "auto_layout.py", str(erd_drawio), "--layout", "lr"],
                "auto_layout.py - lr"
            )

        # Test 10: Auto-layout (radial)
        if network_drawio.exists():
            run_command(
                ["python3", "auto_layout.py", str(network_drawio), "--layout", "radial"],
                "auto_layout.py - radial"
            )

        # Test 11: Convert Mermaid to DrawIO
        mermaid_drawio = temp_dir / "test_mermaid.drawio"
        run_command(
            ["python3", "convert.py", str(files["mermaid"]), str(mermaid_drawio)],
            "convert.py - Mermaid to DrawIO"
        )

        # Test 12: Convert PlantUML to DrawIO
        puml_drawio = temp_dir / "test_puml.drawio"
        run_command(
            ["python3", "convert.py", str(files["puml"]), str(puml_drawio)],
            "convert.py - PlantUML to DrawIO"
        )

        # Test 13: Convert DrawIO to SVG
        if org_drawio.exists():
            svg_file = temp_dir / "test.svg"
            run_command(
                ["python3", "convert.py", str(org_drawio), str(svg_file)],
                "convert.py - DrawIO to SVG"
            )

        # Test 14: Convert DrawIO to Mermaid
        if org_drawio.exists():
            mmd_file = temp_dir / "test.mmd"
            run_command(
                ["python3", "convert.py", str(org_drawio), str(mmd_file)],
                "convert.py - DrawIO to Mermaid"
            )

        # Test 15: Merge (as-pages)
        if org_drawio.exists() and flow_drawio.exists():
            merged_pages = temp_dir / "test_merged_pages.drawio"
            run_command(
                ["python3", "merge.py", str(org_drawio), str(flow_drawio),
                 "--output", str(merged_pages), "--mode", "as-pages"],
                "merge.py - as-pages"
            )

        # Test 16: Merge (side-by-side)
        if erd_drawio.exists() and network_drawio.exists():
            merged_sbs = temp_dir / "test_merged_sbs.drawio"
            run_command(
                ["python3", "merge.py", str(erd_drawio), str(network_drawio),
                 "--output", str(merged_sbs), "--mode", "side-by-side"],
                "merge.py - side-by-side"
            )

        # Test 17: Merge (stack)
        if mermaid_drawio.exists() and puml_drawio.exists():
            merged_stack = temp_dir / "test_merged_stack.drawio"
            run_command(
                ["python3", "merge.py", str(mermaid_drawio), str(puml_drawio),
                 "--output", str(merged_stack), "--mode", "stack"],
                "merge.py - stack"
            )

    # Print summary
    print(f"\n{COLOR_BOLD}Test Summary{COLOR_RESET}")
    print(f"  {COLOR_GREEN}Passed: {TESTS_PASSED}{COLOR_RESET}")
    print(f"  {COLOR_RED}Failed: {TESTS_FAILED}{COLOR_RESET}")
    print(f"  Total:  {TESTS_PASSED + TESTS_FAILED}\n")

    if TESTS_FAILED == 0:
        print(f"{COLOR_GREEN}{COLOR_BOLD}✓ All tests passed!{COLOR_RESET}\n")
        return 0
    else:
        print(f"{COLOR_RED}{COLOR_BOLD}✗ Some tests failed{COLOR_RESET}\n")
        return 1


if __name__ == "__main__":
    sys.exit(main())
