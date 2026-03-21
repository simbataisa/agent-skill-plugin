#!/usr/bin/env python
"""Example usage of the draw.io MCP server diagram operations.

This script demonstrates all major functionality of the diagram_core module.
"""

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


def example_basic_diagram():
    """Example: Create a basic system architecture diagram."""
    print("=" * 60)
    print("Example 1: Basic System Architecture Diagram")
    print("=" * 60)

    # Create a new diagram
    diagram = create_empty_diagram("System Architecture")

    # Add frontend component
    add_vertex(
        diagram,
        "frontend",
        "Web Frontend",
        x=50,
        y=100,
        shape="component",
        color="blue",
    )

    # Add API gateway
    add_vertex(
        diagram,
        "api_gateway",
        "API Gateway",
        x=300,
        y=100,
        shape="component",
        color="blue",
    )

    # Add microservices
    add_vertex(
        diagram,
        "auth_service",
        "Auth Service",
        x=100,
        y=250,
        shape="rounded",
        color="green",
    )
    add_vertex(
        diagram,
        "user_service",
        "User Service",
        x=300,
        y=250,
        shape="rounded",
        color="green",
    )
    add_vertex(
        diagram,
        "data_service",
        "Data Service",
        x=500,
        y=250,
        shape="rounded",
        color="green",
    )

    # Add database
    add_vertex(
        diagram, "database", "PostgreSQL", x=300, y=400, shape="cylinder", color="orange"
    )

    # Add connections
    add_edge(diagram, "conn1", "frontend", "api_gateway", "HTTP")
    add_edge(diagram, "conn2", "api_gateway", "auth_service", "validate")
    add_edge(diagram, "conn3", "api_gateway", "user_service", "get user")
    add_edge(diagram, "conn4", "api_gateway", "data_service", "get data")
    add_edge(diagram, "conn5", "user_service", "database", "query")
    add_edge(diagram, "conn6", "data_service", "database", "query")

    # List all elements
    elements = list_elements(diagram)
    print(f"\nTotal elements: {len(elements)}")
    print(f"Vertices: {len([e for e in elements if e['type'] == 'vertex'])}")
    print(f"Edges: {len([e for e in elements if e['type'] == 'edge'])}")

    # Validate
    issues = validate_diagram(diagram)
    print(f"Validation issues: {len(issues)}")

    # Auto-layout
    auto_layout(diagram, layout_type="tree")
    print("Applied tree layout")

    # Save
    filepath = Path("example_architecture.drawio")
    xml_content = to_xml(diagram)
    filepath.write_text(xml_content)
    print(f"\nSaved to: {filepath}")

    return diagram


def example_modify_diagram():
    """Example: Modify an existing diagram."""
    print("\n" + "=" * 60)
    print("Example 2: Modifying a Diagram")
    print("=" * 60)

    # Create a simple diagram
    diagram = create_empty_diagram("Process Flow")

    add_vertex(diagram, "start", "Start", 50, 50, shape="circle", color="green")
    add_vertex(diagram, "step1", "Process Step 1", 200, 50, shape="rectangle", color="blue")
    add_vertex(diagram, "decision", "Decision", 350, 50, shape="diamond", color="yellow")
    add_vertex(diagram, "end", "End", 500, 50, shape="circle", color="red")

    # Connect them
    add_edge(diagram, "e1", "start", "step1", "proceed")
    add_edge(diagram, "e2", "step1", "decision", "check")
    add_edge(diagram, "e3", "decision", "end", "done")

    print("\nInitial diagram created")
    print(f"Elements: {len(list_elements(diagram))}")

    # Update an element
    update_element(
        diagram,
        "step1",
        label="Updated Process Step",
        x=220,
        y=70,
        width=150,
        height=80,
    )
    print("\nUpdated 'step1' element")

    # Get specific element
    element_info = get_element(diagram, "decision")
    print(f"Decision element: {element_info}")

    # Remove an element (and its edges)
    remove_element(diagram, "end")
    print("\nRemoved 'end' element and its connections")
    print(f"Elements remaining: {len(list_elements(diagram))}")

    return diagram


def example_mermaid_import():
    """Example: Import from Mermaid syntax."""
    print("\n" + "=" * 60)
    print("Example 3: Importing from Mermaid")
    print("=" * 60)

    mermaid_syntax = """
    graph TD
        A[User Interface] --> B[REST API]
        B --> C{Authentication}
        C -->|Valid| D[Database Query]
        C -->|Invalid| E[Error Response]
        D --> F[(Database)]
        F --> G[Response]
        E --> G
        G --> H[Return to Client]
    """

    print("\nMermaid Syntax:")
    print(mermaid_syntax)

    diagram = mermaid_to_drawio(mermaid_syntax)
    elements = list_elements(diagram)

    print(f"\nConverted to {len(elements)} elements")
    print(f"Vertices: {len([e for e in elements if e['type'] == 'vertex'])}")
    print(f"Edges: {len([e for e in elements if e['type'] == 'edge'])}")

    # Save
    filepath = Path("example_mermaid.drawio")
    xml_content = to_xml(diagram)
    filepath.write_text(xml_content)
    print(f"Saved to: {filepath}")

    return diagram


def example_plantuml_import():
    """Example: Import from PlantUML syntax."""
    print("\n" + "=" * 60)
    print("Example 4: Importing from PlantUML")
    print("=" * 60)

    plantuml_syntax = """
    @startuml
    [Web Application] --> (User)
    [Web Application] --> [API Server]
    [API Server] --> database "PostgreSQL Database"
    [API Server] --> [Cache Service]
    [Cache Service] --> database "Redis Cache"
    @enduml
    """

    print("\nPlantUML Syntax:")
    print(plantuml_syntax)

    diagram = plantuml_to_drawio(plantuml_syntax)
    elements = list_elements(diagram)

    print(f"\nConverted to {len(elements)} elements")
    print(f"Vertices: {len([e for e in elements if e['type'] == 'vertex'])}")
    print(f"Edges: {len([e for e in elements if e['type'] == 'edge'])}")

    # Save
    filepath = Path("example_plantuml.drawio")
    xml_content = to_xml(diagram)
    filepath.write_text(xml_content)
    print(f"Saved to: {filepath}")

    return diagram


def example_shape_gallery():
    """Example: Show all available shapes and colors."""
    print("\n" + "=" * 60)
    print("Example 5: Shape and Color Gallery")
    print("=" * 60)

    diagram = create_empty_diagram("Shape Gallery")

    shapes = [
        "rectangle",
        "rounded",
        "diamond",
        "circle",
        "cylinder",
        "cloud",
        "parallelogram",
        "hexagon",
        "triangle",
        "actor",
        "component",
    ]

    colors = ["blue", "green", "yellow", "red", "purple", "orange", "gray", "pink"]

    # Create shape row
    for i, shape in enumerate(shapes):
        add_vertex(
            diagram,
            f"shape_{i}",
            shape.replace("_", " ").title(),
            i * 120,
            50,
            shape=shape,
            color="blue",
        )

    # Create color column
    for i, color in enumerate(colors):
        add_vertex(
            diagram,
            f"color_{i}",
            color.replace("_", " ").title(),
            50,
            150 + i * 100,
            shape="rectangle",
            color=color,
        )

    elements = list_elements(diagram)
    print(f"\nCreated shape/color gallery with {len(elements)} elements")

    # Save
    filepath = Path("example_gallery.drawio")
    xml_content = to_xml(diagram)
    filepath.write_text(xml_content)
    print(f"Saved to: {filepath}")

    return diagram


def main():
    """Run all examples."""
    print("\n")
    print("╔" + "=" * 58 + "╗")
    print("║" + " " * 10 + "Draw.io MCP Server - Usage Examples" + " " * 14 + "║")
    print("╚" + "=" * 58 + "╝")

    try:
        example_basic_diagram()
        example_modify_diagram()
        example_mermaid_import()
        example_plantuml_import()
        example_shape_gallery()

        print("\n" + "=" * 60)
        print("All examples completed successfully!")
        print("=" * 60)
        print("\nGenerated files:")
        print("  - example_architecture.drawio")
        print("  - example_mermaid.drawio")
        print("  - example_plantuml.drawio")
        print("  - example_gallery.drawio")
        print("\nOpen these files in draw.io or Diagrams.net to view them.")

    except Exception as e:
        print(f"\nError: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    main()
