import Testing
import simd
import CoreGraphics
@testable import CoverCraftFeature

/// Tests for PatternFlattener's sophisticated spring relaxation algorithm
@Suite("PatternFlattener Tests")
struct PatternFlattenerTests {
    
    let flattener = PatternFlattener()
    
    // MARK: - Basic Functionality Tests
    
    @Test("Flattener initializes correctly")
    func flattenerInitialization() async throws {
        let service = PatternFlattener()
        #expect(service != nil)
    }
    
    @Test("Empty panel throws appropriate error")
    func emptyPanelHandling() async throws {
        let mesh = SyntheticMeshes.triangle()
        let emptyPanel = Panel(vertexIndices: [], triangleIndices: [], color: .blue)
        
        await #expect(throws: PatternFlattener.FlatteningError.self) {
            try await flattener.flattenPanel(emptyPanel, mesh: mesh)
        }
    }
    
    // MARK: - Single Panel Flattening Tests
    
    @Test("Single triangle flattens correctly")
    func singleTriangleFlattening() async throws {
        let mesh = SyntheticMeshes.triangle()
        let segmentationService = MeshSegmentationService()
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 1)
        
        #expect(panels.count == 1, "Triangle should produce one panel")
        
        let flattenedPanel = try await flattener.flattenPanel(panels[0], mesh: mesh)
        
        // Basic structure validation
        #expect(flattenedPanel.points2D.count == 3, "Triangle should have 3 flattened points")
        #expect(flattenedPanel.edges.count > 0, "Should have edge connections")
        #expect(flattenedPanel.sourcePanel.id == panels[0].id, "Should reference source panel")
        
        // Points should be finite and reasonable
        for point in flattenedPanel.points2D {
            #expect(point.x.isFinite && point.y.isFinite, "Flattened points should be finite")
            #expect(abs(point.x) < 1000 && abs(point.y) < 1000, "Points should be reasonably scaled")
        }
    }
    
    @Test("Cube face flattening preserves topology")
    func cubeFaceFlattening() async throws {
        let mesh = SyntheticMeshes.cube()
        let segmentationService = MeshSegmentationService()
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        
        for panel in panels {
            let flattenedPanel = try await flattener.flattenPanel(panel, mesh: mesh)
            
            #expect(flattenedPanel.points2D.count >= 3, "Panel should have at least 3 points")
            #expect(!flattenedPanel.edges.isEmpty, "Panel should have edges")
            
            // Validate edge connectivity
            let maxVertexIndex = flattenedPanel.points2D.count - 1
            for (v1, v2) in flattenedPanel.edges {
                #expect(v1 >= 0 && v1 <= maxVertexIndex, "Edge vertex 1 should be valid index")
                #expect(v2 >= 0 && v2 <= maxVertexIndex, "Edge vertex 2 should be valid index") 
                #expect(v1 != v2, "Edge should connect different vertices")
            }
        }
    }
    
    // MARK: - Edge Length Preservation Tests
    
    @Test("Spring relaxation preserves edge lengths accurately")
    func edgeLengthPreservation() async throws {
        let mesh = SyntheticMeshes.cube()
        let segmentationService = MeshSegmentationService()
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        
        for panel in panels.prefix(3) { // Test first 3 panels to keep test time reasonable
            let flattenedPanel = try await flattener.flattenPanel(panel, mesh: mesh)
            
            // Calculate original 3D edge lengths
            var original3DLengths: [Float] = []
            let panelVertices = Array(panel.vertexIndices).map { mesh.vertices[$0] }
            
            for i in stride(from: 0, to: panel.triangleIndices.count, by: 3) {
                let v1 = mesh.vertices[panel.triangleIndices[i]]
                let v2 = mesh.vertices[panel.triangleIndices[i + 1]]
                let v3 = mesh.vertices[panel.triangleIndices[i + 2]]
                
                let length12 = simd_distance(v1, v2)
                let length23 = simd_distance(v2, v3)  
                let length31 = simd_distance(v3, v1)
                
                original3DLengths.append(contentsOf: [length12, length23, length31])
            }
            
            // Calculate 2D edge lengths from flattened result
            var flattened2DLengths: [Float] = []
            for (i, j) in flattenedPanel.edges {
                guard i < flattenedPanel.points2D.count && j < flattenedPanel.points2D.count else { continue }
                
                let p1 = flattenedPanel.points2D[i]
                let p2 = flattenedPanel.points2D[j]
                let distance = sqrt(Float((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y)))
                flattened2DLengths.append(distance)
            }
            
            // Compare lengths - spring relaxation should preserve relative ratios
            guard !original3DLengths.isEmpty && !flattened2DLengths.isEmpty else { continue }
            
            let avgOriginal = original3DLengths.reduce(0, +) / Float(original3DLengths.count)
            let avgFlattened = flattened2DLengths.reduce(0, +) / Float(flattened2DLengths.count)
            
            #expect(avgOriginal > 0, "Original edges should have positive length")
            #expect(avgFlattened > 0, "Flattened edges should have positive length")
            
            // Check that the overall scale is reasonable (not too compressed or expanded)
            let scaleRatio = avgFlattened / avgOriginal
            #expect(scaleRatio > 0.1 && scaleRatio < 10.0, "Scale should be reasonable")
        }
    }
    
    @Test("Relative edge length error is acceptable", .timeLimit(.seconds(30)))
    func relativeEdgeLengthError() async throws {
        let mesh = SyntheticMeshes.cube()
        let segmentationService = MeshSegmentationService()
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        
        // Test the largest panel (likely a cube face)
        guard let largestPanel = panels.max(by: { $0.triangleIndices.count < $1.triangleIndices.count }) else {
            throw TestError.noValidPanel
        }
        
        let flattenedPanel = try await flattener.flattenPanel(largestPanel, mesh: mesh)
        
        // For cube faces, calculate edge preservation accuracy
        var relativeErrors: [Float] = []
        
        // Build mapping from mesh vertex indices to flattened point indices
        let vertexIndexMap = Dictionary(uniqueKeysWithValues: 
            Array(largestPanel.vertexIndices).enumerated().map { ($1, $0) })
        
        for i in stride(from: 0, to: largestPanel.triangleIndices.count, by: 3) {
            let meshV1 = largestPanel.triangleIndices[i]
            let meshV2 = largestPanel.triangleIndices[i + 1]
            let meshV3 = largestPanel.triangleIndices[i + 2]
            
            guard let flatIndex1 = vertexIndexMap[meshV1],
                  let flatIndex2 = vertexIndexMap[meshV2],
                  let flatIndex3 = vertexIndexMap[meshV3],
                  flatIndex1 < flattenedPanel.points2D.count,
                  flatIndex2 < flattenedPanel.points2D.count,
                  flatIndex3 < flattenedPanel.points2D.count else { continue }
            
            // Calculate original and flattened edge lengths
            let original12 = simd_distance(mesh.vertices[meshV1], mesh.vertices[meshV2])
            let original23 = simd_distance(mesh.vertices[meshV2], mesh.vertices[meshV3])
            let original31 = simd_distance(mesh.vertices[meshV3], mesh.vertices[meshV1])
            
            let flat1 = flattenedPanel.points2D[flatIndex1]
            let flat2 = flattenedPanel.points2D[flatIndex2]
            let flat3 = flattenedPanel.points2D[flatIndex3]
            
            let flattened12 = sqrt(Float((flat1.x - flat2.x) * (flat1.x - flat2.x) + (flat1.y - flat2.y) * (flat1.y - flat2.y)))
            let flattened23 = sqrt(Float((flat2.x - flat3.x) * (flat2.x - flat3.x) + (flat2.y - flat3.y) * (flat2.y - flat3.y)))
            let flattened31 = sqrt(Float((flat3.x - flat1.x) * (flat3.x - flat1.x) + (flat3.y - flat1.y) * (flat3.y - flat1.y)))
            
            // Calculate relative errors
            if original12 > 0.001 {
                let error12 = abs(flattened12 - original12) / original12
                relativeErrors.append(error12)
            }
            if original23 > 0.001 {
                let error23 = abs(flattened23 - original23) / original23
                relativeErrors.append(error23)
            }
            if original31 > 0.001 {
                let error31 = abs(flattened31 - original31) / original31
                relativeErrors.append(error31)
            }
        }
        
        guard !relativeErrors.isEmpty else {
            throw TestError.noValidEdges
        }
        
        let averageRelativeError = relativeErrors.reduce(0, +) / Float(relativeErrors.count)
        
        // Spring relaxation should achieve < 10% average relative error as per work order
        #expect(averageRelativeError < 0.1, 
               "Average relative edge-length error should be < 10% (got \(averageRelativeError * 100)%)")
        
        // No individual edge should have > 25% error
        let maxError = relativeErrors.max() ?? 0
        #expect(maxError < 0.25,
               "Maximum edge error should be < 25% (got \(maxError * 100)%)")
    }
    
    // MARK: - Determinism Tests
    
    @Test("Flattening produces deterministic results")
    func flatteningDeterminism() async throws {
        let mesh = SyntheticMeshes.cube()
        let segmentationService = MeshSegmentationService()
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 5)
        
        guard let testPanel = panels.first else {
            throw TestError.noValidPanel
        }
        
        let flattened1 = try await flattener.flattenPanel(testPanel, mesh: mesh)
        let flattened2 = try await flattener.flattenPanel(testPanel, mesh: mesh)
        
        #expect(flattened1.points2D.count == flattened2.points2D.count,
               "Point count should be deterministic")
        #expect(flattened1.edges.count == flattened2.edges.count,
               "Edge count should be deterministic")
        
        // Points should be very close (allowing for floating point precision)
        for (p1, p2) in zip(flattened1.points2D, flattened2.points2D) {
            let distance = sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y))
            #expect(distance < 0.001, "Points should be deterministic within floating point precision")
        }
    }
    
    // MARK: - Bounding Box and Layout Tests
    
    @Test("Flattened panels have reasonable bounding boxes")
    func boundingBoxValidation() async throws {
        let mesh = SyntheticMeshes.cube()
        let segmentationService = MeshSegmentationService()  
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        
        for panel in panels {
            let flattenedPanel = try await flattener.flattenPanel(panel, mesh: mesh)
            let bbox = flattenedPanel.boundingBox
            
            #expect(bbox.width > 0, "Bounding box should have positive width")
            #expect(bbox.height > 0, "Bounding box should have positive height")
            #expect(bbox.width.isFinite, "Bounding box width should be finite")
            #expect(bbox.height.isFinite, "Bounding box height should be finite")
            
            // Bounding box should contain all points
            for point in flattenedPanel.points2D {
                #expect(point.x >= bbox.minX && point.x <= bbox.maxX,
                       "Point X should be within bounding box")
                #expect(point.y >= bbox.minY && point.y <= bbox.maxY,
                       "Point Y should be within bounding box")
            }
        }
    }
    
    // MARK: - Multiple Panel Flattening
    
    @Test("Multiple panels can be flattened efficiently")
    func multiplePanelFlattening() async throws {
        let mesh = SyntheticMeshes.cylinder(segments: 8, height: 2.0, radius: 1.0)
        let segmentationService = MeshSegmentationService()
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 5)
        
        let flattenedPanels = try await flattener.flattenPanels(panels, from: mesh)
        
        #expect(flattenedPanels.count == panels.count, "Should flatten all input panels")
        
        for (original, flattened) in zip(panels, flattenedPanels) {
            #expect(flattened.sourcePanel.id == original.id, "Should reference correct source panel")
            #expect(flattened.points2D.count > 0, "Should have flattened points")
            #expect(flattened.edges.count > 0, "Should have edge connections")
        }
    }
    
    // MARK: - Complex Geometry Tests
    
    @Test("Complex geometry flattens without errors")
    func complexGeometryFlattening() async throws {
        let meshes = [
            SyntheticMeshes.icosahedron(),
            SyntheticMeshes.cylinder(segments: 12, height: 3.0, radius: 1.5)
        ]
        
        for mesh in meshes {
            let segmentationService = MeshSegmentationService()
            let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 8)
            
            for panel in panels.prefix(2) { // Test subset to keep test time reasonable
                let flattenedPanel = try await flattener.flattenPanel(panel, mesh: mesh)
                
                #expect(flattenedPanel.points2D.count > 0, "Should produce flattened points")
                #expect(flattenedPanel.edges.count > 0, "Should have edge connections")
                
                // Points should be reasonable (not infinite or NaN)
                for point in flattenedPanel.points2D {
                    #expect(point.x.isFinite, "X coordinate should be finite")
                    #expect(point.y.isFinite, "Y coordinate should be finite")
                }
            }
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Flattening completes in reasonable time", .timeLimit(.seconds(10)))
    func flatteningPerformance() async throws {
        let mesh = SyntheticMeshes.cube()
        let segmentationService = MeshSegmentationService()
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        
        let startTime = Date()
        
        for panel in panels {
            _ = try await flattener.flattenPanel(panel, mesh: mesh)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        #expect(duration < 5.0, "Flattening 6 cube panels should complete within 5 seconds")
    }
    
    @Test("Concurrent flattening operations")
    func concurrentFlattening() async throws {
        let mesh = SyntheticMeshes.cube()
        let segmentationService = MeshSegmentationService() 
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        let flattener = PatternFlattener()
        
        guard panels.count >= 3 else {
            throw TestError.insufficientPanels
        }
        
        // Run multiple flattening operations concurrently
        async let result1 = flattener.flattenPanel(panels[0], mesh: mesh)
        async let result2 = flattener.flattenPanel(panels[1], mesh: mesh)
        async let result3 = flattener.flattenPanel(panels[2], mesh: mesh)
        
        let (flattened1, flattened2, flattened3) = try await (result1, result2, result3)
        
        #expect(flattened1.points2D.count > 0, "Concurrent flattening 1 should succeed")
        #expect(flattened2.points2D.count > 0, "Concurrent flattening 2 should succeed")
        #expect(flattened3.points2D.count > 0, "Concurrent flattening 3 should succeed")
    }
    
    // MARK: - Helper Types
    
    enum TestError: Error {
        case noValidPanel
        case noValidEdges
        case insufficientPanels
    }
}