# CoverCraft Polycam-Style Capture Implementation

## Current Status (As of January 2025)
- Created PolycamStyleARScanning.swift as drop-in replacement for DefaultARScanningService
- Maintains existing ARScanningService interface - NO BREAKING CHANGES
- Implements smooth real-time capture like Polycam app

## Problem We're Solving
The original DefaultARScanningService was a placeholder. We need smooth, real-time mesh capture like Polycam achieves, where the mesh builds progressively as the user scans, not in batches.

## Key Implementation Details

### Core Technology Stack
1. **Scene Reconstruction**: `config.sceneReconstruction = .meshWithClassification`
2. **Frame Semantics**: `config.frameSemantics = .sceneDepth` for direct LiDAR access
3. **Every Frame Processing**: Updates mesh on each ARFrame via `session(_:didUpdate:)`
4. **Incremental Building**: IncrementalMeshBuilder class that updates chunks, doesn't rebuild

### Architecture Decision
- Keep DefaultARScanningService.swift as fallback
- Create new PolycamStyleARScanning.swift as enhanced implementation
- Swap implementation in ServiceContainer.swift registration
- All interfaces remain identical - true drop-in replacement

## What's Different from Polycam App
| Feature | Polycam | CoverCraft |
|---------|---------|------------|
| Photogrammetry | Yes | No (not needed) |
| Texture Capture | Yes | No (patterns don't need it) |
| Cloud Processing | Yes | No (local only) |
| Mesh Topology | Optimized | Simple (sufficient for covers) |
| Export Formats | Many | GIF with patterns |

## Implementation Files

### New File: PolycamStyleARScanning.swift
Location: `/CoverCraftPackage/Sources/CoverCraftAR/PolycamStyleARScanning.swift`

Key components:
- Conforms to existing ARScanningService protocol
- IncrementalMeshBuilder for smooth updates
- Direct memory access for performance
- Processes every ARFrame, not just on completion

### Modified File: ServiceContainer.swift
Location: `/CoverCraftPackage/Sources/CoverCraftCore/ServiceContainer.swift`

Change in `registerARServices()`:
```swift
// OLD:
registerSingleton({ DefaultARScanningService() }, for: ARScanningService.self)

// NEW:
registerSingleton({ PolycamStyleARScanning() }, for: ARScanningService.self)
```

## Next Steps for Future Conversations

### Phase 1: Core Implementation (CURRENT)
- [x] Design PolycamStyleARScanning class
- [ ] Implement and test on device
- [ ] Verify smooth capture at 30+ FPS
- [ ] Ensure memory usage < 500MB

### Phase 2: Visualization
- [ ] Add wireframe rendering like Polycam
- [ ] Implement progress indicators
- [ ] Add coaching overlay for better UX

### Phase 3: Optimization
- [ ] Mesh simplification post-capture
- [ ] Memory optimization for large scans
- [ ] Performance profiling with Instruments

### Phase 4: Integration
- [ ] Update ARScanView.swift to use new service
- [ ] Wire up progress callbacks to UI
- [ ] Add haptic feedback during capture

## Testing Instructions

### Device Requirements
- iPhone 12 Pro or newer (LiDAR required)
- iOS 18.0+
- Good lighting conditions

### Test Code
```swift
// Quick test in ContentView
let service = ServiceContainer.shared.resolve(ARScanningService.self)
service.startScanning { result in
    switch result {
    case .success(let mesh):
        print("Mesh updated: \(mesh.vertices.count) vertices")
        // Should see continuous updates, not just final
    case .failure(let error):
        print("Scan error: \(error)")
    }
}
```

## Performance Targets
- **Frame Rate**: 30+ FPS during capture
- **Memory**: < 500MB for typical scan
- **Update Frequency**: Every frame (60Hz ideally)
- **Latency**: < 50ms from capture to mesh update
- **Mesh Quality**: Sufficient for 5-15 panel segmentation

## Critical Implementation Notes

### Memory Management
- Chunks are stored by UUID to prevent duplicates
- Old chunks automatically replaced on update
- Reset method clears all chunks

### Coordinate Systems
- Vertices transformed to world space
- Uses simd_float4x4 for transforms
- Maintains ARKit coordinate system

### Error Handling
- Graceful degradation if no LiDAR
- Handles empty mesh anchors
- Continues on partial failures

## Don't Break These
1. **ARScanningService protocol** - Keep interface identical
2. **MeshDTO structure** - Don't modify fields
3. **ServiceProtocols.swift** - No changes to protocols
4. **Existing UI** - Should work without modifications
5. **Test suites** - All existing tests should pass

## Debugging Tips
- Use `ARSession.debugOptions = [.showSceneUnderstanding]` to visualize
- Monitor memory with Instruments
- Check frame.camera.trackingState for quality
- Log mesh anchor count to detect accumulation

## References
- [ARKit Scene Reconstruction](https://developer.apple.com/documentation/arkit/arworldtrackingconfiguration/scenereconstruction)
- [ARMeshAnchor Documentation](https://developer.apple.com/documentation/arkit/armeshanchor)
- [Polycam App](https://poly.cam) - Reference for UX
- Original implementation: DefaultARScanningService.swift

## Contact Points
- Project: CoverCraft_Xcode_Project
- Repository: https://github.com/stonezone/CoverCraft
- Current Branch: main (create feature/polycam-capture)

## Success Criteria
✅ Mesh captures smoothly like Polycam
✅ No breaking changes to existing code
✅ Memory efficient for device constraints
✅ Works on all LiDAR-equipped iOS devices
✅ Can be swapped back to DefaultARScanningService if needed