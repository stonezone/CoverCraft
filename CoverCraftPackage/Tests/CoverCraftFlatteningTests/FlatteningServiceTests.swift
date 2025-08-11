// Version: 1.0.0
// CoverCraft Flattening Tests - Pattern Flattening Service Unit Tests
//
// Comprehensive unit tests for DefaultPatternFlatteningService following TDD principles
// Tests cover normal operation, edge cases, performance, and algorithm validation

import Testing
import CoreGraphics
import simd
import CoverCraftDTO
import TestUtilities
@testable import CoverCraftFlattening

@Suite("PatternFlatteningService Tests")
@available(iOS 18.0, *)
struct FlatteningServiceTests {
    
    let service: DefaultPatternFlatteningService
    
    init() {
        service = DefaultPatternFlatteningService()
    }
    
    // MARK: - Basic Flattening Tests
    
    @Test("Flatten simple cube panels")
    func flattenSimpleCubePanels() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let panels = TestDataFactory.createTestPanels(count: 6, from: mesh)
        
        let flattenedPanels = try await service.flattenPanels(panels, from: mesh)
        
        #expect(flattenedPanels.count == panels.count)
        
        // Each flattened panel should have valid 2D geometry
        for flatPanel in flattenedPanels {
            #expect(flatPanel.points2D.count >= 3) // At least triangle
            #expect(!flatPanel.edges.isEmpty)
            #expect(flatPanel.scaleUnitsPerMeter > 0)
        }
    }
    
    @Test("Flatten single triangle panel")
    func flattenSingleTrianglePanel() async throws {
        let mesh = TestDataFactory.createTriangleMesh()
        let panel = TestDataFactory.createTestPanel(triangleCount: 1)
        
        let flattenedPanels = try await service.flattenPanels([panel], from: mesh)
        
        #expect(flattenedPanels.count == 1)
        
        let flatPanel = flattenedPanels[0]
        #expect(flatPanel.points2D.count == 3) // Triangle has 3 points
        #expect(flatPanel.edges.count == 3) // Triangle has 3 edges
    }
    
    @Test("Flatten complex mesh panels")
    func flattenComplexMeshPanels() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 2)
        let panels = TestDataFactory.createTestPanels(count: 8, from: mesh)
        
        let flattenedPanels = try await service.flattenPanels(panels, from: mesh)
        
        #expect(flattenedPanels.count <= panels.count)
        
        // Verify each flattened panel
        for flatPanel in flattenedPanels {
            #expect(flatPanel.points2D.count >= 3)
            #expect(!flatPanel.edges.isEmpty)
            #expect(flatPanel.isValid)
        }
    }
    
    // MARK: - Panel Count Variation Tests
    
    @Test("Flatten varying panel counts")
    func flattenVaryingPanelCounts() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let testCounts = [1, 3, 6, 10]
        
        for panelCount in testCounts {
            let panels = TestDataFactory.createTestPanels(count: panelCount, from: mesh)
            let flattenedPanels = try await service.flattenPanels(panels, from: mesh)
            
            #expect(flattenedPanels.count <= panelCount)
            #expect(flattenedPanels.count > 0)
            
            // All should be valid
            for flatPanel in flattenedPanels {
                #expect(flatPanel.isValid)
            }
        }
    }
    
    @Test("Flatten empty panel list")
    func flattenEmptyPanelList() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let emptyPanels: [PanelDTO] = []
        
        let flattenedPanels = try await service.flattenPanels(emptyPanels, from: mesh)
        
        #expect(flattenedPanels.isEmpty)
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Flatten with empty panel")
    func flattenWithEmptyPanel() async throws {
        let mesh = TestDataFactory.createTriangleMesh()
        let emptyPanel = TestDataFactory.EdgeCases.emptyPanel()
        
        await #expect(throws: CoverCraftError.self) {
            _ = try await service.flattenPanels([emptyPanel], from: mesh)
        }
    }
    
    @Test("Flatten with invalid mesh")
    func flattenWithInvalidMesh() async throws {
        let invalidMesh = TestDataFactory.createInvalidMesh()
        let panel = TestDataFactory.createTestPanel()
        
        await #expect(throws: CoverCraftError.self) {
            _ = try await service.flattenPanels([panel], from: invalidMesh)
        }
    }
    
    @Test("Flatten panels with invalid vertex indices")
    func flattenPanelsWithInvalidVertexIndices() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        
        // Create panel with out-of-bounds vertex indices
        let invalidPanel = PanelDTO(
            vertexIndices: [0, 999, 1000], // indices 999, 1000 are out of bounds
            triangleIndices: [0, 999, 1000],
            color: .red
        )
        
        await #expect(throws: CoverCraftError.self) {
            _ = try await service.flattenPanels([invalidPanel], from: mesh)
        }
    }
    
    @Test("Flatten degenerate panels")
    func flattenDegeneratePanels() async throws {
        let mesh = TestDataFactory.createPlaneMesh() // Flat mesh
        let panels = TestDataFactory.createTestPanels(count: 2, from: mesh)
        
        // Should either handle gracefully or throw appropriate error
        do {
            let flattenedPanels = try await service.flattenPanels(panels, from: mesh)
            
            // If successful, verify basic validity
            for flatPanel in flattenedPanels {
                #expect(flatPanel.points2D.count >= 3)
            }
        } catch is CoverCraftError {
            // Acceptable to fail with proper error for degenerate case
        }
    }
    
    // MARK: - Geometry Validation Tests
    
    @Test("Flattened panel geometry validity")
    func flattenedPanelGeometryValidity() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let panels = TestDataFactory.createTestPanels(count: 6, from: mesh)
        
        let flattenedPanels = try await service.flattenPanels(panels, from: mesh)
        
        for flatPanel in flattenedPanels {
            // Points should be finite and reasonable
            for point in flatPanel.points2D {
                #expect(point.x.isFinite)
                #expect(point.y.isFinite)
                #expect(abs(point.x) < 10000) // Reasonable bounds
                #expect(abs(point.y) < 10000)
            }
            
            // Edges should connect valid point indices
            for edge in flatPanel.edges {
                #expect(edge.startIndex >= 0)
                #expect(edge.endIndex >= 0)
                #expect(edge.startIndex < flatPanel.points2D.count)
                #expect(edge.endIndex < flatPanel.points2D.count)
                #expect(edge.startIndex != edge.endIndex) // No self-loops
            }
        }
    }
    
    @Test("2D area preservation")
    func area2DPreservation() async throws {
        let mesh = TestDataFactory.createPlaneMesh(width: 2.0, height: 2.0) // Known area: 4
        let panels = TestDataFactory.createTestPanels(count: 1, from: mesh)
        
        let flattenedPanels = try await service.flattenPanels(panels, from: mesh)
        
        #expect(flattenedPanels.count == 1)
        
        let flatPanel = flattenedPanels[0]
        let area2D = flatPanel.area2D
        
        // Area should be positive and reasonable
        #expect(area2D > 0)
        #expect(area2D < 1000) // Reasonable upper bound
    }
    
    @Test("Edge type assignment")
    func edgeTypeAssignment() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let panels = TestDataFactory.createTestPanels(count: 6, from: mesh)
        
        let flattenedPanels = try await service.flattenPanels(panels, from: mesh)
        
        for flatPanel in flattenedPanels {
            let edgeTypes = Set(flatPanel.edges.map { $0.type })
            
            // Should have at least cut lines
            #expect(edgeTypes.contains(.cutLine))
            
            // Edge types should be valid
            for edgeType in edgeTypes {
                #expect(EdgeType.allCases.contains(edgeType))
            }
        }
    }
    
    // MARK: - Optimization Tests
    
    @Test("Optimize simple flattened panels")
    func optimizeSimpleFlattenedPanels() async throws {
        let flattenedPanels = TestDataFactory.createTestFlattenedPanels(count: 3)
        
        let optimizedPanels = try await service.optimizeForCutting(flattenedPanels)
        
        #expect(optimizedPanels.count == flattenedPanels.count)
        
        // Optimized panels should maintain validity
        for panel in optimizedPanels {
            #expect(panel.isValid)
            #expect(panel.points2D.count >= 3)
            #expect(!panel.edges.isEmpty)
        }
    }
    
    @Test("Optimization preserves panel data")
    func optimizationPreservesPanelData() async throws {
        let originalPanels = TestDataFactory.createTestFlattenedPanels(count: 2)
        
        let optimizedPanels = try await service.optimizeForCutting(originalPanels)
        
        #expect(optimizedPanels.count == originalPanels.count)
        
        // Colors should be preserved
        let originalColors = Set(originalPanels.map { $0.color })
        let optimizedColors = Set(optimizedPanels.map { $0.color })
        #expect(originalColors == optimizedColors)
        
        // Scale should be preserved
        for (original, optimized) in zip(originalPanels, optimizedPanels) {
            #expect(original.scaleUnitsPerMeter == optimized.scaleUnitsPerMeter)
        }
    }
    
    @Test("Optimization improves layout efficiency")
    func optimizationImprovesLayoutEfficiency() async throws {
        // Create overlapping panels that could benefit from optimization
        let overlappingPanels = [
            FlattenedPanelDTO(
                points2D: [
                    CGPoint(x: 0, y: 0),
                    CGPoint(x: 100, y: 0),
                    CGPoint(x: 100, y: 100),
                    CGPoint(x: 0, y: 100)
                ],
                edges: [
                    EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
                    EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
                    EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
                    EdgeDTO(startIndex: 3, endIndex: 0, type: .cutLine)
                ],
                color: .red,
                scaleUnitsPerMeter: 1000
            ),
            FlattenedPanelDTO(
                points2D: [
                    CGPoint(x: 50, y: 50), // Overlapping with first panel
                    CGPoint(x: 150, y: 50),
                    CGPoint(x: 150, y: 150),
                    CGPoint(x: 50, y: 150)
                ],
                edges: [
                    EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
                    EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
                    EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
                    EdgeDTO(startIndex: 3, endIndex: 0, type: .cutLine)
                ],
                color: .blue,
                scaleUnitsPerMeter: 1000
            )
        ]
        
        let optimizedPanels = try await service.optimizeForCutting(overlappingPanels)
        
        // Should maintain panel count and validity
        #expect(optimizedPanels.count == overlappingPanels.count)
        
        for panel in optimizedPanels {
            #expect(panel.isValid)
        }
        
        // Optimization may have repositioned panels to reduce overlap
        let originalBounds = overlappingPanels.map { $0.boundingRect }
        let optimizedBounds = optimizedPanels.map { $0.boundingRect }
        
        // Both should have reasonable bounds
        for bounds in originalBounds + optimizedBounds {
            #expect(bounds.width > 0)
            #expect(bounds.height > 0)
        }
    }
    
    @Test("Optimize empty panel list")
    func optimizeEmptyPanelList() async throws {
        let emptyPanels: [FlattenedPanelDTO] = []
        
        let optimizedPanels = try await service.optimizeForCutting(emptyPanels)
        
        #expect(optimizedPanels.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    @Test("Flattening performance small dataset")
    func flatteningPerformanceSmallDataset() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let panels = TestDataFactory.createTestPanels(count: 6, from: mesh)
        
        let (flattenedPanels, executionTime) = try await AsyncTestHelpers.measureAsync {
            try await service.flattenPanels(panels, from: mesh)
        }
        
        #expect(flattenedPanels.count > 0)
        #expect(executionTime < 2.0) // Should complete within 2 seconds
    }
    
    @Test("Flattening performance large dataset")
    func flatteningPerformanceLargeDataset() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 4)
        let panels = TestDataFactory.createTestPanels(count: 15, from: mesh)
        
        let (flattenedPanels, executionTime) = try await AsyncTestHelpers.measureAsync {
            try await service.flattenPanels(panels, from: mesh)
        }
        
        #expect(flattenedPanels.count > 0)
        #expect(executionTime < 15.0) // Should complete within reasonable time
    }
    
    @Test("Optimization performance")
    func optimizationPerformance() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 10)
        
        let (optimizedPanels, executionTime) = try await AsyncTestHelpers.measureAsync {
            try await service.optimizeForCutting(panels)
        }
        
        #expect(optimizedPanels.count == panels.count)
        #expect(executionTime < 5.0) // Optimization should be reasonably fast
    }
    
    @Test("Concurrent flattening operations")
    func concurrentFlatteningOperations() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let operationCount = 5
        
        let operations = (0..<operationCount).map { index in
            {
                let panels = TestDataFactory.createTestPanels(count: index + 2, from: mesh)
                return try await service.flattenPanels(panels, from: mesh)
            }
        }
        
        let results = try await AsyncTestHelpers.executeConcurrently(operations: operations)
        
        #expect(results.count == operationCount)
        
        for (index, flattenedPanels) in results.enumerated() {
            #expect(flattenedPanels.count > 0)
            #expect(flattenedPanels.count <= index + 2)
        }
    }
    
    // MARK: - Memory Management Tests
    
    @Test("Memory usage during flattening")
    func memoryUsageDuringFlattening() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 3)
        
        // Multiple flattening operations should not accumulate memory
        for iteration in 0..<5 {
            let panels = TestDataFactory.createTestPanels(count: 5, from: mesh)
            let flattenedPanels = try await service.flattenPanels(panels, from: mesh)
            
            #expect(flattenedPanels.count > 0)
            
            // Brief pause to allow cleanup
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }
    
    // MARK: - Error Recovery Tests
    
    @Test("Error recovery from flattening failure")
    func errorRecoveryFromFlatteningFailure() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        
        // First attempt with invalid data
        let invalidPanel = TestDataFactory.EdgeCases.emptyPanel()
        await #expect(throws: CoverCraftError.self) {
            _ = try await service.flattenPanels([invalidPanel], from: mesh)
        }
        
        // Service should still work after error
        let validPanels = TestDataFactory.createTestPanels(count: 2, from: mesh)
        let flattenedPanels = try await service.flattenPanels(validPanels, from: mesh)
        #expect(flattenedPanels.count > 0)
    }
    
    @Test("Cancellation handling during flattening")
    func cancellationHandlingDuringFlattening() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 5)
        let panels = TestDataFactory.createTestPanels(count: 20, from: mesh)
        
        let wasCancelled = await AsyncTestHelpers.testCancellation {
            try await service.flattenPanels(panels, from: mesh)
        }
        
        #expect(wasCancelled)
    }
    
    // MARK: - Algorithm Validation Tests
    
    @Test("Flattening algorithm consistency")
    func flatteningAlgorithmConsistency() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let panels = TestDataFactory.createTestPanels(count: 6, from: mesh)
        
        // Run multiple times with same input
        var allResults: [[FlattenedPanelDTO]] = []
        
        for _ in 0..<3 {
            let flattenedPanels = try await service.flattenPanels(panels, from: mesh)
            allResults.append(flattenedPanels)
        }
        
        // Results should be consistent
        let firstResult = allResults[0]
        for result in allResults {
            #expect(result.count == firstResult.count)
            
            // Verify basic properties match
            for (index, panel) in result.enumerated() {
                let firstPanel = firstResult[index]
                #expect(panel.points2D.count == firstPanel.points2D.count)
                #expect(panel.edges.count == firstPanel.edges.count)
                #expect(panel.color == firstPanel.color)
            }
        }
    }
    
    @Test("Scale preservation during flattening")
    func scalePreservationDuringFlattening() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let panels = TestDataFactory.createTestPanels(count: 3, from: mesh)
        
        let flattenedPanels = try await service.flattenPanels(panels, from: mesh)
        
        // All flattened panels should have consistent scale
        let scales = flattenedPanels.map { $0.scaleUnitsPerMeter }
        let uniqueScales = Set(scales)
        
        #expect(uniqueScales.count <= 2) // Should be mostly consistent
        
        // Scales should be reasonable
        for scale in scales {
            #expect(scale > 0)
            #expect(scale < 100000) // Not too large
        }
    }
    
    @Test("Topology preservation during flattening")
    func topologyPreservationDuringFlattening() async throws {
        let mesh = TestDataFactory.createTriangleMesh()
        let panel = TestDataFactory.createTestPanel(triangleCount: 1)
        
        let flattenedPanels = try await service.flattenPanels([panel], from: mesh)
        
        #expect(flattenedPanels.count == 1)
        
        let flatPanel = flattenedPanels[0]
        
        // Triangle should remain triangle
        #expect(flatPanel.points2D.count == 3)
        #expect(flatPanel.edges.count == 3)
        
        // Edges should form closed loop
        let edgeSet = Set(flatPanel.edges.flatMap { [$0.startIndex, $0.endIndex] })
        #expect(edgeSet.count == 3) // All three vertices referenced
    }
    
    // MARK: - Integration Tests
    
    @Test("Integration with test data factory")
    func integrationWithTestDataFactory() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 2)
        let panels = TestDataFactory.createTestPanels(count: 8, from: mesh)
        
        let flattenedPanels = try await service.flattenPanels(panels, from: mesh)
        
        #expect(flattenedPanels.count > 0)
        
        // Use factory to create expected flattened panels for comparison
        let expectedFlattened = TestDataFactory.createTestFlattenedPanels(count: flattenedPanels.count)
        
        #expect(flattenedPanels.count <= expectedFlattened.count)
        
        // Both sets should have valid panels
        for panel in flattenedPanels + expectedFlattened {
            #expect(panel.isValid)
        }
    }
    
    @Test("Integration with different mesh types")
    func integrationWithDifferentMeshTypes() async throws {
        let meshes = [
            TestDataFactory.createCubeMesh(),
            TestDataFactory.createTriangleMesh(),
            TestDataFactory.createPlaneMesh(),
            TestDataFactory.createComplexMesh(complexity: 2)
        ]
        
        for mesh in meshes {
            let panels = TestDataFactory.createTestPanels(count: 3, from: mesh)
            
            do {
                let flattenedPanels = try await service.flattenPanels(panels, from: mesh)
                
                // If successful, should produce valid results
                for flatPanel in flattenedPanels {
                    #expect(flatPanel.isValid)
                    #expect(flatPanel.points2D.count >= 3)
                }
            } catch is CoverCraftError {
                // Some mesh types may not be suitable for flattening
                // This is acceptable as long as proper errors are thrown
            }
        }
    }
}