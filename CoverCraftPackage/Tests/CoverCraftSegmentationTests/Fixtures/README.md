# Segmentation Tests Fixtures

This directory contains test fixtures for the Segmentation module, providing panel data for testing mesh segmentation algorithms.

## Overview

The Segmentation fixtures focus on:
- **Panel Definitions**: 3D panel structures with vertices and triangles
- **Color Schemes**: Various coloring approaches for panel visualization
- **Geometric Shapes**: From basic shapes to complex garment panels
- **Edge Cases**: Invalid panels and error conditions

## Fixture Files

### PanelFixtures.swift
Contains comprehensive panel test data:

#### Basic Geometric Shapes
- `rectangularPanel` - Simple 4-vertex rectangular panel
- `triangularPanel` - Minimal 3-vertex triangular panel  
- `complexPolygonPanel` - Multi-vertex irregular polygon

#### T-Shirt Panel Set (Realistic Garment)
- `frontTorso` - Front body panel with neck and chest shaping
- `backTorso` - Back body panel with different neckline
- `leftSleeve` - Left arm panel with shoulder attachment
- `rightSleeve` - Right arm panel (mirrored left)

#### Edge Cases and Invalid Panels
- `emptyPanel` - No vertices or triangles (invalid)
- `orphanVerticesPanel` - Vertices without triangles
- `invalidTriangleCount` - Triangle indices not divisible by 3
- `mismatchedVertices` - Triangles reference missing vertices
- `singleVertexPanel` - Degenerate single-point panel

#### Segmentation Algorithm Test Cases
- `connectedComponent1` - First connected mesh region
- `connectedComponent2` - Second connected mesh region
- `panelWithHoles` - Non-simply connected panel with holes

#### Large Scale Test Data
- `largePanelWithManyTriangles` - 100+ vertex panel for performance testing

## Color Schemes

### Rainbow Colors
Seven-color scheme for multi-panel visualization:
```swift
let panels = PanelFixtures.panelsWithColors(PanelFixtures.rainbowColors)
```

### Monochrome (Grayscale)
Five-shade grayscale for accessibility testing:
```swift
let panels = PanelFixtures.panelsWithColors(PanelFixtures.monochromeColors)
```

### Pastel Colors
Soft colors for aesthetic testing:
```swift
let panels = PanelFixtures.panelsWithColors(PanelFixtures.pastelColors)
```

## Usage Patterns

### Basic Panel Validation
```swift
import Testing
@testable import CoverCraftSegmentation

@Test func panelValidation() {
    let panel = PanelFixtures.rectangularPanel
    #expect(panel.isValid)
    #expect(panel.triangleCount == 2)
    #expect(panel.vertexIndices.count == 4)
}
```

### Segmentation Algorithm Testing
```swift
@Test func meshSegmentation() {
    let mesh = MeshFixtures.tshirtMesh
    let expectedPanels = PanelFixtures.tshirtPanelSet
    
    let segmentedPanels = segmentMesh(mesh)
    #expect(segmentedPanels.count == expectedPanels.count)
    #expect(segmentedPanels.allSatisfy { $0.isValid })
}
```

### Color Assignment Testing
```swift
@Test func panelColoring() {
    let panels = PanelFixtures.panelsWithColors(PanelFixtures.rainbowColors)
    
    #expect(panels.count == PanelFixtures.rainbowColors.count)
    #expect(panels[0].color == ColorDTO.red)
    #expect(panels[1].color.green > 0.9) // Orange has high green
}
```

### Edge Case Validation
```swift
@Test func invalidPanelHandling() {
    let panel = PanelFixtures.emptyPanel
    #expect(!panel.isValid)
    #expect(panel.vertexIndices.isEmpty)
    #expect(panel.triangleIndices.isEmpty)
}
```

### Connected Components Testing
```swift
@Test func connectedComponentExtraction() {
    let mesh = MeshFixtures.complexMesh
    let components = extractConnectedComponents(mesh)
    
    // Should match our test components
    let expectedComponent1 = PanelFixtures.connectedComponent1
    let expectedComponent2 = PanelFixtures.connectedComponent2
    
    #expect(components.count == 2)
    #expect(components.contains { $0.vertexIndices == expectedComponent1.vertexIndices })
}
```

### Performance Testing
```swift
@Test func largeScaleSegmentation() {
    let largeMesh = MeshFixtures.largeMesh
    
    measureTime {
        let panels = segmentMesh(largeMesh)
        #expect(panels.count > 0)
        #expect(panels.allSatisfy { $0.isValid })
    }
}
```

## Test Categories

### Unit Tests - Basic Functionality
Use simple fixtures:
- `rectangularPanel` for basic validation
- `triangularPanel` for minimal cases
- Individual color tests

### Integration Tests - Complex Scenarios  
Use realistic fixtures:
- `tshirtPanelSet` for complete garment testing
- `complexPolygonPanel` for algorithm robustness
- Multiple connected components

### Edge Case Tests - Error Handling
Use invalid fixtures:
- `emptyPanel` for null checks
- `invalidTriangleCount` for format validation
- `mismatchedVertices` for index validation

### Performance Tests - Scalability
Use large fixtures:
- `largePanelWithManyTriangles` for performance benchmarks
- Batch processing multiple panels
- Memory usage validation

### Regression Tests - Bug Prevention
Use previously problematic cases:
- `panelWithHoles` (caused topology issues)
- `singleVertexPanel` (caused crashes)
- Degenerate cases that revealed bugs

## Algorithm-Specific Testing

### Connectivity Analysis
```swift
@Test func connectivityAnalysis() {
    let mesh = MeshFixtures.nonManifoldMesh
    let panels = segmentMesh(mesh)
    
    // Non-manifold mesh should be handled gracefully
    #expect(panels.allSatisfy { validateTopology($0) })
}
```

### Seam Line Detection
```swift
@Test func seamLineIdentification() {
    let mesh = MeshFixtures.tshirtMesh
    let panels = segmentMesh(mesh)
    
    // T-shirt should have seam lines between panels
    let frontPanel = panels.first { $0.id == PanelFixtures.frontTorso.id }
    let backPanel = panels.first { $0.id == PanelFixtures.backTorso.id }
    
    #expect(findSeamLine(frontPanel, backPanel) != nil)
}
```

### Panel Optimization
```swift
@Test func panelOptimization() {
    let unoptimizedPanel = PanelFixtures.complexPolygonPanel
    let optimized = optimizePanel(unoptimizedPanel)
    
    // Optimization should reduce complexity while preserving shape
    #expect(optimized.triangleCount <= unoptimizedPanel.triangleCount)
    #expect(calculateArea(optimized) ≈ calculateArea(unoptimizedPanel))
}
```

## Factory Methods

### Dynamic Panel Generation
```swift
// Create panel with specific vertex count
let panel = PanelFixtures.panelWithVertexCount(8)

// Create panel with specific color
let redPanel = PanelFixtures.panelWithColor(ColorDTO.red)

// Create set of panels with colors
let coloredPanels = PanelFixtures.panelsWithColors([.red, .green, .blue])

// Get random valid panel for varied testing
let randomPanel = PanelFixtures.randomValidPanel()
```

## Best Practices

### Test Data Selection
- Use `basicShapes` for algorithm validation
- Use `tshirtPanelSet` for realistic scenarios
- Use `invalidPanels` for error handling
- Use `largePanelWithManyTriangles` sparingly (performance only)

### Color Testing
- Test with different color schemes for accessibility
- Verify color preservation through processing pipeline
- Check color-blind friendly combinations

### Validation Patterns
```swift
// Always validate panel integrity
#expect(panel.isValid)

// Check vertex-triangle consistency
#expect(panel.triangleIndices.allSatisfy { 
    $0 >= 0 && $0 < totalVertexCount 
})

// Verify no duplicate vertices in set
#expect(panel.vertexIndices.count == Set(panel.vertexIndices).count)
```

### Performance Considerations
- Load large fixtures only when needed
- Use collections for batch operations
- Profile memory usage with large panel sets

## Fixture Maintenance

### Adding New Panels
1. Follow naming convention: `descriptiveNamePanel`
2. Ensure geometric validity
3. Add to appropriate collection (`validPanels`, `invalidPanels`)
4. Include color assignment
5. Update README with usage example

### Modifying Existing Panels
1. Check impact on existing tests
2. Maintain deterministic UUIDs
3. Preserve geometric relationships
4. Update dependent collections

### Quality Assurance
- All valid panels must pass `isValid` check
- Triangle indices must reference existing vertices
- Colors must be valid ColorDTO instances
- Large panels should be performance-tested