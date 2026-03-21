"""Unit tests for diagram_core module."""

import pytest
import tempfile
from pathlib import Path
from drawio_mcp_server.diagram_core import (
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


class TestDiagramCreation:
    """Test diagram creation and basic operations."""

    def test_create_empty_diagram(self):
        """Test creating an empty diagram."""
        diagram = create_empty_diagram("Test")
        assert diagram is not None
        cells = diagram.find_all_cells()
        assert len(cells) == 2  # Root cell (0) and parent cell (1)

    def test_create_diagram_with_name(self):
        """Test creating a diagram with specific name."""
        diagram = create_empty_diagram("CustomName")
        model = diagram.get_mxgraph_model()
        diagram_elem = model.getparent()
        assert diagram_elem.get("name") == "CustomName"


class TestVertexOperations:
    """Test vertex (shape) operations."""

    def test_add_single_vertex(self):
        """Test adding a single vertex."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "Label", 0, 0)
        elements = list_elements(diagram)
        assert len(elements) == 1
        assert elements[0]["id"] == "v1"
        assert elements[0]["label"] == "Label"
        assert elements[0]["type"] == "vertex"

    def test_add_multiple_vertices(self):
        """Test adding multiple vertices."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "First", 0, 0)
        add_vertex(diagram, "v2", "Second", 100, 0)
        add_vertex(diagram, "v3", "Third", 200, 0)
        elements = list_elements(diagram)
        assert len(elements) == 3

    def test_vertex_with_shape(self):
        """Test adding vertex with different shapes."""
        diagram = create_empty_diagram()
        shapes = ["rectangle", "rounded", "diamond", "circle", "cylinder"]
        for i, shape in enumerate(shapes):
            add_vertex(diagram, f"v{i}", shape, i * 100, 0, shape=shape)
        elements = list_elements(diagram)
        assert len(elements) == 5

    def test_vertex_with_color(self):
        """Test adding vertex with different colors."""
        diagram = create_empty_diagram()
        colors = ["blue", "green", "red", "yellow", "orange"]
        for i, color in enumerate(colors):
            add_vertex(diagram, f"v{i}", color, i * 100, 0, color=color)
        elements = list_elements(diagram)
        assert len(elements) == 5

    def test_add_vertex_with_geometry(self):
        """Test vertex geometry (position and size)."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "Test", x=50, y=100, width=200, height=150)
        elem = get_element(diagram, "v1")
        assert elem["x"] == 50
        assert elem["y"] == 100
        assert elem["width"] == 200
        assert elem["height"] == 150

    def test_duplicate_vertex_id_raises_error(self):
        """Test that duplicate IDs are prevented."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "First", 0, 0)
        with pytest.raises(ValueError, match="already exists"):
            add_vertex(diagram, "v1", "Duplicate", 100, 0)


class TestEdgeOperations:
    """Test edge (connector) operations."""

    def test_add_single_edge(self):
        """Test adding a single edge."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "A", 0, 0)
        add_vertex(diagram, "v2", "B", 100, 0)
        add_edge(diagram, "e1", "v1", "v2")
        elements = list_elements(diagram)
        edges = [e for e in elements if e["type"] == "edge"]
        assert len(edges) == 1
        assert edges[0]["source"] == "v1"
        assert edges[0]["target"] == "v2"

    def test_edge_with_label(self):
        """Test edge with label."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "A", 0, 0)
        add_vertex(diagram, "v2", "B", 100, 0)
        add_edge(diagram, "e1", "v1", "v2", value="connects to")
        elem = get_element(diagram, "e1")
        assert elem["label"] == "connects to"

    def test_edge_with_style(self):
        """Test edge with different styles."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "A", 0, 0)
        add_vertex(diagram, "v2", "B", 100, 0)
        styles = ["orthogonal", "straight", "curved"]
        for i, style in enumerate(styles):
            add_vertex(diagram, f"v{i+3}", f"C{i}", i * 100 + 200, 0)
            add_edge(diagram, f"e{i}", "v1", f"v{i+3}", style=style)
        elements = list_elements(diagram)
        edges = [e for e in elements if e["type"] == "edge"]
        assert len(edges) == 3

    def test_edge_with_missing_source_raises_error(self):
        """Test that edge with missing source raises error."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "A", 0, 0)
        with pytest.raises(ValueError, match="Source cell"):
            add_edge(diagram, "e1", "missing", "v1")

    def test_edge_with_missing_target_raises_error(self):
        """Test that edge with missing target raises error."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "A", 0, 0)
        with pytest.raises(ValueError, match="Target cell"):
            add_edge(diagram, "e1", "v1", "missing")


class TestElementManipulation:
    """Test element update and removal."""

    def test_update_element_label(self):
        """Test updating element label."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "Original", 0, 0)
        update_element(diagram, "v1", label="Updated")
        elem = get_element(diagram, "v1")
        assert elem["label"] == "Updated"

    def test_update_element_position(self):
        """Test updating element position."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "Test", 0, 0)
        update_element(diagram, "v1", x=100, y=200)
        elem = get_element(diagram, "v1")
        assert elem["x"] == 100
        assert elem["y"] == 200

    def test_update_element_size(self):
        """Test updating element size."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "Test", 0, 0, width=120, height=60)
        update_element(diagram, "v1", width=200, height=150)
        elem = get_element(diagram, "v1")
        assert elem["width"] == 200
        assert elem["height"] == 150

    def test_update_nonexistent_element_returns_false(self):
        """Test updating nonexistent element."""
        diagram = create_empty_diagram()
        result = update_element(diagram, "missing", label="Test")
        assert result is False

    def test_remove_vertex(self):
        """Test removing a vertex."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "Test", 0, 0)
        assert len(list_elements(diagram)) == 1
        remove_element(diagram, "v1")
        assert len(list_elements(diagram)) == 0

    def test_remove_vertex_removes_connected_edges(self):
        """Test that removing vertex removes its edges."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "A", 0, 0)
        add_vertex(diagram, "v2", "B", 100, 0)
        add_edge(diagram, "e1", "v1", "v2")
        assert len(list_elements(diagram)) == 3  # 2 vertices + 1 edge
        remove_element(diagram, "v1")
        assert len(list_elements(diagram)) == 1  # Only v2 remains

    def test_remove_nonexistent_element_returns_false(self):
        """Test removing nonexistent element."""
        diagram = create_empty_diagram()
        result = remove_element(diagram, "missing")
        assert result is False


class TestDiagramValidation:
    """Test diagram validation."""

    def test_valid_diagram(self):
        """Test validation of valid diagram."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "A", 0, 0)
        add_vertex(diagram, "v2", "B", 100, 0)
        add_edge(diagram, "e1", "v1", "v2")
        issues = validate_diagram(diagram)
        assert len(issues) == 0

    def test_orphaned_edge_detection(self):
        """Test detection of orphaned edges."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "A", 0, 0)
        add_edge(diagram, "e1", "v1", "missing")
        issues = validate_diagram(diagram)
        assert len(issues) > 0
        assert any("missing" in issue.lower() for issue in issues)


class TestAutoLayout:
    """Test auto-layout algorithms."""

    def test_tree_layout(self):
        """Test tree layout."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "Root", 0, 0)
        add_vertex(diagram, "v2", "Child1", 100, 0)
        add_vertex(diagram, "v3", "Child2", 200, 0)
        add_edge(diagram, "e1", "v1", "v2")
        add_edge(diagram, "e2", "v1", "v3")
        auto_layout(diagram, layout_type="tree")
        # Verify elements have been repositioned
        elements = list_elements(diagram)
        vertices = [e for e in elements if e["type"] == "vertex"]
        assert all("x" in v and "y" in v for v in vertices)

    def test_grid_layout(self):
        """Test grid layout."""
        diagram = create_empty_diagram()
        for i in range(4):
            add_vertex(diagram, f"v{i}", f"Node {i}", 0, 0)
        auto_layout(diagram, layout_type="grid")
        elements = list_elements(diagram)
        vertices = [e for e in elements if e["type"] == "vertex"]
        assert len(vertices) == 4

    def test_lr_layout(self):
        """Test left-to-right layout."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "A", 0, 0)
        add_vertex(diagram, "v2", "B", 0, 0)
        add_vertex(diagram, "v3", "C", 0, 0)
        add_edge(diagram, "e1", "v1", "v2")
        add_edge(diagram, "e2", "v2", "v3")
        auto_layout(diagram, layout_type="lr")
        elements = list_elements(diagram)
        vertices = [e for e in elements if e["type"] == "vertex"]
        assert len(vertices) == 3


class TestFormatConversion:
    """Test format conversions."""

    def test_mermaid_basic_flowchart(self):
        """Test basic Mermaid flowchart conversion."""
        mermaid = "graph TD\nA[Start] --> B[End]"
        diagram = mermaid_to_drawio(mermaid)
        elements = list_elements(diagram)
        assert len(elements) >= 2

    def test_mermaid_with_shapes(self):
        """Test Mermaid with different shapes."""
        mermaid = """
        graph TD
        A[Rectangle] --> B(Rounded)
        B --> C{Diamond}
        C --> D((Circle))
        """
        diagram = mermaid_to_drawio(mermaid)
        elements = list_elements(diagram)
        vertices = [e for e in elements if e["type"] == "vertex"]
        assert len(vertices) >= 4

    def test_mermaid_with_labels(self):
        """Test Mermaid with edge labels."""
        mermaid = """
        graph TD
        A[Start] -->|next| B[Process]
        B -->|done| C[End]
        """
        diagram = mermaid_to_drawio(mermaid)
        elements = list_elements(diagram)
        edges = [e for e in elements if e["type"] == "edge"]
        assert len(edges) >= 2

    def test_plantuml_basic(self):
        """Test basic PlantUML conversion."""
        plantuml = """
        @startuml
        [Component1] --> (Actor)
        @enduml
        """
        diagram = plantuml_to_drawio(plantuml)
        elements = list_elements(diagram)
        assert len(elements) >= 2

    def test_plantuml_with_database(self):
        """Test PlantUML with database."""
        plantuml = """
        [WebApp] --> database "PostgreSQL"
        """
        diagram = plantuml_to_drawio(plantuml)
        elements = list_elements(diagram)
        vertices = [e for e in elements if e["type"] == "vertex"]
        assert len(vertices) >= 2


class TestSerialization:
    """Test diagram serialization and parsing."""

    def test_to_xml(self):
        """Test converting diagram to XML."""
        diagram = create_empty_diagram("Test")
        add_vertex(diagram, "v1", "Node", 0, 0)
        xml = to_xml(diagram)
        assert isinstance(xml, str)
        assert "mxfile" in xml
        assert "<mxCell" in xml

    def test_parse_from_string(self):
        """Test parsing diagram from XML string."""
        diagram = create_empty_diagram("Test")
        add_vertex(diagram, "v1", "Node", 0, 0)
        xml = to_xml(diagram)
        parsed = parse_diagram(xml)
        assert parsed is not None
        elements = list_elements(parsed)
        assert len(elements) == 1

    def test_parse_from_file(self):
        """Test parsing diagram from file."""
        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = Path(tmpdir) / "test.drawio"
            diagram = create_empty_diagram("Test")
            add_vertex(diagram, "v1", "Node", 0, 0)
            xml = to_xml(diagram)
            filepath.write_text(xml)
            parsed = parse_diagram(filepath)
            assert parsed is not None
            elements = list_elements(parsed)
            assert len(elements) == 1


class TestListAndGetElements:
    """Test listing and getting elements."""

    def test_list_elements_empty(self):
        """Test listing elements in empty diagram."""
        diagram = create_empty_diagram()
        elements = list_elements(diagram)
        assert elements == []

    def test_list_elements_with_content(self):
        """Test listing elements with content."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "A", 0, 0)
        add_vertex(diagram, "v2", "B", 100, 0)
        add_edge(diagram, "e1", "v1", "v2")
        elements = list_elements(diagram)
        assert len(elements) == 3

    def test_get_element_vertex(self):
        """Test getting specific vertex."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "Test Node", 50, 100, width=150, height=80)
        elem = get_element(diagram, "v1")
        assert elem is not None
        assert elem["id"] == "v1"
        assert elem["label"] == "Test Node"
        assert elem["type"] == "vertex"
        assert elem["x"] == 50
        assert elem["y"] == 100

    def test_get_element_edge(self):
        """Test getting specific edge."""
        diagram = create_empty_diagram()
        add_vertex(diagram, "v1", "A", 0, 0)
        add_vertex(diagram, "v2", "B", 100, 0)
        add_edge(diagram, "e1", "v1", "v2", value="connects")
        elem = get_element(diagram, "e1")
        assert elem is not None
        assert elem["id"] == "e1"
        assert elem["type"] == "edge"
        assert elem["source"] == "v1"
        assert elem["target"] == "v2"
        assert elem["label"] == "connects"

    def test_get_nonexistent_element(self):
        """Test getting nonexistent element."""
        diagram = create_empty_diagram()
        elem = get_element(diagram, "missing")
        assert elem is None


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
