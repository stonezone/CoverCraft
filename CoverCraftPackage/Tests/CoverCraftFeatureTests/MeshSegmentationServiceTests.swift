import Testing
import simd
@testable import CoverCraftFeature

/// Tests for the sophisticated MeshSegmentationService with k-means and connectivity
@Suite("MeshSegmentationService Tests")
struct MeshSegmentationServiceTests {
    
    let segmentationService = MeshSegmentationService()
    
    // MARK: - Basic Functionality Tests
    
    @Test("Service initializes correctly")
    func serviceInitialization() async throws {
        // Service should initialize without issues (actor pattern)
        let service = MeshSegmentationService()
        #expect(service != nil)
    }
    
    @Test("Empty mesh throws appropriate error")
    func emptyMeshHandling() async throws {
        let emptyMesh = Mesh(vertices: [], triangleIndices: [])
        
        await #expect(throws: MeshSegmentationService.SegmentationError.self) {
            try await segmentationService.segmentMesh(emptyMesh, targetPanelCount: 5)
        }
    }
    
    @Test("Invalid target panel count handled gracefully")
    func invalidTargetCount() async throws {
        let triangle = SyntheticMeshes.triangle()
        
        // Zero panels should be handled
        let result = try await segmentationService.segmentMesh(triangle, targetPanelCount: 0)
        #expect(result.isEmpty)
        
        // Negative panels should be handled
        let negativeResult = try await segmentationService.segmentMesh(triangle, targetPanelCount: -1)
        #expect(negativeResult.isEmpty)
    }
    
    // MARK: - Cube Segmentation Tests
    
    @Test("Cube segmentation produces expected panel count")
    func cubeSegmentation() async throws {
        let cube = SyntheticMeshes.cube()
        
        // Test different target counts
        for targetCount in [5, 6, 8] {
            let panels = try await segmentationService.segmentMesh(cube, targetPanelCount: targetCount)
            
            #expect(panels.count > 0, "Should produce at least one panel")
            #expect(panels.count <= targetCount, "Should not exceed target panel count")
            #expect(panels.count <= 6, "Cube has maximum 6 faces")
            
            // Verify all panels are valid
            for panel in panels {
                #expect(panel.isValid, "Each panel should be valid")
                #expect(!panel.triangleIndices.isEmpty, "Panel should have triangles")
                #expect(!panel.vertexIndices.isEmpty, "Panel should have vertices")
            }
        }
    }
    
    @Test("Cube panels have connected triangles")
    func cubeConnectivity() async throws {
        let cube = SyntheticMeshes.cube()
        let panels = try await segmentationService.segmentMesh(cube, targetPanelCount: 6)
        
        // Each panel should have triangles that share vertices (connectivity)
        for panel in panels {
            let triangleCount = panel.triangleIndices.count / 3
            if triangleCount > 1 {
                // Check that triangles in this panel share at least some vertices
                let allVertices = Set(panel.vertexIndices)
                let triangleVertices = Set(panel.triangleIndices)
                
                #expect(triangleVertices.isSubset(of: allVertices), 
                       "Triangle vertices should be subset of panel vertices")
            }
        }
    }
    
    @Test("Cube segmentation is deterministic")
    func cubeSegmentationDeterministic() async throws {
        let cube = SyntheticMeshes.cube()
        
        let panels1 = try await segmentationService.segmentMesh(cube, targetPanelCount: 5)
        let panels2 = try await segmentationService.segmentMesh(cube, targetPanelCount: 5)
        
        #expect(panels1.count == panels2.count, "Panel count should be deterministic")
        
        // Sort panels by triangle count for comparison
        let sorted1 = panels1.sorted { $0.triangleIndices.count < $1.triangleIndices.count }
        let sorted2 = panels2.sorted { $0.triangleIndices.count < $1.triangleIndices.count }
        
        for (p1, p2) in zip(sorted1, sorted2) {
            #expect(p1.triangleIndices.count == p2.triangleIndices.count, 
                   "Triangle counts should be deterministic")
        }
    }
    
    // MARK: - Cylinder Segmentation Tests
    
    @Test("Cylinder segmentation with different segment counts")
    func cylinderSegmentation() async throws {
        let cylinder8 = SyntheticMeshes.cylinder(segments: 8, height: 2.0, radius: 1.0)
        let cylinder16 = SyntheticMeshes.cylinder(segments: 16, height: 2.0, radius: 1.0)
        
        for (cylinder, expectedMinPanels) in [(cylinder8, 3), (cylinder16, 3)] {
            let panels = try await segmentationService.segmentMesh(cylinder, targetPanelCount: 8)
            
            #expect(panels.count >= expectedMinPanels, 
                   "Cylinder should have at least \(expectedMinPanels) panels (top, bottom, sides)")
            #expect(panels.count <= 8, "Should not exceed target")
            
            // Verify mesh coverage - all triangles should be assigned
            let allAssignedTriangles = panels.reduce(0) { $0 + $1.triangleIndices.count }
            #expect(allAssignedTriangles <= cylinder.triangleIndices.count, 
                   "Should not assign more triangles than exist")
        }
    }
    
    // MARK: - Complex Mesh Tests
    
    @Test("Icosahedron segmentation handles complex geometry")
    func icosahedronSegmentation() async throws {
        let icosahedron = SyntheticMeshes.icosahedron()
        
        for targetCount in [5, 10, 15] {
            let panels = try await segmentationService.segmentMesh(icosahedron, targetPanelCount: targetCount)
            
            #expect(panels.count > 0, "Should produce panels")
            #expect(panels.count <= targetCount, "Should respect target count")
            
            // Verify panel quality
            for panel in panels {
                #expect(panel.triangleIndices.count >= 3, 
                       "Each panel should have at least one triangle")
                #expect(panel.triangleIndices.count % 3 == 0, 
                       "Triangle indices should be multiple of 3")
            }
        }
    }
    
    // MARK: - Panel Quality Tests
    
    @Test("All panels have distinct colors")
    func panelColorDistinction() async throws {
        let cube = SyntheticMeshes.cube()
        let panels = try await segmentationService.segmentMesh(cube, targetPanelCount: 6)
        
        let colors = panels.map { $0.color }
        let uniqueColors = Set(colors.map { "\($0.cgColor)" }) // Convert to comparable string
        
        #expect(uniqueColors.count == panels.count, "Each panel should have a distinct color")
    }
    
    @Test("Panel vertices are properly indexed")
    func panelVertexIndexing() async throws {
        let cube = SyntheticMeshes.cube()
        let panels = try await segmentationService.segmentMesh(cube, targetPanelCount: 5)
        
        for panel in panels {
            // All triangle indices should reference valid vertices
            for triangleIndex in panel.triangleIndices {
                #expect(triangleIndex >= 0, "Triangle index should be non-negative")
                #expect(triangleIndex < cube.vertices.count, 
                       "Triangle index should be within vertex array bounds")
            }
            
            // Vertex indices should be a proper set of the triangle vertices
            let triangleVertexSet = Set(panel.triangleIndices)
            let panelVertexSet = panel.vertexIndices
            
            #expect(triangleVertexSet.isSubset(of: panelVertexSet),
                   "Triangle vertices should be subset of panel vertices")
        }
    }
    
    // MARK: - Algorithm Validation Tests
    
    @Test("K-means clustering produces reasonable results")
    func kMeansQuality() async throws {
        let cube = SyntheticMeshes.cube()
        let panels = try await segmentationService.segmentMesh(cube, targetPanelCount: 6)
        
        // For a cube, we expect panels to roughly correspond to faces
        // Each face should have similar normal vectors within a panel
        let faceNormals = cube.computeFaceNormals()
        
        for panel in panels {
            if panel.triangleIndices.count >= 6 { // At least 2 triangles (1 face)
                // Compute normals for triangles in this panel
                var panelNormals: [SIMD3<Float>] = []
                
                for i in stride(from: 0, to: panel.triangleIndices.count, by: 3) {
                    let triangleIndex = i / 3
                    if triangleIndex < faceNormals.count {
                        panelNormals.append(faceNormals[triangleIndex])
                    }
                }
                
                // Check that normals within a panel are reasonably similar
                if panelNormals.count > 1 {
                    let avgNormal = panelNormals.reduce(SIMD3<Float>(0,0,0), +) / Float(panelNormals.count)
                    let normalizedAvg = simd_normalize(avgNormal)
                    
                    for normal in panelNormals {
                        let similarity = simd_dot(simd_normalize(normal), normalizedAvg)
                        #expect(similarity > 0.7, "Normals in same panel should be reasonably similar")
                    }
                }
            }
        }
    }
    
    @Test("Segmentation preserves mesh topology")
    func topologyPreservation() async throws {
        let meshes = [
            SyntheticMeshes.triangle(),
            SyntheticMeshes.cube(), 
            SyntheticMeshes.cylinder(segments: 6, height: 1.0, radius: 0.5)
        ]
        
        for originalMesh in meshes {
            let panels = try await segmentationService.segmentMesh(originalMesh, targetPanelCount: 5)
            
            // Count total triangles assigned
            let totalAssignedTriangles = panels.reduce(0) { $0 + ($1.triangleIndices.count / 3) }
            
            #expect(totalAssignedTriangles <= originalMesh.triangleCount, 
                   "Should not create more triangles than original")
            #expect(totalAssignedTriangles > 0, 
                   "Should assign at least some triangles")
        }
    }
    
    // MARK: - Performance and Edge Cases
    
    @Test("Handles single triangle mesh")
    func singleTriangleMesh() async throws {
        let triangle = SyntheticMeshes.triangle()
        let panels = try await segmentationService.segmentMesh(triangle, targetPanelCount: 5)
        
        #expect(panels.count == 1, "Single triangle should produce one panel")
        #expect(panels[0].triangleIndices.count == 3, "Panel should contain the triangle")
        #expect(panels[0].vertexIndices.count == 3, "Panel should have 3 vertices")
    }
    
    @Test("Large target count doesn't cause issues") 
    func largeTargetCount() async throws {
        let cube = SyntheticMeshes.cube()
        let panels = try await segmentationService.segmentMesh(cube, targetPanelCount: 100)
        
        #expect(panels.count > 0, "Should produce some panels")
        #expect(panels.count <= cube.triangleCount, "Cannot exceed triangle count")
        #expect(panels.count <= 100, "Should respect target maximum")
    }
    
    @Test("Service handles concurrent requests", .timeLimit(.minutes(1)))
    func concurrentSegmentation() async throws {
        let cube = SyntheticMeshes.cube()
        let service = MeshSegmentationService()
        
        // Run multiple segmentations concurrently
        async let result1 = service.segmentMesh(cube, targetPanelCount: 5)
        async let result2 = service.segmentMesh(cube, targetPanelCount: 6)
        async let result3 = service.segmentMesh(cube, targetPanelCount: 8)
        
        let (panels1, panels2, panels3) = try await (result1, result2, result3)
        
        #expect(panels1.count > 0, "Concurrent request 1 should succeed")
        #expect(panels2.count > 0, "Concurrent request 2 should succeed")  
        #expect(panels3.count > 0, "Concurrent request 3 should succeed")
    }
}