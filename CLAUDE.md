# CoverCraft

## Project Overview

**CoverCraft** is an iOS app that uses LiDAR-based mesh capture to scan objects (from small items to large objects like cars) and generate 2D sewing patterns for custom-fitted covers.

### Core Concept
- Scan any 3D object using iPhone's LiDAR sensor
- Adjustable resolution from simple 6-panel cubes to detailed shapes
- Generate flat 2D patterns that can be projected and traced for cutting/sewing
- Break down complex shapes into basic geometric primitives (squares, rectangles, triangles, circles)

### Tech Stack
- **Language**: Swift
- **UI Framework**: SwiftUI
- **AR/3D**: ARKit, SceneKit, RealityKit
- **LiDAR**: ARKit mesh capture with real-time visualization
- **Platform**: iOS (iPhone 12 Pro+ with LiDAR required)
- **Minimum iOS Version**: iOS 18.0+
- **Build**: Xcode, Swift Package Manager

### Why iOS 18 is Required

CoverCraft requires **iOS 18.0** as the minimum deployment target for several critical technical reasons:

1. **Swift 6 Strict Concurrency**: The project uses Swift 6's strict concurrency model with full actor isolation, `@MainActor`, and `Sendable` conformance throughout the codebase. This ensures thread-safe, data-race-free code but requires iOS 18's runtime support.

2. **Latest ARKit Features**: Real-time LiDAR mesh capture with `frameSemantics.sceneDepth` and advanced mesh classification features are only available in iOS 18+.

3. **Modern SwiftUI APIs**: The UI layer leverages iOS 18+ SwiftUI features including enhanced navigation, improved state management with `@Observable`, and better performance characteristics.

4. **Concurrency Runtime Improvements**: iOS 18 includes significant performance improvements to Swift's structured concurrency runtime, critical for real-time AR processing at 30+ FPS.

5. **ARSession Enhancements**: Improved memory management and frame delivery in ARSession that prevents frame retention issues during continuous LiDAR capture.

**Note**: This is an intentional architectural decision. Do not lower the deployment target as it will break concurrency safety guarantees and AR functionality.

### Project Structure
```
CoverCraft/
├── CoverCraft/           # Main app target
├── CoverCraftPackage/    # Swift Package with core modules
│   ├── Sources/
│   │   ├── CoverCraftCore/        # Core services & DI
│   │   ├── CoverCraftAR/          # AR scanning services
│   │   │   └── ARScanViewController.swift  # LiDAR + depth limiting
│   │   ├── CoverCraftDTO/         # Data transfer objects
│   │   │   ├── MeshDTO.swift               # Mesh data + processing algorithms
│   │   │   ├── MeshProcessingOptions.swift # Processing configuration
│   │   │   └── CalibrationDTO.swift        # Calibration data
│   │   ├── CoverCraftUI/          # SwiftUI views
│   │   │   └── Views/
│   │   │       ├── CalibrationView.swift   # Scale calibration UI
│   │   │       └── MeshProcessingView.swift # Mesh cleanup UI
│   │   ├── CoverCraftFeature/     # Main app feature
│   │   │   ├── ContentView.swift  # Main navigation
│   │   │   └── AppState.swift     # Central state
│   │   ├── CoverCraftSegmentation/ # Mesh segmentation
│   │   ├── CoverCraftFlattening/  # Mesh to pattern conversion
│   │   └── CoverCraftExport/      # Pattern export services
│   └── Tests/
├── docs/                 # Project documentation
└── Config/               # Configuration files
```

## Development Guidelines

### Architecture
- **Service-oriented**: Use `ServiceContainer` for dependency injection
- **Protocol-driven**: Define protocols for all services
- **Modular packages**: Core functionality in CoverCraftPackage
- **SwiftUI + UIKit bridge**: Use `UIViewControllerRepresentable` for AR views

### Key Services
- `ARScanningService` - LiDAR mesh capture (headless operations)
- `ARScanViewControllerProvider` - Factory for AR scan view controllers (DI pattern)
- `MeshSegmentationService` - K-means mesh to panels conversion
- `PatternFlatteningService` - 3D panels to 2D pattern conversion
- `PatternExportService` - Pattern export (PDF, SVG, PNG, GIF)
- `CalibrationService` - Real-world scale calibration

### Testing Requirements
- Test on real device (LiDAR required)
- Maintain 30+ FPS during scanning
- Memory usage < 500MB during capture

### Swift 6 Concurrency Patterns
This project uses Swift 6 strict concurrency. Key patterns:

**Delegate methods on @MainActor classes:**
```swift
extension MyViewController: SomeDelegate {
    // Mark as nonisolated to satisfy protocol
    nonisolated public func delegateMethod(_ session: Session, didUpdate frame: Frame) {
        // Capture immutable data BEFORE dispatching
        let capturedValue = frame.someProperty

        // Dispatch to MainActor for UI/state updates
        Task { @MainActor [weak self] in
            self?.updateState(with: capturedValue)
        }
    }
}
```

**View Controller Provider Pattern for DI:**
```swift
// Protocol in Core module (Sendable for thread safety)
public protocol SomeViewControllerProvider: Sendable {
    @MainActor func makeViewController(completion: @escaping @Sendable (Result) -> Void) -> UIViewController
}

// Implementation marked @unchecked Sendable (no mutable state)
public final class DefaultSomeViewControllerProvider: SomeViewControllerProvider, @unchecked Sendable {
    @MainActor public func makeViewController(...) -> UIViewController { ... }
}
```

---

## Current Implementation Status

### Polycam-Style LiDAR Visualization (COMPLETE)

**Status**: COMPLETE
**Goal**: Real-time mesh overlay during LiDAR scanning (like Polycam app)

#### What Was Fixed
1. **Mesh Visualization** - Changed from broken wireframe to semi-transparent cyan overlay
2. **Material Settings** - Added proper depth buffer settings for AR overlay
3. **Frame Processing** - Optimized with DispatchQueue instead of Task/MainActor
4. **IncrementalMeshBuilder** - Full implementation with chunk management
5. **PolycamStyleARScanning** - New service with real-time updates

#### Key Technical Details
- **Material**: Cyan with 0.6 transparency, writesToDepthBuffer=false
- **Processing**: Every frame via session(_:didUpdate:)
- **Updates**: 10Hz to UI to avoid overwhelming
- **Memory**: Chunks pruned after 10 seconds
- **Thread Safety**: NSLock for Sendable conformance

#### Files Modified
- `ARScanViewController.swift` - Fixed visualization and processing
- `PolycamStyleARScanning.swift` - NEW - Complete Polycam-style service

#### Known Issue - RESOLVED
~~Current architecture bypasses ServiceContainer - ARScanView directly instantiates ARScanViewController.~~

**Fixed**: Added `ARScanViewControllerProvider` protocol and `DefaultARScanViewControllerProvider` implementation:
- `ARScanView` now resolves the provider from the DI container
- Provider registered in `CoverCraftApp.init()` via `registerARViewControllerProvider()`
- Maintains backwards compatibility with fallback to direct instantiation
- Enables easy testing and customization of AR scanning behavior

#### Testing Checklist
- [x] Mesh visible during scanning (18 anchors, 41K+ vertices captured)
- [x] Smooth real-time updates
- [ ] 30+ FPS performance
- [ ] Memory < 500MB

#### Known Issue - ARFrame Retention (ADDRESSED)
```
ARSession: The delegate is retaining 11 ARFrames. The camera will stop delivering
camera images if the delegate keeps holding on to too many ARFrames.
```
**Cause**: `Task { @MainActor }` closures in Swift structured concurrency retained ARMeshAnchor references.
**Fix Applied**:
- Changed from `Task { @MainActor }` to `DispatchQueue.main.async`
- Re-fetch anchors from `session.currentFrame` inside the dispatch block
- Extract primitive statistics (counts) before dispatching
- See `ARScanViewController.swift:303-366` for detailed comments

---

## Mesh Processing Pipeline (NEW)

### Overview
After scanning, users can optionally clean up their mesh before pattern generation. Processing is applied in this order (optimized for efficiency):

1. **Connected Component Isolation** (first - reduces work for subsequent steps)
2. **Plane-Based Cropping** (removes floor/ceiling)
3. **Hole Filling** (closes small gaps)

### Key Files
- `MeshDTO.swift` - Contains all processing algorithms
- `MeshProcessingOptions.swift` - Configuration DTO
- `MeshProcessingView.swift` - Settings UI
- `AppState.swift` - Has `processedMesh` and `effectiveMesh`

### Processing Features

#### 1. Depth Limiting (During Scan)
Filters mesh vertices by distance from camera at scan completion.
- **UI**: Slider in AR scan view (0.3m - 5m range)
- **Default**: 2.0m
- **Algorithm**: Squared distance comparison for performance
- **Location**: `ARScanViewController.buildFinalMesh()`

```swift
let maxDepthSquared = maxDepth * maxDepth
let delta = worldPos - cameraPosition
let distanceSquared = delta.x * delta.x + delta.y * delta.y + delta.z * delta.z
if distanceSquared <= maxDepthSquared { /* keep vertex */ }
```

#### 2. Boundary/Hole Detection
Detects open edges and chains them into boundary loops.
- **Edge Detection**: Edges with only 1 adjacent triangle are boundary edges
- **Loop Chaining**: BFS to connect boundary edges into closed loops
- **UI**: Shows hole count in main view after scanning

```swift
let boundaryInfo = mesh.analyzeBoundaries()
// boundaryInfo.holeCount, .isWatertight, .boundaryEdges, .boundaryLoops
```

#### 3. Hole Filling (Centroid Fan)
Automatically closes small holes using fan triangulation.
- **Toggle**: Enable/disable
- **Slider**: Max hole size (3-50 edges)
- **Algorithm**: Compute centroid → add as vertex → create fan triangles

#### 4. Plane-Based Cropping
Removes geometry below/above a horizontal cutting plane.
- **Toggle**: Enable/disable
- **Direction**: Below (floor) or Above (ceiling)
- **Slider**: Cut height (0-50% from mesh bottom)
- **Decision**: Based on triangle centroid Y position

#### 5. Connected Component Isolation
Keeps largest component, removes floating fragments.
- **Toggle**: Enable/disable
- **Slider**: Min fragment size (10-500 triangles)
- **Algorithm**: BFS via shared edges to find components

### Architecture Pattern: Effective Mesh

```swift
// AppState.swift
public var currentMesh: MeshDTO?      // Raw scan
public var processedMesh: MeshDTO?    // After cleanup (optional)
public var effectiveMesh: MeshDTO? {  // Used by all downstream
    processedMesh ?? currentMesh
}
```

All downstream features (calibration, segmentation, generation) use `effectiveMesh` so they automatically get the processed version if available.

### Vertex Remapping Pattern
When filtering triangles, indices must be remapped:

```swift
// 1. Collect used vertices from kept triangles
var usedVertices = Set<Int>()
// 2. Create old→new index mapping
var oldToNew: [Int: Int] = [:]
// 3. Build new vertex array (only used vertices)
// 4. Build new index array with remapped values
```

---

## Calibration System (UPDATED)

### CalibrationView
Users can calibrate real-world scale using 5 methods:

| Method | Description |
|--------|-------------|
| **Bounding Box Diagonal** | Corner to corner (longest possible) |
| **X-Axis (Width)** | Left to right extent |
| **Y-Axis (Height)** | Bottom to top extent |
| **Z-Axis (Depth)** | Front to back extent |
| **Longest Axis** | Auto-picks longest dimension |

### Flow
1. User selects calibration method
2. UI shows computed mesh distance for that method
3. User enters real-world measurement in meters
4. "Apply Calibration" computes scale factor
5. `CalibrationDTO.isComplete` becomes true
6. Pattern generation uses scaled mesh

### Key Files
- `CalibrationView.swift` - Method selection UI
- `CalibrationDTO.swift` - Immutable calibration data
- `AppState.calibrationData` - Current calibration state

---

## Common Tasks

### Running the App
```bash
# Open in Xcode
open CoverCraft.xcworkspace

# Build package
cd CoverCraftPackage && swift build

# Run tests
cd CoverCraftPackage && swift test
```

### Key Algorithms

#### Pattern Resolution Levels
1. **Minimal (6 panels)**: Simple cube decomposition - top, front, back, left, right sides
2. **Low**: Add basic contours for major features
3. **Medium**: Include curves approximated as polygon segments
4. **High**: Detailed panels for complex surfaces (windshields, bumpers, etc.)

#### Mesh Flattening Approach
- Use geometric primitives: squares, rectangles, triangles, circles
- Resolution determines granularity of primitive decomposition
- Generate seam allowances automatically
- Output as scalable 2D patterns

---

## Claude OS Integration

This project uses Claude OS for AI-powered development assistance.

**Knowledge Bases**:
- `covercraft-knowledge_docs` - Project documentation
- `covercraft-project_profile` - Architecture & standards
- `covercraft-project_index` - Code index
- `covercraft-project_memories` - Decisions & patterns

**Commands**:
- `/claude-os-search` - Search project knowledge
- `/claude-os-save` - Save insights
- `/claude-os-session` - Manage dev sessions
