"""Style mappings for draw.io shapes, colors, and connectors."""

# Shape style mappings
SHAPE_STYLES = {
    "rectangle": "rectangle",
    "rounded": "rounded=1",
    "diamond": "rhombus",
    "circle": "ellipse",
    "cylinder": "cylinder",
    "cloud": "cloud",
    "parallelogram": "parallelogram",
    "hexagon": "hexagon",
    "triangle": "triangle",
    "actor": "actor",
    "component": "component",
    "database": "cylinder",
    "folder": "folder",
    "document": "document",
    "image": "image",
}

# Color palette - professional draw.io colors
COLOR_PALETTE = {
    "blue": {"fill": "#DAE8FC", "stroke": "#6C8EBF"},
    "green": {"fill": "#D5E8D4", "stroke": "#82B366"},
    "yellow": {"fill": "#FFF2CC", "stroke": "#D6B656"},
    "red": {"fill": "#F8CECC", "stroke": "#B85450"},
    "purple": {"fill": "#E1D5E7", "stroke": "#9673A6"},
    "orange": {"fill": "#FFE6CC", "stroke": "#D79B00"},
    "gray": {"fill": "#F5F5F5", "stroke": "#666666"},
    "pink": {"fill": "#F8CBAD", "stroke": "#D4542D"},
    "teal": {"fill": "#D0EEE0", "stroke": "#68A37F"},
    "light_blue": {"fill": "#E1F5FF", "stroke": "#03A9F4"},
}

# Edge/connector style mappings
EDGE_STYLES = {
    "orthogonal": "orthogonalEdgeStyle=1;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;",
    "straight": "edgeStyle=none;straight=1;html=1;",
    "curved": "edgeStyle=orthogonalEdgeStyle;curved=1;html=1;",
    "dashed": "dashed=1;dashPattern=1 4;strokeWidth=2;html=1;",
    "bold": "strokeWidth=3;html=1;",
    "arrow": "endArrow=classic;html=1;",
}

# Font styles for text
FONT_STYLES = {
    "normal": {},
    "bold": {"fontStyle": "1"},
    "italic": {"fontStyle": "2"},
    "underline": {"fontStyle": "4"},
    "bold_italic": {"fontStyle": "3"},
}

# Default style template
DEFAULT_VERTEX_STYLE = "rounded=0;whiteSpace=wrap;html=1;"
DEFAULT_EDGE_STYLE = "rounded=0;orthogonalLoop=1;jettySize=auto;html=1;"

# Layout algorithm constants
GRID_CELL_WIDTH = 200
GRID_CELL_HEIGHT = 150
TREE_LEVEL_HEIGHT = 150
TREE_NODE_SPACING = 200
