"""Tests for the MCP server wrapper layer."""

from pathlib import Path

from drawio_mcp_server import server
from drawio_mcp_server.diagram_core import create_empty_diagram, to_xml


def _write_diagram(path: Path, name: str = "Test") -> Path:
    diagram = create_empty_diagram(name)
    path.write_text(to_xml(diagram), encoding="utf-8")
    return path


def test_create_diagram_returns_preview_only():
    result = server.create_diagram("System")

    assert result["success"] is True
    assert result["name"] == "System"
    assert "xml_preview" in result
    assert result["cell_count"] >= 2


def test_add_update_list_and_remove_round_trip(tmp_path: Path):
    diagram_path = _write_diagram(tmp_path / "roundtrip.drawio")

    add_result = server.add_node(
        diagram_path=str(diagram_path),
        node_id="node-1",
        label="API",
        x=10,
        y=20,
        color="blue",
    )
    assert add_result["success"] is True

    update_result = server.update_element(
        diagram_path=str(diagram_path),
        element_id="node-1",
        label="API Gateway",
        x=40,
        y=50,
    )
    assert update_result["success"] is True

    list_result = server.list_elements(str(diagram_path))
    assert list_result["success"] is True
    assert list_result["element_count"] == 1
    assert list_result["elements"][0]["label"] == "API Gateway"

    remove_result = server.remove_element(str(diagram_path), "node-1")
    assert remove_result["success"] is True

    final_list = server.list_elements(str(diagram_path))
    assert final_list["success"] is True
    assert final_list["element_count"] == 0


def test_validate_diagram_reports_valid_file(tmp_path: Path):
    diagram_path = _write_diagram(tmp_path / "valid.drawio")
    server.add_node(str(diagram_path), "node-a", "A", x=0, y=0)
    server.add_node(str(diagram_path), "node-b", "B", x=100, y=0)
    server.add_connection(str(diagram_path), "edge-ab", "node-a", "node-b")

    result = server.validate_diagram(str(diagram_path))

    assert result["success"] is True
    assert result["is_valid"] is True
    assert result["issue_count"] == 0


def test_auto_layout_updates_existing_diagram(tmp_path: Path):
    diagram_path = _write_diagram(tmp_path / "layout.drawio")
    server.add_node(str(diagram_path), "node-a", "A", x=0, y=0)
    server.add_node(str(diagram_path), "node-b", "B", x=0, y=0)
    server.add_connection(str(diagram_path), "edge-ab", "node-a", "node-b")

    result = server.auto_layout(str(diagram_path), "lr")

    assert result["success"] is True
    assert result["layout_applied"] == "lr"
    assert result["element_count"] == 3


def test_import_mermaid_writes_drawio_file(tmp_path: Path):
    output_path = tmp_path / "mermaid_output"

    result = server.import_mermaid("graph TD\nA[Start] --> B[End]", str(output_path))

    assert result["success"] is True
    assert Path(result["output_path"]).exists()
    assert Path(result["output_path"]).suffix == ".drawio"
    assert result["vertices"] >= 2


def test_export_svg_writes_svg_file(tmp_path: Path):
    diagram_path = _write_diagram(tmp_path / "export.drawio")
    server.add_node(str(diagram_path), "node-a", "A", x=0, y=0)

    result = server.export_svg(str(diagram_path), str(tmp_path / "exported"))

    assert result["success"] is True
    assert Path(result["output_path"]).exists()
    assert Path(result["output_path"]).suffix == ".svg"


def test_invalid_shape_returns_validation_error(tmp_path: Path):
    diagram_path = _write_diagram(tmp_path / "invalid-shape.drawio")

    result = server.add_node(
        diagram_path=str(diagram_path),
        node_id="node-1",
        label="Bad",
        shape="not-a-shape",
    )

    assert result["success"] is False
    assert "Unknown shape" in result["error"]
