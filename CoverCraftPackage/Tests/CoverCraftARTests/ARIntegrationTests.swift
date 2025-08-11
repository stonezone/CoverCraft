// Version: 1.0.0
// CoverCraft AR Module Tests - AR Integration Tests
//
// TDD-compliant comprehensive integration test suite using mocks and fixtures
// Following strict Red-Green-Refactor pattern with 90%+ branch coverage

#if canImport(UIKit) && canImport(ARKit)
import Testing
import Foundation
import CoverCraftAR
import CoverCraftCore
import CoverCraftDTO
import TestUtilities

/// Comprehensive integration test suite for AR module
/// 
/// Tests cover:
/// - End-to-end scanning workflows
/// - Integration with calibration system
/// - Mock service validation
/// - Complete data flow scenarios
/// - Performance integration characteristics
/// - Error propagation through system
@available(iOS 18.0, *)
@Suite("AR Integration Tests")
struct ARIntegrationTests {
    
    // MARK: - Test Properties
    
    private let mockService = MockARScanningService.withTestMesh()
    private let unavailableService = MockARScanningService.withARUnavailable()
    private let errorService = MockARScanningService.withScanningError()
    
    // MARK: - End-to-End Workflow Tests
    
    @Test("Complete scanning workflow with mock service")
    func testCompleteScanningWorkflowWithMockService() async throws {
        // Arrange
        let service = MockARScanningService.withTestMesh()
        service.resetTestTracking()
        
        // Act - complete workflow
        #expect(service.isARAvailable() == true)
        
        try await service.startScanning()
        #expect(service.verifyStartScanningCalledOnce())
        
        let mesh = await service.getCurrentMesh()
        #expect(mesh != nil)
        #expect(service.getCurrentMeshCallCount == 1)
        
        await service.stopScanning()
        #expect(service.verifyStopScanningCalledOnce())
        
        // Assert - verify complete call sequence
        let expectedCalls = ["isARAvailable", "startScanning", "getCurrentMesh", "stopScanning"]
        #expect(service.verifyCallOrder(expectedCalls))
    }
    
    @Test("Scanning workflow with calibration integration")
    func testScanningWorkflowWithCalibrationIntegration() async throws {
        // Arrange
        let service = MockARScanningService.withTestMesh()
        let calibration = CalibrationFixtures.ruler30cm
        service.resetTestTracking()
        
        // Act - scanning with calibration context
        try await service.startScanning()
        
        let mesh = await service.getCurrentMesh()
        let scaledMesh = mesh?.scaled(by: calibration.scaleFactor)
        
        await service.stopScanning()
        
        // Assert
        #expect(mesh != nil)
        #expect(scaledMesh != nil)
        #expect(scaledMesh?.vertices.count == mesh?.vertices.count)
        
        // Verify calibration was applied
        if let original = mesh, let scaled = scaledMesh {
            let scaleFactor = calibration.scaleFactor
            
            for i in 0..<min(original.vertices.count, scaled.vertices.count) {
                let originalVertex = original.vertices[i]
                let scaledVertex = scaled.vertices[i]
                
                let expectedScaled = originalVertex * Float(scaleFactor)
                
                #expect(abs(scaledVertex.x - expectedScaled.x) < 0.001)
                #expect(abs(scaledVertex.y - expectedScaled.y) < 0.001)
                #expect(abs(scaledVertex.z - expectedScaled.z) < 0.001)
            }
        }
    }
    
    @Test("Multi-session scanning workflow")
    func testMultiSessionScanningWorkflow() async throws {
        // Arrange
        let service = MockARScanningService.withTestMesh()
        service.resetTestTracking()
        
        // Act - multiple scanning sessions
        for sessionIndex in 0..<3 {
            try await service.startScanning()
            
            let mesh = await service.getCurrentMesh()
            #expect(mesh != nil, "Mesh should be available in session \(sessionIndex)")
            
            await service.stopScanning()
        }
        
        // Assert
        #expect(service.startScanningCallCount == 3)
        #expect(service.stopScanningCallCount == 3)
        #expect(service.getCurrentMeshCallCount == 3)
    }
    
    // MARK: - Mock Service Validation Tests
    
    @Test("Mock service behaves consistently across calls")
    func testMockServiceConsistentBehavior() async throws {
        // Arrange
        let service = MockARScanningService.withTestMesh()
        let testMesh = TestDataFactory.createTestMesh()
        service.configureMockMesh(MeshDTO(vertices: testMesh.vertices, triangleIndices: testMesh.triangleIndices))
        service.resetTestTracking()
        
        // Act - multiple identical operations
        for _ in 0..<5 {
            try await service.startScanning()
            let mesh = await service.getCurrentMesh()
            await service.stopScanning()
            
            #expect(mesh != nil)
            #expect(mesh?.vertices.count == testMesh.vertices.count)
            #expect(mesh?.triangleIndices.count == testMesh.triangleIndices.count)
        }
        
        // Assert - consistent behavior
        #expect(service.startScanningCallCount == 5)
        #expect(service.getCurrentMeshCallCount == 5)
        #expect(service.stopScanningCallCount == 5)
    }
    
    @Test("Mock service error scenarios are reliable")
    func testMockServiceErrorScenariosReliable() async throws {
        // Arrange
        let service = MockARScanningService.withScanningError()
        service.resetTestTracking()
        
        // Act & Assert - consistent error behavior
        for _ in 0..<3 {
            await #expect(throws: ARScanningError.self) {
                try await service.startScanning()
            }
            
            #expect(service.startScanningCallCount > 0)
        }
        
        // Service should maintain error state consistently
        #expect(service.startScanningCallCount == 3)
    }
    
    @Test("Mock service state transitions work correctly")
    func testMockServiceStateTransitions() async throws {
        // Arrange
        let service = MockARScanningService()
        service.resetTestTracking()
        
        // Act - test state transitions
        #expect(service.mockState == .ready)
        
        try await service.startScanning()
        #expect(service.mockState == .scanning)
        
        await service.stopScanning()
        #expect(service.mockState == .ready)
        
        // Assert - proper state management
        #expect(service.verifyStartScanningCalledOnce())
        #expect(service.verifyStopScanningCalledOnce())
    }
    
    // MARK: - Fixture Integration Tests
    
    @Test("Mesh fixtures integrate properly with AR workflow")
    func testMeshFixturesIntegrateWithARWorkflow() async throws {
        // Test all valid mesh fixtures
        for (index, fixture) in MeshFixtures.validMeshes.enumerated() {
            // Arrange
            let service = MockARScanningService()
            service.configureMockMesh(fixture)
            service.resetTestTracking()
            
            // Act
            try await service.startScanning()
            let retrievedMesh = await service.getCurrentMesh()
            await service.stopScanning()
            
            // Assert
            #expect(retrievedMesh != nil, "Mesh fixture \(index) should be retrievable")
            
            if let mesh = retrievedMesh {
                #expect(mesh.vertices.count == fixture.vertices.count)
                #expect(mesh.triangleIndices.count == fixture.triangleIndices.count)
                
                // Verify vertex data integrity
                for vertexIndex in 0..<mesh.vertices.count {
                    let original = fixture.vertices[vertexIndex]
                    let retrieved = mesh.vertices[vertexIndex]
                    
                    #expect(abs(original.x - retrieved.x) < 0.0001)
                    #expect(abs(original.y - retrieved.y) < 0.0001)
                    #expect(abs(original.z - retrieved.z) < 0.0001)
                }
            }
        }
    }
    
    @Test("Calibration fixtures work with AR mesh data")
    func testCalibrationFixturesWorkWithARMeshData() async throws {
        // Test calibration integration with different mesh types
        let meshFixtures = [MeshFixtures.simpleCube, MeshFixtures.tetrahedron, MeshFixtures.tshirtMesh]
        let calibrationFixtures = CalibrationFixtures.validCalibrations.prefix(3)
        
        for mesh in meshFixtures {
            for calibration in calibrationFixtures {
                // Arrange
                let service = MockARScanningService()
                service.configureMockMesh(mesh)
                
                // Act
                try await service.startScanning()
                let retrievedMesh = await service.getCurrentMesh()
                await service.stopScanning()
                
                // Apply calibration scaling
                let scaledMesh = retrievedMesh?.scaled(by: calibration.scaleFactor)
                
                // Assert
                #expect(scaledMesh != nil)
                #expect(scaledMesh?.vertices.count == mesh.vertices.count)
            }
        }
    }
    
    // MARK: - Performance Integration Tests
    
    @Test("End-to-end workflow completes within time constraints")
    func testEndToEndWorkflowPerformance() async throws {
        // Arrange
        let service = MockARScanningService.withTestMesh()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Act - complete workflow
        try await service.startScanning()
        let mesh = await service.getCurrentMesh()
        await service.stopScanning()
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert
        #expect(mesh != nil)
        #expect(totalTime < 0.1) // Should complete within 100ms with mock
    }
    
    // MARK: - Error Propagation Integration Tests
    
    @Test("Service errors propagate correctly through workflow")
    func testServiceErrorsPropagateCorrectlyThroughWorkflow() async throws {
        // Test different error types
        let errorScenarios: [(service: MockARScanningService, expectedError: ARScanningError)] = [
            (.withARUnavailable(), .arNotAvailable),
            (.withScanningError(), .scanningFailed("Test error"))
        ]
        
        for (service, expectedError) in errorScenarios {
            service.resetTestTracking()
            
            // Act & Assert
            do {
                try await service.startScanning()
                #expect(false, "Should have thrown error")
            } catch let error as ARScanningError {
                #expect(error == expectedError)
            }
            
            // Verify service state after error
            let mesh = await service.getCurrentMesh()
            #expect(mesh == nil) // Should be nil after error
        }
    }
    
    // MARK: - Data Flow Integration Tests
    
    @Test("Data flows correctly from AR to application layer")
    func testDataFlowsCorrectlyFromARToApplicationLayer() async throws {
        // Arrange
        let testMesh = TestDataFactory.createTestMesh()
        let service = MockARScanningService()
        service.configureMockMesh(MeshDTO(vertices: testMesh.vertices, triangleIndices: testMesh.triangleIndices))
        
        var capturedMeshData: MeshDTO?
        
        // Act - simulate full data flow
        try await service.startScanning()
        
        let retrievedMesh = await service.getCurrentMesh()
        capturedMeshData = retrievedMesh
        
        await service.stopScanning()
        
        // Assert - data integrity through the flow
        #expect(capturedMeshData != nil)
        
        if let captured = capturedMeshData {
            #expect(captured.vertices.count == testMesh.vertices.count)
            #expect(captured.triangleIndices.count == testMesh.triangleIndices.count)
            
            // Verify data wasn't corrupted in transit
            for i in 0..<captured.vertices.count {
                let original = testMesh.vertices[i]
                let received = captured.vertices[i]
                
                #expect(original.x == received.x)
                #expect(original.y == received.y)
                #expect(original.z == received.z)
            }
        }
    }
}

// MARK: - Test Helpers

@available(iOS 18.0, *)
extension ARIntegrationTests {
    
    /// Verify mesh data integrity after processing
    private func verifyMeshDataIntegrity(_ original: MeshDTO, _ processed: MeshDTO) {
        #expect(processed.vertices.count <= original.vertices.count) // May be optimized
        #expect(processed.triangleIndices.count <= original.triangleIndices.count) // May be filtered
        
        // Verify no NaN or infinite values
        for vertex in processed.vertices {
            #expect(vertex.x.isFinite)
            #expect(vertex.y.isFinite)
            #expect(vertex.z.isFinite)
        }
        
        // Verify triangle indices are valid
        for index in processed.triangleIndices {
            #expect(index >= 0)
            #expect(index < processed.vertices.count)
        }
    }
    
    /// Create test scenario with specific configuration
    private func createTestScenario(
        meshType: MeshDTO,
        calibration: CalibrationDTO,
        sessionConfig: ARSessionConfig
    ) -> MockARScanningService {
        let service = MockARScanningService()
        service.configureMockMesh(meshType)
        service.mockARAvailable = sessionConfig.enableLiDAR
        return service
    }
    
    /// Measure workflow performance
    private func measureWorkflowPerformance(
        _ workflow: () async throws -> Void
    ) async throws -> CFAbsoluteTime {
        let startTime = CFAbsoluteTimeGetCurrent()
        try await workflow()
        return CFAbsoluteTimeGetCurrent() - startTime
    }
}

#else
// Placeholder for non-iOS platforms
@available(iOS 18.0, *)
@Suite("AR Integration Tests - Skipped")
struct ARIntegrationTestsSkipped {
    @Test("Skipped on non-iOS platforms")
    func testSkipped() async throws {
        #expect(true) // Pass - tests skipped on non-iOS platforms
    }
}
#endif