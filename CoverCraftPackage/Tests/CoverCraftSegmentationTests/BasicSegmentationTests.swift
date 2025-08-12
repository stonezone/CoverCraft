import Testing
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
}