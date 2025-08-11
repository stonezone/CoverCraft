// Version: 1.0.0
// Data Transfer Object for panel data across module boundaries

import Foundation
import simd

/// Immutable data transfer object representing a segmented panel
public struct PanelDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let vertexIndices: [Int]
    public let color: ColorDTO
    public let area: Float
    public let centroid: SIMD3<Float>
    public let createdAt: Date
    
    public init(
        id: UUID,
        vertexIndices: [Int],
        color: ColorDTO,
        area: Float,
        centroid: SIMD3<Float>,
        createdAt: Date
    ) {
        self.id = id
        self.vertexIndices = vertexIndices
        self.color = color
        self.area = area
        self.centroid = centroid
        self.createdAt = createdAt
    }
}

/// Immutable data transfer object for color information
public struct ColorDTO: Codable, Sendable, Equatable {
    public let red: Float
    public let green: Float
    public let blue: Float
    public let alpha: Float
    
    public init(red: Float, green: Float, blue: Float, alpha: Float = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    /// Create from SIMD4<Float>
    public init(simd: SIMD4<Float>) {
        self.red = simd.x
        self.green = simd.y
        self.blue = simd.z
        self.alpha = simd.w
    }
    
    /// Convert to SIMD4<Float>
    public var simd: SIMD4<Float> {
        SIMD4<Float>(red, green, blue, alpha)
    }
}