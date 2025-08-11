// Version: 1.0.0
// CoverCraft Test Utilities - Mock Mesh Segmentation Service
// 
// TDD-compliant mock implementation for MeshSegmentationService protocol
// Designed for deterministic, isolated test scenarios

import Foundation
import CoverCraftCore
import CoverCraftDTO

/// Mock implementation of MeshSegmentationService for testing
/// 
/// Provides deterministic behavior for test scenarios with configurable responses.
/// All async operations complete immediately for test performance.
@available(iOS 18.0, *)
public final class MockMeshSegmentationService: MeshSegmentationService, @unchecked Sendable {
    
    // MARK: - Test Configuration
    
    /// Current mock state for controlling behavior
    public enum MockState {
        case ready
        case processing
        case error(Error)
    }
    
    /// Mock state controlling service behavior
    public var mockState: MockState = .ready
    
    /// Mock panels to return from segmentation
    public var mockSegmentedPanels: [PanelDTO] = []
    
    /// Mock preview panels to return from preview segmentation
    public var mockPreviewPanels: [PanelDTO] = []
    
    /// Delay for async operations (for testing timing scenarios)
    public var mockAsyncDelay: TimeInterval = 0.0
    
    /// Whether to simulate different results based on target panel count
    public var shouldVaryResultsByPanelCount: Bool = true
    
    // MARK: - Test Tracking
    
    /// Number of times segmentMesh was called
    public private(set) var segmentMeshCallCount: Int = 0
    
    /// Number of times previewSegmentation was called
    public private(set) var previewSegmentationCallCount: Int = 0
    
    /// Last mesh passed to segmentMesh
    public private(set) var lastSegmentMesh: MeshDTO?
    
    /// Last target panel count passed to segmentMesh
    public private(set) var lastTargetPanelCount: Int?
    
    /// Last mesh passed to previewSegmentation
    public private(set) var lastPreviewMesh: MeshDTO?
    
    /// Last resolution passed to previewSegmentation
    public private(set) var lastPreviewResolution: SegmentationResolution?
    
    /// All method calls in order with parameters
    public private(set) var methodCallHistory: [(method: String, parameters: [String: Any])] = []
    
    // MARK: - Initialization
    
    /// Creates a new mock mesh segmentation service
    /// - Parameters:
    ///   - initialState: Initial mock state
    ///   - segmentedPanels: Mock panels to return from segmentation
    ///   - previewPanels: Mock panels to return from preview
    public init(
        initialState: MockState = .ready,
        segmentedPanels: [PanelDTO] = [],
        previewPanels: [PanelDTO] = []
    ) {
        self.mockState = initialState
        self.mockSegmentedPanels = segmentedPanels
        self.mockPreviewPanels = previewPanels
    }
    
    // MARK: - MeshSegmentationService Protocol Implementation
    
    public func segmentMesh(_ mesh: MeshDTO, targetPanelCount: Int) async throws -> [PanelDTO] {
        await Task.sleep(nanoseconds: UInt64(mockAsyncDelay * 1_000_000_000))
        
        segmentMeshCallCount += 1
        lastSegmentMesh = mesh
        lastTargetPanelCount = targetPanelCount
        
        let parameters: [String: Any] = [
            "meshId": mesh.id.uuidString,
            "targetPanelCount": targetPanelCount
        ]
        methodCallHistory.append((method: "segmentMesh", parameters: parameters))
        
        switch mockState {
        case .ready, .processing:
            mockState = .processing
            defer { mockState = .ready }
            
            if shouldVaryResultsByPanelCount {
                return generatePanelsForTargetCount(targetPanelCount, from: mesh)
            } else {
                return mockSegmentedPanels
            }
            
        case .error(let error):
            throw error
        }
    }
    
    public func previewSegmentation(_ mesh: MeshDTO, resolution: SegmentationResolution) async throws -> [PanelDTO] {
        await Task.sleep(nanoseconds: UInt64(mockAsyncDelay * 1_000_000_000))
        
        previewSegmentationCallCount += 1
        lastPreviewMesh = mesh
        lastPreviewResolution = resolution
        
        let parameters: [String: Any] = [
            "meshId": mesh.id.uuidString,
            "resolution": resolution.rawValue
        ]
        methodCallHistory.append((method: "previewSegmentation", parameters: parameters))
        
        switch mockState {
        case .ready, .processing:
            if shouldVaryResultsByPanelCount {
                return generatePanelsForTargetCount(resolution.targetPanelCount, from: mesh)
            } else {
                return mockPreviewPanels
            }
            
        case .error(let error):
            throw error
        }
    }
    
    // MARK: - Private Helpers
    
    private func generatePanelsForTargetCount(_ targetCount: Int, from mesh: MeshDTO) -> [PanelDTO] {
        guard mesh.isValid, targetCount > 0 else { return [] }
        
        let actualCount = min(targetCount, mesh.triangleCount)
        var panels: [PanelDTO] = []
        
        let trianglesPerPanel = max(1, mesh.triangleCount / actualCount)
        let colors: [ColorDTO] = [.red, .green, .blue, .yellow, .orange, .purple, .cyan, .magenta]
        
        for panelIndex in 0..<actualCount {
            let startTriangle = panelIndex * trianglesPerPanel
            let endTriangle = min(startTriangle + trianglesPerPanel, mesh.triangleCount)
            
            var vertexIndices: Set<Int> = []
            var triangleIndices: [Int] = []
            
            for triangleIdx in startTriangle..<endTriangle {
                let baseIdx = triangleIdx * 3
                if baseIdx + 2 < mesh.triangleIndices.count {
                    let idx1 = mesh.triangleIndices[baseIdx]
                    let idx2 = mesh.triangleIndices[baseIdx + 1]
                    let idx3 = mesh.triangleIndices[baseIdx + 2]
                    
                    vertexIndices.insert(idx1)
                    vertexIndices.insert(idx2)
                    vertexIndices.insert(idx3)
                    
                    triangleIndices.append(contentsOf: [idx1, idx2, idx3])
                }
            }
            
            let color = colors[panelIndex % colors.count]
            let panel = PanelDTO(
                vertexIndices: vertexIndices,
                triangleIndices: triangleIndices,
                color: color
            )
            
            panels.append(panel)
        }
        
        return panels
    }
    
    // MARK: - Test Helpers
    
    /// Reset all call counts and history for fresh test state
    public func resetTestTracking() {
        segmentMeshCallCount = 0
        previewSegmentationCallCount = 0
        lastSegmentMesh = nil
        lastTargetPanelCount = nil
        lastPreviewMesh = nil
        lastPreviewResolution = nil
        methodCallHistory.removeAll()
    }
    
    /// Configure service to simulate segmentation error
    /// - Parameter error: Error to throw from segmentation operations
    public func simulateError(_ error: Error) {
        mockState = .error(error)
    }
    
    /// Configure mock panels for segmentation results
    /// - Parameter panels: Panels to return from segmentMesh
    public func configureMockSegmentedPanels(_ panels: [PanelDTO]) {
        mockSegmentedPanels = panels
    }
    
    /// Configure mock panels for preview results
    /// - Parameter panels: Panels to return from previewSegmentation
    public func configureMockPreviewPanels(_ panels: [PanelDTO]) {
        mockPreviewPanels = panels
    }
    
    /// Verify that segmentMesh was called with specific parameters
    /// - Parameters:
    ///   - expectedMeshId: Expected mesh ID
    ///   - expectedPanelCount: Expected target panel count
    /// - Returns: Whether segmentMesh was called with expected parameters
    public func verifySegmentMeshCalled(withMeshId expectedMeshId: UUID, targetPanelCount expectedPanelCount: Int) -> Bool {
        guard let lastMesh = lastSegmentMesh,
              let lastCount = lastTargetPanelCount else {
            return false
        }
        
        return lastMesh.id == expectedMeshId && lastCount == expectedPanelCount
    }
    
    /// Verify that previewSegmentation was called with specific parameters
    /// - Parameters:
    ///   - expectedMeshId: Expected mesh ID
    ///   - expectedResolution: Expected resolution
    /// - Returns: Whether previewSegmentation was called with expected parameters
    public func verifyPreviewSegmentationCalled(withMeshId expectedMeshId: UUID, resolution expectedResolution: SegmentationResolution) -> Bool {
        guard let lastMesh = lastPreviewMesh,
              let lastResolution = lastPreviewResolution else {
            return false
        }
        
        return lastMesh.id == expectedMeshId && lastResolution == expectedResolution
    }
    
    /// Get total number of method calls
    /// - Returns: Total number of calls made to service methods
    public func getTotalCallCount() -> Int {
        segmentMeshCallCount + previewSegmentationCallCount
    }
}

// MARK: - Mock Error Types

/// Errors that can be thrown by mock mesh segmentation service
@available(iOS 18.0, *)
public enum MeshSegmentationError: Error, Equatable, LocalizedError {
    case invalidMesh(String)
    case segmentationFailed(String)
    case insufficientTriangles
    case processingTimeout
    
    public var errorDescription: String? {
        switch self {
        case .invalidMesh(let reason):
            return "Invalid mesh for segmentation: \(reason)"
        case .segmentationFailed(let reason):
            return "Mesh segmentation failed: \(reason)"
        case .insufficientTriangles:
            return "Mesh has insufficient triangles for segmentation"
        case .processingTimeout:
            return "Segmentation processing timed out"
        }
    }
}

// MARK: - Factory Methods for Common Test Scenarios

@available(iOS 18.0, *)
public extension MockMeshSegmentationService {
    
    /// Create a mock service that returns test panels
    /// - Parameter panelCount: Number of test panels to generate
    /// - Returns: Configured mock service with test panels
    static func withTestPanels(count panelCount: Int = 5) -> MockMeshSegmentationService {
        let testPanels = TestDataFactory.createTestPanels(count: panelCount)
        return MockMeshSegmentationService(
            segmentedPanels: testPanels,
            previewPanels: testPanels
        )
    }
    
    /// Create a mock service that simulates segmentation failure
    /// - Returns: Configured mock service that throws errors
    static func withSegmentationError() -> MockMeshSegmentationService {
        return MockMeshSegmentationService(
            initialState: .error(MeshSegmentationError.segmentationFailed("Test error"))
        )
    }
    
    /// Create a mock service with async delay for timing tests
    /// - Parameter delay: Delay in seconds for async operations
    /// - Returns: Configured mock service with delay
    static func withDelay(_ delay: TimeInterval) -> MockMeshSegmentationService {
        let mock = MockMeshSegmentationService()
        mock.mockAsyncDelay = delay
        return mock
    }
    
    /// Create a mock service that varies results based on input
    /// - Returns: Configured mock service with dynamic behavior
    static func withDynamicResults() -> MockMeshSegmentationService {
        let mock = MockMeshSegmentationService()
        mock.shouldVaryResultsByPanelCount = true
        return mock
    }
    
    /// Create a mock service that returns empty results
    /// - Returns: Configured mock service with empty results
    static func withEmptyResults() -> MockMeshSegmentationService {
        let mock = MockMeshSegmentationService()
        mock.shouldVaryResultsByPanelCount = false
        return mock
    }
}