// Version: 1.0.0
// Protocol contracts for calibration operations

import Foundation
import CoverCraftDTO
import simd

/// Contract for calibration data management
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public protocol CalibrationContract: AnyObject, Sendable {
    /// Current calibration state
    var calibrationData: CalibrationDTO { get }
    
    /// Set the first calibration point
    /// - Parameter point: 3D position in mesh coordinates
    func setFirstPoint(_ point: SIMD3<Float>)
    
    /// Set the second calibration point
    /// - Parameter point: 3D position in mesh coordinates
    func setSecondPoint(_ point: SIMD3<Float>)
    
    /// Update the real-world distance measurement
    /// - Parameter distance: Distance in meters
    func setRealWorldDistance(_ distance: Float)
    
    /// Reset all calibration data
    func reset()
    
    /// Check if calibration is complete and valid
    var isCalibrationComplete: Bool { get }
    
    /// Get the scaling factor for measurements
    var scalingFactor: Float? { get }
}

/// Contract for AR-based calibration operations
@available(iOS 18.0, macOS 15.0, *)
public protocol ARCalibrationContract: Actor {
    /// Perform hit test to find mesh intersection point
    /// - Parameters:
    ///   - screenPoint: 2D screen coordinates
    ///   - meshData: Current mesh data
    /// - Returns: 3D point on mesh surface if found
    func hitTest(screenPoint: SIMD2<Float>, mesh: MeshDTO) async -> SIMD3<Float>?
    
    /// Validate calibration points are reasonable distance apart
    /// - Parameters:
    ///   - firstPoint: First calibration point
    ///   - secondPoint: Second calibration point
    /// - Returns: True if points are valid for calibration
    func validateCalibrationPoints(
        firstPoint: SIMD3<Float>,
        secondPoint: SIMD3<Float>
    ) async -> Bool
}

// CalibrationError is defined in CoverCraftErrors.swift