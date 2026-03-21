# draw.io XML Format Reference

## File Structure

Every `.drawio` file follows this structure:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" modified="2026-03-20T00:00:00.000Z" agent="Claude" version="26.0">
  <diagram name="Page-1" id="page1">
    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <!-- diagram elements here -->
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

The two structural cells (id="0" and id="1") are **always required**. All other elements are children of cell "1" (or of a container).

## mxGraphModel Attributes

- `dx`, `dy`: Canvas offset (use 1200, 800 as defaults)
- `grid="1"`: Show grid
- `gridSize="10"`: Grid spacing in pixels
- `pageWidth`, `pageHeight`: Page dimensions (850x1100 for US Letter, 1169x827 for A4 landscape)

## Vertices (Shapes)

```xml
<mxCell id="unique_id" value="Display Text" style="style;properties;here;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="120" height="60" as="geometry" />
</mxCell>
```

### Common Shape Styles

#### Rectangles
```
whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;
```

#### Rounded Rectangles
```
rounded=1;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;
```

#### Diamond (Decision/Rhombus)
```
rhombus;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;
```

#### Ellipse/Circle
```
ellipse;whiteSpace=wrap;html=1;fillColor=#D5E8D4;strokeColor=#82B366;
```

#### Cylinder (Database)
```
shape=cylinder3;whiteSpace=wrap;html=1;boundedLbl=1;backgroundOutline=1;size=15;fillColor=#E1D5E7;strokeColor=#9673A6;
```

#### Parallelogram (I/O)
```
shape=parallelogram;perimeter=parallelogramPerimeter;whiteSpace=wrap;html=1;fixedSize=1;
```

#### Cloud
```
ellipse;shape=cloud;whiteSpace=wrap;html=1;fillColor=#E1F5FE;strokeColor=#0288D1;
```

#### Hexagon
```
shape=hexagon;perimeter=hexagonPerimeter2;whiteSpace=wrap;html=1;fixedSize=1;size=15;
```

#### Triangle
```
triangle;whiteSpace=wrap;html=1;
```

#### Document Shape
```
shape=document;whiteSpace=wrap;html=1;boundedLbl=1;backgroundOutline=1;size=0.27;
```

#### Person/Actor
```
shape=mxgraph.basic.person;whiteSpace=wrap;html=1;
```

## Edges (Connectors)

```xml
<mxCell id="edge_id" value="label" style="edge;styles;here;" edge="1" parent="1" source="source_id" target="target_id">
  <mxGeometry relative="1" as="geometry" />
</mxCell>
```

### Edge Routing Styles

#### Orthogonal (right-angle, most common)
```
edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;jettySize=auto;html=1;
```

#### Straight Line
```
html=1;
```

#### Curved
```
curved=1;html=1;
```

#### Entity Relation (for ERD)
```
edgeStyle=entityRelationEdgeStyle;html=1;
```

### Arrow Types

| Arrow Style          | Style Property              |
|---------------------|-----------------------------|
| Classic arrow       | `endArrow=classic;endFill=1;` |
| Open arrow          | `endArrow=open;endFill=0;`   |
| Block (inheritance) | `endArrow=block;endFill=0;`  |
| Diamond (aggregation) | `endArrow=diamond;endFill=0;` |
| Diamond filled (composition) | `endArrow=diamond;endFill=1;` |
| Circle              | `endArrow=oval;endFill=1;`   |
| No arrow            | `endArrow=none;`            |
| Bidirectional       | `startArrow=classic;startFill=1;endArrow=classic;endFill=1;` |

### Dashed Lines
```
dashed=1;dashPattern=8 8;
```

### Edge Labels with Positioning
```xml
<mxCell id="edge1" value="label text" style="edgeStyle=orthogonalEdgeStyle;html=1;" edge="1" parent="1" source="a" target="b">
  <mxGeometry relative="1" as="geometry">
    <mxPoint as="offset" />
  </mxGeometry>
</mxCell>
```

### Edge with Waypoints
```xml
<mxCell id="edge1" style="edgeStyle=orthogonalEdgeStyle;html=1;" edge="1" parent="1" source="a" target="b">
  <mxGeometry relative="1" as="geometry">
    <Array as="points">
      <mxPoint x="300" y="200" />
      <mxPoint x="300" y="350" />
    </Array>
  </mxGeometry>
</mxCell>
```

## Style Properties Reference

### Shape Properties
| Property        | Values              | Description               |
|----------------|---------------------|---------------------------|
| `fillColor`    | `#RRGGBB`          | Background color          |
| `strokeColor`  | `#RRGGBB`          | Border color              |
| `strokeWidth`  | number              | Border thickness (default: 1) |
| `rounded`      | `0` or `1`         | Rounded corners           |
| `dashed`       | `0` or `1`         | Dashed border             |
| `opacity`      | `0-100`            | Transparency              |
| `shadow`       | `0` or `1`         | Drop shadow               |
| `glass`        | `0` or `1`         | Glass effect              |

### Text Properties
| Property         | Values                      | Description            |
|-----------------|-----------------------------|------------------------|
| `fontSize`      | number                      | Font size (px)         |
| `fontFamily`    | font name                   | e.g., `Helvetica`     |
| `fontColor`     | `#RRGGBB`                   | Text color             |
| `fontStyle`     | bitmask                     | 1=bold, 2=italic, 4=underline (combine: 3=bold+italic) |
| `align`         | `left`, `center`, `right`   | Horizontal alignment   |
| `verticalAlign` | `top`, `middle`, `bottom`   | Vertical alignment     |
| `whiteSpace`    | `wrap`                      | Enable text wrapping   |
| `html`          | `1`                         | Enable HTML in labels  |

### Layout Properties
| Property           | Values       | Description                        |
|-------------------|--------------|------------------------------------|
| `spacing`          | number       | All-sides padding                  |
| `spacingTop`       | number       | Top padding                        |
| `spacingBottom`    | number       | Bottom padding                     |
| `spacingLeft`      | number       | Left padding                       |
| `spacingRight`     | number       | Right padding                      |
| `labelPosition`    | `left`, `center`, `right` | Label horizontal position |
| `verticalLabelPosition` | `top`, `middle`, `bottom` | Label vertical position |

## Containers and Groups

### Swimlane
```xml
<mxCell id="lane1" value="Department A" style="swimlane;startSize=30;html=1;fillColor=#F5F5F5;strokeColor=#666666;fontStyle=1;" vertex="1" parent="1">
  <mxGeometry x="50" y="50" width="400" height="300" as="geometry" />
</mxCell>

<!-- Child elements use the swimlane id as parent -->
<mxCell id="child1" value="Task" style="whiteSpace=wrap;html=1;" vertex="1" parent="lane1">
  <mxGeometry x="30" y="50" width="120" height="60" as="geometry" />
</mxCell>
```

Child coordinates are **relative to the container**, not the canvas.

### Horizontal Swimlane Pool
```xml
<!-- Pool header -->
<mxCell id="pool" value="Process" style="shape=table;startSize=30;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=0;fontStyle=1;strokeColor=#666666;fillColor=#F5F5F5;" vertex="1" parent="1">
  <mxGeometry x="50" y="50" width="700" height="400" as="geometry" />
</mxCell>
```

### Generic Group
```xml
<mxCell id="group1" style="group;" vertex="1" connectable="0" parent="1">
  <mxGeometry x="100" y="100" width="300" height="200" as="geometry" />
</mxCell>
```

## Multi-line Text in Values

Use `&#10;` for newlines within the `value` attribute:

```xml
<mxCell id="class1" value="ClassName&#10;--&#10;+field1: String&#10;+field2: int&#10;--&#10;+method1()&#10;+method2()" style="..." vertex="1" parent="1">
```

For HTML-formatted text, use `<br>` tags with `html=1` in the style:
```xml
<mxCell id="rich1" value="&lt;b&gt;Title&lt;/b&gt;&lt;br&gt;Description" style="html=1;whiteSpace=wrap;" vertex="1" parent="1">
```

## XML Escaping Rules

| Character | Escape     |
|-----------|-----------|
| `<`       | `&lt;`    |
| `>`       | `&gt;`    |
| `&`       | `&amp;`   |
| `"`       | `&quot;`  |
| newline   | `&#10;`   |

## Color Palette Quick Reference

### Professional Theme
```
Blue:     fill=#DAE8FC  stroke=#6C8EBF
Green:    fill=#D5E8D4  stroke=#82B366
Yellow:   fill=#FFF2CC  stroke=#D6B656
Red:      fill=#F8CECC  stroke=#B85450
Purple:   fill=#E1D5E7  stroke=#9673A6
Orange:   fill=#FFE6CC  stroke=#D79B00
Gray:     fill=#F5F5F5  stroke=#666666
Cyan:     fill=#E1F5FE  stroke=#0288D1
```

### Dark Theme
```
Dark Blue:    fill=#1A1A2E  stroke=#4A9BD9  fontColor=#FFFFFF
Dark Green:   fill=#1A2E1A  stroke=#4AD94A  fontColor=#FFFFFF
Dark Purple:  fill=#2E1A2E  stroke=#9B4AD9  fontColor=#FFFFFF
Dark Gray:    fill=#2D2D2D  stroke=#808080  fontColor=#FFFFFF
```

## Complete Flowchart Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net">
  <diagram name="Flowchart" id="flowchart1">
    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />

        <mxCell id="start" value="Start" style="ellipse;whiteSpace=wrap;html=1;fillColor=#D5E8D4;strokeColor=#82B366;fontSize=14;" vertex="1" parent="1">
          <mxGeometry x="345" y="30" width="100" height="60" as="geometry" />
        </mxCell>

        <mxCell id="input" value="Get User Input" style="shape=parallelogram;perimeter=parallelogramPerimeter;whiteSpace=wrap;html=1;fixedSize=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;fontSize=12;" vertex="1" parent="1">
          <mxGeometry x="325" y="130" width="140" height="60" as="geometry" />
        </mxCell>

        <mxCell id="validate" value="Is Input Valid?" style="rhombus;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;fontSize=12;" vertex="1" parent="1">
          <mxGeometry x="345" y="230" width="100" height="100" as="geometry" />
        </mxCell>

        <mxCell id="error" value="Show Error" style="whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;fontSize=12;" vertex="1" parent="1">
          <mxGeometry x="540" y="250" width="120" height="60" as="geometry" />
        </mxCell>

        <mxCell id="process" value="Process Data" style="whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;fontSize=12;" vertex="1" parent="1">
          <mxGeometry x="335" y="380" width="120" height="60" as="geometry" />
        </mxCell>

        <mxCell id="end" value="End" style="ellipse;whiteSpace=wrap;html=1;fillColor=#D5E8D4;strokeColor=#82B366;fontSize=14;" vertex="1" parent="1">
          <mxGeometry x="345" y="490" width="100" height="60" as="geometry" />
        </mxCell>

        <!-- Edges -->
        <mxCell id="e1" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=classic;endFill=1;" edge="1" parent="1" source="start" target="input">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e2" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=classic;endFill=1;" edge="1" parent="1" source="input" target="validate">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e3" value="No" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=classic;endFill=1;" edge="1" parent="1" source="validate" target="error">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e4" value="Yes" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=classic;endFill=1;" edge="1" parent="1" source="validate" target="process">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e5" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=classic;endFill=1;" edge="1" parent="1" source="error" target="input">
          <mxGeometry relative="1" as="geometry">
            <Array as="points">
              <mxPoint x="600" y="160" />
              <mxPoint x="395" y="160" />
            </Array>
          </mxGeometry>
        </mxCell>
        <mxCell id="e6" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=classic;endFill=1;" edge="1" parent="1" source="process" target="end">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```
