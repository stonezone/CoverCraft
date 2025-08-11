import Testing
import simd
@testable import CoverCraftCore
@testable import CoverCraftFlattening

@Suite("PatternFlattener Tests")
struct PatternFlattenerTests {
    
    @Test("Flattening preserves vertex count")
    func flatteningPreservesVertexCount() async throws {
        let flattener = PatternFlattener()
        let mesh = createTestPlaneMesh()
        let panel = Panel(
            vertexIndices: Set(0..<4),
            triangleIndices: [0, 1, 2, 0, 2, 3],
            color: .blue
        )
        
        let flattened = try await flattener.flattenPanels([panel], from: mesh)
        
        #expect(flattened.count == 1)
        #expect(flattened[0].points2D.count == panel.vertexIndices.count)
    }
    
    @Test("Edge lengths preserved within tolerance")
    func edgeLengthsPreserved() async throws {
        let flattener = PatternFlattener()
        let mesh = createTestPlaneMesh()
        let panel = Panel(
            vertexIndices: Set(0..<4),
            triangleIndices: [0, 1, 2, 0, 2, 3],
            color: .blue
        )
        
        let flattened = try await flattener.flattenPanels([panel], from: mesh)
        let flatPanel = flattened[0]
        
        // Calculate original edge length
        let originalLength = simd_distance(mesh.vertices[0], mesh.vertices[1])
        
        // Calculate flattened edge length
        let point0 = flatPanel.points2D[0]
        let point1 = flatPanel.points2D[1]
        let flattenedLength = hypot(point1.x - point0.x, point1.y - point0.y)
        
        // Should be preserved within tolerance
        let tolerance: Float = 0.5
        #expect(abs(Float(flattenedLength) - originalLength) < tolerance)
    }
    
    @Test("Empty panel throws error")
    func emptyPanelThrowsError() async {
        let flattener = PatternFlattener()
        let mesh = createTestPlaneMesh()
        let emptyPanel = Panel(
            vertexIndices: [],
            triangleIndices: [],
            color: .red
        )
        
        await #expect(throws: PatternFlattener.FlatteningError.self) {
            try await flattener.flattenPanels([emptyPanel], from: mesh)
        }
    }
}