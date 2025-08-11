import Testing
import simd
@testable import CoverCraftCore
@testable import CoverCraftSegmentation

@Suite("MeshSegmentationService Tests")
struct MeshSegmentationTests {
    
    @Test("Segmentation produces correct panel count") 
    func segmentationProducesCorrectPanelCount() async throws {
        let segmenter = MeshSegmentationService()
        let mesh = createTestCubeMesh()
        
        // Test low resolution
        let lowPanels = try await segmenter.segmentMesh(mesh, targetPanelCount: 5)
        #expect(lowPanels.count >= 4)
        #expect(lowPanels.count <= 6)
        
        // Test medium resolution
        let mediumPanels = try await segmenter.segmentMesh(mesh, targetPanelCount: 8)
        #expect(mediumPanels.count >= 6)
        #expect(mediumPanels.count <= 10)
        
        // Test high resolution
        let highPanels = try await segmenter.segmentMesh(mesh, targetPanelCount: 15)
        #expect(highPanels.count >= 5)
        #expect(highPanels.count <= 20)
    }
    
    @Test("Empty mesh throws error")
    func emptyMeshThrowsError() async {
        let segmenter = MeshSegmentationService()
        let emptyMesh = Mesh(vertices: [], triangleIndices: [])
        
        await #expect(throws: MeshSegmentationService.SegmentationError.self) {
            try await segmenter.segmentMesh(emptyMesh, targetPanelCount: 5)
        }
    }
    
    @Test("All vertices are covered")
    func allVerticesAreCovered() async throws {
        let segmenter = MeshSegmentationService()
        let mesh = createTestCubeMesh()
        let panels = try await segmenter.segmentMesh(mesh, targetPanelCount: 6)
        
        var allVertices = Set<Int>()
        for panel in panels {
            allVertices.formUnion(panel.vertexIndices)
        }
        
        // All mesh vertices should be in at least one panel
        for i in 0..<mesh.vertices.count {
            #expect(allVertices.contains(i))
        }
    }
}