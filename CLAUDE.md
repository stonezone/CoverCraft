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
