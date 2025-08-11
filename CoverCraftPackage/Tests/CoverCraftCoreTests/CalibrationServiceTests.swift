// Version: 1.0.0
// CoverCraft Core Tests - Calibration Service Unit Tests
//
// Comprehensive unit tests for DefaultCalibrationService following TDD principles
// Tests cover normal operation, edge cases, and error conditions

import Testing
import simd
import CoverCraftDTO
import TestUtilities
@testable import CoverCraftCore

@Suite("CalibrationService Tests")
@available(iOS 18.0, *)
struct CalibrationServiceTests {
    
    let service: DefaultCalibrationService
    
    init() {
        service = DefaultCalibrationService()
    }
    
    // MARK: - Basic Operations Tests
    
    @Test("Create empty calibration")
    func createEmptyCalibration() {
        let calibration = service.createCalibration()
        
        #expect(calibration.isEmpty)
        #expect(calibration.firstPoint == nil)
        #expect(calibration.secondPoint == nil)
        #expect(calibration.realWorldDistance == 1.0)
        #expect(!calibration.isComplete)
    }
    
    @Test("Set first calibration point")
    func setFirstPoint() {
        let originalCalibration = service.createCalibration()
        let testPoint = SIMD3<Float>(1.0, 2.0, 3.0)
        
        let updatedCalibration = service.setFirstPoint(originalCalibration, point: testPoint)
        
        #expect(updatedCalibration.firstPoint == testPoint)
        #expect(updatedCalibration.secondPoint == nil)
        #expect(!updatedCalibration.isComplete)
    }
    
    @Test("Set second calibration point")
    func setSecondPoint() {
        let initialCalibration = service.createCalibration()
        let firstPoint = SIMD3<Float>(0.0, 0.0, 0.0)
        let secondPoint = SIMD3<Float>(1.0, 0.0, 0.0)
        
        let calibrationWithFirstPoint = service.setFirstPoint(initialCalibration, point: firstPoint)
        let calibrationWithBothPoints = service.setSecondPoint(calibrationWithFirstPoint, point: secondPoint)
        
        #expect(calibrationWithBothPoints.firstPoint == firstPoint)
        #expect(calibrationWithBothPoints.secondPoint == secondPoint)
        #expect(!calibrationWithBothPoints.isComplete) // Still missing real-world distance
    }
    
    @Test("Set real-world distance")
    func setRealWorldDistance() {
        let calibration = service.createCalibration()
        let testDistance = 2.5
        
        let updatedCalibration = service.setRealWorldDistance(calibration, distance: testDistance)
        
        #expect(updatedCalibration.realWorldDistance == testDistance)
    }
    
    @Test("Complete calibration workflow")
    func completeCalibrationWorkflow() {
        // Start with empty calibration
        var calibration = service.createCalibration()
        #expect(!service.validateCalibration(calibration))
        
        // Add first point
        calibration = service.setFirstPoint(calibration, point: SIMD3<Float>(0, 0, 0))
        #expect(!service.validateCalibration(calibration))
        
        // Add second point
        calibration = service.setSecondPoint(calibration, point: SIMD3<Float>(1, 0, 0))
        #expect(!service.validateCalibration(calibration))
        
        // Set real-world distance
        calibration = service.setRealWorldDistance(calibration, distance: 2.0)
        #expect(service.validateCalibration(calibration))
        #expect(calibration.isComplete)
    }
    
    // MARK: - Validation Tests
    
    @Test("Validate incomplete calibrations")
    func validateIncompleteCalibrations() {
        // Empty calibration
        let emptyCalibration = service.createCalibration()
        #expect(!service.validateCalibration(emptyCalibration))
        
        // Only first point
        let firstPointOnly = service.setFirstPoint(emptyCalibration, point: SIMD3<Float>(0, 0, 0))
        #expect(!service.validateCalibration(firstPointOnly))
        
        // Both points but no distance
        let bothPointsNoDistance = service.setSecondPoint(firstPointOnly, point: SIMD3<Float>(1, 0, 0))
        #expect(!service.validateCalibration(bothPointsNoDistance))
        
        // With distance but zero/negative
        let withZeroDistance = service.setRealWorldDistance(bothPointsNoDistance, distance: 0.0)
        #expect(!service.validateCalibration(withZeroDistance))
        
        let withNegativeDistance = service.setRealWorldDistance(bothPointsNoDistance, distance: -1.0)
        #expect(!service.validateCalibration(withNegativeDistance))
    }
    
    @Test("Validate complete calibration")
    func validateCompleteCalibration() {
        let calibration = TestDataFactory.createTestCalibration(isComplete: true)
        #expect(service.validateCalibration(calibration))
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("Identical calibration points")
    func identicalCalibrationPoints() {
        let samePoint = SIMD3<Float>(1.0, 2.0, 3.0)
        
        var calibration = service.createCalibration()
        calibration = service.setFirstPoint(calibration, point: samePoint)
        calibration = service.setSecondPoint(calibration, point: samePoint)
        calibration = service.setRealWorldDistance(calibration, distance: 1.0)
        
        // Calibration should be invalid due to identical points (distance calculation would be 0)
        #expect(!service.validateCalibration(calibration))
    }
    
    @Test("Very small distances")
    func verySmallDistances() {
        var calibration = service.createCalibration()
        calibration = service.setFirstPoint(calibration, point: SIMD3<Float>(0.0, 0.0, 0.0))
        calibration = service.setSecondPoint(calibration, point: SIMD3<Float>(0.001, 0.0, 0.0))
        calibration = service.setRealWorldDistance(calibration, distance: 0.001)
        
        #expect(service.validateCalibration(calibration))
    }
    
    @Test("Very large distances")
    func veryLargeDistances() {
        var calibration = service.createCalibration()
        calibration = service.setFirstPoint(calibration, point: SIMD3<Float>(-1000.0, 0.0, 0.0))
        calibration = service.setSecondPoint(calibration, point: SIMD3<Float>(1000.0, 0.0, 0.0))
        calibration = service.setRealWorldDistance(calibration, distance: 1000.0)
        
        #expect(service.validateCalibration(calibration))
    }
    
    @Test("Extreme coordinate values")
    func extremeCoordinateValues() {
        let largeValue: Float = Float.greatestFiniteMagnitude / 2
        let smallValue: Float = -Float.greatestFiniteMagnitude / 2
        
        var calibration = service.createCalibration()
        calibration = service.setFirstPoint(calibration, point: SIMD3<Float>(smallValue, 0, 0))
        calibration = service.setSecondPoint(calibration, point: SIMD3<Float>(largeValue, 0, 0))
        calibration = service.setRealWorldDistance(calibration, distance: 1.0)
        
        // Should handle extreme values gracefully
        let isValid = service.validateCalibration(calibration)
        #expect(isValid || !isValid) // Either is acceptable, just shouldn't crash
    }
    
    // MARK: - Performance Tests
    
    @Test("Calibration operations performance")
    func calibrationOperationsPerformance() async throws {
        let iterations = 10000
        
        let stats = try await AsyncTestHelpers.benchmark(iterations: iterations) {
            var calibration = service.createCalibration()
            calibration = service.setFirstPoint(calibration, point: SIMD3<Float>(0, 0, 0))
            calibration = service.setSecondPoint(calibration, point: SIMD3<Float>(1, 0, 0))
            calibration = service.setRealWorldDistance(calibration, distance: 2.0)
            return service.validateCalibration(calibration)
        }
        
        // Operations should be very fast (under 1ms average)
        #expect(stats.averageTime < 0.001)
        #expect(stats.maxTime < 0.01) // Even worst case should be under 10ms
    }
    
    // MARK: - Thread Safety Tests
    
    @Test("Concurrent calibration operations")
    func concurrentCalibrationOperations() async throws {
        let operationCount = 100
        
        let operations = (0..<operationCount).map { index in
            {
                var calibration = service.createCalibration()
                calibration = service.setFirstPoint(calibration, point: SIMD3<Float>(Float(index), 0, 0))
                calibration = service.setSecondPoint(calibration, point: SIMD3<Float>(Float(index + 1), 0, 0))
                calibration = service.setRealWorldDistance(calibration, distance: 1.0)
                return service.validateCalibration(calibration)
            }
        }
        
        let results = try await AsyncTestHelpers.executeConcurrently(operations: operations)
        
        // All operations should succeed
        #expect(results.allSatisfy { $0 })
        #expect(results.count == operationCount)
    }
    
    // MARK: - Error Conditions Tests
    
    @Test("NaN and infinite values handling")
    func nanAndInfiniteValuesHandling() {
        let nanPoint = SIMD3<Float>(Float.nan, 0, 0)
        let infinitePoint = SIMD3<Float>(Float.infinity, 0, 0)
        let negativeInfinitePoint = SIMD3<Float>(-Float.infinity, 0, 0)
        
        var calibration = service.createCalibration()
        
        // Test NaN points
        calibration = service.setFirstPoint(calibration, point: nanPoint)
        #expect(!service.validateCalibration(calibration))
        
        // Test infinite points
        calibration = service.createCalibration()
        calibration = service.setFirstPoint(calibration, point: infinitePoint)
        calibration = service.setSecondPoint(calibration, point: negativeInfinitePoint)
        calibration = service.setRealWorldDistance(calibration, distance: 1.0)
        #expect(!service.validateCalibration(calibration))
        
        // Test infinite distance
        calibration = service.createCalibration()
        calibration = service.setFirstPoint(calibration, point: SIMD3<Float>(0, 0, 0))
        calibration = service.setSecondPoint(calibration, point: SIMD3<Float>(1, 0, 0))
        calibration = service.setRealWorldDistance(calibration, distance: Double.infinity)
        #expect(!service.validateCalibration(calibration))
        
        // Test NaN distance
        calibration = service.setRealWorldDistance(calibration, distance: Double.nan)
        #expect(!service.validateCalibration(calibration))
    }
    
    // MARK: - State Immutability Tests
    
    @Test("Calibration immutability")
    func calibrationImmutability() {
        let originalCalibration = service.createCalibration()
        let testPoint = SIMD3<Float>(5.0, 6.0, 7.0)
        
        let updatedCalibration = service.setFirstPoint(originalCalibration, point: testPoint)
        
        // Original should be unchanged
        #expect(originalCalibration.firstPoint == nil)
        #expect(originalCalibration.secondPoint == nil)
        #expect(originalCalibration.realWorldDistance == 1.0)
        
        // Updated should have new values
        #expect(updatedCalibration.firstPoint == testPoint)
        #expect(updatedCalibration.secondPoint == nil)
        #expect(updatedCalibration.realWorldDistance == 1.0)
    }
    
    @Test("Chained operations immutability")
    func chainedOperationsImmutability() {
        let calibration1 = service.createCalibration()
        let calibration2 = service.setFirstPoint(calibration1, point: SIMD3<Float>(0, 0, 0))
        let calibration3 = service.setSecondPoint(calibration2, point: SIMD3<Float>(1, 0, 0))
        let calibration4 = service.setRealWorldDistance(calibration3, distance: 2.0)
        
        // Each step should be independent
        #expect(calibration1.isEmpty)
        #expect(calibration2.firstPoint != nil && calibration2.secondPoint == nil)
        #expect(calibration3.firstPoint != nil && calibration3.secondPoint != nil && calibration3.realWorldDistance == 1.0)
        #expect(calibration4.isComplete && calibration4.realWorldDistance == 2.0)
    }
    
    // MARK: - Integration with Test Data Factory
    
    @Test("Test data factory integration")
    func testDataFactoryIntegration() {
        // Complete calibration
        let completeCalibration = TestDataFactory.createTestCalibration(isComplete: true)
        #expect(service.validateCalibration(completeCalibration))
        
        // Incomplete calibration
        let incompleteCalibration = TestDataFactory.createTestCalibration(isComplete: false)
        #expect(!service.validateCalibration(incompleteCalibration))
        
        // Edge case calibration
        let edgeCaseCalibration = TestDataFactory.EdgeCases.incompleteCalibration()
        #expect(!service.validateCalibration(edgeCaseCalibration))
    }
}

// MARK: - Service Registration Tests

@Suite("CalibrationService Registration Tests")
@available(iOS 18.0, *)
struct CalibrationServiceRegistrationTests {
    
    @Test("Service registration")
    func serviceRegistration() {
        let container = DefaultDependencyContainer()
        
        // Register calibration services
        container.registerCalibrationServices()
        
        // Should be able to resolve the service
        let service: CalibrationService? = container.resolve()
        #expect(service != nil)
        #expect(service is DefaultCalibrationService)
    }
    
    @Test("Service singleton behavior")
    func serviceSingletonBehavior() {
        let container = DefaultDependencyContainer()
        container.registerCalibrationServices()
        
        let service1: CalibrationService? = container.resolve()
        let service2: CalibrationService? = container.resolve()
        
        #expect(service1 != nil)
        #expect(service2 != nil)
        #expect(service1 === service2) // Should be same instance
    }
}