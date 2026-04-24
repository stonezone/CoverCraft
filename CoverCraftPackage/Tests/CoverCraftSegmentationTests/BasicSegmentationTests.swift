import Testing
import Foundation
import simd
import CoverCraftDTO
@testable import CoverCraftCore
@testable import CoverCraftSegmentation

@Suite("Basic Segmentation Coverage Tests")
struct BasicSegmentationTests {
    
    @Test("Basic cube segmentation")
    func basicCubeSegmentation() async throws {
        let segmenter = DefaultMeshSegmentationService()
        let mesh = TestDataFactory.createCubeMesh()
        
        let panels = try await segmenter.segmentMesh(mesh, targetPanelCount: 6)
        
        #expect(panels.count > 0)
        #expect(panels.count <= 6)
        
        for panel in panels {
            #expect(!panel.vertexIndices.isEmpty)
            #expect(!panel.triangleIndices.isEmpty)
        }
    }
    
    @Test("Empty mesh error handling")
    func emptyMeshErrorHandling() async throws {
        let segmenter = DefaultMeshSegmentationService()
        let emptyMesh = TestDataFactory.EdgeCases.emptyMesh()
        
        await #expect(throws: SegmentationError.self) {
            try await segmenter.segmentMesh(emptyMesh, targetPanelCount: 5)
        }
    }
    
    @Test("Invalid panel count error handling")
    func invalidPanelCountErrorHandling() async throws {
        let segmenter = DefaultMeshSegmentationService()
        let mesh = TestDataFactory.createTriangleMesh()
        
        await #expect(throws: SegmentationError.self) {
            try await segmenter.segmentMesh(mesh, targetPanelCount: 0)
        }
        
        await #expect(throws: SegmentationError.self) {
            try await segmenter.segmentMesh(mesh, targetPanelCount: -1)
        }
    }

    @Test("Segmentation RNG seed is stable for fixed mesh IDs")
    func segmentationSeedIsStableForFixedMeshIDs() {
        let meshID = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!
        let alternateMeshID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

        #expect(DefaultMeshSegmentationService.deterministicSeed(for: meshID) == 7_615_160_862_556_605_891)
        #expect(DefaultMeshSegmentationService.deterministicSeed(for: alternateMeshID) == 11_753_873_996_732_508_817)
        #expect(DefaultMeshSegmentationService.deterministicSeed(for: meshID) == DefaultMeshSegmentationService.deterministicSeed(for: meshID))
        #expect(DefaultMeshSegmentationService.deterministicSeed(for: meshID) != DefaultMeshSegmentationService.deterministicSeed(for: alternateMeshID))
    }
}
