// Version: 1.0.0
// CoverCraft Test Utilities - Mock AR Scanning Service
// 
// TDD-compliant mock implementation for ARScanningService protocol
// Designed for deterministic, isolated test scenarios

import Foundation
import CoverCraftCore
import CoverCraftDTO

/// Mock implementation of ARScanningService for testing
/// 
/// Provides deterministic behavior for test scenarios with configurable responses.
/// All async operations complete immediately for test performance.
@available(iOS 18.0, *)
public final class MockARScanningService: ARScanningService, @unchecked Sendable {
    
    // MARK: - Test Configuration
    
    /// Current mock state for controlling behavior
    public enum MockState {
        case ready
        case scanning
        case error(Error)
        case unavailable
    }
    
    /// Mock state controlling service behavior
    public var mockState: MockState = .ready
    
    /// Whether AR is available on the mock device
    public var mockARAvailable: Bool = true
    
    /// Mock mesh to return from getCurrentMesh()
    public var mockCurrentMesh: MeshDTO?
    
    /// Delay for async operations (for testing timing scenarios)
    public var mockAsyncDelay: TimeInterval = 0.0
    
    // MARK: - Test Tracking
    
    /// Number of times startScanning was called
    public private(set) var startScanningCallCount: Int = 0
    
    /// Number of times stopScanning was called
    public private(set) var stopScanningCallCount: Int = 0
    
    /// Number of times getCurrentMesh was called
    public private(set) var getCurrentMeshCallCount: Int = 0
    
    /// Number of times isARAvailable was called
    public private(set) var isARAvailableCallCount: Int = 0
    
    /// All method calls in order
    public private(set) var methodCallHistory: [String] = []
    
    // MARK: - Initialization
    
    /// Creates a new mock AR scanning service
    /// - Parameters:
    ///   - initialState: Initial mock state
    ///   - arAvailable: Whether AR should be available
    ///   - currentMesh: Mock mesh to return
    public init(
        initialState: MockState = .ready,
        arAvailable: Bool = true,
        currentMesh: MeshDTO? = nil
    ) {
        self.mockState = initialState
        self.mockARAvailable = arAvailable
        self.mockCurrentMesh = currentMesh
    }
    
    // MARK: - ARScanningService Protocol Implementation
    
    public func startScanning() async throws {
        await Task.sleep(nanoseconds: UInt64(mockAsyncDelay * 1_000_000_000))
        
        startScanningCallCount += 1
        methodCallHistory.append("startScanning")
        
        switch mockState {
        case .ready:
            mockState = .scanning
        case .scanning:
            // Already scanning - could throw or ignore
            break
        case .error(let error):
            throw error
        case .unavailable:
            throw ARScanningError.arNotAvailable
        }
    }
    
    public func stopScanning() async {
        await Task.sleep(nanoseconds: UInt64(mockAsyncDelay * 1_000_000_000))
        
        stopScanningCallCount += 1
        methodCallHistory.append("stopScanning")
        
        if case .scanning = mockState {
            mockState = .ready
        }
    }
    
    public func getCurrentMesh() async -> MeshDTO? {
        await Task.sleep(nanoseconds: UInt64(mockAsyncDelay * 1_000_000_000))
        
        getCurrentMeshCallCount += 1
        methodCallHistory.append("getCurrentMesh")
        
        return mockCurrentMesh
    }
    
    public func isARAvailable() -> Bool {
        isARAvailableCallCount += 1
        methodCallHistory.append("isARAvailable")
        
        return mockARAvailable
    }
    
    // MARK: - Test Helpers
    
    /// Reset all call counts and history for fresh test state
    public func resetTestTracking() {
        startScanningCallCount = 0
        stopScanningCallCount = 0
        getCurrentMeshCallCount = 0
        isARAvailableCallCount = 0
        methodCallHistory.removeAll()
    }
    
    /// Configure service to simulate AR unavailable scenario
    public func simulateARUnavailable() {
        mockARAvailable = false
        mockState = .unavailable
    }
    
    /// Configure service to simulate scanning error
    /// - Parameter error: Error to throw from scanning operations
    public func simulateError(_ error: Error) {
        mockState = .error(error)
    }
    
    /// Configure service with a mock mesh for testing
    /// - Parameter mesh: Mock mesh to return from getCurrentMesh()
    public func configureMockMesh(_ mesh: MeshDTO) {
        mockCurrentMesh = mesh
    }
    
    /// Verify that scanning was started exactly once
    /// - Returns: Whether startScanning was called exactly once
    public func verifyStartScanningCalledOnce() -> Bool {
        startScanningCallCount == 1
    }
    
    /// Verify that scanning was stopped exactly once
    /// - Returns: Whether stopScanning was called exactly once
    public func verifyStopScanningCalledOnce() -> Bool {
        stopScanningCallCount == 1
    }
    
    /// Verify method call order
    /// - Parameter expectedCalls: Expected sequence of method names
    /// - Returns: Whether calls match expected order
    public func verifyCallOrder(_ expectedCalls: [String]) -> Bool {
        methodCallHistory == expectedCalls
    }
    
    /// Get total number of method calls
    /// - Returns: Total number of calls made to service methods
    public func getTotalCallCount() -> Int {
        startScanningCallCount + stopScanningCallCount + getCurrentMeshCallCount + isARAvailableCallCount
    }
}

// MARK: - Mock Error Types

/// Errors that can be thrown by mock AR scanning service
@available(iOS 18.0, *)
public enum ARScanningError: Error, Equatable, LocalizedError {
    case arNotAvailable
    case scanningFailed(String)
    case meshGenerationFailed
    case sessionInterrupted
    
    public var errorDescription: String? {
        switch self {
        case .arNotAvailable:
            return "AR functionality is not available on this device"
        case .scanningFailed(let reason):
            return "AR scanning failed: \(reason)"
        case .meshGenerationFailed:
            return "Failed to generate mesh from AR data"
        case .sessionInterrupted:
            return "AR session was interrupted"
        }
    }
}

// MARK: - Factory Methods for Common Test Scenarios

@available(iOS 18.0, *)
public extension MockARScanningService {
    
    /// Create a mock service that immediately returns a test mesh
    /// - Returns: Configured mock service with test mesh
    static func withTestMesh() -> MockARScanningService {
        let testMesh = TestDataFactory.createTestMesh()
        return MockARScanningService(currentMesh: testMesh)
    }
    
    /// Create a mock service that simulates AR unavailable
    /// - Returns: Configured mock service with AR unavailable
    static func withARUnavailable() -> MockARScanningService {
        return MockARScanningService(
            initialState: .unavailable,
            arAvailable: false
        )
    }
    
    /// Create a mock service that throws scanning errors
    /// - Returns: Configured mock service that throws errors
    static func withScanningError() -> MockARScanningService {
        return MockARScanningService(
            initialState: .error(ARScanningError.scanningFailed("Test error"))
        )
    }
    
    /// Create a mock service with async delay for timing tests
    /// - Parameter delay: Delay in seconds for async operations
    /// - Returns: Configured mock service with delay
    static func withDelay(_ delay: TimeInterval) -> MockARScanningService {
        let mock = MockARScanningService()
        mock.mockAsyncDelay = delay
        return mock
    }
}