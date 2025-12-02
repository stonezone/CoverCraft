import Foundation
import Testing
import simd
import CoverCraftDTO

@Suite("CalibrationDTO Tests")
struct CalibrationDTOTests {
    
    @Test("Scale factor for 2m over 1 unit")
    func scaleFactorCalculation() {
        let first = SIMD3<Float>(0, 0, 0)
        let second = SIMD3<Float>(1, 0, 0)
        let calibration = CalibrationDTO.with(
            firstPoint: first,
            secondPoint: second,
            realWorldDistance: 2.0
        )
        
        let tolerance: Float = 0.001
        #expect(abs(calibration.scaleFactor - 2.0) < tolerance)
        #expect(calibration.isComplete)
    }
    
    @Test("Incomplete calibration states")
    func incompleteCalibrationStates() {
        // Empty calibration
        let empty = CalibrationDTO.empty()
        #expect(!empty.isComplete)
        #expect(empty.scaleFactor == 1.0)
        
        // Only first point
        let firstOnly = empty.settingFirstPoint(SIMD3<Float>(0, 0, 0))
        #expect(!firstOnly.isComplete)
        
        // Both points but zero distance
        let bothPoints = firstOnly.settingSecondPoint(SIMD3<Float>(1, 0, 0))
        let zeroDistance = bothPoints.settingRealWorldDistance(0.0)
        #expect(!zeroDistance.isComplete)
    }
    
    @Test("Reset produces new empty calibration")
    func resetProducesEmptyCalibration() {
        let populated = CalibrationDTO.with(
            firstPoint: SIMD3<Float>(0, 0, 0),
            secondPoint: SIMD3<Float>(1, 0, 0),
            realWorldDistance: 2.0
        )
        
        let reset = populated.reset()
        
        #expect(!reset.isComplete)
        #expect(reset.firstPoint == nil)
        #expect(reset.secondPoint == nil)
        #expect(reset.realWorldDistance == 1.0)
        #expect(reset.id != populated.id)
    }
}
