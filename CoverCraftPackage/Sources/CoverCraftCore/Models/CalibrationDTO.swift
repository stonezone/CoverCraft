// Version: 1.0.0
// Data Transfer Object for calibration data across module boundaries

import Foundation
import simd

/// Immutable data transfer object for calibration measurements
public struct CalibrationDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let firstPoint: SIMD3<Float>?
    public let secondPoint: SIMD3<Float>?
    public let realWorldDistance: Float
    public let isComplete: Bool
    public let createdAt: Date
    public let lastModified: Date
    
    public init(
        id: UUID = UUID(),
        firstPoint: SIMD3<Float>? = nil,
        secondPoint: SIMD3<Float>? = nil,
        realWorldDistance: Float = 1.0,
        isComplete: Bool = false,
        createdAt: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.firstPoint = firstPoint
        self.secondPoint = secondPoint
        self.realWorldDistance = realWorldDistance
        self.isComplete = isComplete
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
    
    /// Calculate the measured distance between the two points
    public var measuredDistance: Float? {
        guard let first = firstPoint, let second = secondPoint else { return nil }
        return simd_distance(first, second)
    }
    
    /// Calculate the scaling factor for real-world measurements
    public var scalingFactor: Float? {
        guard let measured = measuredDistance, measured > 0 else { return nil }
        return realWorldDistance / measured
    }
}