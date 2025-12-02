// CoverCraft Core Tests - Calibration Service

import Foundation
import Testing
import simd
import CoverCraftDTO
@testable import CoverCraftCore

@Suite("CalibrationService Tests")
struct CalibrationServiceTests {
    
    private let service = DefaultCalibrationService()
    
    @Test("createCalibration returns empty calibration")
    func createCalibrationReturnsEmpty() {
        let calibration = service.createCalibration()
        
        #expect(calibration.firstPoint == nil)
        #expect(calibration.secondPoint == nil)
        #expect(calibration.realWorldDistance == 1.0)
        #expect(!calibration.isComplete)
    }
    
    @Test("complete workflow produces valid calibration")
    func completeWorkflowIsValid() {
        let first = SIMD3<Float>(0, 0, 0)
        let second = SIMD3<Float>(1, 0, 0)
        
        var calibration = service.createCalibration()
        calibration = service.setFirstPoint(calibration, point: first)
        calibration = service.setSecondPoint(calibration, point: second)
        calibration = service.setRealWorldDistance(calibration, distance: 2.0)
        
        #expect(service.validateCalibration(calibration))
        #expect(calibration.isComplete)
        
        let tolerance: Float = 0.001
        #expect(abs(calibration.scaleFactor - 2.0) < tolerance)
    }
    
    @Test("incomplete calibrations are rejected")
    func incompleteCalibrationsInvalid() {
        let base = service.createCalibration()
        
        let firstOnly = service.setFirstPoint(base, point: SIMD3<Float>(0, 0, 0))
        #expect(!service.validateCalibration(firstOnly))
        
        let bothPoints = service.setSecondPoint(firstOnly, point: SIMD3<Float>(1, 0, 0))
        #expect(!service.validateCalibration(bothPoints))
        
        let zeroDistance = service.setRealWorldDistance(bothPoints, distance: 0.0)
        #expect(!service.validateCalibration(zeroDistance))
    }
    
    @Test("identical points are invalid")
    func identicalPointsAreInvalid() {
        let point = SIMD3<Float>(1, 2, 3)
        
        var calibration = service.createCalibration()
        calibration = service.setFirstPoint(calibration, point: point)
        calibration = service.setSecondPoint(calibration, point: point)
        calibration = service.setRealWorldDistance(calibration, distance: 1.0)
        
        #expect(!service.validateCalibration(calibration))
    }
}
