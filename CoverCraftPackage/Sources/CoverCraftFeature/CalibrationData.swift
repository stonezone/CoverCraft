import Foundation
import simd

/// Stores calibration data for real-world scaling
@Observable
@MainActor
public final class CalibrationData {
    /// First selected point on mesh
    public var firstPoint: SIMD3<Float>?
    
    /// Second selected point on mesh
    public var secondPoint: SIMD3<Float>?
    
    /// Real-world distance between points in meters
    public var realWorldDistance: Float = 1.0
    
    public init() {}
    
    /// Computed scale factor to convert mesh units to meters
    public var scaleFactor: Float {
        guard let point1 = firstPoint,
              let point2 = secondPoint else { return 1.0 }
        
        let meshDistance = simd_distance(point1, point2)
        guard meshDistance > 0.0001 else { return 1.0 }
        
        return realWorldDistance / meshDistance
    }
    
    /// Check if calibration is complete
    public var isComplete: Bool {
        firstPoint != nil && secondPoint != nil && realWorldDistance > 0
    }
    
    /// Reset calibration data
    public func reset() {
        firstPoint = nil
        secondPoint = nil
        realWorldDistance = 1.0
    }
}