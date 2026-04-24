# CoverCraft Rewrite: Polycam-Style Real-Time Object Capture

## Overview
This document provides a comprehensive blueprint for rewriting CoverCraft as a real-time object capture and modeling app like Polycam, using iPhone LiDAR and camera for live mesh visualization and 3D model generation.

## Goal
Create an iOS app that:
- Captures objects in real-time using LiDAR + camera
- Shows live mesh/polygon overlay during scanning (like Polycam)
- Builds 3D models incrementally as you scan
- Exports to standard 3D formats (.obj, .usd, etc.)
- Maintains 30+ FPS performance

---

## Reference Projects & Resources

### 1. **cedanmisquith/SwiftUI-LiDAR** ⭐ PRIMARY REFERENCE
**URL:** https://github.com/cedanmisquith/SwiftUI-LiDAR
**What it provides:**
- SwiftUI-based real-time environment scanning
- LiDAR sensor integration with ARKit
- 3D mesh generation with .OBJ export
- Pan, zoom, rotate controls for mesh preview

**Why use for CoverCraft:**
- Perfect example of SwiftUI + ARKit + LiDAR integration
- Real-time mesh generation pipeline
- Export functionality already implemented
- Clean modern architecture

**Key code to extract:**
- ARKit session configuration
- Real-time mesh processing
- SwiftUI integration patterns
- Export pipeline

### 2. **ximhear/ios-lidar-mesh** ⭐ CORE MESH PROCESSING
**URL:** https://github.com/ximhear/ios-lidar-mesh
**What it provides:**
- Polygonal mesh estimation from LiDAR
- ARMeshAnchor processing patterns
- Face center calculations and classifications
- RealityKit mesh visualization

**Why use for CoverCraft:**
- Low-level mesh processing algorithms
- Proven ARMeshAnchor handling
- Triangle face processing
- Real-time anchor updates

**Key code to extract:**
```swift
// From research - mesh processing pattern
extension ARMeshGeometry {
    func vertex(at index: UInt32) -> SIMD3<Float> {
        let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
        return vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
    }
}
```

### 3. **apple/ARKitScenes** ⭐ OFFICIAL APPLE REFERENCE
**URL:** https://github.com/apple/ARKitScenes
**What it provides:**
- Official Apple mesh overlay implementation
- Data collection with iPad Pro patterns
- 3D scene understanding techniques
- Research-grade processing pipelines

**Why use for CoverCraft:**
- Apple's own best practices
- Mesh overlay UI patterns
- Performance optimization techniques
- Data processing workflows

### 4. **zeitraumdev/iPadLIDARScanExport** ⭐ EXPORT PIPELINE
**URL:** https://github.com/zeitraumdev/iPadLIDARScanExport
**What it provides:**
- OBJ export from ARKit 3.5 mesh data
- Model I/O framework integration
- Mesh conversion and assembly

**Why use for CoverCraft:**
- Proven export functionality
- Model I/O integration patterns
- Mesh assembly techniques
- File format handling

### 5. **TravisHall/RealityKit-Example-ARMeshAnchor-Geometry**
**URL:** https://github.com/TravisHall/RealityKit-Example-ARMeshAnchor-Geometry
**What it provides:**
- ARMeshAnchor geometry extraction
- Color-coded mesh visualization
- RealityKit integration examples

**Why use for CoverCraft:**
- Real-time mesh coloring
- Geometry extraction patterns
- RealityKit rendering examples

### 6. **TokyoYoshida/ExampleOfiOSLiDAR**
**URL:** https://github.com/TokyoYoshida/ExampleOfiOSLiDAR
**What it provides:**
- Real-time point cloud display
- Depth map visualization
- .obj export functionality
- Collision detection with LiDAR

**Why use for CoverCraft:**
- Point cloud rendering techniques
- Depth visualization patterns
- Performance optimization examples

### 7. **xiongyiheng/ARKit-Scanner**
**URL:** https://github.com/xiongyiheng/ARKit-Scanner
**What it provides:**
- RGB-D scan acquisition
- Color, depth, and IMU data storage
- Data collection for research

**Why use for CoverCraft:**
- Data capture architecture
- Storage optimization patterns
- Multi-sensor integration

### 8. **Waley-Z/ios-depth-point-cloud**
**URL:** https://github.com/Waley-Z/ios-depth-point-cloud
**What it provides:**
- Depth data to point cloud conversion
- WWDC20 sample code patterns
- Performance-optimized processing

**Why use for CoverCraft:**
- Point cloud processing algorithms
- Depth data handling
- Apple's recommended patterns

---

## Core Technologies & Implementation Strategy

### ARKit Configuration for Real-Time LiDAR
```swift
// Essential ARKit setup for Polycam-style scanning
let configuration = ARWorldTrackingConfiguration()
configuration.sceneReconstruction = .meshWithClassification
configuration.frameSemantics = .sceneDepth // Direct LiDAR access
configuration.worldAlignment = .gravity
configuration.isAutoFocusEnabled = true

// Critical for real-time performance
session.run(configuration, options: [
    .resetTracking,
    .removeExistingAnchors,
    .resetSceneReconstruction
])
```

### Framework Choice: SceneKit vs RealityKit

**Use SceneKit for CoverCraft because:**
- Better wireframe/polygon overlay control
- More mature API for custom geometry
- Easier material and lighting customization
- Better export pipeline integration
- More documentation and examples

**RealityKit limitations:**
- Less control over rendering pipeline
- Limited wireframe customization
- Newer API with fewer examples

### Real-Time Processing Pipeline

**Frame-by-Frame Processing Pattern:**
```swift
// Process EVERY frame for Polycam-style smoothness
func session(_ session: ARSession, didUpdate frame: ARFrame) {
    // Extract all mesh anchors from current frame
    let meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }

    guard !meshAnchors.isEmpty else { return }

    // Process each anchor incrementally
    for anchor in meshAnchors {
        processMeshAnchor(anchor)
    }

    // Update visualization immediately
    DispatchQueue.main.async {
        self.updateMeshVisualization()
    }
}
```

---

## Implementation Architecture

### 1. Core Components

```
CoverCraftApp (SwiftUI)
├── ARScanView (SwiftUI wrapper)
├── PolycamARViewController (UIKit/ARKit)
├── MeshProcessor (Real-time processing)
├── MeshVisualizer (SceneKit rendering)
├── MeshExporter (Model I/O export)
└── CaptureSession (Data management)
```

### 2. Data Flow

```
LiDAR Sensor → ARFrame → ARMeshAnchor → MeshProcessor → SceneKit → Visual Overlay
                                      ↓
                                 MeshBuilder → 3D Model → Export Pipeline
```

### 3. Memory Management

**Incremental Mesh Building:**
```swift
class IncrementalMeshBuilder {
    private var meshChunks: [UUID: MeshChunk] = [:]
    private let maxChunks = 100 // Prevent memory bloat
    private let chunkTimeout: TimeInterval = 10.0 // Auto-cleanup

    func addOrUpdateChunk(from anchor: ARMeshAnchor) -> Bool {
        // Process and merge new mesh data
        // Return true if visualization needs update
    }

    func pruneOldChunks() {
        // Remove chunks older than timeout
        // Keep memory usage under 500MB
    }
}
```

---

## Step-by-Step Implementation

### Step 1: Project Setup

```swift
// 1. Create new iOS project with SwiftUI
// 2. Add ARKit capabilities in Info.plist:
//    - NSCameraUsageDescription
//    - NSLocationWhenInUseUsageDescription
// 3. Add frameworks: ARKit, SceneKit, SwiftUI
// 4. Set minimum iOS version: 18.0 (for LiDAR)
```

### Step 2: ARKit Session Setup

```swift
import ARKit
import SceneKit
import SwiftUI

class PolycamARViewController: UIViewController {
    private var sceneView: ARSCNView!
    private var meshBuilder = IncrementalMeshBuilder()
    private var meshVisualizationNode: SCNNode?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupMeshVisualization()
    }

    private func setupARView() {
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.autoenablesDefaultLighting = true
        view.addSubview(sceneView)

        // Configure for LiDAR mesh capture
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) else {
            fatalError("LiDAR not supported")
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .meshWithClassification
        configuration.frameSemantics = .sceneDepth
        configuration.worldAlignment = .gravity

        sceneView.session.run(configuration)
    }
}
```

### Step 3: Real-Time Mesh Processing

```swift
extension PolycamARViewController: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Process mesh anchors EVERY frame (60 FPS)
        let meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }

        var hasUpdates = false
        for anchor in meshAnchors {
            if meshBuilder.addOrUpdateChunk(from: anchor) {
                hasUpdates = true
            }
        }

        if hasUpdates {
            // Update visualization at 30 FPS to maintain performance
            DispatchQueue.main.async { [weak self] in
                self?.updateMeshVisualization()
            }
        }
    }
}
```

### Step 4: Mesh Visualization with SceneKit

```swift
private func updateMeshVisualization() {
    guard let meshNode = meshVisualizationNode else { return }

    // Get current mesh from builder
    let meshData = meshBuilder.getCurrentMesh()

    // Create SceneKit geometry
    let geometry = createWireframeGeometry(from: meshData)
    meshNode.geometry = geometry

    // Apply Polycam-style material (semi-transparent overlay)
    let material = SCNMaterial()
    material.diffuse.contents = UIColor.systemTeal.withAlphaComponent(0.6)
    material.fillMode = .lines // Wireframe mode
    material.isDoubleSided = true
    material.writesToDepthBuffer = false
    geometry?.materials = [material]
}

private func createWireframeGeometry(from meshData: MeshData) -> SCNGeometry? {
    guard !meshData.vertices.isEmpty else { return nil }

    // Convert mesh data to SceneKit geometry
    let vertexSource = SCNGeometrySource(
        vertices: meshData.vertices.map { SCNVector3($0.x, $0.y, $0.z) }
    )

    let indices = meshData.triangleIndices.map { UInt32($0) }
    let element = SCNGeometryElement(
        indices: indices,
        primitiveType: .triangles
    )

    return SCNGeometry(sources: [vertexSource], elements: [element])
}
```

### Step 5: SwiftUI Integration

```swift
struct ARScanView: UIViewControllerRepresentable {
    @Binding var capturedMesh: MeshData?
    @Binding var isScanning: Bool

    func makeUIViewController(context: Context) -> PolycamARViewController {
        let controller = PolycamARViewController()
        controller.onMeshCaptured = { mesh in
            capturedMesh = mesh
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: PolycamARViewController, context: Context) {
        uiViewController.setScanning(isScanning)
    }
}

struct ContentView: View {
    @State private var capturedMesh: MeshData?
    @State private var isScanning = false

    var body: some View {
        ZStack {
            ARScanView(capturedMesh: $capturedMesh, isScanning: $isScanning)
                .ignoresSafeArea()

            VStack {
                Spacer()

                HStack {
                    Button(isScanning ? "Stop Scan" : "Start Scan") {
                        isScanning.toggle()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    if let mesh = capturedMesh {
                        Button("Export") {
                            exportMesh(mesh)
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
    }
}
```

### Step 6: Export Pipeline

```swift
import ModelIO

func exportMesh(_ meshData: MeshData, to url: URL) {
    // Create MDL mesh from mesh data
    let allocator = MTKMeshBufferAllocator(device: MTLCreateSystemDefaultDevice()!)

    // Convert vertices to MDL format
    let vertexBuffer = allocator.newBuffer(
        with: Data(bytes: meshData.vertices, count: meshData.vertices.count * MemoryLayout<SIMD3<Float>>.size),
        type: .vertex
    )

    let indexBuffer = allocator.newBuffer(
        with: Data(bytes: meshData.triangleIndices, count: meshData.triangleIndices.count * MemoryLayout<UInt32>.size),
        type: .index
    )

    // Create MDL submesh
    let submesh = MDLSubmesh(
        indexBuffer: indexBuffer,
        indexCount: meshData.triangleIndices.count,
        indexType: .uInt32,
        geometryType: .triangles,
        material: nil
    )

    // Create MDL mesh
    let mdlMesh = MDLMesh(
        vertexBuffer: vertexBuffer,
        vertexCount: meshData.vertices.count,
        descriptor: MDLVertexDescriptor.defaultLayout,
        submeshes: [submesh]
    )

    // Create asset and export
    let asset = MDLAsset()
    asset.add(mdlMesh)

    do {
        try asset.export(to: url)
    } catch {
        print("Export failed: \(error)")
    }
}
```

---

## Performance Optimizations

### 1. Frame Rate Management
```swift
private var lastVisualizationUpdate: TimeInterval = 0
private let visualizationUpdateInterval: TimeInterval = 1.0/30.0 // 30 FPS

func session(_ session: ARSession, didUpdate frame: ARFrame) {
    // Process every frame but update UI at 30 FPS
    let currentTime = frame.timestamp

    processFrameData(frame) // Always process for accuracy

    if currentTime - lastVisualizationUpdate > visualizationUpdateInterval {
        updateVisualization()
        lastVisualizationUpdate = currentTime
    }
}
```

### 2. Memory Management
```swift
class MeshMemoryManager {
    private let maxMemoryMB: Int = 500
    private var currentMemoryMB: Int = 0

    func addMeshChunk(_ chunk: MeshChunk) {
        if currentMemoryMB > maxMemoryMB {
            pruneLeastRecentlyUsedChunks()
        }
        // Add chunk...
    }
}
```

### 3. Background Processing
```swift
private let meshProcessingQueue = DispatchQueue(label: "mesh-processing", qos: .userInteractive)

func processLargeDataset() {
    meshProcessingQueue.async {
        // Heavy mesh processing
        let processedData = self.processMeshData()

        DispatchQueue.main.async {
            // Update UI with results
            self.updateVisualization(with: processedData)
        }
    }
}
```

---

## Testing & Validation

### Hardware Requirements
- iPhone 12 Pro or newer (LiDAR required)
- iPad Pro 2020 or newer (LiDAR required)
- iOS 18.0+ for latest ARKit features

### Performance Targets
- **Frame Rate:** Maintain 30+ FPS during scanning
- **Memory Usage:** Stay under 500MB total
- **Mesh Quality:** 1-2cm accuracy (LiDAR limitation)
- **Export Speed:** < 10 seconds for typical scans

### Test Scenarios
1. **Small Objects:** Coffee cups, books, small electronics
2. **Medium Objects:** Furniture, appliances
3. **Large Spaces:** Rooms, outdoor areas (within 5m LiDAR range)
4. **Challenging Conditions:** Low light, reflective surfaces, glass

---

## Key Differences from Current CoverCraft

### Current Issues
1. ❌ Batch processing (mesh built on finish)
2. ❌ No real-time visualization
3. ❌ Memory crashes with large scans
4. ❌ Poor performance (< 15 FPS)

### New Implementation
1. ✅ Frame-by-frame processing (60 FPS data, 30 FPS UI)
2. ✅ Real-time mesh overlay (Polycam-style)
3. ✅ Incremental mesh building with memory management
4. ✅ Optimized rendering pipeline

### Architecture Comparison
```
OLD: Scan → Finish → Build Mesh → Crash
NEW: Scan → Live Mesh → Continuous Updates → Export
```

---

## Implementation Timeline

### Phase 1: Core Foundation (Week 1)
- [ ] Set up new project structure
- [ ] Implement ARKit session with LiDAR
- [ ] Basic mesh anchor processing
- [ ] Simple wireframe visualization

### Phase 2: Real-Time Processing (Week 2)
- [ ] Incremental mesh builder
- [ ] Frame-by-frame processing
- [ ] Memory management
- [ ] Performance optimization

### Phase 3: Advanced Features (Week 3)
- [ ] Polycam-style UI/UX
- [ ] Export pipeline (.obj, .usd)
- [ ] Mesh classification and coloring
- [ ] Advanced material rendering

### Phase 4: Polish & Testing (Week 4)
- [ ] Performance tuning
- [ ] Error handling and edge cases
- [ ] User testing and feedback
- [ ] App Store preparation

---

## Conclusion

This rewrite will transform CoverCraft from a crash-prone batch processor into a smooth, real-time 3D capture app that rivals Polycam. By leveraging proven implementations from the GitHub projects above and following Apple's best practices, we can achieve:

- **Polycam-quality real-time mesh visualization**
- **Stable 30+ FPS performance**
- **Professional-grade export capabilities**
- **Modern SwiftUI architecture**

The key is processing ARMeshAnchor data every frame while carefully managing memory and rendering updates to maintain smooth performance. The reference projects provide all the necessary code patterns and optimization techniques to make this a reality.