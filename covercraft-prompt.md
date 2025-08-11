# CoverCraft iOS App Generation Instructions

You are tasked with creating a complete, production-ready iOS app called CoverCraft that generates sewing patterns from LiDAR scans. This will be delivered as a fully functional Xcode project.

## Core Requirements

Create an iOS app that:
1. Uses LiDAR to scan objects (iPhone 12 Pro and later)
2. Allows calibration by measuring real-world distance between two points
3. Segments the scanned mesh into panels (5 for low, 8 for medium, 15 for high resolution)
4. Flattens the 3D panels into 2D sewing patterns
5. Exports patterns as PNG, GIF, SVG, and PDF with scale reference

## Project Structure

Create the following directory structure:
```
CoverCraft/
├── CoverCraft.xcodeproj
├── CoverCraft/
│   ├── App/
│   │   ├── CoverCraftApp.swift
│   │   ├── Info.plist
│   │   └── Assets.xcassets
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── Mesh.swift
│   │   │   ├── Panel.swift
│   │   │   └── CalibrationData.swift
│   │   ├── Services/
│   │   │   ├── MeshSegmentationService.swift
│   │   │   ├── PatternFlattener.swift
│   │   │   └── PatternExporter.swift
│   │   └── Protocols/
│   │       └── ServiceProtocols.swift
│   ├── Features/
│   │   ├── Scanning/
│   │   │   ├── ARScanViewController.swift
│   │   │   ├── ARScanView.swift
│   │   │   └── ScanViewModel.swift
│   │   ├── Calibration/
│   │   │   ├── CalibrationView.swift
│   │   │   └── CalibrationViewModel.swift
│   │   ├── Segmentation/
│   │   │   ├── SegmentationView.swift
│   │   │   ├── SegmentationPreview.swift
│   │   │   └── SegmentationViewModel.swift
│   │   └── Export/
│   │       ├── PatternPreview.swift
│   │       └── ExportViewModel.swift
│   ├── Shared/
│   │   ├── Views/
│   │   │   └── HelpView.swift
│   │   └── Extensions/
│   │       └── UIExtensions.swift
│   └── Resources/
│       └── Localizable.strings
├── CoverCraftTests/
│   ├── CoreTests/
│   │   ├── MeshSegmentationTests.swift
│   │   └── PatternFlattenerTests.swift
│   └── Mocks/
│       └── MockServices.swift
└── README.md
```

## Implementation Guidelines

### CRITICAL: Code Quality Rules
- **USE DESCRIPTIVE VARIABLE NAMES** - No single letters except loop indices
- **ADD COMMENTS** for complex algorithms
- **IMPLEMENT ERROR HANDLING** - No force unwrapping, use guard/if-let
- **FOLLOW MVVM PATTERN** - ViewModels handle business logic
- **USE DEPENDENCY INJECTION** - Pass services through initializers

### Module 1: Core Models
```swift
// Mesh.swift - Use clear, descriptive names
struct Mesh {
    var vertices: [SIMD3<Float>]
    var triangleIndices: [Int] // Groups of 3
    var faceNormals: [SIMD3<Float>]
    
    var triangleCount: Int { triangleIndices.count / 3 }
}

// Panel.swift
struct Panel {
    let identifier: UUID
    var vertexIndices: Set<Int>
    var triangleIndices: [Int]
    var color: UIColor // For visualization
}

// CalibrationData.swift
struct CalibrationData {
    var firstPoint: SIMD3<Float>?
    var secondPoint: SIMD3<Float>?
    var realWorldDistance: Float = 1.0 // meters
    
    var scaleFactor: Float {
        guard let p1 = firstPoint, let p2 = secondPoint else { return 1.0 }
        let meshDistance = simd_distance(p1, p2)
        return meshDistance > 0 ? realWorldDistance / meshDistance : 1.0
    }
}
```

### Module 2: AR Scanning
Implement ARKit scanning with proper lifecycle management:
- Use ARSCNView for visualization
- Implement ARSessionDelegate for mesh updates
- Add coaching overlay for user guidance
- Store mesh data progressively, not all at once
- Include "Finish Scan" button
- Proper error handling for non-LiDAR devices

### Module 3: Mesh Segmentation
```swift
// Use k-means clustering with clear implementation
class MeshSegmentationService {
    func segmentMesh(_ mesh: Mesh, targetPanelCount: Int) -> [Panel] {
        // Step 1: Compute face normals
        let faceNormals = computeFaceNormals(for: mesh)
        
        // Step 2: Cluster faces by normal similarity
        let clusterAssignments = performKMeansClustering(
            normals: faceNormals,
            clusterCount: targetPanelCount
        )
        
        // Step 3: Group connected faces
        let panels = groupConnectedFaces(
            mesh: mesh,
            clusterAssignments: clusterAssignments
        )
        
        // Step 4: Balance panel sizes if needed
        return balancePanelSizes(panels, targetCount: targetPanelCount)
    }
    
    // Include clear, documented helper methods
}
```

### Module 4: Pattern Flattening
Use spring-mass relaxation with clear physics:
```swift
class PatternFlattener {
    func flattenPanel(_ panel: Panel, from mesh: Mesh) -> FlattenedPanel {
        // Project to 2D plane
        let projectedPoints = projectToPlane(panel: panel, mesh: mesh)
        
        // Apply spring relaxation to preserve edge lengths
        let relaxedPoints = applySpringRelaxation(
            points: projectedPoints,
            targetEdgeLengths: computeEdgeLengths(panel: panel, mesh: mesh),
            iterations: 200
        )
        
        return FlattenedPanel(points2D: relaxedPoints, sourcePanel: panel)
    }
}
```

### Module 5: Export System
Create a comprehensive export system:
```swift
class PatternExporter {
    func exportPattern(_ panels: [FlattenedPanel], format: ExportFormat) -> URL {
        switch format {
        case .png:
            return exportAsPNG(panels, resolution: 150) // DPI
        case .gif:
            return exportAsGIF(panels)
        case .svg:
            return exportAsSVG(panels)
        case .pdfLetter:
            return exportAsPDF(panels, pageSize: .letter)
        case .pdfA4:
            return exportAsPDF(panels, pageSize: .a4)
        }
    }
    
    // PDF should be 1:1 scale with tiling for large patterns
    private func exportAsPDF(_ panels: [FlattenedPanel], pageSize: PageSize) -> URL {
        // Include crop marks
        // Add 10cm scale reference
        // Tile across multiple pages if needed
        // Add page numbers and assembly marks
    }
}
```

### Module 6: User Interface
Use SwiftUI with proper state management:
```swift
// Main navigation flow
struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        NavigationStack {
            List {
                Section("1. Scan Object") {
                    NavigationLink("Start LiDAR Scan", 
                                 destination: ARScanView(viewModel: scanViewModel))
                    if appState.hasMesh {
                        MeshStatistics(mesh: appState.currentMesh)
                    }
                }
                
                Section("2. Calibration") {
                    NavigationLink("Set Real-World Scale",
                                 destination: CalibrationView(viewModel: calibrationViewModel))
                    if appState.isCalibrated {
                        ScaleDisplay(scale: appState.calibrationData.scaleFactor)
                    }
                }
                
                Section("3. Panel Configuration") {
                    ResolutionPicker(selection: $appState.resolution)
                    NavigationLink("Preview Segmentation",
                                 destination: SegmentationPreview(viewModel: segmentationViewModel))
                }
                
                Section("4. Generate Pattern") {
                    GeneratePatternButton(action: generatePattern)
                    if appState.hasPattern {
                        NavigationLink("Export Pattern",
                                     destination: ExportView(viewModel: exportViewModel))
                    }
                }
            }
            .navigationTitle("CoverCraft")
        }
    }
}
```

### Testing Requirements
Create unit tests for critical components:
```swift
// MeshSegmentationTests.swift
class MeshSegmentationTests: XCTestCase {
    func testSegmentationProducesCorrectPanelCount() {
        // Test low, medium, high resolutions
    }
    
    func testPanelsAreConnected() {
        // Verify each panel forms a connected component
    }
}

// PatternFlattenerTests.swift  
class PatternFlattenerTests: XCTestCase {
    func testEdgeLengthsPreserved() {
        // Verify 3D edge lengths match 2D within tolerance
    }
}
```

## Project Configuration

### Info.plist Keys
```xml
<key>NSCameraUsageDescription</key>
<string>CoverCraft needs camera access to scan objects with LiDAR</string>
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>arkit</string>
</array>
<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>
```

### Build Settings
- iOS Deployment Target: 14.0 (ARKit mesh reconstruction)
- Swift Language Version: 5.0
- Enable Bitcode: No
- Supported Devices: iPhone (LiDAR models only)

## Self-Check Points (IMPORTANT - Check yourself at each stage)

### ✓ After Core Models
- Are variable names descriptive and meaningful?
- Is the data model simple and focused?
- Have I avoided premature optimization?

### ✓ After AR Implementation
- Does scanning work smoothly?
- Is memory managed properly?
- Are there clear user instructions?

### ✓ After Segmentation
- Is the algorithm clearly documented?
- Does it handle edge cases?
- Is performance acceptable for mobile?

### ✓ After Pattern Generation
- Are patterns geometrically accurate?
- Is the scale reference clear?
- Do exports work correctly?

### ✓ Before Completion
- Have I avoided over-engineering?
- Is the code readable and maintainable?
- Does the app solve the actual problem?
- Can a user successfully create a pattern?

## Final Deliverable Structure

Package as Xcode project with:
1. Complete source code following above structure
2. Basic unit tests (at least 10 tests)
3. README with build instructions
4. Assets.xcassets with app icon placeholder
5. Working Info.plist configuration

## Performance Targets
- Scan to pattern: < 30 seconds for average object
- Memory usage: < 200MB during operation
- Pattern export: < 5 seconds
- Smooth 30fps during AR scanning

## Remember
- **Focus on working features over perfect architecture**
- **Use clear, self-documenting code**
- **Test the critical paths**
- **Ensure the app actually generates usable sewing patterns**
- **Don't create unnecessary abstractions**

The goal is a functional app that helps users create protective covers, not a computer science masterpiece. Keep it practical, clear, and focused on the user's needs.