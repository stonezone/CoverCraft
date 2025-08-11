# AR Tests Fixtures

This directory contains test fixtures for the AR module, providing realistic and edge-case data for comprehensive testing.

## Overview

The AR fixtures cover three main areas:
- **Mesh Data**: 3D geometric data from AR scanning
- **Calibration Data**: Real-world scaling reference points
- **AR Session Data**: Camera parameters and session configuration

## Fixture Files

### MeshFixtures.swift
Contains various 3D mesh test data:

#### Valid Meshes
- `simpleCube` - Basic 8-vertex cube for fundamental testing
- `singleTriangle` - Minimal valid mesh (3 vertices)
- `tetrahedron` - Simple 4-sided polyhedron
- `tshirtMesh` - Realistic garment with torso and sleeves
- `largeMesh` - 10,000+ vertex mesh for performance testing

#### Invalid/Edge Case Meshes
- `emptyMesh` - No vertices or triangles (invalid)
- `orphanVertices` - Vertices with no connecting triangles
- `invalidTriangleIndices` - References non-existent vertices
- `nonManifoldMesh` - Edges shared by >2 triangles
- `degenerateTriangles` - Zero-area triangles

### CalibrationFixtures.swift
Real-world scaling calibration scenarios:

#### Complete Calibrations
- `ruler30cm` - Standard 30cm ruler measurement
- `tapeMeasure1m` - 1-meter tape measure calibration
- `creditCard` - Credit card dimensions (8.56cm)
- `diagonalMeasure` - 3D diagonal measurements

#### Partial/Error Calibrations
- `emptyCalibration` - No calibration points set
- `firstPointOnly` - Only first point selected
- `zeroDistance` - Invalid zero-distance calibration
- `negativeDistance` - Invalid negative distance

#### Device-Specific Calibrations
- `iphone15ProCalibration` - iPhone 15 Pro LiDAR calibration
- `iPadProCalibration` - iPad Pro calibration parameters

### ARSessionFixtures.swift
AR session configuration and camera data:

#### Camera Intrinsics
- `iphone15ProIntrinsics` - iPhone 15 Pro camera parameters
- `iPadProIntrinsics` - iPad Pro camera specifications
- `genericIntrinsics` - Generic device parameters

#### Camera Poses (Extrinsics)
- `topDownPose` - Camera looking straight down
- `angledPose` - 45-degree camera angle
- `closeUpPose` - Near-distance camera position
- `distantPose` - Far-distance camera position
- `motionSequence` - Series of poses for tracking

#### Session Configurations
- `basicWorldTracking` - Standard AR world tracking
- `highQualityScanning` - High-resolution detailed scanning
- `minimalConfig` - Minimal performance configuration
- `faceTracking` - Face tracking configuration

#### Lighting Conditions
- `brightIndoorLighting` - Well-lit indoor environment
- `dimIndoorLighting` - Low-light indoor conditions
- `outdoorDaylight` - Bright outdoor conditions
- `unknownLighting` - Unknown/variable lighting

## Usage Patterns

### Basic Test Setup
```swift
import Testing
@testable import CoverCraftAR

@Test func basicMeshValidation() {
    let mesh = MeshFixtures.simpleCube
    #expect(mesh.isValid)
    #expect(mesh.triangleCount == 12)
    #expect(mesh.vertices.count == 8)
}
```

### Calibration Testing
```swift
@Test func calibrationScaleCalculation() {
    let calibration = CalibrationFixtures.ruler30cm
    #expect(calibration.isComplete)
    #expect(calibration.scaleFactor > 0)
    #expect(calibration.realWorldDistance == 0.30)
}
```

### AR Session Testing
```swift
@Test func arSessionConfiguration() {
    let config = ARSessionFixtures.basicWorldTracking
    #expect(config.enableLiDAR == true)
    #expect(config.trackingMode == .worldTracking)
}
```

### Error Handling Tests
```swift
@Test func invalidMeshHandling() {
    let mesh = MeshFixtures.emptyMesh
    #expect(!mesh.isValid)
    #expect(mesh.vertices.isEmpty)
    #expect(mesh.triangleIndices.isEmpty)
}
```

### Performance Testing
```swift
@Test func largeMeshPerformance() {
    let mesh = MeshFixtures.largeMesh
    
    measureTime {
        let result = processMesh(mesh)
        #expect(result != nil)
    }
}
```

## Test Categories

### Unit Tests
Use basic fixtures like `simpleCube`, `ruler30cm`, and `basicWorldTracking` for individual component testing.

### Integration Tests  
Use complex fixtures like `tshirtMesh` with complete calibrations for module interaction testing.

### Edge Case Tests
Use invalid fixtures like `emptyMesh`, `zeroDistance` for error handling validation.

### Performance Tests
Use `largeMesh` and `motionSequence` for performance benchmarking.

### Regression Tests
Use specific fixtures that previously caused bugs to prevent regression.

## Best Practices

### Test Organization
- Group related tests using fixture collections (`validMeshes`, `invalidMeshes`)
- Use descriptive test names that indicate expected behavior
- Include both positive and negative test cases

### Data Integrity
- All fixtures use fixed UUIDs and timestamps for deterministic testing
- Mesh data includes realistic geometric properties
- Calibration data covers common real-world scenarios

### Performance Considerations
- Use `randomValidMesh()` for varied test inputs
- `largeMesh` should only be used for performance-specific tests
- Complex fixtures like `tshirtMesh` are for integration testing

### Error Testing
- Always test edge cases and invalid inputs
- Verify graceful error handling
- Check for proper error messages and recovery

## Fixture Maintenance

### Adding New Fixtures
1. Follow existing naming conventions (`descriptiveNameFixture`)
2. Include both valid and invalid variations
3. Add to appropriate collections (`validMeshes`, `allCalibrations`)
4. Update this README with usage examples

### Modifying Fixtures
1. Ensure changes don't break existing tests
2. Maintain backward compatibility where possible
3. Update related test cases
4. Document breaking changes

### Performance Impact
- Keep fixture data reasonably sized
- Use lazy initialization for large fixtures
- Avoid excessive fixture loading in individual tests