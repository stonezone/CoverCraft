# Flattening Tests Fixtures

This directory contains test fixtures for the Flattening module, providing 2D flattened panel data for testing pattern generation algorithms.

## Overview

The Flattening fixtures provide:
- **2D Panel Layouts**: Flattened representations of 3D panels
- **Edge Definitions**: Cut lines, fold lines, seam allowances
- **Scale Variations**: Different measurement units and scales
- **Layout Optimization**: Various 2D arrangements and orientations

## Fixture Files

### FlattenedPanelFixtures.swift
Contains comprehensive 2D pattern data:

#### Basic Flattened Shapes
- `rectangularFlattened` - Simple rectangle (10cm x 15cm)
- `triangularFlattened` - Equilateral triangle
- `hexagonFlattened` - Regular hexagon shape

#### T-Shirt Flattened Panels (Realistic Pattern Set)
- `frontTorsoFlattened` - Front body with neck and armhole curves
- `backTorsoFlattened` - Back body with higher neckline
- `leftSleeveFlattened` - Left sleeve with attachment curves
- `rightSleeveFlattened` - Right sleeve (mirrored left)

#### Edge Cases and Invalid Panels
- `emptyFlattened` - No points or edges (invalid)
- `singlePointFlattened` - Single point (degenerate)
- `lineSegmentFlattened` - Two points only (1D)
- `invalidEdgeIndices` - Edges reference non-existent points
- `zeroScaleFlattened` - Invalid zero scale factor
- `negativeScaleFlattened` - Invalid negative scale

#### Scale Variations
- `millimeterScale` - 1000 units per meter (precise)
- `centimeterScale` - 100 units per meter (standard)
- `inchScale` - 39.37 units per meter (imperial)

#### Edge Type Examples
- `allEdgeTypesPanel` - Panel with all edge types:
  - Cut lines (solid)
  - Fold lines (dashed)
  - Seam allowances (dotted)
  - Registration marks (alignment)

#### Performance Testing
- `largeFlattened` - 100+ point circular pattern

## Edge Types

### EdgeType Enumeration
```swift
public enum EdgeType: String, CaseIterable {
    case cutLine = "cut"           // Edge to be cut
    case foldLine = "fold"         // Edge to be folded  
    case seamAllowance = "seam"    // Seam allowance edge
    case registrationMark = "registration" // Alignment mark
}
```

### Usage in Patterns
- **Cut Lines**: Outer perimeter, pattern boundaries
- **Fold Lines**: Darts, pleats, construction folds
- **Seam Allowances**: Extra material for joining panels
- **Registration Marks**: Notches, alignment points

## Usage Patterns

### Basic Flattening Validation
```swift
import Testing
@testable import CoverCraftFlattening

@Test func flattenedPanelValidation() {
    let panel = FlattenedPanelFixtures.rectangularFlattened
    #expect(panel.isValid)
    #expect(panel.points2D.count == 4)
    #expect(panel.edges.count == 4)
    #expect(panel.scaleUnitsPerMeter > 0)
}
```

### Area Calculation Testing
```swift
@Test func areaCalculation() {
    let panel = FlattenedPanelFixtures.rectangularFlattened
    let expectedArea = 100.0 * 150.0 // 10cm × 15cm in mm²
    
    #expect(abs(panel.area - expectedArea) < 1.0)
}
```

### Bounding Box Testing
```swift
@Test func boundingBoxCalculation() {
    let panel = FlattenedPanelFixtures.rectangularFlattened
    let bounds = panel.boundingBox
    
    #expect(bounds.width == 100.0)
    #expect(bounds.height == 150.0)
    #expect(bounds.origin.x == 0.0)
    #expect(bounds.origin.y == 0.0)
}
```

### Scale Conversion Testing
```swift
@Test func scaleConversion() {
    let mmPanel = FlattenedPanelFixtures.millimeterScale
    let cmPanel = FlattenedPanelFixtures.centimeterScale
    
    // Same real-world size, different scales
    #expect(mmPanel.scaleUnitsPerMeter == 1000.0)
    #expect(cmPanel.scaleUnitsPerMeter == 100.0)
    
    // Convert to real-world dimensions
    let mmRealWidth = mmPanel.boundingBox.width / mmPanel.scaleUnitsPerMeter
    let cmRealWidth = cmPanel.boundingBox.width / cmPanel.scaleUnitsPerMeter
    
    #expect(abs(mmRealWidth - cmRealWidth) < 0.001)
}
```

### Edge Type Testing
```swift
@Test func edgeTypeHandling() {
    let panel = FlattenedPanelFixtures.allEdgeTypesPanel
    
    let cutLines = panel.edges.filter { $0.type == .cutLine }
    let foldLines = panel.edges.filter { $0.type == .foldLine }
    let seamLines = panel.edges.filter { $0.type == .seamAllowance }
    let regMarks = panel.edges.filter { $0.type == .registrationMark }
    
    #expect(cutLines.count > 0)
    #expect(foldLines.count > 0)
    #expect(seamLines.count > 0)
    #expect(regMarks.count > 0)
}
```

### T-Shirt Pattern Testing
```swift
@Test func completeTshirtPattern() {
    let tshirtSet = FlattenedPanelFixtures.tshirtFlattenedSet
    
    #expect(tshirtSet.count == 4) // Front, back, 2 sleeves
    #expect(tshirtSet.allSatisfy { $0.isValid })
    
    // All panels should have same scale
    let scales = Set(tshirtSet.map { $0.scaleUnitsPerMeter })
    #expect(scales.count == 1)
}
```

### Layout Optimization Testing
```swift
@Test func layoutOptimization() {
    let panels = FlattenedPanelFixtures.tshirtFlattenedSet
    let optimized = optimizeLayout(panels, paperSize: CGSize(width: 594, height: 841)) // A4
    
    // All panels should fit within bounds
    for panel in optimized {
        let bounds = panel.boundingBox
        #expect(bounds.maxX <= 594)
        #expect(bounds.maxY <= 841)
    }
}
```

### Error Handling Tests
```swift
@Test func invalidFlattenedPanelHandling() {
    let empty = FlattenedPanelFixtures.emptyFlattened
    #expect(!empty.isValid)
    #expect(empty.area == 0.0)
    
    let zeroScale = FlattenedPanelFixtures.zeroScaleFlattened
    #expect(!zeroScale.isValid)
    #expect(zeroScale.scaleUnitsPerMeter == 0.0)
    
    let invalidEdges = FlattenedPanelFixtures.invalidEdgeIndices
    #expect(!invalidEdges.isValid)
}
```

## Test Categories

### Unit Tests - Core Functionality
Use basic fixtures:
- `rectangularFlattened` for area/bounds calculations
- `triangularFlattened` for minimal polygon cases
- Individual edge type validation

### Integration Tests - Pattern Generation
Use realistic fixtures:
- `tshirtFlattenedSet` for complete patterns
- `allEdgeTypesPanel` for comprehensive edge handling
- Scale conversion between panels

### Edge Case Tests - Robustness
Use invalid fixtures:
- `emptyFlattened` for null/empty validation
- `singlePointFlattened` for degenerate cases
- `invalidEdgeIndices` for bounds checking

### Performance Tests - Scalability
Use complex fixtures:
- `largeFlattened` for algorithm performance
- Batch processing multiple panels
- Memory usage with large point sets

### Layout Tests - Arrangement
Use panel sets:
- Fitting panels within paper boundaries
- Minimizing material waste
- Optimal rotation and positioning

## Algorithm-Specific Testing

### Area Preservation
```swift
@Test func areaPreservationDuringFlattening() {
    let panel3D = PanelFixtures.frontTorso
    let panelFlat = FlattenedPanelFixtures.frontTorsoFlattened
    
    // 3D surface area should approximately equal 2D area (with distortion tolerance)
    let area3D = calculate3DSurfaceArea(panel3D)
    let area2D = panelFlat.area
    
    let distortionFactor = abs(area2D - area3D) / area3D
    #expect(distortionFactor < 0.1) // Less than 10% distortion
}
```

### Self-Intersection Detection
```swift
@Test func selfIntersectionDetection() {
    let panel = FlattenedPanelFixtures.hexagonFlattened
    #expect(!hasSelfIntersections(panel))
    
    // Create problematic panel for testing
    let selfIntersecting = createSelfIntersectingPanel()
    #expect(hasSelfIntersections(selfIntersecting))
}
```

### Seam Allowance Addition
```swift
@Test func seamAllowanceGeneration() {
    let basePanel = FlattenedPanelFixtures.rectangularFlattened
    let withSeams = addSeamAllowances(basePanel, width: 15.0) // 1.5cm seams
    
    // Panel with seams should be larger
    #expect(withSeams.boundingBox.width > basePanel.boundingBox.width)
    #expect(withSeams.boundingBox.height > basePanel.boundingBox.height)
    
    // Should have seam allowance edges
    let seamEdges = withSeams.edges.filter { $0.type == .seamAllowance }
    #expect(seamEdges.count > 0)
}
```

## Factory Methods

### Dynamic Panel Generation
```swift
// Create square panel
let square = FlattenedPanelFixtures.squareFlattened(size: 50.0, scale: 1000.0)

// Create regular polygon
let pentagon = FlattenedPanelFixtures.regularPolygonFlattened(
    sides: 5, 
    radius: 30.0, 
    scale: 1000.0
)

// Create panel with specific edge type
let foldPanel = FlattenedPanelFixtures.flattenedPanelWithEdgeType(.foldLine)

// Get random valid panel
let random = FlattenedPanelFixtures.randomValidFlattenedPanel()
```

## Best Practices

### Coordinate System
- All coordinates are positive (top-left origin)
- Units match scale factor (typically millimeters)
- Y-axis points downward (screen coordinates)

### Scale Factor Usage
```swift
// Convert from pattern units to real-world meters
let realWidth = panel.boundingBox.width / panel.scaleUnitsPerMeter

// Convert from real-world meters to pattern units  
let patternWidth = realWidthMeters * panel.scaleUnitsPerMeter
```

### Edge Validation
```swift
// Ensure all edge indices are valid
for edge in panel.edges {
    #expect(edge.startIndex >= 0 && edge.startIndex < panel.points2D.count)
    #expect(edge.endIndex >= 0 && edge.endIndex < panel.points2D.count)
    #expect(edge.startIndex != edge.endIndex) // No self-edges
}
```

### Performance Considerations
- Large panels (100+ points) only for performance tests
- Batch operations when processing multiple panels
- Use appropriate scale factors (avoid very small/large numbers)

## Fixture Maintenance

### Adding New Panels
1. Use descriptive naming: `descriptiveNameFlattened`
2. Include realistic scale factors
3. Define appropriate edge types
4. Add to relevant collections
5. Validate geometric properties

### Scale Consistency
- Use standard scales: 1000 (mm), 100 (cm), 39.37 (inches)
- Keep real-world dimensions reasonable
- Test cross-scale compatibility

### Edge Type Coverage
- Include all edge types in test suites
- Validate edge type preservation
- Test rendering differences

### Quality Assurance
- All valid panels pass `isValid` check
- Calculated areas are reasonable
- Bounding boxes are correct
- No self-intersecting edges