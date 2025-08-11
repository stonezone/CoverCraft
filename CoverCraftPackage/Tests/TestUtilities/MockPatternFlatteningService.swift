// Version: 1.0.0
// CoverCraft Test Utilities - Mock Pattern Flattening Service
// 
// TDD-compliant mock implementation for PatternFlatteningService protocol
// Designed for deterministic, isolated test scenarios

import Foundation
import CoreGraphics
import CoverCraftCore
import CoverCraftDTO

/// Mock implementation of PatternFlatteningService for testing
/// 
/// Provides deterministic behavior for test scenarios with configurable responses.
/// All async operations complete immediately for test performance.
@available(iOS 18.0, *)
public final class MockPatternFlatteningService: PatternFlatteningService, @unchecked Sendable {
    
    // MARK: - Test Configuration
    
    /// Current mock state for controlling behavior
    public enum MockState {
        case ready
        case flattening
        case optimizing
        case error(Error)
    }
    
    /// Mock state controlling service behavior
    public var mockState: MockState = .ready
    
    /// Mock flattened panels to return from flattenPanels
    public var mockFlattenedPanels: [FlattenedPanelDTO] = []
    
    /// Mock optimized panels to return from optimizeForCutting
    public var mockOptimizedPanels: [FlattenedPanelDTO] = []
    
    /// Delay for async operations (for testing timing scenarios)
    public var mockAsyncDelay: TimeInterval = 0.0
    
    /// Whether to simulate realistic flattening behavior
    public var shouldGenerateRealisticResults: Bool = true
    
    /// Scale factor for generated flattened panels (units per meter)
    public var mockScaleUnitsPerMeter: Double = 1000.0 // 1000 units = 1 meter
    
    // MARK: - Test Tracking
    
    /// Number of times flattenPanels was called
    public private(set) var flattenPanelsCallCount: Int = 0
    
    /// Number of times optimizeForCutting was called
    public private(set) var optimizeForCuttingCallCount: Int = 0
    
    /// Last panels passed to flattenPanels
    public private(set) var lastFlattenPanels: [PanelDTO]?
    
    /// Last mesh passed to flattenPanels
    public private(set) var lastFlattenMesh: MeshDTO?
    
    /// Last panels passed to optimizeForCutting
    public private(set) var lastOptimizePanels: [FlattenedPanelDTO]?
    
    /// All method calls in order with parameters
    public private(set) var methodCallHistory: [(method: String, parameters: [String: Any])] = []
    
    // MARK: - Initialization
    
    /// Creates a new mock pattern flattening service
    /// - Parameters:
    ///   - initialState: Initial mock state
    ///   - flattenedPanels: Mock flattened panels to return
    ///   - optimizedPanels: Mock optimized panels to return
    public init(
        initialState: MockState = .ready,
        flattenedPanels: [FlattenedPanelDTO] = [],
        optimizedPanels: [FlattenedPanelDTO] = []
    ) {
        self.mockState = initialState
        self.mockFlattenedPanels = flattenedPanels
        self.mockOptimizedPanels = optimizedPanels
    }
    
    // MARK: - PatternFlatteningService Protocol Implementation
    
    public func flattenPanels(_ panels: [PanelDTO], from mesh: MeshDTO) async throws -> [FlattenedPanelDTO] {
        await Task.sleep(nanoseconds: UInt64(mockAsyncDelay * 1_000_000_000))
        
        flattenPanelsCallCount += 1
        lastFlattenPanels = panels
        lastFlattenMesh = mesh
        
        let parameters: [String: Any] = [
            "panelCount": panels.count,
            "meshId": mesh.id.uuidString
        ]
        methodCallHistory.append((method: "flattenPanels", parameters: parameters))
        
        switch mockState {
        case .ready, .flattening:
            mockState = .flattening
            defer { mockState = .ready }
            
            if shouldGenerateRealisticResults {
                return generateFlattenedPanels(from: panels, mesh: mesh)
            } else {
                return mockFlattenedPanels
            }
            
        case .optimizing:
            // Invalid state transition
            throw PatternFlatteningError.invalidState("Cannot flatten while optimizing")
            
        case .error(let error):
            throw error
        }
    }
    
    public func optimizeForCutting(_ panels: [FlattenedPanelDTO]) async throws -> [FlattenedPanelDTO] {
        await Task.sleep(nanoseconds: UInt64(mockAsyncDelay * 1_000_000_000))
        
        optimizeForCuttingCallCount += 1
        lastOptimizePanels = panels
        
        let parameters: [String: Any] = [
            "panelCount": panels.count
        ]
        methodCallHistory.append((method: "optimizeForCutting", parameters: parameters))
        
        switch mockState {
        case .ready, .optimizing:
            mockState = .optimizing
            defer { mockState = .ready }
            
            if shouldGenerateRealisticResults {
                return optimizePanelsForCutting(panels)
            } else {
                return mockOptimizedPanels
            }
            
        case .flattening:
            // Invalid state transition
            throw PatternFlatteningError.invalidState("Cannot optimize while flattening")
            
        case .error(let error):
            throw error
        }
    }
    
    // MARK: - Private Helpers
    
    private func generateFlattenedPanels(from panels: [PanelDTO], mesh: MeshDTO) -> [FlattenedPanelDTO] {
        guard mesh.isValid else { return [] }
        
        var flattenedPanels: [FlattenedPanelDTO] = []
        
        for panel in panels {
            let flattenedPanel = generateFlattenedPanel(from: panel, mesh: mesh)
            flattenedPanels.append(flattenedPanel)
        }
        
        return flattenedPanels
    }
    
    private func generateFlattenedPanel(from panel: PanelDTO, mesh: MeshDTO) -> FlattenedPanelDTO {
        // Generate simple rectangular 2D representation
        let sideLength: CGFloat = 100.0 // Base size in units
        let offset: CGFloat = CGFloat(flattenedPanels.count) * 120.0 // Spread panels apart
        
        let points2D = [
            CGPoint(x: offset, y: 0),
            CGPoint(x: offset + sideLength, y: 0),
            CGPoint(x: offset + sideLength, y: sideLength),
            CGPoint(x: offset, y: sideLength)
        ]
        
        let edges = [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
            EdgeDTO(startIndex: 3, endIndex: 0, type: .cutLine)
        ]
        
        return FlattenedPanelDTO(
            points2D: points2D,
            edges: edges,
            color: panel.color,
            scaleUnitsPerMeter: mockScaleUnitsPerMeter,
            originalPanelId: panel.id
        )
    }
    
    private func optimizePanelsForCutting(_ panels: [FlattenedPanelDTO]) -> [FlattenedPanelDTO] {
        // Simple optimization: pack panels closer together
        var optimizedPanels: [FlattenedPanelDTO] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        let rowHeight: CGFloat = 110.0
        let maxWidth: CGFloat = 800.0
        
        for panel in panels {
            let boundingBox = panel.boundingBox
            
            // Check if panel fits in current row
            if currentX + boundingBox.width > maxWidth {
                // Move to next row
                currentX = 0
                currentY += rowHeight
            }
            
            // Translate panel to new position
            let translation = CGPoint(
                x: currentX - boundingBox.minX,
                y: currentY - boundingBox.minY
            )
            
            let translatedPoints = panel.points2D.map { point in
                CGPoint(x: point.x + translation.x, y: point.y + translation.y)
            }
            
            let optimizedPanel = FlattenedPanelDTO(
                points2D: translatedPoints,
                edges: panel.edges,
                color: panel.color,
                scaleUnitsPerMeter: panel.scaleUnitsPerMeter,
                originalPanelId: panel.originalPanelId
            )
            
            optimizedPanels.append(optimizedPanel)
            currentX += boundingBox.width + 10 // Add margin
        }
        
        return optimizedPanels
    }
    
    // MARK: - Test Helpers
    
    /// Reset all call counts and history for fresh test state
    public func resetTestTracking() {
        flattenPanelsCallCount = 0
        optimizeForCuttingCallCount = 0
        lastFlattenPanels = nil
        lastFlattenMesh = nil
        lastOptimizePanels = nil
        methodCallHistory.removeAll()
    }
    
    /// Configure service to simulate flattening error
    /// - Parameter error: Error to throw from flattening operations
    public func simulateError(_ error: Error) {
        mockState = .error(error)
    }
    
    /// Configure mock flattened panels
    /// - Parameter panels: Panels to return from flattenPanels
    public func configureMockFlattenedPanels(_ panels: [FlattenedPanelDTO]) {
        mockFlattenedPanels = panels
    }
    
    /// Configure mock optimized panels
    /// - Parameter panels: Panels to return from optimizeForCutting
    public func configureMockOptimizedPanels(_ panels: [FlattenedPanelDTO]) {
        mockOptimizedPanels = panels
    }
    
    /// Verify that flattenPanels was called with specific parameters
    /// - Parameters:
    ///   - expectedPanelCount: Expected number of panels
    ///   - expectedMeshId: Expected mesh ID
    /// - Returns: Whether flattenPanels was called with expected parameters
    public func verifyFlattenPanelsCalled(withPanelCount expectedPanelCount: Int, meshId expectedMeshId: UUID) -> Bool {
        guard let lastPanels = lastFlattenPanels,
              let lastMesh = lastFlattenMesh else {
            return false
        }
        
        return lastPanels.count == expectedPanelCount && lastMesh.id == expectedMeshId
    }
    
    /// Verify that optimizeForCutting was called with specific panel count
    /// - Parameter expectedPanelCount: Expected number of panels
    /// - Returns: Whether optimizeForCutting was called with expected parameters
    public func verifyOptimizeForCuttingCalled(withPanelCount expectedPanelCount: Int) -> Bool {
        guard let lastPanels = lastOptimizePanels else {
            return false
        }
        
        return lastPanels.count == expectedPanelCount
    }
    
    /// Get total number of method calls
    /// - Returns: Total number of calls made to service methods
    public func getTotalCallCount() -> Int {
        flattenPanelsCallCount + optimizeForCuttingCallCount
    }
    
    /// Verify that flattening completed successfully
    /// - Returns: Whether service is in ready state after operations
    public func verifyCompletedSuccessfully() -> Bool {
        if case .ready = mockState {
            return true
        }
        return false
    }
}

// MARK: - Mock Error Types

/// Errors that can be thrown by mock pattern flattening service
@available(iOS 18.0, *)
public enum PatternFlatteningError: Error, Equatable, LocalizedError {
    case invalidPanels(String)
    case flatteningFailed(String)
    case optimizationFailed(String)
    case invalidState(String)
    case insufficientData
    
    public var errorDescription: String? {
        switch self {
        case .invalidPanels(let reason):
            return "Invalid panels for flattening: \(reason)"
        case .flatteningFailed(let reason):
            return "Pattern flattening failed: \(reason)"
        case .optimizationFailed(let reason):
            return "Pattern optimization failed: \(reason)"
        case .invalidState(let reason):
            return "Invalid service state: \(reason)"
        case .insufficientData:
            return "Insufficient data for flattening"
        }
    }
}

// MARK: - Factory Methods for Common Test Scenarios

@available(iOS 18.0, *)
public extension MockPatternFlatteningService {
    
    /// Create a mock service that returns test flattened panels
    /// - Parameter panelCount: Number of test flattened panels to generate
    /// - Returns: Configured mock service with test panels
    static func withTestFlattenedPanels(count panelCount: Int = 3) -> MockPatternFlatteningService {
        let testPanels = TestDataFactory.createTestFlattenedPanels(count: panelCount)
        return MockPatternFlatteningService(
            flattenedPanels: testPanels,
            optimizedPanels: testPanels
        )
    }
    
    /// Create a mock service that simulates flattening failure
    /// - Returns: Configured mock service that throws errors
    static func withFlatteningError() -> MockPatternFlatteningService {
        return MockPatternFlatteningService(
            initialState: .error(PatternFlatteningError.flatteningFailed("Test error"))
        )
    }
    
    /// Create a mock service that simulates optimization failure
    /// - Returns: Configured mock service that throws optimization errors
    static func withOptimizationError() -> MockPatternFlatteningService {
        return MockPatternFlatteningService(
            initialState: .error(PatternFlatteningError.optimizationFailed("Test optimization error"))
        )
    }
    
    /// Create a mock service with async delay for timing tests
    /// - Parameter delay: Delay in seconds for async operations
    /// - Returns: Configured mock service with delay
    static func withDelay(_ delay: TimeInterval) -> MockPatternFlatteningService {
        let mock = MockPatternFlatteningService()
        mock.mockAsyncDelay = delay
        return mock
    }
    
    /// Create a mock service with custom scale factor
    /// - Parameter scaleUnitsPerMeter: Scale factor for generated panels
    /// - Returns: Configured mock service with custom scale
    static func withCustomScale(_ scaleUnitsPerMeter: Double) -> MockPatternFlatteningService {
        let mock = MockPatternFlatteningService()
        mock.mockScaleUnitsPerMeter = scaleUnitsPerMeter
        return mock
    }
    
    /// Create a mock service that returns static results (not generated)
    /// - Returns: Configured mock service with static behavior
    static func withStaticResults() -> MockPatternFlatteningService {
        let mock = MockPatternFlatteningService()
        mock.shouldGenerateRealisticResults = false
        return mock
    }
}