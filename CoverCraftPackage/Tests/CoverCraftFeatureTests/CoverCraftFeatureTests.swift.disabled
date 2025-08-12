import Testing
import simd
@testable import CoverCraftFeature

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

@Suite("CalibrationData Tests")
@MainActor
struct CalibrationTests {
    
    @Test("Calibration scale factor calculation")
    func calibrationScaleFactor() {
        let calibration = CalibrationData()
        
        // Set two points 1 unit apart in mesh space
        calibration.firstPoint = SIMD3<Float>(0, 0, 0)
        calibration.secondPoint = SIMD3<Float>(1, 0, 0)
        
        // Set real-world distance to 2 meters
        calibration.realWorldDistance = 2.0
        
        // Scale factor should be 2.0
        let tolerance: Float = 0.001
        #expect(abs(calibration.scaleFactor - 2.0) < tolerance)
    }
    
    @Test("Incomplete calibration")
    func incompleteCalibration() {
        let calibration = CalibrationData()
        
        // Only first point set
        calibration.firstPoint = SIMD3<Float>(0, 0, 0)
        #expect(!calibration.isComplete)
        #expect(calibration.scaleFactor == 1.0)
        
        // Both points but no distance
        calibration.secondPoint = SIMD3<Float>(1, 0, 0)
        calibration.realWorldDistance = 0
        #expect(!calibration.isComplete)
    }
    
    @Test("Calibration reset")
    func calibrationReset() {
        let calibration = CalibrationData()
        
        calibration.firstPoint = SIMD3<Float>(0, 0, 0)
        calibration.secondPoint = SIMD3<Float>(1, 0, 0)
        calibration.realWorldDistance = 2.0
        
        #expect(calibration.isComplete)
        
        calibration.reset()
        
        #expect(calibration.firstPoint == nil)
        #expect(calibration.secondPoint == nil)
        #expect(calibration.realWorldDistance == 1.0)
        #expect(!calibration.isComplete)
    }
}

// MARK: - Test Utilities

private func createTestCubeMesh() -> Mesh {
    // Create a simple cube mesh for testing
    let vertices: [SIMD3<Float>] = [
        SIMD3<Float>(-1, -1, -1), // 0
        SIMD3<Float>( 1, -1, -1), // 1
        SIMD3<Float>( 1,  1, -1), // 2
        SIMD3<Float>(-1,  1, -1), // 3
        SIMD3<Float>(-1, -1,  1), // 4
        SIMD3<Float>( 1, -1,  1), // 5
        SIMD3<Float>( 1,  1,  1), // 6
        SIMD3<Float>(-1,  1,  1)  // 7
    ]
    
    let triangles: [Int] = [
        // Front face
        0, 1, 2,  0, 2, 3,
        // Back face
        4, 6, 5,  4, 7, 6,
        // Left face
        0, 3, 7,  0, 7, 4,
        // Right face
        1, 5, 6,  1, 6, 2,
        // Top face
        3, 2, 6,  3, 6, 7,
        // Bottom face
        0, 4, 5,  0, 5, 1
    ]
    
    return Mesh(vertices: vertices, triangleIndices: triangles)
}

private func createTestPlaneMesh() -> Mesh {
    // Create a simple square plane mesh
    let vertices: [SIMD3<Float>] = [
        SIMD3<Float>(0, 0, 0),
        SIMD3<Float>(1, 0, 0),
        SIMD3<Float>(1, 1, 0),
        SIMD3<Float>(0, 1, 0)
    ]
    
    let triangles: [Int] = [
        0, 1, 2,
        0, 2, 3
    ]
    
    return Mesh(vertices: vertices, triangleIndices: triangles)
}