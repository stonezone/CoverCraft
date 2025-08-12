import Testing
import simd
@testable import CoverCraftCore

@Suite("CalibrationData Tests")
@MainActor
struct CalibrationTests {
    
    @Test("Calibration scale factor calculation")
    func calibrationScaleFactor() {
        let calibration = CalibrationData()
        
        // Set two points 1 unit apart in mesh space
        calibration.firstPoint = SIMD3<Float>(0, 0, 0)
        calibration.secondPoint = SIMD3<Float>(1, 0, 0)
        
        // Set real-world distance to 2 meters
        calibration.realWorldDistance = 2.0
        
        // Scale factor should be 2.0
        let tolerance: Float = 0.001
        #expect(abs(calibration.scaleFactor - 2.0) < tolerance)
    }
    
    @Test("Incomplete calibration")
    func incompleteCalibration() {
        let calibration = CalibrationData()
        
        // Only first point set
        calibration.firstPoint = SIMD3<Float>(0, 0, 0)
        #expect(!calibration.isComplete)
        #expect(calibration.scaleFactor == 1.0)
        
        // Both points but no distance
        calibration.secondPoint = SIMD3<Float>(1, 0, 0)
        calibration.realWorldDistance = 0
        #expect(!calibration.isComplete)
    }
    
    @Test("Calibration reset")
    func calibrationReset() {
        let calibration = CalibrationData()
        
        calibration.firstPoint = SIMD3<Float>(0, 0, 0)
        calibration.secondPoint = SIMD3<Float>(1, 0, 0)
        calibration.realWorldDistance = 2.0
        
        #expect(calibration.isComplete)
        
        calibration.reset()
        
        #expect(calibration.firstPoint == nil)
        #expect(calibration.secondPoint == nil)
        #expect(calibration.realWorldDistance == 1.0)
        #expect(!calibration.isComplete)
    }
}