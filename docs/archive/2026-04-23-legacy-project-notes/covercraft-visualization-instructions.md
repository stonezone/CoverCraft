# INSTRUCTIONS FOR CLAUDE CODE: Add AR Visualization Layer

## CRITICAL: Read This First
**vibe_check immediately**: These are MINIMAL implementations. Not production-ready. Not perfect. Just functional enough to see the mesh and calibrate. If you're thinking "but it should also..." STOP.

## Prerequisites
- CoverCraft running on iPhone ✓
- Console showing "Mesh updated: X vertices" ✓
- PolycamStyleARScanning.swift working ✓

## Task 1: Wireframe Visualization (MINIMAL)

### File to Modify
`CoverCraftPackage/Sources/CoverCraftUI/ARScanView.swift`

### Add ONLY This
```swift
import SceneKit
import ARKit

// Add to ARScanView struct
@State private var sceneView = ARSCNView()
@State private var meshNode: SCNNode?

// In makeUIView or body:
func setupWireframe() {
    // MINIMAL wireframe - white lines, that's it
    sceneView.scene = SCNScene()
    sceneView.autoenablesDefaultLighting = false
    sceneView.showsStatistics = false // DO NOT add debug info
}

// Add mesh update handler
func updateMeshVisualization(_ mesh: MeshDTO) {
    // Remove old mesh
    meshNode?.removeFromParentNode()

    // Create geometry from vertices
    let vertices = mesh.vertices.map { SCNVector3($0.x, $0.y, $0.z) }
    let source = SCNGeometrySource(vertices: vertices)

    // Create wireframe elements
    var indices: [Int32] = []
    for i in stride(from: 0, to: mesh.triangleIndices.count, by: 3) {
        // Lines for triangle edges
        indices.append(contentsOf: [
            Int32(mesh.triangleIndices[i]), Int32(mesh.triangleIndices[i+1]),
            Int32(mesh.triangleIndices[i+1]), Int32(mesh.triangleIndices[i+2]),
            Int32(mesh.triangleIndices[i+2]), Int32(mesh.triangleIndices[i])
        ])
    }

    let element = SCNGeometryElement(
        indices: indices,
        primitiveType: .line
    )

    let geometry = SCNGeometry(sources: [source], elements: [element])
    geometry.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.5)

    meshNode = SCNNode(geometry: geometry)
    sceneView.scene?.rootNode.addChildNode(meshNode!)
}
```

**vibe_check**: Am I adding particle effects, animations, or color gradients? STOP. White lines only.

### DO NOT Add
- ❌ Mesh smoothing
- ❌ Vertex normals visualization
- ❌ Color coding by distance
- ❌ Fancy shaders
- ❌ Mesh optimization
- ❌ Level-of-detail system

## Task 2: Calibration Ray Casting (MINIMAL)

### File to Modify
`CoverCraftPackage/Sources/CoverCraftAR/PolycamStyleARScanning.swift`

### Update captureCalibrationPoint Method
```swift
public func captureCalibrationPoint(at point: CGPoint) async throws -> CalibrationPoint {
    guard let frame = session.currentFrame else {
        throw ARScanError.calibrationFailed
    }

    // MINIMAL ray cast - just get a point
    let query = frame.raycastQuery(
        from: point,
        allowing: .existingPlaneGeometry,
        alignment: .any
    )

    guard let query = query,
          let result = session.raycast(query).first else {
        throw ARScanError.calibrationFailed
    }

    let worldPos = result.worldTransform.columns.3
    return CalibrationPoint(
        screenPosition: point,
        worldPosition: SIMD3<Float>(worldPos.x, worldPos.y, worldPos.z),
        confidence: 0.9 // Just return high confidence, don't calculate
    )
}
```

### Add to CalibrationView
```swift
// In CoverCraftPackage/Sources/CoverCraftUI/Views/CalibrationView.swift
@State private var point1: CalibrationPoint?
@State private var point2: CalibrationPoint?
@State private var measuredDistance: Float = 0

// Simple two-tap calibration
func handleTap(at location: CGPoint) {
    Task {
        if point1 == nil {
            point1 = try await arService.captureCalibrationPoint(at: location)
            showMessage("Tap second point")
        } else if point2 == nil {
            point2 = try await arService.captureCalibrationPoint(at: location)
            calculateScale()
        }
    }
}

func calculateScale() {
    guard let p1 = point1, let p2 = point2 else { return }
    let distance = simd_distance(p1.worldPosition, p2.worldPosition)
    // User will input real distance
    // scale = realDistance / distance
}
```

**vibe_check**: Am I implementing automatic object detection? Multi-point calibration? STOP. Two points only.

### DO NOT Add
- ❌ Automatic measurement detection
- ❌ Computer vision for finding rulers
- ❌ Multiple calibration methods
- ❌ Calibration history
- ❌ Advanced error correction

## Task 3: Progress Indicators (MINIMAL)

### File to Add
`CoverCraftPackage/Sources/CoverCraftUI/Views/ARProgressView.swift`

### ENTIRE Implementation
```swift
import SwiftUI

struct ARProgressView: View {
    let vertexCount: Int
    let message: String

    var body: some View {
        VStack {
            // Just text, no fancy animations
            Text(message)
                .font(.headline)
                .foregroundColor(.white)

            Text("\(vertexCount) vertices captured")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
}

struct ARCoachingOverlay: View {
    @State private var message = "Move slowly around object"

    var body: some View {
        // MINIMAL coaching - just text
        Text(message)
            .font(.title3)
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(15)
    }
}
```

**vibe_check**: Am I adding animated arrows, 3D coaching animations, or haptic patterns? STOP. Text only.

### Update ARScanView to Use These
```swift
// Add to ARScanView
@State private var vertexCount = 0
@State private var scanMessage = "Starting scan..."

// In body:
ZStack {
    // AR view
    sceneView

    // Overlay UI (keep it simple)
    VStack {
        ARCoachingOverlay()
            .padding(.top, 50)

        Spacer()

        ARProgressView(
            vertexCount: vertexCount,
            message: scanMessage
        )
        .padding(.bottom, 100)
    }
}

// Update when mesh updates
.onReceive(meshUpdatePublisher) { mesh in
    vertexCount = mesh.vertices.count
    scanMessage = vertexCount > 10000 ? "Good coverage" : "Keep scanning"
}
```

### DO NOT Add
- ❌ Animated progress bars
- ❌ 3D coaching animations
- ❌ Sound effects
- ❌ Haptic feedback (yet)
- ❌ Particle effects
- ❌ Complex state machines

## Integration Checklist

1. **Wireframe**: Can you see white lines forming mesh? ✓ = Done
2. **Calibration**: Can you tap two points? ✓ = Done
3. **Progress**: Does vertex count show? ✓ = Done

**If all three ✓, STOP. Do not enhance.**

## Anti-Patterns to Avoid

**vibe_check before each file save:**
- Am I adding "just one more feature"? → STOP
- Is this more than 50 lines of code? → Too much
- Am I importing a new framework? → Probably unnecessary
- Am I creating abstractions? → Not needed
- Am I handling edge cases? → Not yet

## If Tempted to Add More

Run this check:
```
vibe_distill:
  current_plan: [what you're about to add]

  Answer: Can the user SEE the mesh and tap TWO points?
  If YES → You're done
  If NO → Fix only what prevents those two things
```

## Summary of Scope

**Wireframe**: White lines showing mesh. Nothing more.
**Calibration**: Two taps, calculate distance. Nothing more.
**Progress**: Text showing vertex count. Nothing more.

Total new code should be < 200 lines across all files.

**Success Criteria:**
- Mesh visible as white wireframe ✓
- Can tap two calibration points ✓
- Vertex count visible ✓
- You didn't add animations ✓
- You didn't import new packages ✓
- You didn't refactor existing code ✓

---

**FINAL REMINDER**: These are placeholder implementations to test the concept. Make them work, not beautiful. The user wants to SEE the mesh like Polycam shows it. White lines are enough. Ship it.