// Version: 1.0.0
// CoverCraft Segmentation Tests - Mesh Segmentation Service Unit Tests
//
// Comprehensive unit tests for DefaultMeshSegmentationService following TDD principles
// Tests cover normal operation, edge cases, performance, and error conditions

import Testing
import simd
import CoverCraftDTO
import TestUtilities
@testable import CoverCraftSegmentation

@Suite("MeshSegmentationService Tests")
@available(iOS 18.0, *)
struct SegmentationServiceTests {
    
    let service: DefaultMeshSegmentationService
    
    init() {
        service = DefaultMeshSegmentationService()
    }
    
    // MARK: - Basic Segmentation Tests
    
    @Test("Segment simple cube mesh")
    func segmentSimpleCube() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let targetPanelCount = 6 // One panel per face
        
        let panels = try await service.segmentMesh(mesh, targetPanelCount: targetPanelCount)
        
        #expect(panels.count <= targetPanelCount)
        #expect(panels.count > 0)
        
        // All panels should have valid data
        for panel in panels {
            #expect(!panel.vertexIndices.isEmpty)
            #expect(!panel.triangleIndices.isEmpty)
            #expect(panel.triangleIndices.count % 3 == 0) // Multiple of 3 for triangles
        }
    }
    
    @Test("Segment triangle mesh")
    func segmentTriangleMesh() async throws {
        let mesh = TestDataFactory.createTriangleMesh()
        let targetPanelCount = 1
        
        let panels = try await service.segmentMesh(mesh, targetPanelCount: targetPanelCount)
        
        #expect(panels.count == 1)
        #expect(panels[0].vertexIndices.count == 3)
        #expect(panels[0].triangleIndices.count == 3)
    }
    
    @Test("Segment complex mesh")
    func segmentComplexMesh() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 3)
        let targetPanelCount = 10
        
        let panels = try await service.segmentMesh(mesh, targetPanelCount: targetPanelCount)
        
        #expect(panels.count > 0)
        #expect(panels.count <= targetPanelCount)
        
        // Verify all triangles are accounted for
        let totalTriangleIndices = panels.reduce(0) { $0 + $1.triangleIndices.count }
        #expect(totalTriangleIndices > 0)
    }
    
    // MARK: - Target Panel Count Tests
    
    @Test("Different target panel counts")
    func differentTargetPanelCounts() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        
        let testCounts = [1, 3, 6, 10, 20]
        
        for targetCount in testCounts {
            let panels = try await service.segmentMesh(mesh, targetPanelCount: targetCount)
            
            #expect(panels.count > 0)
            #expect(panels.count <= targetCount)
            
            // Verify panel quality
            for panel in panels {
                #expect(!panel.vertexIndices.isEmpty)
                #expect(!panel.triangleIndices.isEmpty)
            }
        }
    }
    
    @Test("Minimum panel count")
    func minimumPanelCount() async throws {
        let mesh = TestDataFactory.createTriangleMesh()
        let targetPanelCount = 1
        
        let panels = try await service.segmentMesh(mesh, targetPanelCount: targetPanelCount)
        
        #expect(panels.count == 1)
        #expect(panels[0].triangleIndices.count == 3) // Single triangle
    }
    
    @Test("Large panel count request")
    func largePanelCountRequest() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let targetPanelCount = 1000 // Much larger than triangles available
        
        let panels = try await service.segmentMesh(mesh, targetPanelCount: targetPanelCount)
        
        // Should not exceed reasonable limits based on mesh complexity
        #expect(panels.count > 0)
        #expect(panels.count <= mesh.triangleCount) // Can't have more panels than triangles
    }
    
    // MARK: - Preview Segmentation Tests
    
    @Test("Preview segmentation low resolution")
    func previewSegmentationLowResolution() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        
        let panels = try await service.previewSegmentation(mesh, resolution: .low)
        
        #expect(panels.count > 0)
        #expect(panels.count <= SegmentationResolution.low.targetPanelCount)
        
        // Preview should be fast and approximate
        for panel in panels {
            #expect(!panel.vertexIndices.isEmpty)
            #expect(!panel.triangleIndices.isEmpty)
        }
    }
    
    @Test("Preview segmentation medium resolution")
    func previewSegmentationMediumResolution() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 2)
        
        let panels = try await service.previewSegmentation(mesh, resolution: .medium)
        
        #expect(panels.count > 0)
        #expect(panels.count <= SegmentationResolution.medium.targetPanelCount)
    }
    
    @Test("Preview segmentation high resolution")
    func previewSegmentationHighResolution() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 3)
        
        let panels = try await service.previewSegmentation(mesh, resolution: .high)
        
        #expect(panels.count > 0)
        #expect(panels.count <= SegmentationResolution.high.targetPanelCount)
    }
    
    @Test("Preview vs full segmentation consistency")
    func previewVsFullSegmentationConsistency() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        
        let previewPanels = try await service.previewSegmentation(mesh, resolution: .medium)
        let fullPanels = try await service.segmentMesh(mesh, targetPanelCount: SegmentationResolution.medium.targetPanelCount)
        
        // Results should be similar (allowing for some variation)
        let panelCountDifference = abs(previewPanels.count - fullPanels.count)
        #expect(panelCountDifference <= 2) // Allow small variance
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("Empty mesh segmentation")
    func emptyMeshSegmentation() async throws {
        let emptyMesh = TestDataFactory.EdgeCases.emptyMesh()
        
        await #expect(throws: CoverCraftError.self) {
            _ = try await service.segmentMesh(emptyMesh, targetPanelCount: 5)
        }
    }
    
    @Test("Invalid mesh segmentation")
    func invalidMeshSegmentation() async throws {
        let invalidMesh = TestDataFactory.createInvalidMesh()
        
        await #expect(throws: CoverCraftError.self) {
            _ = try await service.segmentMesh(invalidMesh, targetPanelCount: 5)
        }
    }
    
    @Test("Zero panel count request")
    func zeroPanelCountRequest() async throws {
        let mesh = TestDataFactory.createTriangleMesh()
        
        await #expect(throws: CoverCraftError.self) {
            _ = try await service.segmentMesh(mesh, targetPanelCount: 0)
        }
    }
    
    @Test("Negative panel count request")
    func negativePanelCountRequest() async throws {
        let mesh = TestDataFactory.createTriangleMesh()
        
        await #expect(throws: CoverCraftError.self) {
            _ = try await service.segmentMesh(mesh, targetPanelCount: -5)
        }
    }
    
    @Test("Degenerate mesh handling")
    func degenerateMeshHandling() async throws {
        let degenerateMesh = MeshFixtures.degenerateTriangles
        
        // Should either handle gracefully or throw appropriate error
        do {
            let panels = try await service.segmentMesh(degenerateMesh, targetPanelCount: 1)
            // If it succeeds, should still produce valid results
            for panel in panels {
                #expect(!panel.vertexIndices.isEmpty)
            }
        } catch is CoverCraftError {
            // Acceptable to fail with proper error
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Segmentation performance small mesh")
    func segmentationPerformanceSmallMesh() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        
        let (panels, executionTime) = try await AsyncTestHelpers.measureAsync {
            try await service.segmentMesh(mesh, targetPanelCount: 6)
        }
        
        #expect(panels.count > 0)
        #expect(executionTime < 1.0) // Should complete within 1 second
    }
    
    @Test("Segmentation performance large mesh")
    func segmentationPerformanceLargeMesh() async throws {
        let largeMesh = MeshFixtures.largeMesh
        
        let (panels, executionTime) = try await AsyncTestHelpers.measureAsync {
            try await service.segmentMesh(largeMesh, targetPanelCount: 10)
        }
        
        #expect(panels.count > 0)
        #expect(executionTime < 10.0) // Should complete within 10 seconds even for large mesh
    }
    
    @Test("Preview performance comparison")
    func previewPerformanceComparison() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 3)
        
        let (previewPanels, previewTime) = try await AsyncTestHelpers.measureAsync {
            try await service.previewSegmentation(mesh, resolution: .medium)
        }
        
        let (fullPanels, fullTime) = try await AsyncTestHelpers.measureAsync {
            try await service.segmentMesh(mesh, targetPanelCount: SegmentationResolution.medium.targetPanelCount)
        }
        
        #expect(previewPanels.count > 0)
        #expect(fullPanels.count > 0)
        #expect(previewTime <= fullTime) // Preview should be faster or equal
    }
    
    @Test("Concurrent segmentation operations")
    func concurrentSegmentationOperations() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let operationCount = 5
        
        let operations = (0..<operationCount).map { index in
            {
                try await service.segmentMesh(mesh, targetPanelCount: index + 2)
            }
        }
        
        let results = try await AsyncTestHelpers.executeConcurrently(operations: operations)
        
        #expect(results.count == operationCount)
        
        for (index, panels) in results.enumerated() {
            #expect(panels.count > 0)
            #expect(panels.count <= index + 2)
        }
    }
    
    // MARK: - Panel Quality Tests
    
    @Test("Panel color assignment")
    func panelColorAssignment() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let targetPanelCount = 6
        
        let panels = try await service.segmentMesh(mesh, targetPanelCount: targetPanelCount)
        
        // Each panel should have a color assigned
        let colorsUsed = Set(panels.map { $0.color })
        #expect(colorsUsed.count > 0)
        #expect(colorsUsed.count <= panels.count) // No more colors than panels
    }
    
    @Test("Panel index validity")
    func panelIndexValidity() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let panels = try await service.segmentMesh(mesh, targetPanelCount: 6)
        
        for panel in panels {
            // All vertex indices should be valid
            for vertexIndex in panel.vertexIndices {
                #expect(vertexIndex >= 0)
                #expect(vertexIndex < mesh.vertices.count)
            }
            
            // All triangle indices should reference valid vertices
            for triangleIndex in panel.triangleIndices {
                #expect(triangleIndex >= 0)
                #expect(triangleIndex < mesh.vertices.count)
            }
        }
    }
    
    @Test("Panel coverage completeness")
    func panelCoverageCompleteness() async throws {
        let mesh = TestDataFactory.createTriangleMesh()
        let panels = try await service.segmentMesh(mesh, targetPanelCount: 1)
        
        // For simple cases, all triangles should be covered
        let totalTriangleIndices = panels.reduce(0) { $0 + $1.triangleIndices.count }
        #expect(totalTriangleIndices >= mesh.triangleIndices.count)
    }
    
    // MARK: - Memory Management Tests
    
    @Test("Memory usage during segmentation")
    func memoryUsageDuringSegmentation() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 4)
        
        // Multiple segmentations should not accumulate memory
        for iteration in 0..<10 {
            let panels = try await service.segmentMesh(mesh, targetPanelCount: 5 + iteration)
            #expect(panels.count > 0)
            
            // Force cleanup between iterations
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }
    
    // MARK: - Error Recovery Tests
    
    @Test("Error recovery from malformed input")
    func errorRecoveryFromMalformedInput() async throws {
        // First try with invalid mesh
        let invalidMesh = TestDataFactory.createInvalidMesh()
        await #expect(throws: CoverCraftError.self) {
            _ = try await service.segmentMesh(invalidMesh, targetPanelCount: 5)
        }
        
        // Service should still work with valid input after error
        let validMesh = TestDataFactory.createCubeMesh()
        let panels = try await service.segmentMesh(validMesh, targetPanelCount: 6)
        #expect(panels.count > 0)
    }
    
    @Test("Cancellation handling")
    func cancellationHandling() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 5)
        
        let wasCancelled = await AsyncTestHelpers.testCancellation {
            try await service.segmentMesh(mesh, targetPanelCount: 20)
        }
        
        #expect(wasCancelled)
    }
    
    // MARK: - Integration Tests
    
    @Test("Integration with test fixtures")
    func integrationWithTestFixtures() async throws {
        let validMeshes = MeshFixtures.validMeshes
        
        for mesh in validMeshes {
            let panels = try await service.segmentMesh(mesh, targetPanelCount: 5)
            
            #expect(panels.count > 0)
            #expect(panels.count <= 5)
            
            // Verify panel data integrity
            for panel in panels {
                #expect(!panel.vertexIndices.isEmpty)
                #expect(!panel.triangleIndices.isEmpty)
            }
        }
    }
    
    @Test("Integration with different resolutions")
    func integrationWithDifferentResolutions() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 2)
        
        for resolution in SegmentationResolution.allCases {
            let panels = try await service.previewSegmentation(mesh, resolution: resolution)
            
            #expect(panels.count > 0)
            #expect(panels.count <= resolution.targetPanelCount)
        }
    }
    
    // MARK: - Algorithm Validation Tests
    
    @Test("Segmentation algorithm consistency")
    func segmentationAlgorithmConsistency() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let targetPanelCount = 6
        
        // Run multiple times with same input
        var allResults: [[PanelDTO]] = []
        
        for _ in 0..<5 {
            let panels = try await service.segmentMesh(mesh, targetPanelCount: targetPanelCount)
            allResults.append(panels)
        }
        
        // Results should be consistent (deterministic algorithm)
        let firstResult = allResults[0]
        for result in allResults {
            #expect(result.count == firstResult.count)
            // Note: Exact panel matching depends on algorithm implementation
            // We verify count consistency as a basic check
        }
    }
    
    @Test("Mesh topology preservation")
    func meshTopologyPreservation() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let panels = try await service.segmentMesh(mesh, targetPanelCount: 6)
        
        // All vertex indices used in panels should exist in original mesh
        let allUsedVertices = Set(panels.flatMap { $0.vertexIndices })
        for vertexIndex in allUsedVertices {
            #expect(vertexIndex < mesh.vertices.count)
        }
        
        // Triangle indices should form valid triangles
        for panel in panels {
            #expect(panel.triangleIndices.count % 3 == 0)
        }
    }
}